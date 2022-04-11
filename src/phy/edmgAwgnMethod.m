function [noiseVarLinActSubc,noiseVarLinTotSubc,varargout] = edmgAwgnMethod(snrLogTotSubc,noiseFlag,snrMode,snrAntNormFactor,cfgEDMG)
%edmgAwgnMethod returns noise
%   Noise noiseFlag:
%   - 0: non noise channel (for debugging)
%   - 1: Calculate AWGN channel using comm.AWGNChannel
%   - 2: Calculate AWGN channel without using comm.AWGNChannel
%   Output variables
%   noiseVarLinActSubc: noise power on activated subcarriers (number of
%   Tones) for OFDM


phyMode = cfgEDMG.PHYType;
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
if strcmp(phyMode,'OFDM')
    ofdmCfg = helperOFDMInfoNist('EDMG-Data',cfgEDMG);
end

% Create an instance of the AWGN channel per SNR point simulated
% Account for noise energy in nulls so the SNR is defined per
% active subcarrier
if noiseFlag == 0
    noiseVarLinActSubc = 0;
    noiseVarLinTotSubc = 0;
    varargout{1} = [];
elseif noiseFlag == 1
    % MATLAB AWGNChannel
    snrLinTotSubc = 10^(snrLogTotSubc/10);
    if strcmp(phyMode,'OFDM') 
        snrLogActSubc = snrLogTotSubc - 10*log10(ofdmCfg.FFTLength/ofdmCfg.NumTones); 
    else
        snrLogActSubc = snrLogTotSubc;
    end
    snrLinActSubc = 10^(snrLogActSubc/10);
    awgnChannel = comm.AWGNChannel;
    awgnChannel.SignalPower = 1*snrAntNormFactor; 
    awgnChannel.SamplesPerSymbol = 1;
    if strcmp(snrMode,'SNR')
        awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
        awgnChannel.SNR = snrLogActSubc;
        % Noise variance at receiver over channel
        noiseVarLinActSubc = awgnChannel.SignalPower / snrLinActSubc;
        % Noise Variance per active subcarrier at equalizer
        noiseVarLinTotSubc = awgnChannel.SignalPower / snrLinTotSubc;
    elseif strcmp(snrMode,'EbNo')
        awgnChannel.NoiseMethod = 'Signal to noise ratio (Eb/No)';
        awgnChannel.BitsPerSymbol = 1;
        if strcmp(phyMode,'OFDM') 
            awgnChannel.EbNo = 10*log10(awgnChannel.SamplesPerSymbol) + snrLogActSubc + 10*log10(mcsTable.Rate * mcsTable.NBPSCS);
            bitEnergy = awgnChannel.SignalPower /(mcsTable.Rate * mcsTable.NBPSCS);
        else
            awgnChannel.EbNo = 10*log10(awgnChannel.SamplesPerSymbol) + snrLogActSubc + 10*log10(mcsTable.Rate * mcsTable.NBPSCS);
            bitEnergy = awgnChannel.SignalPower /(mcsTable.Rate * mcsTable.NBPSCS);  
        end                    
        noiseVarLinActSubc = bitEnergy / (awgnChannel.SamplesPerSymbol*snrLinActSubc);
        noiseVarLinTotSubc = bitEnergy / (awgnChannel.SamplesPerSymbol*snrLinTotSubc);
    elseif strcmp(snrMode,'EsNo')
        awgnChannel.NoiseMethod = 'Signal to noise ratio (Es/No)';
        awgnChannel.EsNo = 10*log10(awgnChannel.SamplesPerSymbol) + snrLogActSubc;
        % Noise Variance per active subcarrier at equalizer
        noiseVarLinActSubc = awgnChannel.SignalPower / (awgnChannel.SamplesPerSymbol*snrLinActSubc);
        noiseVarLinTotSubc = awgnChannel.SignalPower / (awgnChannel.SamplesPerSymbol*snrLinTotSubc);
    else
        error('snrMode should be SNR, Eb/No or Es/No.');
    end
    varargout{1} = awgnChannel;
elseif noiseFlag == 2
    % Setup AWGN variance
    symbolEnergy = 1*snrAntNormFactor;  % Modulated symbol energy Es
    samplesPerSymbol = 1;
    % Noise variance over channel at receiver. Account for noise energy in nulls,
    % so the SNR is defined per active subcarrier
    if strcmp(phyMode,'OFDM') 
        snrLogActSubc = snrLogTotSubc - 10*log10(ofdmCfg.FFTLength/ofdmCfg.NumTones); 
    else
        snrLogActSubc = snrLogTotSubc;
    end
    snrLinTotSubc = 10^(snrLogTotSubc/10);
    snrLinActSubc = 10^(snrLogActSubc/10);
    if strcmp(snrMode,'SNR')
        noiseVarLinTotSubc = symbolEnergy/snrLinTotSubc;
        noiseVarLinActSubc = symbolEnergy/snrLinActSubc;
    elseif strcmp(snrMode,'EbNo')     % SNR per Bit ( Eb/N0 ), N0 is the variance of the (complex valued) noise.
        if strcmp(phyMode,'OFDM') 
            bitEnergy = symbolEnergy /(mcsTable.Rate * mcsTable.NBPSCS);  
        else
            bitEnergy = symbolEnergy /(mcsTable.Rate * mcsTable.NBPSCS);    
        end
        noiseVarLinTotSubc = bitEnergy /(samplesPerSymbol*snrLinTotSubc);
        noiseVarLinActSubc = bitEnergy /(samplesPerSymbol*snrLinActSubc);
    elseif strcmp(snrMode,'EsNo')    % SNR per Symbol ( Es/N0 ), N0 is the variance of the (complex valued) noise.
        noiseVarLinTotSubc = symbolEnergy /(samplesPerSymbol*snrLinTotSubc);
        noiseVarLinActSubc = symbolEnergy /(samplesPerSymbol*snrLinActSubc);
    end
    varargout{1} = [];
else
    error('Noise noiseFlag should be 0, 1 or 2.');
end

end