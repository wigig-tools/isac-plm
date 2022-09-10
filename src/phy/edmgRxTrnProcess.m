function [packetError, syncStart, varargout] = edmgRxTrnProcess(rxSig, cfgEDMG, varargin)
%EDMGPREAMBLEPROCESS process the legacy and EDMG preamble.
%
%   [packet_error, syncStart] = EDMGPREAMBLEPROCESS(rxSig, cfgEDMG)
%   packet_error = 1 if sync is not successful otherwise packet_error = 0
%   syncStart is the syncronization point
%
%   [packet_error, syncStart, preamble_param] =
%                                    EDMGPREAMBLEPROCESS(rxSig, cfgEDMG)
%   returns the struct preamble_param including the following information:
%   - Syncronization L-STF
%   - Channel estimation L-CEF
%   - Syncronization EDMG-STF
%   - Channel estimation EDMG-CEF
%
%
%   [packet_error, syncStart] = edmgPreambleProcess(rxSig, cfgEDMG, 'Name',
%    value, ..)
%   'syncTh': threshold for syncronization
%   'syncMargin': Margin between syncronization and symbol starting point.
%   syncMargin should be set between 0 and GI/CP length%

%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Input processing
p = inputParser;
addParameter(p, 'syncTh', 0.03)
addParameter(p, 'syncMargin', 10)
addParameter(p, 'userIdx', 1)
parse(p, varargin{:});
syncTh = p.Results.syncTh;
syncMargin = p.Results.syncMargin;
userIdx = p.Results.userIdx;

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

%% Var init
numSts = cfgEDMG.NumSpaceTimeStreams;
golayId = sum(numSts(1:userIdx-1))+1:...
    sum(numSts(1:userIdx-1))+ numSts(userIdx);
fieldIndices = nist.edmgFieldIndices(cfgEDMG);

%% Get packet
[pktStartOffset, rxSyncRate]= edmgPacketDetection(rxSig, syncTh);
rxSigLength = size(rxSyncRate, 1);
preambleLength = fieldIndices.EDMGHeaderA(2);
% Sync point not found
if isempty(pktStartOffset)
    warning('EDMG sync error')
    packetError = true;
    syncStart = nan;
    varargout{1} = [];
    return
end

% Length rx signal shorter than preamble lenght
if rxSigLength<pktStartOffset+preambleLength
    warning('Packet too short')
    packetError = true;
    syncStart = nan;
    varargout{1} = [];
    return
end

% t0 = pktStartOffset+preambleLength;


edmgStf = rxSig(pktStartOffset+(fieldIndices.EDMGSTF(1): ...
    fieldIndices.EDMGSTF(2)), :);
[edmgT0, edmgAgc, coarseCfo] = edmgSync(edmgStf, cfgEDMG, userIdx);

edmgT0NotFound = any(isnan(edmgT0(:)));
if edmgT0NotFound
    edmgT0Sync = 1;
else
    edmgT0Sync = edmgT0-1 + fieldIndices.EDMGSYNC(1);
end

[edmgT0Ms, edmgAgc, coarseCfo] = edmgMsPPDUSync(rxSyncRate(edmgT0Sync:end), cfgEDMG, userIdx);



%% Sync and channel estimation (EDMG)
% If sync point not found
packetError = any(isnan(edmgT0Ms));
if packetError
    warning('EDMG sync error')
    syncStart = nan;
    varargout{1} = [];
    varargout{2} = [];
    return
end

% Advance timing
syncStart = edmgT0 - 1 + edmgT0Ms-1 -syncMargin;

subNum = size(fieldIndices.TRNSubfields,1);

i = 1;
while i<subNum &&  size(rxSig,1) > syncStart+fieldIndices.TRNSubfields(i,2)
    trnSubf = rxSig(syncStart+ (fieldIndices.TRNSubfields(i,1):fieldIndices.TRNSubfields(i,2)));
    ht(:,i) = edmgTrnChannelEstimate(trnSubf, cfgEDMG);
    i = i+1;
end
h{1} = ht;

% % SNR estimation
edmg_snrEst = edmgSNREstimate(edmgStf,cfgEDMG);

%% Create output struct
% EDMG
preamble.edmg.t0 = edmgT0;
if ~strcmp(cfgEDMG.PreambleSpatialMappingType, 'Custom')
    preamble.edmg.chanEst = h;
else
    if strcmp(cfgEDMG.PHYType, 'OFDM')
        preamble.edmg.chanEst = edmg_chanEst(:,:,golayId);
    else
        preamble.edmg.chanEst = edmg_chanEst(:,golayId,:);
    end
end
preamble.edmg.snrEst  = edmg_snrEst;
preamble.edmg.agc = edmgAgc;
preamble.edmg.CFO = 0;
varargout{1} = preamble;
varargout{2} = rxSig;

end