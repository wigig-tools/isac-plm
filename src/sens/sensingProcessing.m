function [rEst, vEst, aEst, rdaDenoise, varargout] = sensingProcessing(csi,...
    phyParams, sensParams, ftm, codebook)
%%SENSINGPROCESSING Doppler sensing processing.
%
%   [R,V,A,RDA] = SENSINGPROCESSING(CSI, PHY, SENS, FTM)  doppler sensing
%   processing given the CSI, the phy struct PHY, the sensing struct SENS 
%   and the Fine Time Measuremnt (FTM),i.e., the absolute delay of LOS. 
%   Return the estimated range R, the estimated velocity V, the estiamated 
%   angle of the target as well as the range-doppler-angle map RDA. 
%
%   [..., info] = SENSINGPROCESSING(...) return extra info of the doppler
%   processing, e.g., the axis of the RDA map.
%
%   2021-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Params Init
pri = sensParams.pri;
dopplerFftLen =  sensParams.dopplerFftLen;
c = getConst('lightSpeed');
lambda = c/phyParams.fc;
fastTimeLen = size(csi{1},1);
angleLen = size(csi{1},2);
nPri = size(csi,2);
axVelocity = linspace(-1/(4*pri), 1/(4*pri),dopplerFftLen)*lambda;
axFastTime = (0:fastTimeLen-1)*1/phyParams.fs;
nCpi = floor(nPri/sensParams.pulsesCpi);

[nBlks,hopLen] = getBlockStft(sensParams.pulsesCpi,sensParams.windowLen,sensParams.windowOverlap);
DT = sensParams.pulsesCpi./(sensParams.windowLen+hopLen*(0:nBlks-1));
axSlowTimeBlks =  sensParams.pulsesCpi*pri*((1./DT)' + (0:nCpi-1));
axDopFftTime = reshape(axSlowTimeBlks, 1,[]);
axPri = (0:nPri-1)*sensParams.pri;

rd = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks);
rda = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks,angleLen);
rdMask = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks);
rdaMask = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks,angleLen);
rdaThr = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks);
rdaDenoise = zeros(dopplerFftLen,fastTimeLen,nCpi*nBlks,angleLen);

Hmat = reshape(squeeze(cell2mat(csi.')),fastTimeLen, nPri,angleLen);

for a = 1:angleLen % Beam index
    %% Doppler processing
    for i = 1:nCpi % Coherent processing
        % Remove clutters
        csiNoClutter = clutterRemoval(squeeze(Hmat(:,(i-1)*sensParams.pulsesCpi+1:i*sensParams.pulsesCpi,a)).');
        % Get range-doppler map
        [~, rdEstimate] = stft(csiNoClutter, sensParams.window, ...
            sensParams.windowLen, sensParams.windowOverlap, dopplerFftLen, 'dim',1);
        % DC of target is reconstructed with linear interpolation
        rdEstimate(end/2+1,:,:) = abs(rdEstimate(end/2+2,:,:))/2+abs(rdEstimate(end/2,:,:)/2);
        % Process of each STFT block
        for b = 1:nBlks
            rdBlock = abs(rdEstimate(:,:,b));
            rd(:,:,(i-1)*nBlks+b) = rdBlock;
            % Find peaks
            [~,~, id, rdaThrB]=find2DPeaks(rdBlock);
            % Store index
            rdBlock(~id) = 0;
            rdMask(:,:,(i-1)*nBlks+b) = rdBlock;
            rdaThr(:,:,(i-1)*nBlks+b) = rdaThrB;
        end
    end
    rda(:,:,:,a) = rd;
    rdaMask(:,:,:,a) = rdMask;
    rdaDenoise(:,:,:,a) = rdaThr;
end

if angleLen>1
    dopplerFusion = sum(rdaDenoise,4);
    dopplerFusionEstimateMask  =zeros(dopplerFftLen,fastTimeLen,nCpi);
    for j = 1:size(dopplerFusion,3)
        y = dopplerFusion(:,:,j);
        [~,~, id]=find2DPeaks(y);
        y(~id) = 0;
        dopplerFusionEstimateMask(:,:,j) = y;
    end
    rdMask = dopplerFusionEstimateMask;
end

%% Velocity estimation
[vEst, vId] = estimateVelocity(rdMask, axDopFftTime,axVelocity, 'maxVelocity', axVelocity(end));
% Velocity extrapolation (linear)
if isscalar(vEst)
    vEst = vEst*ones(1,nPri-1);
else
    vEst = interp1(axDopFftTime(vId), vEst(vId), axPri(2:end), 'linear', 'extrap');
end

%% Range estimation
syncMargin = phyParams.giLength-round(phyParams.symbOffset*phyParams.giLength);
[rEst, timeOffset, tId] = estimateRange(rdMask, axDopFftTime,axFastTime, syncMargin,ftm);
% Range extrapolation
if isscalar(rEst)
    rEst = rEst*ones(1,nPri);
else
    rEst = interp1(axDopFftTime(tId), rEst(tId), axPri, 'linear', 'extrap');
end

%% Angle Estimation
if angleLen>1
    [aEst,axAngle, idAng] =  estimateAngle(rda, axDopFftTime,...
        codebook, phyParams.packetType);
    % Angle extrapolation
    if size(aEst,1) == 1
        aEst = repmat(aEst, nPri,1);
    else
        aEst = interp1(axDopFftTime(idAng), aEst(idAng,:), axPri, 'linear', 'extrap');
    end
else
    aEst = [];
end

%% Output
info.axVelocity = axVelocity;
info.axFastTime = axFastTime;
info.timeOffset = timeOffset;
info.axDopFftTime = axDopFftTime;
info.axPri = axPri;
if angleLen>1
    info.axAngle = axAngle;
end

varargout{1} = info;
varargout{2} = rda;
 
end
