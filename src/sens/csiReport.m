function [csiSens, sensInfo] = csiReport(csiSens,phyParams,sensParams)
% CSIREPORT CSI report procedure
%   [CSI_OUT, INFO] = CSIREPORT(CSI_IN, PHY, SENS) return the CSI CSI_OUT
% 	after the report scheme is applied. In case no report is needed
%   CSI_OUT = CSI_IN
%   If report is required, selects the right function to call between
%   adaptiveThresholdReport and fixedThresholdReport

%   2021-2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)

%   This file is available under the terms of the NIST License.

sensInfo = [];
if sensParams.thresholdSensing
    if sensParams.adaptiveThreshold
        % Adaptive threshold-based reporting phase
        [csiThreshold,normCSIVarValue, threshold] = ...
            adaptiveThresholdReport(csiSens,phyParams,sensParams);
    else
        % Fixed threshold-based reporting phase
        [csiThreshold, normCSIVarValue, threshold] = ...
            fixedThresholdReport(csiSens,phyParams,sensParams);
    end
    csiSens = num2cell(csiThreshold.',1);
    sensInfo.normCSIVarValue = normCSIVarValue;
    sensInfo.threshold = threshold;
    sensInfo.adaptiveThreshold = sensParams.adaptiveThreshold;
end
end
