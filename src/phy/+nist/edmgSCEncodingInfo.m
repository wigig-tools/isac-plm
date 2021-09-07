function Y = edmgSCEncodingInfo(cfgEDMG,userIdx,varargin) 
%edmgSCEncodingInfo generate LDPC encode and decode parameters.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgSCEncodingInfo(CFGEDMG) return the LDPC encoding and decoding
%   parameters for Single Carrier PHY.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   Reference: IEEE Std 802.11ad-2012, Section 21.6.3.2.3
%              IEEE P802.11ay Draft 7.0, Section 28.5.9.4

%   Copyright 2016 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if nargin>2
    NBLKSmax = varargin{1}; 
else
    NBLKSmax = 1;
end
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
codeRate = mcsTable.Rate(userIdx);
codeRepetition = mcsTable.Repetition(userIdx);
NCBPS = mcsTable.NCBPS(userIdx);

[~,chara] = edmgPHYInfoCharacteristics(cfgEDMG);
EDMG_BRP_MIN_SC_BLOCKS = chara.aBRPminSCblocks;   % P802.11ay/D7.0, Section 10.42.10.1

info = edmgSCInfo(cfgEDMG);
NDSPB = info.NDSPB; % NumDataSymPerBlk (info.NFFT-info.NGI)

% IEEE P802.11ay D7.0, Section 28.5.9.4.3 LDPC encoding

if isequal(codeRate,7/8)
    LCW = 624; % LDPC codeword length for extend MCS
else
    LCW = 672; % LDPC codeword length
end

% IEEE P802.11ay D7.0 Section 28.5.9.4.3 LDPC Encoding Process
Length = cfgEDMG.PSDULength(userIdx);
% Calculate number of LDPC codewords
NCW = ceil((Length*8)/(LCW*(codeRate/codeRepetition)));

% Number of coded bits per block
NCBPB = NDSPB*NCBPS; % Table 21-20   % 448*mcsTable.NCBPS; 
% Calculate number of symbol blocks
NBLKS = ceil((NCW*LCW)/(NCBPB));

% IEEE P802.11ay D7.0 Section 28.9.2.2.4 EDMG BRP PPDU duration
if wlan.internal.isBRPPacket(cfgEDMG) && NBLKS<EDMG_BRP_MIN_SC_BLOCKS
	NBLKS = EDMG_BRP_MIN_SC_BLOCKS;
end

% IEEE P802.11ay D7.0, Section 28.5.9.4.4 MU PPDU padding
% The number of pad SC symbol blocks for the MU PPDU transmission for the iuser th user
if NBLKS < NBLKSmax
    NPAD_BLKS = NBLKSmax - NBLKS;
    NBLKS = NBLKSmax;
else
    NPAD_BLKS = 0;
end

% Calculate number of pad bits required
NDATA_PAD = NCW*LCW*(codeRate/codeRepetition)-Length*8;

% Calculate number of symbol block padding bits
NBLK_PAD = NBLKS*NCBPB-NCW*LCW;

Y = struct(...
    'NCW',NCW, ...
    'NBLKS',NBLKS, ...
    'NDATA_PAD',NDATA_PAD, ...
    'NBLK_PAD',NBLK_PAD, ...
    'NPAD_BLKS',NPAD_BLKS, ...
    'LCW',LCW);

end