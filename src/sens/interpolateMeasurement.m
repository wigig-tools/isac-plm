function csi = interpolateMeasurement(csi, normCSIVarValue, threshold, interpolationScheme, varargin)
%%INTERPOLATEMEASUREMENT interpolates channel measurement 
%
%   [CSI] = INTERPOLATEMEASUREMENT(CSI, CSIVARIATION, THRESHOLD, SCHEME) 
%   interploates channel if the threshold based sensing criteria does not
%   satisfy. Return the interpolated CSI based on the SCHEME.
%   Input: CSI is fastTimeLen*slowTimeLen matrix which contains all channel measurements
%          CSIVARIATION is slowTimeLen*1 vector which contains CSI variation values
%          THRESHOLD defines threshod value for criteria
%          SCHEME defnes the method used for interpolating the measurement if CSIVARIATION< THRESHOLD
%
%   2021-2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)

%   This file is available under the terms of the NIST License.

%% Varargin processing
p = inputParser;

defaultRoh = 0.9;
addOptional(p,'roh',defaultRoh,@isnumeric)
defaultErrorVar = 1e-12;
addOptional(p,'errorVar',defaultErrorVar,@isnumeric)

parse(p,varargin{:})

switch interpolationScheme
    case 'linearInterpolation'
        [indices,~] = find(normCSIVarValue(:)>=threshold);
        for i = 1:length(indices)-1
            csi(indices(i)+1:indices(i+1)-1,1:size(csi,2)) = interp1(indices(i:i+1),csi(indices(i:i+1),1:size(csi,2)),indices(i)+1:indices(i+1)-1,'linear');
        end

    case 'autoRegressive'
        [indices,~] = find(normCSIVarValue(:)>=threshold);
        for i = 1:length(normCSIVarValue)
            if ~ismember(i,indices)
                roh = p.Results.roh;
                errorVar = p.Results.errorVar;
                csi(i,1:size(csi,2)) =  roh * csi(i-1,1:size(csi,2)) + (1-roh) * sqrt(errorVar/2)*(randn+1i*randn);
            else
                csi(i,1:size(csi,2)) =  csi(i,1:size(csi,2));
            end
        end
        
    case 'zeroPadding'
        [indices,~] = find(normCSIVarValue(:)<threshold);
        csi(indices,1:size(csi,2))=0;

    case 'previousMeasuremment'
        [indices,~] = find(normCSIVarValue(:)<threshold);
        csi(indices,1:size(csi,2))=NaN;
        [indices,~] = find(normCSIVarValue(:)>=threshold);
        for i = 1:length(normCSIVarValue)
            if ~ismember(i,indices)
                if size(indices)==1 % If we have only one measurement at the beginning
                    [~,in] = min(abs(i-indices));
                    csi(i,1:size(csi,2)) =  csi(indices(in),1:size(csi,2));
                else
                nearestIndex = interp1(indices, indices, i, 'previous');
                if ~isnan(nearestIndex)
                    csi(i,1:size(csi,2)) =  csi(nearestIndex,1:size(csi,2));
                else
                    [~,in] = min(abs(i-indices));
                    csi(i,1:size(csi,2)) =  csi(indices(in),1:size(csi,2));
                end
                end
            end
        end
end
end