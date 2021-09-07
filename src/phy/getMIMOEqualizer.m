function [mimoEquaWeight,dataFdMimoChan] = getMIMOEqualizer(phyParams,simuParams,tdMimoChan,fdMimoChan,estNoiseVar)
%getMIMOEqualizer Calculate MIMO equalizer based on channel knowledge and noise power without received signal
%   Inputs
%   phyParams is a PHY parameter struct
%   simuParams is a simulation parameter struct
%   tdMimoChan is a numUser length TDL channel impluse response (CIR) cell array
%   fdMimoChan is a numUser length TDL channel frequency response (CFR) cell array
%   estNoiseVar is an estimated noise var
%   
%   Outputs
%   mimoEquaWeight is a weight matrix of equalizer
%   dataFdMimoChan is a equivalent channel matrix for data subcarriers

%	2021 NIST/CTL Jiayi Zhang
%   This file is available under the terms of the NIST License.

%#codegen

if phyParams.equiChFlag < 2
    eqMapObj = [];
elseif phyParams.equiChFlag == 2
    eqMapObj = phyParams.spatialMapMat;
elseif phyParams.equiChFlag >= 3
    eqMapObj = phyParams.svdChan;
else
    error('equiChFlag should be one of 0,1,2,3.');
end 

% Obtain FD estimated channel on data subcarriers
dataFdMimoChan = cell(phyParams.numUsers,1);
mimoEquaWeight = cell(phyParams.numUsers,1);

for iUser = 1:phyParams.numUsers
    if isempty(fdMimoChan)
        mimoEquaWeight{iUser} = ones(phyParams.numSTSVec(iUser));
    else
    
        % Consider to permute and use subcarrier in the last dimension.
        % This condition is set because we lose one dimension when STS is 1. 
        if min(cellfun(@(x) ndims(x), fdMimoChan))==4 || ...
           (min(cellfun(@(x) ndims(x), fdMimoChan))==3 && ...
           any(phyParams.cfgEDMG.NumSpaceTimeStreams==1) ) %This condition is set because we 

            % Remove doppler dimension assuming ideal channel estimation of the first doppler realization
            fdMimoChan = cellfun(@(x) squeeze(x(:,1,:,:)), fdMimoChan, ...
                'UniformOutput', false);
            % Remove doppler dimension assuming ideal channel estimation of the first doppler realization
            selectFirstTdl = @(y) cellfun(@(x) x(:, 1), y, 'UniformOutput', false);
            tdMimoChan = cellfun(@(x) selectFirstTdl(x),tdMimoChan, ...
                'UniformOutput', false);
        end

        if isempty(phyParams.precScaleFactor)
            beta = 1;
        elseif iscell(phyParams.precScaleFactor)
            beta = phyParams.precScaleFactor{iUser};
        else
            beta = phyParams.precScaleFactor;
        end
        if strcmp(phyParams.phyMode,'OFDM')
            dataFdMimoChan{iUser} = getFDEquivalentMIMODataChannel(iUser,tdMimoChan{iUser},fdMimoChan{iUser},phyParams.equiChFlag,phyParams.cfgEDMG,eqMapObj);
        else
            % SC
            if phyParams.equiChFlag == 3
                dataFdMimoChan{iUser} = squeeze(getFDEquivalentMIMODataChannel(iUser,tdMimoChan,fdMimoChan{iUser},phyParams.equiChFlag,phyParams.cfgEDMG,beta));
            else
                dataFdMimoChan{iUser} = squeeze(getFDEquivalentMIMODataChannel(iUser,tdMimoChan,fdMimoChan{iUser},phyParams.equiChFlag,phyParams.cfgEDMG,eqMapObj));
            end
        end
        % Receiver Equalization Matrix
        if phyParams.equaAlgoFlag==0
            mimoEquaWeight{iUser} = 1./beta;
        elseif phyParams.equaAlgoFlag == 1 || phyParams.equaAlgoFlag == 3
            [~,~,mimoEquaWeight{iUser}] = nist.edmgMIMOEqualize([],dataFdMimoChan{iUser},phyParams.equaAlgoStr);
        else
            noiseVarLin = estNoiseVar;
            if iscell(noiseVarLin)
                noiseVarEst = phyParams.numTxAnt * mean(noiseVarLin{iUser});
            elseif ismatrix(noiseVarLin) && size(noiseVarLin,1)==phyParams.numUsers
                noiseVarEst = phyParams.numTxAnt * mean(noiseVarLin(iUser,:));
            elseif isvector(noiseVarLin) && length(noiseVarLin)==phyParams.numSTSTot
                noiseVarEst = phyParams.numTxAnt * mean(noiseVarLin(stsIdx));
            elseif isvector(noiseVarLin) && length(noiseVarLin)==phyParams.numSTSVec(iUser)
                noiseVarEst = phyParams.numTxAnt * mean(noiseVarLin);
            elseif isscalar(noiseVarLin)
                noiseVarEst = phyParams.numTxAnt * noiseVarLin;
            else
                error('noiseVarLin format is incorrect.');
            end
            [~,~,mimoEquaWeight{iUser}] = nist.edmgMIMOEqualize([],dataFdMimoChan{iUser},simuParams.equaAlgoStr,noiseVarEst);
        end
    end
end

end

