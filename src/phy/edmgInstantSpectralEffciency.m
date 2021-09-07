function [specEffSumUser,specEffIndiUser,peSinr] = edmgInstantSpectralEffciency(fdMimoChan,Es,noiseVar,cfgEDMG, ...
    spatialMapMat,mimoEquaWeight,varargin)
%edmgSpectralEffciency spectral efficiency
%   This function calculates the instant spectral efficiency of OFDM and SC MIMO systems based on Continuous-input 
%   Continuous-output Memoryless Channel (CCMC) capacity.
%   
%   Inputs:
%   fdMimoCfr is the numUser-length frequency domain CFR cell array, each entry is a fftSize-by-numTxAnt-by-numSTS 3D
%       matrix
%   Es is a scaler of symbol energy
%   noiseVar is a scaler of noise variance
%   cfgEDMG is the EDMG configuration ojbect
%   spatialMapMat is a numSTSTot-by-numTxAnt-by-numTaps time-domain precoding matrix or 
%       numActiveSubc-numSTSTot-by-numTxAnt frequency-domain multi-user precoding matrix.
%   mimoEquaWeight is a complex-valued equalization weight matrix with size Nsd x Nr x Nsts.
%   varargin is an optional scale factor.
%
%   Outputs:
%   specEffSumUser is a scaler of sum spectral efficiency of all users
%   specEffIndiUser is a numUsers-length vector of spectral efficiency of individual users
%   peSinr is a numUsers-length vector of the post-equalizer SINR values

%   2020~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

numUsers = cfgEDMG.NumUsers;
numTx = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numSTSTot = sum(numSTSVec,2);

assert(numTx==numSTSTot,'The number of transmit RF chains (numTx) should be equal to the number total space-time streams (numSTSTot).');

narginchk(6,7);
if nargin == 7 && strcmp(cfgEDMG.PHYType,'SC')
    scaleFactor = varargin{1};
end

        
if isscalar(noiseVar)
    noiseVarMu = noiseVar*ones(1,numUsers);
elseif isvector(noiseVar) && length(noiseVar)==numUsers
    noiseVarMu = noiseVar;
elseif iscell(noiseVar) && length(noiseVar)==numUsers
    noiseVarMu = cell2mat(noiseVar);
else
    error('The format of noiseVarLin is incorrect.');
end

peSinr = cell(numUsers,1);
specEffIndiUser = zeros(numUsers,1);
if strcmp(cfgEDMG.PHYType,'OFDM')
    % OFDM
    ofdmInfo = nist.edmgOFDMInfo(cfgEDMG);
    for iUser = 1:numUsers
        if isempty(fdMimoChan)
            peSinrSubc = edmgPostEqualizeSINR(fdMimoChan,Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser});
        else
            % Calculate Post-equalizer SINR
            peSinrSubc = edmgPostEqualizeSINR(fdMimoChan{iUser},Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser});
        end
        % Calculate individual user spectral efficiency over multiple spatial streams
        numSTS = size(peSinrSubc,2);
        instSpecEffIndiSts = zeros(numSTS,1);
        for iSTS = 1:numSTS
            instSpecEffIndiSts(iSTS,1) = (ofdmInfo.NFFT/(ofdmInfo.NFFT+ofdmInfo.NGI)) * mean( log2(1 + peSinrSubc(:,iSTS) ), 1);
        end
        peSinr{iUser} = peSinrSubc;
        specEffIndiUser(iUser) = sum(instSpecEffIndiSts,1);
    end
    % Get sum user spectral efficiency
    specEffSumUser = sum(specEffIndiUser,1);
elseif strcmp(cfgEDMG.PHYType,'SC')
    % SC
    scInfo = edmgSCInfo(cfgEDMG);
    for iUser = 1:numUsers
        % Calculate Post-equalizer SINR
        if nargin == 7
            if isempty(scaleFactor)
                beta = 1;
            elseif iscell(scaleFactor)
                beta = scaleFactor{iUser};
            else
                beta = scaleFactor;
            end
            if isempty(fdMimoChan)
                peSinrBlk = edmgPostEqualizeSINR(fdMimoChan,Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser},beta);
            else
                peSinrBlk = edmgPostEqualizeSINR(fdMimoChan{iUser},Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser},beta);
            end
        else
            if isempty(fdMimoChan)
                peSinrBlk = edmgPostEqualizeSINR(fdMimoChan,Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser});
            else
                peSinrBlk = edmgPostEqualizeSINR(fdMimoChan{iUser},Es,noiseVarMu(iUser),iUser,cfgEDMG,spatialMapMat,mimoEquaWeight{iUser});
            end
        end
        % Calculate individual user spectral efficiency over multiple spatial streams
        numSTS = size(peSinrBlk,2);
        instSpecEffIndiSts = zeros(numSTS,1);
        for iSTS = 1:numSTS
            instSpecEffIndiSts(iSTS,1) = ((scInfo.NFFT - scInfo.NGI)/(scInfo.NFFT)) * log2(1 + peSinrBlk(iSTS) );
        end
        peSinr{iUser} = peSinrBlk;
        specEffIndiUser(iUser) = sum(instSpecEffIndiSts,1);
    end
    % Get sum user spectral efficiency
    specEffSumUser = sum(specEffIndiUser,1);
else
    error('OFDM or SC mode only');
end

end

