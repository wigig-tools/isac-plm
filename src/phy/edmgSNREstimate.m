function [SNR] = edmgSNREstimate(edmg_stf,cfgEDMG)
%EDMGSNRESTIMATE returns the estimated SNR computed on EDMG-STF (OFDM) and EDMG-CEF (SC)
%
%   2020~2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

SNR = 1./nist.edmgSTFNoiseEstimate(edmg_stf, cfgEDMG.PHYType);

end