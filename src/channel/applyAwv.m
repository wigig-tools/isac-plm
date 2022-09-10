function Hbf = applyAwv(H,awvTx, awvRx)
%%APPLYAWV Analog beamforming
%
%   Heq = APPLYAWV(H,F,W) apply Nt transmit Antenna Wave
%   Vectors (AWVs) F and Nr receive AWVs on the digital channel H return
%   the equivalent NtxNr channels.
%
%   H is the RxTxL downlink MIMO full digital channel where R is the number
%   of receive antenna, T is the number of transmit antennas, L is number
%   of delay taps
%   F is the TxNt matrix of tx AWV being T the number of transmit antennas
%   and Nt the number of AWVs
%   W is the RxNr matrix of rx AWV being R the number of transmit antennas
%   and Nr the number of AWVs
%   Heq is the equivalent channel of size LxNtxNr

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

totRxAnt = size(H,1);
totTxAnt = size(H,2);
mpcLen = size(H,3);
txBfComb = size(awvTx,2);
rxBfComb = size(awvRx,2);


H2D  = reshape(permute(H,[1 3 2]), totRxAnt*mpcLen, totTxAnt); % [totRxAnt*mpcLen, totTxAnt]
H2Dtxbf = H2D*conj(awvTx); % [totRxAnt*mpcLen, totTxAnt] x [totTxAnt, txBfComb]
H3Dtxbf = reshape(H2Dtxbf, totRxAnt,mpcLen,txBfComb); % [totRxAnt, mpcLen, txBfComb]

% Rx analog beamforming
H2D  = reshape(H3Dtxbf, totRxAnt, mpcLen*txBfComb).'; % [mpcLen*txBfComb,totRxAnt]
H2Dtxrxbf =H2D*awvRx; % [mpcLen*txBfComb, totRxAnt] x [totRxAnt, rxBfComb] = [mpcLen*txBfComb, rxBfComb]
Hbf = reshape(H2Dtxrxbf,mpcLen,txBfComb,rxBfComb); % [mpcLen, txBfComb, rxBfComb]

end