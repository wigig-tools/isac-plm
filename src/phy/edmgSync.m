function [t0, varargout] = edmgSync(edmgSTF, cfgEDMG, userIdx)
%EDMGSYNC EDMG Short Training Field (EDMG-STF) Syncronization
%
%
%   t0 = EDMGSYNC(edmg_stf, ss_id, cfgEDMG) returns the syncronization point
%   for each MIMO stream and the agc value
%
%   edmg_stf is the time-domain  EDMG-STF signal. It is a complex Ns x N_STS
%   matrix where Ns represents the number of time-domain samples and N_STS
%   is the number of received MIMO streams.
%
%   ss_id is the vector 1xN_STS of id numbers of the MIMO streams obtained
%   from header A
%
%   CFGDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   [t0, agc] = EDMGSYNC(edmg_stf, cfgEDMG) returns the automatic
%   gain control for each stram.

%   2019-2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,...
    'EDMG format configuration object');

numSTSVec = cfgEDMG.NumSpaceTimeStreams;
nSTS = numSTSVec(userIdx); % user's number of space-time streams
golayId = sum(numSTSVec(1:userIdx-1))+1:sum(numSTSVec(1:userIdx-1))+nSTS;

nRx = size(edmgSTF, 2);
lenSTF = size(edmgSTF, 1);

lenSeq = 128 * cfgEDMG.NumContiguousChannels;

if strcmpi(cfgEDMG.PHYType, 'OFDM')
    nSeq = 30;
    seq = ones(1,nSeq);
    [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
    STF_grid_idx = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    EDMG_STF_GRID = zeros(ofdmInfo.NFFT,1);
    edmgSTF = sum(edmgSTF,2);
elseif strcmpi(cfgEDMG.PHYType, 'SC')
    nSeq = 19;
    seq = [ones(1,nSeq-1), -1];
    edmgSTF = sum(edmgSTF,2);
end
syncIdVect = nan(1,nSTS);
t0 =  nan(1,nSTS);
agc = nan(1, nSTS);
coarseCFO = nan;
factorThreshold = 0.0004; % detection threshold. Manually tuned
corrGolay = zeros(lenSTF+lenSeq-1, nRx);

%% Generate Ga for the ss_id
% for tx_ant = 1:N_STS
if strcmpi(cfgEDMG.PHYType, 'OFDM')
    for tx_ant = 1:nSTS
        STFSeq = edmgSTFSeq(golayId(tx_ant));
        EDMG_STF_GRID(STF_grid_idx, 1) = STFSeq;
        modOut = wlan.internal.wlanOFDMModulate(EDMG_STF_GRID,0)*...
            ofdmInfo.NFFT/(sqrt(ofdmInfo.NTONES_EDMG_STF*nSTS));
        Ga128c = flip(modOut(1:128));
        corrGolay(:,tx_ant) = conv(edmgSTF,conj(Ga128c));
    end
elseif strcmpi(cfgEDMG.PHYType, 'SC')
    for tx_ant = 1:nSTS
        [Ga128, ~] = nist.edmgGolaySequence(lenSeq, golayId(tx_ant));
        Ga128c = Ga128(end:-1:1);
        corrGolay(:,tx_ant) = conv(edmgSTF,conj(Ga128c));
    end
end
tx_ant =1;
[~, i] = max(max(corrGolay));
corrGolay = corrGolay(:,i);
L = length(corrGolay);

%%
cWind = floor(lenSeq/2)+1;
peakSum = 0;
corrGolayWindow = abs(corrGolay(cWind:cWind+lenSeq-1));
[~, peakId] = max(corrGolayWindow);
peakId = peakId + cWind - 1;
isSyncd = 0;
indx   = 1:nSeq-1;

while peakId <= L-(nSeq-1)*lenSeq+1 && ...
        cWind < length(edmgSTF)-(nSeq-1)*lenSeq+1
    sumPeaksCorr = sum(...
        seq(indx).*corrGolay(peakId+(indx-1)*lenSeq).'.* ...
        seq(indx+1).*conj(corrGolay(peakId+(indx)*lenSeq)).'...
        );
    
    energySymb = mean(abs(edmgSTF(:)).^2);
    energyPeaksCorr = abs(sumPeaksCorr)^2;
    if energyPeaksCorr > ...
            factorThreshold*((lenSeq*lenSeq*(nSeq-1))^2*energySymb^2)
        isSyncd = 1;
        if energyPeaksCorr > peakSum
            peakSum = energyPeaksCorr;
            syncId = peakId;
            cfoEstAngle = angle(sumPeaksCorr);
        end
    else
        isSyncd = 0;
    end
    cWind = cWind+lenSeq;
    corrGolayWindow = abs(corrGolay(cWind:cWind+lenSeq-1));
    [~,peakId] = max(corrGolayWindow);
    peakId = peakId + cWind - 1;
end

if isSyncd
    peak_delta    = lenSeq/2;
    if syncId-peak_delta<1
        syncId=peak_delta+1;
    end
    
    corrGolayN  = corrGolay(syncId-peak_delta+1:syncId+peak_delta);
    syncIdVect(tx_ant)    = syncId;
    agc(tx_ant)  = (lenSeq/nSTS)/abs(corrGolayN(peak_delta));
end
% end
missed = all(isnan(syncIdVect(:)));
if ~missed
    syncIdVect =  syncIdVect(~isnan(syncIdVect(:)))-(lenSeq-1);
    t0 = syncIdVect ;
    coarseCFO = -cfoEstAngle/(2*pi*lenSeq);
end
varargout{1} = agc;
varargout{2} = coarseCFO;

end