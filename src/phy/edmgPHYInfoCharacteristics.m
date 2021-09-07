function [info,chara] = edmgPHYInfoCharacteristics(cfgEDMG)
%edmgPHYInfoCharacteristics EDMG PHY time-related information and static characteristics
%
%   Input:
%   cfgEDMG is the EDMG configuration object.
%   
%   Outputs:
%   info is a struct including the PHY time-related information paramters
%   chara is a struct including the PHY static characteristics
%   
%   References:
%   IEEE Std 802.11-2016, IEEE Std 802.11-2020
%   IEEE P802.11ay Draft7.0

%   2020~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% Parameters of DMG and EDMG based on NCB=1
info.FS = 2640e6;   % OFDM sample rate, P802.11ay D7.0 Table 28-62
info.FC = info.FS*(2/3); % SC chip rate, 1760 MHz, P802.11ay D7.0 Table 21-4
info.TS = 1/info.FS;     % OFDM sample time, (1/Fs), P802.11ay D7.0 Table 28-62
info.TC = 1/info.FC;     % SC chip time, 0.57 Nanoseconds (1/Fc), P802.11ay D7.0 Table 21-4

% Parameters of EDMG based on NCB>1
NCB = cfgEDMG.NumContiguousChannels;
info.FS_EDMG = info.FS * NCB;
info.FC_EDMG = info.FC * NCB;
info.TS_EDMG = 1/info.FS_EDMG;
info.TC_EDMG = 1/info.FC_EDMG;

% Get guard internval
[~,info.TGI] = edmgGIInfo(cfgEDMG);

% IEEE Std 802.11-2016, Table 20-32
chara = struct();
chara.aDMGChipTimeDuration = info.TC;
chara.aDMGSampleTimeDuration = info.TS;
chara.aBRPminSCblocks = 18;  % aBRPminSCblocks, 
chara.aSCBlockSize = 512;  % aSCBlockSize
chara.aSCGILength = 64;  % aSCGILength
chara.aBRPminOFDMblocks = 20;  % aBRPminOFDMblocks
    
end

