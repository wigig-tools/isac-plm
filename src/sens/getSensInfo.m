function sensInfo = getSensInfo(sensInfo,channelParams,phyParams,simParams,thInfo)
%%GETSENSINFO Sens Info Structure
%   S = GETSENSINFO(S,C,P,SIM,th complete the sensing information structure
%   S with dependend paramaters or parameters defined in other structures
%   such as, channel C, phy P, simulation S or threshold th.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

if isnan(channelParams.targetInfo.range)
    sensInfo.gtRange = nan(1, simParams.nTimeSamp);
else
    sensInfo.gtRange = channelParams.targetInfo.range(:,1:simParams.nTimeSamp);
end

if isnan(channelParams.targetInfo.velocity)
    sensInfo.gtVelocity = nan(1, simParams.nTimeSamp-1);
else
    sensInfo.gtVelocity = channelParams.targetInfo.velocity(:,1:simParams.nTimeSamp-1);
end

if ~isempty(thInfo)
    sensInfo.normCSIVarValue = thInfo.normCSIVarValue;
    sensInfo.threshold = thInfo.threshold;
end
if phyParams.cfgEDMG.MsSensing == 1    
    if isstruct(channelParams.targetInfo.angle)
        switch phyParams.packetType
            case 'TRN-R'
                sensInfo.gtAz = channelParams.targetInfo.angle.aoaAz(2,1,:,1:simParams.nTimeSamp);
                sensInfo.gtEl = channelParams.targetInfo.angle.aoaEl(2,1,:,1:simParams.nTimeSamp);
            case 'TRN-T'
                sensInfo.gtAz = channelParams.targetInfo.angle.aodAz(2,1,:,1:simParams.nTimeSamp);
                sensInfo.gtEl = channelParams.targetInfo.angle.aodEl(2,1,:,1:simParams.nTimeSamp);
        end
    elseif isnan(channelParams.targetInfo.angle)
        sensInfo.gtAz = nan(1, simParams.nTimeSamp);
        sensInfo.gtEl = nan(1, simParams.nTimeSamp);
    end

end