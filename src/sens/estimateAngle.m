function [angEst,angleGrid,idAng]  =  estimateAngle(discreteMicroDopplerTime,slowTimeGrid,...
    codebook, packetType, varargin)
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

parse(p,varargin{:});
% velocityGrid = velocityGrid(:).';
slowTimeGrid = slowTimeGrid(:).';

switch packetType
    case 'TRN-R'
        angleGrid = codebook(2).steeringAngle;
    case 'TRN-T'
        angleGrid = codebook(1).steeringAngle;
    case 'TRN-TR'
        error('TBD')
end

angleGridId = 1:size(angleGrid,1);
assert(size(discreteMicroDopplerTime,3) == length(slowTimeGrid), 'Input must be the same length')

discreteMicroDopplerTime = discreteMicroDopplerTime(:,:,:, angleGridId);

%% 
[~, A] = meshgrid(slowTimeGrid,angleGridId);
spectrogram = reshape(sum(sum(discreteMicroDopplerTime,1),2), [], size(angleGrid,1)).';

switch p.Results.method
    case 'mean'
        A(spectrogram==0) = 0;
        angEst = sum(A)./(size(A,1)-sum(A==0));
    case 'max'
        [~, mv] = max(spectrogram,[], 1);
        angEst  = angleGrid(mv,:);
    case 'max+filter'
        filterLen = p.Results.filterLen;
        [~, mv] = max(spectrogram,[], 1);
        angEst  = angleGrid(mv,:);
        angEst(:,1) = conv(angEst(:,1), ones(1,filterLen)/filterLen, 'same');
        angEst(:,2) = conv(angEst(:,2), ones(1,filterLen)/filterLen, 'same');
end

idAng = any(spectrogram);
angEst(~idAng,:) = NaN;

angEst = unwrap(angEst/180*pi)/pi*180;
end