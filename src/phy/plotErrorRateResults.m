function [figData,titleStr] = plotErrorRateResults(simuParams,phyParams,results,resultsType,numSTSMax,varargin)
%plotErrorRateResults Plot bit error and packet error performance
%   Generalized tool of plotting the bit error ratio (BER) and packet error ratio (PER) vs signal-to-noise ratio (SNR)
%
%   Inputs:
%   simuParams is a simulation parameter struct
%   phyParams is a PHY parameter struct
%   results is a result variable struct
%   resultsType is a result type char, BER, PER, DR
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
switch simuParams.chanModel
    case 'AWGN'
        titleStrLine2 = strcat(simuParams.chanCfgStr);
    case 'Rayleigh'
        titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.tdlCfgStr);
    case 'MatlabTGay'
        titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.tdlCfgStr);
    case 'Intel'
        titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.paaCfgStr);
    case 'NIST'
        setIdx = varargin{1};
        titleStrLine2 = strcat(simuParams.chanCfgStr,',',simuParams.tdlCfgStr,',',simuParams.paaCfgStr,',', ...
            simuParams.abfCfgStr,',',simuParams.realizationSetCfgStr);
        setIdxStr = sprintf('Set#%d',setIdx);
    otherwise
        titleStrLine2 = varargin{1};
end
titleStr = strcat({titleStrLine1;titleStrLine2});

numMCS = size(phyParams.mcsMU,1);

legendStr = cell(1,numMCS);
for iMCS = 1:numMCS
    if numMCS == 1
        if numSTSMax > 1
            legendStr{iMCS} = strcat(setIdxStr,',',simuParams.stsCfgStr);
        else
            legendStr{iMCS} = setIdxStr;
        end
    else
        mcsStr = sprintf('MCS %s',vec2str(phyParams.mcsMU(iMCS,:)));
        if numSTSMax > 1
            legendStr{iMCS} = strcat(mcsStr,',',setIdxStr,',',simuParams.stsCfgStr);
        else
            legendStr{iMCS} = strcat(mcsStr,',',setIdxStr);
        end
    end
    
    if strcmp(resultsType,'BER')
        erAvgUser = results.berAvgUser{iMCS};
        erIndiUser = results.berIndiUser{iMCS};
    elseif strcmp(resultsType,'PER')
        erAvgUser = results.perAvgUser{iMCS};
        erIndiUser = results.perIndiUser{iMCS};
    else
        drIndiUser = results.gbitRateIndiUser{iMCS};
        drAvgUser = results.gbitRateAvgUser{iMCS};
        drSumUser = results.gbitRateSumUser{iMCS};
    end
    
    if strcmp(resultsType,'DR')
        % Plot sum user DR
        p1 = plot(simuParams.snrRanges{iMCS}, drSumUser, 'LineStyle','--','Marker','.','Color','k','LineWidth',2);
        p1.LineWidth = 2;
        p1.DisplayName = strcat('Sum-User,', legendStr{iMCS});
        hold on;
        % Plot averge user DR
        p2 = plot(simuParams.snrRanges{iMCS}, drAvgUser, 'LineStyle','-','Marker','.','Color','r','LineWidth',2);
        p2.LineWidth = 2;
        p2.DisplayName = strcat('Avg-User,', legendStr{iMCS});
        hold on;
        % Plot individual user DR
        for iUser = 1:phyParams.numUsers
            p3 = plot(simuParams.snrRanges{iMCS}, drIndiUser(:,iUser), 'LineStyle','-.','Marker',plotProperty.Mark(iUser+1), 'LineWidth',1);
            p3.DisplayName = strcat(sprintf('User %d,',iUser), legendStr{iMCS});
            hold on;
        end
    else
        % Plot averge user BER/PER
        p1 = semilogy(simuParams.snrRanges{iMCS}, erAvgUser, 'LineStyle','-','Marker','.','Color','r','LineWidth',2);
        p1.LineWidth = 2;
        p1.DisplayName = strcat('Avg-User,', legendStr{iMCS});
        hold on;
        % Plot individual user BER/PER
        for iUser = 1:phyParams.numUsers
            p2 = semilogy(simuParams.snrRanges{iMCS}, erIndiUser(:,iUser), 'LineStyle','-.','Marker',plotProperty.Mark(iUser+1), 'LineWidth',1);
            p2.DisplayName = strcat(sprintf('User %d,',iUser), legendStr{iMCS});
            hold on;
        end
    end
end
hold off;

grid on;
xlabel(strcat(simuParams.snrMode,' (dB)'));
if strcmp(resultsType,'DR')
    ylabel(strcat(resultsType,' (Gbits/sec)'));
%     ylim([0 50])
    lgd = legend;
    lgd.Location = 'northwest';
else
    ylabel(resultsType);
    ylim([0.99e-6 1])
    lgd = legend;
    lgd.Location = 'northeast';
end
title(titleStr);

end

