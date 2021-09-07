function [simulation, phy, channel, nistChanData] =  configScenario(scenarioPath,metricStr)
%CONFIGSCENARIO initial 11ay structs configuration
%
%   [SIM, PHY, CHAN] = CONFIGSCENARIO(FOLDERNAME) returns the structs used
%   in the NIST 802.11ay PHY given the configuration folder FOLDERNAME.
%
%   2020-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

%% Config
% Simulation
simulation = configSimulation(scenarioPath);
simulation.wsNameStr = pwd;
simulation.metricStr = metricStr;

% PHY
phy = configPhy(scenarioPath);

% Channel
channel = configChannel(scenarioPath,simulation.chanModel);

% Node: for future use QD
nodeParams = configNodes(scenarioPath);

% Complete config with dependent parameters
[simulation, phy, channel] = setDependencies(simulation, phy, channel);

% Set Parameter Constraint
[simulation, phy, channel, nodeParams] = setParameterConstraint(simulation,phy,channel,nodeParams);

% Set Channel Model 
[channel,numRunRealizationSets,nistChanData] = setChannelModelParams(channel,phy,simulation,nodeParams);
simulation.numRunRealizationSets = numRunRealizationSets;

% Set System Object Initialization
phy = setPhySystemInit(phy);

% Set Simulation labels
simulation = setSimulationLabels(simulation, phy,channel);

end