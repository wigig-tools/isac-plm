% EDMG-PHY-MODEL Link-Level Simulator and passive sensing
%
%   2019~2022 NIST/CTL Steve Blandino, Neeraj Varshney, Jian Wang

%   This file is available under the terms of the NIST License.

%% 
clear
close all
clc

%% Input
scenarioNameStr = 'singleHumanTarget';

%% Set path
rootFolderPath = pwd;
fprintf('-------- NIST/CTL 802.11ay PHY --------\n');
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
runIsac(scenarioNameStr);

% End main file