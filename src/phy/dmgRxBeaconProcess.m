function [packetError, syncStart, varargout] = dmgRxBeaconProcess(rxSig, cfgEDMG, varargin)
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
addParameter(p, 'syncMargin', 10)
parse(p, varargin{:});

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

%% Var init
syncMargin = p.Results.syncMargin;
fieldIndices = nist.edmgFieldIndices(cfgEDMG);
nSector  = size(rxSig,2);
golayLen = 128*cfgEDMG.NumContiguousChannels;
chanEst = zeros(golayLen, nSector);
snrEst = zeros(nSector,1);
legacySyncPoint = cell(nSector,1);

%% Loop on beacon sector
for sectorId = 1:nSector
    % Extract Legacy STF
    legacyStf = rxSig(fieldIndices.DMGSTF(1):...
        fieldIndices.DMGSTF(2), sectorId);

    % Estimate Noise variance on STF
    legacyStfVarEst = nist.dmgSTFNoiseEstimate(legacyStf);

    % Extract Legacy preable
    legacyPreamble = rxSig(fieldIndices.DMGSTF(1):...
        fieldIndices.EDMGHeaderA(2),sectorId);

    % Channel estimation on legacy CEF
    [symbolTimingOffset,legacyChanEstFd,legacyChanEstTd] = ...
        edmgTimingAndChannelEstimate(legacyPreamble, 1.76e9, ...
        'margin', syncMargin);

    chanEst(:,sectorId) = legacyChanEstTd;
    snrEst(sectorId) = dmgSnrEstimate(legacyPreamble(symbolTimingOffset+1:end), legacyChanEstTd,cfgEDMG);
    legacySyncPoint{sectorId} = symbolTimingOffset;
end

%% Create output struct
% Legacy
packetError = cellfun(@isempty, legacySyncPoint);
syncStart = legacySyncPoint;
preamble.legacy.stfVarEst = legacyStfVarEst;
preamble.legacy.t0 = legacySyncPoint;
preamble.legacy.chanEstFd = legacyChanEstFd;
preamble.legacy.chanEstTd{1} = chanEst;
preamble.legacy.snr = snrEst;
preamble.legacy.CFO = [];

preamble.edmg.t0 = NaN;
preamble.edmg.chanEst = NaN;
preamble.edmg.snrEst  = NaN;
preamble.edmg.agc = NaN;
preamble.edmg.CFO = NaN;

varargout{1} = preamble;
varargout{2} = rxSig;

end