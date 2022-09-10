function generateSensingPlots(simParams, results, info, dirOut)
%GENERATESENSINGPLOTS Sensing Plot
%
% GENERATESENSINGPLOTS(S,R,INFO,dir) generate sensing performance plots for
% each SNR and save them in dir, given the simulation structure S, the
% results struct R and the sensing information struct INFO.
%
% To enable the plot, sensPlot = 1 in simulationConf.
% Plot saved:
%   - Overview of range doppler maps defined as subplots per each coherent
%   processing interaval
%   - Velocity vs Slow Time
%   - Range vs Slow Time
%   If ground truth is provided
%   - Histogram of velocity estimation accuracy
%   - Histogram of range estimation accuracy
%
%   When using directional mode:
%   - Overview of azimuth-elevation maps  defined as subplots per each
%   coherent processing interaval
%   - Azimuth vs Slow Time
%   - Elevation vs Slow Time
%   If ground truth is provided
%   - Histogram of azimuth estimation accuracy
%   - Histogram of elevation estimation accuracy
%
%%  When setting the saveRdaMap = 1 jpeg files of the following plot are saved:
%   - Velocity vs Slow Time
%   - Azimuth vs Slow Time
%   - Elevation vs Slow Time
%
%
% The jpeg can be saved without axis description specifying disableRdaAxis
% =1
%

%   2021~2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)
%
%   This file is available under the terms of the NIST License.

isPlot = simParams.sensPlot;
disableRdaAxis = simParams.disableRdaAxis;

if isPlot
    dirOut = fullfile(dirOut, 'figures');
    if ~isfolder(dirOut)
        mkdir(dirOut);
    else
        rmdir(dirOut, 's');
        mkdir(dirOut);
    end

    if simParams.saveRdaMap
        rdaDir = fullfile(dirOut, 'rda');
        mkdir(rdaDir);
    end

    c = getConst('lightSpeed');
    fftLen = size(results(1).rda,1);
    rangeLen = size(results(1).rda,2);
    nCpi = size(results(1).rda,3);
    nAngle = size(results(1).rda,4);
    slowTimeFftAx = info.axDopFftTime;
    velocityGrid = info.axVelocity;
    slowTimeAx = info.axPri;
    gtTargetVel = info.gtVelocity;
    gtTargetRange = info.gtRange;
    if all(isnan(gtTargetVel))
        legendGt = '';
    else
        legendGt = 'Ground Truth';
    end
    fastTimeRecovered = info(1).axFastTime-[info.timeOffset].';
    rangeAx = fastTimeRecovered*c;
    snrLen = size(simParams.snrRanges{1},2);
    rd = zeros(size(velocityGrid,2),size(fastTimeRecovered,2),nCpi,snrLen);

    for iSnr = 1:snrLen
        rd(:,:,:,iSnr) = sum(results(iSnr).rda,4);
    end

    %% Range Doppler Map
    figure
    for iSnr = 1:snrLen
        [X, Y] = meshgrid(rangeAx(iSnr,:),velocityGrid);
        rowPlot = floor(sqrt(nCpi));
        columnPlot =  ceil(nCpi/rowPlot);
        for i = 1:nCpi
            % plot range-doppler map
            subplot(rowPlot,columnPlot,i)
            dopplerPlot = rd(:,:,i,iSnr);
            pcolor(X, Y, (abs(dopplerPlot)));
            shading interp
            if i == (columnPlot*(rowPlot-1)+1)
                xlabel('Range (m)')
                ylabel('Velocity (m/s)')
            end
            zlim([0,  max(eps,max(dopplerPlot(:)))])
            title(sprintf('%d', i))
        end
        savefig(gcf, ...
            fullfile(dirOut,sprintf('rangeDopplerMap_%ddB.fig', simParams.snrRanges{1}(iSnr))));
    end
    close(gcf)

    if simParams.saveRdaMap
        figure
        for iSnr = 1:snrLen
            [X, Y] = meshgrid(rangeAx(iSnr,:),velocityGrid);
            for i = 1:nCpi
                dopplerPlot = rd(:,:,i,iSnr);
                pcolor(X, Y, (abs(dopplerPlot)));
                shading flat
                xlabel('Range (m)')
                ylabel('Velocity (m/s)')
                colormap('hot')
                if disableRdaAxis, axis off, end
                saveas(gcf, ...
                    fullfile(rdaDir,sprintf('rd%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
            end
        end
        close(gcf)
    end

    % Micro-Doppler
    if nCpi>1
        [Tax, Vax] = meshgrid(slowTimeFftAx,velocityGrid);
        figure
        for iSnr = 1:snrLen
            vEst = results(iSnr).vEst';
            pcolor(Tax, Vax, squeeze(sum(abs(rd(:,:,:,iSnr)),2)))
            shading interp
            hold on
            len= length(vEst(:));
            % GT
            plot(slowTimeAx(1:len),gtTargetVel(1:len),...
                '-.','Color','r','LineWidth',2);
            % Estimation
            plot(slowTimeAx(1:len),vEst,...
                '--','Color','k','LineWidth',2)
            hold off
            legend('',legendGt,'Estimated')
            xlabel('Time(s)')
            ylabel('Velocity (m/s)')
            savefig(gcf, ...
                fullfile(dirOut,strcat('microdoppler_',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));

            % Error histogram
            if isfield(results, 'velocitySE')
                histogram(results.velocitySE, 'normalization', 'probability')
                xlabel('Accuracy velocity (m/s)')
                ylabel('Probabiltiy')
                grid on
                savefig(gcf, ...
                    fullfile(dirOut,sprintf('errVelocity_%ddB.fig', simParams.snrRanges{1}(iSnr))));
                ylim([0 1])
            end
        end
        close(gcf)
    end

    % Range
    if nCpi>1
        figure
        for iSnr = 1:snrLen
            rEst = results(iSnr).rEst';
            [Tax, Rax] = meshgrid(slowTimeFftAx,rangeAx(iSnr,:));
            pcolor(Tax, Rax, squeeze(sum(abs(rd(:,:,:,iSnr)),1)))
            shading interp
            hold on
            len= length(rEst(:));
            plot(slowTimeAx,gtTargetRange(1:len),...
                '-.','Color','r','LineWidth',2)
            plot(slowTimeAx,rEst,...
                '--','Color','k','LineWidth',2)
            hold off
            legend('',legendGt,'Estimated')
            xlabel('Time (s)')
            ylabel('Range (m)')
            savefig(gcf, ...
                fullfile(dirOut,strcat('rangeTime_',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));

            if isfield(results, 'rangeSE')
                histogram(results(iSnr).rangeSE, 'normalization', 'probability')
                xlabel('Accuracy range(m)')
                ylabel('Probabiltiy')
                grid on
                savefig(gcf, ...
                    fullfile(dirOut,sprintf('errRange_%ddB.fig', simParams.snrRanges{1}(iSnr))));
                ylim([0 1])
            end
        end
        close(gcf)
    end

    % Angle
    if nCpi>1 && nAngle>1
        azAx =  unique(info.axAngle(:,1), 'stable');
        elAx =  unique(info.axAngle(:,2), 'stable');
        azAxLen = length(azAx);
        elAxLen = length(elAx);

        figure
        for iSnr = 1:snrLen
            az = results(iSnr).aEst(:,1);
            el = results(iSnr).aEst(:,2);

            dopplerPlot = squeeze(sum(sum(results(iSnr).rda,1),2)).';
            dopplerPlot = dopplerPlot(1:nAngle, :);
            dopplerReshape = reshape(dopplerPlot, azAxLen, elAxLen,[]);

            rowPlot = floor(sqrt(nCpi));
            columnPlot =  ceil(nCpi/rowPlot);

            for i = 1:nCpi
                % plot range-doppler map
                subplot(rowPlot,columnPlot,i)
                pcolor(wrapTo180(fftshift(reshape(info.axAngle(:,1),azAxLen,elAxLen),1)),reshape(info.axAngle(:,2),azAxLen,elAxLen),fftshift(dopplerReshape(:,:,i),1))
                shading interp
                if i == (columnPlot*(rowPlot-1)+1)
                    xlabel('Azimuth (deg)'), ylabel('Elevation (deg)')
                end
                title(i)
            end

            savefig(gcf, ...
                fullfile(dirOut,sprintf('azElMap_%ddB.fig', simParams.snrRanges{1}(iSnr))));
            close(gcf)

            figure
            % Azimuth vs Time
            azAxZeroCenter = wrapTo180(fftshift(azAx));
            [X,Y] = meshgrid(slowTimeFftAx,azAxZeroCenter);
            azTimePlot = fftshift(permute(sum(dopplerReshape,2), [1 3 2]),1);
            pcolor(X,Y, azTimePlot)
            shading interp
            hold on
            plot(slowTimeAx, wrapTo180(squeeze(info.gtAz)), 'LineWidth',2, 'Color','r');
            plot(slowTimeAx, wrapTo180(az), '--','LineWidth',2, 'Color','k');
            hold off
            legend('', legendGt, 'Estimation')
            xlabel('Time (s)')
            ylabel('Azimuth (deg)')
            savefig(gcf, ...
                fullfile(dirOut,sprintf('azEst_%ddB.fig', simParams.snrRanges{1}(iSnr))));

            % Elevation vs time
            [X,Y] = meshgrid(slowTimeFftAx,elAx);
            elTimePlot = permute(sum(dopplerReshape,1), [2 3 1]);
            pcolor(X,Y, elTimePlot)
            shading interp
            hold on
            plot(slowTimeAx, squeeze(info.gtEl), 'LineWidth',2, 'Color','r');
            plot(slowTimeAx, el, '--','LineWidth',2, 'Color','k');
            hold off
            legend('',legendGt, 'Estimation')

            xlabel('Time (s)')
            ylabel('Elevation (deg)')

            savefig(gcf, ...
                fullfile(dirOut,sprintf('elEst_%ddB.fig', simParams.snrRanges{1}(iSnr))));
            close(gcf)

            % Hist Error
            if isfield(results, 'azErr')


 histogram((abs(results.azErr)) ...
                    , 'normalization', 'probability')

                xlabel('Accuracy azimuth (deg)')
                ylabel('Probabiltiy')
                grid on
                axis([0 20 0 1])
                savefig(gcf, ...
                    fullfile(dirOut,sprintf('errAz_%ddB.fig', simParams.snrRanges{1}(iSnr))));
            end

            if isfield(results, 'elErr')
                histogram(abs(results.elErr) ...
                    , 'normalization', 'probability', 'BinWidth',1)
                xlabel('Accuracy elevation (deg)')
                ylabel('Probabiltiy')
                grid on
                axis([0 20 0 1])
                savefig(gcf, ...
                    fullfile(dirOut,sprintf('errEl_%ddB.fig', simParams.snrRanges{1}(iSnr))));
            end
            close(gcf)
            %% RDA Map
            if simParams.saveRdaMap
                figure
                dopplerAngleEstimateResh = reshape(results(iSnr).rda, fftLen, rangeLen, nCpi, azAxLen, elAxLen);
                dopplerAngleEstimateAz = squeeze(sum(dopplerAngleEstimateResh,5));
                dopplerAngleEstimateEl = squeeze(sum(dopplerAngleEstimateResh,4));
                azAx = wrapTo180(fftshift(azAx));
                % Range - Azimuth
                rangeAzimuth = permute(sum(dopplerAngleEstimateAz,1), [4 2 3 1]);
                for i = 1:nCpi
                    pcolor(rangeAx, azAx, rangeAzimuth(:,:,i))
                    shading flat
                    colormap('hot')
                    ylabel('Azimuth (deg)')
                    xlabel('Range (m)')
                    saveas(gcf, ...
                        fullfile(rdaDir,sprintf('ra%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
                end

                % Range - Elevation
                elvationRange = permute(sum(dopplerAngleEstimateEl,1), [4 2 3 1]);
                for i = 1:nCpi
                    pcolor( rangeAx, elAx, elvationRange(:,:,i))
                    shading flat
                    colormap('hot')
                    xlabel('Range (m)')
                    ylabel('Elevation (deg)')
                    if disableRdaAxis, axis off, end
                    saveas(gcf, ...
                        fullfile(rdaDir,sprintf('re%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
                end

                % Velocity - Azimuth
                azimuthVelocity = permute(sum(dopplerAngleEstimateAz,2), [4 1 3 2]);

                for i = 1:nCpi
                    pcolor( velocityGrid, azAx, fftshift(azimuthVelocity(:,:,i),1))
                    shading flat
                    colormap('hot')
                    ylabel('Azimuth (deg)')
                    xlabel('Velocity (m/s)')
                    if disableRdaAxis, axis off, end
                    saveas(gcf, ...
                        fullfile(rdaDir,sprintf('va%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
                end

                % Velocity - Elevation
                elevationVelocity = permute(sum(dopplerAngleEstimateEl,2), [4 1 3 2]);

                for i = 1:nCpi
                    pcolor( velocityGrid, elAx, elevationVelocity(:,:,i))
                    shading flat
                    colormap('hot')
                    ylabel('Elevation (deg)')
                    xlabel('Velocity (m/s)')
                    if disableRdaAxis, axis off, end
                    saveas(gcf, ...
                        fullfile(rdaDir,sprintf('ve%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
                end


                % Azimuth - Elevation
                elevationAzimuth = permute(sum(sum(dopplerAngleEstimateResh,1),2), [4 5 3 1 2]);
                for i = 1:nCpi
                    pcolor(azAx,elAx,fftshift(elevationAzimuth(:,:,i).',2))
                    shading flat
                    colormap('hot')
                    xlabel('Azimuth (deg)')
                    ylabel('Elevation (deg)')
                    if disableRdaAxis, axis off, end
                    saveas(gcf, ...
                        fullfile(rdaDir,sprintf('ae%d_%ddB', i,simParams.snrRanges{1}(iSnr))), 'jpeg');
                end

                close(gcf)
            end
        end
    end

    %% Threshold bases sensing measurement and reporting
    if isfield(info, 'normCSIVarValue')
        for iSnr = 1:size(simParams.snrRanges{1},2)
            normCSIVarValue = info(iSnr).normCSIVarValue;
            figThresholdSens = figure(iSnr);
            plot(slowTimeAx,normCSIVarValue)
            hold on
            plot(slowTimeAx,info(iSnr).threshold,'-.');
            grid on
            legend('CSI variation','Threshold Level')
            xlabel('time-index')
            ylabel('Normalized CSI Variation [0,1]')
            title(['SNR = ',num2str(simParams.snrRanges{1}(iSnr)),'dB'])
            savefig(figThresholdSens, fullfile(dirOut,strcat('NormCSIVarVsTime-',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));
            close(figThresholdSens)
            if ~info(1).adaptiveThreshold
                thresholdRange = 0:0.001:1;
                numMeasurements = zeros(1,length(thresholdRange));
                for iThreshold = 1:length(thresholdRange)
                    ind = normCSIVarValue(:)>=thresholdRange(iThreshold);
                    numMeasurements(iThreshold) = sum(ind);
                end
                figThresholdSens = figure(iSnr);
                plot(thresholdRange,numMeasurements,'-*')
                hold on
                xline(info(iSnr).threshold,'--r')
                xlabel('Threshold')
                ylabel('Number of Measurements need to be feedback')
                grid on
                title(['SNR = ',num2str(simParams.snrRanges{1}(iSnr)),'dB'])
                savefig(figThresholdSens, fullfile(dirOut,strcat('NumMeasVsThreshold-',num2str(simParams.snrRanges{1}(iSnr)),'dB.fig')));
                close(figThresholdSens)
            end
        end
    end
end
end
