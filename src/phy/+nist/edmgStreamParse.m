function y = edmgStreamParse(x, numSS, numCBPS, numBPSCS)  
%edmgStreamParse Stream parser
%
%   Y = edmgStreamParse(X, NUMSS, NUMCBPS, NUMBPSCS) parses the encoded
%   bits in X into spatial streams as defined in IEEE 802.11-2016 Sections
%   19.3.11.8.2 and 21.3.10.6, and IEEE P802.11ax/D4.1 Section 27.3.11.6.
%
%   Y is a matrix of size (Ncbpss*Nsym)-by-NUMSS containing stream parsed
%   data, where Ncbpss is the number of coded bits per OFDM symbol per
%   spatial stream, Nsym is the number of OFDM symbols, and NUMSS is the
%   number of spatial streams.
%
%   X is a matrix of size (Ncbps*Nsym/Nes)-by-Nes containing the encoded
%   bits, where Nes is the number of encoded streams.
%
%   NUMSS is a scalar between 1 and 8 representing the number of spatial
%   streams.
%
%   NUMCBPS is a scalar specifying the number of coded bits per OFDM
%   symbol. NUMCBPS must be equal to NUMBPSCS*NUMSS*Nsd, where Nsd is one
%   of 12, 24, 48, 51, 52, 102, 108, 117, 234, 468, 490, 980, or 1960.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1, 2, 4, 6, 8, or 10.
%
%   Example 1:
%   % Stream parse 3 OFDM symbols with 2 encoded streams into 5 spatial  
%   % streams.
%
%       % Input parameters
%       numCBPS = 3240;
%       numBPSCS = 6;
%       numES = 2;
%       numSS = 5;
%       numSym = 3;
%
%       % Create input bits
%       bits = randi([0 1],numCBPS*numSym/numES,numES,'int8');
%
%       % Stream parser
%       parsedData = nist.edmgStreamParse(bits,numSS,numCBPS,numBPSCS);
%
%   Example 2:
%   % Get bit order of an OFDM symbol after stream parsing from 1 encoded 
%   % stream into 3 spatial streams.
%
%       % Input parameters
%       numCBPS = 156;
%       numBPSCS = 1;
%       numES = 1;
%       numSS = 3;
%       numSym = 1;
%
%       % Create input sequence
%       sequence = (1:numCBPS*numSym).';
%       inp = reshape(sequence,numCBPS*numSym/numES,numES);
%
%       % Stream parser
%       parsedData = nist.edmgStreamParse(inp,numSS,numCBPS,numBPSCS);
%
%   See also nist.edmgStreamParse.

%   Copyright 2015-2019 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Validate numBPSCS
wlan.internal.validateParam('NUMBPSCS',numBPSCS);

% Validate numSS
validateattributes(numSS,{'numeric'},{'scalar','>=',1,'<=',8},mfilename,'numSS');

% Validate numCBPS
validateattributes(numCBPS,{'numeric'},{'scalar'},mfilename,'numCBPS');
% coder.internal.errorIf(~any(numCBPS/(numBPSCS*numSS) == [12 24 48 51 52 102 108 117 234 468 490 980 1960]), ...
%     'wlan:wlanStreamParse:InvalidNUMCBPS');

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0,numSS,'like',x);
    return;
end

% Validate input x
validateattributes(x,{'double','int8'},{'2d'},mfilename,'Input x');

if (size(x, 2) == 1) && (numSS == 1) % 1 encoded stream & 1 spatial stream
    y = x;
else
    coder.internal.errorIf(~any(size(x,2) == [1:9 12]), ...
        'wlan:wlanStreamParse:InvalidInputColumnsNUMES'); % The number of columns of x must be a valid numES
    coder.internal.errorIf(mod(numel(x),numCBPS) ~= 0, ...
        'wlan:wlanStreamParse:InvalidInputSizeNUMCBPS'); % Integer number of OFDM symbols
    
    % IEEE Std 802.11-2016, Sections 19.3.11.8.2 and 21.3.10.6
    numES = size(x,2);
    blkSize = max(1,numBPSCS/2); % Eq. 21.68
    sumS = numSS*blkSize;
    numBlock = floor(numCBPS/(numES*sumS)); % Eq. 21.69
    % Number of OFDM symbols
    numSym = size(x,1)*numES/numCBPS;
    % Number of coded bits per OFDM symbol per spatial stream
    numCBPSS = numCBPS/numSS;
    
    % Cross-validation between inputs and numES (size(x,2))
    coder.internal.errorIf(~(numCBPS == numBlock*numES*sumS || numES == numSS), ...
        'wlan:wlanStreamParse:InvalidInputRelation');
    
    tailLen = numCBPS - numBlock*numES*sumS;
    
    if tailLen>0  
        % Stream parsing per OFDM symbol when numCBPS > numBlock*numES*sumS
        % (Ref: IEEE Std 802.11-2016, Section 21.3.10.6)
        % VHT 'CBW160', numSS = 5, MCS = 5
        % VHT 'CBW160', numSS = 5, MCS = 6
        % VHT 'CBW160', numSS = 7, MCS = 5
        % VHT 'CBW160', numSS = 7, MCS = 6
        y = coder.nullcopy(zeros(numCBPSS*numSym,numSS,'like',x));
        M = tailLen/(blkSize*numES); % Eq. 21.70
        
        % 1st part of each OFDM symbol
        firstInd = bsxfun(@plus,(1:numCBPSS-M*blkSize).',(0:numSym-1)*numCBPSS);
        tempSym = reshape(x(firstInd(:),:),blkSize,numSS,[],numES); % [blkSize, numSS, numBlock, numES]
        tempSym = permute(tempSym,[1 4 3 2]); % [blkSize, numES, numBlock, numSS]
        y(firstInd(:),:) = reshape(tempSym,[],numSS); % [numCBPSS-M*blkSize, numSS]
        
        % 2nd part of each OFDM symbol
        secondInd = bsxfun(@plus,(numCBPSS-M*blkSize+1:numCBPSS).',(0:numSym-1)*numCBPSS);
        for k = 1:numSym
            tempSym2 = reshape(x(secondInd(:,k),:),blkSize,numSS,[]); % [blkSize, numSS, M]
            tempSym2 = permute(tempSym2,[1 3 2]); % [blkSize, M, numSS]
            y(secondInd(:,k),:) = reshape(tempSym2,[],numSS); % [M*blkSize, numSS]
        end
    else % Stream parsing for all OFDM symbols
        % No tail in IEEE P802.11ax/D4.1, Section 27.3.11.6.
        tempX = reshape(x,blkSize,numSS,[],numES); % [blkSize, numSS, numBlock*numSym, numES]
        tempX = permute(tempX,[1 4 3 2]); % [blkSize, numES, numBlock*numSym, numSS]
        y = reshape(tempX,[],numSS); % [numCBPSS*numSym, numSS]
    end
end

end

