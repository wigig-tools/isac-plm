function simuParams = setSimulationLabels(simuParams, phyParams,chanCfg)
%setSimulationLabels Set formatted simulation labels.
% 
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if simuParams.pktFormatFlag == 0
    simuParams.pktFormatStr = 'PPDU';
elseif simuParams.pktFormatFlag == 1
    simuParams.pktFormatStr = 'PSDU';
else
end

if simuParams.dopplerFlag == 0
   simuParams.doppFlagStr = 'TIV';   % 'DoppOff';
else
   simuParams.doppFlagStr = 'TV';   % 'DoppOn';
end

if strcmp(phyParams.giType,'Normal')
    simuParams.giTypeStr = 'NGI';
elseif strcmp(phyParams.giType,'Long')
    simuParams.giTypeStr = 'LGI';
elseif strcmp(phyParams.giType,'Short')
    simuParams.giTypeStr = 'SGI';
else
    error('giType should be Normal, Long, Short.');
end

if phyParams.equaAlgoFlag == 0
    simuParams.equaAlgoStr = 'NA';
elseif phyParams.equaAlgoFlag == 1
    simuParams.equaAlgoStr = 'ZF';
elseif phyParams.equaAlgoFlag == 2
    simuParams.equaAlgoStr = 'MMSE';
elseif phyParams.equaAlgoFlag == 3
    simuParams.equaAlgoStr = 'MF';
end

if chanCfg.chanFlag > 0
    if strcmp(chanCfg.tdlType,'Impulse')
        simuParams.tdlTypeStr = 'Impu';
    elseif strcmp(chanCfg.tdlType,'Sinc')
        simuParams.tdlTypeStr = 'Sinc';
    else
        error('tdlType should be Impulse or Sinc.');
    end
else
    simuParams.tdlTypeStr = '';
end

simuParams.tdlCfgStr = '';
simuParams.paaCfgStr = '';
simuParams.abfCfgStr = '';
if chanCfg.chanFlag == 0
    simuParams.chanCfgStr = strcat(chanCfg.MdlStr,'-',chanCfg.EnvStr,'-',simuParams.doppFlagStr);
elseif chanCfg.chanFlag == 1
    simuParams.chanCfgStr = strcat(chanCfg.MdlStr,'-',chanCfg.EnvStr,'-',simuParams.doppFlagStr);
    simuParams.tdlCfgStr = strcat(chanCfg.tdlType,'-',chanCfg.pdpMethodStr,'-D',num2str(chanCfg.maxMimoArrivalDelay),'-L',num2str(chanCfg.numTaps));
elseif chanCfg.chanFlag == 2
    simuParams.chanCfgStr = strcat(chanCfg.MdlStr,'-',chanCfg.EnvStr,'-',simuParams.doppFlagStr);
    simuParams.tdlCfgStr = chanCfg.tdlType;
elseif chanCfg.chanFlag == 3
    chanCfg.numTaps = [];
    if chanCfg.apSp == 0
        chanCfg.subScenaStr = 'STA';  % Manually modify cr_ch_cfg.m
    elseif chanCfg.apSp == 1
        chanCfg.subScenaStr = 'AP';
    end
    if chanCfg.pLos == 0
        chanCfg.pLosStr = 'NLOS';
    elseif chanCfg.pLos == 1
        chanCfg.pLosStr = 'LOS';
    end
    chanCfg.antTypeStr = strcat(num2str(chanCfg.txAntType),num2str(chanCfg.rxAntType));
    chanCfg.hpbwStr = strcat(num2str(chanCfg.txHpbw),num2str(chanCfg.rxHpbw));
    simuParams.chanCfgStr = strcat(chanCfg.MdlStr,'-',chanCfg.EnvStr,'-',chanCfg.subScenaStr,'-',chanCfg.pLosStr);
    simuParams.paaCfgStr = strcat(chanCfg.antTypeStr,'-',chanCfg.hpbwStr);
elseif chanCfg.chanFlag == 4
    simuParams.chanCfgStr = strcat(chanCfg.MdlStr,'-',chanCfg.EnvStr,'-',simuParams.doppFlagStr,'-',chanCfg.RrayType,'-',chanCfg.ReflecOrder);
    if isempty(chanCfg.numTaps)
        simuParams.tdlCfgStr = strcat('TDL',simuParams.tdlTypeStr,num2str(chanCfg.tdlMimoNorFlag));
    else
        simuParams.tdlCfgStr = strcat('TDL',simuParams.tdlTypeStr,num2str(chanCfg.tdlMimoNorFlag),'-Tap',num2str(chanCfg.numTaps));
    end
    simuParams.paaCfgStr = strcat('PAA',chanCfg.paaCfg.arrayDimension);
    simuParams.abfCfgStr = strcat(chanCfg.paaCfg.beamSelection,'-',chanCfg.paaCfg.beamReduction);
else
    error('chanFlag should be 0~4.');
end

simuParams.simuCfgStr = strcat('T',num2str(simuParams.pktFormatFlag),'C',num2str(simuParams.chanFlag));
if chanCfg.chanFlag == 4
    simuParams.mimoCfgStr = vec2str(chanCfg.nistChan.graphTxRxOriginal);
else
    simuParams.mimoCfgStr = vec2str(phyParams.numSTSVec);
end

simuParams.dbfCfgStr = sprintf('P%dV%dA%dQ%dE%dW%d', ...
    phyParams.processFlag, phyParams.svdFlag, phyParams.powAlloFlag, phyParams.precAlgoFlag, phyParams.equiChFlag, phyParams.equaAlgoFlag);

if strcmp(simuParams.metricStr,'ER')
    if size(phyParams.mcsMU,1) == 1
        simuParams.mcsCfgStr = sprintf('MCS%d', phyParams.mcsMU(1,1));
    else
        simuParams.mcsCfgStr = sprintf('MCS%d-%d', phyParams.mcsMU([1 end],1));
    end
else
    simuParams.mcsCfgStr = '';
end
simuParams.pmFolderStr = [simuParams.metricStr,'_',simuParams.simTypeStr,'_',simuParams.pktFormatStr,'_', ...
    phyParams.phyMode,'_',simuParams.mimoFlagStr,'_U',num2str(phyParams.numUsers),'_X',num2str(phyParams.numTxAnt), ...
    '_',simuParams.giTypeStr,'_',simuParams.chanCfgStr,'_',simuParams.tdlCfgStr,'_',simuParams.paaCfgStr,'_',simuParams.dtStr];

end
% End of file