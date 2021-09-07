function [startOffset,M] = edmgPacketDetect(x,varargin)
%edmgPacketDetect EDMG packet detection for OFDM and SC PHY using L-STF field
%
%   STARTOFFSET = edmgPacketDetect(X) returns the offset from the
%   start of the input waveform to the start of the detected preamble using
%   auto-correlation. The dmgPacketDetect() only detect DMG SC packet
%   type.
%
%   STARTOFFSET is an integer scalar indicating the location of the start
%   of a detected packet as the offset from the start of the matrix X. If
%   no packet is detected an empty value is returned.
%
%   X is the received time-domain signal. It is an Ns-by-1 matrix of real
%   or complex samples, where Ns represents the number of time domain
%   samples.
%
%   STARTOFFSET = edmgPacketDetect(..., OFFSET) specifies the offset to
%   begin the auto-correlation process from the start of the matrix X. The
%   STARTOFFSET is relative to the input OFFSET when specified. It is an
%   integer scalar greater than or equal to zero. When unspecified a value
%   of 0 is used.
%
%   STARTOFFSET = edmgPacketDetect(...,OFFSET,THRESHOLD) specifies the
%   threshold which the decision statistic must meet or exceed to detect a
%   packet. THRESHOLD is a real scalar greater than 0 and less than or
%   equal to 1. When unspecified a value of 0.03 is used.
%
%   [STARTOFFSET,M] = edmgPacketDetect(...) returns the decision
%   statistics of the packet detection algorithm of matrix X. When
%   THRESHOLD is set to 1, the decision statistics of the complete waveform
%   will be returned and STARTOFFSET will be empty.
%
%   M is a real vector of size N-by-1, representing the decision statistics
%   based on auto-correlation of the input waveform. The length of N
%   depends on the starting location of the auto-correlation process till
%   the successful detection of a packet.

%   Copyright 2017-2018 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,3);
nargoutchk(0,2);

% Check if M is requested
if nargout==2
    M = [];
end

validateattributes(x, {'double'}, {'2d','finite'}, mfilename, 'signal input');
startOffset = [];

if isempty(x)
    return;
end

if nargin == 1
    threshold = 0.03; % Default value
    offset = 0;       % Default value
elseif nargin == 2
    threshold = 0.03;
    validateattributes(varargin{1}, {'double'}, {'integer','scalar','>=',0}, mfilename, 'offset');
    offset = varargin{1};
else
    validateattributes(varargin{1}, {'double'}, {'integer','scalar','>=',0}, mfilename, 'offset');
    validateattributes(varargin{2}, {'double'}, {'real','scalar','>',0,'<=',1}, mfilename, 'threshold');
    offset = varargin{1};
    threshold = varargin{2};   
end

% Validate Offset value
coder.internal.errorIf(offset>size(x,1)-1, 'wlan:shared:InvalidOffsetValue');
symbolLength = 128;  % Length of single repetition of Golay sequence 
numRepetitions = 17; % Number of repetition of Golay sequence in the preamble

lenLSTF = symbolLength*numRepetitions; % Length of L-STF field
lenHalfLSTF = lenLSTF/2;               % Length of 1/2 L-STF field
inpLength = (size(x,1)-offset); 

% Append zeros to make the input equal to multiple of L-STF/2
if inpLength<=lenHalfLSTF
    numPadSamples = lenLSTF-inpLength;
else
    numPadSamples = lenHalfLSTF*ceil(inpLength/lenHalfLSTF)-inpLength;
end
padSamples = zeros(numPadSamples,size(x,2));

% Process the input waveform in blocks of L-STF length. The processing
% blocks are offset by half the L-STF length.
numBlocks = (inpLength+numPadSamples)/lenHalfLSTF;

if nargout==2
% Define decision statistics vector
DS = coder.nullcopy(zeros(size(x,1)+length(padSamples)-offset-2*symbolLength+1,1));
    if numBlocks > 2
        for n=1:numBlocks-2
            % Update buffer
            buffer = x((n-1)*lenHalfLSTF+(1:lenLSTF)+offset,:);
            [startOffset,out] = correlateSamples(buffer,symbolLength,threshold);

            DS((n-1)*lenHalfLSTF+1:lenHalfLSTF*n,1) = out(1:lenHalfLSTF);

            if ~(isempty(startOffset))
                % Packet detected
                startOffset = startOffset+(n-1)*lenHalfLSTF;
                DS((n-1)*lenHalfLSTF+(1:length(out)),1) = out;
                % Resize decision statistics
                M = DS(1:(n-1)*lenHalfLSTF+length(out));
                return;
            end
        end
        % Process last block of data
        blkOffset = lenHalfLSTF*(numBlocks-2);
        buffer = [x(blkOffset+1+offset:end,:);padSamples];
        [startOffset,out] = correlateSamples(buffer,symbolLength,threshold);
            if ~(isempty(startOffset))
                startOffset = startOffset+blkOffset; % Packet detected
            end
        DS(blkOffset+1:end,1)= out;
        M = DS(1:end-length(padSamples)); 
    else
        buffer = [x(offset+1:end,:);padSamples];
        [startOffset,out] = correlateSamples(buffer,symbolLength,threshold);
        M = out;
    end
else
    if numBlocks > 2
        for n=1:numBlocks-2
            buffer = x((n-1)*lenHalfLSTF+(1:lenLSTF)+offset,:); % Update buffer
            startOffset = correlateSamples(buffer,symbolLength,threshold);

            if ~(isempty(startOffset))
                startOffset = startOffset+(n-1)*lenHalfLSTF; % Packet detected
                return;
            end
        end
    % Process last block of data
    blkOffset = lenHalfLSTF*(numBlocks-2);
    buffer = [x(blkOffset+1+offset:end,:);padSamples];
    startOffset = correlateSamples(buffer,symbolLength,threshold);
        if ~(isempty(startOffset))
            startOffset = startOffset+blkOffset; % Packet detected
        end
    else
        buffer = [x(offset+1:end,:);padSamples];
        startOffset = correlateSamples(buffer,symbolLength,threshold); 
    end
end

end


function [packetStart,Mn] = correlateSamples(rxSig,symbolLength,threshold)
%   Estimate the start offset of the preamble of the receive WLAN packet,
%   using auto-correlation method [1].

%   [1] OFDM Wireless LANs: A Theoretical and Practical Guide 1st Edition
%       by Juha Heiskala (Author),John Terry Ph.D. ISBN-13:978-0672321573

pNoise = eps; % Adding noise to avoid the divide by zero
weights = ones(symbolLength,1);
packetStart = []; % Initialize output

% Shift data for correlation
rxDelayed = rxSig(symbolLength+1:end,:); % Delayed samples
rx = rxSig(1:end-symbolLength,:);        % Actual samples

% Sum output on multiple receive antennas
C = sum(filter(weights,1,(conj(rxDelayed).*rx)),2);
CS = C(symbolLength:end)./symbolLength;

% Sum output on multiple receive antennas
P = sum(filter(weights,1,abs(rxDelayed).^2./symbolLength),2);

PS = P(symbolLength:end)+pNoise;

Mn = abs(CS).^2./PS.^2;
N = Mn > threshold;

% The scalingFactor is used to scale the length of continuous region of
% correlation samples above the threshold.
scalingFactor = 5; 

if (sum(N) >= symbolLength*scalingFactor)
    % Convert mxArray to a known data type. Needed for codeGen
    startOnes = patternMatch([N(1)~=1 N.'],[0 1]);
    endOnes = patternMatch([N.' N(end)~=1],[1 0]);
    lengthOnes = endOnes - startOnes + 1;
    if max(lengthOnes)>symbolLength*scalingFactor
        maxIndex = find(lengthOnes>symbolLength*scalingFactor);
        % The index of the first maximum interval is the start of the packet
        packetStart = startOnes(maxIndex(1))-1; % Packet detected
    else
        packetStart = []; % No packet detected
    end
end

end

function ind = patternMatch(data,pattern)
%patternMatch Returns the indices where pattern is present in data array
  ind = zeros(1,length(data)-length(pattern)+1);
  tmp = 1;
  for i = 1:length(data)-length(pattern)+1
    flag = 0;
    for j = 1:length(pattern)
      if data(i+j-1) ~= pattern(j)
        flag = 1;
      end
    end
    if flag == 0
      ind(tmp) = i;
      tmp = tmp+1;
    end
  end
  ind = ind(1:tmp-1);
end
