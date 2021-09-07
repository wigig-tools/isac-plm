function [muPrecoderNorm,normFactor] = normalizeMultiUserPercoderIndividual(muPrecoderIn,numSTSVec,phyType)
%normalizeMultiUserPercoderIndividual Normalize multi-user precoder under individual per-user power contraint
%
%   [muPrecoderNorm] = normalizeMultiUserPercoderIndividual(muPrecoderIn,numSTSVec,phyType) returns normalized 
%       multi-user precoder under per-user power contraint, where each user's precoding sub-matrix in the multi-user 
%       preocding matrix is normalized in terms of the number of spatial streams.
%
%   Inputs:
%   muPrecoderIn is multi-user precoding matrix with different sizes. In the OFDM mode, muPrecoderIn is a 
%       numTxAnt-by-numSTSTot matrix for given subcarrier; or a numActiveSubc-by-numTxAnt-by-numSTSTot
%       for group of active subcarriers including data and pilots. In the SC mode, muPrecoderIn is a 
%       numTxAnt-by-numSTSTot matrix or numTxAnt-by-numSTSTot-by-numTaps matrix.
%   numSTSVec a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   phyType is the physical layer mode string in 'OFDM' or 'SC'.
%
%   Outputs:
%   muPrecoderNorm is the normalized multi-user precoding matrix with the same size as muPrecoderIn
%   normFactor is the numUsers-length cell array of the normalization factors, each cell entry can be a scalar or 
%       a numActiveSubc-length vector.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

numUsers = length(numSTSVec);

if strcmp(phyType,'OFDM')
    if size(muPrecoderIn,1)<=8
        assert(ismatrix(muPrecoderIn),'Check dimention of OFDM precoder.');
        assert(size(muPrecoderIn,2)==sum(numSTSVec),'numSTSTot does not match.');
        [numTxAnt,numSTSTot] = size(muPrecoderIn);
        muPrecoderNorm = zeros(numTxAnt,numSTSTot);
        normFactor = cell(numUsers,1);
        for iUser = 1:numUsers
            stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
            suPrecoder = muPrecoderIn(:,stsIdx);
            normFactor{iUser} = sqrt(numTxAnt)/norm(squeeze(suPrecoder),'fro');
            muPrecoderNorm(:,stsIdx) = suPrecoder*normFactor{iUser};
        end
    elseif size(muPrecoderIn,1)>8
        assert(ndims(muPrecoderIn)==3 || (ismatrix(muPrecoderIn)),'Check dimention of OFDM precoder.');
        assert(size(muPrecoderIn,3)==sum(numSTSVec),'numSTSTot does not match.');
        [numActiveSubc,numTxAnt,numSTSTot] = size(muPrecoderIn);
        muPrecoderNorm = zeros(numActiveSubc,numTxAnt,numSTSTot);
        normFactor = cell(numUsers,1);
        for iUser = 1:numUsers
            stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
            suPrecoder = muPrecoderIn(:,:,stsIdx);
            normFactor{iUser} = zeros(numActiveSubc,1);
            for iSubc = 1:numActiveSubc
                normFactor{iUser}(iSubc) = sqrt(numTxAnt)/norm(squeeze(suPrecoder(iSubc,:,:)),'fro');
                muPrecoderNorm(iSubc,:,stsIdx) = suPrecoder(iSubc,:,:)*normFactor{iUser}(iSubc);
            end
        end
    end
elseif strcmp(phyType,'SC')
    if ismatrix(muPrecoderIn) 
        assert(size(muPrecoderIn,1)<=8,'Check dimention of SC precodeder.');
        assert(size(muPrecoderIn,2)==sum(numSTSVec),'numSTSTot does not match.');
        [numTxAnt,numSTSTot] = size(muPrecoderIn);
        muPrecoderNorm = zeros(numTxAnt,numSTSTot);
        normFactor = cell(numUsers,1);
        for iUser = 1:numUsers
            stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
            suPrecoder = muPrecoderIn(:,stsIdx);
            normFactor{iUser} = sqrt(numTxAnt)/norm(suPrecoder,'fro');
            muPrecoderNorm(:,stsIdx) = suPrecoder*normFactor{iUser};
        end
    elseif ndims(muPrecoderIn)==3
        assert(size(muPrecoderIn,1)<=8,'Check dimention of SC precoder.');
        assert(size(muPrecoderIn,2)==sum(numSTSVec),'numSTSTot does not match.');
        [numTxAnt,numSTSTot,numTaps] = size(muPrecoderIn);
        % Calculate norm by reshaping 3D to 2D and summing up the power of all taps
        muPrecoderNorm = zeros(numTxAnt,numSTSTot,numTaps);
        normFactor = cell(numUsers,1);
        for iUser = 1:numUsers
            stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
            suPrecoder = muPrecoderIn(:,stsIdx,:);
            reshapeQ = reshape(suPrecoder,[numTxAnt*numSTSVec(iUser),numTaps]);
            normFactor{iUser} = sqrt(numTxAnt)/norm(reshapeQ,'fro');
            muPrecoderNorm(:,stsIdx,:) = suPrecoder*normFactor{iUser};
        end
    else
        error('Dimention of SC precoder is incorrect.');
    end
else
    error('phyType should be either OFDM or SC.');
end

end

