function  [simuParams,phyParams,channelParams] = setDependencies(simuParams,phyParams,channelParams)
%scriptDependenciesFun return parameters dependent on the configuration parameters

%   2019~2021 NIST/CTL Jiayi Zhang, Steve Blandino

%   This file is available under the terms of the NIST License.


%% Configure SimulationParams Parameters

if simuParams.debugFlag == 0
    simuParams.numMaxParWorks = 20;
    simuParams.simTypeStr = 'Result';
elseif simuParams.debugFlag == 1
    simuParams.numMaxParWorks = 0; % number of maximum works for parallel pool (parfor)
    simuParams.simTypeStr = 'Debug';
else
    simuParams.numMaxParWorks = 20;
    simuParams.simTypeStr = 'Test';
end

%% Setup system model
phyParams.numUsers = length(phyParams.numSTSVec);     
simuParams.numUsers = phyParams.numUsers;

%% Setup Controllor for System, Channel

 % 0,1,2,3,4 respectevely
simuParams.chanFlag =  find(ismember({'AWGN', 'Rayleigh', 'MatlabTGay', 'Intel', 'NIST'}, simuParams.chanModel ))-1;
channelParams.chanFlag = simuParams.chanFlag;
channelParams.chanModel = simuParams.chanModel;

if phyParams.numUsers>1
    simuParams.mimoFlag = 2;           % mimo flag         =0: SISO, =1: SU-MIMO, =2: MU-MIMO
else
    if phyParams.numSTSVec ==1
        simuParams.mimoFlag = 0;
    else
        simuParams.mimoFlag = 1;
    end
end

simuParams.runFoldStr = 'edmg-phy-model';
simuParams.dataFoldStr = 'data';
simuParams.resultFoldStr = 'results';
if strcmp(simuParams.metricStr,'ER')
    simuParams.resultSubFoldStr = 'LLS_results';
elseif strcmp(simuParams.metricStr,'SE')
    simuParams.resultSubFoldStr = 'LLA_results';
else
    error('metricStr should be either ER or SE.');
end

%% Setup Tx/Rx signal processing
phyParams = setTxRxProcessParams(phyParams);

if simuParams.pktFormatFlag == 0
    phyParams.equiChFlag = 1;
end

%% Configure BER vs SNR Simulation 
% For each SNR point a number of packets are generated, passed through a
% channel and demodulated to determine the packet error rate. The SNR
% points to simulate are selected from |snrRanges| based on the MCS to
% simulate. The SNR range for each MCS is selected in order to simulate the
% transition from all packets being decoded in error to all packets being
% decoded successfully as the SNR increases.

simuParams.delay = 0; % pow2(4);   % 0; % 
simuParams.zeroPadding = pow2(8);

% MCS to test
% MCS   11ad-MCS   11ay-MCS
% BPSK 13,14        1,2,
% QPSK  15,16,17         6,7,8
% 16-QAM    18,19,20,21         11,12,13,14
% 64-QAM    22,23,24      17,18,19
% Check MCS
if strcmp(simuParams.metricStr,'SE')
    if strcmp(phyParams.phyMode,'OFDM')
        phyParams.mcs = checkInput(phyParams.mcs, 1, 'Set expected mcs value:');
    elseif strcmp(phyParams.phyMode,'SC')
        phyParams.mcs = checkInput(phyParams.mcs, 2, 'Set expected mcs value:');
    else
        error('phyMode should be either OFDM or SC.');
    end
end
if isnumeric(phyParams.mcs)
    if isvector(phyParams.mcs) && length(phyParams.mcs)~=phyParams.numUsers
        phyParams.numMCS = length(phyParams.mcs);          % Number of MCS
        phyParams.mcsMU = phyParams.mcs' .* ones(phyParams.numMCS,phyParams.numUsers); % MCS for all users    
    elseif ismatrix(phyParams.mcs) && size(phyParams.mcs,2)==phyParams.numUsers
        phyParams.numMCS = size(phyParams.mcs,1);          % Number of MCS
        phyParams.mcsMU = phyParams.mcs;
    else
        error('mcs format is incorrect.');
    end
else
    error('mcs format is incorrect.');
end
if isrow(phyParams.mcsMU)
    if simuParams.debugFlag == 0
        simuParams.snrRanges = { simuParams.snrRange(1):simuParams.snrStep:simuParams.snrRange(2) };
    else
        simuParams.snrRanges = { simuParams.snrRange };
    end
else
    error('phyParams.mcsMU should not be a row vector.');
end


%% Plot Configuration
simuParams.plotProperty.Mark = '.*osd^v><ph*osd^v><ph*osd^v><ph*osd^v><ph';
simuParams.plotProperty.Color = 'krbmcgykrbmcgykrbmcgykrbmcgykrbmcgy'; 
simuParams.plotProperty.Line = {'-'; '-'; ':'; '-.';};

% Label date info for results
simuParams.dtStr = datestr(now,30); % 'yyyymmddTHHMMSS'


%% FE Impairment
% scriptSetAnalogFE
   