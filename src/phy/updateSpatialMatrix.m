function phyParams = updateSpatialMatrix(phyParams,spatialMapMat,svdChan,powAlloMat,precScaleFactor)
%%UPDATESPATIALMATRIX return the updated spatial matrix
%
%   PHYSTRUCT = UPDATESPATIALMATRIX(PHYSTRUCT, ...)
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

phyParams.cfgEDMG.PreambleSpatialMappingType = phyParams.smTypeDP;
phyParams.cfgEDMG.SpatialMappingMatrix = spatialMapMat;
phyParams.spatialMapMat = spatialMapMat;
phyParams.svdChan = svdChan;
phyParams.powAlloMat = powAlloMat;
phyParams.precScaleFactor = precScaleFactor;

end