function runPHYSpectralEfficiency(example, varargin)
%% IEEE 802.11ay MIMO Spectral Efficiency Analysis for OFDM and SC PHY
%
% This program evaluates the link-level spectral efficiency performances of the IEEE(R) 802.11ay(TM) EDMG OFDM OFDM 
% and SC PHY with aid of single-input single-output (SISO), single-user (SU) and multi-user (MU) multiple-input multiple
% -output (MIMOs) using an end-to-end Monte-Carlo simulation when communicating over diverse multi-path fading 
% channel models in 60 GHz milimeter wave band. This program only supports the EDMG PHY service data unit (PSDU) 
% format transmission only. The synchronization and channel estimation are igonred for both the OFDM and SC modes
% in the persence of perfect channel state information (CSI).
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%% Introduction
% This program analyzes the link-level ergodic spectral efficiency (SE) performances for the IEEE 802.11ay EDMG PHY 
% with OFDM or the SC modes over diverse of multipath fading channels at 60 GHz millimeter wave (mmWave) band,
% respectively, at a selection of SNR points independent to modulation and coding scheme (MCS). 
% Both the single-user (SU) or multi-user (MU) multiple-input multiple-output (MIMO) are supported based on spatial
% multiplexing up to totoal eight spatial streams.
% For each SNR point, three type of ergodic SEs, including the individual user SE, average user SE and sum user SE
% of the link are calculated, respectively, in terms of capacity upon varying the realizations of channel state 
% information during the ergodic process.
%
% This program also demonstrates how a parfor loop can be used instead of the for loop when simulating each SNR point 
% to speed up a simulation. parfor as part of the Parallel Computing Toolbox(TM), executes processing for each SNR in 
% parallel to reduce the total simulation time.

% This program supports the EDMG PHY service data unit (PSDU) format, i.e. PPDU data-field only format with the 
% perfect channel estimation and synchronization for transmission. The support of PHY protocol data unit (PPDU) 
% format with impefect channel estimation and synchronization is to be validated.

%% Varargin processing
p = inputParser;
addParameter(p,'testOutput', []);
parse(p, varargin{:});
testOutput  = p.Results.testOutput;
isTest = ~isempty(testOutput);

scenarioPath  = fullfile('examples', example);
if isTest
    scenarioPathOutput = fullfile(testOutput, 'Output');
else
    scenarioPathOutput = fullfile(scenarioPath, 'Output');
end

if ~isfolder(scenarioPathOutput)
    mkdir(scenarioPathOutput);
end

%% Config
metricStr = 'SE';

[simuParams, phyParams,channelParams, chanData] = configScenario(scenarioPath,'metricStr', metricStr);
simuParams.isTest = isTest;

%% Configure PHY Parameters
numRlzn = 100;  % Number of realizations
snrRanges = simuParams.snrRanges;
simuParams.maxNumErrors = 0;
simuParams.maxNumPackets = 0;
    
%% Location loop
for setIdx = 1:channelParams.numRunRealizationSets
    
    % Update MIMO Config with Beam Reduction for NIST-Q-D Channel Model
    if strcmp(channelParams.chanModel,'NIST')
        simuParams.setIdx = setIdx;
        [phyParams,channelParams] = updateMIMOConfigAfterBeamReduct(phyParams,channelParams,setIdx);
    end
    
    % Update Simulation Labels
    simuParams = updateSimulationLabels(simuParams,phyParams,channelParams);
    
    % Set simulation print information
    simuParams = setSimulationPrintInfo(simuParams,phyParams,channelParams);
    
    % Set and Update cfgSim cfgNDP and cfgEDMG
    cfgSim = setPhySystemConfig(simuParams,phyParams,channelParams);
    
    if ~simuParams.isTest
        fprintf('SNRdB\tergoSEAvgUser\tergoSESumUser\tnumRlzn\trunTimePerPkt\trunTimeTotPkt\n');
        fprintf(simuParams.fileID,'## SNRdB\tergoSEAvgUser\tergoSESumUser\tnumRlzn\trunTimePerPkt\trunTimeTotPkt\r\n');
    end
    numTxAnt = phyParams.numTxAnt;
    numSTSVec = phyParams.numSTSVec;
    numSTSTot = phyParams.numSTSTot;
    numUsers = phyParams.numUsers;
    
    %% Processing SNR Points
    phyParams.cfgEDMG.MCS = phyParams.mcsMU(1,:);
    numSNR = numel(snrRanges{1}); % Number of SNR points
    snrdb = snrRanges{1};
    
    postEqualizeSinr = cell(numSNR,numRlzn);
    ergoSEIndiUser = zeros(numSNR,numUsers);
    ergoSESumUser = zeros(numSNR,1);
    ergoSEAvgUser = zeros(numSNR,1);
    
    %% Loop for SNR
% *************************** Switch Serial or Parallel Computing ***************************
    for iSNR = 1:numSNR % Use 'for' to debug the simulation
%     parfor (iSNR = 1:numSNR,simuParams.numMaxParWorks) % Use 'parfor' to speed up the simulation
% *******************************************************************************************
        
        %% Initilization per SNR Loop
        % Set random substream index per iteration to ensure that each
        % iteration uses a repeatable set of random numbers
        stream = RandStream('combRecursive','Seed',0);
        stream.Substream = iSNR;
        RandStream.setGlobalStream(stream);

        % Use local struct per SNR point
        paraSimu = simuParams;
        paraPhy = phyParams;
        paraChan = channelParams;
        ayChan = paraChan.tgayChannel;
        fieldIndices = nist.edmgFieldIndices(paraPhy.cfgEDMG);
        paraPhy.cfgEDMG = phyParams.cfgEDMG;
        
        % Create an instance of the AWGN channel per SNR point simulated
        % Account for noise energy in nulls so the SNR is defined per active subcarrier
        noiseVarLin = getAWGNVariance(snrdb(iSNR),paraSimu.snrMode,paraSimu.snrAntNormFactor,paraPhy.cfgEDMG);
        paraSimu.noiseVarLin.ActSubc = noiseVarLin.ActSubc;
        paraSimu.noiseVarLin.TotSubc = noiseVarLin.TotSubc;
        
        % Set Random Seeds - Same random per SNR loop.
        rng(100);
        tempSEIndiUser = zeros(numUsers,1);
        tempSESumUser = zeros(1,1);
        
        for iRlzn = 1:numRlzn

            %% Multi-User CSI Initilization
            if paraSimu.chanFlag > 0
                % Get channel doppler samples
                numSamp = getChannelDopplerSamples(fieldIndices, paraSimu.dopplerFlag, paraSimu.zeroPadding, paraSimu.delay);
                % Get NIST QD TGay TDL channel model
                if paraSimu.chanFlag == 3
                    % Get indices of location and realization from NIST Q-D channel realizations
                    [iLoc,iPacket] = getQDTDLChannelRealizationIndex(paraChan,iRlzn,numRlzn);
                    instChanData = struct;
                    instChanData.channelGain = chanData.channelGain{iLoc,iPacket};
                    instChanData.delay = chanData.delay{iLoc,iPacket};
                    instChanData.dopplerFactor = chanData.dopplerFactor{iLoc,iPacket};
                    instChanData.TxComb = chanData.TxComb{iLoc,1};
                    instChanData.RxComb = chanData.RxComb{iLoc,1};
                    % Generate channel impluse response (CIR) packet by packet
                    ayChan = getQDTDLChannel(paraPhy.cfgEDMG,paraChan,instChanData,numSamp,snrdb(iSNR));
                end
                % Get CIR and CFR from various channel model
                [tdMimoChan,fdMimoChan] = getMUMIMOChannelResponse(paraChan.chanModel,numSamp,paraPhy.fftLength,paraPhy.cfgEDMG,paraChan,ayChan);
            elseif paraSimu.chanFlag == 0
                tdMimoChan = [];
                fdMimoChan = [];
            else
                error('Wrong channel')
            end     
            
            %% Acquire CSIT
            switch paraSimu.csit
                case 'estimated'                   
                    % Sounding at Transmitter
                    [txNdpSigSeq,~] = edmgTx(paraPhy.cfgNDP,cfgSim);

                    % Sounding over multi-path fading channel
                    rxNdpSigSeq = getReceivedPilots(txNdpSigSeq,tdMimoChan,paraPhy,paraSimu, paraChan,noiseVarLin.ActSubc);

                    % Estimate CSIT
                    spatialMapMat = [];
                    svdChan = [];

                    if paraSimu.chanFlag > 0
                        [pktErrNdp,  estCIRNdp, estCFRNdp, estNoiseVarNdp] = getEstimatedCSIT(rxNdpSigSeq, paraPhy, cfgSim);

                        if any(cell2mat(pktErrNdp))
                            continue; % Go to next loop iteration
                        end

                        % Get Precoding Matrix
                        [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder(estCIRNdp,estCFRNdp,estNoiseVarNdp,paraPhy.cfgEDMG,cfgSim);
                    end
                    
                    % Update Spatial matrix
                    paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                    
                    % Get Equalizer Weight Matrix
                    [mimoEquaWeight,~] = getMIMOEqualizer(paraPhy,paraSimu,estCIRNdp,estCFRNdp,estNoiseVarNdp);
                    
                    if strcmp(paraPhy.phyMode,'OFDM')
                        noiseVarEst = mean(cell2mat(estNoiseVarNdp),'all'); 
                        noiseVarEst = noiseVarEst / (paraPhy.fftLength/paraPhy.ofdmInfo.NTONES);
                        fdMimoChanEst = cell(numUsers,1);
                        for iUser = 1:numUsers
                            fdMimoChanTemp = permute(estCFRNdp{iUser},[1,4,2,3]);
                            fdMimoChanEst{iUser} = zeros(paraPhy.fftLength,1,numTxAnt,numSTSVec(iUser));
                            fdMimoChanEst{iUser}(paraPhy.activeSubcIdx,:,:,:) = fdMimoChanTemp;
                        end
                    else
                        % SC
                        noiseVarEst = mean(cell2mat(estNoiseVarNdp),'all');
                        fdMimoChanEst = getMIMOChannelFrequencyResponse(estCIRNdp,paraPhy.fftLength);
                    end
                    
                case 'ideal'
                    % Perfect noise estimation
                    estNoiseVarNdp = cell(numUsers,1);
                    for iUser = 1:numUsers
                        if isscalar(noiseVarLin.TotSubc)
                            estNoiseVarNdp{iUser} = noiseVarLin.TotSubc * ones(1,paraPhy.numSTSVec(iUser));
                        elseif isvector(noiseVarLin.TotSubc) && length(noiseVarLin.TotSubc)==numUsers
                            estNoiseVarNdp{iUser} = noiseVarLin.TotSubc(iUser) * ones(1,paraPhy.numSTSVec(iUser));
                        else
                            error('The format of noiseVarLin.TotSubc is incorrect.');
                        end
                    end
                    
                    % Get Precoding Matrix
                    [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder(tdMimoChan,fdMimoChan,estNoiseVarNdp,paraPhy.cfgEDMG,cfgSim);
                    
                    % Update Spatial matrix
                    paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                    
                    % Get Equalizer Weight Matrix
                    [mimoEquaWeight,~] = getMIMOEqualizer(paraPhy,paraSimu,tdMimoChan,fdMimoChan,estNoiseVarNdp);
                    
                    noiseVarEst = noiseVarLin.ActSubc;
                    fdMimoChanEst = fdMimoChan;

                otherwise
                    % Perfect noise estimation
                    estNoiseVarNdp = cell(numUsers,1);
                    for iUser = 1:numUsers
                        if isscalar(noiseVarLin.TotSubc)
                            estNoiseVarNdp{iUser} = noiseVarLin.TotSubc * ones(1,paraPhy.numSTSVec(iUser));
                        elseif isvector(noiseVarLin.TotSubc) && length(noiseVarLin.TotSubc)==numUsers
                            estNoiseVarNdp{iUser} = noiseVarLin.TotSubc(iUser) * ones(1,paraPhy.numSTSVec(iUser));
                        else
                            error('The format of noiseVarLin.TotSubc is incorrect.');
                        end
                    end
                    
                    % Reset Precoding Matrix
                    spatialMapMat = eye(numSTSTot,numTxAnt);
                    svdChan = [];
                    powAlloMat = [];
                    precScaleFactor = 1;
                    paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                    
                    % Get Equalizer Weight Matrix
                    [mimoEquaWeight,~] = getMIMOEqualizer(paraPhy,paraSimu,tdMimoChan,fdMimoChan,estNoiseVarNdp);
                    
                    noiseVarEst = noiseVarLin.ActSubc;
                    fdMimoChanEst = fdMimoChan;
            end
            
            %% Calculate Inst. Spectral Efficiency 
            % SINR Calculation
            Es = 1/numTxAnt;
            if strcmp(paraPhy.phyMode,'OFDM')
                [instSESumUser,instSEIndiUser,poEqSinr] = edmgInstantSpectralEffciency(fdMimoChanEst,Es,noiseVarEst,paraPhy.cfgEDMG,spatialMapMat,mimoEquaWeight);
            else
                [instSESumUser,instSEIndiUser,poEqSinr] = edmgInstantSpectralEffciency(fdMimoChanEst,Es,noiseVarEst,paraPhy.cfgEDMG,spatialMapMat,mimoEquaWeight,precScaleFactor);
            end
            
            %% Sum SE over realizations
            tempSESumUser = tempSESumUser + instSESumUser;
            tempSEIndiUser = tempSEIndiUser + instSEIndiUser;
            
            % Save postEqualizeSINR
            postEqualizeSinr{iSNR,iRlzn} = poEqSinr;
        end     % End of realizations

        %% Calculate average BER and PER
        % Calculate Ergodic Spectral Efficiency at SNR point
        seIndiUser = tempSEIndiUser / numRlzn;
        seSumUser = tempSESumUser / numRlzn;
        seAvgUser = mean(seIndiUser);
        ergoSEIndiUser(iSNR,:) = seIndiUser;
        ergoSESumUser(iSNR,1) = seSumUser;
        ergoSEAvgUser(iSNR,1) = seAvgUser;
        
        
        %% Print results in commmand line
        % Print sum user and average user SE
        if ~paraSimu.isTest
            fprintf('%.2f\t%f\t%f\t%d\n',snrdb(iSNR), seAvgUser, seSumUser, numRlzn);
            % Print individual user SE
            for iUser = 1:numUsers
                fprintf('\tUser#%d:\t%f\n',iUser, seIndiUser(iUser));
            end
        end
        
    end     % End for SNR loop / parfor loop
    
    results.ergoSEIndiUser = ergoSEIndiUser;
    results.ergoSESumUser = ergoSESumUser;
    results.ergoSEAvgUser = ergoSEAvgUser;
    results.postEqualizeSinr = postEqualizeSinr;
    
    if ~simuParams.isTest
        %% Print results to file
        fprintf(simuParams.fileID,'SNRdB\tergoSEAvgUser\tergoSESumUser\tnumRlzn\r\n');
        for iSNR = 1:numSNR
            % Print sum user and average user SE
            fprintf(simuParams.fileID,'%.2f\t%f\t%f\t%d\r\n',snrdb(iSNR), ergoSEAvgUser(iSNR,1), ergoSESumUser(iSNR,1), numRlzn);
            % Print individual user SE
            for iUser = 1:numUsers
                fprintf(simuParams.fileID,'\tUser#%d:\t%f\r\n',iUser, ergoSEIndiUser(iSNR,iUser));
            end
        end
        %% Plot Bit Error Rate vs SNR Results
        saveResults(simuParams, phyParams, channelParams, cfgSim, results)
    end
%    writematrix(0, fullfile(scenarioPathOutput, 'results.txt'))
end % End of idxLocation

outputFiles =dir(simuParams.resultPathStr);
outputFiles(1:2) = [];
of = 2;
    copyfile(fullfile(outputFiles(of).folder,outputFiles(of).name), ...
        fullfile(scenarioPath,'Output', 'isac-plm-ws.mat'))
%% End of file
