function SNR = dmgSnrEstimate(preamble,h,cfgEDMG)

gaLen = 128*cfgEDMG.NumContiguousChannels;
nStfFields = 14;

nonedmgFields = [wlan.internal.dmgSTF(cfgEDMG); wlan.internal.dmgCE(cfgEDMG)];


y = conv(nonedmgFields,h);
[~,w] = max(abs(h));
idealSTF  = y(2*gaLen+w: gaLen+w+ gaLen*nStfFields-1);
rxSTF = preamble(gaLen+1:gaLen*nStfFields);
n = idealSTF-rxSTF;
SNR = 10*log10(var(y)/var(n));

end