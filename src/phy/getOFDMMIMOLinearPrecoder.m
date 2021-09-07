function [precodMat,equiMuChan,powAllo] = getOFDMMIMOLinearPrecoder(fdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
    fftLength,activeSubcIdx,precAlgoFlag,varargin)
%getOFDMMIMOLinearPrecoder Get single-carrier time-domain MIMO linear transmit precoder
%   
%   [precodMat,equiMuChan,powAllo] = getOFDMMIMOLinearPrecoder(fdMimoChan,noiseVarLin,numTxAnt,numSTSVec,fftLength,
%       activeSubcIdx,precAlgoFlag,precNormFlag,powAlloFlag) performs time-domain MIMO linear precoding for EDMG OFDM 
%       transmitter. Precoding algorithms includes linear zero-forcing (ZF), regularzied zero-forcing (RZF), namly 
%       minimum mean square error (MMSE) with white or colored noise in stream-level or user-level.
%
%   Inputs:
%   fdMimoChan is either the numUser-length MU MIMO channel frequency response (CFR) cell array, each entry is a 
%       fftSize-by-numTx-by-numSTS or a numActiveSubc-by-numTx-by-numSTS matrix of single user MIMO CFR. 
%       The numActiveSubc is the number of data and pilot subcarriers.
%   noiseVarLin is the noise variance in linear, which can be in various formats: when noiseVarLin is a numUsers
%       length cell array, each cell holds a numSTS-length noise variance of that user. The numSTS is the number
%       of space-time streams of that user. When noiseVarLin is a numSTSTot-length vector, each element is the 
%       noise variance of the space-time stream of a user. When noiseVarLin is numSTS-by-numUsers matrix, each column
%       vector is the multi-steam noise variance vector of that user.
%   numTxAnt is the number of transmit antennas (RF chains).
%   numSTSVec is a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   fftLength is the length of FFT/IFFT operation
%   activeSubcIdx is the index list of active subcattiers including data and pilots.
%   precAlgoFlag is the precoding algorithm flag, =0 without precoding, =1 using zero-forcing, =2 using MMSE,
%       =3 using MMSE with color noise variance.
%   varargin is optional.
%   
%   Outputs:
%   precodMat is a numActiveSubc-by-numTxAnt-by-numSTSTot frequency-domain multi-user precoding matrix.
%   equiMuChan is the numTxAnt-by-numSTSTot equivalent multi-user MIMO channel impluse response.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector for SC.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(fdMimoChan),'fdMimoChan should be a cell array.');
assert(ismember(precAlgoFlag,[0:4]),'precAlgo should be 0, 1, 2, 3 or 4.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
numActiveSubc = length(activeSubcIdx);
equiMuChan = zeros(numActiveSubc,numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
powAllo = cell(numUsers,1); % Nsdp-by-Nsts

stsNoiseVar = reformatMultiUserNoiseVarianceIndividualStream(noiseVarLin,numSTSVec);

for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    % Get Data and Pilot subcarriers to build FD each user's MIMO channel with active subcarrier
    if size(fdMimoChan{iUser},1) == numActiveSubc
        fdSuMimoChan = fdMimoChan{iUser};
    elseif size(fdMimoChan{iUser},1) == fftLength
        fdSuMimoChan = fdMimoChan{iUser}(activeSubcIdx,:,:); % Nsdp-by-Ntx-by-Nsts
    else
        error('number of subcarriers of fdMimoChan should be either numActiveSubc or fftLength.');
    end
    % Precoding
    if precAlgoFlag == 0
        % Non precoding
        for iSubc = 1:numActiveSubc
            equiMuChan(iSubc,:,stsIdx) = eye(numSTSVec(iUser));     % Nsdp-by-Ntx-by-Nsts
        end
    else
        % ZF/MMSE/MF precoding
        equiMuChan(:,:,stsIdx) = conj(fdSuMimoChan);     % Nsdp-by-Ntx-by-Nsts
    end
    % Equal power allocation
    powAllo{iUser} = ones(numActiveSubc,numSTSVec(iUser));
end

% Channel inversion precoding by zero-forcing or MMSE precoding solution
if precAlgoFlag == 0
    precodMat = equiMuChan;
elseif precAlgoFlag == 1
    precodMat = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'OFDM');
elseif precAlgoFlag == 2
    precodMat = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'OFDM',stsNoiseVar);
elseif precAlgoFlag == 3
    precodMat = zeros(numActiveSubc,numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        meanNoiseVar = mean(stsNoiseVar(stsIdx));
        % Channel inversion precoding by zero-forcing or MMSE precoding solution
        precodMat(:,:,stsIdx) = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'OFDM',meanNoiseVar,iUser);
    end
elseif precAlgoFlag == 4
    precodMat = zeros(numActiveSubc,numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        % Channel inversion precoding by zero-forcing or MMSE precoding solution
        precodMat(:,:,stsIdx) = getTxPrecodeFilterWeight(equiMuChan,numTxAnt,numSTSVec,'OFDM',stsNoiseVar,iUser);
    end
else
end


end

