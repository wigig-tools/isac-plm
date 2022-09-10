function [outMean, outRaw] = stft(in, varargin)
% STFT Short-time FFT
%   STFT = STFT(IN) returns the short-time FFT of N time domain signals IN.
%   STFT processes each column of IN independently.
%
%   STFT = STFT(IN,WINDOW,WINLEN) returns the short-time FFT of N time domain 
%   signals IN after each column is split into overlapping window segment 
%   of length WINLEN. Each segmemnt is multiplied by the window specified
%   as:
%   * 'rectangle' (default, 64)
%   * 'hamming'
%   * 'blackmanharris'
%   * 'gaussian'
%
%   STFT = STFT(IN,WINDOW,WINLEN,OVERLAP) specifies the percentage of windows
%   overlap specified as a real number in [0,1]. default 0.25.
%
%   STFT = STFT(IN,WINDOW,WINLEN,OVERLAP,NFFT) specifies the FFT length as a 
%   positive integer. This property determines the length of the STFT
%   output (number of rows). default 128
%   The FFT length must be greater than or equal to the window length.
%
%   STFT = STFT(IN,..., 'dim', DIM) applies the fft operation across the
%    dimension DIM. 

%   2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


%% Varargin processing
p = inputParser;

defaultProcess = 2;
validProcess = [1 2];
checkProcess = @(x) any(ismember(x,validProcess));

defaultWindow = 'rect';
validWindow = {'rect','hamming', 'blackmanharris', 'gaussian', 'kaiser'};
checkWindow = @(x) any(validatestring(x,validWindow));
checkOverlap = @(x) (x>=0 & x<=1);

addOptional(p,'window',defaultWindow,checkWindow)
addOptional(p,'windowLen',64,@isnumeric)
addOptional(p,'overlap', 0.5, checkOverlap);
addOptional(p,'nfft', 128, @isnumeric);
addParameter(p,'dim',defaultProcess,checkProcess)
parse(p,varargin{:})

assert(p.Results.windowLen<= p.Results.nfft, 'FFT size must be greater than or equal to the window lenght');


if p.Results.dim == 1
    in = in.';
end

n = size(in,1);
inLen = size(in,2);

assert(p.Results.windowLen<=inLen, 'The length of the segments cannot be greater than the length of the input signal.')

%% Get Window
window = getDftWindow(p.Results.window, p.Results.windowLen);

%% Compute FFT
noverlap = floor(p.Results.windowLen*p.Results.overlap); % Number of sample overlapping
hopLength    = p.Results.windowLen - noverlap;
nBlocks = floor((inLen-p.Results.windowLen)/hopLength)+1;
dataId = reshape(repmat(1:p.Results.windowLen,nBlocks,1)'+...
    hopLength*(0:nBlocks-1),[],1); % index to create overlapping segments
dataBlocks = in(:,dataId); % overlapping segments
dataBlocksWindowed = dataBlocks.*repmat(window, nBlocks,n).'; % Windowing
dataBlocksParallel = reshape(dataBlocksWindowed, n, p.Results.windowLen,[]); % S/P before FFT
dataBlocksFft =  fftshift(fft(dataBlocksParallel, p.Results.nfft, 2),2); % FFT

outRaw = dataBlocksFft;
outMean = mean(abs(dataBlocksFft),3);
if p.Results.dim == 1
    outRaw =permute(outRaw, [2 1 3]);
    outMean = outMean.';
end