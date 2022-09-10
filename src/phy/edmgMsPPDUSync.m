function [t0, varargout] = edmgMsPPDUSync(edmgSTF, cfgEDMG, userIdx)
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

%   2022 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.


validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,...
    'EDMG format configuration object');


lenSeq = cfgEDMG.SubfieldSeqLength * cfgEDMG.NumContiguousChannels;


nSeq = 9;
seq = [ones(1,nSeq-1), -1];

syncId = nan;
t0 =  nan;
agc = nan;
coarseCFO = nan;
factorThreshold = 1e4; % detection threshold. Manually tuned

%% Generate Ga 
[Ga, ~] = getGolaySta(cfgEDMG, userIdx);
corrGolay = conv(edmgSTF, conj(Ga(end:-1:1)));
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

    xcn0 = seq(indx).*(corrGolay(peakId+(indx-1)*lenSeq).');
    xcn1 = (seq(indx+1).*conj(corrGolay(peakId+(indx)*lenSeq)).');
    sumPeaksCorr = xcn0*xcn1.';
    energySymb = sum(abs(edmgSTF(cWind:cWind+(nSeq-1)*lenSeq-1)).^2);
    energyPeaksCorr = abs(sumPeaksCorr)^2;
    if energyPeaksCorr > (factorThreshold*energySymb^2)
        isSyncd = 1;
        if energyPeaksCorr > peakSum
            peakSum = energyPeaksCorr;
            syncId = peakId;
            cfoEstAngle = angle(sumPeaksCorr);
        end
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
    agc  = lenSeq/abs(corrGolayN(peak_delta));
end
% end
missed = isnan(syncId);
if ~missed
    t0 = syncId -(lenSeq-1);
    coarseCFO = -cfoEstAngle/(2*pi*lenSeq);
end
varargout{1} = agc;
varargout{2} = coarseCFO;

end