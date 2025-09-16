function planeEquation = getPlaneCoefficient(point, azimuth, elevation)
%GETPLANECOEFFICIENT Calculates the coefficients of a plane given the perpendicular vector
% defined as a point in the plane and orientation.
%
%   planeEquation = GETPLANECOEFFICIENT(point, azimuth, elevation) calculates the coefficients
%   of a plane equation in the form Ax + By + Cz + D = 0. The plane is defined by a point and 
%   the orientation specified by the azimuth and elevation angles.
%
%   Inputs:
%       point - A 1x3 vector [x0, y0, z0] representing the coordinates of a point on the plane.
%       azimuth - The azimuth angle in degrees, measured from the positive x-axis towards 
%                 the positive y-axis.
%       elevation - The elevation angle in degrees, measured from the xy-plane upwards.
%
%   Outputs:
%       planeEquation - A 1x4 vector [A, B, C, D] representing the coefficients of the plane
%                       equation Ax + By + Cz + D = 0.

%   2024 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.

    % Convert azimuth and elevation from degrees to radians
    azimuthRad = deg2rad(azimuth);
    elevationRad = deg2rad(elevation);

    % Calculate direction cosines of the vector
    l = cos(elevationRad) * cos(azimuthRad);
    m = cos(elevationRad) * sin(azimuthRad);
    n = sin(elevationRad);

    % Extract the coordinates of the point
    x0 = point(1);
    y0 = point(2);
    z0 = point(3);

    % Define the plane equation coefficients
    A = l;
    B = m;
    C = n;
    D = -(l*x0 + m*y0 + n*z0);

    planeEquation = [A B C D];
end
