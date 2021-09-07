function [precodMat,equiMuChan,powAllo] = getSCMIMOLinearPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
    precAlgoFlag,varargin)
%getSCMIMOLinearPrecoder Get single-carrier time-domain MIMO linear transmit precoder
%
%   [precodMat,equiMuChan,powAllo] = getSCMIMOLinearPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec,precAlgoFlag,
%       precNormFlag,powAlloFlag) performs time-domain MIMO linear precoding for EDMG single-carrier (SC) transmitter.
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
%   precNormFlag is the precoder normalization flag, =0 using total power contraint, =1 using per-user power contraint.
%   powAlloFlag is the power allocation flag.
%   varargin is optional.
%   
%   Outputs:
%   precodMat is a numTxAnt-by-numSTSTot-by-numTaps time-domain multi-user precoding matrix.
%   equiMuChan is the numTxAnt-by-numSTSTot equivalent multi-user MIMO channel impluse response.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector for SC.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(ismember(precAlgoFlag,[0:4]),'precAlgo should be 0, 1, 2, 3 or 4.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
equiMuChan = zeros(numTxAnt,numSTSTot); % Ntx-by-Nsts
powAllo = cell(numUsers,1);

stsNoiseVar = reformatMultiUserNoiseVarianceIndividualStream(noiseVarLin,numSTSVec);

for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    tdOneTapSuMimoChan = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan{iUser},numTxAnt,numSTSVec(iUser));
    if precAlgoFlag == 0
        % Non precoding
        equiMuChan(:,stsIdx) = eye(numSTSVec(iUser));     % Nsdp-by-Ntx-by-Nsts
    else
        % ZF/MMSE/MF precoding
        equiMuChan(:,stsIdx) = conj(tdOneTapSuMimoChan);
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
    precodMat = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'SC',noiseVarLin);
elseif precAlgoFlag == 3
    precodMat = zeros(numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        meanNoiseVar = mean(stsNoiseVar(stsIdx));
        % Channel inversion precoding by zero-forcing or MMSE precoding solution
        precodMat(:,stsIdx) = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'SC',meanNoiseVar,iUser);
    end
elseif precAlgoFlag == 4
    precodMat = zeros(numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        % Channel inversion precoding by zero-forcing or MMSE precoding solution
        precodMat(:,stsIdx) = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'SC',stsNoiseVar,iUser);
    end    
else
end

end
