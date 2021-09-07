function [muPrecoderNorm,normFactor] = normalizeMultiUserPercoderJoint(muPrecoderIn,numSTSTot,phyType)
%normalizeMultiUserPercoderJoint Normalize multi-user precoder under joint multi-user total power contraint
%
%   [muPrecoderNorm] = normalizeMultiUserPercoderJoint(muPrecoderIn,numSTSVec,phyType) returns normalized 
%       multi-user precoder under joint total power contraint, where the multi-user preocding matrix is normalized 
%       in terms of the total number of spatial streams.
%
%   Inputs:
%   muPrecoderIn is multi-user precoding matrix with different sizes. In the OFDM mode, muPrecoderIn is a 
%       numTxAnt-by-numSTSTot matrix for given subcarrier; or a numActiveSubc-by-numTxAnt-by-numSTSTot
%       for group of active subcarriers including data and pilots. In the SC mode, muPrecoderIn is a 
%       numTxAnt-by-numSTSTot matrix or numTxAnt-by-numSTSTot-by-numTaps matrix.
%   numSTSTot is the total number of space-time streams among all users.
%   phyType is the physical layer mode string in 'OFDM' or 'SC'.
%
%   Outputs:
%   muPrecoderNorm is the normalized multi-user precoding matrix with the same size as muPrecoderIn
%   normFactor is the normalization factor, it can be a scalar or a numActiveSubc-length vector.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if strcmp(phyType,'OFDM')
    if size(muPrecoderIn,1)<=8
        assert(ismatrix(muPrecoderIn),'Check dimention of OFDM precoder.');
        assert(size(muPrecoderIn,2)==numSTSTot,'numSTSTot does not match.');
        [numTxAnt,numSTSTot] = size(muPrecoderIn);
%         normFactor = sqrt(numSTSTot)/norm(muPrecoderIn,'fro');
        normFactor = sqrt(numTxAnt)/norm(muPrecoderIn,'fro');
        muPrecoderNorm = muPrecoderIn*normFactor;
    elseif size(muPrecoderIn,1)>8
        assert(ndims(muPrecoderIn)==3 || (ismatrix(muPrecoderIn)),'Check dimention of OFDM precoder.');
        assert(size(muPrecoderIn,3)==numSTSTot,'numSTSTot does not match.');
        [numActiveSubc,numTxAnt,numSTSTot] = size(muPrecoderIn);
        muPrecoderNorm = zeros(numActiveSubc,numTxAnt,numSTSTot);
        normFactor = zeros(numActiveSubc,1);
        for iSubc = 1:numActiveSubc
            normFactor(iSubc) = sqrt(numTxAnt)/norm(squeeze(muPrecoderIn(iSubc,:,:)),'fro');
            muPrecoderNorm(iSubc,:,:) = muPrecoderIn(iSubc,:,:)*normFactor(iSubc);
        end
    end
elseif strcmp(phyType,'SC')
    if ismatrix(muPrecoderIn)
        assert(size(muPrecoderIn,1)<=8,'Check dimention of SC precoder.');
        assert(size(muPrecoderIn,2)==numSTSTot,'numSTSTot does not match.');
        [numTxAnt,numSTSTot] = size(muPrecoderIn);
        normFactor = sqrt(numTxAnt)/norm(muPrecoderIn,'fro');
        muPrecoderNorm = muPrecoderIn*normFactor;
    elseif ndims(muPrecoderIn)==3
        assert(size(muPrecoderIn,1)<=8,'Check dimention of SC precoder.');
        assert(size(muPrecoderIn,2)==numSTSTot,'numSTSTot does not match.');
        [numTxAnt,numSTSTot,numTaps] = size(muPrecoderIn);
        % Calculate norm by reshaping 3D to 2D and summing up the power of all taps
        reshapeQ = reshape(muPrecoderIn,[numTxAnt*numSTSTot,numTaps]);
        normFactor = sqrt(numTxAnt)/norm(reshapeQ,'fro');
        muPrecoderNorm = muPrecoderIn*normFactor;
    else
        error('Dimention of SC precoder is incorrect.');
    end
else
    error('phyType should be either OFDM or SC.');
end

end

