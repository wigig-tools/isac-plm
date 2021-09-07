function [muPrecoderOut] = applyPowerAllocationToMUPrecoder(powAllo,muPrecoderIn,numSTSVec,phyType)
%applyPowerAllocationToMUPrecoder Apply the power allocation to multi-user precoder
%   
%   [muPrecoderOut] = applyPowerAllocationToMUPrecoder(powAllo,muPrecoderIn,numSTSVec,phyType) applys the stream-level
%       or user-level power allocation to multi-user precoder
%
%   Inputs:
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numActiveSubc-by-numSTS matrix 
%       for OFDM or a numSTS-length row vector for SC.
%   muPrecoderIn is a numActiveSubc-by-numTxAnt-by-numSTSTot multi-user precoding matrix for OFDM or a 
%       numTxAnt-by-numSTSTot multi-user precoding matrix for SC.
%   numSTSVec is a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   phyType is the physical layer mode string in 'OFDM' or 'SC'.
%
%   Output:
%   muPrecoderOut the multi-user precoding matrix after applying power allocation, having the same size as muPrecoderIn.

%   2020~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell((powAllo)) && length(powAllo)==length(numSTSVec),'Check dimention of powAllo.');
numUsers = length(numSTSVec);

% Apply power allocation
if strcmp(phyType,'OFDM')
    assert(ndims(muPrecoderIn)==3 || (ismatrix(muPrecoderIn) && size(muPrecoderIn,1)>8),'Check dimention of OFDM precoder.');
    [numActiveSubc,numTxAnt,numSTSTot] = size(muPrecoderIn);
    muPrecoderOut = zeros(numActiveSubc,numTxAnt,numSTSTot);
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        for iSubc = 1:numActiveSubc
            suSubcPrecoder = reshape(squeeze(muPrecoderIn(iSubc,:,stsIdx)),numTxAnt,numSTSVec(iUser));
            powMat = sqrt(diag(squeeze(powAllo{iUser}(iSubc,:)))); 
            muPrecoderOut(iSubc,:,stsIdx) = suSubcPrecoder * sqrt(powMat);
        end
    end
elseif strcmp(phyType,'SC')
    assert(ismatrix(muPrecoderIn) && size(muPrecoderIn,1)<=8,'Check dimention of SC precodeder.');
    [numTxAnt,numSTSTot] = size(muPrecoderIn);
    muPrecoderOut = zeros(numTxAnt,numSTSTot);
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        suPrecoder = reshape(muPrecoderIn(:,stsIdx),numTxAnt,numSTSVec(iUser));
        powMat = sqrt(diag(powAllo{iUser}(1,:))); 
        muPrecoderOut(:,stsIdx) = suPrecoder * sqrt(powMat);
    end
else
    error('phyType should be either OFDM or SC.');
end

end

