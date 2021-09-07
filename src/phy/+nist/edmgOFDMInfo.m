function [const,varargout] = edmgOFDMInfo(cfgEDMG)
%EDMGOFDMINFO Constants for EDMG OFDM PHY
%
%   [CONST,VARARGOUT] = edmgOFDMInfo() returns a structure containing constants and a structure 
%   containing data and pilot indices for EDMG OFDM PHY.

%   Copyright 2016-2018 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

nargoutchk(0,3);
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if ~strcmp(cfgEDMG.PHYType,'OFDM')
    error('This function only supports PHYType = OFDM.');
end

cfgOFDM = nist.edmgOFDMConfig(cfgEDMG);

fc = 60.48e9; % centerFreqHz = % 58.32e9;
NCB = cfgEDMG.NumContiguousChannels;    % Number of contiguous 2.16 GHz channels

% Ref. Draft P802.11ay D7.0 Table 28-62 EDMG OFDM mode timing related parameters
switch NCB
    case 1
        NSD = 336; % Number of data subcarriers
        NSP = 16;  % Number of pilot subcarriers
        NDC = 3;   % Number of DC subcarriers
        NST = 355; % Total number of subcarriers
        NSR = 177; % Highest subcarrier index
        NTONES_EDMG_STF  = [88 192 296 400];    % EDMG-STF Tones
    otherwise
        error('Only EDMG with NCB=1 is supported.');
end

NTONES = cfgOFDM.NumTones; % Number of active subcarriers
NFFT = cfgOFDM.FFTLength;  % FFT length
NGI = cfgOFDM.CPLength;    % Guard interval

G_SEQ_LEN = 128*NCB;
normalizationFactor = NFFT/sqrt(NTONES); % OFDM normalization factor


const = struct();
const.CenterFreqHz = fc;
const.NCB = NCB;    % Add for 11ay
const.NSD = NSD;
const.NSP = NSP;
const.NDC = NDC;
const.NST = NST;
const.NSD = NSD;
const.NSR = NSR;
const.NTONES = NTONES;
const.NFFT = NFFT;
const.NormalizationFactor = normalizationFactor;
const.NGI = NGI;
const.NTONES_EDMG_STF = NTONES_EDMG_STF(NCB);

% If requested, calculate data and pilot indices
if nargout>1
    % Subcarrier indices for data and pilots
    pilotSubcarriers = cfgOFDM.ActiveFrequencyIndices(cfgOFDM.PilotIndices);
    dataSubcarriers = cfgOFDM.ActiveFrequencyIndices(cfgOFDM.DataIndices);

    % Indices for data and pilots with FFT size
    dataIndices = cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices);
    pilotIndices = cfgOFDM.ActiveFFTIndices(cfgOFDM.PilotIndices);

    ind = struct;
    ind.DataSubcarriers = dataSubcarriers;
    ind.PilotSubcarriers = pilotSubcarriers;
    ind.DataIndices = dataIndices;
    ind.PilotIndices = pilotIndices;
    varargout{1} = ind;
    
    if nargout==3
        varargout{2} = cfgOFDM;
    end
end

end