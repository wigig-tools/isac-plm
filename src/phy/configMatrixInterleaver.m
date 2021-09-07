function [Nx, Ny] = configMatrixInterleaver(phyMode, NCB, NSD, NSS, NBPSC, LCW) 
%configMatrixInterleaver Compute matrix interleaver size for 802.11ay EDMG. It is a symbol interleaver for
% 16-QAM and 64-QAM modulations. the interleaver performs modulated complex symbols interleaving inside an OFDM symbol 
% Inputs
%   NCB the number of bonded channels.
%   NSD is the number of 16-QAM or 64-QAM symbols in a OFDM symbol
%   NSS is the number of spatial streams for a user
%   NBPSC is the number of coded bits per constellation point, depending on the modulation scheme.
%   LCW is the length of the LDCP code word.
% Outputs
%   Nx is the number of raws of matrix dimension
%   Ny is the number of columns of matrix dimension
%   
%   Ref. Draft P802.11ay Draft 7.0

%   2019~2021 by NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if strcmp(phyMode,'OFDM')
    switch NCB
        case 1
            NP = 0;
        case 2
            NP = 34;
        case 3
            NP = 19;
        case 4
            NP = 4;
    end

    x = ((NSD + NP) * NBPSC * NSS) / LCW;
    if x < 2.5*NCB
        Nx = 2*NCB;
    elseif (x < 3.5*NCB) && (x >= 2.5*NCB)
        Nx = 3*NCB;
    elseif (x < 5*NCB) && (x >= 3.5*NCB)
        Nx = 4*NCB;
    elseif (x < 7*NCB) && (x >= 5*NCB)
        Nx = 6*NCB;
    elseif (x < 10*NCB) && (x >= 7*NCB) 
        Nx = 8*NCB;
    elseif (x < 14*NCB) && (x >= 10*NCB)
        Nx = 12*NCB;
    elseif (x < 20*NCB) && (x >= 14*NCB)
        Nx = 16*NCB;
    elseif (x >= 20*NCB)
        Nx = 24*NCB;
    end
    Ny = (NSD + NP)/Nx;
    
elseif strcmp(phyMode,'SC')
    NDSPB = NSD;
    NCBPS = NBPSC;
    x = (NDSPB * NCBPS * NSS) / LCW;
    if x <= 3*NCB
        Nx = 2*NCB;
    elseif (x <= 6*NCB) && (x > 3*NCB)
        Nx = 4*NCB;
    elseif (x <= 12*NCB) && (x > 6*NCB)
        Nx = 8*NCB;
    elseif (x <= 24*NCB) && (x > 12*NCB)
        Nx = 16*NCB;
    elseif (x > 24*NCB)
        Nx = 32*NCB;
    end
    Ny = NDSPB/Nx;
    
else
    error('phyMode should be either OFDM or SC.');
end
