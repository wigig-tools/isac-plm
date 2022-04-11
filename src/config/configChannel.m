function params =  configChannel(scenarioPath)
%CONFIGCHANNEL loads the channel parameters
%   CONFIGCHANNEL(SCENARIOPATH) loads the channel parameters
%   from SCENARIOPATH/Input/channelConfig.txt and it checks if the loaded 
%   parameters are in the expected range.
%
%
%   See also CONFIGSIMULATION, CONFIGPHY

%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Load params
cfgPath = fullfile(scenarioPath, 'Input/channelConfig.txt');

try
    paramsList = readtable(cfgPath,'Delimiter','\t', 'Format','%s %s' );
catch
    error('Channel not defined')
end

paramsCell = (table2cell(paramsList))';
params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);

%%
switch params.chanModel
    case 'AWGN'
        
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

    case 'sensNIST'
        params.runQd = any(cellfun(@(x) strcmp(x, 'qdSrcFolder'),  fieldnames(params)));
        if params.runQd
            params = fieldToNum(params, 'environmentFileName', {'Box.xml','LectureRoom.xml'}, 'defaultValue', 'LectureRoom.xml');
            params = fieldToNum(params, 'generalizedScenario', [0 1], 'defaultValue', 0);
            params = fieldToNum(params, 'indoorSwitch', [0 1], 'defaultValue', 	1);
            if isfield(params,'referencePoint')
                params.referencePoint = str2num(params.referencePoint); %#ok<ST2NM>
            else
                params.referencePoint = [0,0,0];
            end
            params = fieldToNum(params, 'selectPlanesByDist', [0 1], 'defaultValue', 0);
            params = fieldToNum(params, 'switchQDGenerator', [0 1], 'defaultValue', 0);
            params = fieldToNum(params, 'switchRandomization',[0 1], 'defaultValue', 0);
            params = fieldToNum(params, 'totalNumberOfReflections', 0:2, 'defaultValue', 1);
            params = fieldToNum(params, 'totalTimeDuration', [0 inf],'step', eps,'defaultValue',128.28);
            params = fieldToNum(params, 'switchSaveVisualizerFiles' , 0:1, 'defaultValue',1);
            params = fieldToNum(params, 'qdFilesFloatPrecision', [1:6],'defaultValue', 6);
            params = fieldToNum(params, 'jsonOutput', 0:1,'defaultValue', 1);
            params = fieldToNum(params, 'switchQDModel', {'nistMeasurements', 'tgayMeasurements'},'defaultValue', 'nistMeasurements');
            params = fieldToNum(params, 'outputFormat', {'txt', 'json', 'both'},'defaultValue', 'json');
        end
        params = fieldToNum(params, 'numTaps', [1 192], 'step', eps,  'defaultValue',128);

    otherwise
        error('Channel model not defined')
end

end