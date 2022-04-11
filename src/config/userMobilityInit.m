function userMobility =  userMobilityInit(nodes, nTimeSamp, varargin)
%%USERMOBILITYINIT Mobility struct
%
%   USERMOBILITYINIT(N,T) generates the mobility struct with random
%   position orientation and rotation for N nodes and for T samples.
%
%   USERMOBILITYINIT(...,Name,Value) generates the mobility struct with
%   the specified field Name set to the specified Value.
%
%   USERMOBILITYINIT field:
%
%   Position: 3xT
%   Orientation: 3x1
%   Rotation: 3xT
%
%   Copyright 2022 NIST/CLT (steve.blandino@nist.gov)


userMobility = struct('Orientation', cell(1,nodes),...
    'Rotation', cell(1,nodes), ...
    'Position', cell(1,nodes) );


for nodeId = 1:nodes
    userMobility(nodeId).Position = setParam(userMobility(nodeId).Position, 1+abs(rand(3, nTimeSamp)));
    userMobility(nodeId).Orientation = setParam(userMobility(nodeId).Orientation, zeros(3, 1));
    userMobility(nodeId).Rotation = setParam(userMobility(nodeId).Rotation, zeros(3, nTimeSamp));
end


end

function field = setParam(field, value)
if isempty(field)
    field = value;
else
end
end