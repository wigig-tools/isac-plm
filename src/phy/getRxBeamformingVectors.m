function rxBf = getRxBeamformingVectors(cbRx, varargin)
%% GETBEAMFORMINGVECTORS Returns beamforming vectors
%
%   BF = GETBEAMFORMINGVECTORS(CB) returns vectors BF given the codebook CB
%

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


p = inputParser;
addParameter(p,'paa', [1 1]);
addParameter(p,'NAp', 1);
addParameter(p,'nodes', 2);

parse(p, varargin{:});
paaNodes  = p.Results.paa;
NAp  = p.Results.NAp;
nodes  = p.Results.nodes;

numStaSectors = cbRx.numSectors;
nStaAnt = cbRx.numElements;
rxBfId = nchoosek(1:numStaSectors,paaNodes(2));
rxBfComb = size(rxBfId,1);
staId = NAp+1:nodes;

rxBf = zeros(paaNodes(staId)* nStaAnt, rxBfComb);

for rxPaa = 1:paaNodes(staId)
    rxPaaId = (rxPaa-1)*nStaAnt+1:(rxPaa-1)*nStaAnt+nStaAnt;
    rxBf(rxPaaId,:) = [cbRx.weightingVector(:,rxBfId(:,rxPaa))];
end