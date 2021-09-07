function [precodMat,equiMuChan,powAllo] = getSCMIMOBlockDiagonalPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
    precAlgoFlag,varargin)
%getSCMIMOBlockDiagonalPrecoder Get single-carrier multi-user MIMO precoder based on singular value decomposition
%   
%   [precodMat,equiMuChan,powAllo] = getSCMIMOBlockDiagonalPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec,
%       precAlgoFlag,precNormFlag,powAlloFlag) performs time-domain multi-user MIMO precoding with the aid of 
%       block-diagonalization for EDMG single-carrier (SC) transmitter.
%
%   Inputs:
%   tdMimoChan is a numUsers-length cell array of time-domain MIMO channels. Each cell holds the user's time-domain
%       MIMO channel impluse response (CIR), each entry is a numTxAnt-by-numRxAnt subcell array, which contains the 
%       maxTdlLen-by-1 column vectors. maxTdlLen is the maximum TDL tap length.
%   noiseVarLin is the noise variance in linear, which can be in various formats: when noiseVarLin is a numUsers
%       length cell array, each cell holds a numSTS-length noise variance of that user. The numSTS is the number
%       of space-time streams of that user. When noiseVarLin is a numSTSTot-length vector, each element is the 
%       noise variance of the space-time stream of a user. When noiseVarLin is numSTS-by-numUsers matrix, each column
%       vector is the multi-steam noise variance vector of that user.
%   numTxAnt is the number of transmit antennas (RF chains).
%   numSTSVec is a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   precAlgoFlag is the precoding algorithm flag, =0 without precoding, =1 using zero-forcing, =2 using MMSE,
%       =3 using MMSE with color noise variance.
%   varargin is optional.
%
%   Outputs:
%   precodMat is a numTxAnt-by-numSTSTot time-domain multi-user precoding matrix.
%   equiMuChan is the numTxAnt-by-numSTSTot equivalent multi-user MIMO channel impluse response.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector for SC.
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(tdMimoChan),'tdMimoChan should be a cell array.');
assert(ismember(precAlgoFlag,[1,2]),'precAlgo should be 1 or 2.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
equiMuChan = zeros(numTxAnt,numSTSTot); % Ntx-by-Nsts
% muChanEigenVal = zeros(1,numSTSTot); % 1-by-Nsts
powAllo = cell(numUsers,1);

tdOneTapMuMimoChan = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan,numTxAnt,numSTSVec);

for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    tdOneTapSuMimoChan = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan{iUser},numTxAnt,numSTSVec(iUser));
    % Precoding
    if precAlgoFlag == 1
        % BD-ZF precoding
        tdOneTapMuMimoInterfChan = tdOneTapMuMimoChan;
        tdOneTapMuMimoInterfChan(:,stsIdx) = [];
        [uPrecodMat,uSvdHV] = getBlockDiagPrecodingMatrixPerUser(tdOneTapMuMimoInterfChan,tdOneTapSuMimoChan);
        equiMuChan(:,stsIdx) = uPrecodMat;   % Ntx-by-Nsts
        
        % Equal power allocation
        powAllo{iUser} = ones(1,numSTSVec(iUser));
    else
        % BD-MMSE precoding
        error('precAlgoFlag should be 1.');
    end
end

precodMat = equiMuChan;

end
