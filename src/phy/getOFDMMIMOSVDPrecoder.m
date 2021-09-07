function [precodMat,singularMat,postcodMat,equiMuChan,powAllo] = getOFDMMIMOSVDPrecoder(fdMimoChan,noiseVarLin, ...
    numTxAnt,numSTSVec,fftLength,activeSubcIdx,precAlgoFlag,svdFlag,varargin)
%getOFDMMIMOSVDPrecoder Get OFDM frequency-domain MIMO linear transmit precoder based on singular value decomposition
%   
%   [precodMat,singularMat,postcodMat,equiMuChan,powAllo] = getOFDMMIMOSVDPrecoder(fdMimoChan,noiseVarLin,numTxAnt
%      numSTSVec,fftLength,activeSubcIdx,precAlgoFlag,precNormFlag,powAlloFlag,svdFlag) performs frequency-domain MIMO 
%       linear precoding based on singular value decomposition (SVD) for EDMG OFDM transmitter.
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
%   svdFlag is the SVD method flag
%   varargin is optional.
%   
%   Outputs:
%   precodMat is a numActiveSubc-by-numTxAnt-by-numSTSTot frequency-domain multi-user precoding matrix.
%   singularMat is numUsers-length cell array, each cell is a numActiveSubc-by-numSTS-by-numSTS diagonal matrix holding
%       singular value of the user's CFR cell in fdMimoChan.
%   postcodMat is the numUsers-length cell array, each cell is a numActiveSubc-by-numSTS-by-numSTS unity matrix in 
%       which each column is the left singular vector of the user's CFR cell in fdMimoChan on per-subcarrier basis.
%   equiMuChan is the numActiveSubc-by-numTxAnt-by-numSTSTot equivalent multi-user MIMO CFR.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numActiveSubc-by-numSTS matrix.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(fdMimoChan),'fdMimoChan should be a cell array.');
assert(ismember(precAlgoFlag,[0,1,2,3]),'precAlgo should be 0, 1, 2 or 3.');
assert(ismember(svdFlag,[1,2]),'svdFlag should be 1 or 2.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
numActiveSubc = length(activeSubcIdx);
equiMuChan = zeros(numActiveSubc,numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
powAllo = cell(numUsers,1); % Nsdp-by-Nsts
singularMat = cell(numUsers,1);
postcodMat = cell(numUsers,1);

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
    if svdFlag == 1
        % Compute the feedback matrix based on received signal per user
        [matU,matS,matV] = getSUCSISVDFeedback(fdSuMimoChan,'3D');
        % Water filling power allocation
        equiMuChan(:,:,stsIdx) = matV;     % Nsdp-by-Ntx-by-Nsts
        singularMat{iUser} = matS;  % Nsdp-by-Nsts-by-Nsts
        postcodMat{iUser} = matU;   % Nsdp-by-Nsts-by-Nsts
    else    % if svdFlag == 2
        % Compute the feedback matrix based on received signal per user
        [matU,matS,matV] = getSUCSISVDFeedback(fdSuMimoChan,'3D');
        for iSubc = 1:numActiveSubc
            matV_Subc = reshape(squeeze(matV(iSubc,:,:)),[numTxAnt,numSTSVec(iUser)]);
            matS_Subc = reshape(squeeze(matS(iSubc,:,:)),[numSTSVec(iUser),numSTSVec(iUser)]);     % Nsdp-by-Ntx-by-Nsts
            equiMuChan(iSubc,:,stsIdx) = matV_Subc * matS_Subc;
        end
        singularMat{iUser} = matS;  % Nsdp-by-Nsts-by-Nsts
        postcodMat{iUser} = matU;   % Nsdp-by-Nsts-by-Nsts
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
else
    precodMat = equiMuChan;
end


end
