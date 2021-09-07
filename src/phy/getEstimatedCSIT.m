function [pktErrNdp, estCIRNdp, estCFRNdp, estNoiseVarNdp] = ...
    getEstimatedCSIT(rxNdpSigSeq, phyParams, cfgSim)
%%GETESTIMATEDCSIT returns the channel state information.
%
%   [ERR, CIR, CFR, NOISEVAR = GETESTIMATEDCSIT(R,PHYSTRUCT, CFGSIMSTRUCT)
%   Returns the full channel state information estimated from the received
%   pilot signal R. In case of missing sync ERR = 1 otherwise ERR =0.
%   CIR is the channel impulse response estimated. CFR is the channel
%   frequency response estimated.
%
%   To define PHYSTRUCT
%   See also CONFIGPHY
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

numUsers = length(phyParams.numSTSVec);
pktErrNdp = cell(numUsers,1);
estNoiseVarNdp = cell(numUsers,1);
estCIRNdp = cell(numUsers,1);
estCFRNdp = cell(numUsers,1);
syncMargin = phyParams.giLength-round(cfgSim.symbOffset*phyParams.giLength);

for iUser = 1:numUsers
    [pktErrNdp{iUser}, ~, preambleNdp] = edmgRxPreambleProcess(rxNdpSigSeq{iUser}, phyParams.cfgNDP, ...
        'syncMargin', syncMargin, 'userIdx', iUser);
    if pktErrNdp{iUser} == 1
        continue; % Go to next loop iteration
    end
    estNoiseVarNdp{iUser} = 1./preambleNdp.edmg.snrEst;     % EDMG test
    if strcmpi(phyParams.cfgNDP.PHYType, 'OFDM')
        estCFRNdp{iUser} = reformatSUMIMOChannel(preambleNdp.edmg.chanEst,'FD');
        estCIRNdp{iUser} = [];
    else
        % SC
        estCIRNdp{iUser} = reformatSUMIMOChannel(preambleNdp.edmg.chanEst,'TD');
        estCFRNdp{iUser} = [];
    end
end
                            
                            