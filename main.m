% Integrated Sensing and Communication - Physical Layer Model (ISAC-PLM)
%
%   2019~2022 NIST/CTL Steve Blandino, Neeraj Varshney, Jian Wang

%   This file is available under the terms of the NIST License.

%% 
clear getPrecodedRxSignal
close all
clc

%% Input
scenarioNameStr = 'examples/bistaticLivingRoomTRN-T';

%% Set path
rootFolderPath = pwd;
fprintf('--------ISAC-PLM --------\n');
fprintf('Current root folder:\n\t%s\n',rootFolderPath);
[path,folderName] = fileparts(rootFolderPath);
if strcmp(folderName, 'isac-plm')
    fprintf('Start to run.\n');
else
    error('The root folder should be ''isac-plm''');
end

addpath(genpath(fullfile(rootFolderPath,'src')));
addpath(genpath(fullfile(rootFolderPath,'data')));

fprintf('Use customized scenario: %s.\n',scenarioNameStr);

%% Run
if isfile(fullfile([scenarioNameStr, '\Input\sensConfig.txt']))
    runIsac(scenarioNameStr);
else
    % Generate BER PER and data rate
    runPHYErrorRateDataRate(scenarioNameStr);
    % Generate Spectral Efficiency
    runPHYSpectralEfficiency(scenarioNameStr);
end