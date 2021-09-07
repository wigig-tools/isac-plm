function [startOffset,cfrEst,cirEst] = edmgSCTimingAndChannelEstimate(preamble)
%edmgSCTimingAndChannelEstimate DMG single carrier symbol timing and channel estimation
%
%   [STARTOFFSET,CHANEST] = edmgSCTimingAndChannelEstimate(PREAMBLE) returns
%   the symbol timing offset, and the frequency domain channel estimate.
%   The symbol timing offset is selected to minimize the energy of the
%   channel impulse response out with the guard interval. Only the SC PHY
%   is supported.
% 
%   STARTOFFSET is the estimated offset between the first input sample of
%   PREAMBLE, and the start of the STF.
%
%   CHANEST is a complex column vector of length 512 containing the
%   frequency domain channel estimate for each symbol in a block.
%
%   PREAMBLE is a complex column vector containing the DMG-STF, DMG-CE and
%   DMG header field symbols.

%   Copyright 2017 The MathWorks, Inc.

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,1);
nargoutchk(1,3);

NGolay = 128;
[Ga128,Gb128] = wlanGolaySequence(NGolay);
Gu = [-Gb128; -Ga128; Gb128; -Ga128];
Gv = [-Gb128; Ga128; -Gb128; -Ga128];
lengthCEF = 1152; % The length of CE field for DMG SC format
lengthGuGvField = numel(Gu) + numel(Gv);
blkLength = 512;
N_RX = size(preamble,2);
searchWindow = size(Ga128,1);

validateattributes(preamble, {'double'}, {'2d','finite'}, mfilename, 'signal input');

L = (2176 + lengthCEF); % Length of STF and CE field of DMG SC PHY
if size(preamble,1) < L 
    startOffset = [];
    cfrEst = [];
    return;
end

startOffset = zeros(1,N_RX);
cirEst = zeros(searchWindow, N_RX);

% Same processing per rx antenna
for rx_ant = 1: N_RX    
    % Correlate against Gu and GV for channel estimation
    gucor = xcorr(preamble(:,rx_ant), dmgRotate(Gu));
    gvcor = xcorr(preamble(:,rx_ant), dmgRotate(Gv));
    h512 = gucor(1:end-512) + gvcor(1+512:end); % Gv is later so delayed

    % Location of maximum impulse; use this as the basis to search around
    [~,maxImpulseIdx] = max(h512);
    
    % Measure power in search region around the maximum impulse
    seachStartOffset = 63;
    searchRegion = abs(h512(maxImpulseIdx - 1 + (-seachStartOffset + (0:searchWindow-1))).^2);
    
    % Measure the energy in the guard period (64 samples) and find the max
    Ngi = 64;
    cirEnergy = filter(ones(Ngi,1), 1, searchRegion);
    [~, maxCIREnergyIdx] = max(cirEnergy);
    syncIdx = maxCIREnergyIdx;
    
    % Index to start sync in the search region
    startIdxSearchRegion = syncIdx-Ngi+1;
    
    % Offset in samples from max impulse where we actually synchronize
    offsetFromMaxImpulseIdx = startIdxSearchRegion - (seachStartOffset + 1) - 1;
    
    % Determine the start offset of the packet within the waveform
    startOffset(rx_ant) = maxImpulseIdx   - (size(preamble,1) + lengthCEF + lengthGuGvField);
    
    % Extract 128 sample CIR
    cirEst(:,rx_ant) = h512(maxImpulseIdx + offsetFromMaxImpulseIdx-1+(1:searchWindow))/lengthGuGvField;
end

% Convert channel estimate to frequency domain
cfrEst = sum(fftshift(fft([cirEst; zeros(blkLength-length(cirEst),N_RX)], [], 1), 1),2)/sqrt(N_RX);

end

function y = dmgRotate(x)
    y = bsxfun(@times, x, repmat(exp(1i*pi*(0:3).'/2), size(x,1)/4, 1));
end