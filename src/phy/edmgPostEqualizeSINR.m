function [sinr,varargout] = edmgPostEqualizeSINR(chanEst,Es,noiseVar,userIdx,cfgEDMG,precoder,equalizer,varargin)
%edmgPostEqualizeSINR calculates the post-equalizer SINR per MIMO stream per single-user.

%   This function calcualtes the effective received post-processing signal-to-interference-plus-noise ratio (SINR)
%   per spatial-stream (SS) for specfic single user. Both OFDM and SC systems are supported. STBC is not supported.
%   
%   Inputs:
%   chanEst is a 4-D estimated channel matrix in frequency-domain, with a size numFFT-by-numSamp-by-numTx-by-numSS.
%       numFFT is the number of FFT point, numSamp is the number of Doppler samples, numTx is the number of Tx 
%       RF chains, numSS is the number of space-time streams.
%   Es is the energy per symbol, default as 1.
%   noiseVar is the noise variance
%   userIdx is the index of given user
%   cfgEDMG is the EDMG configuration object
%   precoder is the transmit precoding matrix with various size. When the precoder is not available, it has a
%       scalar value of 1, otherwise it is a numActiveSubc-numSTSTot-by-numTx frequency-domain multi-user 
%       precoding matrix for OFDM or a numSTSTot-by-numTxAnt-by-numTaps time-domain precoding matrix for SC.
%   equalizer is a numSD-by-numRx-by-numSS frequency-domain receiver equalization weight matrix, where numSD is the 
%       number of data subcarriers and numRx is the number of receiver RF chains. 
%   
%   Outputs:
%   sinr is post-equalizer SINR values in a numSD-by-numSS matrix for OFDM or a 1-by-numSS vector for SC.
%   varargout{1} is an optional received subband SNR values (snr) in a numSD-by-numTx-by-numSTS matrix for OFDM or 
%       a NFFT-by-numTx-by-numSTS matrix for SC.

%   2020~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(7,8);
nargoutchk(1,2);

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

assert(userIdx<=cfgEDMG.NumUsers,'userIdx should be less equal to numUsers.');
assert(Es>=0,'Es should be >=0.');
assert(noiseVar>=0,'noiseVar should be >=0.');

numTx = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numSTSTot = sum(numSTSVec,2);
numSS = numSTSVec(userIdx);
assert(size(chanEst,3)==numTx,'The dim-3 of chanEst should be equal to numTx.');
assert(size(chanEst,4)==numSS,'The dim-4 of chanEst should be equal to numSS.');
assert(isscalar(precoder) || ndims(precoder)<=3,'precoder is a scalar or ndims<=3.');
assert(isvector(equalizer) || ndims(equalizer)<=3,'equalizer is a matrix or ndims<=3.');

if strcmp(cfgEDMG.PHYType,'OFDM')
    [ofdmInfo,ofdmInd,ofdmCfg] = nist.edmgOFDMInfo(cfgEDMG);
    numSD = length(ofdmInd.DataIndices);
    if isempty(chanEst)
        snr = ones(numSD,1) * Es / noiseVar;
        sinr = snr;
    else
        assert(size(chanEst,1) == ofdmInfo.NFFT,'The dim-1 of chanEst should be equal to FFT-size.');
        if numSTSTot == 1
            % SISO
            snr = abs(chanEst(ofdmInd.DataIndices,1,1,1)).^2 * Es / noiseVar;
            sinr = snr;
        else
            % MIMO
            % Indies of current multi-STSs of user u out of all MU STSs
            ustsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
            mimoChan = permute(chanEst(ofdmInd.DataIndices,1,:,:),[1,3,4,2]);
            % Subband SNR
            snr = abs(mimoChan).^2 * Es / noiseVar; 
            % Subband post-equalizer SINR
            sinr = zeros(numSD,numSS);
            for iSS = 1:numSS
                for iSubc = 1:numSD
                    % Index of current iSTS-th STS of user u out of all MU STSs
                    stsIdx = sum(numSTSVec(1:userIdx-1))+iSS;
                    % Different precoder and equalizer dimensions
                    if isscalar(precoder) && ndims(equalizer)<=3
                        % when precAlgoFlag==0 && equaAlgoFlag>0
                        assert(cfgEDMG.NumUsers==1,'when precoder=1, SU-MIMO only (numUsers=1).');
                        wVec = conj(permute(equalizer(iSubc,:,iSS),[2,3,1]));
                        HMat = permute(mimoChan(iSubc,:,:),[3,2,1]);
                        sDiag = zeros(numTx,numTx);
                        sDiag(stsIdx,stsIdx) = 1;
                        powDes = real( Es * wVec' * HMat * sDiag * HMat' * wVec );
                        issiDiag = eye(numTx,numTx) - sDiag;
                        powIssi = real( Es * wVec' * HMat * issiDiag * HMat' * wVec );
                        powMui = 0;
                    elseif ndims(precoder)<=3 && isvector(equalizer)
                        % when precAlgoFlag>0 && equaAlgoFlag==0
                        % Desired signal
                        HMat = permute(mimoChan(iSubc,:,:),[3,2,1]);
                        wVec = zeros(numSS,1);
                        if size(equalizer,1)>numTx
                            wVec(iSS,1) = equalizer(iSubc);
                        else
                            wVec(iSS,1) = equalizer;
                        end
                        if size(precoder,1)>numTx
                            qVec = permute(precoder(ofdmCfg.DataIndices(iSubc),stsIdx,:),[3,2,1]);
                            QMatIssi = permute(precoder(ofdmCfg.DataIndices(iSubc),ustsIdx,:),[3,2,1]);
                            QMatMui = permute(precoder(ofdmCfg.DataIndices(iSubc),:,:),[3,2,1]);
                        else
                            qVec = permute(precoder(stsIdx,:),[2,1]);
                            QMatIssi = permute(precoder(ustsIdx,:),[2,1]);
                            QMatMui = permute(precoder(:,:),[2,1]);
                        end
                        QMatIssi(:,iSS) = [];
                        QMatMui(:,ustsIdx) = [];
                        % Desired signal
                        powDes = real( Es * wVec' * HMat * qVec * qVec' * HMat' * wVec );
                        % ISSI
                        powIssi = real( Es * wVec' * HMat * QMatIssi * QMatIssi' * HMat' * wVec );
                        % MUI
                        powMui = real( Es * wVec' * HMat * QMatMui * QMatMui' * HMat' * wVec );
                    else
                        % when precAlgoFlag>0 && equaAlgoFlag>0
                        HMat = permute(mimoChan(iSubc,:,:),[3,2,1]);    % numSS-by-numTx
                        wVec = conj(permute(equalizer(iSubc,:,iSS),[2,3,1]));   % numTx-by-numSS
                        if size(precoder,1)>numTx
                            qVec = permute(precoder(ofdmCfg.DataIndices(iSubc),stsIdx,:),[3,2,1]);
                            QMatIssi = permute(precoder(ofdmCfg.DataIndices(iSubc),ustsIdx,:),[3,2,1]);
                            QMatMui = permute(precoder(ofdmCfg.DataIndices(iSubc),:,:),[3,2,1]);
                        else
                            qVec = permute(precoder(stsIdx,:),[2,1]);
                            QMatIssi = permute(precoder(ustsIdx,:),[2,1]);
                            QMatMui = permute(precoder(:,:),[2,1]);
                        end
                        QMatIssi(:,iSS) = [];
                        QMatMui(:,ustsIdx) = [];
                        % Desired signal 
                        powDes = real( Es * wVec' * HMat * qVec * qVec' * HMat' * wVec );
                        % ISSI
                        powIssi = real( Es * wVec' * HMat * QMatIssi * QMatIssi' * HMat' * wVec );
                        % MUI
                        powMui = real( Es * wVec' * HMat * QMatMui * QMatMui' * HMat' * wVec );
                    end
                    % Noise 
                    powNoise = real( noiseVar * wVec' * wVec );
                    sinr(iSubc,iSS) = powDes / ( powIssi + powMui + powNoise );
                end
            end
            % Remove spatial streams with NaN data
            while iSS>0 && iSS <= size(sinr,2)
                if any(isnan(sinr(:,iSS)))
                    sinr(:,iSS) = [];
                end
                iSS = iSS-1;
            end
        end
    end
else
    % SC
    if nargin == 8
        scaleFactor = varargin{1};
    end
    scInfo = edmgSCInfo(cfgEDMG);
    if isempty(chanEst)
        snr = ones(scInfo.NTONES,1) * Es / noiseVar;
        sinr = snr;
    else
        assert(size(chanEst,1) == scInfo.NFFT,'The dim-1 of chanEst should be equal to FFT-size.');
        if numSTSTot == 1
            % SISO
            snr = abs(chanEst(:,1,1,1)).^2 * Es / noiseVar;
            sinr = ((1/scInfo.NFFT) * sum(1./(snr+1),1))^(-1) - 1;
        else
            % MIMO
            % Indies of current multi-STSs of user u out of all MU STSs
            ustsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
            % Transform TD precoder to FD precoder
            precoderFd = getSUMIMOChannelFrequencyResponse(precoder,scInfo.NFFT);    % fftSize-by-numSamp-by-numTx-by-numSS
            fdPrecoder = permute(precoderFd(:,1,:,:),[1,4,3,2]);    % fftSize-by-numSS-by-numTx-by-numSamp
            mimoChan = permute(chanEst(:,1,:,:),[1,3,4,2]);
            % Subband SNR
            snr = abs(mimoChan).^2 * Es / noiseVar; 
            % Time-domain post-equalizer SINR
            sinr = zeros(1,numSS);
            % Different precoder dimension
            if ismatrix(precoder)
                % when precAlgoFlag 1~4;
                for iSS = 1:numSS
                    % Index of current iSTS-th STS of user u out of all MU STSs
                    stsIdx = sum(numSTSVec(1:userIdx-1))+iSS;
                    fdAmpDes = zeros(scInfo.NFFT,1);
                    fdPowDes = zeros(scInfo.NFFT,1);
                    fdPowIssi = zeros(scInfo.NFFT,1);
                    fdPowMui = zeros(scInfo.NFFT,1);
                    fdPowNoise = zeros(scInfo.NFFT,1);
                    for iSubc = 1:scInfo.NFFT
                        HMat = permute(mimoChan(iSubc,:,:),[3,2,1]);    % numSS-by-numTx
                        wVec = conj(permute(equalizer(iSubc,:,iSS),[2,3,1]));   % numTx-by-numSS
                        if size(fdPrecoder,1)>numTx
                            qVec = permute(fdPrecoder(iSubc,stsIdx,:),[3,2,1]);
                            QMatIssi = permute(fdPrecoder(iSubc,ustsIdx,:),[3,2,1]);
                            QMatMui = permute(fdPrecoder(iSubc,:,:),[3,2,1]);
                        else
                            qVec = permute(fdPrecoder(stsIdx,:),[2,1]);
                            QMatIssi = permute(fdPrecoder(ustsIdx,:),[2,1]);
                            QMatMui = permute(fdPrecoder(:,:),[2,1]);
                        end
                        QMatIssi(:,iSS) = [];
                        QMatMui(:,ustsIdx) = [];
                        % Desired signal 
                        fdAmpDes(iSubc) = wVec' * HMat * qVec;
                        fdPowDes(iSubc) = real( Es * wVec' * HMat * qVec * qVec' * HMat' * wVec );                     
                        % ISSI
                        fdPowIssi(iSubc) = real( Es * wVec' * HMat * QMatIssi * QMatIssi' * HMat' * wVec );
                        % MUI
                        fdPowMui(iSubc) = real( Es * wVec' * HMat * QMatMui * QMatMui' * HMat' * wVec );
                        % Noise 
                        fdPowNoise(iSubc) = real( noiseVar * wVec' * wVec );
                    end
                    powDes = real( Es * (1/scInfo.NFFT)^2 * abs(sum(fdAmpDes))^2 );
                    powRisi = (1/scInfo.NFFT) * sum(fdPowDes) - powDes;
                    powIssi = (1/scInfo.NFFT) * sum(fdPowIssi);
                    powMui = (1/scInfo.NFFT) * sum(fdPowMui);
                    powNoise = (1/scInfo.NFFT) * sum(fdPowNoise);
                    sinr(iSS) = real( powDes / ( powRisi + powIssi + powMui + powNoise ) );
                end
            elseif ndims(precoder)==3 && size(precoder,1)==numSTSTot
                % when precAlgoFlag = 5;
                fdPrecoder = sqrt(1/scInfo.NFFT) * fdPrecoder;
                for iSS = 1:numSS
                    % Index of current iSTS-th STS of user u out of all MU STSs
                    stsIdx = sum(numSTSVec(1:userIdx-1))+iSS;
                    wVec = conj(reshape(equalizer(:,iSS,iSS),[scInfo.NFFT,1]));
                    % Frequency-domain 
                    fdAmpDes = zeros(scInfo.NFFT,1);
                    fdPowDes = zeros(scInfo.NFFT,1);
                    fdPowIssi = zeros(scInfo.NFFT,1);
                    fdPowMui = zeros(scInfo.NFFT,1);
                    for iSubc = 1:scInfo.NFFT
                        hVec = permute(mimoChan(iSubc,:,iSS),[3,2,1]);
                        qVec = permute(fdPrecoder(iSubc,stsIdx,:),[3,2,1]);
                        QMatIssi = permute(fdPrecoder(iSubc,ustsIdx,:),[3,2,1]);
                        QMatIssi(:,iSS) = [];
                        QMatMui = permute(fdPrecoder(iSubc,:,:),[3,2,1]);
                        QMatMui(:,ustsIdx) = [];
                        % Desired signal 
                        fdAmpDes(iSubc) = wVec(iSubc)' * scaleFactor(iSubc);
                        fdPowDes(iSubc) = real( Es * abs(wVec(iSubc)).^2 * abs(scaleFactor(iSubc)).^2 );
                        % ISSI
                        fdPowIssi(iSubc) = real( Es * abs(wVec(iSubc)).^2 * hVec * QMatIssi * QMatIssi' * hVec' );
                        % MUI
                        fdPowMui(iSubc) = real( Es * abs(wVec(iSubc)).^2 * hVec * QMatMui * QMatMui' * hVec' );
                    end
                    powDes = real( Es * (1/scInfo.NFFT)^2 * abs(sum(fdAmpDes))^2 );
                    powRisi = (1/scInfo.NFFT) * sum(fdPowDes) - powDes;
                    powIssi = (1/scInfo.NFFT) * sum(fdPowIssi);
                    powMui = (1/scInfo.NFFT) * sum(fdPowMui);
                    % Noise 
                    fdPowNoise = real( noiseVar * abs(wVec).^2 );
                    powNoise = (1/scInfo.NFFT) * sum(fdPowNoise);
                    sinr(iSS) = real( powDes / ( powRisi + powIssi + powMui + powNoise ) );
                end
            else
                error('precoder format is incorrect.');
            end
            % Remove spatial streams with NaN data
            while iSS>0 && iSS <= size(sinr,2)
                if any(isnan(sinr(:,iSS)))
                    sinr(:,iSS) = [];
                end
                iSS = iSS-1;
            end
        end
    end
end
varargout{1} = snr;

end

