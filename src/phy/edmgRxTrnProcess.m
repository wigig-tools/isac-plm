function [packetError, syncStart, varargout] = edmgRxTrnProcess(rxSig, cfgEDMG, varargin)
%EDMGPREAMBLEPROCESS process the legacy and EDMG preamble.
%
%   [packet_error, syncStart] = EDMGRXTRNPROCESS(rxSig, cfgEDMG)
%   packet_error = 1 if sync is not successful otherwise packet_error = 0
%   syncStart is the syncronization point
%
%   [packet_error, syncStart, preamble_param] =
%                                    EDMGRXTRNPROCESS(rxSig, cfgEDMG)
%   returns the struct preamble_param including the following information:
%   - Syncronization L-STF
%   - Channel estimation L-CEF
%   - Syncronization EDMG-STF
%   - Channel estimation EDMG-CEF
%
%   [_, TRN] = EDMGRXTRNPROCESS(rxSig, cfgEDMG) returns the struct TRN
%   including quantities estimated in TRN subfields
%   - snr: SNR per TRN subfield
%
%   [packet_error, syncStart] = EDMGRXTRNPROCESS(rxSig, cfgEDMG, 'Name',
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
[edmgT0, ~, ~] = edmgSync(edmgStf, cfgEDMG, userIdx);

edmgT0NotFound = any(isnan(edmgT0(:)));
if edmgT0NotFound
    edmgT0Sync = 1;
else
    edmgT0Sync = edmgT0-1 + fieldIndices.EDMGSYNC(1);
end

[edmgT0Ms, edmgAgc, ~] = edmgMsPPDUSync(rxSyncRate(edmgT0Sync:end), cfgEDMG, userIdx);



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
trnSnrEst = zeros(1,subNum);
ht = zeros(cfgEDMG.SubfieldSeqLength/2+1, subNum);
i = 1;
while i<subNum &&  size(rxSig,1) > syncStart+fieldIndices.TRNSubfields(i,2)
    trnSubf = rxSig(syncStart+ (fieldIndices.TRNSubfields(i,1):fieldIndices.TRNSubfields(i,2)));
    [ht(:,i), snr] = edmgTrnChannelEstimate(trnSubf, cfgEDMG);
    trnSnrEst(i) = snr;
    i = i+1;
end
ht(:, i:end) = [];
trnSnrEst(i:end) = [];
h{1} = ht;

% % SNR estimation
edmgSnrEst = edmgSNREstimate(edmgStf,cfgEDMG);

%% Create output struct
% EDMG
preamble.edmg.t0 = edmgT0;
preamble.edmg.chanEst = h;
preamble.edmg.snrEst  = edmgSnrEst;
preamble.edmg.agc = edmgAgc;
preamble.edmg.CFO = 0;
% TRN
trn.snr = trnSnrEst;
varargout{1} = preamble;
varargout{2} = trn;

end