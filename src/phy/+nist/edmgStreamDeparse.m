function y = edmgStreamDeparse(x, numES, numCBPS, numBPSCS)  
%edmgStreamDeparse Stream deparser
%
%   Y = edmgStreamDeparse(X, NUMES, NUMCBPS, NUMBPSCS) deparses the spatial
%   streams in input X to form encoded streams. This is the inverse of the
%   operation defined in IEEE 802.11-2016 Sections 19.3.11.8.2 and
%   21.3.10.6, and IEEE P802.11ax/D4.1, Section 27.3.11.6.
%
%   Y is a matrix of size (Ncbps*Nsym/Nes)-by-Nes containing stream
%   deparsed data, where Ncbps is the number of coded bits per OFDM symbol,
%   Nsym is the number of OFDM symbols, and Nes is the number of encoded
%   streams.
%
%   X is a matrix of size (Ncbpss*Nsym)-by-Nss containing stream parsed
%   data, where Ncbpss is the number of coded bits per OFDM symbol per
%   spatial stream, and Nss is the number of spatial streams.
%
%   NUMES is a scalar representing the number of encoded streams. Valid
%   values are 1 to 9, and 12.
%
%   NUMCBPS is a scalar specifying the number of coded bits per OFDM
%   symbol. NUMCBPS must be equal to NUMBPSCS*Nss*Nsd, where Nsd is one
%   of 12, 24, 48, 51, 52, 102, 108, 117, 234, 468, 490, 980, or 1960.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1, 2, 4, 6, 8, or 10.
%
%   Example:
%   % Stream deparse 5 OFDM symbols with 2 spatial streams into 1 encoded
%   % stream.
%
%       % Input parameters
%       numCBPS = 432;
%       numBPSCS = 2;
%       numES = 1;
%       numSS = 2;
%       numSym = 5;
%
%       % Create parsed input of hard bits
%       parsed = randi([0 1],numCBPS/numSS*numSym,numSS);
%
%       % Stream deparser
%       deparsed = nist.edmgStreamDeparse(parsed,numES,numCBPS,numBPSCS);
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

% Validate numES
wlan.internal.validateParam('NUMES',numES);

% Validate numCBPS
validateattributes(numCBPS,{'numeric'},{'scalar'},mfilename,'numCBPS');

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0,numES);
    return;
end

% Validate input x
validateattributes(x,{'double'},{'2d'},mfilename,'Input x');

% Cross-validation between inputs
coder.internal.errorIf(~any(size(x,2) == 1:8), ...
    'wlan:wlanStreamParse:InvalidInputColumnsNUMSS'); % The number of columns of x must be a valid numSS
% coder.internal.errorIf(~any(numCBPS/(numBPSCS*size(x,2)) == [12 24 48 51 52 102 108 117 234 468 490 980 1960]), ...
%     'wlan:wlanStreamDeparse:InvalidNUMCBPS');

if (size(x, 2) == 1) && (numES == 1) % 1 spatial stream and 1 encoded stream
    y = x;
else
    coder.internal.errorIf(mod(numel(x),numCBPS) ~= 0, ... 
        'wlan:wlanStreamParse:InvalidInputSizeNUMCBPS'); % Integer number of OFDM symbols
    
    numSS = size(x,2);
    blkSize = max(1,numBPSCS/2); % Eq. 21.68
    sumS = numSS*blkSize;
    numBlock = floor(numCBPS/(numES*sumS)); % Eq. 21.69
    % Number of coded bits per OFDM symbol per spatial stream
    numCBPSS = numCBPS/numSS;
    % Number of OFDM symbols
    numSym = size(x,1)/numCBPSS;
    
    % Cross-validation between inputs and numSS (size(x,2))
    coder.internal.errorIf(~(numCBPS == numBlock*numES*sumS || numES == numSS), ...
        'wlan:wlanStreamParse:InvalidInputRelation');
    
    tailLen = numCBPS - numBlock*numES*sumS;
    
    if tailLen>0  
        % Stream deparsing per OFDM symbol when numCBPS > numBlock*numES*sumS
        % (Ref: IEEE Std 802.11-2016, Section 21.3.10.6)
        % VHT 'CBW160', numSS = 5, numES = 5, MCS = 5
        % VHT 'CBW160', numSS = 5, numES = 5, MCS = 6
        % VHT 'CBW160', numSS = 7, numES = 7, MCS = 5
        % VHT 'CBW160', numSS = 7, numES = 7, MCS = 6
        assert(numES==numSS) % Above cases on valid in this condition
        y = zeros(numCBPSS*numSym,numSS);
        M = tailLen/(blkSize*numES); % Eq. 21.70
        
        % 1st part of each OFDM symbol
        firstInd = bsxfun(@plus,(1:numCBPSS-M*blkSize).',(0:numSym-1)*numCBPSS);
        tempSym = reshape(x(firstInd(:),:),blkSize,numES,[],numSS); % [blkSize, numES, numBlock, numSS]
        tempSym = permute(tempSym,[1 4 3 2]); % [blkSize, numSS, numBlock, numES]
        tempSymReshape = reshape(tempSym,[],numES); % For codegen
        y(firstInd(:),1:numES) = tempSymReshape(:,1:numES); % [numCBPSS-M*blkSize, numES]
        
        % 2nd part of each OFDM symbol
        secondInd = bsxfun(@plus,(numCBPSS-M*blkSize+1:numCBPSS).',(0:numSym-1)*numCBPSS);
        for k = 1:numSym
            tempSym2 = reshape(x(secondInd(:,k),:),blkSize,[],numSS); % [blkSize, M, numSS]
            tempSym2 = permute(tempSym2,[1 3 2]); % [blkSize, numSS, M]
            tempSym2Reshape = reshape(tempSym2,[],numES); % For codegen
            y(secondInd(:,k),1:numES) = tempSym2Reshape(:,1:numES); % [M*blkSize, numES]
        end
    else % Stream deparsing for all OFDM symbols
        % No tail in IEEE P802.11ax/D4.1, Section 27.3.11.6.
        tempX = reshape(x,blkSize,numES,[],numSS); % [blkSize, numES, numBlock*numSym, numSS]
        tempX = permute(tempX,[1 4 3 2]); % [blkSize, numSS, numBlock*numSym, numES]
        y = reshape(tempX,[],numES); % [(numCBPS*numSym/numES), numES]
    end
end

end

