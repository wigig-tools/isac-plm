function channel = channelDependentParams(system, paa, userMobility, varargin)
%%CHANNELDEPENDENTPARAMS helper function Q-D config
%   
%   C   = CHANNELDEPENDENTPARAMS(S, P, M) returns the channel structure C
%   given the system structure S, the PAA structure P and the user mobility
%   structure M. The channel structure C can be used to write the
%   configuration of file of the NIST Q-D channel realization software.
%
%   C   = CHANNELDEPENDENTPARAMS(..., 'carrierFrequency', val) specifies
%   the carrier frequency in Hz. If not specified 60e9 Hz is assumed.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

p = inputParser;
addParameter(p,'carrierFrequency', 60e9);
parse(p, varargin{:});

channel.carrierFrequency = p.Results.carrierFrequency;
channel.numberOfTimeDivisions	= system.nTimeSamp;
numberOfNodes = size(paa,2);
channel.numberOfNodes = numberOfNodes;

% Get PAA information 
for node = 1:numberOfNodes
    channel.nodePaaConfigFile{node} = [paa(node).Position; paa(node).Orientation].';
    channel.nodePositionConfigFile{node} = userMobility(node).Position.';
    channel.nodeRotationConfigFile{node} = userMobility(node).Rotation.';
end

end