function rxDpSigSeq = getNoisyRxSignal(txDpSigSeq, tdMimoChan, noise)
%%GETNOISYRXSIGNAL Receive signal
%
%   Y = GETNOISYRXSIGNAL(X,H,N) returns Y = conv(X,H)+N being X the
%   transmit signalm H the channel and N the noise

%   2019-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

fadeDpSigSeq = conv(squeeze(tdMimoChan), txDpSigSeq);
rxDpSigSeq = fadeDpSigSeq+...
    sqrt(noise.varLinActSubc/2) *(randn(size(fadeDpSigSeq))+1j*randn(size(fadeDpSigSeq)));

end