% EDMG-PHY-MODEL Link-Level Simulator
%
%   2019~2021 NIST/CTL Jiayi Zhang, Steve Blandino, Jian Wang

%   This file is available under the terms of the NIST License.

clear
close all
clc

rootFolderPath = pwd;
fprintf('-------- NIST/CTL 802.11ay PHY --------\n');
fprintf('Current root folder:\n\t%s\n',rootFolderPath);
[path,folderName] = fileparts(rootFolderPath);
if strcmp(folderName, 'edmg-physical-layer-model')
    fprintf('Start to run.\n');
else
    error('The root folder should be ''edmg-physical-layer-model''');
end

addpath(genpath(fullfile(rootFolderPath,'src')));
addpath(genpath(fullfile(rootFolderPath,'data')));

scenarioNameStr = 'muMimoOfdm_data';

fprintf('Use customized scenario: %s.\n',scenarioNameStr);

% Both functions below support either with or without parfor, 
% simply use comment/uncomment the for/parfor line to activate or deactivate

% Generate BER PER and data rate
runPHYErrorRateDataRate(scenarioNameStr);

% Generate Spectral Efficiency
runPHYSpectralEfficiency(scenarioNameStr);

% End main file