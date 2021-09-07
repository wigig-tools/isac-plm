function [H] = edmgChannelEstimate(EDMG_CEF, cfgEDMG)
%EDMGCHANNEL_ESTIMATION EDMG Channel Estimaton Field (EDMG-STF) MIMO
%channel estimation
%
%
%   H = EDMGCHANNEL_ESTIMATION(edmg_cef, cfgEDMG) returns the estimated
%   channel response.
%
%   edmg_stf is the time-domain  EDMG-STF signal. It is a complex Ns x N_STS
%   matrix where Ns represents the number of time-domain samples and N_STS
%   is the number of received MIMO streams.
%
%   CFGDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the DMG format.
%
%   In OFDM system H is the channel frequency response of dimensions
%   NTONES x NRX x NSTS
% 
%   In SC systems H is the channel impulse response of dimensions 
%   N_RX x N_STS x N (128*Ncb)
%
%   2020~2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

N_STS = sum(cfgEDMG.NumSpaceTimeStreams);   % Total number of space-time streams
N_RX = size(EDMG_CEF, 2);
N = 128 * cfgEDMG.NumContiguousChannels;
[P, N_EDMG_CEF] = edmgCEConfig(cfgEDMG);
QMat = getPreambleSpatialMap(cfgEDMG);

if strcmpi(cfgEDMG.PHYType, 'OFDM')
    [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
    NFFT = ofdmInfo.NFFT;
    [NGI,~] = edmgGIInfo(cfgEDMG,'Long');     % Long guard interval: NGI = NCB*192 
    NSYMB = NFFT+NGI;
    CEF_grid_idx = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    NTONES =  ofdmInfo.NTONES;
    CFR_est = zeros(N_RX,N_STS,NTONES);
    TX_SEQ = edmgCEFSeq(1:N_STS);
    QMat = squeeze(QMat(1,:,:))';
    rxsym = zeros(NTONES,N_EDMG_CEF,N_RX);
    for rx_ant = 1:N_RX
        EDMG_CEF_rx = reshape(EDMG_CEF(:,rx_ant), NSYMB,[]);
        EDMG_CEF_rx = EDMG_CEF_rx(NGI+1:end,:);
        EDMG_CEF_rx_fft = fftshift(fft(EDMG_CEF_rx,NFFT, 1),1)/(NFFT/sqrt(NTONES*N_STS));
        rxsym(:,:,rx_ant ) = EDMG_CEF_rx_fft(CEF_grid_idx,:);
        if strcmp(cfgEDMG.PreambleSpatialMappingType, 'Custom')
            CFR_est(rx_ant, :, : ) = ((rxsym(:,:,rx_ant ) *P'.*conj(TX_SEQ)/N_EDMG_CEF)).'; % Return equivalent channel
        else
            CFR_est(rx_ant, :, : ) = ((rxsym(:,:,rx_ant ) *P'.*conj(TX_SEQ)/N_EDMG_CEF)*QMat).'; % Match tx QMat
        end
    end
    H = permute(CFR_est,[3 1 2]);

    
elseif strcmpi(cfgEDMG.PHYType, 'SC')
    CIR_est=  zeros(N_RX, N_STS, N_EDMG_CEF, N);
    EDMG_CEF = [zeros(N,N_RX); EDMG_CEF];
    EDMG_CEF = reshape(EDMG_CEF, [10*N, N_EDMG_CEF, N_RX]);
    EDMG_CEF = EDMG_CEF(N+1:end,:,:);
    
    %% Generate Ga for the ss_id
    for cef_id = 1:N_EDMG_CEF
        for tx_ant = 1:N_STS
            [Ga, Gb] = nist.edmgGolaySequence(N, tx_ant);
            Gac = Ga(end:-1:1);
            Gbc = Gb(end:-1:1);
            for rx_ant = 1:N_RX
                ant_rx_edmg_cef = EDMG_CEF(:,cef_id,rx_ant);
                
                corrGa = conv(ant_rx_edmg_cef,conj(Gac));
                corrGb = conv(ant_rx_edmg_cef,conj(Gbc));
                
                corrGa = corrGa(N+1:end);
                corrGb = corrGb(1:end-N);
                
                sum_ab = corrGa+corrGb;
                diff_ab = corrGa-corrGb;
                
                seq1 = sum_ab(1:2*N);
                seq2 = diff_ab(2*N+1:4*N);
                seq3 = diff_ab(4*N+1:6*N);
                seq4 = sum_ab(6*N+1:8*N);
                
                av_seq = seq1 + seq2 - seq3 + seq4;
                
                CIR_est(rx_ant,tx_ant,cef_id,:) = -P(tx_ant, cef_id)*av_seq(N:2*N-1)/(8*N)*sqrt(N_STS);
            end
        end
    end
    if strcmp(cfgEDMG.PreambleSpatialMappingType, 'Custom')
        H = (mean(CIR_est,3));
        sz = size(H);
        H = reshape(H,sz(unique([1 find(sz~=1)])));

    else
        Htemp = (mean(CIR_est,3));
        sz = size(Htemp);
        Htemp = reshape(Htemp,sz(unique([1 find(sz~=1)])));
        H2D     = reshape(permute(Htemp,[1 3 2]), N_RX*size(Htemp,3), []);
        H       = permute(reshape((H2D*QMat').',  N_STS,N_RX,[]), [2,1,3]);
    end
end

end