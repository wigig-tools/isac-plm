function [simulation, phy, channel, sens] =  configScenario(scenarioPath, varargin)
%CONFIGSCENARIO configuration scenario 
%
%   [SIM, PHY, CHAN, SENS] = CONFIGSCENARIO(FOLDERNAME) returns the structs used
%   in the NIST 802.11ay PHY given the configuration folder FOLDERNAME.
%
%   [SIM, PHY, CHAN, SENS] = CONFIGSCENARIO(FOLDERNAME, 'metricStr', str)
%   indicates the simulation to run. 'ER' specifies error rate (default)
%   'SE' specifies spectral efficiency.
%
%   [SIM, PHY, CHAN, SENS] = CONFIGSCENARIO(FOLDERNAME, 'isTest', bool)
%   'true' indicates that the software is run as test (testing code not 
%   released). 'false' is default.

% NIST-developed software is provided by NIST as a public service. You may 
% use, copy and distribute copies of the software in any medium, provided 
% that you keep intact this entire notice. You may improve,modify and 
% create derivative works of the software or any portion of the software, 
% and you may copy and distribute such modifications or works. Modified 
% works should carry a notice stating that you changed the software and 
% should note the date and nature of any such change. Please explicitly 
% acknowledge the National Institute of Standards and Technology as the 
% source of the software. NIST-developed software is expressly provided 
% "AS IS." NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR
% ARISING BY OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED 
% WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
% NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS 
% THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, 
% OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY
% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS THEREOF,
% INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY, RELIABILITY,
% OR USEFULNESS OF THE SOFTWARE.
% 
% You are solely responsible for determining the appropriateness of using 
% and distributing the software and you assume all risks associated with 
% its use,including but not limited to the risks and costs of program 
% errors, compliance with applicable laws, damage to or loss of data, 
% programs or equipment, and the unavailability or interruption of 
% operation. This software is not intended to be used in any situation 
% where a failure could cause risk of injury or damage to property. 
% The software developed by NIST employees is not subject to copyright 
% protection within the United States.
%
% 2020-2021 NIST/CTL (steve.blandino@nist.gov)

%% Varagin 
p = inputParser;
addParameter(p,'metricStr', 'ER');
addParameter(p,'isTest', 0);
parse(p, varargin{:});


%% Config
% Sens
sens = configSens(scenarioPath);
isIsac = ~isempty(sens);

% Simulation
simulation = configSimulation(scenarioPath, 'isac', isIsac);
simulation.metricStr =  p.Results.metricStr;
simulation.isTest = p.Results.isTest;
simulation.scenarioPath =scenarioPath;

% PHY
phy = configPhy(scenarioPath, 'isac', isIsac);

% Channel
channel = configChannel(scenarioPath);

% Node: for future use QD
nodeParams = configNodes(scenarioPath);

% Complete config with dependent parameters
[simulation, phy, channel, nodeParams] = setDependencies(simulation, phy, channel, nodeParams);

% Set Channel Model 
channel = setChannelModelParams(channel,sens,phy,simulation,nodeParams);

% Set Simulation labels
simulation = setSimulationLabels(simulation, phy,channel);

% Update Simulation Labels
simulation = updateSimulationLabels(simulation,phy,channel);

end