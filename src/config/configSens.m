function params =  configSens(scenarioPath)
%CONFIGSENS loads the 802.11ay sensing parameters 
%   CONFIGSENS(FOLDERPATH) loads the 802.11ay simulation parameters 
%   from sensConfig.txt relative to the scenarios in FOLDERPATH
%   and it checks if the loaded parameters are in the expected range.
%
%   P = CONFIGSENS(FOLDERPATH) returns the parameter structure P.
%   P field:
%       pri: . (Default '')
%

%   See also CONFIGSIMULATION, CONFIGCHANNEL, CONFIGPHY

%   2019-2022 NIST/CTL Steve Blandino, Neeraj Varshney

%   This file is available under the terms of the NIST License.

%#codegen

%% Load params
cfgPath = fullfile(scenarioPath, 'Input/sensConfig.txt');
if isfile(cfgPath)
    paramsList = readtable(cfgPath,'Delimiter','\t', 'Format','%s %s' );
    paramsCell = (table2cell(paramsList))';
    params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);

    %% Check validity
    params = fieldToNum(params, 'pri', [eps 10], 'step', eps, 'defaultValue',0.0005);
    params = fieldToNum(params, 'dopplerFftLen', [1 2048], 'step', eps, 'defaultValue',64);
    params = fieldToNum(params, 'window', {'rect' ,'hamming','blackmanharris','gaussian'}, 'defaultValue', 'blackmanharris');
    params = fieldToNum(params, 'windowLen', [1 params.dopplerFftLen], 'step', 1, 'defaultValue', params.dopplerFftLen);
    params = fieldToNum(params, 'windowOverlap', [0 1-eps], 'step', eps, 'defaultValue', 0.5);
    params = fieldToNum(params, 'pulsesCpi', [0 1e3], 'step', 1, 'defaultValue', 16);
    params = fieldToNum(params, 'thresholdSensing', [0 1], 'defaultValue', 0);
    if params.thresholdSensing == 1
        params = fieldToNum(params, 'adaptiveThreshold', [0 1], 'defaultValue', 0);
        params = fieldToNum(params, 'numTimeDivisions', [1 1e3], 'step', 1, 'defaultValue', 5);
        params = fieldToNum(params, 'threshold', [0 1], 'step', eps, 'defaultValue', 0);
        params = fieldToNum(params, 'stepThreshold', [0 0.5], 'step', 0.05, 'defaultValue', 0.1);
        params = fieldToNum(params, 'percentMeasurement', [0 100], 'step', eps, 'defaultValue',90);
        params = fieldToNum(params, 'csiVariationScheme', {'EucDistance','TRRS', 'FRRS','Wish'}, 'defaultValue', 'TRRS');
        params = fieldToNum(params, 'interpolationScheme', {'previousMeasuremment', 'linearInterpolation', 'autoRegressive', 'zeroPadding'}, 'defaultValue', 'previousMeasuremment');
    end

else
    params = [];
end

