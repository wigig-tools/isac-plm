function runIsac(scenario, varargin)
%%RUNISAC evaluates the bit and packet error rates
% (BER/PER) performances of the IEEE(R) 802.11ay(TM) and performs sensing.
%
% RUNISAC(scenario) executes the configuration stored in
% the folder ./example/scenario

%% IEEE 802.11ay MIMO Error Rate Simulation for OFDM and SC PHY
% This program evaluates the bit and packet error rates (BER/PER) performances of the IEEE(R) 802.11ay(TM) EDMG
% OFDM OFDM and SC PHY links with aid of single-input single-output (SISO), single-user (SU) and multi-user (MU)
% multiple-input multiple-output (MIMOs) using an end-to-end Monte-Carlo simulation when communicating over diverse
% multi-path fading channel models in 60 GHz milimeter wave band. This program supports both the EDMG PHY protocol
% data unit (PPDU) format transmission and the EDMG PHY service data unit (PSDU) format only transmission. The
% synchronization and channel estimation are supported for both the OFDM and SC modes in the presence of imperfect
% channel state information.

%   2019~2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Introduction
% In this program an end-to-end simulation is used to determine the bit and packet error rates (BER, PER) for the
% 802.11ay EDMG OFDM and SC based single-user (SU) or multi-user (MU) multiple-input multiple-output (MIMO)-aided
% spatial streams over diverse of multipath fading channels at 60 GHz millimeter wave (mmWave) band, respectively,
% at a selection of SNR points for a defined modulation and coding scheme (MCS). For each SNR point, multiple packets
% are transmitted through a channel, detected/equalized and demodulated, so that the PSDUs are recovered.
% The PSDUs are compared to those transmitted to determine the number of bit/packet errors and hence the bit/packet
% error rate (BER/PER).
% Moreover, using a NIST QD channel realization including targets modeling, the software execute doppler process
% returing range and velocity information of a target moving.
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
[isTest,scenarioPath] = varArgInitProcess(scenario, inputParser, varargin);

%% Config
[simParams, phyParams, channelParams, sensParams] = configScenario(scenarioPath,...
    'isTest', isTest, 'metricStr', 'ISAC');

%% Processing SNR Points
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
    snrdb = simParams.snrRanges{iMCS};
    numSNR = numel(snrdb); % Number of SNR points

    %% Loop for SNR
    % For each SNR point a number of packets are tested and the bit and packet error rate calculated
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
        isacResults(iSNR) = isac(simParams, phyParams, sensParams, channelParams, snrdb(iSNR), 'mcsIndex', iMCS);
    end     % End for SNR loop

    % Save performance of individual users
    results.berIndiUser{iMCS,1} = [isacResults.berEachUser];
    results.perIndiUser{iMCS,1} = [isacResults.perEachUser];
    results.evmIndiUser{iMCS,1} = [isacResults.evmEachUser];

    % Save average performance of all users
    results.berAvgUser{iMCS,1} = [isacResults.berPerUser];
    results.perAvgUser{iMCS,1} = [isacResults.perPerUser];
    results.evmAvgUser{iMCS,1} = [isacResults.evmPerUser];

    % Save data rate of individual users
    results.gbitRateIndiUser{iMCS,1} = [isacResults.gbitRateIndiUser];
    results.gbitRateAvgUser{iMCS,1} = [isacResults.gbitRateAvgUser];
    results.gbitRateSumUser{iMCS,1} = [isacResults.gbitRateSumUser];

    % Save sensing results
    results.sensing = [isacResults.sensRes];
    results.sensingInfo = [isacResults.sensInfo];

end     % End of MCS loop

%% Plot Bit Error Rate vs SNR Results
if ~simParams.isTest
    saveResults(simParams, phyParams, channelParams, [], results);
else
    close all
end

outputFiles =dir(simParams.resultPathStr);
outputFiles(1:2) = [];
 of = 2;
    copyfile(fullfile(outputFiles(of).folder,outputFiles(of).name), ...
        fullfile(scenarioPath,'Output', 'isac-plm-ws.mat'))


end

function [isTest,scenarioPath]= varArgInitProcess(example, p, vin)
%Configure path, check if the software is used in test mode
addParameter(p,'testOutput', []);
parse(p, vin{:});
testOutput  = p.Results.testOutput;
isTest = ~isempty(testOutput);

scenarioPath  = fullfile('examples', example);
if isTest
    scenarioPathOutput = fullfile(testOutput, 'Output');
else
    scenarioPathOutput = fullfile(scenarioPath, 'Output');
    if ~isfolder(scenarioPath)
        error('Folder %s not defined',scenarioPath)
    end
end

if ~isfolder(scenarioPathOutput)
    mkdir(scenarioPathOutput);
else
    rmdir(scenarioPathOutput, 's');
    mkdir(scenarioPathOutput);
end
end
% End of file
