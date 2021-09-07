function y = edmgHeaderEncode(headerBits,varargin)
%edmgHeaderEncode Encode header bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgHeaderEncode(HEADERBITS,CFGEDMG) generates the EDMG LDPC header
%   encoded bits for Single Carrier and OFDM PHYs.
%
%   Y = edmgHeaderEncode(...,PSDU,CFGEDMG) generates EDMG LDPC header encoded
%   bits for Control PHY. PSDU is the PLCP service data unit input to the
%   PHY. It is a double or int8 typed column vector of length
%   cfgEDMG.PSDULength*8. The PSDU is the required input for EDMG Control
%   PHY.
%
%   Y is the encoded header bits. It is of size N-by-1 of type uint8, where
%   N is the number of LDPC encoded header bits in the header field of
%   Control, Single Carrier and OFDM PHY.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(3,5); % Expect at least 3 inputs; headerBits, cfgEDMG and fieldType, and optionally psdu and userIdx

if isa(varargin{1},'nist.edmgConfig')
    cfgEDMG = varargin{1};
    fieldType = varargin{2};
    if nargin == 4
        assert(strcmp(fieldType,'EDMG-Header-B'),'fieldType should be EDMG-Header-B.');
        userIdx = varargin{3};
    end
    coder.internal.errorIf(strcmp(phyType(cfgEDMG),'Control'),'nist.edmgLHeader:NoPSDUControl');
else
    narginchk(4,5);
    psdu = varargin{1};
    cfgEDMG = varargin{2};
    fieldType = varargin{3};
    if nargin == 5
        assert(strcmp(fieldType,'EDMG-Header-B'),'fieldType should be EDMG-Header-B.');
        userIdx = varargin{4};
    end
end
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% If PSDU is empty then do not attempt to encode it; return empty
if isempty(headerBits)
    y = zeros(0,1,'int8');
    return;
end

LCW = 672; % Codeword length

if strcmp(fieldType,'L-Header')
    scramInit = nist.edmgScramblerInitializationBits(cfgEDMG);
elseif strcmp(fieldType,'EDMG-Header-A')
    scramInit = nist.edmgScramblerInitializationBits(cfgEDMG);
elseif strcmp(fieldType,'EDMG-Header-B')
    scramInit = nist.edmgScramblerInitializationBits(cfgEDMG,userIdx);
else
    error('fieldType should be one of L-Header, EDMG-Header-A, EDMG-Header-B.');
end

switch phyType(cfgEDMG)
    case 'Control'
        % Scramble header and data field: IEEE 802.11ad-2012, Section 21.4.3.2.3
        scramBits = [headerBits(1:5); nist.edmgScramble([headerBits(6:end); psdu],scramInit)];

        % LDPC Encoding of header bits
        parms = edmgControlEncodingInfo(cfgEDMG);
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW; 
        blkFirstCW = [scramBits(1:parms.LDPFCW); zeros(LCWD-parms.LDPFCW,1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkFirstCW,rate);
        y = [scramBits(1:parms.LDPFCW); parityBits];

    case 'SC' 
        % Scramble header field: IEEE Std 802.11ad-2012, Section 21.6.3.1.4  
        scramBits = [headerBits(1:7); nist.edmgScramble(headerBits(8:end),scramInit)];
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW;
        blkCW = [scramBits; zeros(LCWD-size(scramBits,1),1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkCW,rate);
        c1 = [scramBits; parityBits(1:160)];
        c2 = [scramBits; parityBits(1:152); parityBits(161:end)];
        % Scramble (XOR) c2
        if strcmp(fieldType,'EDMG-Header-B')
            y = [c1; nist.edmgScramble(c2,ones(7,1),1)];
        else
            y = [c1; nist.edmgScramble(c2,ones(7,1))];
        end
    otherwise % OFDM
        % Scramble header field: IEEE Std 802.11ad-2012, Section 21.5.3.1.4  
        scramBits = [headerBits(1:7); nist.edmgScramble(headerBits(8:end),scramInit)];
        rate = 3/4;      % Header is always encoded with rate 3/4
        LCWD = rate*LCW; % Block length of LDPC data
        blkCW = [scramBits; zeros(LCWD-length(scramBits),1)]; % Pad with zeros
        parityBits = wlan.internal.ldpcEncodeCore(blkCW,rate);
        c1 = [scramBits; parityBits(9:end)];
        c2 = [scramBits; parityBits(1:84); parityBits(93:end)];
        c3 = [scramBits; parityBits(1:160)];
        % Scramble(XOR) c2 and c3
        if strcmp(fieldType,'EDMG-Header-B')
            y = [c1; nist.edmgScramble([c2; c3],ones(7,1),1)];
        else
            y = [c1; nist.edmgScramble([c2; c3],ones(7,1))];
        end
end

