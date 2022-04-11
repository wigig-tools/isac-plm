function [figData,titleStr] = plotSpectralEfficiencyResults(simuParams,phyParams,channelParams, results,resultsType,numSTSMax,varargin)
%plotSpectralEfficiencyResults Plot spectral efficiency performance
%   Generalized tool of plotting the sum, average and individual spectral efficiency (SE) vs signal-to-noise ratio (SNR)
%
%   Inputs:
%   simuParams is a simulation parameter struct
%   phyParams is a PHY parameter struct
%   results is a result variable struct
%   resultsType is a result type char, SE
%   numSTSMax is a maximum number of space-time streams scalar
%   varargin is an optional cell including realizationSetIndicator
%
%   Output:
%   figData
%   titleStr

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

plotProperty = simuParams.plotProperty;
figData = figure('Name',resultsType);

titleStrLine1 = strcat('EDMG-',simuParams.pktFormatStr,',',phyParams.phyMode,'-PHY,',simuParams.mimoFlagStr,',', ...
    simuParams.giTypeStr,',',simuParams.mimoCfgStr,',',simuParams.dbfCfgStr,',',simuParams.mcsCfgStr);

setIdxStr = '';
if strcmp(channelParams.chanModel,'NIST')
    setIdx = varargin{1};
    titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.tdlCfgStr,',',simuParams.paaCfgStr,',', ...
        simuParams.abfCfgStr,',',simuParams.realizationSetCfgStr);
    setIdxStr = sprintf(', Set#%d',setIdx);
else
    titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.tdlCfgStr,',',simuParams.paaCfgStr);
end
titleStr = strcat({titleStrLine1;titleStrLine2});

if numSTSMax > 1
    legendStr = strcat(setIdxStr,',',simuParams.stsCfgStr);
else
    legendStr = setIdxStr;
end

% Plot sum user SE
p1 = plot(simuParams.snrRanges{1},results.ergoSESumUser, 'LineStyle','--', 'Marker','.', 'Color','k', 'LineWidth',2);
p1.LineWidth = 2;
p1.DisplayName = strcat('Sum-User', legendStr);
hold on;
% Plot average user SE
p2 = plot(simuParams.snrRanges{1},results.ergoSEAvgUser, 'LineStyle','-', 'Marker','.', 'Color','r', 'LineWidth',2);
p2.LineWidth = 2;
p2.DisplayName = strcat('Avg-User', legendStr);
hold on;
% Plot individual user SE
for iUser = 1:phyParams.numUsers
    p3 = plot(simuParams.snrRanges{1},results.ergoSEIndiUser(:,iUser), 'LineStyle','-.', 'Marker',plotProperty.Mark(iUser+2), 'LineWidth',1);
    p3.DisplayName = strcat(sprintf('User %d',iUser), legendStr);
    hold on;
end
hold off;

grid on;
xlabel(strcat(simuParams.snrMode,' (dB)'));
ylabel(strcat(resultsType,' (bits/sec/Hz)'));
lgd = legend;
lgd.Location = 'northwest';
title(titleStr);

end

