function sym = edmgOFDMDemodulate(rx,cfgEDMG,varargin)
%edmgOFDMDemodulate OFDM demodulate EDMG fields
%   SYM = edmgOFDMDemodulate(RX) OFDM demodulates the time-domain
%   received signal RX.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a complex matrix of
%   size Ns-by-Nr, where Ns represents the number of time-domain samples.
%   If Ns is not an integer multiple of the OFDM symbol length for the
%   specified field, then mod(Ns,symbol length) trailing samples are
%   ignored.
%
%   SYM = edmgOFDMDemodulate(RX,'OFDMSymbolOffset',SYMOFFSET) specifies
%   the optional OFDM symbol sampling offset as a fraction of the cyclic
%   prefix length between 0 and 1, inclusive. When unspecified, a value of
%   0.75 is used.

%   Copyright 2018-2020 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Validate inputs
validateattributes(rx,{'double'},{'2d','finite'},mfilename,'rx');
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

[numSamples,numRx] = size(rx);
coder.internal.errorIf(numRx==0,'wlan:shared:NotEnoughAntennas');

% Get OFDM info
cfgOFDM = nist.edmgOFDMConfig(cfgEDMG);

% Get OFDM symbol offset
nvp = wlan.internal.demodNVPairParse(varargin{:});
symOffset = nvp.SymOffset;

if numSamples==0
    sym = zeros(cfgOFDM.NumTones,0,numRx); % Return empty for 0 samples
    return;
end

% Validate input length
wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

% Demodulate
sym = wlan.internal.ofdmDemodulate(rx,cfgOFDM,symOffset);

end