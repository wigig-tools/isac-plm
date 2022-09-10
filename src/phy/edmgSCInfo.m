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
% const.DMGSTF = [1 17*G_SEQ_LEN];
% const.DMGCEF = [17*G_SEQ_LEN+1 17*G_SEQ_LEN+9*G_SEQ_LEN];
% const.DMGHeader = [const.DMGCEF(2)+1 const.DMGCEF(2) + 2*(N_SPB+64) ];
% const.Header_A = [const.DMGHeader(2)+1 const.DMGHeader(2)+ 2*NCB*(N_SPB+64)]; 
% const.EDMGSTF =  [const.Header_A(2)+1 const.Header_A(2) + 19*NCB*G_SEQ_LEN];
% 
% if cfgEDMG.MsSensing == 1
%     CEF_length = 0;
% else
%     CEF_length = 9*G_SEQ_LEN+(11*G_SEQ_LEN)*(2^(ceil(max(log10(NSTS)/log10(2),1))-1)-1);
% end
% 
% const.EDMGCEF =  [const.EDMGSTF(2)+1  const.EDMGSTF(2)+ CEF_length];
% 
% if cfgEDMG.MsSensing == 1
%     const.EDMGHeaderB = [const.EDMGCEF(2)+1 const.EDMGCEF(2)];
% else
%     if cfgEDMG.NumUsers>1
%         const.EDMGHeaderB = [const.EDMGCEF(2)+1 const.EDMGCEF(2)+NCB*(N_SPB+NGI)];
%     else
%         const.EDMGHeaderB = [const.EDMGCEF(2)+1 const.EDMGCEF(2)];
%     end
% end
% 
% if cfgEDMG.MsSensing == 1
%     syncLen  = 18 * TRN_BL*NCB*cfgEDMG.NumUsers;
%     
%     const.SYNC = [const.EDMGSTF(2)+1, const.EDMGSTF(2)+ syncLen];
%     N_TRN = 2^(ceil(max(log2(NSTS),1))-1);
%     TRN_SF_LENGTH = TRN_BL * NCB * 6 * N_TRN;
%     TRN_LENGTH =  TRN_SF_LENGTH * N_SUBFIELD;
%     const.TRN = [const.SYNC(2)+1, const.SYNC(2)+TRN_LENGTH ]
% end

end

% End of file