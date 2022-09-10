function h=edmgTrnChannelEstimate(x,cfgEDMG)
%%EDMGTRNCHANNELESTIMATE
%

%   2021-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

TRN_BL = cfgEDMG.SubfieldSeqLength;
N_CB = cfgEDMG.NumContiguousChannels;
[Ga, Gb] = nist.edmgGolaySequence(TRN_BL * N_CB, 1);

% Generate TRN_Basic.
% Cicular Convolution
corrGa = conv(x, conj(Ga(end:-1:1)));
corrGb = conv(x, conj(Gb(end:-1:1)));

corrGa = [zeros(TRN_BL,1);corrGa];
corrGb = [corrGb; zeros(TRN_BL,1)];

sum_ab =  corrGb+corrGa;
diff_ab =corrGb-corrGa; 

seq1 = diff_ab(2*TRN_BL:2*TRN_BL+TRN_BL/2); % ISI
seq2 = sum_ab(4*TRN_BL:4*TRN_BL+TRN_BL/2);
seq3 = diff_ab(6*TRN_BL:6*TRN_BL+TRN_BL/2);% ISI
% av_seq = -seq3 + seq2;
av_seq = seq2;
                
h = av_seq/(4*TRN_BL);

