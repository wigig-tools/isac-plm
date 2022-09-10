function [mimoMat, delayMat] = getMultiUserChannel(Hraw, paaInfo, nTimeSample, varargin)
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
% 2020-2022 NIST/CTL (steve.blandino@nist.gov)

%% Varargin processing
p = inputParser;
addParameter(p,'nTx', 1)
addParameter(p,'paa', [1 1]);

parse(p, varargin{:});
nTx  = p.Results.nTx;
paaNodes  = p.Results.paa;


nNodes = size(Hraw,1);
nRx = nNodes-nTx;
rxIdVec = nTx+1:nNodes;
txIdVec = 1:nTx;
H = cell(nRx, nTx);
[H{:}] =  Hraw{nTx+1:end, 1:nTx};

assert(size(H{1}.channelMimo{1}.delay,1)>=nTimeSample, 'simulationConfig:nTimeSamp does not match with qdChannel/qdOutput')

nPaaTx = paaNodes(1:nTx);
nPaaRx = paaNodes(nTx+1:end);

mimoMat = cell(nTimeSample,1);
delayMat = cell(nTimeSample,1);

for t = 1:nTimeSample

    for nodeRx = 1:nRx

        for nodeTx = 1:nTx
            nPaaRx = nPaaRx(nodeRx);
            nPaaTx = nPaaTx(nodeTx);
            rxSv = paaInfo(rxIdVec(nodeRx)).sv_3d;
            txSv = paaInfo(txIdVec(nodeTx)).sv_3d;

            for paaRx = 1:nPaaRx

                for paaTx = 1:nPaaTx
                    %% DDIR to MIMO
                    ddir = H{rxIdVec(nodeRx)-nTx,txIdVec(nodeTx)}.channelMimo{paaRx,paaTx};
                    % Get Tx and Rx phasor/steering vector for each ray
                    if iscell(ddir.aodAz)
                        aoaAz = ddir.aoaAz{t};
                        aoaEl = ddir.aoaEl{t};
                        aodAz = ddir.aodAz{t};
                        aodEl = ddir.aodEl{t};
                    else
                        aoaAz = ddir.aoaAz(t,:).';
                        aoaEl = ddir.aoaEl(t,:).';
                        aodAz = ddir.aodAz(t,:).';
                        aodEl = ddir.aodEl(t,:).';
                    end

                    % MPC complex gain
                    if iscell(ddir.gain)
                        ddirAmplitude = 10.^(ddir.gain{t}/20);
                        ddirPhase  = ddir.phase{t};
                    else
                        ddirAmplitude = 10.^(ddir.gain(t,:)/20);
                        ddirPhase  = ddir.phase(t,:);
                    end

                    complexGain = ddirAmplitude(:).*exp(1j*ddirPhase(:));

                    L = size(complexGain,1);
                    antRxId = 1:paaInfo(rxIdVec(nodeRx)).numElements;
                    antTxId = 1:paaInfo(txIdVec(nodeTx)).numElements;
                    
                    if isempty(txSv)
                        txSteeringVectors = ones(1,L);
                    else
                        txSteeringVectors  = getSteeringVectors(aodAz,aodEl,txSv);
                    end

                    if isempty(rxSv)
                        rxSteeringVectors = ones(1,L);
                    else
                        rxSteeringVectors  = getSteeringVectors(aoaAz,aoaEl,rxSv);
                    end

                    % Apply steering vector to get MIMO matrix
                    for l = 1: L
                        mimoMat{t}{paaRx,paaTx}(antRxId,antTxId,l) = rxSteeringVectors(:,l)*complexGain(l)*txSteeringVectors(:,l)';
                    end
                    if iscell(ddir.delay)
                        delayMat{t}{paaRx,paaTx} = ddir.delay{t};
                    else
                        delayMat{t}{paaRx,paaTx} = ddir.delay(t,:);
                    end
                end
            end
        end
    end

end
end