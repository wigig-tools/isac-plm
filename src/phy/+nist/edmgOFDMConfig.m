function info = edmgOFDMConfig(cfgEDMG)
%edmgOFDMConfig OFDM information for DMG
%   INFO = wlanDMGOFDMInfo() returns OFDM info for DMG.
%
%   INFO is a structure with the following fields:
%     FFTLength              - The FFT length
%     CPLength               - The cyclic prefix length
%     NumTones               - The number of active subcarriers
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%     DataIndices            - Indices of data within the active 
%                              subcarriers in the range [1, NumTones]
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]
%
%   Ref. Draft P802.11ay D7.0 Table 28-62 EDMG OFDM mode timing related parameters

%   Copyright 2018 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

fftLength = 512 * cfgEDMG.NumContiguousChannels;

switch cfgEDMG.NumContiguousChannels
    case 1
    % Get the indices of data and pilots within active subcarriers
    freqInd = [-177:-2 2:177].';
    pilotIdx = [-150; -130; -110; -90; -70; -50; -30; -10; 10; 30; 50; 70; 90; 110; 130; 150];
    otherwise
        error('Only EDMG with NCB=1 is supported.');
end

idx = ismember(freqInd,pilotIdx);
seqInd = (1:numel(freqInd))';
pilotIndices = seqInd(idx);
dataIndices = seqInd(~idx);

[cpLength,cpDuration] = edmgGIInfo(cfgEDMG);

% Form structure
info = struct;
info.FFTLength = fftLength;
info.CPLength = cpLength;
info.CPDuration = cpDuration;
info.NumTones = numel(freqInd);
info.ActiveFrequencyIndices = freqInd;
info.ActiveFFTIndices = freqInd+fftLength/2+1;
info.DataIndices = dataIndices;
info.PilotIndices = pilotIndices;

end