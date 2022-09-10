function [txBf, rxBf, txAngle, rxAngle] = getAllBeamformingVectors(cbTx,cbRx, varargin)

p = inputParser;
addParameter(p,'paa', [1 1]);
addParameter(p,'NAp', 1);
addParameter(p,'nodes', 2);

parse(p, varargin{:});
paaNodes  = p.Results.paa;
NAp  = p.Results.NAp;
nodes  = p.Results.nodes;

apId = 1:NAp;
staId = NAp+1:nodes;
numApSectors = cbTx.numSectors;
numStaSectors = cbRx.numSectors;
nApAnt = cbTx.numElements;
nStaAnt = cbRx.numElements;
txBfId = nchoosek(1:numApSectors,paaNodes(apId));
rxBfId = nchoosek(1:numStaSectors,paaNodes(staId));
txBfComb = size(txBfId,1);
rxBfComb = size(rxBfId,1);


txBf = zeros(paaNodes(apId)* nApAnt, txBfComb);
rxBf = zeros(paaNodes(staId)* nStaAnt, rxBfComb);

for txPaa = 1:paaNodes(apId)
    for rxPaa = 1:paaNodes(staId)
        txPaaId = (txPaa-1)*nApAnt+1:(txPaa-1)*nApAnt+nApAnt;
        rxPaaId = (rxPaa-1)*nStaAnt+1:(rxPaa-1)*nStaAnt+nStaAnt;
        txBf(txPaaId,:) = [cbTx.weightingVector(:,txBfId(:,txPaa))];
        rxBf(rxPaaId,:) = [cbRx.weightingVector(:,rxBfId(:,rxPaa))];
        txAngle = [cbTx.steeringAngle(txBfId(:,txPaa),:)];
        rxAngle = [cbRx.steeringAngle(rxBfId(:,rxPaa),:)];
    end
end
if txBfComb == 0
    txBf = 1;
    txAngle = nan;
end
if rxBfComb ==0
    rxBf = 1;
    rxAngle = nan;
end
