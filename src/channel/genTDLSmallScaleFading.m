function [tapGains, tapIdxs] = genTDLSmallScaleFading(fSamp,tDelay,cGain,tdlLenMax,tdlType,rxPowThresholdLog)
%genTDLSmallScaleFading Generate small-scale fading for TDL channel model
%   This function calculates small scale fading for TDL channel model based on multi-path delay profile
%
% Inputs:
%   fSamp is a scalar of sampling frequency
%   delay is numMPC-by-1 delay values vector
%   cGain is numMPC-by-1 channel gain values vector
%   tdlLenMax is maximum TDL length allowed, set empty by using original TDL length
%   tdlType is type of TDL, 'Impulse' or 'Sinc'
%   rxPowThresholdLog is the receiver power sensity threshold in dB
%
% Outputs:
%   tapGains is tdlLen-by-1 or tdlLenMax-by-1 channel gain vector
%   tapIdxs is tdlLen-length or tdlLenMax-length delay index vector

%   2019~2021 NIST/CTL Jian Wang

%   This file is available under the terms of the NIST License.

%codegen

assert(isvector(tDelay)&&isvector(cGain),'tDelay and cGain should be vectors.')
[tauSort, idxSort] = sort(tDelay,1);
campSort = cGain(idxSort);

% Remove delay<0 samples to valid path idx in order to cal relative delay
pathIdx = find(tauSort>=0);

% Set rx power threshold
if ~isnan(rxPowThresholdLog)
    rxMagThresholdLin = 10.^(rxPowThresholdLog/20);
    pathIdx = find(abs(campSort) > max(abs(campSort))/rxMagThresholdLin); % /10 Cut-off power 20dB down
end

staticGain = campSort(pathIdx);
remainDelay = tauSort(pathIdx);

% Calculate TDL tap indecies
[tapIdxs, alphaMat] = getTDLTapIndices(fSamp,remainDelay,tdlType);

% Calculate TDL gain
tapGains = staticGain.'*alphaMat;

% Reset tap length
if ~isempty(tdlLenMax) && tdlLenMax < length(tapGains)
    tapGains(:,tdlLenMax+1:end) = [];
end

tapGains = transpose(tapGains);

end
