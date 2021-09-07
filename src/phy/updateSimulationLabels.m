function simuParams = updateSimulationLabels(simuParams,phyParams,chanCfg)
%updateSimulationLabels
%   This script file should be included in mainfile, in order to update formatted simulation labels in string type variables.
% 
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

simuParams.realizationSetCfgStr = '';

if chanCfg.chanFlag == 4
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
if chanCfg.chanFlag == 4
    simuParams.pmNameStr = [simuParams.phyCfgStr,'_',simuParams.realizationSetCfgStr];
else
    simuParams.pmNameStr = simuParams.phyCfgStr;
end

end
% End of file