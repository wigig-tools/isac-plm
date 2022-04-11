function range = getRange(delay, varargin)
%%GETRANGE Target range
%   GETRANGE = GETRANGE(D) returns the range given the fast time/delay D
%
%  GETRANGE = GETRANGE(D, S, TOF) returns the range given the fast
%  time/delay, the sync point S and the time of flight of the sync point.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


%% Varargin processing
p = inputParser;

defaultSyncPoint = 0;
defaultTof = 0;
checkInteger = @(x)  ~mod(x, round(x));
addOptional(p,'syncPoint',defaultSyncPoint,checkInteger)
addOptional(p,'tof',defaultTof,@isnumeric)
parse(p,varargin{:})

%% Vars
syncPoint= p.Results.syncPoint;
tof = p.Results.tof;
c = getConst('lightSpeed');

%% Get Range
delay = delay-delay(syncPoint+1)+tof;
range = delay*c;

end