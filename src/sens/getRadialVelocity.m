function vTrue = getRadialVelocity(range,ts)
%%GETRADIALVELOCITY Target radial veloity
%   GETRADIALVELOCITY = GETRADIALVELOCITY(D,ts) returns the radial velocity
%   given the range over time and the slow time sampling
%   rate

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


dR = range(2:end)-range(1:end-1);
vTrue = squeeze(dR/(2*ts));
end