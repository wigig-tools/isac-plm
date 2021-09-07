function [packetError, syncStart, varargout] = edmgRxPreambleProcess(rxSig, cfgEDMG, varargin)
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
chipRate = 1.76e9;

%% Get packet
[pktStartOffset, rxSyncRate, fs]= edmgPacketDetection(rxSig, syncTh);
rxSigLength = size(rxSyncRate, 1);
preambleLength = fieldIndices.EDMGCEF(2)/(fs/chipRate);

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

%% Packet detected: Fine timing Sync and channel estimation (Legacy)
% Extract Legacy STF
legacyStf = rxSyncRate(pktStartOffset+(fieldIndices.DMGSTF(1):...
    fieldIndices.DMGSTF(2)/(fs/chipRate)), :);

% Estimate Noise variance on STF
legacyStfVarEst = nist.dmgSTFNoiseEstimate(legacyStf);

% If SISO channel estimation on legacy CEF
symbolTimingOffset = 0;
legacyChanEstFd = [];
legacyChanEstTd = [];

if cfgEDMG.NumTransmitAntennas == 1
    legacyPreamble = rxSig(pktStartOffset+fieldIndices.DMGSTF(1):...
        pktStartOffset+fieldIndices.EDMGHeaderA(2),:);
    [symbolTimingOffset,legacyChanEstFd,legacyChanEstTd, ~] = ...
        edmgTimingAndChannelEstimate(legacyPreamble, fs, ...
        'margin', syncMargin);
end

%% Sync and channel estimation (EDMG)
% Advance timing
legacyT0 = pktStartOffset+symbolTimingOffset;

% Extract EDMG-STF
edmgStf = rxSig(legacyT0+(fieldIndices.EDMGSTF(1): ...
    fieldIndices.EDMGSTF(2)), :);

% Sync, AGC, coarse CFO
[edmgT0, edmgAgc, coarseCfo] = edmgSync(edmgStf, cfgEDMG, userIdx);

% If sync point not found
packetError = any(isnan(edmgT0(:)));
if packetError
    warning('EDMG sync error')
    syncStart = nan;
    varargout{1} = [];
    return
end

% Advance timing
syncStart = edmgT0-1 + legacyT0(:)-syncMargin;

% Extract Full preamble
edmg_preamble = rxSig(syncStart+(fieldIndices.EDMGSTF(1):...
    fieldIndices.EDMGCEF(2)), :);

% Fine CFO recovery
[edmg_cef, edmgStf, cfo] = edmgCFORecovery(edmg_preamble, coarseCfo,  cfgEDMG);

% Channel estimation on EDMG-CEF
[edmg_chanEst] = edmgChannelEstimate(edmg_cef, cfgEDMG);

% SNR estimation
edmg_snrEst = edmgSNREstimate(edmgStf,cfgEDMG);

%% Create output struct
% Legacy
preamble.legacy.stfVarEst = legacyStfVarEst;
preamble.legacy.t0 = legacyT0;
preamble.legacy.chanEstFd = legacyChanEstFd;
preamble.legacy.chanEstTd = legacyChanEstTd;
preamble.legacy.CFO = [];

% EDMG
preamble.edmg.t0 = edmgT0;
if ~strcmp(cfgEDMG.PreambleSpatialMappingType, 'Custom')
    preamble.edmg.chanEst = edmg_chanEst;
else
    if strcmp(cfgEDMG.PHYType, 'OFDM')
        preamble.edmg.chanEst = edmg_chanEst(:,:,golayId);
    else
        preamble.edmg.chanEst = edmg_chanEst(:,golayId,:);
    end
end
preamble.edmg.snrEst  = edmg_snrEst;
preamble.edmg.agc = edmgAgc;
preamble.edmg.CFO = cfo;
varargout{1} = preamble;
varargout{2} = rxSig;

end