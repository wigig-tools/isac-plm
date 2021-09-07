function [weight] = getTxPrecodeFilterWeight(equiChan,numTxAnt,numSTSVec,phyMode,varargin)
%getTxPrecodeFilterWeight Transmit precoding filtering weight based on zero-forcing (ZF) or minimum mean square error
%   (MMSE) precoding criteria
%   
%   Inputs:
%   equiChan is 3D equivalent channel matrix with size of numActiveSubc-by-numTxAnt-by-numSTSTot for OFDM or 
%               2D equivalent channel matrix with size of numTxAnt-by-numSTSTot for SC. 
%   numTxAnt is the number of transmit antennas
%   phyMode is the PHYType of EDMG, 'OFDM' or 'SC'
%   varargin{1}: optional noiseVarLin noise variance in linear
%   varargin{2}: when scalar, varargin{2} is userIdx, 
%               otherwise, varargin{2} is effChanGainDiag, which is a numActiveSubc-by-numSTSTtot matrix, 
%               each row is the diagonal elements of effective channel gains 
%   
%   Outputs:
%   weight is 3D precoding weight matrix with size of numSubc-by-numTxAnt-by-numSTSTot for OFDM and 2D
%   precoding matrix with size of numTxAnt-by-numSTSTot for SC. 
%               When varargin{2} is userIdx, weight is a 3D precoding weight matrix with size of 
%               numSubc-by-numTxAnt-by-numSTSVec(userIdx) for OFDM or 2D precoding weight matrix with size of
%               numTxAnt-by-numSTSVec(userIdx).
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(4,6);
numSTSTot = sum(numSTSVec);

if nargin == 4
    deltaVal = 0; % Non or Zero-forcing
else
    if nargin>=5
        noiseVarLin = varargin{1};
        noiseVarDiag = reformatMultiUserNoiseVarianceIndividualStream(noiseVarLin,numSTSVec);
        deltaVal = numTxAnt * diag(noiseVarDiag);
    end
    if nargin==6
        if isscalar(varargin{2})
            userIdx = varargin{2};
        else
            effChanGainDiag = varargin{2};
        end
    end
end

% Channel inversion precoding
if strcmp(phyMode,'OFDM')
    assert(ndims(equiChan)==3 || (ismatrix(equiChan) && size(equiChan,1)>8),... 
        'Check dimention of equiChan for OFDM precoder.');
    assert(size(equiChan,2)==numTxAnt && size(equiChan,3)==numSTSTot, ...
        'The 2nd dim of equiChan should be equal to numTxAnt.');
    warning('off', 'MATLAB:nearlySingularMatrix'); %Avoid display message at each subcarrier
    warning('off', 'MATLAB:SingularMatrix');
    condCheck = zeros(1,size(equiChan,1));
    
    if nargin <= 5
        weight = zeros(size(equiChan)); % Nsdp-by-Ntx-by-Nsts
        for iSubc = 1:size(equiChan,1)
            muHMat = squeeze(equiChan(iSubc,:,:)); % Ntx-by-Nsts
            weight(iSubc,:,:) = muHMat/(muHMat'*muHMat + deltaVal); % Nsdp-by-Ntx-by-Nsts
            condCheck(iSubc) = 1/cond(muHMat'*muHMat);
        end
    else
        if isscalar(varargin{2})
            % Calculate user-specific precoder
            stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
            if isscalar(noiseVarLin)
                % Per-user level noise Variance
                suEquiChan = equiChan(:,:,stsIdx);
                deltaVal = numTxAnt * noiseVarLin * eye(numTxAnt);
                weight = zeros(size(suEquiChan)); % Nsdp-by-Ntx-by-Nsts
                for iSubc = 1:size(equiChan,1)
                    muHMat = squeeze(equiChan(iSubc,:,:)); % Ntx-by-Nsts
                    suHMat = reshape(squeeze(suEquiChan(iSubc,:,:)),[numTxAnt,numSTSVec(userIdx)]);
                    weight(iSubc,:,:) = (muHMat*muHMat' + deltaVal) \ suHMat; % Nsdp-by-Ntx-by-Nsts
                    condCheck(iSubc) = 1/cond(muHMat*muHMat');
                end
            elseif isvector(noiseVarLin)
                % Per-stream level noise Variance
                suEquiChan = equiChan(:,:,stsIdx);
                weight = zeros(size(suEquiChan)); % Nsdp-by-Ntx-by-Nsts
                for iSubc = 1:size(equiChan,1)
                    muHMat = squeeze(equiChan(iSubc,:,:)); % Ntx-by-Nsts
                    for iSS = 1:numSTSVec(userIdx)
                        ssHMat = reshape(suEquiChan(iSubc,:,iSS),[numTxAnt,1]);
                        deltaVal = numTxAnt * noiseVarLin(stsIdx(iSS)) * eye(numTxAnt);
                        weight(iSubc,:,iSS) = (muHMat*muHMat' + deltaVal) \ ssHMat; % Nsdp-by-Ntx-by-Nsts
                    end
                    condCheck(iSubc) = 1/cond(muHMat*muHMat');
                end
            end
        else
            % Calculate weighted MMSE precoder
            weight = zeros(size(equiChan)); % Nsdp-by-Ntx-by-Nsts
            for iSubc = 1:size(equiChan,1)
                muHMat = squeeze(equiChan(iSubc,:,:)); % Ntx-by-Nsts
                gMat = diag(effChanGainDiag(iSubc,:));
                weight(iSubc,:,:) = muHMat/(muHMat'*muHMat + deltaVal) * gMat; % Nsdp-by-Ntx-by-Nsts
                condCheck(iSubc) = 1/cond(muHMat'*muHMat);
            end 
        end
    end
    if sum(condCheck<eps)
        warning('Matrix is close to singular or badly scaled. Results may be inaccurate. ')
    end
    warning('on', 'MATLAB:nearlySingularMatrix')
    warning('on', 'MATLAB:SingularMatrix')
elseif strcmp(phyMode,'SC')
    assert(ismatrix(equiChan) && size(equiChan,1)<=8,'Check dimention of equiChan for SC precodeder.');
    assert(size(equiChan,1)==numTxAnt && size(equiChan,2)==numSTSTot, ...
        'The 2nd dim of equiChan should be equal to numTxAnt.');
    warning('off', 'MATLAB:nearlySingularMatrix'); %Avoid display message at each subcarrier
    warning('off', 'MATLAB:SingularMatrix');
    
    if nargin <= 5
        muHMat = equiChan; % Nt-by-Nsts
        weight = muHMat/(muHMat'*muHMat + deltaVal); % Ntx-by-Nsts
    else
        if isscalar(varargin{2})
            % Calculate user-specific precoder
            stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
            if isscalar(noiseVarLin)
                % Per-user level noise Variance
                suEquiChan = equiChan(:,stsIdx);
                deltaVal = numTxAnt * noiseVarLin * eye(numTxAnt);
                muHMat = equiChan; % Ntx-by-Nsts
                suHMat = reshape(suEquiChan,[numTxAnt,numSTSVec(userIdx)]);
                weight = (muHMat*muHMat' + deltaVal) \ suHMat; % Ntx-by-Nsts
            elseif isvector(noiseVarLin)
                % Per-stream level noise Variance
                suEquiChan = equiChan(:,stsIdx);
                muHMat = equiChan; % Ntx-by-Nsts
                weight = zeros(size(suEquiChan)); % Nsdp-by-Ntx-by-Nsts
                for iSS = 1:numSTSVec(userIdx)
                    ssHMat = reshape(suEquiChan(:,iSS),[numTxAnt,1]);
                    deltaVal = numTxAnt * noiseVarLin(stsIdx(iSS)) * eye(numTxAnt);
                    weight(:,iSS) = (muHMat*muHMat' + deltaVal) \ ssHMat; % Ntx-by-Nsts
                end
            end
        else
            % Calculate weighted MMSE precoder
            muHMat = equiChan; % Ntx-by-Nsts
            gMat = diag(effChanGainDiag);
            weight = muHMat/(muHMat'*muHMat + deltaVal) * gMat; %Ntx-by-Nsts
        end
    end
    condCheck = 1/cond(muHMat'*muHMat);
    if sum(condCheck<eps)
        warning('Matrix is close to singular or badly scaled. Results may be inaccurate. ')
    end
    warning('on', 'MATLAB:nearlySingularMatrix');
    warning('on', 'MATLAB:SingularMatrix');
end

end

