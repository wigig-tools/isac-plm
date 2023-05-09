function [phyParams] = setPhySystemInit(phyParams)
%scriptSetPHYSystemInit Setup System Initialization
%   This file setup Initialization for the EDMG PHY system object
%   
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

% Create a format configuration object for a EDMG Not Data Packet (NDP) transmission
cfgNDP = nist.edmgConfig;
cfgNDP.PHYType = phyParams.phyMode;      % add for EDMG 11ay
cfgNDP.PSDULength = 0; % Bytes
cfgNDP.NumUsers = 1;
cfgNDP.ScramblerInitialization = randi(127,1,1);
cfgNDP.GuardIntervalType = phyParams.giType;
cfgNDP.MCS = 1;

% Create a format configuration object for a EDMG OFDM transmission
cfgEDMG = nist.edmgConfig;
cfgEDMG.PHYType = phyParams.phyMode;      % add for EDMG 11ay
cfgEDMG.GuardIntervalType = phyParams.giType;

cfgEDMG.NumUsers = phyParams.numUsers;
cfgEDMG.PSDULength = phyParams.lenPsduByt * ones(1,phyParams.numUsers);
cfgEDMG.ScramblerInitialization = randi(127,1,phyParams.numUsers);
cfgEDMG.MCS = phyParams.mcsMU(1,:);         % Force to OFDM

% TRN 
cfgEDMG.PacketType = phyParams.packetType;
if strcmp(phyParams.sensingType, 'bistatic-trn')
    cfgEDMG.UnitP = phyParams.unitP;
    cfgEDMG.UnitM = phyParams.unitM;
    cfgEDMG.UnitN = phyParams.unitN;
    cfgEDMG.SubfieldSeqLength = phyParams.subfieldSeqLength;
    cfgEDMG.TrainingLength = phyParams.trainingLength;
end

% Setup MIMO for cfgNDP and cfgEDMG
cfgNDP.NumTransmitAntennas = phyParams.numTxAnt;
cfgNDP.NumSpaceTimeStreams = phyParams.numSTSVec;
cfgNDP.PreambleSpatialMappingType = phyParams.smTypeNDP;

cfgEDMG.NumTransmitAntennas = phyParams.numTxAnt;
cfgEDMG.NumSpaceTimeStreams = phyParams.numSTSVec;
cfgEDMG.PreambleSpatialMappingType = phyParams.smTypeDP;  % 'Data';    
cfgEDMG.SpatialMappingType = phyParams.smTypeDP;
cfgEDMG.SensingType  = phyParams.sensingType;
if any(ismember(["bistatic-trn", "passive-beacon"], cfgEDMG.SensingType  ))
    phyParams.lenPsduByt = 0;
    cfgEDMG.PSDULength = cfgEDMG.PSDULength*0;
end


[phyParams.phyInfo,phyParams.phyChara] = edmgPHYInfoCharacteristics(cfgEDMG);

phyParams.numDataBitsPerPkt = cfgEDMG.PSDULength*8;

% Setup Mode Basis
% Get sampling rate and specify carrier frequency
phyParams.fs = nist.edmgSampleRate(cfgEDMG);
if strcmp(phyParams.phyMode,'OFDM')
    [phyParams.ofdmInfo,phyParams.ofdmInd,phyParams.ofdmCfg] = nist.edmgOFDMInfo(cfgEDMG);
    phyParams.fc = phyParams.ofdmInfo.CenterFreqHz;
    phyParams.fftLength = phyParams.ofdmInfo.NFFT;
    phyParams.giLength = phyParams.ofdmInfo.NGI;
    phyParams.numTones = phyParams.ofdmInfo.NTONES;
    [phyParams.activeSubcIdx, ~] = sort([phyParams.ofdmInd.DataIndices; phyParams.ofdmInd.PilotIndices]);
elseif strcmp(phyParams.phyMode,'SC')
    phyParams.scInfo = edmgSCInfo(cfgEDMG);
    phyParams.fc = phyParams.scInfo.CenterFreqHz;
    phyParams.fftLength = phyParams.scInfo.NFFT;
    phyParams.giLength = phyParams.scInfo.NGI;
    phyParams.numTones = phyParams.scInfo.NTONES;
    phyParams.activeSubcIdx = transpose(1:phyParams.fftLength);
else
    error('phyMode should be either OFDM and SC.');
end

phyParams.cfgNDP = cfgNDP;
phyParams.cfgEDMG = cfgEDMG;

end