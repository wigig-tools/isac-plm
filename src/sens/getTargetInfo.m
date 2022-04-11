function out = getTargetInfo(rawTargetInfo, ts, varargin)
%%GETTARGETINFO Target true range and velocity
%
%   GETTARGETINFO(S, TS) return a struct containing true range and velocity
%   given the rawTargetInfo obtained from the QD Channel Realization
%   Software and TS the slowtime rate.
%
%   GETTARGETINFO(S, TS, 'nTx', arg) specifies the number of transmitter
%   in the struct rawTargetInfo

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Vararing processing
p = inputParser;
addParameter(p,'nTx', 1)
parse(p, varargin{:});
nTx  = p.Results.nTx;

%% Vars
nNodes = size(rawTargetInfo,1);
%nRx = nNodes-nTx;
rxId = nTx+1:nNodes;
txId = 1:nTx;

%% Get Delay, Range and Velocity
for nt = 1:nNodes
    for nr = 1:nNodes
        if nt~=nr
            delay(nr,nt,:) = rawTargetInfo{nr,nt}.channelMimo{1}.delay;
            range(nr,nt,:) = getRange(squeeze(delay(nr,nt,:)), 0 , ...
                rawTargetInfo{nr,nt}.channelMimo{1}.delay(1));  % Assumption: 1st tap is LOS
            velocity(nr,nt,:) = getRadialVelocity(range(nr,nt,:), ts);

        end
    end
end

%% Output
out.delay = squeeze(delay(rxId,txId,:));
out.range = squeeze(range(rxId,txId,:));
out.velocity = squeeze(velocity(rxId,txId,:));

end
