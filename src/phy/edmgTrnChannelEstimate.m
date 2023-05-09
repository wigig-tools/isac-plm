function [h,snr]=edmgTrnChannelEstimate(x,cfgEDMG)
%%EDMGTRNCHANNELESTIMATE Channel estimation

% [H, SNR] = EDMGTRNCHANNELESTIMATE(X, cfgEDMG) channel estimator on TRN.
% Return the channel vector H of length SubfieldSeqLength/2+1x1 and the SNR
% estimate, given the TRN subfield X and the EDMG object cfgEDMG

% 2021-2023 NIST/CTL Steve Blandino

% This file is available under the terms of the NIST License.

TRN_BL = cfgEDMG.SubfieldSeqLength;
N_CB = cfgEDMG.NumContiguousChannels;
[Ga, Gb] = nist.edmgGolaySequence(TRN_BL * N_CB, 1);

corrGa = conv(x, conj(Ga(end:-1:1)));
corrGb = conv(x, conj(Gb(end:-1:1)));

corrGa = [zeros(TRN_BL,1);corrGa];
corrGb = [corrGb; zeros(TRN_BL,1)];

sum_ab  = corrGb+corrGa;
diff_ab = corrGb-corrGa; 

seq1 = diff_ab(2*TRN_BL:2*TRN_BL+TRN_BL/2); 
seq2 = sum_ab(4*TRN_BL:4*TRN_BL+TRN_BL/2);
% seq3 = diff_ab(6*TRN_BL:6*TRN_BL+TRN_BL/2);
% av_seq = -seq3 + seq2;
av_seq = -seq1+seq2;
                
h = av_seq/(4*TRN_BL);

[~, trnSf] = edmgTrn(cfgEDMG);
y = conv(trnSf,h);
y = y(TRN_BL:5*TRN_BL);
x = x(TRN_BL:5*TRN_BL);
n = y-x;
snr = 10*log10(var(y)/var(n));