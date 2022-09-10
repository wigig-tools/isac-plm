function y = edmgMssSync(cfgEDMG)
%%EDMGMSSYNC EDMG Multi-Static Sensing PPDU Sync Field
%
%   Y = EDMGMSSYNC(CFGEDMG) generates the EDMG Multi-Static Sensing PPDU 
%   Sync Field as in IEEE 802.11-22/0464r6
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig
%   specifies the parameters for the EDMG format.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},...
    mfilename,'EDMG format configuration object');

% Table 1 - Coefficient Matrix for EDMG Multi-Static Sensing Sync field
M = [1 -1 1 -1 1 1 1 1; ...
    1 -1 1 -1 1 1 1 1;...
    1 1 -1 -1 1 -1 -1 1;...
    1 1 -1 -1 1 -1 -1 1;...
    -1 1 -1 1 1 1 1 1;...
    -1 1 -1 1 1 1 1 1;...
    1 -1 -1 1 -1 -1 1 1;...
    1 -1 -1 1 -1 -1 1 1];

NSYNC_SUBFIELDS = 18;
NSYNC_STF = 9;
NSYNC_CE = 9;

EDMG_MS_SENSING_NSTA = cfgEDMG.NumUsers; % Num of STAs in Instance
TRN_BL = 128;  
N_CB = cfgEDMG.NumContiguousChannels;

SYNC = zeros(NSYNC_SUBFIELDS*TRN_BL * N_CB, EDMG_MS_SENSING_NSTA);
% r: STA Multistatic ID
for  r = 1: EDMG_MS_SENSING_NSTA
    % p: Golay index
    % For r=1,3,5,7 p is set to 7 and for r=2,4,6 p is set to 8
    p = 8-mod(r-1,2);

    % Get pairs of Golay complementary sequences 
    [Ga, Gb] = nist.edmgGolaySequence(TRN_BL * N_CB, p);

    % Get SYNC STF 
    SYNC_STF = [repmat(-M(r,7)*Ga, NSYNC_STF-1,1); M(r,7)*Ga];

    % GET SYNC CE
    M_CE  = reshape(repmat(M(r,:),TRN_BL * N_CB,1), [],1);
    SYNC_CE = repmat([Gb; Ga], (NSYNC_CE-1)/2,1).*M_CE;
    
    % SYNC 
    SYNC(:,r) = [SYNC_STF;SYNC_CE; SYNC_CE(1:TRN_BL * N_CB)];

end

y = SYNC(:);