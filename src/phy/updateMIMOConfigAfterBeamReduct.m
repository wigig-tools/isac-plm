function [phyParams,chanCfg] = updateMIMOConfigAfterBeamReduct(phyParams,chanCfg,varargin)
%updateMIMOConfigAfterBeamReduct
%   This script updates MIMO configurations in case any beam reduction for NIST-QD channel model

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(strcmp(chanCfg.chanModel,'NIST'),'ChanModel should be NIST.');

% Update numRxAnt in case larger then number of streams after beam selection
if chanCfg.realizationSetFlag == 0
    chanCfg.realizationSetIndicator = 0;
else
    setIdx = varargin{1};
    assert(setIdx>0,'locIdx should be > 0.');
    chanCfg.realizationSetIndicator = chanCfg.realizationSetIndexVec(setIdx);
end
if length(chanCfg.realizationSetIndexVec) == 1
    if chanCfg.realizationSetIndexVec(1) == 0
        assert(isequal(phyParams.numSTSVec,chanCfg.nistChan.graphTxRxOriginal),'numSTSVec should be the graphTxRxOriginal, without beam reduction.');
        assert(strcmp(chanCfg.paaCfg.beamReduction,'BRo'),'beamReduction should be inactivated.');
    elseif chanCfg.realizationSetIndexVec(1) > 0
        phyParams.numSTSVec = chanCfg.nistChan.graphTxRx{1,chanCfg.realizationSetIndexVec(1)};
    else
        error('chanCfg.realizationSetIndexVec(1) should be >= 0.');
    end
else
    if chanCfg.realizationSetIndicator == 0
        phyParams.numSTSVec = chanCfg.nistChan.graphTxRx{1,chanCfg.realizationSetIndexVec(1)};
    else
        phyParams.numSTSVec = chanCfg.nistChan.graphTxRx{1,chanCfg.realizationSetIndicator};
    end
end
if ~isequal(phyParams.numSTSVec,chanCfg.nistChan.graphTxRxOriginal)
    fprintf('chanFlag=4: Updated numSTSVec, numSTSTot, numTxAnt and numUsers after beam selection.\n');
end
phyParams.numSTSTot = sum(phyParams.numSTSVec);
phyParams.numTxAnt = sum(phyParams.numSTSVec);
phyParams.numUsers = length(phyParams.numSTSVec);  

if phyParams.svdFlag > 0
    if phyParams.precAlgoFlag == 0
        % Channel SVD, Tx V pre-coding using matched filtering, Rx equalization
        if phyParams.numTxAnt == 1
            phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP,'Direct', 'Set expected smTypeNDP value:');
            phyParams.smTypeDP = checkInput(phyParams.smTypeDP,'Direct', 'Set expected smTypeDP value:');
            phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 1, 'Set expected equiChFlag value:');
        end
    end
end

%% Update MIMO for cfgNDP and cfgEDMG
phyParams.cfgNDP.NumTransmitAntennas = phyParams.numTxAnt;
phyParams.cfgNDP.NumSpaceTimeStreams = phyParams.numSTSVec;
phyParams.cfgNDP.PreambleSpatialMappingType = phyParams.smTypeNDP;

phyParams.cfgEDMG.NumTransmitAntennas = phyParams.numTxAnt;
phyParams.cfgEDMG.NumSpaceTimeStreams = phyParams.numSTSVec;
phyParams.cfgEDMG.PreambleSpatialMappingType = phyParams.smTypeDP;
phyParams.cfgEDMG.SpatialMappingType = phyParams.smTypeDP;

end
