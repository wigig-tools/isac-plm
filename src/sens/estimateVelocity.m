function [vEst, vId] =  estimateVelocity(discreteMicroDopplerTime,slowTimeGrid,...
    velocityGrid, varargin)
%%ESTIMATEVELOCITY Target estiamated velocity
%
%   V = ESTIMATEVELOCITY(D,TGRID,VGRID) return the velocity of the target 
%   over time (Tx1), given the micro doppler mask over time (FFT x FastTime x T)
%   and the slowtime sampling points (Tx1) and velocity samples (FFTx1)

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Varargin processing
p = inputParser;

defaultMethod = 'max';
validMethod = {'max','mean', 'max+filter'};
checkMethod = @(x) any(validatestring(x,validMethod));
defaultFilterLen = 5;
addOptional(p,'method',defaultMethod,checkMethod)
addOptional(p,'filterLen',defaultFilterLen,@isnumeric)
defaultMaxVelocity = 0;
addOptional(p,'maxVelocity',defaultMaxVelocity,@isnumeric)

parse(p,varargin{:});
velocityGrid = velocityGrid(:).';
slowTimeGrid = slowTimeGrid(:).';
maxVelocity = p.Results.maxVelocity;

assert(size(discreteMicroDopplerTime,1) == length(velocityGrid), 'Input must be the same length')
assert(size(discreteMicroDopplerTime,3) == length(slowTimeGrid), 'Input must be the same length')

%% 
[~, V] = meshgrid(slowTimeGrid,velocityGrid);
spectrogram = squeeze(sum(discreteMicroDopplerTime,2));

switch p.Results.method
    case 'mean'
        V(spectrogram==0) = 0;
        vEst = sum(V)./(size(V,1)-sum(V==0));
    case 'max'
        [~, mv] = max(spectrogram,[], 1);
        vEst  = velocityGrid(mv);
    case 'max+filter'
        filterLen = p.Results.filterLen;
        [~, mv] = max(spectrogram,[], 1);
        vEst  = velocityGrid(mv);
        vEst = conv(vEst, ones(1,filterLen)/filterLen, 'same');
end

        vId = sum(spectrogram) ~= 0;
%% Recover aliasing jumps 
if maxVelocity~= 0 
    normVal = pi/maxVelocity;
    vEst(vId) = unwrap(vEst(vId)*normVal)/normVal;
end

end