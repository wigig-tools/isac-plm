function saveResults(simuParams, phyParams, channelParams, cfgSim, results)
%saveResults This file should be included in main file in order to plot and save bit error rate (BER)
%   and packet error rate (PER) results.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

fprintf('--- Save %s Results ---\n- Folder Path:\t%s\n',simuParams.metricStr, simuParams.resultPathStr);
fprintf(simuParams.fileID,'## --- Save %s Result ---\r\n## Folder Path:\t%s\r\n',simuParams.metricStr, simuParams.resultPathStr);

if strcmp(simuParams.metricStr,'ER')
    if channelParams.chanFlag == 4
        numSTSMax = max(channelParams.nistChan.graphTxRxOriginal);
        % Plot Bit Error Rate vs SNR Results
        figDataBERvsSNR = plotErrorRateResults(simuParams, phyParams, results,'BER', numSTSMax, channelParams.realizationSetIndicator);
        % Plot Packet Error Rate vs SNR Results
        figDataPERvsSNR = plotErrorRateResults(simuParams, phyParams, results,'PER', numSTSMax, channelParams.realizationSetIndicator);
        % Plot Data Rate vs SNR Results
        figDataDRvsSNR = plotErrorRateResults(simuParams, phyParams, results,'DR', numSTSMax, channelParams.realizationSetIndicator);
    else
        numSTSMax = max(phyParams.numSTSVec);
        % Plot Bit Error Rate vs SNR Results
        figDataBERvsSNR = plotErrorRateResults(simuParams, phyParams, results,'BER', numSTSMax);
        % Plot Packet Error Rate vs SNR Results
        figDataPERvsSNR = plotErrorRateResults(simuParams, phyParams, results,'PER', numSTSMax);
        % Plot Data Rate vs SNR Results
        figDataDRvsSNR = plotErrorRateResults(simuParams, phyParams, results,'DR', numSTSMax);
    end

    %% Save Data
    savefig(figDataBERvsSNR, fullfile(simuParams.resultPathStr, simuParams.figNameStrBER));
    savefig(figDataPERvsSNR, fullfile(simuParams.resultPathStr, simuParams.figNameStrPER));
    savefig(figDataDRvsSNR, fullfile(simuParams.resultPathStr, simuParams.figNameStrDR));

    clear figDataBERvsSNR figDataPERvsSNR figDataDRvsSNR

    fprintf('- Save BER vs SNR Fig File:\t%s\n',simuParams.figNameStrBER);
    fprintf('- Save PER vs SNR Fig File:\t%s\n',simuParams.figNameStrPER);
    fprintf('- Save DR vs SNR Fig File:\t%s\n',simuParams.figNameStrDR);
    fprintf(simuParams.fileID,'## Save BER vs SNR Fig File:\t%s\r\n',simuParams.figNameStrBER);
    fprintf(simuParams.fileID,'## Save PER vs SNR Fig File:\t%s\r\n',simuParams.figNameStrPER);
    fprintf(simuParams.fileID,'## Save DR vs SNR Fig File:\t%s\r\n',simuParams.figNameStrDR);
    
elseif strcmp(simuParams.metricStr,'SE')
    if channelParams.chanFlag == 4
        numSTSMax = max(channelParams.nistChan.graphTxRxOriginal);
        % Plot Bit Error Rate vs SNR Results
        figDataSEvsSNR = plotSpectralEfficiencyResults(simuParams, phyParams, results, 'SE', numSTSMax, channelParams.realizationSetIndicator);
    else
        numSTSMax = max(phyParams.numSTSVec);
        % Plot Bit Error Rate vs SNR Results
        figDataSEvsSNR = plotSpectralEfficiencyResults(simuParams, phyParams, results, 'SE', numSTSMax);
    end

    %% Save Data
    savefig(figDataSEvsSNR, fullfile(simuParams.resultPathStr, simuParams.figNameStrSE));
    clear figDataSEvsSNR 

    fprintf('- Save SE vs SNR Fig File:\t%s\n',simuParams.figNameStrSE);
    fprintf(simuParams.fileID,'## Save SE vs SNR Fig File:\t%s\r\n',simuParams.figNameStrSE);
    
end

fprintf('- Save Workspace Data File:\t%s\n',simuParams.wsNameStr);
fprintf('- Save TXT Data File:\t%s\n',simuParams.fiNameStr);
fprintf('***** End *****\n');

fprintf(simuParams.fileID,'## Save Workspace Data File:\t%s\r\n',simuParams.wsNameStr);
fprintf(simuParams.fileID,'## Save TXT Data File:\t%s\r\n',simuParams.fiNameStr);
fprintf(simuParams.fileID,'## ***** End *****\r\n');
fclose(simuParams.fileID);

% Save common variables
wsDataPathStr = fullfile(simuParams.resultPathStr,simuParams.wsNameStr);
save(wsDataPathStr, ...
    'simuParams', 'phyParams','channelParams','cfgSim', 'results');

% Close all windows
% if simuParams.debugFlag ~= 1
%     close all
% end

end

% End of file