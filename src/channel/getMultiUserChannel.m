function [Hmat, Delaymat] = getMultiUserChannel(Hraw, paaInfo, nTimeSample, varargin)
%%GETMULTIUSERCHANNEL converts the raw channel obtained from the NIST QD
%channel model, converting it into the downlink channel struct array
%of dimension nTimeSample x 1, where nTimeSample corresponds to the lenght
% of the simulation. Each entry is the MU-MIMO cell matrix of dimension 
% (nRx x nRxPaa) x (nTx x nTxPaa). The entry of each cell is the nAntRx x
% nAntTx matrix.
%
% [H, D] = GETMULTIUSERCHANNEL(Hraw, paaInfo, nTimeSample) returns the
% MU-MIMO channel H and the delay D.
% H can be accessed as:  H{t}{paaRxId,paaTxId}(rxAnt,txAnt, l)
% D can be accessed as:  D{t}{paaRxId,paaTxId}(l)
%
% [H, D] = GETMULTIUSERCHANNEL(Hraw, ..., 'nTx', value) specify the number of TX
% in the scenario. Default value is 1.  Assumption: paaInfo(1:nTx) are 
% relative to the tx.
%

% NIST-developed software is provided by NIST as a public service. You may
% use, copy and distribute copies of the software in any medium, provided
% that you keep intact this entire notice. You may improve,modify and
% create derivative works of the software or any portion of the software,
% and you may copy and distribute such modifications or works. Modified
% works should carry a notice stating that you changed the software and
% should note the date and nature of any such change. Please explicitly
% acknowledge the National Institute of Standards and Technology as the
% source of the software. NIST-developed software is expressly provided
% "AS IS." NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR
% ARISING BY OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
% WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
% NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS
% THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE,
% OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY
% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS THEREOF,
% INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY, RELIABILITY,
% OR USEFULNESS OF THE SOFTWARE.
%
% You are solely responsible for determining the appropriateness of using
% and distributing the software and you assume all risks associated with
% its use,including but not limited to the risks and costs of program
% errors, compliance with applicable laws, damage to or loss of data,
% programs or equipment, and the unavailability or interruption of
% operation. This software is not intended to be used in any situation
% where a failure could cause risk of injury or damage to property.
% The software developed by NIST employees is not subject to copyright
% protection within the United States.
%
% 2020 NIST/CTL (steve.blandino@nist.gov)

%% Varargin processing
p = inputParser;
addParameter(p,'nTx', 1)
parse(p, varargin{:});
nTx  = p.Results.nTx;

nNodes = size(Hraw,1);
nRx = nNodes-nTx;
rxId = nTx+1:nNodes;
txId = 1:nTx;
H = cell(nRx, nTx);
[H{:}] =  Hraw{nTx+1:end, 1:nTx};
paaT = [paaInfo(1:nTx).NumPaa];
paaR = [paaInfo(nTx+1:end).NumPaa];
Hmat = cell(nTimeSample,1);
for t = 1:nTimeSample
    sumIdPaaRx = 0;
    for nodeRx = rxId
        sumIdPaaTx = 0;
        
        for nodeTx = txId
            paaRxId = sumIdPaaRx+1;
            
            rxPaaInfo = paaInfo(nodeRx);
            txPaaInfo = paaInfo(nodeTx);
            nPaaRx = rxPaaInfo.NumPaa;
            nPaaTx = txPaaInfo.NumPaa;
            for paaRx = 1:nPaaRx
                paaTxId = sumIdPaaTx+1;
                
                for paaTx = 1:nPaaTx
                    ddir = H{nodeRx-nTx,nodeTx}.channelMimo{paaRx,paaTx};
                    % Get Tx and Rx phasor/steering vector for each ray
                    txSteeringVectors  = getSteeringVectors(typeCast(ddir.aodAz(t,:)),typeCast(ddir.aoaEl(t,:)),txPaaInfo.codebook.sv_3d);
                    rxSteeringVectors  = getSteeringVectors(typeCast(ddir.aoaAz(t,:)),typeCast(ddir.aoaEl(t,:)),rxPaaInfo.codebook.sv_3d);
                    ddirAmplitude = 10.^(typeCast(ddir.gain(t,:))/20);
                    ddirPhase  = typeCast(ddir.phase(t,:));
                    complexGain = ddirAmplitude.*exp(1j*ddirPhase);
                    L = size(ddirAmplitude,1);
                    antRxId = 1:rxPaaInfo.NumAntenna;
                    antTxId = 1:txPaaInfo.NumAntenna;
                    
                    for l = 1: L
                        Hmat{t}{paaRxId,paaTxId}(antRxId,antTxId,l) = squeeze(rxSteeringVectors(l,:))*complexGain(l)*squeeze(txSteeringVectors(l,:))';
                    end
                    Delaymat{t,1}{paaRxId,paaTxId} = ddir.delay(t,:);
                    paaTxId= paaTxId+1;
                end
                paaRxId = paaRxId+1;
                
            end
            sumIdPaaTx = sum(paaT(1:nodeTx));
            
        end
        sumIdPaaRx = sum(paaR(1:(nodeRx-nTx)));
        
    end
    
end
end

function x = typeCast(x)
if iscell(x)
    x = cell2mat(x);
end
x = x(:);
end