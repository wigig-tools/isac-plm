function [rxNdpSigSeq] = getReceivedPilots(txNdpSigSeq,tdMimoChan,phyParams,simuParams,channelParams,noiseVarLin)
%GETRECEIVEDPILOTS returns the received pilot signal
%
%   GETRECEIVEDPILOTS(T,H, PHYSTRUCT, SIMSTRUCT, CHANSTRUCT, NOISEVAR)
%   Returns the filtered pilots T trough the multipath channel H and add
%   Gaussian receiver noise with variance NOISEVAR. 
%
%   GETRECEIVEDPILOTS(T,H, PHYSTRUCT, SIMSTRUCT, CHANSTRUCT, NOISEVAR, AWGN)
%   Returns the filtered pilots T trough the AWGN channel and add
%   Gaussian receiver noise with variance NOISEVAR. 
% 
%   To define PHYSTRUCT, SIMSTRUCT, CHANSTRUCT 
%   See also CONFIGPHY, CONFIGSIMULATION, CONFIGCHANNEL
%
%	2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


assert(simuParams.chanFlag~=0,'chanFlag should not be 0 (AWGN).');

numUsers = length(phyParams.numSTSVec);
rxNdpSigSeq = cell(numUsers,1);

for iUser = 1:numUsers
    tdlCirSu{1} = tdMimoChan{iUser};
    
    if simuParams.dopplerFlag == 1
        fadeNdpSigSeqSu = dopplerConv(tdlCirSu,txNdpSigSeq);
    else
        fadeNdpSigSeqSu = passBlockFadingChannel(txNdpSigSeq,tdlCirSu);
    end
    
    if isscalar(noiseVarLin)
        noiseVarLinSu = noiseVarLin;
    elseif isvector(noiseVarLin) && length(noiseVarLin)==numUsers
        noiseVarLinSu = noiseVarLin(iUser);
    else
        error('The format of noiseVarLin is incorrect.');
    end
    rxNdpSigSeqSu = addNoise(fadeNdpSigSeqSu,noiseVarLinSu);
    rxNdpSigSeq{iUser} = rxNdpSigSeqSu{1};
end
end