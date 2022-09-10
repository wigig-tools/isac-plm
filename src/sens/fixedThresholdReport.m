function [csi, normCSIVarValue, threshold] = fixedThresholdReport(csi, phyParams, sensParams)
%%THRESHOLDSENSING threshold based sensing procedure.
%
%   [CSI] = THRESHOLDSENSING(CSI, PHY, SENS) performs threshold based sensing 
%   given the CSI, the phy struct PHY, and the sensing struct SENS. 
%   Return the interpolated CSI based on the threshold.
%
%
%   2021-2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)

%   This file is available under the terms of the NIST License.

fastTimeLen = size(csi{1},1);
slowTimeLen = size(csi,2);
csi = reshape(squeeze(cell2mat(csi)),fastTimeLen, slowTimeLen).';

fastTimeGrid = (0:fastTimeLen-1)*1/phyParams.fs;
ts = fastTimeGrid;

%% Calculate CSI variation
normCSIVarValue = zeros(fastTimeLen,1);
for tau = 1:slowTimeLen
    if tau == 1
        normCSIVarValue(tau,:) = 1; 
    else        
        normCSIVarValue(tau,:) = csiVariation(csi(tau,:),csi(tau-1,:),ts,...
            sensParams.csiVariationScheme,phyParams);
    end
end
threshold = sensParams.threshold*ones(length(normCSIVarValue),1);

%% Interpolate measurement if there is no feedback due to thresholding
csi = interpolateMeasurement(csi,normCSIVarValue,sensParams.threshold,sensParams.interpolationScheme);

end
