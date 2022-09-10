function [rx,trnBf] = getPrecodedRxSignal(tx, H, codebook, phy)
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
fieldIndices = nist.edmgFieldIndices(phy.cfgEDMG);
numSta = phy.numUsers;
[searchTx,searchRx] = getNumPrecodingVectors(phy.cfgEDMG);

rx = zeros(rxSigLen, 1+numSta+searchTx*searchRx);

%% DMG Preamble + L-STF
% Get equivalent channel 
persistent HeqPreamble fa wa info 

 if isempty(HeqPreamble)
%      warning('Persistent variable used assuming AWV of PPDU is not changing over time')
     [HeqPreamble,fa, wa, info] = analogBeamforming(H, codebook,'maxAnalogSnr');
 end

% Transmission
indStart = 1;
indEnd = fieldIndices.EDMGSTF(2);
rx(1:indEnd+channelLen-1,1) = getNoisyRxSignal(tx(indStart:indEnd), HeqPreamble(:,:,:,1));

%% EDMG SYNC
for s = 1: numSta
    % Get equivalent channel
    % HeqPreamble = analogBeamforming(H, codebook, 'maxAnalogSnr');
    r = s+1;

    % Transmission
    indStart = fieldIndices.EDMGSYNC(s,1);
    indEnd = fieldIndices.EDMGSYNC(s,2);
    rx(indStart:indEnd+channelLen-1,r) = getNoisyRxSignal(tx(indStart:indEnd), HeqPreamble(:,:,:,1));
end

%% EDMG TRN
% Get equivalent channel
if all([codebook.numElements]==1)
    Heq = analogBeamforming(H, [],'noBeamforming');
    trnBf = [0 0];
else
    switch phy.cfgEDMG.PacketType
        case 'TRN-R'
            Heq = analogBeamforming(H, codebook(2), 'sweepRx', 'txbf', fa);
            trnBf = [repmat(info.fAng, size(codebook(2).steeringAngle,1), 1), codebook(2).steeringAngle];
        case 'TRN-T'
            Heq = analogBeamforming(H, codebook(1), 'sweepTx', 'rxbf', wa);
            trnBf = [codebook(1).steeringAngle, repmat(info.wAng, size(codebook(1).steeringAngle,1), 1)];
        otherwise
    end
end

% Transmission
switch phy.cfgEDMG.PacketType
    case  'TRN-R'
        trnPrecNum = min(size(fieldIndices.TRNSubfields,1),size(Heq,5));
        for trnId = 1: trnPrecNum
            r = trnId+numSta+2;
            c1 =fieldIndices.TRNSubfields(trnId,1) ;
            c2= fieldIndices.TRNSubfields(trnId,2);
            rx(c1:c2+channelLen-1,r) = getNoisyRxSignal(tx(c1:c2), Heq(:,:,:,:,trnId));
        end
    case 'TRN-T'
        % TRN-T
        trnPrecNum = min(size(fieldIndices.TRNSubfields,1),size(Heq,4));
        for trnId = 1: trnPrecNum
            r = trnId+numSta+2;
            % UNIT - M 
            c1 =fieldIndices.TRNSubfields(trnId,1) ;
            c2= fieldIndices.TRNSubfields(trnId,2);
            rx(c1:c2+channelLen-1,r) = getNoisyRxSignal(tx(c1:c2), Heq(:,:,:,ceil(trnId/phy.unitN),:));
        end

        % UNIT-P
        for trnId = 1:sum(fieldIndices.TRNUnitP(:,1)<c2)
            c1 =fieldIndices.TRNUnitP(trnId,1) ;
            c2= fieldIndices.TRNUnitP(trnId,2);
            rx(c1:c2+channelLen-1,r) = getNoisyRxSignal(tx(c1:c2), HeqPreamble(:,:,:,1));
            r = r+1;
        end
        r = r-1;
    otherwise
        % TRN-TR
        error('Case not managed yet')
end

rx = sum(rx(1:fieldIndices.TRNSubfields(trnPrecNum,2)+channelLen-1,1:r),2);

end