function EDMG_STF = edmgSTF(cfgEDMG)
%EDMGSTF EDMG Short Training Field (EDMG-STF)
%
%   Y = EDMGSTF(CFGEDMG) generates the EDMG Short Training Field (STF)
%   time-domain signal for the EDMG transmission format.
%
%   Y is the time-domain EDMG STF signal. It is a complex matrix of size
%   Ns-by-1, where Ns represents the number of time-domain samples.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig
%   specifies the parameters for the EDMG format.

%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

N_STS = sum(cfgEDMG.NumSpaceTimeStreams,2); % Total number of space-time streams
N_TX = cfgEDMG.NumTransmitAntennas;

if  strcmp(phyType(cfgEDMG),'SC')
    NCB = cfgEDMG.NumContiguousChannels;
    QMat = permute(getPreambleSpatialMap(cfgEDMG),[2 1 3]);
    
    NGA = 19;
    LENGTH_GOLAY = 128;
    LENGTH_STF = LENGTH_GOLAY * NCB * NGA;
    % Generate EDMG-STF Field for EDMG-SC PHY
    STFSeq = zeros(LENGTH_STF, N_STS);
    
    % Generate Ga for Gb for different stream indicies
    Ga_Mat = cell(N_STS, 1);
    
    for j = 1:N_STS
        % Get the corresponding Golay Sequence for stream (j).
        [Ga, ~] = nist.edmgGolaySequence(LENGTH_GOLAY * NCB, j);
        Ga_Mat{j} = Ga;
        
        % Generate STF for Stream
        STFSeq(:,j) = [repmat(Ga, NGA-1, 1); -Ga];
    end
    
    % Generate EDMG-STF for each Transmit RF Chain.
    EDMG_STF = zeros(LENGTH_STF , N_TX);
    
    if size(QMat,3) == 1
        % Matrix multiplication
        for i = 1:N_TX
            for j = 1:N_STS
                EDMG_STF(:, i) = EDMG_STF(:, i) + QMat(i,j) * STFSeq(:,j);
            end
        end
    else
        % 3D QMat is used with time domain convolution. The whole packet is
        % precoded in nist.edmgData
        EDMG_STF = STFSeq;
    end
        EDMG_STF = EDMG_STF/sqrt(N_TX);

elseif strcmp(phyType(cfgEDMG),'OFDM')
    
    QMat = permute(getPreambleSpatialMap(cfgEDMG), [1 3 2]);
    [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
    FFTLen = ofdmInfo.NFFT;
    STFSeq = zeros(ofdmInfo.NTONES, N_STS);
    EDMG_STF_FD = zeros(size(STFSeq, 1), N_TX);
    EDMG_STF_GRID = zeros(FFTLen,1,N_TX);
    STF_grid_idx = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    
    % Get sequence
    for j = 1:N_STS
        STFSeq(:,j) = edmgSTFSeq(j);
    end
    
    % Precode sequence
    for s = 1:ofdmInfo.NTONES
        for i = 1:N_STS
            for j = 1:N_TX
                EDMG_STF_FD(s, i) = EDMG_STF_FD(s, i) + QMat(s, i,j) * STFSeq(s,j);
            end
        end
    end
    
    EDMG_STF_GRID(STF_grid_idx,1,1:N_TX) = EDMG_STF_FD;
    modOut = wlan.internal.wlanOFDMModulate(EDMG_STF_GRID,ofdmInfo.NFFT/4);
    EDMG_STF = repmat(modOut *ofdmInfo.NFFT/(sqrt(ofdmInfo.NTONES_EDMG_STF*N_STS)), [6 1] );
elseif strcmp(phyType(cfgEDMG),'Control')
    assert(false, 'Wrong PHY type')
    % DMG Control PHY: IEEE Std 802.11ad 2012, Section 21.4.3.1.2
    %    y = rotate([repmat(Gb,48,1); -Gb; -Ga]);
    % else
    %    % DMG SC and OFDM PHY: IEEE Std 802.11ad 2012, Section 21.3.6.2
    %    y = rotate([repmat(Ga,16,1); -Ga]);
    
else
    assert(false, 'Wrong PHY type')
end
end