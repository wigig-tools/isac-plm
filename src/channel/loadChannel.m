function [outputChannel, varargout] = loadChannel(pathScenario, varargin)
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
%   Copyright 2020-2022 NIST/CLT (steve.blandino@nist.gov)


p = inputParser;
addParameter(p,'paa', [1 1]);
parse(p, varargin{:});

paaNodes  = p.Results.paa;
nodes = length(paaNodes);

dirPathChan = fullfile(pathScenario,'Input/qdChannel');
fid = fopen(fullfile(dirPathChan,'qdOutput.json'));
if ~fid
    error('Provide input channel')
end

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

nodeList = 1:nodes;
id = 1;
outputChannel = cell(nodes,nodes);
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
    numTgt = max([s.target])+1;
    outputTargetChannel = cell(nodes,nodes);
    for tx = nodeList
        for rx = nodeList(nodeList~=tx)
            for txPaa = 1:paaNodes(tx)
                for rxPaa = 1:paaNodes(rx)
                    for tgId = 1:numTgt 
                    	outputTargetChannel{tx,rx}.channelMimo{txPaa, rxPaa,tgId} = s(id);
                    	id = id+1;
                    end
                end
            end
        end
    end
    varargout{1} = outputTargetChannel;
else
    varargout{1} =  [];
end

end