function [fdEquiMimoDataCfr] = getFDEquivalentMIMODataChannel(userIdx,tdMimoChan,fdMimoChan,equiChFlag,cfgEDMG,varargin)
%getFDEquivalentMIMODataChannel Get frequency domain equivalent MIMO channel for data field
%   This function obtains the frequency domain equivalent MIMO channel frequency response (CFR) for data field of EDMG.
%   
%   Inputs:
%   userIdx is an integer scalar of the user index 
%   tdMimoChan is the original time domain TDL channel impuluse respose (CIR); 
%       When in OFDM mode, it's a numTxAnt-by-numSTS single-user CIR cell array; 
%       while in SC mode, it is a numUsers-length multi-user CIR cell array, each entry is a numTxAnt-by-numSTS 
%       single user CIR sub cell array, which contains numTaps-by-1 column vector.
%   fdMimoChan is the original sinlge user frequency domain CFR in both OFDM and SC modes in a format of 
%       numSubc-by-numTxAnt-by-numSTS 3D matrix.
%   equiChFlag is the equivalent channel control flag, =0: not available; =1: use original channel frequency response;
%       =2: use precoded CFR; =3: the equivalent matrix is construced by U matrix and inverse of singular vector
%       from SVD. 
%   cfgEDMG is the EDMG configuration object defined by nist.edmgConfig
%   varargin{1} is an optional SVD structure of channel state information or an optional NFFT-length vector of scale 
%       factors in frequency-domain.
%   
%   Output
%   fdEquiMimoDataCfr is numSD-by-numSTS-by-numSTS 3D matrix of frequency-domain equivalent MIMO CFR
%
%   2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if isempty(tdMimoChan) && isempty(fdMimoChan) 
    error('One of tdlChanIR and fdMimoChan should not be bempty.');
end

% Index into streams for the user of interest
phyMode = cfgEDMG.PHYType;
numTxAnt = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numSTSTot = sum(numSTSVec);   % Num of total spatial streams for all active users
numSTS = numSTSVec(userIdx);
stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));

if equiChFlag < 2 && isempty(varargin{1})
    % If no spatial mapping matrix input is present
    spatialMapMat = eye(numSTSTot,numTxAnt);
    svdChan = [];
elseif equiChFlag == 2 && isa(varargin{1},'double')
    spatialMapMat = varargin{1};
    svdChan = [];
elseif equiChFlag == 3 && isa(varargin{1},'struct')
    svdChan = varargin{1};
    spatialMapMat = cfgEDMG.SpatialMappingMatrix;
elseif equiChFlag == 3 && isa(varargin{1},'double') && isvector(varargin{1})
    scaleFactor = varargin{1};
    svdChan = [];
    spatialMapMat = cfgEDMG.SpatialMappingMatrix;
else
    spatialMapMat = cfgEDMG.SpatialMappingMatrix;
end

if strcmp(phyMode,'OFDM')
    [ofdmInfo,ofdmInd,ofdmCfg] = nist.edmgOFDMInfo(cfgEDMG);
    % Get subcarrier index having data and pilot
    [activeSubcIdx, ~] = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    % Get frequency-domain equivalent MIMO channel matrix 
    if (~isempty(tdMimoChan) ) && isempty(fdMimoChan) 
        fdMimoChan = squeeze(getMIMOChannelFrequencyResponse(tdMimoChan,ofdmInfo.NFFT));
    end
    % Get data subcarreirs MIMO channel
    if size(fdMimoChan,1) == ofdmInfo.NSD
        fdMimoDataChan = fdMimoChan;
    elseif size(fdMimoChan,1) == length(activeSubcIdx)
        fdMimoDataChan = fdMimoChan(ofdmCfg.DataIndices,:,:);
    elseif size(fdMimoChan,1) == ofdmInfo.NFFT
        fdMimoDataChan = fdMimoChan(ofdmInd.DataIndices,:,:);
    else
        error('Size (dim 1) of fdMimoChan is not correct.');
    end
else
    % SC mode
    scInfo = edmgSCInfo(cfgEDMG);
    activeSubcIdx = 1:scInfo.NTONES;    
    if equiChFlag < 4
        if (~isempty(tdMimoChan{1,1}) ) && isempty(fdMimoChan)
            fdMimoDataChan = squeeze(getMIMOChannelFrequencyResponse(tdMimoChan{userIdx},scInfo.NFFT));
        else
            fdMimoDataChan = fdMimoChan;
        end
    end
end


%% Format Equivalent Channel  
if equiChFlag == 0
    % No equalization
    fdEquiMimoDataCfr = [];
elseif equiChFlag == 1
    % Use H
        fdEquiMimoDataCfr = fdMimoDataChan;
elseif equiChFlag == 2
    % Obtain FD equivalent channel on data subcarriers
    % Use H and SVD precoding matrix V (or Q matrix)
    if strcmp(phyMode,'OFDM')    
        fdEquiMimoDataCfr = complex(zeros(ofdmInfo.NSD,numSTS,numSTS));
        for iSubc = 1:ofdmInfo.NSD
            subcMimoChan = reshape(squeeze(fdMimoDataChan(iSubc,:,:)),numTxAnt,numSTS);
            if size(spatialMapMat,1)>numTxAnt
                subcSpatialMap = reshape(squeeze(spatialMapMat(ofdmCfg.DataIndices(iSubc),stsIdx,:)),numSTS,numTxAnt);
            else
                subcSpatialMap = spatialMapMat(stsIdx,:);
            end
            fdEquiMimoDataCfr(iSubc,:,:) = subcSpatialMap * subcMimoChan;
        end
    else
        % SC mode
        fdEquiMimoDataCfr = complex(zeros(scInfo.NTONES,numSTS,numSTS));
        for iSubc = 1:scInfo.NTONES
            subcMimoChan = reshape(squeeze(fdMimoDataChan(iSubc,:,:)),numTxAnt,numSTS);
            subcSpatialMap = spatialMapMat(stsIdx,:);
            fdEquiMimoDataCfr(iSubc,:,:) = subcSpatialMap * subcMimoChan;
        end
    end
elseif equiChFlag == 3
    % Use SVD S matrix and U matrix
    % Obtain FD equivalent channel on data subcarriers
    if strcmp(phyMode,'OFDM')       
        fdEquiMimoDataCfr = complex(zeros(ofdmInfo.NSD,numSTS,numSTS));
        for iSubc = 1:ofdmInfo.NSD
            combinMap = permute(squeeze(svdChan.postcodMat{userIdx}(ofdmCfg.DataIndices(iSubc),:,:)),[2,1]);
            singularVal = reshape(squeeze(svdChan.singularMat{userIdx}(ofdmCfg.DataIndices(iSubc),:,:)),numSTS,numSTS);
            fdEquiMimoDataCfr(iSubc,:,:) = singularVal^(-1) * combinMap;
        end
    else
        % SC mode
        fdEquiMimoDataCfr = zeros(scInfo.NFFT,numSTS,numSTS);
        for iSS = 1:numSTS
            fdEquiMimoDataCfr(:,iSS,iSS) = scaleFactor;
        end
    end
else
    error('equaChEst should be 0, 1, 2, 3.');
end      

end
