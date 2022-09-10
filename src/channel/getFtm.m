function ftm = getFtm(channel)
%%GETFTM Fine Time Measurments
%
%   FTM = GETFTM(H) returns the fine time measurement as end-to-end delay
%   between nodes, given the channel cell array H

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

nNode = size(channel,1);
ftm = cell(nNode,nNode);

for i = 1:nNode
    for j = 1:nNode
        if i~=j
            if iscell(channel{i,j}.channelMimo{1}.gain)
                [~,mi] = cellfun(@max, channel{i,j}.channelMimo{1}.gain);
                ftm{i,j} =  cellfun(@(x,y) x(y), channel{i,j}.channelMimo{1}.delay, num2cell(mi));
            else
                [~,mi] = max(channel{i,j}.channelMimo{1}.gain,[],2);
                ftm{i,j} = channel{i,j}.channelMimo{1}.delay(mi);
            end
        end
    end
end