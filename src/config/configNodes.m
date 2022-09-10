function paramsOut =  configNodes(scenarioPath, varargin)
%CONFIGNODES Node Configuration
% 
% P = CONFIGNODES(S) load info relative to each node, defined in the input 
% folder S for instance the definition of PAA at each node
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


%% Load params
lengthStruct = varargin{1};

paramsOut = struct('NumPaa', cell(1,lengthStruct),...
    'Codebook',  cell(1,lengthStruct)...
     );

% Node position are configured
for iterateNumberOfNodes = 1:lengthStruct

    nodePaa = sprintf('nodePaa%d.txt', iterateNumberOfNodes-1);

    cfgPathPaaNode = fullfile(scenarioPath, ['Input/',nodePaa]);
    if isfile(cfgPathPaaNode)
        paramsList = readtable(cfgPathPaaNode,'Delimiter','\t', 'Format','auto' );
        paramsCell = (table2cell(paramsList))';
        params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);
    else 
        params = struct;
    end

    params = fieldToNum(params, 'NumPaa', [1 20], 'step', 1, 'defaultValue',1);
    params = fieldToNum(params, 'Codebook', [], 'defaultValue', 'omni');
  
    paramsOut(iterateNumberOfNodes) = orderfields(params,fieldnames(paramsOut));

end
end