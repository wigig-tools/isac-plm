function y = edmgCE(cfgEDMG)
%EDMGCE EDMG Channel Estimation Field (DMG-CE)
%
%   Y = EDMGCE(CFGDMG) generates the EDMG Channel Estimation Field (CE)
%   time-domain signal for the EDMG transmission format.
%
%   Y is the time-domain EDMG CE signal. It is a complex matrix of size
%   Ns-by-Ntx, where Ns represents the number of time-domain samples and
%   Ntx is the number of digital transmit antennas (RF chains).
%
%   cfgEDMG is the format configuration object of type nist.edmgConfig
%   specifies the parameters for the EDMG format.
%
%   2019-2021 NIST/CLT steve Blandino

%   This file is available under the terms of the NIST License.

%% Init 
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

[P, N_EDMG_CEF] = edmgCEConfig(cfgEDMG);

N_STS = sum(cfgEDMG.NumSpaceTimeStreams,2); % Total number of space-time streams
N_CB  = cfgEDMG.NumContiguousChannels;
N_TX  = cfgEDMG.NumTransmitAntennas;

%% CE Field 
if strcmp(phyType(cfgEDMG),'SC')
    %% SC 
    QMat = permute(getPreambleSpatialMap(cfgEDMG),[2 1 3]);
    % Generate Ga for Gb for different stream indicies
    Ga_Mat = cell(N_STS, 1);
    Gb_Mat = cell(N_STS, 1);
    
    Gu_Mat = cell(N_STS, 1);
    Gv_Mat = cell(N_STS, 1);
    
    CE_Subfield_Mat = cell(N_STS, N_EDMG_CEF);
    
    for j = 1:N_STS        
        % Get the corresponding Golay Sequence for stream (j).
        [Ga, Gb] = nist.edmgGolaySequence(128 * N_CB, j);
        Ga_Mat{j} = Ga;
        Gb_Mat{j} = Gb;        
        % Generate Gu and Gv matrix based on stream index.
        Gu_Mat{j,1} = [-Gb; -Ga; +Gb; -Ga];
        Gv_Mat{j,1} = [-Gb; +Ga; -Gb; -Ga];        
        % Generate CEF Subfields
        for n = 1:N_EDMG_CEF
            if n == 1
                % Subfield Idx n = 1
                CE_Subfield_Mat{j,n} = [Gu_Mat{j,1}; Gv_Mat{j,1}; -Gb];
            else
                % Subfield Idx n >= 2
                CE_Subfield_Mat{j,n} = [-Ga; Gu_Mat{j,1}; Gv_Mat{j,1}; -Gb];
            end
        end
    end
    
    if size(QMat,3) == 1
        % Generate CEF for each Transmit RF Chain.
        CEF_Mat = cell(N_TX, N_EDMG_CEF);  % CEF Field for N_RF for each CE Subfield.
        % Generate Subfield
        CEF_Size = 0;
        for n = 1:N_EDMG_CEF
            for i = 1:N_TX
                vector = zeros(numel(CE_Subfield_Mat{1,n}), 1);
                for j = 1:N_STS
                    vector = vector + QMat(i,j) * P(j,n) * CE_Subfield_Mat{j,n};
                    
                end
                CEF_Mat{i, n} = vector;
            end
            %         end
            CEF_Size = CEF_Size + numel(vector);
        end
        y = zeros(CEF_Size, N_TX);
        for i = 1:N_TX
            y(:,i) = cat(1, CEF_Mat{i,1:end});
        end
    else
        % 3D QMat is used with time domain convolution. The whole packet is
        % precoded in nist.edmgData
        CEF_Mat = cell(N_EDMG_CEF,1);  % CEF Field for N_RF for each CE Subfield.
        for n = 1:N_EDMG_CEF
            CEn = [CE_Subfield_Mat{:,n}];
            Pn  = diag(P(1:N_STS,n));
            CEF_Mat{n} = Pn*CEn.';
        end
        y = [CEF_Mat{:}].';
    end
    y = y/sqrt(N_TX);

elseif strcmp(phyType(cfgEDMG),'OFDM')
    %% OFDM 
    QMat = permute(getPreambleSpatialMap(cfgEDMG), [1 3 2]);
    [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
    EDMG_CEF_FD = zeros(ofdmInfo.NTONES,N_EDMG_CEF,N_TX);
    EDMG_CEF_GRID = zeros(ofdmInfo.NFFT,N_EDMG_CEF,N_TX);
    CEF_grid_idx = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    CEFSeq = edmgCEFSeq(1:N_STS);
    for n = 1:N_EDMG_CEF
        for s = 1:ofdmInfo.NTONES
            for i = 1:N_STS
                for j = 1:N_TX
                    EDMG_CEF_FD(s,n,i) = EDMG_CEF_FD(s, n,i) + QMat(s, i,j) * P(j,n) * CEFSeq(s,j);
                end
            end
        end
    end
    EDMG_CEF_GRID(CEF_grid_idx,:, :) = EDMG_CEF_FD;
    modOut = wlan.internal.wlanOFDMModulate(EDMG_CEF_GRID,192);
    y = modOut *ofdmInfo.NFFT/(sqrt(ofdmInfo.NTONES*N_STS));
elseif strcmp(phyType(cfgEDMG),'Control')
    %% Control 
    error('Feature not implemented')
end
end

