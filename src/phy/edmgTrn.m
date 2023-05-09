function [y,TRN_SUBFIELD] = edmgTrn(cfgEDMG)
%%EDMGTRN EDMG TRN field
%
%   Y = EDMGMSSYNC(CFGEDMG) generates the The TRN field structure
%   of EDMG BRP-TX PPDUs, of EDMG BRP-RX/TX PPDUs, of of EDMG BRP-RX PPDUs
%   and of EDMF Multi Static Sensing PPDU as 28.9.2.2.5
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig
%   specifies the parameters for the EDMG format.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},...
    mfilename,'EDMG format configuration object');

[P, N_TRN] = edmgCEConfig(cfgEDMG);

N_CB = cfgEDMG.NumContiguousChannels;
NUM_TX_CHAINS = cfgEDMG.NumTransmitAntennas;

%% Analyze TRN Subfields
TRN_BL = cfgEDMG.SubfieldSeqLength; 
if strcmp(cfgEDMG.PacketType, 'TRN-R')
    N_SUBFIELD = 10;
elseif strcmp(cfgEDMG.PacketType, 'TRN-T')
    N_SUBFIELD =cfgEDMG.UnitP + cfgEDMG.UnitM+1;
elseif strcmp(cfgEDMG.PacketType, 'TRN-TR')
    N_SUBFIELD = (cfgEDMG.UnitP + cfgEDMG.UnitM+1)*(cfgEDMG.UnitRxPerUnitTx+1);
end
EDMG_TRN_LENGTH =cfgEDMG.TrainingLength;

N_SUBFIELD = N_SUBFIELD*EDMG_TRN_LENGTH;
TRN_BASIC_LENGTH = TRN_BL * N_CB * 6;
TRN_SUBFIELD_LENGTH =  TRN_BASIC_LENGTH * N_TRN;    % The length of TRN Subfield.
TRN_SUBFIELD = zeros(TRN_BL * N_CB * 6,  N_TRN);
TRN_UNIT = zeros(TRN_SUBFIELD_LENGTH * N_SUBFIELD, NUM_TX_CHAINS);


for iTx = 1:NUM_TX_CHAINS
    % Get Ga, Gb
    [Ga, Gb] = nist.edmgGolaySequence(TRN_BL * N_CB, iTx);
    % Generate TRN_Basic.
    TRN_BASIC = [Ga; -Gb; Ga; Gb; Ga; -Gb];
    % Generate TRN Subfield.
    for n = 1:N_TRN
        TRN_SUBFIELD(:,n) = P(iTx, n) * TRN_BASIC;
    end
    % Generate TRN Field.
    TRN_UNIT(:, iTx) = repmat(TRN_SUBFIELD(:), N_SUBFIELD, 1);

end

y =  TRN_UNIT; 