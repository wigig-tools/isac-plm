function [suPrecodMat,svdHV] = getBlockDiagPrecodingMatrixPerUser(muInterfChanEst,suChanEst)
%getBlockDiagPrecodingMatrixPerUser The block diagonalization aided zero-forcing precoding for multi-user MIMO
%   This function create the block diagonalization aided precoding solution based on the zero-forcing criteria for the
%   multi-user MIMO downlink transmission in either OFDM or SC mode.
%   Inputs:
%       muInterfChanEst is the MU interference estimated channel by nulling the target user's channel matrix. It
%       is a tensor with size of numST-by-numTx-by-numSTSsu in OFDM mode or a matrix with size of numTx-by-numSTSsu 
%       in SC mode.                     
%       suChanEst is the target user's estimated channel. It is a tensor with size of numST-by-numTx-by-numSTSsu in 
%       OFDM mode or a matrix with size of numTx-by-numSTSsu in SC mode.      
%   Outputs:
%       suPrecodMat is the target user's precoding matrix. It is a tensor with size of numST-by-numTx-by-numSTSsu in 
%       OFDM mode or a matrix with size of numTx-by-numSTSsu in SC mode.  
%       svdHV is the target user's SVD structure including the matU, matS and matV as it's members. The members matU and matS 
%       are tensors with size of numST-by-numSTSsu-by-numSTSsu in OFDM mode or square matrices with size of 
%       numSTSsu-by-numSTSsu in SC mode. The member matV is a tensor with size of numST-by-numTx-by-numSTSsu in 
%       OFDM mode or a matrix with size of numTx-by-numSTSsu in SC mode. 
%
%   2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

if size(muInterfChanEst,1) > 8
    % Frequency-domain block diagonalization for OFDM
    [~,~,numRxNull] = size(muInterfChanEst);
    [numST,numTx,numSTSsu] = size(suChanEst);
    muIntfChPerm = permute(muInterfChanEst,[3,2,1]);   % numUsers*Nr-by-Nt-by-Nsdp
    suChanEstPerm = permute(suChanEst,[3,2,1]); % Nr-by-Nt-by-Nsdp

    % Pack the per user CSI into a matrix by getting user STS index
    suPrecodMat = zeros(numST,numTx,numSTSsu); % Nsdp-by-Ntx-by-Nsts
    matU = zeros(numST,numSTSsu,numSTSsu); % Nsdp-by-Nr-by-Nr
    matS = zeros(numST,numSTSsu,numSTSsu); % Nsdp-by-Nr-by-Nr
    matV = zeros(numST,numSTSsu,numSTSsu); % Nsdp-by-Nt-by-Nr
    for iSubc = 1:numST
        muIntChPermSubc = reshape(squeeze(muIntfChPerm(:,:,iSubc)),[numRxNull,numTx]);
        suChPermSubc = reshape(squeeze(suChanEstPerm(:,:,iSubc)),[numSTSsu,numTx]);
        [~, ~, matVIntfSubc] = svd(muIntChPermSubc); % numRxMu-by-numTx
        rankIntfH = rank(muIntChPermSubc);
        matVIntfZeroSubc = matVIntfSubc(:,rankIntfH+1:end);
        matHV_Subc = suChPermSubc * matVIntfZeroSubc;
        [matU_Subc, matS_Subc, matV_Subc] = svd(matHV_Subc(:,:), 'econ');
        suPrecodMat(iSubc,:,:) = reshape(matVIntfZeroSubc * matV_Subc,[1,numTx,numSTSsu]);     % Nsdp-by-Nt-by-Nsts
        matU(iSubc,:,:) = reshape(matU_Subc,[1,numSTSsu,numSTSsu]);     % Nsdp-by-Nsts-by-Nsts
        matS(iSubc,:,:) = reshape(matS_Subc,[1,numSTSsu,numSTSsu]);     % Nsdp-by-Nsts-by-Nsts
        matV(iSubc,:,:) = reshape(matV_Subc,[1,numSTSsu,numSTSsu]);     % Nsdp-by-Nt-by-Nsts
    end
    svdHV.matU = matU;
    svdHV.matS = matS;
    svdHV.matV = matV;
else
    % Time domain block diagonalization for OFDM
    [numTx,numSTSsu] = size(suChanEst);
    muIntfChPerm = permute(muInterfChanEst,[2,1]);   % numUsers*Nr-by-Nt
    suChanEstPerm = permute(suChanEst,[2,1]); % Nr-by-Nt

    % Pack the per user CSI into a matrix by getting user STS index
    [~, ~, matVIntf] = svd(muIntfChPerm); % numRxMu-by-numTx
    rankIntfH = rank(muIntfChPerm);
    matVIntfZero = matVIntf(:,rankIntfH+1:end);
    matHV = suChanEstPerm * matVIntfZero;
    [matU, matS, matV] = svd(matHV(:,:), 'econ');
    suPrecodMat = reshape(matVIntfZero * matV,[numTx,numSTSsu]);     % Nt-by-Nsts
    svdHV.matU = matU;     % Nsts-by-Nsts
    svdHV.matS = matS;     % Nsts-by-Nsts
    svdHV.matV = matV;     % Nt-by-Nsts
end


end
% End of file
