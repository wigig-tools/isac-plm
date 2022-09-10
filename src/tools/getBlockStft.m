function [nBlocks,hopLength]  =   getBlockStft(inLen, windowLen, overlap)
% GETBLOCKSTFT Number of STFT blocks 
%   [NB,HL] = GETBLOCKSTFT(IN, WINLEN, OL) returns the number NB of STFT blocks
%	in which the data are segmented and the hop length given the input data 
%	length IN, the window length WINLEN and the overlap between blocks defined 
%	as a value in [0-1] being 0 no overlap and 1 full overlap.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

noverlap = floor(windowLen*overlap); % Number of sample overlapping
hopLength    = windowLen - noverlap;
nBlocks = floor((inLen-windowLen)/hopLength)+1;