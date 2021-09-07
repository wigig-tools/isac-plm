function [startOffset,chanEst,cirEst] = edmgOFDMTimingAndChannelEstimate(preamble, varargin)
%edmgOFDMTimingAndChannelEstimate EDMG OFDM symbol timing and channel estimation
%
%   [STARTOFFSET,CHANEST] = edmgOFDMTimingAndChannelEstimate(PREAMBLE) returns
%   the symbol timing offset, and the frequency domain channel estimate.
%   The symbol timing offset is selected to minimize the energy of the
%   channel impulse response out with the guard interval. Only the OFDM PHY
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
%
%    [STARTOFFSET,CHANEST] = edmgOFDMTimingAndChannelEstimate(PREAMBLE, 'CIR', h) 
%   can be used for comparing channel estimation with the ideal channel

%   2019~2021 NIST/CTL, Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

%% Input processing
narginchk(1,7);
nargoutchk(1,4);

p = inputParser;
addParameter(p, 'margin', 0)
parse(p, varargin{:});
margin = p.Results.margin;

debug.edmgOFDMTimingAndChannelEstimate.plot = 0;    % 1;
debug.edmgOFDMTimingAndChannelEstimate.display = 0; % 1;

OSF = 1.5;
FFTLength = 512;
blkLength = 512;
seqLength = 128;

%% Do initial operations as the transmitter over Gu and Gv
[Ga128,Gb128] = wlanGolaySequence(seqLength);
N_RX = size(preamble,2);

startOffset = zeros(1,N_RX);
searchWindow = size(Ga128,1)*OSF;

cirEst = zeros(searchWindow, N_RX);

if debug.edmgOFDMTimingAndChannelEstimate.plot
    Ga128c = qamHalfPiRotate(Ga128, 1);    
    Ga128c_2_64 = wlan.internal.dmgResample(Ga128c);
    corrGolay = conv(preamble,conj(Ga128c_2_64(end:-1:1)));
    figure, plot(real(corrGolay(1:end)), 'color', [ 0.0980    0.2235    0.4078])
    xlabel('Sample')
    ylabel('Correlation Ga128')
end


Gu_rotated = dmgRotate([-Gb128; -Ga128; Gb128; -Ga128]);
Gv_rotated = dmgRotate([-Gb128; Ga128; -Gb128; -Ga128]);

Gu = wlan.internal.dmgResample(Gu_rotated); % Resample to 2.64GHz
Gv = wlan.internal.dmgResample(Gv_rotated);

lengthCEField = 1152*OSF; % The length of oversampled CEF field for DMG OFDM format
lengthGuGvField = numel(Gu) + numel(Gv);

validateattributes(preamble, {'double'}, {'2d','finite'}, mfilename, 'signal input');

L = (2176*OSF + lengthCEField); % Length of STF and CEF field of DMG OFDM PHY
if size(preamble,1) < L
    startOffset = [];
    chanEst = [];
    return;
end

%% Channel estimation
% Correlate against Gu and Gv for channel estimation
% Same processing per rx antenna
for rx_ant = 1: N_RX
    gucor = xcorr(preamble(:, rx_ant), Gu);
    gvcor = xcorr(preamble(:, rx_ant), Gv);
    h512 = gvcor(1:end-FFTLength*OSF) + gucor(1+FFTLength*OSF:end); % Gv is later so delayed

    if debug.edmgOFDMTimingAndChannelEstimate.plot == 1
        figure
        plot(real(h512), 'color', [ 0.0980    0.2235    0.4078])
        xlabel('Sample')
        ylabel('Re(R(a)+R(b))')
    end

    % Location of maximum impulse; use this as the basis to search around
    [~,maxImpulseIdx] = max(h512);

    % Measure power in search region around the maximum impulse
    seachStartOffset = searchWindow/2-1;

    searchRegion = abs(h512(maxImpulseIdx - 1 + (-seachStartOffset + (0:searchWindow-1)))).^2;

    % Measure the energy in the guard period (64 samples) and find the max
    Ngi = 64*OSF; 
    cirEnergy = filter(ones(Ngi,1), 1, searchRegion);
    [~, maxCIREnergyIdx] = max(cirEnergy);
    syncIdx = maxCIREnergyIdx-length(getFilterWeights); % 71 Filter length

    % Index to start sync in the search region
    startIdxSearchRegion = syncIdx-Ngi+1;
    % Offset in samples from max impulse where we actually synchronize
    offsetFromMaxImpulseIdx = startIdxSearchRegion - (seachStartOffset + 1) - 1;

    % Determine the start offset of the packet within the waveform
    startOffset(rx_ant) = maxImpulseIdx  - (size(preamble,1) + lengthCEField + lengthGuGvField);

    % Extract 128 sample CIR
    cirEst(:,rx_ant) = h512(maxImpulseIdx-margin + offsetFromMaxImpulseIdx-1+(1:searchWindow))/lengthGuGvField;
end

% Compute overall impulse response of the cascade transmit/receiver
% interpolator
fWeights = getFilterWeights;

h_casc = downsample(filter(fWeights,1,[zeros(blkLength,1);fWeights;zeros([1, 2*blkLength-length(fWeights)]).'])/3,2);

% Align to channel impulse
[~,maxFilterCascade] = max(h_casc);
h_casc = h_casc(maxFilterCascade - searchWindow/2 : maxFilterCascade + searchWindow/2-1);
% Convert filter impulse respone to frequency domain
H_casc =  fftshift(fft([h_casc; zeros(blkLength-length(h_casc),1)], [], 1), 1);

% Convert channel estimate to frequency domain
chanEst = fftshift(fft([cirEst; zeros(blkLength-length(cirEst),N_RX)], [], 1), 1);

chanEst = (chanEst./H_casc).*exp(1j*(2*pi*(-256:255).'*(- offsetFromMaxImpulseIdx-searchWindow/2))/FFTLength);
mappingInd = getActiveFrequencyIndices+(FFTLength/2+1);
chanEst = chanEst(mappingInd,:);
cirEst  = ifft(chanEst,seqLength);
cirEst = cirEst./norm(cirEst,'fro');

end

function y = dmgRotate(x)
    y = bsxfun(@times, x, repmat(exp(1i*pi*(0:3).'/2), size(x,1)/4, 1));
end

function out = getFilterWeights

    % IEEE Std 802.11ad-2012, Section 21.3.6.4.2
    h = [-1, 0, 1, 1, -2, -3, 0, 5, 5, -3, -9, -4, 10, 14, -1, -20, -16, 14, ...
        33, 9, -35, -42, 11, 64, 40, -50, -96, -15, 120, 126, -62, -256, ...
        -148, 360, 985, 1267, 985, 360, -148, -256, -62, 126, 120, -15, -96, ...
        -50, 40, 64, 11, -42, -35, 9, 33, 14, -16, -20, -1, 14, 10, -4, -9, ...
        -3, 5, 5, 0, -3, -2, 1, 1, 0, -1].';

    % Normalized filter weights
    out = (sqrt(3)*h)./sqrt(sum(abs(h).^2));

end

function index = getActiveFrequencyIndices()
    index = transpose(-177:177);
    index(177:179) = [];
end