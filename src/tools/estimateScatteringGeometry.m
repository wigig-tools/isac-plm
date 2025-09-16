function [AOD, P] = estimateScatteringGeometry(tx, rx, delay, aoa, varargin)
% ESTIMATESCATTERINGGEOMETRY - Computes the Angle of Departure (AoD) and scattering 
% center position
%
% Syntax:
%   [AOD, P] = ESTIMATESCATTERINGGEOMETRY(tx, rx, delay, aoa, varargin)
%
% Inputs:
%   tx      - [3x1] Transmitter 3D coordinates [x, y, z]
%   rx      - [3x1] Receiver 3D coordinates [x, y, z]
%   delay   - [Nx1] Signal delay in nanoseconds
%   aoa     - [Nx2] Angle of Arrival (AoA) in degrees [azimuth, elevation]
%             The elevation is defined as the angle from the xy plane
%
% Name-Value Pair Arguments:
%   'txHeading' - [1x2] Heading of the transmitter [azimuth, elevation] (default: [0, 0])
%   'rxHeading' - [1x2] Heading of the receiver [azimuth, elevation] (default: [0, 0])
%
% Outputs:
%   AOD - [Nx2] Angle of Departure [azimuth, elevation] in degrees
%         The elevation is defined as the angle from the xy plane
%   P   - [Nx3] Scattering center positions in 3D space [x, y, z]
%
% Example:
%   [AOD, P] = ESTIMATESCATTERINGGEOMETRY([0; 0; 0], [100; 0; 0], delay, aoa, ...
% 'txHeading', [0, 0], 'rxHeading', [0, 0]);

%   2024 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


cspeed = 299792458; % Speed of light in meters per second

%% Input processing
p = inputParser;
addParameter(p, 'txHeading', [0 0]);
addParameter(p, 'rxHeading', [0 0]);
parse(p, varargin{:});

txHeading = p.Results.txHeading;
rxHeading = p.Results.rxHeading;

% Ensure inputs are column vectors
tx = tx(:);
rx = rx(:);
delay = delay(:) / 1e9; % Convert nanoseconds to seconds

% Validate inputs
assert(all(size(tx) == [3 1]), 'Provide 3D coordinates for Tx position');
assert(all(size(rx) == [3 1]), 'Provide 3D coordinates for Rx position');
lenInput = size(delay, 1);

azimuth = aoa(:, 1) / 180 * pi; % Convert AoA azimuth to radians
elevation = aoa(:, 2) / 180 * pi; % Convert AoA elevation to radians

if length(tx) ~= 3 || length(rx) ~= 3
    error('Transmitter and receiver positions must be 3-element vectors.');
end

rayLength = delay*cspeed; %Range in m

isDegenerating = rayLength<norm(abs(tx-rx));

%% Compute the unit vector for AoA direction (u_aoa)
u_aoa = [cos(azimuth) .* cos(elevation), ...
         sin(azimuth) .* cos(elevation), ...
         sin(elevation)].';

%% Compute the vector between RX and TX
d_rx_tx = rx - tx;

%% Compute numerator and denominator for the alpha equation
numerator = (cspeed * delay).^2 - norm(d_rx_tx)^2;
denominator(1, :) = 2 * (d_rx_tx' * u_aoa - cspeed .* delay');
denominator(2, :) = 2 * (d_rx_tx' * (-u_aoa) - cspeed .* delay');

%% Calculate alpha
alpha = numerator' ./ denominator;

%% Calculate the position of the scattering center
P1 = rx + u_aoa .* alpha(1, :); % 1st solution
P2 = rx - u_aoa .* alpha(2, :); % 2nd solution

dod1 = P1 - tx; % Direction of departure for P1
dod2 = P2 - tx; % Direction of departure for P2
P1 = P1';
P2 = P2';

%% Compute AoD
[az1, el1] = vector2angle(dod1');
[az2, el2] = vector2angle(dod2');

%% Find the forward solution
keepP1 = isPointInPositveHalfSpace(P1, getPlaneCoefficient(tx, txHeading(1), txHeading(2))) & ...
         isPointInPositveHalfSpace(P1, getPlaneCoefficient(rx, rxHeading(1), rxHeading(2)));

keepP2 = isPointInPositveHalfSpace(P2, getPlaneCoefficient(tx, txHeading(1), txHeading(2))) & ...
         isPointInPositveHalfSpace(P2, getPlaneCoefficient(rx, rxHeading(1), rxHeading(2)));

keepP1 = keepP1 & ~isDegenerating;
keepP2 = keepP2 & ~isDegenerating;

%% Prepare output
P = nan(lenInput, 3);
P(keepP1, :) = P1(keepP1, :);
P(keepP2, :) = P2(keepP2, :);

AOD = nan(lenInput, 2);
AOD(keepP1, :) = [az1(keepP1, :), el1(keepP1, :)];
AOD(keepP2, :) = [az2(keepP2, :), el2(keepP2, :)];

end
