function generateSensingPlots(simParams, results, info, dirOut)
%GENERATESENSINGPLOTS Sensing Accuracy plots
%
% GENERATESENSINGPLOTS(S,R,dir) generate sensing performance plots for
% each SNR and save them in dir, given the simulation structure S and the
% results struct R
%
%   2021~2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)
%
%   This file is available under the terms of the NIST License.

dirOut = fullfile(dirOut, 'figures');
if ~isfolder(dirOut)
    mkdir(dirOut);
else
    rmdir(dirOut, 's');
    mkdir(dirOut);
end


c = getConst('lightSpeed');
nFft = size(results(1).doppler,3);
slowTimeFftAx = info.slowTimeFftGrid;
velocityGrid = info.velocityGrid;
slowTimeAx = info.slowTimeGrid;
gtTargetVel = info.gtVelocity;
gtTargetRange = info.gtRange;
fastTimeRecovered = repmat(info(1).fastTimeGrid,[2,1])-[info.timeShift].';
rangeAx = fastTimeRecovered*c;

%% Range Doppler Map
if simParams.plotRangeDopplerMap
    for iSnr = 1:size(simParams.snrRanges{1},2)
        [X, Y] = meshgrid(rangeAx(iSnr,:),velocityGrid);
        doppler = results(iSnr).doppler;
        figRangeDopplerMap = figure(iSnr);
        hold on
        for i = 1:nFft
            % plot range-doppler map
            pcolor(X, Y, (abs(doppler(:,:,i))));
%             view([0 90])
            shading interp
            xlabel('Range (m)')
            ylabel('Velocity (m/s)')
        end
        title(['SNR = ',num2str(simParams.snrRanges{1}(iSnr)),'dB'])
        savefig(figRangeDopplerMap, ...
            fullfile(dirOut,strcat('rangeDopplerMap_',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));
        close(figRangeDopplerMap)
    end
end

% Micro-Doppler
if simParams.plotVelocity
    [Tax, Vax] = meshgrid(slowTimeFftAx,velocityGrid);
    for iSnr = 1:size(simParams.snrRanges{1},2)
        doppler = results(iSnr).doppler;
        vEst = results(iSnr).vEst';
        figVelocity = figure(iSnr);
        pcolor(Tax, Vax, squeeze(sum(abs(doppler),2)))
        shading interp
        hold on
        len= length(vEst(:));
        plot3(slowTimeAx(1:len),gtTargetVel(1:len),...
            max(max(squeeze(sum(abs(doppler),2)))).*ones(len,1),...
            '-.','Color','r','LineWidth',2)
        plot3(slowTimeAx(1:len),vEst,...
            max(max(squeeze(sum(abs(doppler),2)))).*ones(len,1),...
            '--','Color','k','LineWidth',2)
        legend('','Ground truth','Estimated')
        xlabel('Time(s)')
        ylabel('Velocity (m/s)')
        title(['SNR = ',num2str(simParams.snrRanges{1}(iSnr)),'dB'])
        savefig(figVelocity, ...
            fullfile(dirOut,strcat('microdoppler_',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));
        close(figVelocity)

    end
end

% Range
if simParams.plotRange
    for iSnr = 1:size(simParams.snrRanges{1},2)
        doppler = results(iSnr).doppler;
        rEst = results(iSnr).rEst';
        [Tax, Rax] = meshgrid(slowTimeFftAx,rangeAx(iSnr,:));
        figRange = figure(iSnr);
        pcolor(Tax, Rax, squeeze(sum(abs(doppler),1)))
        shading interp
        hold on
        len= length(rEst(:));
        plot3(slowTimeAx,gtTargetRange(1:len),...
            max(max(squeeze(sum(abs(doppler),1)))).*ones(len,1),...
            '-.','Color','r','LineWidth',2)
        plot3(slowTimeAx,rEst,...
            max(max(squeeze(sum(abs(doppler),1)))).*ones(len,1),...
            '--','Color','k','LineWidth',2)
        legend('','Ground truth','Estimated')
        xlabel('Time (s)')
        ylabel('Range (m)')
        title(['SNR = ',num2str(simParams.snrRanges{1}(iSnr)),'dB'])
        savefig(figRange, ...
            fullfile(dirOut,strcat('rangeTime_',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));
        close(figRange)
    end
end

end