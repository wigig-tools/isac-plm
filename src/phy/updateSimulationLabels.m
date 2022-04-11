function simuParams = updateSimulationLabels(simuParams,phyParams,chanCfg)
%%UPDATESIMULATIONLABELS Simulation labels
%   
%   S = UPDATESIMULATIONLABELS(SIM,PHY,CH) update the simulation struct SIM 
%   with labels in string type variables, describing params in SIM, in PHY 
%   the PHY config struct and in CH the channel config struct
% 
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

simuParams.realizationSetCfgStr = '';

if simuParams.chanFlag == 3
        simuParams.realizationSetCfgStr = strcat('Set',num2str(chanCfg.realizationSetIndicator));
end

simuParams.stsCfgStr = vec2str(phyParams.numSTSVec);
if numel(phyParams.numSTSVec) == 1
    simuParams.stsCfgStr = strcat('[',simuParams.stsCfgStr,']');
end
simuParams.dbfCfgStr = sprintf('P%dV%dA%dQ%dE%dW%d', ...
    phyParams.processFlag, phyParams.svdFlag, phyParams.powAlloFlag, phyParams.precAlgoFlag, phyParams.equiChFlag,phyParams.equaAlgoFlag);

simuParams.phyCfgStr = [simuParams.snrMode,'_',simuParams.stsCfgStr,'_',simuParams.dbfCfgStr,'_',simuParams.mcsCfgStr];

% Config Result File and Folders
if simuParams.chanFlag == 3
    simuParams.pmNameStr = [simuParams.phyCfgStr,'_',simuParams.realizationSetCfgStr];
else
    simuParams.pmNameStr = simuParams.phyCfgStr;
end

% Set simulation print information
simuParams = setSimulationPrintInfo(simuParams,phyParams,chanCfg);

  
end
% End of file

