function cfgSim = setPhySystemConfig(simuParams,phyParams,channelParams)
%setPhySystemConfig Setup System Configuration for internal functions
%   
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

% cfgSim = struct;
cfgSim.debugFlag = simuParams.debugFlag;
cfgSim.metricStr = simuParams.metricStr;
cfgSim.simTypeStr = simuParams.simTypeStr;
cfgSim.pktFormatFlag = simuParams.pktFormatFlag;
cfgSim.pktFormatStr = simuParams.pktFormatStr;
cfgSim.phyMode = phyParams.phyMode;
cfgSim.symbOffset = phyParams.symbOffset;
cfgSim.ldpcDecMethod = phyParams.ldpcDecMethod;
cfgSim.softCsiFlag  = phyParams.softCsiFlag;
cfgSim.dopplerFlag = simuParams.dopplerFlag;
cfgSim.doppFlagStr = simuParams.doppFlagStr;
cfgSim.chanFlag = channelParams.chanFlag;
cfgSim.chanModel = channelParams.chanModel;
cfgSim.processFlag = phyParams.processFlag;
cfgSim.snrMode = simuParams.snrMode;
cfgSim.snrAntNormFlag = simuParams.snrAntNormFlag;
cfgSim.snrAntNormFactor = simuParams.snrAntNormFactor;
cfgSim.snrAntNormStr = simuParams.snrAntNormStr;
cfgSim.mimoFlag = simuParams.mimoFlag;
cfgSim.mimoFlagStr =simuParams.mimoFlagStr;
cfgSim.svdFlag = phyParams.svdFlag;
cfgSim.powAlloFlag = phyParams.powAlloFlag;
cfgSim.precAlgoFlag = phyParams.precAlgoFlag;
cfgSim.precNormFlag = phyParams.precNormFlag;
cfgSim.equiChFlag = phyParams.equiChFlag;
cfgSim.equaAlgoFlag = phyParams.equaAlgoFlag;
cfgSim.equaAlgoStr = simuParams.equaAlgoStr;
cfgSim.giTypeStr = simuParams.giTypeStr;
cfgSim.chanCfgStr = simuParams.chanCfgStr;
cfgSim.tdlCfgStr = simuParams.tdlCfgStr;
cfgSim.tdlTypeStr = simuParams.tdlTypeStr;
cfgSim.paaCfgStr = simuParams.paaCfgStr;
cfgSim.abfCfgStr = simuParams.abfCfgStr;
cfgSim.realizationSetCfgStr = simuParams.realizationSetCfgStr;
cfgSim.simuCfgStr = simuParams.simuCfgStr;
cfgSim.mimoCfgStr = simuParams.mimoCfgStr;
cfgSim.stsCfgStr = simuParams.stsCfgStr;
cfgSim.dbfCfgStr = simuParams.dbfCfgStr;
cfgSim.mcsCfgStr = simuParams.mcsCfgStr;
cfgSim.phyCfgStr = simuParams.phyCfgStr;
cfgSim.pmNameStr = simuParams.pmNameStr;
cfgSim.fiNameStr = simuParams.fiNameStr;
cfgSim.wsNameStr = simuParams.wsNameStr;
cfgSim.figNameStrBER = simuParams.figNameStrBER;
cfgSim.figNameStrPER = simuParams.figNameStrPER;
cfgSim.figNameStrSE = simuParams.figNameStrSE;
cfgSim.delay = simuParams.delay;
cfgSim.zeroPadding  = simuParams.zeroPadding;

end
