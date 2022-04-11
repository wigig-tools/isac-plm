function runPHYErrorRateDataRate(scenario, varargin)
%%RUNPHYERRORRATEDATARATE evaluates the bit and packet error rates 
% (BER/PER) performances of the IEEE(R) 802.11ay(TM)
%
% RUNPHYERRORRATEDATARATE(scenario) executes the configuration stored in 
% the folder ./example/scenario

%% IEEE 802.11ay MIMO Error Rate Simulation for OFDM and SC PHY
% This program evaluates the bit and packet error rates (BER/PER) performances of the IEEE(R) 802.11ay(TM) EDMG
% OFDM OFDM and SC PHY links with aid of single-input single-output (SISO), single-user (SU) and multi-user (MU) 
% multiple-input multiple-output (MIMOs) using an end-to-end Monte-Carlo simulation when communicating over diverse 
% multi-path fading channel models in 60 GHz milimeter wave band. This program supports both the EDMG PHY protocol 
% data unit (PPDU) format transmission and the EDMG PHY service data unit (PSDU) format only transmission. The 
% synchronization and channel estimation are supported for both the OFDM and SC modes in the presence of imperfect 
% channel state information. 

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%% Introduction
% In this program an end-to-end simulation is used to determine the bit and packet error rates (BER, PER) for the 
% 802.11ay EDMG OFDM and SC based single-user (SU) or multi-user (MU) multiple-input multiple-output (MIMO)-aided 
% spatial streams over diverse of multipath fading channels at 60 GHz millimeter wave (mmWave) band, respectively,
% at a selection of SNR points for a defined modulation and coding scheme (MCS). For each SNR point, multiple packets 
% are transmitted through a channel, detected/equalized and demodulated, so that the PSDUs are recovered. 
% The PSDUs are compared to those transmitted to determine the number of bit/packet errors and hence the bit/packet 
% error rate (BER/PER). 
%
% This program also demonstrates how a parfor loop can be used instead of the for loop when simulating each SNR point 
% to speed up a simulation. parfor as part of the Parallel Computing Toolbox(TM), executes processing for each SNR in 
% parallel to reduce the total simulation time.

%% Waveform Configuration
% An 802.11ay EDMG OFDM or SC transmission is simulated in this program. The EDMG format configuration object contains 
% the format specific configuration of the transmission. The object is created using the nist.edmgConfig function. 
% The properties of the object contain the configuration. This object can be configured for an OFDM or SC
% transmission with the given MCS and an PSDU value in Byte. 
% In this program, both the EDMG PHY protocol data unit (PPDU) format and the EDMG PHY service data unit (PSDU)
% format, i.e. PPDU data-field only format transmissions are supported. Specifically, the EDMG PPDU format can be
% formed as either the non-data packet (NDP) or the data packet (DP). 

%% Varargin processing
[isTest,scenarioPath, outputPath] = varArgInitProcess(scenario, inputParser, varargin);

%% Config
[simuParams, phyParams,channelParams, chanData] = configScenario(scenarioPath, 'isTest', isTest);

%% Location loop
% Used with NIST-Q-D Channel Model
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
        fprintf('MCS\tSNR\tEVM\tBER\tPER\tGbitRateAve\tGbitRateSum\tnumComPkt\tnumPkt\trunTimePerPkt\trunTimeTotPkt\n');
        fprintf(simuParams.fileID,'## MCS\tSNR\tEVM\tBER\tPER\tGbitRateAve\tGbitRateSum\tnumComPkt\tnumPkt\trunTimePerPkt\trunTimeTotPkt\r\n');
    end
    %% Processing SNR Points
    % For each SNR point a number of packets are tested and the bit and packet error rate calculated.
    
    numUsers = phyParams.numUsers;
    
    results.berIndiUser = cell(phyParams.numMCS,1);
    results.perIndiUser = cell(phyParams.numMCS,1);
    results.evmIndiUser = cell(phyParams.numMCS,1);
    results.berAvgUser = cell(phyParams.numMCS,1);
    results.perAvgUser = cell(phyParams.numMCS,1);
    results.evmAvgUser = cell(phyParams.numMCS,1);
    results.gbitRateIndiUser = cell(phyParams.numMCS,1);
    results.gbitRateAvgUser = cell(phyParams.numMCS,1);
    results.gbitRateSumUser = cell(phyParams.numMCS,1);
    
    %% Loop for MCS
    for iMCS = 1:phyParams.numMCS
        phyParams.cfgEDMG.MCS = phyParams.mcsMU(iMCS,:);        
        [refConstellation,EVM] = edmgReferenceConstellation(phyParams.cfgEDMG);        
        snrdb = simuParams.snrRanges{iMCS};
        numSNR = numel(snrdb); % Number of SNR points
        
        berEachUser = inf(numSNR,numUsers);
        perEachUser = inf(numSNR,numUsers);
        evmEachUser = inf(numSNR,numUsers);
        berPerUser = inf(numSNR,1);
        perPerUser = inf(numSNR,1);
        evmPerUser = inf(numSNR,1);
        gbitRateIndiUser = zeros(numSNR,numUsers);
        gbitRateAvgUser = zeros(numSNR,1);
        gbitRateSumUser = zeros(numSNR,1);
        
        numPkt = ones(1,numSNR); % Index of packets transmitted (including dropped packets)
        numComPkt = ones(1,numSNR); % Index of packets transmitted completely
        runTimePerPkt = cell(numSNR,1);
        runTimeTotPkt = cell(numSNR,1);

        %% Loop for SNR
% *************************** Switch Serial or Parallel Computing ***************************
%         parfor (iSNR = 1:numSNR,simuParams.numMaxParWorks) % Use 'parfor' to speed up the simulation
        for iSNR = 1:numSNR % Use 'for' to debug the simulation
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
            
            % Create an instance of the AWGN channel per SNR point simulated
            % Account for noise energy in nulls so the SNR is defined per
            % active subcarrier
            noiseVarLin = getAWGNVariance(snrdb(iSNR),paraSimu.snrMode,paraSimu.snrAntNormFactor,paraPhy.cfgEDMG);
            paraSimu.noiseVarLin.ActSubc = noiseVarLin.ActSubc;
            paraSimu.noiseVarLin.TotSubc = noiseVarLin.TotSubc;
            
            % Loop to simulate multiple packets
            numBitErrors = zeros(1,numUsers); 
            numPacketErrors = zeros(1,numUsers);
            packetLoopTimeStart = tic;
			evmSumSTS = zeros(1,numUsers);
			
            if paraSimu.debugFlag
				figConstell = figure;
			end
            
            % Set Random Seeds - Same random per SNR loop.
            rng(paraSimu.snrSeed);  
            
            while mean(numPacketErrors)<=paraSimu.maxNumErrors && numPkt(iSNR)<=paraSimu.maxNumPackets

                %% Generate SU/MU-MIMO TDL Channel
                if paraSimu.chanFlag > 0 && paraSimu.chanFlag <= 4
                    % Get channel doppler samples
                    numSamp = getChannelDopplerSamples(fieldIndices, paraSimu.dopplerFlag, paraSimu.zeroPadding, paraSimu.delay);
                    
                    % Get NIST QD TGay TDL channel model
                    if paraSimu.chanFlag == 3
                        % Get indices of location and realization from NIST Q-D channel realizations
                        [iSet,iPacket] = getQDTDLChannelRealizationIndex(paraChan,numPkt(iSNR),paraSimu.maxNumPackets);
                        instChanData = struct;
                        instChanData.channelGain = chanData.channelGain{iSet,iPacket};
                        instChanData.delay = chanData.delay{iSet,iPacket};
                        instChanData.dopplerFactor = chanData.dopplerFactor{iSet,iPacket};
                        instChanData.TxComb = chanData.TxComb{iSet,1};
                        instChanData.RxComb = chanData.RxComb{iSet,1};
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
                                numPacketErrors = numPacketErrors+1;
                                numPkt(iSNR) = numPkt(iSNR)+1;
                                continue; % Go to next loop iteration
                            end
                            
                            % Get Precoding Matrix
                            [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder( ...
                                estCIRNdp,estCFRNdp,estNoiseVarNdp,paraPhy.cfgEDMG,cfgSim);
                        end
                           
                        % Update Spatial matrix
                        paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                        
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
                        [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder( ...
                            tdMimoChan,fdMimoChan,estNoiseVarNdp,paraPhy.cfgEDMG,cfgSim);
                        
                        % Update Spatial matrix
                        paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                        
                    otherwise
                        % Reset Precoding Matrix
                        spatialMapMat = eye(paraPhy.numSTSTot,paraPhy.numTxAnt);
                        svdChan = [];
                        powAlloMat = [];
                        precScaleFactor = 1;
                        paraPhy = updateSpatialMatrix(paraPhy,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
                end
                
                %% MIMO Waveform
                [txDpSigSeq,txDpPsdu] = edmgTx(paraPhy.cfgEDMG,cfgSim);

                %% Pass multi-path fading channel
                if paraSimu.chanFlag == 0
                    fadeDpSigSeq{1}  = txDpSigSeq;
                else
                    if paraSimu.dopplerFlag == 1
                        fadeDpSigSeq = dopplerConv(tdMimoChan,txDpSigSeq);
                    else
                        fadeDpSigSeq = passBlockFadingChannel(txDpSigSeq,tdMimoChan);
                    end
                end
                rxDpSigSeq = addNoise(fadeDpSigSeq,noiseVarLin.ActSubc);
                
                %% Receiver processing
                if paraSimu.pktFormatFlag == 0
                    %Full receiver
                    [syncError, rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks] = ...
                        edmgRxFull(rxDpSigSeq, paraPhy, cfgSim);
                    
                    if syncError                        
                        numPacketErrors = numPacketErrors+1;
                        numPkt(iSNR) = numPkt(iSNR)+1;                        
                        continue; % Go to next loop iteration
                    end
                    
                else
                    %Ideal receiver
                    [rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks] = ...
                        edmgRxIdeal(rxDpSigSeq, paraSimu, paraPhy, cfgSim, ...
                        tdMimoChan, fdMimoChan);
                end
%               

                %% Calculate EVM on received symbols
                evmIndiSTS = cell(numUsers,1);
                for iUser = 1:numUsers
                    for iSTS = 1:paraPhy.numSTSVec(iUser)
                        evmIndiSTS{iUser}(iSTS)= 20*log10(mean(step(EVM{iUser}, detSymbBlks{iUser}(:,:,iSTS))/100));
                    end
                end
                
                %% Plot Symbol Constellation
                if paraSimu.debugFlag == 1
                    if strcmpi(paraPhy.phyMode,'OFDM')
                        plotComparisonConstellation(refConstellation, evmIndiSTS, rxDataGrid, detSymbBlks, ...
                            numUsers, paraPhy.numSTSVec, figConstell);
                    else
                        plotComparisonConstellation(refConstellation, evmIndiSTS, rxDataBlks, detSymbBlks, ...
                            numUsers, paraPhy.numSTSVec, figConstell);
                    end
                end
                
                %% Get bit and packet errors per packet per user
                for iUser = 1:numUsers
                    % Bit error rate
                    bitError = biterr(txDpPsdu{iUser},rxDpPsdu{iUser});
                    numBitErrors(iUser) = numBitErrors(iUser) + bitError;
                    
                    % Determine if any bits are in error, i.e. a packet error
                    pktErrDp = any(bitError);
                    numPacketErrors(iUser) = numPacketErrors(iUser) + pktErrDp;
                    % Get EVM
                    evmSumSTS(iUser) = evmSumSTS(iUser)+mean(10.^(evmIndiSTS{iUser}/20));
                end
                
                % Next packet for total transmission
                numPkt(iSNR) = numPkt(iSNR)+1;
                % Next packet for completed transmission
                numComPkt(iSNR) = numComPkt(iSNR)+1;
            end            % End of packet while loop
            % Loop processing time cost
            packetLoopTimeEnd = toc(packetLoopTimeStart);
            packetLoopTimeAve = packetLoopTimeEnd/(numPkt(iSNR)-1);
            runTimeTotPkt{iSNR} = duration(seconds(packetLoopTimeEnd),'Format','hh:mm:ss.SS');
            runTimePerPkt{iSNR} = duration(seconds(packetLoopTimeAve),'Format','hh:mm:ss.SS');

            %% Calculate average BER and PER
            % Calculate bit error rate (BER)
            numBits = (numComPkt(iSNR)-1)*paraPhy.numDataBitsPerPkt; % PSDULength in bytes
            berUsers = numBitErrors./numBits;
            berEachUser(iSNR,:) = berUsers;            
            berPerUser(iSNR,1) = sum(numBitErrors)/(sum(numBits));

            % Calculate packet error rate (PER) at SNR point
            perUsers = numPacketErrors/(numPkt(iSNR)-1);
            perEachUser(iSNR,:) = perUsers;
            perPerUser(iSNR,1) = sum(numPacketErrors)/(numUsers*(numPkt(iSNR)-1));
            
            % Calculate EVM at SNR point
            evmUsers = 20*log10(evmSumSTS/(numPkt(iSNR)-1));
            evmEachUser(iSNR,:) = evmUsers;
            evmPerUser(iSNR,1) = 20*log10(sum(evmSumSTS)/(numUsers*(numPkt(iSNR)-1)));
            
            % Calculate data rate of individual users
            gbitRateUsers = getActualGigabitDataRate(perUsers,paraPhy.cfgEDMG);
            gbitRateIndiUser(iSNR,:) = gbitRateUsers;
            gbitRateAvgUser(iSNR,1) = mean(gbitRateUsers,2);
            gbitRateSumUser(iSNR,1) = sum(gbitRateUsers,2);
            
            %% Print results in commmand line
            % Print average user error rate
            if ~paraSimu.isTest
                fprintf('%s\t%.2f\t%.2f\t%f\t%f\t%f\t%f\t%d\t%d\t%s\t%s\n',vec2str(paraPhy.cfgEDMG.MCS),snrdb(iSNR), ...
                    evmPerUser(iSNR,1), berPerUser(iSNR,1), perPerUser(iSNR,1), ...
                    gbitRateAvgUser(iSNR,1), gbitRateSumUser(iSNR,1), ...
                    numComPkt(iSNR)-1, numPkt(iSNR)-1, runTimePerPkt{iSNR}, runTimeTotPkt{iSNR});
                % Print individual users error rates
                for iUser = 1:numUsers
                    fprintf('\t\tUser#%d:\t%.2f\t%f\t%f\t%f\n',iUser, evmUsers(iUser), ...
                        berUsers(iUser), perUsers(iUser), gbitRateUsers(iUser));
                end
            end
            
        end     % End for SNR loop
        
        % Save performance of individual users
        results.berIndiUser{iMCS,1} = berEachUser;
        results.perIndiUser{iMCS,1} = perEachUser;
        results.evmIndiUser{iMCS,1} = evmEachUser;
        
        % Save average performance of all users
        results.berAvgUser{iMCS,1} = berPerUser;
        results.perAvgUser{iMCS,1} = perPerUser;
        results.evmAvgUser{iMCS,1} = evmPerUser;
        
        % Save data rate of individual users
        results.gbitRateIndiUser{iMCS,1} = gbitRateIndiUser;
        results.gbitRateAvgUser{iMCS,1} = gbitRateAvgUser;
        results.gbitRateSumUser{iMCS,1} = gbitRateSumUser;
        
        %% Print results to file
        if ~simuParams.isTest
            for iSNR = 1:numSNR
                % Print average user error rate
                fprintf(simuParams.fileID,'%s\t%.2f\t%.2f\t%f\t%f\t%f\t%f\t%d\t%d\t%s\t%s\r\n', ...
                    vec2str(phyParams.cfgEDMG.MCS), snrdb(iSNR), ...
                    results.evmAvgUser{iMCS}(iSNR), results.berAvgUser{iMCS}(iSNR), results.perAvgUser{iMCS}(iSNR), ...
                    results.gbitRateAvgUser{iMCS}(iSNR), results.gbitRateSumUser{iMCS}(iSNR), ...
                    numComPkt(iSNR)-1, numPkt(iSNR)-1,runTimePerPkt{iSNR},runTimeTotPkt{iSNR});
                % Print individual users error rates
                for iUser = 1:numUsers
                    fprintf(simuParams.fileID,'\t\tUser#%d:\t%.2f\t%f\t%f\t%f\r\n', ...
                        iUser, results.evmIndiUser{iMCS}(iSNR,iUser), ...
                        results.berIndiUser{iMCS}(iSNR,iUser), results.perIndiUser{iMCS}(iSNR,iUser), ...
                        results.gbitRateIndiUser{iMCS}(iSNR,iUser));
                end
            end
        end
        writematrix(results.evmAvgUser{1}, fullfile(outputPath, 'testResult.txt'));
    end     % End of MCS loop
    
    %% Plot Bit Error Rate vs SNR Results
    %     scriptPlotSaveErrorRateResults
    if ~simuParams.isTest
        saveResults(simuParams, phyParams, channelParams, cfgSim, results);
    else
        close all
    end
    
end % End of idxLocation

if ~simuParams.isTest
    outputFiles =dir(simuParams.resultPathStr);
    outputFiles(1:2) = [];
    for of = 1:length(outputFiles)
        copyfile(fullfile(outputFiles(of).folder,outputFiles(of).name), ...
            fullfile(outputPath, outputFiles(of).name))
    end
end
end

function [isTest,scenarioPath,scenarioPathOutput]= varArgInitProcess(example, p, vin)
addParameter(p,'testOutput', []);
parse(p, vin{:});
testOutput  = p.Results.testOutput;
isTest = ~isempty(testOutput);

scenarioPath  = fullfile('examples', example);
if ~isfolder(scenarioPath)
    error('Scenario not defined')
end
if isTest
    scenarioPathOutput = fullfile(testOutput, 'Output');
else
    scenarioPathOutput = fullfile(scenarioPath, 'Output');
end

if ~isfolder(scenarioPathOutput)
    mkdir(scenarioPathOutput);
end
end
% End of file
