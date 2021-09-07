function [tdlSisoNorm, chipDelay, chipGain] = getQDTDLSUSISOChannel(gain,delay,fs,numSamplesPerSymbol, ...
    maxTdlLen,tdlType,rxPowThresholdLog)
%getQDTDLSUSISOChannel NIST 11ay tappad delay line Single-User SISO channel impluse response generater
%   This function generate the time domain tapped delay line(TDL) single-user (SU) SISO channel impluse reponse (CIR)
%   from a single NIST QD TGay channel realization at given Tx-Rx location
% 
%   Inputs:
%   gain is the numTaps-length CIR gain vector
%   delay is the numTaps-length CIR delay vector
%   fs is the sampling frequency
%   numSamplesPerSymbol is the number of samples per symbol
%   maxTdlLen is the maximum TDL tap length allowed, set empty by using original TDL length
%   tdlType is the TDL type, e.g. 'Impulse' or 'Sinc'
%   rxPowThresholdLog is the receiver power sensitivity threshold in dB
%
%   Outputs:
%   tdlSisoNorm is the normalized TDL SISO channel gain 
%   chipDelay is the chip delay with non-zero positive gain value
%   chipGain is the chip gain with non-zero positive gain value
%
%   2019~2021 NIST/CTL Jian Wang

%   This file is available under the terms of the NIST License.

%# codegen

pathLossCutIdx = find(abs(gain).^2 > 10^(-11)); %110 dB path loss
camp = gain(pathLossCutIdx);
tau = delay(pathLossCutIdx);

tapGains = genTDLSmallScaleFading(fs * numSamplesPerSymbol,tau,camp,maxTdlLen,tdlType,rxPowThresholdLog);
if isrow(tapGains)
    tapGains = transpose(tapGains);
end
norm_factor = norm(tapGains,'fro');
tdlSisoNorm = tapGains/norm_factor;
sampleDelayIdx = find(abs(tapGains) > 0);
chipDelay = round(sampleDelayIdx/numSamplesPerSymbol);
chipGain = tdlSisoNorm(sampleDelayIdx);

end
