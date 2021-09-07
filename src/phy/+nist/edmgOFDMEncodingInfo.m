function Y = edmgOFDMEncodingInfo(cfgEDMG,userIdx,varargin) 
%edmgOFDMEncodingInfo generate LDPC encode and decode parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgOFDMEncodingInfo(CFGEDMG) return the LDPC encoding and decoding
%   parameters for OFDM PHY.
%
%   CFGEDMG is the format configuration object of type wlanEDMGConfig which
%   specifies the parameters for the EDMG format.
%
%   %   Reference: IEEE Std 802.11ad-2012, Section 21.5.3.2.3
%   %              IEEE P802.11ay Draft 7.0, Section 28.6.9.2
%
%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if nargin>2
    NSYMSmax = varargin{1};
else
    NSYMSmax = 0;
end

mcsTable = nist.edmgMCSRateTable(cfgEDMG);
codeRate = mcsTable.Rate(userIdx);
NCBPS = mcsTable.NCBPS(userIdx);

% IEEE P802.11ay D7.0, Section 28.6.9.2.3 LDPC Encoding

if isequal(codeRate,7/8)
    LCW = 624; % LDPC codeword length for extend MCS
else
    LCW = 672; % LDPC codeword length
end

Length = cfgEDMG.PSDULength(userIdx);

% Calculate number of LDPC codewords
NCW = ceil((Length*8)/(LCW*codeRate));

% Calculate number of OFDM symbols
NSYMS = ceil((NCW*LCW)/NCBPS);

[~,chara] = edmgPHYInfoCharacteristics(cfgEDMG);
if wlan.internal.isBRPPacket(cfgEDMG) && NSYMS<chara.aBRPminOFDMblocks
    NSYMS = chara.aBRPminOFDMblocks;
end

% IEEE P802.11ay D7.0, Section 28.6.9.2.4 MU PPDU padding
% The number of pad OFDM symbols for the MU PPDU transmission for the iuser th user
if NSYMS < NSYMSmax
    NPAD_SYMS = NSYMSmax - NSYMS;
    NSYMS = NSYMSmax;
else
    NPAD_SYMS = 0;
end

% Calculate number of data pad bits required
NDATA_PAD = NCW*LCW*codeRate - Length*8;
% Calculate number of coded pad bits required
NSYM_PAD = NSYMS*NCBPS - NCW*LCW;

% DCM Flag
if cfgEDMG.MCS(userIdx)<=10
    DCM = 1;
else
    DCM = 0;
end

Y = struct(...
    'NCW',NCW,...
    'NSYMS',NSYMS,...
    'NDATA_PAD',NDATA_PAD,...
    'NSYM_PAD',NSYM_PAD,...
    'NPAD_SYMS',NPAD_SYMS,... 
    'LCW',LCW,...
    'DCM',DCM);

end

