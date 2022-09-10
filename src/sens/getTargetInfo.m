function out = getTargetInfo(rawTargetInfo, ts, varargin)
%%GETTARGETINFO Target true range, velocity and angles
%
%   GETTARGETINFO(S, TS) return a struct containing true range and velocity
%   given the rawTargetInfo obtained from the QD Channel Realization
%   Software and TS the slowtime rate.
%
%   GETTARGETINFO(S, TS, 'nTx', arg) specifies the number of transmitter
%   in the struct rawTargetInfo

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

out.delay = nan;
out.range = nan;
out.velocity = nan;
out.angle = nan;
if ~isempty(rawTargetInfo)
    %% Vararing processing
    p = inputParser;
    addParameter(p,'nTx', 1)
    parse(p, varargin{:});
    nTx  = p.Results.nTx;

    %% Vars
    nNodes = size(rawTargetInfo,1);
    nTgt = size(rawTargetInfo{2}.channelMimo,3);
    %nRx = nNodes-nTx;
    rxId = nTx+1:nNodes;
    txId = 1:nTx;

    %% Get Delay, Range and Velocity
    for nt = 1:nNodes
        for nr = 1:nNodes
            if nt~=nr
                for tgId = 1:nTgt
                    delay(nr,nt, tgId, :) = rawTargetInfo{nr,nt}.channelMimo{1,1,tgId}.delay;
                    range(nr,nt,tgId,:) = getRange(squeeze(delay(nr,nt,tgId,:)), 0 , ...
                        rawTargetInfo{nr,nt}.channelMimo{1,1,tgId}.delay(1));  % Assumption: 1st tap is LOS
                    velocity(nr,nt, tgId,:) = getRadialVelocity(range(nr,nt,tgId,:), ts);
                    angle.aoaAz(nr,nt, tgId,:) = rawTargetInfo{nr,nt}.channelMimo{1,1,tgId}.aoaAz;
                    angle.aodAz(nr,nt, tgId, :) = rawTargetInfo{nr,nt}.channelMimo{1,1,tgId}.aodAz;
                    angle.aoaEl(nr,nt, tgId, :) = rawTargetInfo{nr,nt}.channelMimo{1,1, tgId}.aoaEl;
                    angle.aodEl(nr,nt,tgId,:) = rawTargetInfo{nr,nt}.channelMimo{1,1,tgId}.aodEl;
                end
            end
        end
    end

    %% Output
    out.delay = permute(delay(rxId,txId,:,:), [3 4 1 2]);
    out.range = permute(range(rxId,txId,:,:), [3 4 1 2]);
    out.velocity = permute(velocity(rxId,txId,:,:), [3 4 1 2]);
    out.angle = angle;
end

end
