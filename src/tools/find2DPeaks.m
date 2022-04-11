function  [peaks, peaksSub, varargout]= find2DPeaks(in, varargin)
%%FIND2DPEAKS Find local peaks in 2D matrix
%
%   PKS = FIND2DPEAKS(X) finds local peaks in the data matrix X. A local
%   peak is defined as a data sample which is larger than the two
%   neighboring samples after applyign a gaussian smooting filtering.
%
%   [PKS,LOCS]= FIND2DPEAKS(X) also returns the indices LOCS at which the
%   peaks occur
%
%   [PKS,LOCS]= FIND2DPEAKS(X, T) finds peaks that are greater than the
%   minimum peak height T.
%
%   [PKS,LOCS]= FIND2DPEAKS(X, T, H, DIM) specifies the filter matrix used
%   to smooth the image as 'gaussian', 'movingAverage', 'sinc'.
%   The filter size DIM is a 2x1 integer vector.
%   [PKS,LOCS]= FIND2DPEAKS(X, T, 'gaussian', DIM, VAR) the gaussian filter
%   adimit as input also the variance of the filter.
%
%   [PKS,LOCS,W]= FIND2DPEAKS(...) returns a binary matrix of same
%   dimensions of X with 1's in the peak positions.

%   2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Varargin processing
p = inputParser;

defaultThres = max(in(:))/10;
defaultFilter = 'gaussian';
defaultVar = 1;
validFilter = {'sinc','gaussian', 'movingAverage'};
checkFilter = @(x) any(validatestring(x,validFilter));
addOptional(p,'tresh',defaultThres,@isnumeric)
addOptional(p,'filt',defaultFilter,checkFilter)
addOptional(p,'filtSize',[7 1],@isnumeric)
addOptional(p,'filtVar',defaultVar,@isnumeric)

parse(p,varargin{:})

%% INIT params
peaksSub=[];
peaks = [];
sizeIn=size(in);
binaryOut=zeros(sizeIn);
filt = getSmoothingFilter(p.Results.filt, p.Results.filtSize, p.Results.filtVar);
thres = p.Results.tresh;
edg = 3;

%% Processing
% Threshold
inTh=in.*(in>thres);

if any(in(:))

    % smooth image
    inTh=conv2(single(inTh),filt,'same') ;

    % Apply again threshold
    inTh=inTh.*(inTh>0.9*thres);

    % Remove edges of the matrix to avoid local maxima in the boundary
    [x, y]= find(inTh(edg:sizeIn(1)-edg,edg:sizeIn(2)-edg));

    % Search peaks in residial elements in x,y
    pSearchSpaceSize = length(y);
    % Vector allocation
    isPeak = false(1, pSearchSpaceSize);

    % Fix index
    x=x+edg-1;
    y=y+edg-1;

    %% For each cell, check if the value is higher than 8 neighbour cells
    for j=1:pSearchSpaceSize
        if (in(x(j),y(j))>in(x(j)-1,y(j)-1 )) &&...
                (in(x(j),y(j))>in(x(j)-1,y(j))) &&...
                (in(x(j),y(j))>in(x(j)-1,y(j)+1)) &&...
                (in(x(j),y(j))>in(x(j),y(j)-1)) && ...
                (in(x(j),y(j))>in(x(j),y(j)+1)) && ...
                (in(x(j),y(j))>in(x(j)+1,y(j)-1)) && ...
                (in(x(j),y(j))>in(x(j)+1,y(j))) && ...
                (in(x(j),y(j))>in(x(j)+1,y(j)+1))

            isPeak(j) = true;
        end
    end
    peaksSub = [x(isPeak),y(isPeak)];
    peaksInd = sub2ind(sizeIn, x(isPeak),y(isPeak));
    peaks = in(peaksInd);
    binaryOut(peaksInd) = 1;
end

varargout{1}=binaryOut;