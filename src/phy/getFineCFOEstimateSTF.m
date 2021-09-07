function foffset = getFineCFOEstimateSTF(edmg_stf,cfgEDMG)
%getFineCFOEstimateSTF Fine carrier frequency offset estimation
%   FOFFSET = getFineCFOEstimateSTF(edmg_stf) estimates the carrier
%   frequency offset FOFFSET using time-domain EDMG-STF.
%   The periodic sequence within the EDMG-STF allows fine frequency offset 
%   estimation to be performed.
%
%   IN is a complex Ns-by-Nr matrix where Ns is the number of time domain
%   samples in the EDMG-STF, and Nr is the number of receive antennas.
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

NCB = cfgEDMG.NumContiguousChannels;
FFTLen = 512*NCB;
NSTF = size(edmg_stf,1);   % Number of samples in L-LTF

% Extract EDMG-STF or as many samples as we can
edmg_stf = edmg_stf(1:min(NSTF,end),:);

% Fine CFO estimate assuming one repetition per FFT period (6 OFDM symbols)
M = FFTLen;             % Number of samples per repetition
GI = 128*NCB;               % Guard interval length
S = M*6;                % Maximum useful part of EDMG-STF (6 OFDM symbols)
N = size(edmg_stf,1);       % Number of samples in the input

use_stf = edmg_stf(GI+(1:min(S,N-GI)),:);
foffset = wlan.internal.cfoEstimate(use_stf,M)./M;

end