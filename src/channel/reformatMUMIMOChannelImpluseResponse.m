function muMimoCirMat = reformatMUMIMOChannelImpluseResponse(muMimoCirCell,numTxAnt,numSTSVec,varargin)
%reformatMUMIMOChannelImpluseResponse reformat multi-user MIMO channel impluse response
%   This function reformats the multi-user (MU) MIMO channel impluse response (CIR).
% 
%  Inputs:
%   muMimoCirCell is a numUsers-length cell array holding the MU-MIMO CIR, each entry is a numTxAnt-by-numRxAnt sub
%   cell array, which contains the maxTdlLen-by-1 column vectors. maxTdlLen is the maximum TDL tap length.
%   numTxAnt is the number of transmit antenna array or RF chains
%   numSTSVec is a numUser-length row vector holding the number of spatial time streams of each user. 
%   varargin{1} is the maximum TDL tap length of MU-MIMO CIR
% 
%  Output:
%   muMimoCirMat is a numSTSTot-by-numTxAnt-by-maxTdlLen 3D time domain MU-MIMO CIR matrix.
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen
        
narginchk(3,4);

assert(iscell(muMimoCirCell),'muMimoCirCell should be a cell array');
assert(iscell(muMimoCirCell{1,1})||ismatrix(muMimoCirCell{1,1}), ...
    'Entrys of muMimoCirCell should be sub cell arraies or matrix');
numUsers = length(muMimoCirCell);
numSTSTot = sum(numSTSVec);

if nargin>3
    maxTdlLen = varargin{1};
else
    powIdx = zeros(numTxAnt,numSTSTot);
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        suMimoCir = muMimoCirCell{iUser};
        for iTxA = 1:numTxAnt
            for iRxA = 1:numSTSVec(iUser)
                if iscell(suMimoCir)
                    suSisoCir = squeeze(suMimoCir{iTxA,iRxA});
                else
                    suSisoCir = squeeze(suMimoCir(iRxA,iTxA,:,:));
                end
                streamPow = abs(suSisoCir).^2;
                lastTapIdx = find(streamPow > 1e-12,1,'last');
                if isempty(lastTapIdx)
                    powIdx(iTxA,stsIdx(iRxA)) = 1;
                else
                    powIdx(iTxA,stsIdx(iRxA)) = lastTapIdx;
                end
            end
        end
    end
    maxTdlLen = max(powIdx(:));
end

muMimoCirMat = zeros(numSTSTot,numTxAnt,maxTdlLen);
for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    muMimoCirMat(stsIdx,:,:) = reformatTDLMIMOChannelZeroPadding(muMimoCirCell{iUser},'MatrixArray',maxTdlLen);
end

end

