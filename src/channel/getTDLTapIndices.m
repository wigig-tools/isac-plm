function [tapIdxs, alphaMat] = getTDLTapIndices(fs,tau,tdlType)
%getTDLTapIndices Calculate tap indices for tapped delay line channel model
%   This function calculates tap indices for tapped delay line (TDL) channel model based on either impulse or sinc
%   function.
%
% Inputs:
%   fs is a scalar of sampling frequency
%   tau is delay values vector
%   tdlType is type of TDL, 'Impulse' or 'Sinc'
%   
% Outputs:
%   tapIdxs is TDL index vector
%   alphaMat is TDL combining matrix

%   2019~2021 NIST/CTL Jian Wang

%   This file is available under the terms of the NIST License.

%#codegen

% Get TDL sampling duration
Ts = 1/fs;
if strcmp(tdlType,'Impulse')
    % Normalize path delays.
    tRatioAbolute = floor(tau/Ts);
    % Get relative delay
    tapIdxs = 0 : max(tRatioAbolute) - min(tRatioAbolute);
    tRatioRelative = tRatioAbolute - min(tRatioAbolute);
    % Pre-compute AlphaMatrix.
    alphaMat = repmat(tRatioRelative, size(tapIdxs))-repmat(tapIdxs, size(tRatioRelative));
    alphaMat(alphaMat ~= 0) = -1;
    alphaMat(alphaMat == 0) = 1;
    alphaMat(alphaMat < 0) = 0;
elseif strcmp(tdlType,'Sinc')
    % Normalize path delays.
    tRatioAbolute = tau/Ts;
    tRatioRelative = tRatioAbolute - min(tRatioAbolute);
    % Initial estimate of tapidx range.
    % Minimum value of range is 0.
    err = 0.1;  % Small value.
    c = 1/(pi*err);  % Based on bound sinc(x) < 1/(pi*x).
    % Get relative delay
    tapIdxs = min(floor(min(tRatioRelative) - c), 0) : ceil(max(tRatioRelative) + c);
    % Pre-compute AlphaMatrix
    alphaMat = sinc(repmat(tRatioRelative, size(tapIdxs))-repmat(tapIdxs, size(tRatioRelative)));
end

end

