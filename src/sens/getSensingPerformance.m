function res = getSensingPerformance(rEst, vEst, targetInfo, aEst, packetType)
%%GETSENSINGPERFORMANCE Sensing performance
%
%   GETSENSINGPERFORMANCE(R,V,TG) returns the accuracy of the estimated
%   range R and the estimated velocity V given the target ground truth
%   information TG.
%

%   2022 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.

%% Get ground truth
res = [];
if ~(all(isnan(targetInfo.range(:))) || all(isnan(targetInfo.velocity(:))))
    len= size(rEst,2);
    gtRange = targetInfo.range(1,1:len);
    gtVelocity = targetInfo.velocity(1,1:len-1);

    %% Range Stats
    res.rangeSE = abs(gtRange - rEst).^2;
    res.rangeMSE = mean(res.rangeSE);
    res.rangeSEdB = 10*log10(res.rangeSE);
    res.rangeMSEdB = 10*log10(res.rangeMSE);

    res.rangeNSE = res.rangeSE./(abs(gtRange).^2);
    res.rangeNMSE = mean(res.rangeNSE);
    res.rangeNSEdB = 10*log10(res.rangeNSE);
    res.rangeNMSEdB = 10*log10(res.rangeNMSE);

    %% Velocity Stats
    res.velocitySE = abs(gtVelocity - vEst).^2;
    res.velocityMSE = mean(res.velocitySE);
    res.velocitySEdB = 10*log10(res.velocitySE);
    res.velocityMSEdB = 10*log10(res.velocityMSE);

    res.velocityNSE = res.velocitySE./(abs(gtVelocity).^2);
    res.velocityNMSE = mean(res.velocityNSE);
    res.velocityNSEdB = 10*log10(res.velocityNSE);
    res.velocityNMSEdB = 10*log10(res.velocityNMSE);

    %% Angle Stats
    if ~isempty(aEst)
        switch packetType
            case 'TRN-R'
                gtAngleAz = squeeze(targetInfo.angle.aoaAz(2,1,1,1:len));
                gtAngleEl = squeeze(targetInfo.angle.aoaEl(2,1,1,1:len));
                res.azErr =  aEst(:,1)-gtAngleAz;
                res.elErr =  aEst(:,2)-gtAngleEl;

            case 'TRN-T'
                gtAngleAz = squeeze(targetInfo.angle.aodAz(2,1,1,1:len));
                gtAngleEl = squeeze(targetInfo.angle.aodEl(2,1,1,1:len));
                res.azErr =  aEst(:,1)-gtAngleAz;
                res.elErr =  aEst(:,2)-gtAngleEl;
        end
    end
end
%%
res.rEst = rEst;
res.vEst = vEst;
if ~isempty(aEst)
    res.aEst = aEst;
end
