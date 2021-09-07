function [spatialMapMat,csiSvd,powAllo,normFactor] = getSCTxTDMIMOPrecoder(tdMimoChan,noiseVarLin,cfgEDMG,cfgSim)
%getSCTxTDMIMOPrecoder Get single-carrier transmit time-domain MIMO precoder
%
%   [spatialMapMat,csiSvd,powAllo] = getSCTxTDMIMOPrecoder(tdMimoChan,noiseVarLin,cfgEDMG,cfgSim) performs time-domain
%       MIMO precoding for EDMG single-carrier (SC) transmitter.
%
%   Inputs:
%   tdMimoChan is a numUsers-length cell array of time-domain MIMO channels. Each cell holds the user's time-domain
%       MIMO channel impluse response (CIR), each entry is a numTxAnt-by-numRxAnt subcell array, which contains the 
%       maxTdlLen-by-1 column vectors. maxTdlLen is the maximum TDL tap length.
%   noiseVarLin is the noise variance in linear, which can be in various formats: when noiseVarLin is a numUsers
%       length cell array, each cell holds a numSTS-length noise variance of that user. The numSTS is the number
%       of space-time streams of that user. When noiseVarLin is a numSTSTot-length vector, each element is the 
%       noise variance of the space-time stream of a user. When noiseVarLin is numSTS-by-numUsers matrix, each column
%       vector is the multi-steam noise variance vector of that user.
%   cfgEDMG is the object accroding to nist.edmgConfig.
%   cfgSim is the structure holding the parameters of simulation configuration.
%
%   Outputs:
%   spatialMapMat is a numSTSTot-by-numTxAnt-by-numTaps time-domain multi-user precoding matrix.
%   csiSvd is the singular value decomposed CIR of multiple users.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector.
%   normFactor is the normalization factor, it can be a scalar or a numActiveSubc-length vector or a numUsers-length
%       cell array.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(strcmp(cfgEDMG.PHYType,'SC'),'phyMode should be SC');
assert(iscell(tdMimoChan),'tdMimoChan should be a cell array.');
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

scInfo = edmgSCInfo(cfgEDMG);
numTxAnt = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numUsers = cfgEDMG.NumUsers;
numSTSTot = sum(numSTSVec);

if isempty(cfgSim)
    processFlag = 1;
    svdFlag = 0;
    powAlloFlag = 0;
    precAlgoFlag = 1;
    precNormFlag = 0;
else
    processFlag = cfgSim.processFlag;
    svdFlag = cfgSim.svdFlag;
    powAlloFlag = cfgSim.powAlloFlag;
    precAlgoFlag = cfgSim.precAlgoFlag;
    precNormFlag = cfgSim.precNormFlag;
end
assert(ismember(precNormFlag,[0,1]),'precNormFlag should be 0 or 1.');

powAllo = cell(numUsers,1);

if processFlag <= 4 && svdFlag <= 3
    % Create the One-Tap TD CIR for all users
    if svdFlag == 0
        [precodMat,~,powAllo] = getSCMIMOLinearPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
            precAlgoFlag);
        csiSvd = [];
    elseif svdFlag == 1 || svdFlag == 2
        [precodMat,singularMat,postcodMat,~,powAllo] = getSCMIMOSVDPrecoder(tdMimoChan,noiseVarLin, ...
            numTxAnt,numSTSVec,precAlgoFlag,svdFlag);
        csiSvd.precodMat = precodMat;   % Ntx-by-Ntsts
        csiSvd.singularMat = singularMat;   % Nsts-by-Nsts
        csiSvd.postcodMat = postcodMat;   % Nsts-by-Nsts
    elseif svdFlag == 3
        [precodMat,~,powAllo] = getSCMIMOBlockDiagonalPrecoder(tdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
            precAlgoFlag);
        csiSvd = [];
    else
    end

    % Apply power allocation
    if powAlloFlag ~= 0
        precodMat = applyPowerAllocationToMUPrecoder(powAllo,precodMat,numSTSVec,'SC');
    end
    if precNormFlag == 0
        [precodMat,normFactor] = normalizeMultiUserPercoderJoint(precodMat,numSTSTot,'SC');
    else
        [precodMat,normFactor] = normalizeMultiUserPercoderIndividual(precodMat,numSTSVec,'SC');
    end
    % Set the spatial mapping based on the steering matrix
    spatialMapMat = permute(precodMat,[2 1]); % Ntsts-by-Ntx

elseif processFlag == 5 && precAlgoFlag == 5
    % MU Ring Precoding
    [precodMat,detMuCir] = getSCMIMOMuliTapPrecoder(tdMimoChan,numTxAnt,numSTSVec);
    
    if precNormFlag == 0
        [precodMat,normFactor] = normalizeMultiUserPercoderJoint(precodMat,numSTSTot,'SC');
    else
        [precodMat,normFactor] = normalizeMultiUserPercoderIndividual(precodMat,numSTSVec,'SC');
    end
    detCfr = getSUMIMOChannelFrequencyResponse(detMuCir,scInfo.NFFT);
    normFactor = detCfr * normFactor;
    
    % Set the spatial mapping based on the steering matrix
    spatialMapMat = permute(precodMat,[2 1 3]); % Ntsts-by-Ntx-by-Ntap
    csiSvd = [];
else
    spatialMapMat = [];
    csiSvd = [];
    normFactor = [];
end

end




