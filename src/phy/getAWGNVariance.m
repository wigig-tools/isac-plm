function [noiseVarLin] = getAWGNVariance(snrLogTotSubc,snrMode,snrAntNormFactor,cfgEDMG)
%getAWGNVariance Get noise variance of AWGN channel
% Inputs
%   snrLogTotSubc is the SNR value in dB over total subcarriers 
%   snrMode is char in 'SRN', 'EbNo' or 'EsNo'
%   snrAntNormFactor is a scalar of SNR normalization factor
%   cfgEDMG is a EDMG configuration object
%   
% Outputs
%   noiseVarLin is a struct contain ActSubc and TotSubc: which are two noise power on activated subcarriers (number of
%   Tones) and total subcarriers for OFDM, respectively. These two variable become equal in SC mode.
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

phyMode = cfgEDMG.PHYType;
mcsTable = nist.edmgMCSRateTable(cfgEDMG);

% Setup AWGN variance
symbolEnergy = 1*snrAntNormFactor;  % Modulated symbol energy Es
samplesPerSymbol = 1;
% Noise variance over channel at receiver. Account for noise energy in nulls,
% so the SNR is defined per active subcarrier
if strcmp(phyMode,'OFDM')
    ofdmCfg = nist.edmgOFDMConfig(cfgEDMG);
    snrLogActSubc = snrLogTotSubc - 10*log10(ofdmCfg.FFTLength/ofdmCfg.NumTones); 
else
    snrLogActSubc = snrLogTotSubc;
end
snrLinTotSubc = 10^(snrLogTotSubc/10);
snrLinActSubc = 10^(snrLogActSubc/10);
if strcmp(snrMode,'SNR')
    noiseVarLin.TotSubc = symbolEnergy/snrLinTotSubc;
    noiseVarLin.ActSubc = symbolEnergy/snrLinActSubc;
elseif strcmp(snrMode,'EbNo')     % SNR per Bit ( Eb/N0 ), N0 is the variance of the (complex valued) noise.
    if strcmp(phyMode,'OFDM') 
        bitEnergy = symbolEnergy ./(mcsTable.Rate .* mcsTable.NBPSCS);  % Eb = Es/(fecRate * bitsPerSymb);
    else
        bitEnergy = symbolEnergy ./(mcsTable.Rate .* mcsTable.NCBPSS);  % Eb = Es/(fecRate * bitsPerSymb);                    
    end
    noiseVarLin.TotSubc = bitEnergy /(samplesPerSymbol*snrLinTotSubc);
    noiseVarLin.ActSubc = bitEnergy /(samplesPerSymbol*snrLinActSubc);
elseif strcmp(snrMode,'EsNo')    % SNR per Symbol ( Es/N0 ), N0 is the variance of the (complex valued) noise.
    noiseVarLin.TotSubc = symbolEnergy /(samplesPerSymbol*snrLinTotSubc);
    noiseVarLin.ActSubc = symbolEnergy /(samplesPerSymbol*snrLinActSubc);
end

end

