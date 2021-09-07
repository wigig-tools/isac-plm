function [precodMat,singularMat,postcodMat,equiMuChan,powAllo] = getSCMIMOSVDPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
    precAlgoFlag,svdFlag,varargin)
%getSCMIMOSVDPrecoder Get single-carrier multi-user MIMO precoder based on singular value decomposition
%
%   [precodMat,singularMat,postcodMat,equiMuChan,powAllo] = getSCMIMOSVDPrecoder(tdMimoChan,noiseVarLin,numTxAnt,
%       numSTSVec,precAlgoFlag,precNormFlag,powAlloFlag,svdFlag) performs time-domain multi-user MIMO precoding 
%       with the aid of singular value decomposition (SVD) for EDMG single-carrier (SC) transmitter.
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
%   svdFlag is the SVD method flag
%   varargin is optional.
%
%   Outputs:
%   precodMat is a numTxAnt-by-numSTSTot time-domain multi-user precoding matrix.
%   singularMat is numUsers-length cell array, each cell is a numSTS-by-numSTS diagonal matrix holding singular value of the user's
%       CIR cell in tdMimoChan.
%   postcodMat is the numUsers-length cell array, each cell is a numSTS-by-numSTS unity matrix in which each column is
%       the left singular vector of the user's CIR cell in tdMimoChan.
%   equiMuChan is the numTxAnt-by-numSTSTot equivalent multi-user MIMO CIR.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector.
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(tdMimoChan),'tdMimoChan should be a cell array.');
assert(ismember(precAlgoFlag,[0,1,2,3]),'precAlgo should be 0, 1, 2 or 3.');
assert(ismember(svdFlag,[1,2]),'precAlgo should be 1 or 2.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
equiMuChan = zeros(numTxAnt,numSTSTot); % Ntx-by-Nsts
powAllo = cell(numUsers,1);
singularMat = cell(numUsers,1);
postcodMat = cell(numUsers,1);

stsNoiseVar = reformatMultiUserNoiseVarianceIndividualStream(noiseVarLin,numSTSVec);

for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    tdOneTapSuMimoChan = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan{iUser},numTxAnt,numSTSVec(iUser));
    if svdFlag == 1
        [matU,matS,matV] = getSUCSISVDFeedback(tdOneTapSuMimoChan,'2D');
        equiMuChan(:,stsIdx) = matV;     % Ntx-by-Nsts
        postcodMat{iUser} = matU;   % Nsts-by-Nsts
        singularMat{iUser} = matS;  % Nsts-by-Nsts
    else    % if svdFlag == 2
        % Compute the feedback matrix based on received signal per user
        [matU,matS,matV] = getSUCSISVDFeedback(tdOneTapSuMimoChan,'2D');
        equiMuChan(:,stsIdx) = matV * matS;
        singularMat{iUser} = matS;  % Nsts-by-Nsts
        postcodMat{iUser} = matU;   % Nsts-by-Nsts
    end

    % Equal power allocation
    powAllo{iUser} = ones(1,numSTSVec(iUser));
end

% Channel inversion precoding by zero-forcing or MMSE precoding solution
if precAlgoFlag == 0
    precodMat = equiMuChan;
elseif precAlgoFlag == 1
    precodMat = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'SC');
elseif precAlgoFlag == 2
    precodMat = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'SC',stsNoiseVar);
else
    precodMat = equiMuChan;
end


end
