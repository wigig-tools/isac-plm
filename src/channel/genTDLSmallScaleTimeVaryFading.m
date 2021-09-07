function [tapGains, tapIdxs] = genTDLSmallScaleTimeVaryFading(fSamp,tDelay,cGain,fDoppler,numDoppler,tdlLenMax,tdlType,rxPowThresholdLog)
%smallScaleFadingDoppler Generate small scale fading for TDL channel model under time varying channel
%   This function calculates small scale fading for TDL channel model based on multi-path delay profile under
%   time-varying channel
%   
% Inputs:
%   fSamp is a scalar of sampling frequency
%   delay is numMPC-by-1 delay values vector
%   cGain is numMPC-by-1 channel gain values vector
%   fDoppler is numMPC-by-1 Doppler factor values vector
%   numDoppler is the number of Doppler samples
%   tdlLenMax is maximum TDL length allowed, set empty by using original TDL length
%   tdlType is type of TDL, 'Impulse' or 'Sinc'
%   rxPowThresholdLog is the receiver power sensity threshold in dB
%
% Outputs:
%   tapGains is channel gain vector at each TDL taps
%   tapIdxs is delay index vector of each TDL taps

%   2019~2021 NIST/CTL Jian Wang

%   This file is available under the terms of the NIST License.

%codegen

[tauSort, idxSort] = sort(tDelay,1);
campSort = cGain(idxSort);
doppSort = fDoppler(idxSort);

% Remove delay<0 samples to valid path idx in order to cal relative delay
pathIdx = find(tauSort>=0);
    
% Set rx power threshold
if ~isnan(rxPowThresholdLog)
    rxMagThresholdLin = 10.^(rxPowThresholdLog/20);
    pathIdx = find(abs(campSort) > max(abs(campSort))/rxMagThresholdLin); % /10 Cut-off power 20dB down
end

staticGain = campSort(pathIdx);
remainDelay = tauSort(pathIdx);
remainDoppler = doppSort(pathIdx);

% Calculate TDL tap indecies
[tapIdxs, alphaMat] = getTDLTapIndices(fSamp,remainDelay,tdlType);

% Calculate TDL gain
if numDoppler == 1
    tapGains = staticGain.'*alphaMat;
else
    % if ~isvector(camp_r)
    ts = double(0:(numDoppler-1)).' / fSamp; % [Ns, 1]
    timeVaryGain = bsxfun(@times,exp(1i * 2 * pi * bsxfun(@times, ts, remainDoppler.')),staticGain.');
    tapGains = timeVaryGain*alphaMat;
end

% Reset tap length
if ~isempty(tdlLenMax) && tdlLenMax < length(tapGains)
    tapGains(:,tdlLenMax+1:end) = [];
end

tapGains = transpose(tapGains);

end
