function h = getSmoothingFilter(fltrType, fltrSize,varargin)
%%GETSMOOTHINGFILTER Smooting Filter.
%
%   GETSMOOTHINGFILTER(T,N) returns an N-point type T filter in a column 
%   vector. T can be specified as sinc, gaussian or movingAverage.

%   GETSMOOTHINGFILTER('gaussian',N, STD) specifies the standard deviation
%   of the gaussian window

%   2021 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.

switch fltrType
    case 'sinc'
        
        h = fftshift(fftshift(abs(fft(fft(ones(ceil(fltrSize/2)),fltrSize(1),1),fltrSize(2),2)),1),2)/(fltrSize(1)*fltrSize(2));
    case 'gaussian'
        
        std = varargin{1};
        fltrSize   = (fltrSize-1)/2;

        [x,y] = meshgrid(-fltrSize(2):fltrSize(2),-fltrSize(1):fltrSize(1));
        h     = exp(-(x.^2 + y.^2)/(2*std^2));

        h = h/sum(h(:));
        
    case 'movingAverage'
        h = ones(fltrSize)/prod(fltrSize);

end
    



end