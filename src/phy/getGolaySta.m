function [Ga,Gb] = getGolaySta(cfgEDMG,r)

M = [1 -1 1 -1 1 1 1 1; ...
    1 -1 1 -1 1 1 1 1;...
    1 1 -1 -1 1 -1 -1 1;...
    1 1 -1 -1 1 -1 -1 1;...
    -1 1 -1 1 1 1 1 1;...
    -1 1 -1 1 1 1 1 1;...
    1 -1 -1 1 -1 -1 1 1;...
    1 -1 -1 1 -1 -1 1 1];


TRN_BL = cfgEDMG.SubfieldSeqLength;  
N_CB = cfgEDMG.NumContiguousChannels;

% r: STA Multistatic ID
    % p: Golay index
    % For r=1,3,5,7 p is set to 7 and for r=2,4,6 p is set to 8
    p = 8-mod(r-1,2);

    % Get pairs of Golay complementary sequences 
    [Ga, Gb] = nist.edmgGolaySequence(TRN_BL * N_CB, p);

    % Get SYNC STF 
%     SYNC_STF = [repmat(-M(r,7)*Ga, NSYNC_STF-1,1); M(r,7)*Ga];
% 
%     % GET SYNC CE
%     M_CE  = reshape(repmat(M(r,:),TRN_BL * N_CB,1), [],1);
%     SYNC_CE = repmat([Gb; Ga], (NSYNC_CE-1)/2,1).*M_CE;
%     
%     % SYNC 
%     SYNC(:,r) = [SYNC_STF;SYNC_CE; SYNC_CE(1:TRN_BL * N_CB)];

% end