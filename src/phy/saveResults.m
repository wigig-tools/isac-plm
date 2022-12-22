function saveResults(simParams, phyParams, channelParams, cfgSim, results)
%saveResults This file should be included in main file in order to plot and save bit error rate (BER)
%   and packet error rate (PER) results.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

fprintf('--- Save %s Results ---\n- Folder Path:\t%s\n',simParams.metricStr, simParams.resultPathStr);
fprintf(simParams.fileID,'## --- Save %s Result ---\r\n## Folder Path:\t%s\r\n',simParams.metricStr, simParams.resultPathStr);

if strcmp(simParams.metricStr,'ER')
    if simParams.chanFlag == 3
        numSTSMax = max(channelParams.nistChan.graphTxRxOriginal);
        % Plot Bit Error Rate vs SNR Results
        figDataBERvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'BER', numSTSMax, channelParams.realizationSetIndicator);
        % Plot Packet Error Rate vs SNR Results
        figDataPERvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'PER', numSTSMax, channelParams.realizationSetIndicator);
        % Plot Data Rate vs SNR Results
        figDataDRvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'DR', numSTSMax, channelParams.realizationSetIndicator);
    else
        numSTSMax = max(phyParams.numSTSVec);
        % Plot Bit Error Rate vs SNR Results
        figDataBERvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'BER', numSTSMax);
        % Plot Packet Error Rate vs SNR Results
        figDataPERvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'PER', numSTSMax);
        % Plot Data Rate vs SNR Results
        figDataDRvsSNR = plotErrorRateResults(simParams, phyParams, channelParams, results,'DR', numSTSMax);
    end

    %% Save Data
    savefig(figDataBERvsSNR, fullfile(simParams.resultPathStr, simParams.figNameStrBER));
    savefig(figDataPERvsSNR, fullfile(simParams.resultPathStr, simParams.figNameStrPER));
    savefig(figDataDRvsSNR, fullfile(simParams.resultPathStr, simParams.figNameStrDR));

    clear figDataBERvsSNR figDataPERvsSNR figDataDRvsSNR

    fprintf('- Save BER vs SNR Fig File:\t%s\n',simParams.figNameStrBER);
    fprintf('- Save PER vs SNR Fig File:\t%s\n',simParams.figNameStrPER);
    fprintf('- Save DR vs SNR Fig File:\t%s\n',simParams.figNameStrDR);
    fprintf(simParams.fileID,'## Save BER vs SNR Fig File:\t%s\r\n',simParams.figNameStrBER);
    fprintf(simParams.fileID,'## Save PER vs SNR Fig File:\t%s\r\n',simParams.figNameStrPER);
    fprintf(simParams.fileID,'## Save DR vs SNR Fig File:\t%s\r\n',simParams.figNameStrDR);

elseif strcmp(simParams.metricStr,'SE')
    if simParams.chanFlag == 3
        numSTSMax = max(channelParams.nistChan.graphTxRxOriginal);
        % Plot Bit Error Rate vs SNR Results
        figDataSEvsSNR = plotSpectralEfficiencyResults(simParams, phyParams, channelParams, results, 'SE', numSTSMax, channelParams.realizationSetIndicator);
    else
        numSTSMax = max(phyParams.numSTSVec);
        % Plot Bit Error Rate vs SNR Results
        figDataSEvsSNR = plotSpectralEfficiencyResults(simParams, phyParams, channelParams, results, 'SE', numSTSMax);
    end

    %% Save Data
    savefig(figDataSEvsSNR, fullfile(simParams.resultPathStr, simParams.figNameStrSE));
    clear figDataSEvsSNR

    fprintf('- Save SE vs SNR Fig File:\t%s\n',simParams.figNameStrSE);
    fprintf(simParams.fileID,'## Save SE vs SNR Fig File:\t%s\r\n',simParams.figNameStrSE);
elseif strcmp(simParams.metricStr,'ISAC')   &&  ~isempty(results.sensing)
    dirOut = fullfile(simParams.scenarioPath, 'Output', 'Sensing');
    if ~isfolder (dirOut)
        mkdir(dirOut)
    end
    generateSensingPlots(simParams, results.sensing, results.sensingInfo, dirOut);

    %% save info
    s = results.sensingInfo(1);
    s.timeOffset = [results.sensingInfo.timeOffset]; % Recovered with sync, might change with SNR
    file = fullfile(dirOut, 'sensingInfo.json');
    fid = fopen(file, 'w');
    json = jsonencode(s);
    fprintf(fid, '%s\n', json);
    fclose(fid);

    % save results
    file = fullfile(dirOut, 'sensingResults.json');
    fid = fopen(file, 'w');
    s = [];
    snrvect = simParams.snrRange(1):simParams.snrStep:simParams.snrRange(end);
    n = size(results.sensingInfo(1).gtRange,2);
    for i = 1:length(results.sensing)
        s.snr = snrvect(i);
        s = getFieldOutputJson(results.sensing(i),'rangeNMSEdB', s, n);
        s = getFieldOutputJson(results.sensing(i),'velocityNMSEdB', s, n-1);
        s = getFieldOutputJson(results.sensing(i),'rangeMSEdB', s, n);
        s = getFieldOutputJson(results.sensing(i),'velocityMSEdB', s, n-1);
        if isfield(results.sensing(i), 'aEst')
            if ~isempty(results.sensing(i).aEst)
                s = getFieldOutputJson(results.sensing(i),'azErr', s, n);
                s = getFieldOutputJson(results.sensing(i),'elErr', s, n);
            end
        end
        json = jsonencode(s);
        fprintf(fid, '%s\n', json);
    end
    fclose(fid);

    % save target info

    file = fullfile(dirOut, 'targetEstimation.json');
    fid = fopen(file, 'w');
    s = [];
    for i = 1:length(results.sensing)

        s.range = results.sensing.rEst;
        s.velocity = results.sensing.vEst;
        if isfield(results.sensing(i), 'aEst')
            if ~isempty(results.sensing(i).aEst)
                s.angleAz = results.sensing.aEst(:,1);
                s.angleEl = results.sensing.aEst(:,2);
            end
        end
        json = jsonencode(s);
        fprintf(fid, '%s\n', json);
    end
    fclose(fid);

    % Save RDA map
    file = fullfile(dirOut, 'rda.json');
    fid = fopen(file, 'w');
    s = [];
    snrvect = simParams.snrRange(1):simParams.snrStep:simParams.snrRange(end);
    for i = 1:length(results.sensing)
        for j = 1:size(results(i).sensing.rda,3)
            rda = permute(results(i).sensing.rda(:,:,j,:), [1 2 4 3]);
            s.snr = snrvect(i);
            s.sensInstanceId = j;
            iRda = find(rda);
            [iv,ir,ia]=ind2sub(size(results(i).sensing.rda), iRda);
            s.axisRange = ir;
            s.axisVelocity = iv;
            s.axisAngle = ia;
            s.reflectionPower = rda(iRda);
            json = jsonencode(s);
            fprintf(fid, '%s\n', json);
            results(i).sensing.rdaMap.axisRange = ir;
            results(i).sensing.rdaMap.axisVelocity = iv;
            results(i).sensing.rdaMap.axisAngle = ia;
            results(i).sensing.rdaMap.reflectionPower = rda(iRda);
        end
    end
    fclose(fid);
    results.sensing = rmfield(results.sensing, 'rda');
end

fprintf('- Save Workspace Data File:\t%s\n',simParams.wsNameStr);
fprintf('- Save TXT Data File:\t%s\n',simParams.fiNameStr);
fprintf('***** End *****\n');

fprintf(simParams.fileID,'## Save Workspace Data File:\t%s\r\n',simParams.wsNameStr);
fprintf(simParams.fileID,'## Save TXT Data File:\t%s\r\n',simParams.fiNameStr);
fprintf(simParams.fileID,'## ***** End *****\r\n');
fclose(simParams.fileID);

% Save common variables
wsDataPathStr = fullfile(simParams.resultPathStr,simParams.wsNameStr);
save(wsDataPathStr, ...
    'simParams', 'phyParams','cfgSim', 'results');

end

function s = getFieldOutputJson(str, field,s,n)
if isfield(str, field)
    s.(field)  = str.(field);
else
    s.(field)  = nan(1,n);
end

end
% End of file