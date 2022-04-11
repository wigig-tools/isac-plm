function [rEst, vEst, doppler, varargout] = sensingProcessing(csi, phyParams, sensParams, ftm)
%%SENSINGPROCESSING Doppler sensing processing.
%
%   [R,V] = SENSINGPROCESSING(CSI, PHY, SENS, FTM) perfromance doppler sensing 
%   processing given the CSI, the phy struct PHY, the sensing struct SENS and the Fine Time Measuremnt
%   (FTM),i.e., the absolute delay of LOS. Return the estimated range R and
%   the estimated velocity V of the target.
%
%   [R,V, info] = SENSINGPROCESSING(...) return extra info of the doppler
%   processing, e.g., range-doppler map.
%
%   2021-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Params Init
pri = sensParams.pri;
dopplerFftLen =  sensParams.dopplerFftLen;
c = getConst('lightSpeed');
lambda = c/phyParams.fc;
fastTimeLen = size(csi{1},1);
slowTimeLen = size(csi,2);
velocityGrid = linspace(-1/(2*pri), 1/(2*pri),dopplerFftLen)*lambda;
fastTimeGrid = (0:fastTimeLen-1)*1/phyParams.fs;
nFft = floor(slowTimeLen/sensParams.pulsesCpi);
slowTimeFftGrid = (1:nFft)*sensParams.pulsesCpi*pri;
slowTimeGrid = (0:slowTimeLen-1)*sensParams.pri;
doppler = zeros(dopplerFftLen,fastTimeLen,nFft);
dopplerEstimateMask = zeros(dopplerFftLen,fastTimeLen,nFft);
%% Remove DC
csiNoClutter = clutterRemoval(reshape(squeeze(cell2mat(csi)),fastTimeLen, slowTimeLen).');

%% Pulse Doppler processing
for i = 1:nFft
    % Get range-doppler map
    x = csiNoClutter((i-1)*sensParams.pulsesCpi+1:i*sensParams.pulsesCpi,:);
    dopplerEstimate = stft(x, sensParams.window, ...
        sensParams.windowLen, sensParams.windowOverlap, dopplerFftLen, 'dim',1);
    dopplerEstimate(end/2+1,:) = abs(dopplerEstimate(end/2+2,:))/2+abs(dopplerEstimate(end/2,:)/2);
    doppler(:,:,i) = dopplerEstimate;

    % Find peaks
    [~,~, id]=find2DPeaks(dopplerEstimate);
    
    % Store index
    dopplerEstimate(~id) = 0;
    dopplerEstimateMask(:,:,i) = dopplerEstimate;
end


%% Velocity estimation
vEst = estimateVelocity(dopplerEstimateMask, slowTimeFftGrid,velocityGrid);
% Velocity extrapolation (linear)
vEst = interp1(slowTimeFftGrid, vEst, slowTimeGrid(2:end), 'linear', 'extrap');

%% Range estimation
syncMargin = phyParams.giLength-round(phyParams.symbOffset*phyParams.giLength);
[rEst, timeShift] = estimateRange(dopplerEstimateMask, slowTimeFftGrid,fastTimeGrid, syncMargin,ftm);
% Range extrapolation
rEst = interp1(slowTimeFftGrid, rEst, slowTimeGrid, 'linear', 'extrap')*c;

%% Output
info.velocityGrid = velocityGrid; 
info.fastTimeGrid = fastTimeGrid;
info.timeShift = timeShift;
info.slowTimeFftGrid = slowTimeFftGrid;
info.slowTimeGrid = slowTimeGrid;
%info.ftm = ftm;
% info.vEst = vEst;
% info.rEst = rEst;
% info.nFft = nFft;
% info.pri = pri;
varargout{1} = info;

end