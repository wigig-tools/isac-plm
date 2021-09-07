function y = edmgHeaderBBits(cfgEDMG,userIdx)
%edmgHeaderBBits Generate EDMG Header-B bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgHeaderBBits(CFGEDMG) generates the DMG header bits for Control,
%   Single Carrier and OFDM PHYs. The MCS value in the format configuration
%   object nist.edmgConfig is used to distinguish between EDMG PHYs.
%
%   Y is uint8-typed, column vector of size N-by-1, where N is 40 for
%   Control, and 48 for Single Carrier and OFDM PHY.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

assert(~strcmp(phyType(cfgEDMG),'Control'),'phyTpye should be OFDM or SC, should not be Control.');

% Generate EDMG Header B bits
headerBits = getHeaderBits(cfgEDMG,userIdx); % Add input userIdx

% Generate header check sequence: Std IEEE 802.11-2016, Section 20.3.7
hcs = wlan.internal.wlanCRCGenerate(headerBits,16);

% Header bits
y = [headerBits; hcs];

end

function out = getHeaderBits(cfgEDMG,userIdx)
% Per user basis

    scramInitBits = nist.edmgScramblerInitializationBits(cfgEDMG,userIdx);

    % SC/OFDM EDMG-Header-B
    % Std IEEE 802.11ay-D5.0, Table 28-19

    % Scrambler Initialization: bit 0-6
    b06 = flip(scramInitBits);

    % Length: bit 7-28
    % Length of the PSDU field in octets in the range 1 – 4 194 303.
    b728 = de2bi(cfgEDMG.PSDULength(1,userIdx),22,'right-msb').';

    % Base MCS: bit 29-33
    % Generated from TXVECTOR parameter EDMG_MCS. Indicates the lowest index of the modulation and coding scheme that 
    % is used to define the modulation and coding scheme of the spatial streams.
    b2933 = de2bi(cfgEDMG.MCS(userIdx),5,'right-msb').';

    % Differential Base MCS: bit 34-35
    % Generated from TXVECTOR parameter EDMG_MCS.
    % The Base MCS field defines the modulation and coding scheme for the spatial stream 1.
    % The Differential EDMG-MCS field defines a possible modulation level change for the spatial stream 2 relative to the modulation level of spatial stream 1. The rules for setting the Differential EDMG-MCS field are defined in Table 28-15 and Table 28-16 for the EDMG SC and the EDMG OFDM modes, respectively.
    % All spatial streams have the same code rate defined by the Base MCS field.
    % If the number of spatial streams is 1 (per user), then the Differential EDMG-MCS field is reserved.
    b3435 = [0; 0];         % place holder

    % Superimposed Code Applied, Std IEEE 802.11ay-D5.0,  Table 28-12
    % If the LDPC code rate is 7/8 and this field is set to 0, it indicates puncturing code with codeword length 
    % 624 or 1248 is applied (see 28.5.9.4.3 and 28.6.9.2.3).
    % If the LDPC code rate is 7/8 and this field is set to 1, it indicates that superimposed code with codeword 
    % length 672 or 1344 is applied (see 28.3.6.2 and 28.3.6.7).
    % If the EDMG-MCS field indicates a value of 13 and the π/2-8-PSK Applied field is 1, then this field 
    % indicates the 7/8 code employed in the encoding procedure with codeword shortening to achieve the 
    % effective code rate of 5/6 as defined in 28.5.9.4.3.
    % In all other cases, this field is reserved.
    b36 = 0;    % place holder

    % Short/Long LDPC
    % Corresponds to the TXVECTOR parameter LDPC_CW_LENGTH. Indicates the LDPC codeword length used in the PSDU. 
    % Set to 0 for LDPC codeword of length 672, 624, 504, or 468. Set to 1 for LDPC codeword of length 1344, 1248, 
    % 1008, or 936.
    b37 = 0;    % place holder

    % STBC Applied
    % Corresponds to the TXVECTOR parameter STBC. If set to 1, indicates that STBC was applied at the transmitter. 
    % Otherwise, set to 0.
    % If set to 1, the DCM BPSK Applied and the Phase Hopping fields shall be set to 0.
    b38 = 0;

    % NUC Applied
    % Corresponds to the TXVECTOR parameter NUC_MOD. If this field is set to 1, π/2-64-NUC is applied at the 
    % transmitter for the MCSs indicated by the Base MCS and Differential EDMG-MCS fields, if supported. If an 
    % indicated MCS does not support π/2-64-NUC, then π/2-64-QAM uniform constellation is applied for this 
    % particular MCS.
    % If set to 0, π/2-64-QAM uniform constellation is applied for MCSs signalled in the Base MCS and Differential 
    % EDMG-MCS fields.
    b39 = 0;

    % π/2-8-PSK Applied
    % Corresponds to TXVECTOR parameter PSK_APPLIED. If this field is set to 1, π/2-8-PSK with corresponding LDPC 
    % shortening code with rates 2/3 or 5/6 is applied at the transmitter for MCS 12 or 13, respectively, as 
    % indicated within the EDMG-MCS field.
    % If set to 0, π/2-16-QAM constellation with regular LDPC code with rates ½ or 5/8 is applied at the 
    % transmitter for MCS 12 or 13, respectively, as indicated in the EDMG-MCS field.
    b40 = 0;

    % Spoofing Error Length Indicator
    % If set to 0 in an EDMG OFDM PPDU, indicates that the spoofing error, defined as the difference between the 
    % PPDU duration calculated based on L-Header and the actual PPDU duration, is smaller than TOFDM-SYM, where 
    % TOFDM-SYM = TDFT + TGI, TDFT is the OFDM IDFT/DFT period and TGI is the guard interval duration, which is 
    % determined by bits B2 and B3 of the Last RSSI field within the L-Header of the PPDU. Otherwise, if set to 1 
    % in an EDMG OFDM PPDU, indicates that the spoofing error is greater than or equal to TOFDM-SYM. 
    % For an EDMG SC PPDU, this field is reserved.
    b41 = 0;

    % Beamformed
    % Corresponds to the TXVECTOR parameter BEAMFORMED. Set to 1 to indicate that digital beamforming is applied. 
    % Set to 0 otherwise.
    b42 = 1;

    % Number of Transmit Chains
    % Corresponds to TXVECTOR parameter NUM_TX_CHAINS. The value of this field plus 1 indicates the number of 
    % transmit chains used in the transmission of the PPDU. The value of the field plus 1 also indicates the total 
    % number of orthogonal sequences in a TRN field (see 28.9.2.2.5). This field is reserved when the EDMG TRN 
    % Length field is 0, or when the EDMG Beam Tracking Request field is 1 and the packet is an EDMG BRP-RX PPDU.
    b4345 = [0; 0; 0];

    % Reserved: bit 46-47
    b4647 = [0; 0];

    out = int8([b06; b728; b2933; b3435; b36; b37; b38; b39; b40; b41; b42; b4345; b4647]);


end
