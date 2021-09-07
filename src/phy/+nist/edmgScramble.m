function y = edmgScramble(x,varargin)
%wlanScramble Scramble and descramble the binary input
%
%   Y = edmgScramble(X,SCRAMINIT) scrambles and descrambles the binary
%   input X using a frame-synchronous scrambler.
%
%   Y is a binary column vector or a matrix of type int8 or double with the
%   same size and type as the input X.
%
%   X is a binary column vector or a matrix of type int8 or double and is
%   scrambled with a length-127 frame-synchronous scrambler. Each column of
%   X is scrambled independently with the same initial state. The
%   frame-synchronous scrambler uses the generator polynomial defined in
%   IEEE(R) standard 802.11-2020 and P802.11ay D7.0. The same scrambler
%   structure is used to scramble bits at the transmitter and descramble
%   bits at the receiver.
%
%   SCRAMINIT is the initial state of the scrambler. It is an integer
%   between 1 and 127 inclusive, or a corresponding 7-by-1 column vector of
%   binary bits of type int8 or double. The mapping of the initialization
%   bits on scrambler schematic X1 to X7 is specified in IEEE(R) standard
%   802.11-2012, Section 20.3.9, P802.11ay D7.0 28.4.5.2.2, 28.5.9.3 and 28.6.9.1

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

inputClass = class(x);
y = zeros(size(x),inputClass);

if isempty(x)
    return;
end

% Validate inputs
if nargin>2
    scramInit = varargin{1};
    edmgFlag = varargin{2};
else
    scramInit = varargin{1};
    edmgFlag = 0;
end

validateattributes(x,{'int8','double'},{'binary','ndims',2},mfilename,'Input');

validateattributes(scramInit,{'numeric'},{'nonempty'},mfilename,'Scrambler initialization');

% Validate scrambler initialization input
if isscalar(scramInit)
    % Index scramInit for codegen
    coder.internal.errorIf((scramInit(1)<1 | scramInit(1)>127),'wlan:wlanScramble:InvalidScramInit');
    scramblerInitBits = de2bi(scramInit,7,'left-msb').'; 
elseif iscolumn(scramInit)
    coder.internal.errorIf(any((scramInit~=0) & (scramInit~=1)) || (numel(scramInit)~=7) ...
        || all(scramInit==0),'wlan:wlanScramble:InvalidScramInit');
    scramblerInitBits = scramInit;
else
    % Matrix or row vector
    coder.internal.error('wlan:wlanScramble:InvalidScramInit');
end

buffSize = min(127,size(x,1));
I = zeros(buffSize,1,'int8');

% Scrambling sequence generated using generator polynomial
if edmgFlag == 0
    for d = 1:buffSize
        I(d) = xor(scramblerInitBits(1),scramblerInitBits(4)); % x7 xor x4
        scramblerInitBits(1:end-1) = scramblerInitBits(2:end); % Left-shift
        scramblerInitBits(7) = I(d);                           % Update x1
    end
else
    % edmgFlag == 1 
    % P802.11ay Draft 7.0 Section 28.5.9.3.2
    for d = 1:buffSize
        I(d) = xor(scramblerInitBits(1),scramblerInitBits(7)); % x7 xor x1
        scramblerInitBits(1:end-1) = scramblerInitBits(2:end); % Left-shift
        scramblerInitBits(7) = I(d);                           % Update x1
    end
end

% Generate a periodic sequence from I to be xor-ed with the input
if isempty(coder.target)
    scramblerSequence = repmat(I,ceil(size(x,1)/buffSize),1);
    y = cast(xor(x,scramblerSequence(1:size(x,1))),inputClass);
else % Codegen branch
    y = coder.nullcopy(cast(zeros(size(x)),inputClass));
    for j = 1:size(x,2)
        k = 0;
        for i = 1:size(x,1)
            if k == buffSize
                k = 1;
            else
                k = k + 1;
            end
            y(i,j) = xor(x(i,j),I(k));
        end
    end
end

end
