function y = cfar2D(rdm, guardRadius, trainingRadius, threshold)
%% 2D Constant False-Alarm Rate detector
%   RDM = CFAR2D(RDM, G, T, TH) Applies a constant false-alarm rate detector
%   on a 2D dimensional image RDM. For each test cell, the noise is
%   estimated in the surrounding cell of radius T not included in the guard
%   cells of radius G. A target is detected if the power of the cell under
%   test is larger than T dB than the detected noise power in the training
%   region.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

cutIndexStart = trainingRadius+1;
cutIndexEnd = size(rdm)-trainingRadius;
[columnInds, rowInds] = meshgrid(cutIndexStart(2):cutIndexEnd(2),...
    cutIndexStart(1):cutIndexEnd(1));
cutInds = [rowInds(:)  columnInds(:) ];

linIndxTrnRegion = sub2ind(size(rdm),rowInds(:),columnInds(:));
CUTNum = size(cutInds,1);

th = zeros(CUTNum,1);
% noise= zeros(CUTNum,1);
parfor m = 1:CUTNum
    trninds = get2DTrainingInds(rdm,cutInds(m,:),guardRadius,trainingRadius);
    noisePowEst = mean(rdm(trninds));
    th(m,:) = noisePowEst * threshold;
%     noise(m,:) = noisePowEst;
end
y = zeros(size(rdm));
detectionInds = linIndxTrnRegion(reshape(rdm(linIndxTrnRegion),[],1) > th);
y(detectionInds) = rdm(detectionInds);

% figure,subplot(1,2,1), surf(rdm), shading interp,subplot(1,2,2),surf(y), shading interp
end

function trnCellIndx = get2DTrainingInds(X,Idx,guardRadius,trainingRadius)
% Return cell training indexes

GuardRegionSize = 2*guardRadius+1;
TrainingRegionSize = 2*trainingRadius+1;

indxTrnR = linspace(Idx(1)-trainingRadius(1), ...
    Idx(1)+trainingRadius(1),TrainingRegionSize(1));
indxTrnC = linspace(Idx(2)-trainingRadius(2), ...
    Idx(2)+trainingRadius(2),TrainingRegionSize(2));
indxGrdR = linspace(Idx(1)-guardRadius(1), ...
    Idx(1)+guardRadius(1),GuardRegionSize(1));
indxGrdC = linspace(Idx(2)-guardRadius(2), ...
    Idx(2)+guardRadius(2),GuardRegionSize(2));

% Generate the subscripts of the Guard and Training Regions
[subTrnC, subTrnR] = meshgrid(indxTrnC,indxTrnR);
[subGrdC, subGrdR] = meshgrid(indxGrdC,indxGrdR);

% Convert subscripts to linear indices
trnIndx = sub2ind(size(X),subTrnR(:),subTrnC(:));
grdIndx = sub2ind(size(X),subGrdR(:),subGrdC(:));

% Compute indices of training cells, excluding the guard region and
% CUT.
trnCellIndx = setdiff(trnIndx,grdIndx);

end
