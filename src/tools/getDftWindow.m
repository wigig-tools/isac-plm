function w = getDftWindow(T, N, varargin)
%GETDFTWINDOW Data window for Harmonic Analysis with DFT.
%
%   GETDFTWINDOW(T,N) returns an N-point type T window in a column vector.
%
%   GETDFTWINDOW('blackmanharris',N) returns the N-point 4-term (-92 dB) 
%   blackman-harris windows.
%
%   GETDFTWINDOW('gaussian',N, alpha) returns the  N-point gaussian with
%   parameter alpha, being alpha the reciprocal of the standard deviation. 
%   If not specified, alpha = 2.5.
%
%   Windows T and figure of merit:
%   'rect' Side Lobe Level = -13dB/ coherent gain = 1.00/ 3dB bw =
%   0.89/ worst case processing loss 3.92 dB
%   'hamming' Side Lobe Level = -43dB/ coherent gain = 0.54/ 3dB bw =
%   1.3/ worst case processing loss 3.10 dB
%   'gaussian', alpha = 2.5 Side Lobe Level = -42dB/ coherent gain = 1.39/
%   3dB bw = 1.33/ worst case processing loss 3.14 dB
%   'blackmanharris' Side Lobe Level = -92dB/ coherent gain = 0.36/ 3dB bw =
%   1.90/ worst case processing loss 3.56 dB

%   Reference:
%    Fredric j. Harris, On the Use of Windows for Harmonic
%         Analysis with the Discrete Fourier Transform, Proceedings of
%         the IEEE, Vol. 66, No. 1, January 1978

%   2021 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.


switch(T)
    case 'rect'
        w = ones(N,1);

    case 'hamming'
        w = 0.54 + 0.46*cos(2*pi*(linspace(-N/2,N/2,N))/N).';

    case 'blackmanharris'
        n = (0:N-1)'*2*pi/N;
        a0 = 0.35875;
        a1 = 0.48829;
        a2 = 0.14128;
        a3 = 0.01168;
        w = a0 - a1*cos(n)+ a2*cos(2*n) - a3*cos(3*n);

    case 'gaussian'
        if isempty(varargin)
            alpha = 2.5;
        else
            alpha = varargin{1};
        end
        w  = exp(-1/2*((alpha*linspace(-N/2,N/2,N)/(N/2)).^2)).';

end