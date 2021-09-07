function paramsOut =  configNodes(scenarioPath)
%CONFIGCHANNEL loads the 802.11ay PHY parameters from phyConfig.txt
%relative to the scenario defined in scenarioNameStr and it checks if the
%loaded parameters are in the expected range.
%
%   Syntax: params =  phyCfg(scenarioNameStr)
%It returns the parameter structure params given the scenario string name.
%
%   params field:
%
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen


%% Load params
listing = dir(fullfile(scenarioPath, 'Input'));
nodePositionFilesInput = sum(cell2mat(arrayfun(@(x) regexp(x.name,'NodePosition[\d].dat','once'), listing, 'UniformOutput', false)));
% nodeRotationFilesInput = sum(cell2mat(arrayfun(@(x) regexp(x.name,'NodeRotation[\d].dat','once'), listing, 'UniformOutput', false)));
nodePaaFilesInput = sum(cell2mat(arrayfun(@(x) regexp(x.name,'paaConfigNode[\d].txt','once'), listing, 'UniformOutput', false)));

assert(nodePositionFilesInput>=2 || nodePositionFilesInput==0, 'Define at least 2 NodePosition config files')
assert(nodePaaFilesInput>=2 || nodePaaFilesInput==0, 'Define at least 2 NodePosition config files')

if nodePositionFilesInput>=2
    lengthStruct = nodePositionFilesInput;
elseif nodePositionFilesInput == 0 && nodePaaFilesInput>=2
    lengthStruct = nodePaaFilesInput;
elseif nodePositionFilesInput == 0 && nodePaaFilesInput>=0
    lengthStruct = 0;
end
% nodePositionTime = cell(1,nodePositionFilesInput);
% nodeRotationTime = cell(1,nodePositionFilesInput);
paramsOut = struct('NumPaa', cell(1,lengthStruct),...
    'Position', cell(1,lengthStruct),...
    'Orientation', cell(1,lengthStruct),...
    'Polarization',  cell(1,lengthStruct),...
    'Geometry', cell(1,lengthStruct),...
    'NumAntenna', cell(1,lengthStruct),...
    'NumAntennaVert', cell(1,lengthStruct),...
    'AntennaElement', cell(1,lengthStruct),...
    'isAntennaBackBaffled', cell(1,lengthStruct),...
    'phaseQuantizationBits', cell(1,lengthStruct),...
    'ampQuantizationBits', cell(1,lengthStruct),...
    'ReceiveArrayVelocitySource', cell(1,lengthStruct),...
    'ReceiveArrayVelocity', cell(1,lengthStruct),...
    'nodePosition', cell(1,lengthStruct), ...
    'nodeRotation', cell(1,lengthStruct),...
    'NumAntennaHor', cell(1,lengthStruct),...
    'arrayDimension', cell(1,lengthStruct) );

if nodePositionFilesInput>=2
    % Node position are configured
    for iterateNumberOfNodes = 1:nodePositionFilesInput
        nodePosition = sprintf('NodePosition%d.dat', iterateNumberOfNodes-1);
        nodeRotation = sprintf('NodeRotation%d.dat', iterateNumberOfNodes-1);
        nodePaa = sprintf('paaConfigNode%d.txt', iterateNumberOfNodes-1);
        
        
        cfgPathPositionNode = fullfile(scenarioPath, ['Input/',nodePosition]);
        cfgPathRotationNode = fullfile(scenarioPath, ['Input/',nodeRotation]);
        cfgPathPaaNode = fullfile(scenarioPath, ['Input/',nodePaa]);
        
        % NodePosition processing
        nodePositionTime = load(cfgPathPositionNode);
        if sum(arrayfun(@(x) strcmp(x.name,['NodeRotation', num2str(iterateNumberOfNodes-1),'.dat']), listing))
            nodeRotationTime{iterateNumberOfNodes} = load(cfgPathRotationNode);
        else
            nodeRotationTime{iterateNumberOfNodes} = zeros(size(nodePositionTime));
        end
        
        if sum(arrayfun(@(x) strcmp(x.name,['paaConfigNode', num2str(iterateNumberOfNodes-1),'.txt']), listing))
            paramsList = readtable(cfgPathPaaNode,'Delimiter','\t', 'Format','auto' );
            paramsCell = (table2cell(paramsList))';
            params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);
        else
            params =struct();
        end
        
        params.nodePosition = nodePositionTime;
        params.nodeRotation = nodeRotationTime;
        params = fieldToNum(params, 'NumPaa', [1 20], 'step', 1, 'defaultValue',1);
        params = fieldToNum(params, 'Position', [-inf inf], 'step' ,eps, 'defaultValue', zeros(params.NumPaa,3));
        params = fieldToNum(params, 'Orientation', [-pi pi], 'step' ,eps, 'defaultValue', zeros(params.NumPaa,3));
        params = fieldToNum(params, 'Polarization', 'HV');
        params = fieldToNum(params, 'Geometry', {'UniformLinear', 'UniformRectangular'}, 'defaultValue', 'UniformLinear');
        params = fieldToNum(params, 'NumAntenna', [1 inf], 'step', eps, 'defaultValue', 16);
        params = fieldToNum(params, 'NumAntennaVert', [1 inf], 'step', eps, 'defaultValue', 4);
        params = fieldToNum(params, 'AntennaElement', {'Isotropic'}, 'defaultValue', 'Isotropic');
        params = fieldToNum(params, 'isAntennaBackBaffled', [1 0], 'defaultValue', false);
        params = fieldToNum(params, 'phaseQuantizationBits', [0 8], 'step', 1, 'defaultValue', 0);
        params = fieldToNum(params, 'ampQuantizationBits', [0 8], 'step', 1, 'defaultValue', 0);
        
        switch params.Geometry
            case 'UniformLinear'
                assert(params.NumAntenna == params.NumAntennaVert || ...
                    params.NumAntennaVert ==1, ...
                    [cfgPathPaaNode, ' Config Error: Uniform Linear Array. Set' ...
                    'NumAntennaVert = 1 or NumAntennaVert = NumAntenna']);
                params.NumAntennaHor = params.NumAntenna/params.NumAntennaVert;
                
                
            case 'UniformRectangular'
                assert(~mod(params.NumAntenna,params.NumAntennaVert),...
                    [cfgPathPaaNode, ' Config Error: Uniform Rectangular Array. Set' ...
                    'NumAntenna/NumAntennaVert should be integer']);
                params.NumAntennaHor = params.NumAntenna/params.NumAntennaVert;
        end
        
        params.arrayDimension = [num2str(params.NumAntennaHor),'x',num2str(params.NumAntennaVert)];
        paramsOut(iterateNumberOfNodes) = params;
        
    end
elseif nodePositionFilesInput ==0 && nodePaaFilesInput>=2
    % Node position are not configured but the PAA could be configured
%     nodePaaFilesInput = sum(cell2mat(arrayfun(@(x) regexp(x.name,'paaConfigNode[\d].txt','once'), listing, 'UniformOutput', false)));
    
    for iterateNumberOfNodes = 1:nodePaaFilesInput
        
        nodePaa = sprintf('paaConfigNode%d.txt', iterateNumberOfNodes-1);
        cfgPathPaaNode = fullfile(scenarioPath, ['Input/',nodePaa]);
        
        if sum(arrayfun(@(x) strcmp(x.name,['paaConfigNode', num2str(iterateNumberOfNodes-1),'.txt']), listing))
            paramsList = readtable(cfgPathPaaNode,'Delimiter','\t', 'Format','%s %s' );
            paramsCell = (table2cell(paramsList))';
            params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);
        else
            params =struct();
        end
        
        params = fieldToNum(params, 'NumPaa', [1 20], 'step', 1, 'defaultValue',1);
        params = fieldToNum(params, 'Position', [-inf inf], 'step' ,eps, 'defaultValue', zeros(params.NumPaa,3));
        params = fieldToNum(params, 'Orientation', [-pi pi], 'step' ,eps, 'defaultValue', zeros(params.NumPaa,3));
        params = fieldToNum(params, 'Polarization', 'HV');
        params = fieldToNum(params, 'Geometry', {'UniformLinear', 'UniformRectangular'}, 'defaultValue', 'UniformRectangular');
        params = fieldToNum(params, 'NumAntenna', [1 inf], 'step', eps, 'defaultValue', 16);
        params = fieldToNum(params, 'NumAntennaVert', [1 inf], 'step', eps, 'defaultValue', 4);
        params = fieldToNum(params, 'AntennaElement', {'Isotropic'}, 'defaultValue', 'Isotropic');
        params = fieldToNum(params, 'isAntennaBackBaffled', [1 0], 'defaultValue', false);
        params = fieldToNum(params, 'phaseQuantizationBits', [0 8], 'step', 1, 'defaultValue', 0);
        params = fieldToNum(params, 'ampQuantizationBits', [0 8], 'step', 1, 'defaultValue', 0);
        params = fieldToNum(params, 'ReceiveArrayVelocitySource', 'Custom', 'defaultValue', 'Custom');
        params = fieldToNum(params, 'ReceiveArrayVelocity', [], 'defaultValue', '4,4,0');
        params.nodePosition = [];
        params.nodeRotation = [];
        
        switch params.Geometry
            case 'UniformLinear'
                assert(params.NumAntenna == params.NumAntennaVert || ...
                    params.NumAntennaVert ==1, ...
                    [cfgPathPaaNode, ' Config Error: Uniform Linear Array. Set' ...
                    'NumAntennaVert = 1 or NumAntennaVert = NumAntenna']);
                params.NumAntennaHor = params.NumAntenna/params.NumAntennaVert;
                
                
            case 'UniformRectangular'
                assert(~mod(params.NumAntenna,params.NumAntennaVert),...
                    [cfgPathPaaNode, ' Config Error: Uniform Rectangular Array. Set' ...
                    'NumAntenna/NumAntennaVert should be integer']);
                params.NumAntennaHor = params.NumAntenna/params.NumAntennaVert;
        end
        
        params.arrayDimension = [num2str(params.NumAntennaHor),'x',num2str(params.NumAntennaVert)];
        paramsOut(iterateNumberOfNodes) = params;
        
    end
    
end
end
