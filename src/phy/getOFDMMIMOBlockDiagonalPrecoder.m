function [precodMat,equiMuChan,powAllo] = getOFDMMIMOBlockDiagonalPrecoder(fdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
    fftLength,activeSubcIdx,precAlgoFlag,varargin)
%getOFDMMIMOBlockDiagonalPrecoder Get OFDM frequency-domain MIMO linear transmit precoder based on block-diagonalization
%   
%   [precodMat,singularMat,postcodMat,equiMuChan,powAllo] = getOFDMMIMOBlockDiagonalPrecoder(fdMimoChan,noiseVarLin,
%      numTxAnt,numSTSVec,fftLength,activeSubcIdx,precAlgoFlag,precNormFlag,powAlloFlag,svdFlag) performs 
%       frequency-domain MIMO linear precoding based on block-diagonalization (BD) for EDMG OFDM transmitter. 
%       The BD method includes zero-forcing algorithm.
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
%   equiMuChan is the numActiveSubc-by-numTxAnt-by-numSTSTot equivalent multi-user MIMO CFR.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numActiveSubc-by-numSTS matrix.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(fdMimoChan),'fdMimoChan should be a cell array.');
assert(ismember(precAlgoFlag,[1,2]),'precAlgoFlag should be 1 or 2.');

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);

% Reformat MU FD CFR
fdMuMimoChan = zeros(size(fdMimoChan{1},1),numTxAnt,numSTSTot);
for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    fdMuMimoChan(:,:,stsIdx) = fdMimoChan{iUser}(:,:,:);
end

numActiveSubc = length(activeSubcIdx);
equiMuChan = zeros(numActiveSubc,numTxAnt,numSTSTot); % Nsdp-by-Ntx-by-Nsts
% muChanEigenVal = zeros(numActiveSubc,numSTSTot); % Nsdp-by-Nsts
powAllo = cell(numUsers,1); % Nsdp-by-Nsts

% stsNoiseVar = reformatMultiUserNoiseVarianceIndividualStream(noiseVarLin,numSTSVec);

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
    if precAlgoFlag == 1
        % BD-ZF precoding
        if size(fdMuMimoChan,1) == numActiveSubc
            fdMuMimoInterfChan = fdMuMimoChan;
        elseif size(fdMuMimoChan,1) == fftLength
            fdMuMimoInterfChan = fdMuMimoChan(activeSubcIdx,:,:);
        else
            error('number of subcarriers of fdMuMimoChan should be either numActiveSubc or fftLength.');
        end
        fdMuMimoInterfChan(:,:,stsIdx) = [];
        [uPrecodMat,uSvdHV] = getBlockDiagPrecodingMatrixPerUser(fdMuMimoInterfChan,fdSuMimoChan);
        equiMuChan(:,:,stsIdx) = uPrecodMat;
%         singularMat{iUser} = uSvdHV.matS;  % Nsdp-by-Nsts-by-Nsts
%         postcodMat{iUser} = uSvdHV.matU;   % Nsdp-by-Nsts-by-Nsts

        % Equal power allocation
        powAllo{iUser} = ones(numSubc,numSTSVec(iUser));
    else
        % BD-MMSE precoding
        error('precAlgoFlag should be 1.');
    end
end

precodMat = equiMuChan;

end
