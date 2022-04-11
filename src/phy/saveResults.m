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

    %% save info
    s = results.sensingInfo(1);
    s.timeShift = [results.sensingInfo.timeShift]; % Recovered with sync, might change with SNR
    file = fullfile(dirOut, 'sensingInfo.json');
    fid = fopen(file, 'w');
    json = jsonencode(s);
    fprintf(fid, '%s\n', json);
    fclose(fid);

    file = fullfile(dirOut, 'sensingResults.json');
    fid = fopen(file, 'w');
    s = [];
    snrvect = simParams.snrRange(1):simParams.snrStep:simParams.snrRange(end);
    for i = 1:length(results.sensing)
        s.snr = snrvect(i);        
        s.nmseRange = results.sensing(i).rangeNMSEdB;
        s.nmseVelocity = results.sensing(i).velocityNMSEdB;
        s.mseRange = results.sensing(i).rangeMSEdB;
        s.mseVelocity = results.sensing(i).velocityMSEdB;
        s.rangeEstimate = results.sensing.rEst;
        s.velocityEstimate = results.sensing.vEst;
        s.rangeDopplerMap= results.sensing.doppler;
        json = jsonencode(s);
        fprintf(fid, '%s\n', json);
    end
    fclose(fid);
    
    generateSensingPlots(simParams, results.sensing, results.sensingInfo, dirOut);
    
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
    'simParams', 'phyParams','channelParams','cfgSim', 'results');

end

% End of file