function [iSet,iRlzn] = getQDTDLChannelRealizationIndex(chanCfg,varargin)
%getNistQDTGayTDLChannelRealizationIndex Get location and realization indecies of NIST QD channel model
%   Inputs
%   chanCfg channel configuration structure for NIST QD channel realization
%   idxLoc is the index of current location duration simulation
%   varargin{1}: idxPkt is the current packet index
%   varargin{2}: maxNumPackets is the maximum number of packets
%   
%   Outputs
%   iLoc is the index of location to be used
%   iRlzn is the index of realization to be used

%   2019~2020 NIST/CTL <jiayi.zhang@nist.gov>

%#codegen

narginchk(1,3);

realizationSetIndexVec = chanCfg.realizationSetIndexVec;
realizationSetIndicator = chanCfg.realizationSetIndicator;
numUseRealizationSets = length(realizationSetIndexVec);
realizationIndexFlag = chanCfg.realizationIndexFlag;
numRealizationSets = chanCfg.numRealizationSets;
numRealizationsPerSet = chanCfg.numRealizationsPerSet;

if nargin > 1
    idxPkt = varargin{1};
    maxNumPackets = varargin{2};
end

assert(chanCfg.realizationSetIndicator>=0,'realizationSetIndicator should be >= 0.');

% Generate CIR packet by packet
if realizationIndexFlag == 0
    % Use fixed iPacket index 2020/03/26
    if realizationSetIndicator == 0
        maxNumPktPerLoc = maxNumPackets/numRealizationSets;
        iSet = ceil(idxPkt/maxNumPktPerLoc);
        if mod(idxPkt,maxNumPktPerLoc) == 0
            iRlzn = idxPkt/maxNumPktPerLoc;
        else
            iRlzn = mod(idxPkt,maxNumPktPerLoc); % packet index
        end
    else
        iSet = realizationSetIndicator;
        numPktUse = min(numRealizationsPerSet,maxNumPackets);
        if mod(idxPkt,numPktUse) == 0
            iRlzn = idxPkt/numPktUse;
        else
            iRlzn = mod(idxPkt,numPktUse); % packet index
        end
    end
elseif realizationIndexFlag == 1
    % Use random iPacket index
    if realizationSetIndicator == 0
        if numUseRealizationSets > 1
            iSet = realizationSetIndexVec(randi(numUseRealizationSets));
        else
            iSet = randi(numRealizationSets);
        end
    else
        iSet = realizationSetIndicator;
    end
    iRlzn = randi(numRealizationsPerSet);
else
    error('realizationIndexFlag should be 0 or 1.');
end


% End