function rx = getPrecodedRxBeacon(tx, H, codebook, noise)
%%GETPRECODEDRXSIGNAL Receive precoded signal
%
%   R = GETPRECODEDRXSIGNAL(T,H,C, PHY) segments the transmit baseband T,
%   precode using the codebook C, transmit over H and add noise.
%
%   [R, TRNBF] = GETPRECODEDRXSIGNAL(...) returns TRN steering angles.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

txSigLen = size(tx,1);
channelLen = size(H{1}, 3);
rxSigLen = channelLen + txSigLen -1 ;

Heq = analogBeamforming(H, codebook(1), 'sweepTx', 'rxbf', 1);
nSector = size(Heq,4);
rx = zeros(rxSigLen, nSector);

for sectorId = 1:nSector
    rx(:,sectorId) = getNoisyRxSignal(tx, Heq(:,:,:,sectorId),noise);
end

end