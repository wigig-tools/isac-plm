function isInRegion = isPointInPositveHalfSpace(point, planeCoefficients)
%ISPOINTINPOSITVEHALFSPACE Determine if a point is in the positive 
% half-space defined by a plane.
%
%   isInRegion = ISPOINTINPOSITVEHALFSPACE(point, planeCoefficients) 
%   returns a logical array indicating whether each row in 'point' is in 
%   the positive half-space defined by the plane with coefficients 
%   'planeCoefficients'.
%
%   Inputs:
%       point - A Nx3 matrix where each row represents the (x, y, z) 
%               coordinates of a point to be tested. N is the number of points.
%       planeCoefficients - A 1x4 vector [A, B, C, D] representing the coefficients 
%                           of the plane equation Ax + By + Cz + D = 0.
%
%   Outputs:
%       isInRegion - A Nx1 logical array where each element indicates whether the corresponding
%                    point is in the positive half-space defined by the plane. True (1) means
%                    the point is in the positive half-space, while False (0) means it is not.
   
%   2024 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

% Extract plane coefficients
    A = planeCoefficients(1);
    B = planeCoefficients(2);
    C = planeCoefficients(3);
    D = planeCoefficients(4);

    % Calculate the value of the plane equation for the given point
    planeValue = A*point(:,1) + B*point(:,2) + C*point(:,3) + D;

    % Determine if the point is in the region delimited by the plane and
    % in the direction of the vector
    % The point is in the region if planeValue is greater than 0, indicating it is on the side of the plane the vector points towards
    isInRegion = planeValue > 0;
end
