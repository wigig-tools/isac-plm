function [tdlCirMuMimo,maxMuTapLen] = getQDTDLMUMIMOChannel(gain,delay,doppler,txPort,rxPort,numDoppler, ...
    sampleRate,numTxAnt,numSTSVec,maxSuTdlLen,tdlType,rxPowThresholddB,normFlag)
%getQDTDLMUMIMOChannel Get tapped delay line (TDL) multi-user (MU) MIMO channel impluse response 
%   This function generates the tapped delay line (TDL) multi-user (MU) MIMO channel impluse response (CIR) 
%   for NIST quasi-deterministic (QD) channel realization at given Tx-Rx location 
% 
%   Inputs:
%   gain is the numTxAnt-by-numSTSTot gain cell array of CIR
%   delay is the numTxAnt-by-numSTSTot delay cell array of CIR
%   doppler is the numTxAnt-by-numSTSTot Doppler cell array of CIR
%   txPort is the beam to transmit RF chain port mapping matrix
%   rxPort is the beam to receiver RF chain port mapping matrix
%   numDoppler is the number of Doppler samples
%   sampleRate is the sampling frequency
%   numSamplesPerSymbol is the number of samples per symbol
%   maxSuTdlLen is the maximum TDL tap length allowed for SU channel, set empty by using original TDL length
%   tdlType is the TDL type, e.g. 'Impulse' or 'Sinc'
%   rxPowThresholdLog is the receiver power sensitivity threshold in dB
%
%   Outputs:
%   tdlCirMuMimo is the normalized TDL MU-MIMO channel gain 
%   maxMuTapLen is the maximum TDL length of MU-MIMO channel 
%
%   2019~2020 NIST/CTL <jiayi.zhang@nist.gov>

numUsers = length(numSTSVec);
numSTSTot = sum(numSTSVec);
assert(numTxAnt == length(txPort),'numTxAnt should be equal to the length of txPort.');
assert(numSTSTot == length(rxPort),'numSTSTot should be equal to the length of RxPort.');
assert(numUsers == max(rxPort),'numUsers should be the maximum value of the elements in RxPort.');

numSTSTot = sum(numSTSVec);
lenCir = zeros(numTxAnt,numSTSTot);
muTapGain= cell(numTxAnt,numSTSTot);
for iTxA = 1:numTxAnt
    for iSTS = 1:numSTSTot
        beamCamplex = gain{iTxA,iSTS};
        beamDelay = delay{iTxA,iSTS};
        if numDoppler == 1
            tdlStream = genTDLSmallScaleFading(sampleRate,beamDelay,beamCamplex,maxSuTdlLen,tdlType,rxPowThresholddB);
        else
            beamDoppler = doppler{iTxA,iSTS};
            tdlStream = genTDLSmallScaleTimeVaryFading(sampleRate,beamDelay,beamCamplex,beamDoppler,numDoppler, ...
                maxSuTdlLen,tdlType,rxPowThresholddB);
        end
        lenCir(iTxA,iSTS) = size(tdlStream,1);
        muTapGain{iTxA,iSTS} = tdlStream;
    end
end

% Zero padding
maxMuTapLen = max(lenCir,[],'all');
[tdlCirMuMimo,~] = normalizeMUMIMOMultiPathChannel(muTapGain,numTxAnt,numSTSVec,normFlag,maxMuTapLen,rxPort);

end

% End of file