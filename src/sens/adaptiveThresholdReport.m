function [csiThreshold,normCSIVar,threshold]  = adaptiveThresholdReport(csi,phyParams,sensParams)
%%ADAPTIVETHRESHOLD adaptive threshold for threshold based sensing.
%
%   [CSI, CSIVAR, THRESHOLD] = ADAPTIVETHRESHOLDREPORT(CSI, PHY, SENS) calculates 
%   adaptive threshold for threshold based sensing given the CSI, the phy 
%   struct PHY, and the sensing struct SENS. 
%   Return (i) the interpolated CSI based on the adaptive threshold.
%          (ii) normalized CSI variation values
%          (iii) Adaptive threshold values 
%
%   2021-2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)

%   This file is available under the terms of the NIST License.


dopplerFftLen =  sensParams.dopplerFftLen;
fastTimeLen = size(csi{1},1);
slowTimeLen = size(csi,2);
fastTimeGrid = (0:fastTimeLen-1)*1/phyParams.fs;
csiThreshold = [];
normCSIVar = [];
threshold = [];
dtLen = floor(slowTimeLen/sensParams.numTimeDivisions);
nFft = floor(dtLen/sensParams.pulsesCpi);
if dtLen < sensParams.pulsesCpi
    error('Not enough packet to compute Doppler FFT with required pulses per CPI');
end
doppler = zeros(dopplerFftLen,fastTimeLen,nFft);

for j = 1:dtLen:slowTimeLen

    if slowTimeLen > j+dtLen-1
        csiPartial = reshape(squeeze(cell2mat(csi(j:j+dtLen-1))),fastTimeLen, dtLen).';
        normCSIVarValue = nan(dtLen,1);
        for tau = 1:dtLen
            if tau == 1
                normCSIVarValue(tau,:) = 1;
            else
                normCSIVarValue(tau,:) = csiVariation(csiPartial(tau,:),csiPartial(tau-1,:),fastTimeGrid,sensParams.csiVariationScheme,phyParams);
            end
        end
        csiNoClutter = interpolateMeasurement(csiPartial,normCSIVarValue,sensParams.threshold,sensParams.interpolationScheme);
        % Peak detection using the interepolated CSI measuerements
        peak = [];
        for i = 1:nFft
            % Get range-doppler map
            x = csiNoClutter((i-1)*sensParams.pulsesCpi+1:i*sensParams.pulsesCpi,:);
            dopplerEstimate = stft(x, sensParams.window, ...
                sensParams.windowLen, sensParams.windowOverlap, dopplerFftLen, 'dim',1);
            dopplerEstimate(end/2+1,:) = abs(dopplerEstimate(end/2+2,:))/2+abs(dopplerEstimate(end/2,:)/2);
            doppler(:,:,i) = dopplerEstimate;
    
            % Find peaks
            [peaks,~,~]=find2DPeaks(dopplerEstimate);
            peak = [peak; peaks];
        end
        threshold = [threshold; sensParams.threshold*ones(dtLen,1)];
        % Calculate percent of feedback for adapting the threshold
        percentFeedback = length(find(normCSIVarValue>=sensParams.threshold))*100/dtLen;
        % Adaptive thresholding
        if ~isempty(peak)
            if percentFeedback > sensParams.percentMeasurement
                sensParams.threshold = sensParams.threshold + sensParams.stepThreshold;
            else
                sensParams.threshold = sensParams.threshold - sensParams.stepThreshold;
                if sensParams.threshold<0
                    sensParams.threshold = 0;
                end
    
            end
    
        else
            sensParams.threshold = sensParams.threshold + sensParams.stepThreshold;
            if sensParams.threshold > 1
                sensParams.threshold = 1;
            end
        end
    
    
    else
        % For last remaining CSI measurements 
        csiPartial = reshape(squeeze(cell2mat(csi(j:slowTimeLen))),fastTimeLen, length(j:slowTimeLen)).';
        normCSIVarValue = nan(length(j:slowTimeLen),1);
        for tau = 1:length(j:slowTimeLen)
            if tau == 1
                normCSIVarValue(tau,:) = 1;
            else
                normCSIVarValue(tau,:) = csiVariation(csiPartial(tau,:),csiPartial(tau-1,:),fastTimeGrid,sensParams.csiVariationScheme,phyParams);
            end
        end
        csiNoClutter = interpolateMeasurement(csiPartial,normCSIVarValue,sensParams.threshold,sensParams.interpolationScheme);
        threshold = [threshold; sensParams.threshold*ones(length(j:slowTimeLen),1)];
    end
    csiThreshold = [csiThreshold; csiNoClutter];
    normCSIVar = [normCSIVar; normCSIVarValue];

end
end
