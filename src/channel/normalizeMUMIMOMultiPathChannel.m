function [tdlCirMuMimo,normFactor] = normalizeMUMIMOMultiPathChannel(muTapGain,numTxAnt,numSTSVec,normFlag,varargin)
%normalizeMUMIMOMultiPathChannel Normalize multi-user MIMO multi-path channel
%   This function normalizes the time domain tapped delay line (TDL) multi-user (MU) MIMO channel impluse response.
%   
% Inputs:
%   muTapGain is the time-domain multi-user channel impluse response TDL with the format of either a 
%       numTxAnt-by-numSTSTot cell array whose entries are maxTapLen-by-numSamp matricies; 
%       or a numSTSTot-by-numTxAnt-by-tapLen-by-numSamp 4-D matrix. numSTSTot is the total number of space-time
%       streams of all users.
%   numTxAnt is number of transmit antenna arrays or RF chains.
%   numSTSVec is the numUsers-length vecotr, each entry is the number of space-time streams of that user.
%   normFlag is the normalization control flag
%   varargin{1} is maximum tap length
%   varargin{2} is receiver port map
%   
% Outpus:
%   tdlCirMuMimo is the numUsers-length time domain TDL MU-MIMO CIR cell array, each entry is the numTxAnt-by-numSTS
%       sub cell array, having a maxTapLen-by-numSamp matrix.
%   normFactor is the normalization factor of time domain MU-MIMO CIR.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

narginchk(4,6);
if nargin == 5
    maxTapLen = varargin{1};
    rxPortMap = [];
elseif nargin == 6
    maxTapLen = varargin{1};
    rxPortMap = varargin{2};
end

zpMuTapGain = reformatTDLMIMOChannelZeroPadding(muTapGain,'MatrixArray',maxTapLen);
normFactor = norm(reshape(zpMuTapGain(:,:,:,1),[],1),'fro');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
tdlCirMuMimo = cell(numUsers,1);
for iUser = 1:numUsers
    if nargin < 6
        rxIdxList = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    else
        rxIdxList = find(rxPortMap == iUser);        
    end
    numRxAnt = numSTSVec(iUser);
    tdlCirSuNorm = cell(numTxAnt,numRxAnt);
    for iRxA = 1:numRxAnt
        for iTxA = 1:numTxAnt
            if iscell(zpMuTapGain)
                tdlCirStream = zpMuTapGain{iTxA,rxIdxList(iRxA)};
            else
                tdlCirStream = reshape(squeeze(zpMuTapGain(rxIdxList(iRxA),iTxA,:,:)),maxTapLen,[]);
            end
            if normFlag == 0
                tdlCirStrNorm =  tdlCirStream / normFactor;
            elseif normFlag == 1
                tdlCirStrNorm = sqrt(numTxAnt*numSTSTot) * tdlCirStream / normFactor;
            elseif normFlag == 2
                tdlCirStrNorm = sqrt(numTxAnt*numSTSTot) * tdlCirStream / (normFactor*sqrt(numSTSTot));
            else
                error('MIMO normFlag should be 0, 1 or 2.');
            end
            tdlCirSuNorm{iTxA,iRxA} = tdlCirStrNorm;
        end
    end
    tdlCirMuMimo{iUser} = tdlCirSuNorm;
end

end

