function params =  configChannel(scenarioPath, chanModel)
%CONFIGCHANNEL loads the channel parameters 
%   CONFIGCHANNEL(FOLDERPATH, FILENAME) loads the channel parameters 
%   from FILENAMEConfig.txt relative to the scenarios in FOLDERPATH
%   and it checks if the loaded parameters are in the expected range.
%   FILENAME is specified as 'AWGN','Rayleigh','NIST','Intel',
%   'MatlabTgay'.
%
%   P = CONFIGCHANNEL(FOLDERPATH, 'Rayleigh') returns the parameter 
%   structure P.
%   P fields:
%       numTaps: Number of taps specified as a positive integer. (Default
%       value = 10)
%       maxMimoArrivalDelay: Sample offset in the CIR (Default value = 0)
%       pdpMethodStr: Power delay profile specified as 'PS', 'Equ' or
%       'Exp'.
%       tdlType: Channel interpolation method specified as 'Impulse' or
%       'Sinc'.
%
%   P = CONFIGCHANNEL(FOLDERPATH, 'NIST') returns the parameter structure
%   P.
%   P fields:
%       environmentFileName: channel model environment specified as 'LR'
%       living room, 'OAH' for open access hotspot or 'SC' for street
%       canyon
%       totalNumberOfReflections: defines the reflection order, specified
%       as a positive integer
%       tdlType: Channel interpolation method specified as 'Impulse' or
%       'Sinc'.
%       rRayType: Generate random rays specified as: DeteR
%
%   See also CONFIGSIMULATION, CONFIGPHY

%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

%% Load params
if ~strcmp(chanModel, 'AWGN')
	try
		cfgPath = fullfile(scenarioPath, ['Input/channel',chanModel ,'Config.txt']);
		paramsList = readtable(cfgPath,'Delimiter','\t', 'Format','%s %s' );
		paramsCell = (table2cell(paramsList))';
		params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);
	catch
		warning('Default %s channel', chanModel)
		params = [];
	end
end

%% 
switch chanModel
    case 'AWGN'
        params =[];
    case 'Rayleigh'
        params = fieldToNum(params, 'numTaps', [1 192], 'step', eps,  'defaultValue',10);
        params = fieldToNum(params, 'maxMimoArrivalDelay', [0 192], 'step', eps , 'defaultValue',0);
        params = fieldToNum(params, 'pdpMethodStr', {'PS', 'Equ', 'Exp'},  'defaultValue', 'Exp');
        params = fieldToNum(params, 'tdlType', {'Impulse', 'Sinc'},'defaultValue','Impulse');

    case 'NIST'
        params = fieldToNum(params, 'environmentFileName', {'LiR','LR', 'OAH', 'SC'},  'defaultValue','LR');
        params = fieldToNum(params, 'indoorSwitch', [0,1],  'defaultValue',1);
        params = fieldToNum(params, 'numberOfTimeDivisions', [1 inf], 'step', eps, 'defaultValue',1);
        if isfield(params,'referencePoint')
            params.referencePoint = str2num(params.referencePoint); %#ok<ST2NM>
        else
            params.referencePoint = [3,3,2];
        end
        params = fieldToNum(params, 'selectPlanesByDist', [-inf inf],'step', eps, 'defaultValue', 0);
        params = fieldToNum(params, 'switchQDGenerator', [0,1], 'defaultValue', 0);
        params = fieldToNum(params, 'numberOfNodes', [2 100], 'step',1, 'defaultValue', 2);
        params = fieldToNum(params, 'totalNumberOfReflections', [1 4], 'step',1, 'defaultValue', 1);
        params = fieldToNum(params, 'totalTimeDuration', [0 inf],'step', eps,'defaultValue',  1);
        params = fieldToNum(params, 'switchSaveVisualizerFiles', [0,1],'defaultValue', 0);
        params = fieldToNum(params, 'carrierFrequency', [58e9 71e9],'step', eps, 'defaultValue', 60e9);
        params = fieldToNum(params, 'qdFilesFloatPrecision', [1 10],'step', 1, 'defaultValue', 6);
        params = fieldToNum(params, 'useOptimizedOutputToFile', [0 1], 'defaultValue',1);
        params = fieldToNum(params, 'jsonOutput', [0 1], 'defaultValue',1);
        params = fieldToNum(params, 'rRayType', {'DeteR'}, 'defaultValue','DeteR');
        params = fieldToNum(params, 'tdlType', {'Impulse', 'Sinc'},'defaultValue','Impulse');
        params = fieldToNum(params, 'numTaps', [1 512], 'step',1, 'defaultValue',[]);
        params = fieldToNum(params, 'rxPowThresType', {'Inactivated','Static','Dynamic'}, 'defaultValue','Inactivated');
        params = fieldToNum(params, 'rxPowThresdB', [0 100], 'step',1, 'defaultValue',[]);
        params = fieldToNum(params, 'realizationIndexType', {'Fixed','Random'},'defaultValue','Random');
        params = fieldToNum(params, 'realizationSetType', {'Combined','Individual'},'defaultValue','Combined');
        params = fieldToNum(params, 'realizationSetIndexVec', [1 100], 'step',1, 'defaultValue', [1:20]);
        params = fieldToNum(params, 'dataSetSizeStr', [], 'defaultValue','20X100');

    case 'Intel'
        
    case 'MatlabTGay'
		error('MatlabTGay channel not supported')
        params = fieldToNum(params, 'environmentFileName', {'LHL-SU-SISO', 'OAH-SU-SISO', 'LHL-SU-SISO', 'OAH-SU-SISO' ...
          'LHL-SU-MIMO1x1SS', 'LHL-SU-MIMO1x1DD', 'OAH-SU-MIMO1x1DD', ...
          'SCH-SU-MIMO1x1DD', 'SCH-SU-MIMO2x2SS',  'SCH-SU-MIMO2x2DD', ...
          'IndoorMIMO2x2SS',  'IndoorMIMO2x2DD',  'SCH-SU-MIMO2x2DD-HBF'},  'defaultValue','LHL-SU-SISO');
        params = fieldToNum(params, 'showEnvironment', [0,1], 'defaultValue', 0);
        params = fieldToNum(params, 'tdlType', {'Impulse', 'Sinc'},'defaultValue','Impulse');
        params = fieldToNum(params, 'tdlMimoNorFlag', [0,1], 'defaultValue', 1);
        params = fieldToNum(params, 'ReceiveArrayVelocitySource', {'Auto', 'Custom'}, 'defaultValue', 'Auto');
        if isfield(params,'ReceiveArrayVelocity')
            params.ReceiveArrayVelocity = str2num(params.ReceiveArrayVelocity); %#ok<ST2NM>
        else
            params.ReceiveArrayVelocity = [4,4,0];
        end
        params = fieldToNum(params, 'numTaps', [1 128], 'defaultValue', []);

end
params.chanModel = chanModel;

end