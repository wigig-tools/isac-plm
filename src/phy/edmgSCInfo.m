function [const] = edmgSCInfo(cfgEDMG)
%EDMGSCINFO Constants for EDMG SC PHY
%
%   [CONST] = edmgSCInfo(CFGEDMG) returns a structure containing constants and a structure 
%   containing data field, STF, CEF, header for nonEDMG (DMG) and EMDG portion for EDMG SC PHY.
% 
%   2019-2020 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

nargoutchk(0,2);

fc = 60.48e9; % centerFreqHz = % 58.32e9;
NCB = cfgEDMG.NumContiguousChannels;    % Number of contiguous 2.16 GHz channels
TRN_BL = 128;
N_SUBFIELD = 10;
if NCB==1
    NTONES = 512; % Number of active subcarriers
    NFFT = 512; % FFT length
    N_SPB = 448;
end

G_SEQ_LEN = 128*NCB;

[NGI,TGI] = edmgGIInfo(cfgEDMG); % 96; % 128;  % Guard interval
NDSPB = NFFT - NGI;  % NumDataSymPerBlk
NSTS = sum(cfgEDMG.NumSpaceTimeStreams,2);  % Total number of space-time streams
normalizationFactor = (NFFT/sqrt(NTONES)); % SC normalization factor

const = struct();
const.CenterFreqHz = fc;
const.NCB = NCB;
const.NTONES = NTONES;
const.NFFT = NFFT;
const.NormalizationFactor = normalizationFactor;
const.NGI = NGI;
const.NDSPB = NDSPB;


end

% End of file