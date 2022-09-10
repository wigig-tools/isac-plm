function [Hbfout, f, w, infoScan] = maxAnalogSnr(H,cbTx, cbRx, varargin)
%%MAXANALOGSNR    Max SNR analog beamformer
%
%   [Heq, F, W] = MAXANALOGSNR(H,CT, CR) return the equivalent channel Heq 
%   obtained appying the analog transmit beamforming vector F and the 
%   analog receive beamforming vector W on the full digital channel H. F 
%   and W are chosen from the codebook CT and CR respectively to maximize 
%   the SNR.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

p = inputParser;
addParameter(p,'paa', [1 1]);
addParameter(p,'nAp', 1);
addParameter(p,'nodes', 2);

parse(p, varargin{:});
paaNodes  = p.Results.paa;
nAp = p.Results.nAp;
nodes = p.Results.nodes;

time = size(H,1);
apId = 1:nAp;
staId = nAp+1:nodes;
nApAnt = cbTx.numElements;
nStaAnt = cbRx.numElements;
f = zeros(paaNodes(apId)*nApAnt,time);
w = zeros(paaNodes(staId)*nStaAnt,time);
wAng = zeros(time,2);
fAng = zeros(time,2);
mpcLen = size(H{1},3);
Hbfout = zeros(1,1,mpcLen,time);

%% Get beamforming vectors
[txBf, rxBf, txAngle, rxAngle] = getAllBeamformingVectors(cbTx,cbRx,'paa', paaNodes);

%% Find beamformer vector maximizing SNR
for t = 1:time
    Ht = H{t};
    % Apply Tx and Rx beamformers
    Hbft = applyAwv(Ht, txBf/sqrt(nApAnt), rxBf/sqrt(nStaAnt)); 

    % Select Fa and Wa maximizing SNR
    totPower = (sum(abs(Hbft).^2,1));

    [~,id] = max(totPower(:));
    [Itx,Irx] = ind2sub(size(reshape(totPower, size(txBf,2),size(rxBf,2))), id);

    w(:,t) = rxBf(:,Irx);
    f(:,t) = txBf(:,Itx);
    wAng(t,:) = rxAngle(Irx,:);
    fAng(t,:) = txAngle(Itx,:);

    % Get equivalent channel relative to max SNR beamformer
    Hbfout(1,1,:,t) = applyAwv(Ht, f(:,t)/sqrt(nApAnt), w(:,t)/sqrt(nStaAnt));
end
infoScan.Hbf = [];

infoScan.txBf = txBf;
infoScan.rxBf = rxBf;
infoScan.wAng = wAng;
infoScan.fAng = fAng;

end