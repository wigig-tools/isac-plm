function rxDpSigSeq = getNoisyRxSignal(txDpSigSeq, tdMimoChan, varargin)
%%GETNOISYRXSIGNAL Receive signal
%
%   Y = GETNOISYRXSIGNAL(X,H,N) returns Y = conv(X,H)+N being X the
%   transmit signalm H the channel and N the noise

%   2019-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

if ~isempty(varargin)
    noise = varargin{1}.varLinActSubc;
else
    noise = 0;
end

fadeDpSigSeq = conv(squeeze(tdMimoChan), txDpSigSeq);
rxDpSigSeq = fadeDpSigSeq+...
    sqrt(noise/2) *(randn(size(fadeDpSigSeq))+1j*randn(size(fadeDpSigSeq)));
end