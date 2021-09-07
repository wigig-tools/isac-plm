function [spatialMapMat,csiSvd,powAllo,normFactor] = edmgTxMIMOPrecoder(tdMimoChan,fdMimoChan,noiseVarLin,cfgEDMG,cfgSim)
%edmgTxMIMOPrecoder EDMG transmit MIMO precoder
%
%   [spatialMapMat,csiSvd,powAllo] = getSCTxTDMIMOPrecoder(tdMimoChan,fdMimoChan,noiseVarLin,cfgEDMG,cfgSim) performs 
%   MIMO precoding for EDMG single-carrier (SC) and OFDM transmitters.
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
%   spatialMapMat is a numSTSTot-by-numTxAnt-by-numTaps time-domain precoding matrix or 
%       numActiveSubc-numSTSTot-by-numTxAnt frequency-domain multi-user precoding matrix.
%   csiSvd is the singular value decomposed CIR or CFR of multiple users.
%   powAllo is a numUsers-length power allocation cell array, each cell holds a numSTS-length row vector for OFDM or
%       a numSTS-length row vector for SC.
%   normFactor is the normalization factor, it can be a scalar or a numActiveSubc-length vector for OFDM or 
%       a numUsers-length cell array for SC.

%	2019~2021 NIST/CTL <jiayi.zhang@nist.gov>

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

phyMode = cfgEDMG.PHYType;
smType = cfgEDMG.SpatialMappingType;
numTxAnt = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numSTSTot = sum(numSTSVec);

% Consider to permute and use subcarrier in the last dimension.
% This condition is set because we lose one dimension when STS is 1. 
if min(cellfun(@(x) ndims(x), fdMimoChan))==4 || ...
   (min(cellfun(@(x) ndims(x), fdMimoChan))==3 && ...
   any(cfgEDMG.NumSpaceTimeStreams==1) )
        
    % Remove doppler dimension assuming ideal channel estimation of the first doppler realization
    fdMimoChan = cellfun(@(x) squeeze(x(:,1,:,:)), fdMimoChan, ...
        'UniformOutput', false); 
    % Remove doppler dimension assuming ideal channel estimation of the first doppler realization
    selectFirstTdl = @(y) cellfun(@(x) x(:, 1), y, 'UniformOutput', false);
    tdMimoChan = cellfun(@(x) selectFirstTdl(x),tdMimoChan, ...
        'UniformOutput', false);  
end

if strcmp(smType,'Direct')
    spatialMapMat = eye(numSTSTot,numTxAnt);  % 1;  % 
    csiSvd = [];
    powAllo = ones(1,numTxAnt);   % Nsdp-by-Nsts
    normFactor = 1;
elseif strcmp(smType,'Hadamard')
    whMat = hadamard(8);
    spatialMapMat = whMat(1:numSTSTot, 1:numTxAnt)/sqrt(numTxAnt);
    csiSvd = [];
    powAllo = ones(1,numTxAnt);   % Nsdp-by-Nsts
    normFactor = 1;
elseif strcmp(smType,'Fourier')
% The following can be obtained from dftmtx(numTx) which however does not generate code
%     spatialMapMat = dftmtx(numTxAnt)/sqrt(numTxAnt);
    [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
    spatialMapMat = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
    csiSvd = [];
    powAllo = ones(1,numTxAnt);   % Nsdp-by-Nsts
    normFactor = 1;
elseif strcmp(smType,'Custom')
    % Digital Beamforming
    if strcmp(phyMode,'OFDM')
        [spatialMapMat,csiSvd,powAllo,normFactor] = getOFDMTxFDMIMOPrecoder(tdMimoChan,fdMimoChan,noiseVarLin,cfgEDMG,cfgSim);
    elseif strcmp(phyMode,'SC')
        % SC TD-Precoding
        [spatialMapMat,csiSvd,powAllo,normFactor] = getSCTxTDMIMOPrecoder(tdMimoChan,noiseVarLin,cfgEDMG,cfgSim);
    else
        error('phyMode should be either OFDM or SC.');
    end
end

end

