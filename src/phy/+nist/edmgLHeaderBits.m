function y = edmgLHeaderBits(cfgEDMG)
%edmgLHeaderBits Generate EDMG Header bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgLHeaderBits(CFGEDMG) generates the DMG header bits for Control,
%   Single Carrier and OFDM PHYs. The MCS value in the format configuration
%   object nist.edmgConfig is used to distinguish between EDMG PHYs.
%
%   Y is uint8-typed, column vector of size N-by-1, where N is 40 for
%   Control, and 48 for Single Carrier and OFDM PHY.
%
%   CFGEDMG is the format configuration object of type wlanEDMGConfig which
%   specifies the parameters for the EDMG format.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2020-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% Generate L header bits
headerBits = getHeaderBits(cfgEDMG);
% Generate header check sequence: Std IEEE 802.11ad-2012, Section 21.3.7
hcs = wlan.internal.wlanCRCGenerate(headerBits,16);

% Header bits
y = [headerBits; hcs];

end

function out = getHeaderBits(cfgEDMG)
% Add input userIdx

scramInitBits = nist.edmgScramblerInitializationBits(cfgEDMG);

switch phyType(cfgEDMG)
    case 'Control' % Control PHY header
        % Std IEEE 802.11ad-2012, Table 21-11
        
        % Reserved: bit 0
        b0 = 0;

        % Scrambler Initialization: bit 1-4
        b14 = flip(scramInitBits(4:end)); 

        % Length: bit 5-14
        b514 = de2bi(cfgEDMG.PSDULength,10,'right-msb').';

        % Packet Type: bit 15
        if cfgEDMG.TrainingLength==0
            b15 = 0; % Reserved when TrainingLength is 0
        else
            b15 = double(strcmp(cfgEDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 16-20
        b1620 = de2bi(cfgEDMG.TrainingLength/4,5,'right-msb').';

        % Turnaround: bit 21
        b21 = double(cfgEDMG.Turnaround);

        % Reserved bits: bit 22-23
        b2223 = [0; 0];

        out = int8([b0; b14; b514; b15; b1620; b21; b2223]);
    case 'SC'
        % Std IEEE 802.11ad-2012, Table 21-17
        
        % Scrambler Initialization: bit 0-6
        b06 = flip(scramInitBits);

        % MCS: bit 7-11
        b711 = de2bi(cfgEDMG.MCS(1),5,'right-msb').';

        % Length: bit 12-29
        b1229 = de2bi(cfgEDMG.PSDULength(1,1),18,'right-msb').';

        % Additional PPDU:bit 30
        b30 = 0; % Force to false as signaling an additional PPDU not supported

        % Packet Type: bit 31
        if cfgEDMG.TrainingLength==0
            b31 = 0; % Reserved when TrainingLength is 0
        else
            b31 = double(strcmp(cfgEDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 32-36
%         if cfgEDMG.MsSensing == 0
%             b3236 = de2bi(cfgEDMG.TrainingLength/4,5,'right-msb').';
%         else % Disable
            b3236 = de2bi(0,5,'right-msb').';
%         end

        % Aggregation: bit 37
        b37 = double(cfgEDMG.AggregatedMPDU);

        % Beam Tracking Request: bit 38
        if cfgEDMG.TrainingLength==0
            b38 = 0; % Reserved when TrainingLength is 0
        else
            b38 = double(cfgEDMG.BeamTrackingRequest);
        end

        % Last RSSI: bit 39-42
        b3942 = de2bi(cfgEDMG.LastRSSI,4,'right-msb').';

        % Turnaround: bit 43
        b43 = double(cfgEDMG.Turnaround);

        % Reserved: bit 44-47
        b4447 = [0; 0; 0; 0];

        out = int8([b06; b711; b1229; b30; b31; b3236; b37; b38; b3942; b43; b4447]);
    otherwise % OFDM PHY header
        % Std IEEE 802.11ad-2012, Table 21-13
        
        % Scrambler Initialization: bit 0-6
        b06 = flip(scramInitBits);

        % MCS: bit 7-11
        b711 = de2bi(cfgEDMG.MCS(1),5,'right-msb').';

        % Length: bit 12-29
        b1229 = de2bi(cfgEDMG.PSDULength(1,1),18,'right-msb').'; % Modified to use first column

        % Additional PPDU: bit 30
        b30 = 0; % Force to false as signaling an additional PPDU not supported

        % Packet Type: bit 31
        if cfgEDMG.TrainingLength==0
            b31 = 0; % Reserved when TrainingLength is 0
        else
            b31 = double(strcmp(cfgEDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 32-36
        b3236 = de2bi(0,5,'right-msb').';

        % Aggregation: bit 37
        b37 = double(cfgEDMG.AggregatedMPDU);

        % Beam Tracking Request: bit 38
        if cfgEDMG.TrainingLength==0
            b38 = 0; % Reserved when TrainingLength is 0
        else
            b38 = double(cfgEDMG.BeamTrackingRequest);
        end

        % Tone Pairing Type: bit 39
        if cfgEDMG.MCS(1)>=13 && cfgEDMG.MCS(1)<=17
            b39 = double(strcmp(cfgEDMG.TonePairingType,'Dynamic'));
        else
            b39 = 0; % Reserved if DTP not applicable
        end

        % DTP Indicator: bit 40
        if cfgEDMG.MCS(1)>=13 && cfgEDMG.MCS(1)<=17 && strcmp(cfgEDMG.TonePairingType,'Dynamic')
            b40 = double(cfgEDMG.DTPIndicator);
        else
            b40 = 0; % Reserved if DTP not used or applicable
        end

        % Last RSSI: bit 41-44
        b4144 = de2bi(cfgEDMG.LastRSSI,4,'right-msb').';

        % Last RSSI: bit 45
        b45 = double(cfgEDMG.Turnaround);

        % Reserved: bit 46-47
        b4647 = [0; 0];

        out = int8([b06; b711; b1229; b30; b31; b3236; b37; b38; b39; b40; b4144; b45; b4647]);
end

end
