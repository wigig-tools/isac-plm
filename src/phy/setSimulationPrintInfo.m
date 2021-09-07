function simuParams = setSimulationPrintInfo(simuParams,phyParams,chanCfg)
%setSimulationPrintInfo Set formatted simulation labels for printing simulation information.
% 
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

% Write Result Files

if strcmp(simuParams.metricStr,'ER')
    simuParams.figNameStrBER = ['BER_',simuParams.pmNameStr,'.fig'];
    simuParams.figNameStrPER = ['PER_',simuParams.pmNameStr,'.fig'];
    simuParams.figNameStrDR = ['DR_',simuParams.pmNameStr,'.fig'];
    simuParams.figNameStrSE = '';
elseif strcmp(simuParams.metricStr,'SE')
    simuParams.figNameStrBER = '';
    simuParams.figNameStrPER = '';
    simuParams.figNameStrSE = ['SE_',simuParams.pmNameStr,'.fig'];
end
simuParams.fiNameStr = ['log_',simuParams.pmNameStr,'.txt'];
simuParams.wsNameStr = ['ws_',simuParams.pmNameStr,'.mat'];

if ~simuParams.isTest
    
    simuParams.resultPathStr = fullfile(simuParams.resultFoldStr,simuParams.resultSubFoldStr,simuParams.pmFolderStr);
    if ~isfolder(simuParams.resultPathStr)
        mkdir(simuParams.resultPathStr);
        fprintf('\tCretaed folder:\n\t%s\n',simuParams.resultPathStr);
    end
    
    fprintf('%s\n', pwd);
    
    simuParams.fileID = fopen(fullfile(simuParams.resultPathStr,simuParams.fiNameStr),'w');
    fprintf('%s\n',simuParams.pmNameStr);
    fprintf('%s\n',simuParams.pmFolderStr);
    fprintf(simuParams.fileID,'## %s\r\n',simuParams.pmNameStr);
    fprintf(simuParams.fileID,'## %s\r\n',simuParams.pmFolderStr);
    if chanCfg.chanFlag == 4
        fprintf('QD Channel Data Path:\t%s\n',chanCfg.MatPath);
        fprintf('QD Channel Data File:\t%s\n',chanCfg.MatName);
        fprintf(simuParams.fileID,'## QD Channel Data Path:\t%s\r\n',chanCfg.MatPath);
        fprintf(simuParams.fileID,'## QD Channel Data File:\t%s\r\n',chanCfg.MatName);
    end
    
    % Print in commmand line
    fprintf('numMaxParWorks: %d,\tdebugFlag: %d,\tpktFormatFlag(T): %d,\tchanFlag(C): %d,\tmimoFlag(M): %d\n', ...
        simuParams.numMaxParWorks,simuParams.debugFlag,simuParams.pktFormatFlag,chanCfg.chanFlag,simuParams.mimoFlag);
    
    fprintf('pktFormat: %s,\tphyMode: %s,\tgiType: %s,\tmimoFlag: %s,\tmimoCfg: %s,\tsmTypeNDP: %s,\tsmTypeDP: %s\n', ...
        simuParams.pktFormatStr,phyParams.phyMode,simuParams.giTypeStr,simuParams.mimoFlagStr,simuParams.mimoCfgStr, ...
        phyParams.smTypeNDP,phyParams.smTypeDP);
    
    fprintf('symbOffset: %f\n',phyParams.symbOffset);
    
    fprintf('chanCfg: %s,\ttdlCfg: %s\n',simuParams.chanCfgStr,simuParams.tdlCfgStr);
    fprintf('paaCfg: %s,\tabfCfg: %s\n',simuParams.paaCfgStr,simuParams.abfCfgStr);
    
    if chanCfg.chanFlag == 1
        fprintf('chanCfg.maxMimoArrivalDelay: %d\n',chanCfg.maxMimoArrivalDelay);
    end
    
    if chanCfg.chanFlag == 4
        fprintf('chanCfg.rxPowThresType: %s\t',chanCfg.rxPowThresType);
        fprintf('chanCfg.rxPowThresdB: %s\n',num2str(chanCfg.rxPowThresdB));
        fprintf('chanCfg.realizationIndexType: %s\t',chanCfg.realizationIndexType);
        fprintf('chanCfg.realizationSetType: %s\n',chanCfg.realizationSetType);
        if chanCfg.realizationSetFlag == 0
            fprintf('chanCfg.numCombRealizationSets: %s\t',num2str(chanCfg.numCombRealizationSets));
            fprintf('chanCfg.realizationSetIndexVec: %s\n',vec2str(chanCfg.realizationSetIndexVec));
        else
            fprintf('chanCfg.numRealizationSets: %s\t',num2str(chanCfg.numRealizationSets));
            fprintf('chanCfg.realizationSetIndicator: %s\n',vec2str(chanCfg.realizationSetIndicator));
        end
    end
    
    fprintf('simuParams.numRunRealizationSets: %d\n',simuParams.numRunRealizationSets);
    
    fprintf('snrMode: %s,\tsnrAntNorm: %s\n',simuParams.snrMode,simuParams.snrAntNormStr);
    fprintf('numTxAnt(X): %d,\tnumUsers(U): %d,\tnumSTSVec(S): %s\n',phyParams.numTxAnt,simuParams.numUsers,simuParams.stsCfgStr);
    fprintf('processFlag(P): %d,\tsvdFlag(V): %d,\tpowAlloFlag(A): %d,\tprecAlgoFlag(Q): %d,\tequiChFlag(E): %d,\tequaAlgoFlag(W): %d\n', ...
        phyParams.processFlag,phyParams.svdFlag,phyParams.powAlloFlag, ...
        phyParams.precAlgoFlag,phyParams.equiChFlag,phyParams.equaAlgoFlag);
    
    fprintf('softCsiFlag: %d,\tldpcDecMethod: %s\n',phyParams.softCsiFlag,phyParams.ldpcDecMethod);
    fprintf('MCS: %s\n',vec2str(phyParams.mcsMU));
    fprintf('PSDULengthByte: %d,\tnumDataBitsPerPkt: %s\n',phyParams.lenPsduByt,num2str(phyParams.numDataBitsPerPkt));
    fprintf('maxNumErrors: %d\tmaxNumPackets: %d\n',simuParams.maxNumErrors, simuParams.maxNumPackets);
    
    fprintf('***** Start %s Simulation *****\n', simuParams.metricStr);
    
    % Print in results file
    fprintf(simuParams.fileID,'## numMaxParWorks: %d,\tdebugFlag: %d,\tpktFormatFlag(T): %d,\tchanFlag(C): %d,\tmimoFlag(M): %d\r\n', ...
        simuParams.numMaxParWorks,simuParams.debugFlag,simuParams.pktFormatFlag,chanCfg.chanFlag,simuParams.mimoFlag);
    
    fprintf(simuParams.fileID,'## pktFormat: %s,\tphyMode: %s,\tgiType: %s,\tmimoFlag: %s,\tmimoCfg: %s,\tsmTypeNDP: %s,\tsmTypeDP: %s\r\n', ...
        simuParams.pktFormatStr,phyParams.phyMode,simuParams.giTypeStr,simuParams.mimoFlagStr,simuParams.mimoCfgStr, ...
        phyParams.smTypeNDP,phyParams.smTypeDP);
    
    fprintf(simuParams.fileID,'## symbOffset: %f\r\n',phyParams.symbOffset);
    
    fprintf(simuParams.fileID,'## chanCfg: %s,\ttdlCfg: %s\r\n',simuParams.chanCfgStr,simuParams.tdlCfgStr);
    fprintf(simuParams.fileID,'## paaCfg: %s,\tabfCfg: %s\r\n',simuParams.paaCfgStr,simuParams.abfCfgStr);
    
    if chanCfg.chanFlag == 1
        fprintf(simuParams.fileID,'## chanCfg.maxMimoArrivalDelay: %d\r\n',chanCfg.maxMimoArrivalDelay);
    end
    
    if chanCfg.chanFlag == 4
        fprintf(simuParams.fileID,'## chanCfg.rxPowThresType: %s\r\t',chanCfg.rxPowThresType);
        fprintf(simuParams.fileID,'## chanCfg.rxPowThresdB: %s\r\n',num2str(chanCfg.rxPowThresdB));
        fprintf(simuParams.fileID,'## chanCfg.realizationIndexType: %s\r\t',chanCfg.realizationIndexType);
        fprintf(simuParams.fileID,'## chanCfg.realizationSetType: %s\r\n',chanCfg.realizationSetType);
        if chanCfg.realizationSetFlag == 0
            fprintf(simuParams.fileID,'## chanCfg.numCombRealizationSets: %s\r\t',num2str(chanCfg.numCombRealizationSets));
            fprintf(simuParams.fileID,'## chanCfg.realizationSetIndexVec: %s\r\n',vec2str(chanCfg.realizationSetIndexVec));
        else
            fprintf(simuParams.fileID,'## chanCfg.numRealizationSets: %s\r\t',num2str(chanCfg.numRealizationSets));
            fprintf(simuParams.fileID,'## chanCfg.realizationSetIndexVec: %s\r\n',vec2str(chanCfg.realizationSetIndicator));
        end
    end
    
    fprintf(simuParams.fileID,'## simuParams.numRunRealizationSets: %d\r\n',simuParams.numRunRealizationSets);
    
    fprintf(simuParams.fileID,'## snrMode: %s,\tsnrAntNor: %s\r\n', ...
        simuParams.snrMode, simuParams.snrAntNormStr);
    
    fprintf(simuParams.fileID,'## numTxAnt(X): %d,\tnumUsers(U): %d,\tnumSTSVec(S): %s\r\n',...
        phyParams.numTxAnt,simuParams.numUsers,simuParams.stsCfgStr);
    
    fprintf(simuParams.fileID,'## processFlag(P): %d,\tsvdFlag(V): %d,\tpowAlloFlag(A): %d,\tprecAlgoFlag(Q): %d,\tequiChFlag(E): %d,\tequaAlgoFlag(W): %d\r\n', ...
        phyParams.processFlag,phyParams.svdFlag,phyParams.powAlloFlag,...
        phyParams.precAlgoFlag,phyParams.equiChFlag,phyParams.equaAlgoFlag);
    
    fprintf(simuParams.fileID,'## softCsiFlag: %d,\tldpcDecMethod: %s\r\n',phyParams.softCsiFlag,phyParams.ldpcDecMethod);
    fprintf(simuParams.fileID,'## MCS: %s\r\n',vec2str(phyParams.mcsMU));
    fprintf(simuParams.fileID,'## PSDULengthByte: %d,\tnumDataBitsPerPkt: %s\r\n',phyParams.lenPsduByt,num2str(phyParams.numDataBitsPerPkt));
    fprintf(simuParams.fileID,'## maxNumErrors: %d\tmaxNumPackets: %d\r\n',simuParams.maxNumErrors,simuParams.maxNumPackets);
    
    fprintf(simuParams.fileID,'## ***** Start %s Simulation *****\r\n', simuParams.metricStr);
    
end
% End of file