function paaInfo = paaInit(varargin)
%%PAAINIT generates mm-wave antenna array parameters structure.
%
%   paaInfo = PAAINIT(Name,Value) generates the mm-wave antenna array
%   parameters structure with the specified field Name set to the specified
%   Value.
%
%
%   PAAINIT field:
%
%   NumPaa               - Number of PAAs at each node
%   Position             - PAA positions
%   Orientation          - PAA orientation
%   Polarization         - PAA polarization
%   Geometry             - PAA geometry
%   NumAntenna           - Number of antennas in each PAA
%   NumAntennaVert       - Number of antennas in the vertical direction
%   AntennaElement       - Antenna element radiation pattern
%   isAntennaBackBaffled - Cut back plane
%   phaseQuantizationBits- Phase shifter quantization (bit)
%   ampQuantizationBits  - Phase shifter quantization (bit)
%
%   NumPaa Number of PAA at each node
%   Specify the number of nodes in the system as integer scalar. It should
%   be greater or equal 2. The default value of this field is 2.
%
%
%   Copyright 2020 NIST/CLT (steve.blandino@nist.gov)

p = inputParser;
p.KeepUnmatched=true;

var_struct = {'Nodes'};
defaultNodes = 2;
checkNodes = @(x) (rem(x,1)==0);

addOptional(p,var_struct{1},defaultNodes,checkNodes)
parse(p,varargin{:})

Nodes = p.Results.Nodes;

paaInfo = struct('NumPaa', cell(1,Nodes), ...
    'Position', cell(1,Nodes), ...
    'Orientation', cell(1,Nodes), ...
    'Polarization', cell(1,Nodes), ...
    'Geometry', cell(1,Nodes), ...
    'NumAntenna', cell(1,Nodes), ...
    'NumAntennaVert', cell(1,Nodes), ...
    'AntennaElement', cell(1,Nodes), ...
    'isAntennaBackBaffled', cell(1,Nodes), ...
    'phaseQuantizationBits', cell(1,Nodes),...
    'ampQuantizationBits', cell(1,Nodes),...
    'NumAntennaHor', cell(1,Nodes) );

isURA= @(x,y) (x~=1).* (y~=1)==1;

for ii = 1:2:nargin
    fname = varargin{ii};
    fvalue = varargin{ii+1};
    if ~any(strcmp(fname, var_struct))
        if ~isfield(paaInfo, fname)
            error (['No field with name ', fname, ...
                ' is defined in PAA struct'])
        end
        if isscalar(fvalue)
            paaInfo =  arrayfun(@(x) (setfield(x, fname, fvalue)), paaInfo);
        elseif iscell(fvalue)
            for nodeId = 1:Nodes
                paaInfo(nodeId).(fname) = fvalue{nodeId};
            end
        else
            for nodeId = 1:Nodes
                paaInfo(nodeId).(fname) = fvalue(nodeId);
            end
        end
    end
end
for nodeId = 1:Nodes
    paaInfo(nodeId).NumPaa = setParam(paaInfo(nodeId).NumPaa,1);
    paaInfo(nodeId).Position = setParam(paaInfo(nodeId).Position, zeros(3, paaInfo(nodeId).NumPaa));
    paaInfo(nodeId).Orientation = setParam(paaInfo(nodeId).Orientation, zeros(3, paaInfo(nodeId).NumPaa));
    paaInfo(nodeId).Geometry = setParam(paaInfo(nodeId).Geometry, 'UniformLinear');
    paaInfo(nodeId).NumAntenna  = setParam(paaInfo(nodeId).NumAntenna, 2);
    paaInfo(nodeId).NumAntennaVert  = setParam(paaInfo(nodeId).NumAntennaVert, 1);
    paaInfo(nodeId).AntennaElement =  setParam(paaInfo(nodeId).AntennaElement, 'Isotropic');
    paaInfo(nodeId).isAntennaBackBaffled = setParam(paaInfo(nodeId).isAntennaBackBaffled, 'true');
    paaInfo(nodeId).phaseQuantizationBits   = setParam(paaInfo(nodeId).phaseQuantizationBits,0);
    paaInfo(nodeId).ampQuantizationBits     = setParam(paaInfo(nodeId).ampQuantizationBits,2);
    switch paaInfo(nodeId).Geometry
        case 'UniformLinear'
            assert(paaInfo(nodeId).NumAntenna == paaInfo(nodeId).NumAntennaVert || ...
                paaInfo(nodeId).NumAntennaVert ==1, ...
                [' Config Error: Uniform Linear Array. Set' ...
                'NumAntennaVert = 1 or NumAntennaVert = NumAntenna']);
            paaInfo(nodeId).NumAntennaHor = paaInfo(nodeId).NumAntenna/paaInfo(nodeId).NumAntennaVert;


        case 'UniformRectangular'
            assert(~mod(params.NumAntenna,params.NumAntennaVert),...
                [cfgPathPaaNode, ' Config Error: Uniform Rectangular Array. Set' ...
                'NumAntenna/NumAntennaVert should be integer']);
            params.NumAntennaHor = params.NumAntenna/params.NumAntennaVert;
    end
end

end

function field = setParam(field, value)
if isempty(field)
    field = value;
else
end
end