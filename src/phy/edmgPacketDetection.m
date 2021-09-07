function [pktStartOffset,rx_sync_rate,FS] = edmgPacketDetection(rx_sig,th)
%edmgPacketDetection detects the packet and detects L-STF/ L-CEF sampling 
% rate.
%
%   [pktStartOffset,rx_sync_rate,FS] = nist.edmgPacketDetect(rx_sig, th) returns
%   the offset pktStartOffset from the start of the input waveform to the 
%   start of the detected preamble using auto-correlation and the resampled
%   received symbols at the sampling frequency FS. 
%
%   rx_sig: received signal
%   th : specifies the threshold which the decision statistic must meet or 
%       exceed to detect a packet.
%
%   Copyright 2020 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

golayLen = 128;
maxSTFLen = golayLen*17*3/2; %L-STF oversampled
Nrx = size(rx_sig,2);
Nblock = floor(size(rx_sig,1)/maxSTFLen);
buffer = reshape(rx_sig(1:maxSTFLen*Nblock,:), [], Nblock,Nrx);

[Ga128,~] = wlanGolaySequence(golayLen);
Ga128c = qamHalfPiRotate(Ga128, 1);
Ga128c_2_64 = wlan.internal.dmgResample(Ga128c);

for i = 1:Nblock    
    % Window the received symbols and check if cross correlation is max at
    % 1.76Gs or 2.64Gs.
    corrGolay2_64 = conv(sum(buffer(:,i,:),3),conj(Ga128c_2_64(end:-1:1)));
    corrGolay1_76 = conv(sum(buffer(:,i,:),3),conj(Ga128c(end:-1:1)));
    if  max(abs(corrGolay1_76))>  max(abs(corrGolay2_64))
        rx_sync_rate = rx_sig;
        FS = 1.76e9;
    else
        rx_sync_rate = nist.dmgRxOFDMResample(rx_sig);
        FS = 2.64e9;
    end
    
    %% Packet detection and coarse timing syncronization
    pktStartOffset = nist.edmgPacketDetect(rx_sync_rate, 0, th);
    if ~(isempty(pktStartOffset))
        % Packet detected        
        return;
    end
end

end
    
