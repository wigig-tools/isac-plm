function [spatialMapMat,csiSvd,powAllo,normFactor] = getOFDMTxFDMIMOPrecoder(tdMimoChan,fdMimoChan,noiseVarLin,cfgEDMG,cfgSim)
%getOFDMTxFDMIMOPrecoder Get OFDM transmit time-domain MIMO precoder
%   [spatialMapMat,csiSvd,powAllo] = getOFDMTxFDMIMOPrecoder(tdMimoChan,fdMimoChan,noiseVarLin,cfgEDMG,cfgSim) performs 
%       time-domain MIMO precoding for EDMG OFDM transmitter.
%
%   Inputs:
%   tdMimoChan is a numUsers-length cell array of time-domain MIMO channels. Each cell holds the user's time-domain
%       MIMO channel impluse response (CIR), each entry is a numTxAnt-by-numRxAnt subcell array, which contains the 
%       maxTdlLen-by-1 column vectors. maxTdlLen is the maximum TDL tap length.
%   fdMimoChan is either the numUser-length MU MIMO channel frequency response (CFR) cell array, each entry is a 
%       fftSize-by-numTx-by-numSTS or a numActiveSubc-by-numTx-by-numSTS matrix of single user MIMO CFR. 
%       The numActiveSubc is the number of data and pilot subcarriers.
%   noiseVarLin is the noise variance in linear, which can be in various formats: when noiseVarLin is a numUsers
%       length cell array, each cell holds a numSTS-length noise variance of that user. The numSTS is the number
%       of space-time streams of that user. When noiseVarLin is a numSTSTot-length vector, each element is the 
%       noise variance of the space-time stream of a user. When noiseVarLin is numSTS-by-numUsers matrix, each column
%       vector is the multi-steam noise variance vector of that user.
%   cfgEDMG is the object accroding to nist.edmgConfig.
%   cfgSim is the structure holding the parameters of simulation configuration.
%
%   Outputs:
%   spatialMapMat is a numActiveSubc-by-numSTSTot-by-numTxAnt frequency-domain multi-user precoding matrix.
%   csiSvd is the singular value decomposed CFR of multiple users.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSubc-by-numSTS matrix.
%   normFactor is the normalization factor, it can be a scalar or a numActiveSubc-length vector or a numUsers-length
%       cell array.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

assert(strcmp(cfgEDMG.PHYType,'OFDM'),'phyMode should be OFDM');

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

%% Get FD CTF
[ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
fftLength = ofdmInfo.NFFT;
[activeSubcIdx, ~] = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
if (~isempty(tdMimoChan) ) && ( isempty(fdMimoChan) )
    if iscell(tdMimoChan) && size(tdMimoChan{1},1) == numTxAnt && size(tdMimoChan{1},2) == numSTSVec(1)
        % tdMimoChan is numUser-by-1 cell array with cell entry as numTxAnt-by-numSTSVec(userIdx) matrix
        fdMimoChan = squeeze(getMIMOChannelFrequencyResponse(tdMimoChan,fftLength));
    elseif ndims(tdMimoChan) >= 2 && size(tdMimoChan,1) == numTxAnt && size(tdMimoChan,2) == numSTSTot
        % tdMimoChan is numTxAnt-by-numSTSTot-by-maxTapLen 3D MU-MIMO matrix
        fdMimoChan = squeeze(getSUMIMOChannelFrequencyResponse(tdMimoChan,fftLength));
    else
        error('tdMimoChan format should be either cell array or 3D matrix.');
    end
elseif (isempty(tdMimoChan) ) && ( isempty(fdMimoChan) ) 
    error('One of tdMimoChan and fdMimoChan should not be bempty.');
end

%% FD Digital Precoding
if processFlag <=4 && precAlgoFlag <=4
    % Precoding
    if svdFlag == 0
        [precodMat,~,powAllo] = getOFDMMIMOLinearPrecoder(fdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
            fftLength,activeSubcIdx,precAlgoFlag);
        csiSvd = [];
    elseif svdFlag == 1 || svdFlag == 2
        [precodMat,singularMat,postcodMat,~,powAllo] = getOFDMMIMOSVDPrecoder(fdMimoChan,noiseVarLin, ...
            numTxAnt,numSTSVec,fftLength,activeSubcIdx,precAlgoFlag,svdFlag);
        csiSvd.precodMat = precodMat;     % Nsdp-by-Ntx-by-Nsts
        csiSvd.singularMat = singularMat;   % Nsdp-by-Nsts-by-Nsts
        csiSvd.postcodMat = postcodMat;   % Nsdp-by-Nsts-by-Nsts
    elseif svdFlag == 3
        [precodMat,~,powAllo] = getOFDMMIMOBlockDiagonalPrecoder(fdMimoChan,noiseVarLin,numTxAnt,numSTSVec, ...
            fftLength,activeSubcIdx,precAlgoFlag);
        csiSvd = [];
    else
    end

    % Apply power allocation
    if powAlloFlag ~= 0
        precodMat = applyPowerAllocationToMUPrecoder(powAllo,precodMat,numSTSVec,'OFDM');
    end
    if precNormFlag == 0
        [precodMat,normFactor] = normalizeMultiUserPercoderJoint(precodMat,numSTSTot,'OFDM');
    else
        [precodMat,normFactor] = normalizeMultiUserPercoderIndividual(precodMat,numSTSVec,'OFDM');
    end

    % Set the spatial mapping based on the precoding matrix
    spatialMapMat = permute(precodMat,[1 3 2]); % Nsdp-by-Nsts-by-Ntx
    
else
    powAllo = [];
    spatialMapMat = [];
    csiSvd = [];
    normFactor = [];
end


end

