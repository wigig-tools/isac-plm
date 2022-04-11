function [outputChannel, varargout] = loadChannel(channel, pathScenario, varargin)
%LOADCHANNEL returns the multi user propagation channel generated with NIST
%   QD software.
%
%   H = LOADCHANNEL(N) returns a NxN hollow struct array, where N is the
%   number of nodes.
%   The entry of the struct (i,j) inculdes the channel struct of dimension
%   1x(NPAA_i x NPAA_j) including the following fields:
%   ** delay
%   ** amplitude
%   ** phase
%   ** aod_el
%   ** aod_az
%   ** aoa_el
%   ** aoa_az

%   H = LOADCHANNEL(N, 'nodePAA', [NPAA_1, NPAA_2, ..., NPAA_N]) specifies
%   the number of PAAs expected per node.
%
%   H = LOADCHANNEL(N, 'filePath', 'path') allows to specify the folder
%   location of the QD output.
%
%   Copyright 2020 NIST/CLT (steve.blandino@nist.gov)

%#codegen

if channel.runQd
    
    dirPathCfgChan = fullfile(pathScenario, 'Input');
    dirPathChan = fullfile(pathScenario, 'Output');
    if ~exist(dirPathCfgChan, 'dir')
        mkdir(dirPathCfgChan)
    end
    [~,folderName] = fileparts(pathScenario); %#ok<ASGLU>
    %% Write config files
    
    for node = 1:channel.numberOfNodes
        writematrix(channel.nodePositionConfigFile{node}, fullfile(dirPathCfgChan, sprintf('NodePosition%d.dat',node-1)));
        writematrix(channel.nodeRotationConfigFile{node}, fullfile(dirPathCfgChan, sprintf('NodeRotation%d.dat',node-1)));
        writematrix(channel.nodePaaConfigFile{node}, fullfile(dirPathCfgChan, strcat('node', num2str(node-1), 'paa.dat')));
    end
    
    paraCfg = rmfield(channel, {'nodePaaConfigFile', 'nodePositionConfigFile', 'nodeRotationConfigFile','numberOfNodes','chanModel', 'runQd','chanFlag', 'tgayChannel','nistChan', 'numTaps'});
    writetable(table(struct2cell(paraCfg), 'RowNames', fieldnames(paraCfg)), fullfile(dirPathCfgChan, 'paraCfgCurrent'),'WriteRowNames', true, 'WriteVariableNames', false, 'Delimiter' , '\t');
    writematrix(zeros(channel.numberOfNodes,3), fullfile(dirPathCfgChan,  'nodeVelocities.dat') )
    
    run(fullfile(pathScenario(1:find(pathScenario==filesep, 2, 'last' )), 'main_fun(folderName)'))
else
    dirPathChan = fullfile(pathScenario,'Input/qdChannel');
end

fid = fopen(fullfile(dirPathChan,'qdOutput.json'));
if ~fid
    error('Provide input channel')
end

paaNodes  = cellfun(@(x) size(x,1),channel.nodePaaConfigFile);
Nlines = 1;
s = struct('tx', cell(1,Nlines), ...
    'rx', cell(1,Nlines), ...
    'paaTx', cell(1,Nlines), ...
    'paaRx', cell(1,Nlines), ...
    'delay', cell(1,Nlines), ...
    'gain', cell(1,Nlines), ...
    'phase', cell(1,Nlines), ...
    'aodEl', cell(1,Nlines), ...
    'aodAz', cell(1,Nlines), ...
    'aoaEl', cell(1,Nlines), ...
    'aoaAz', cell(1,Nlines) ...
    );
while ~feof(fid)
    tline = fgetl(fid);
    s(Nlines) = jsondecode(tline);
    Nlines = Nlines+1;
end

fclose(fid);

nodeList = 1:channel.numberOfNodes;
id = 1;
outputChannel = cell(channel.numberOfNodes,channel.numberOfNodes);
for tx = nodeList
    for rx = nodeList(nodeList~=tx)
        for txPaa = 1:paaNodes(tx)
            for rxPaa = 1:paaNodes(rx)
                outputChannel{tx,rx}.channelMimo{txPaa, rxPaa} = s(id);
                id = id+1;
            end
        end
    end
end


fid = fopen(fullfile(dirPathChan,'qdTargetOutput.json'));
if fid>0
    paaNodes  = cellfun(@(x) size(x,1),channel.nodePaaConfigFile);
    Nlines = 1;
    s = struct('tx', cell(1,Nlines), ...
        'rx', cell(1,Nlines), ...
        'paaTx', cell(1,Nlines), ...
        'paaRx', cell(1,Nlines), ...
        'target', cell(1,Nlines), ...
        'delay', cell(1,Nlines), ...
        'gain', cell(1,Nlines), ...
        'phase', cell(1,Nlines), ...
        'aodEl', cell(1,Nlines), ...
        'aodAz', cell(1,Nlines), ...
        'aoaEl', cell(1,Nlines), ...
        'aoaAz', cell(1,Nlines) ...
        );
    while ~feof(fid)
        tline = fgetl(fid);
        s(Nlines) = jsondecode(tline);
        Nlines = Nlines+1;
    end

    fclose(fid);

    id = 1;
    outputTargetChannel = cell(channel.numberOfNodes,channel.numberOfNodes);
    for tx = nodeList
        for rx = nodeList(nodeList~=tx)
            for txPaa = 1:paaNodes(tx)
                for rxPaa = 1:paaNodes(rx)
                    outputTargetChannel{tx,rx}.channelMimo{txPaa, rxPaa} = s(id);
                    id = id+1;
                end
            end
        end
    end
    varargout{1} = outputTargetChannel;
else
    varargout{1} =  [];
end

end


function structOut = initializeChannelStruct(varName, NChan) %#ok<INUSD>
% Helper function: create emty channel structure with field varName.
x= repmat('varName{%d}, cell(1,NChan),',[1 length(varName)]);
x(end) = [];
x= sprintf(x, 1:length(varName));
structOut = eval(['struct(', x,');']);
end

function structIn = sisoMat2struct(structIn, sisoChan) %#ok<INUSD>
% Helper function: convert matrix in structure
fn = fieldnames(structIn);
for i = 1:length(fn)
    eval(['structIn.',fn{i},'= sisoChan(',num2str(i), ',:);'])
end
end