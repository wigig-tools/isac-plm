function params =  configSimulation(scenarioPath, varargin)
%CONFIGSIMULATION loads the 802.11ay simulation parameters 
%   CONFIGSIMULATION(FOLDERPATH) loads the 802.11ay simulation parameters 
%   from simulationConfig.txt relative to the scenarios in FOLDERPATH
%   and it checks if the loaded parameters are in the expected range.
%
%   P = CONFIGSIMULATION(FOLDERPATH) returns the parameter structure P.
%
%   P field:
%       debugFlag	   : debug flag. 0: Results, 1: Debug, 2: Test (Default
%       = 0)
%
%       pktFormatFlag  : packet format flag. 0: PPDU, 1: PSDU (data-only).
%       (Default = 1)
%
%       chanModel	   : channel model. 'AWGN','NIST','Rayleigh','Intel', 
%       'MatlabTGay'. (Default = 'Rayleigh')
%
%       dopplerFlag    : doppler flag. 0: Doppler off (block fading). 
%       1: Doppler ON. (Default = 0)
%
%       snrMode	       : 'EsNo', 'EbNo', 'SNR'. (Default value: EsNo)
%
%       snrAntNormFlag: SNR Rx antenna normalization flag.
%       0: AllAnt. 1:PerAnt
%
%       snrRange	   : Define the SNR range in dB specified as a 1-by-2 
%       vector of scalar. (Default [0 20])
%
%       snrStep	   : Define the SNR step in dB specified as a positive
%       scalar. The simulation SNR points are generated in the range 
%       snrRanges with a step of snrStep, i.e.
%       snrRanges(1):snrStep:snrRanges(2)

%       maxNumErrors	: Maximum number of error specified as a positive 
%       integer. (Default = 100)
%       maxNumPackets	: Maximum number of packets specified as positive 
%       interger. (Default = 1000)
%
%   See also CONFIGPHY,CONFIGCHANNEL 

%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

p = inputParser;

defaultMode = false;
checkInputValidity = @(x) islogical(x);
addOptional(p,'isac',defaultMode,checkInputValidity)
parse(p,varargin{:})
isIsac = p.Results.isac;

%% Load params
cfgPath = fullfile(scenarioPath, 'Input/simulationConfig.txt');
if ~isfile(cfgPath)
    error('Config file %s not defined', cfgPath)
end
paramsList = readtable(cfgPath,'Delimiter','\t', 'Format','%s %s' );
paramsCell = (table2cell(paramsList))';
params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);

%% Check validity
params = fieldToNum(params, 'debugFlag', [0 2],'step', 1,'defaultValue', 0);
if isIsac
    params = fieldToNum(params, 'psduMode', 0,'defaultValue', 0);
else
    params = fieldToNum(params, 'psduMode', [0 1],'defaultValue', 1);
end
params = fieldToNum(params, 'dopplerFlag', [0 1],'defaultValue', 0);
params = fieldToNum(params, 'noiseFlag', [0 1 2],'defaultValue', 2);
params = fieldToNum(params, 'snrMode', {'EsNo','EbNo','SNR'},'defaultValue','EsNo');
params = fieldToNum(params, 'snrAntNormFlag', [0 1],'defaultValue',0);
params = fieldToNum(params, 'snrStep', [0 inf],'step',eps,'defaultValue', 1);
params = fieldToNum(params, 'snrRange', [-inf inf], 'step',eps,'defaultValue',[300 300]);
params = fieldToNum(params, 'maxNumErrors', [0 inf],'step',eps, 'defaultValue',1e2);
params = fieldToNum(params, 'maxNumPackets', [0 inf],'step',eps, 'defaultValue',1e3);
params = fieldToNum(params, 'snrSeed', [1 inf],'step',eps, 'defaultValue',1e2);
params = fieldToNum(params, 'nTimeSamp', [1 1e4],'step', 1, 'defaultValue',1);
params = fieldToNum(params, 'sensPlot', [0 1], 'step', 1, 'defaultValue', 0);
params = fieldToNum(params, 'saveRdaMap', [0 1], 'step', 1, 'defaultValue', 0);
params = fieldToNum(params, 'disableRdaAxis', [0 1], 'step', 1, 'defaultValue', 0);
params = fieldToNum(params, 'saveCsi', [0 1], 'step', 1, 'defaultValue', 0);
params.wsNameStr = pwd;
end

