function [channelParams,varargout] = setChannelModelParams(channelParams, sensParams, varargin)
%setChannelModelParams Channel Model Configuration
%   Set different configurations for channel models and their environments.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

p = inputParser;
channelParams.tgayChannel = [];
channelParams.nistChan = [];
channelParams.numRunRealizationSets = 1;
chanData = [];

switch channelParams.chanModel
    %% AWGN only channel
    case 'AWGN'
        channelParams.MdlStr = 'AWGN';
        channelParams.EnvStr = [];
        channelParams.numTaps = 0;
        
    %% Randomn Rayleigh multi-path fading
    case 'Rayleigh'
        channelParams.MdlStr = 'RandRayl';
        channelParams.EnvStr  = 'NA';
        channelParams.tdlType = channelParams.tdlType; % 'Impulse';    % 'Sinc';
        channelParams.numTaps = channelParams.numTaps;    % 50;    % Num of resolvable multi-path, 0 for chanFlag = 4.
        channelParams.maxMimoArrivalDelay = channelParams.maxMimoArrivalDelay;  % = 0: non delay, > 0: with max delay value 
        channelParams.pdpMethodStr = channelParams.pdpMethodStr;  % Tap PDP: EquA, EquB, EquC, ExpA, ExpB.
    
    %% MatlabTGay channel model
    case 'MatlabTGay'
        phyParams  = varargin{1};
        assert(phyParams.numUsers==1,'MatlabTGay channel supports single user only (numUsers=1).');

        channelParams.MdlStr = 'MatlabTGay';
        % 'LHL-SU-SISO'; %'OAH-SU-SISO';% 'LHL-SU-SISO'; % 'OAH-SU-SISO';
        % 'LHL-SU-MIMO1x1SS'; 'LHL-SU-MIMO1x1DD'; 'OAH-SU-MIMO1x1DD';
        % 'SCH-SU-MIMO1x1DD'; 'SCH-SU-MIMO2x2SS';  %'SCH-SU-MIMO2x2DD';
        % 'IndoorMIMO2x2SS';   'IndoorMIMO2x2DD';  'SCH-SU-MIMO2x2DD-HBF';
        channelParams.EnvStr = channelParams.environmentFileName;
        channelParams.EnvShowFlag = channelParams.showEnvironment;
        % Matlab TGay channel object
        tgayChannel = cell(phyParams.numUsers, 1);
        for uIdx = 1:phyParams.numUsers
%             tgayChannel{uIdx} = wlanTGayChannel;
            tgayChannel{uIdx} = nist.edmgTGayChannel;
            if strcmp(phyParams.phyMode, 'SC')
                tgayChannel{uIdx}.SampleRate = 1.76e9;
            else
                tgayChannel{uIdx}.SampleRate = 2.64e9;
            end
            tgayChannel{uIdx}.CarrierFrequency = 60e9;
            tgayChannel{uIdx} = setTGayChannelEnvironment(tgayChannel{uIdx},channelParams.EnvStr);
            %         tgayChannel{uIdx}.ReceiveArrayPosition = [1+14*rand; 1+14*rand; 1.5];
            tgayChannel{uIdx}.ReceiveArrayVelocitySource = channelParams.ReceiveArrayVelocitySource;
            tgayChannel{uIdx}.ReceiveArrayVelocity = channelParams.ReceiveArrayVelocity(:);
            if channelParams.EnvShowFlag == 1
                tgayChannel{uIdx}.showEnvironment;
            end
        end
        channelParams.tgayChannel = tgayChannel;
    
    %% NIST QD Channel configuration
    case 'NIST'
        msgStr = 'The feature of using NIST 60GHz QD channel model requires additional datasets from NIST.\n';
        warning(msgStr);
        addRequired(p,'phyParams');
        addRequired(p,'simuParams');
        addRequired(p,'nodeParams');
        parse(p, varargin{:});
        phyParams  = varargin{1};
        simuParams = varargin{2};
        nodeParams  = varargin{3};

        channelParams.MdlStr = 'NistQD';
        % chanQDString = {'lectureRoom.xml', 'dataCenter.xml', 'lRoom.xml', 'cityBlock.amf','streetCanyon.xml'} ;
        channelParams.EnvStr = channelParams.environmentFileName;    % 'LR' or 'LiR'; % Convert from box etc
        channelParams.RrayType = channelParams.rRayType;    %'DeteR'; 'R-Stat'; 'R-Dete';
        reflectionIndex = channelParams.totalNumberOfReflections;
        reflectionOrder = {'1st', '2nd'};
        channelParams.ReflecOrder = reflectionOrder{reflectionIndex};    % '1st', '2nd'
        channelParams.tdlType = channelParams.tdlType; % 'Impulse'; 'Sinc';

        % Realization settings

        % Set limitation to TDL numTaps, =[]: no limitation 
        % channelParams.numTaps = [];

        % Set receiver senstivity power threshold
        % chanCfg.rxPowThresType should be 'Inactivated', 'Static' or 'Dynamic'.
        % channelParams.rxPowThresdB is a numeric value, empty [] (default) or a scalar
        % When rxPowThresType is Inactivated (default), set rxPowThresdB as numeric empty [];
        % when rxPowThresType is Static, use rxPowThresdB as a numeric scalar;
        % when rxPowThresType is Dynamic, use SNRdB with threshold of rxPowThresdB (numeric scalar);

        % Set realization index flag, =0: fixed, =1: random
        if strcmp(channelParams.realizationIndexType,'Fixed')
            channelParams.realizationIndexFlag = 0;
        elseif strcmp(channelParams.realizationIndexType,'Random')
            channelParams.realizationIndexFlag = 1;
        else
            error('channelParams.realizationIndexType should be either Fixed or Random.');
        end

        % Set realization sets for location or oreinations, =0: Combined for with same numSTSVec; =1: Individual;
        if strcmp(channelParams.realizationSetType,'Combined')
            channelParams.realizationSetFlag = 0;
        elseif strcmp(channelParams.realizationSetType,'Individual')
            channelParams.realizationSetFlag = 1;
        else
            error('channelParams.realizationSetType should be either Combined or Individual.');
        end

        % Set realization set index vector, = [0] only valid for non-Beam Reduction, =[1:20] by default
        % channelParams.realizationSetIndexVec = [1:20];

        % Set dataset name string
        channelParams.dataSetNameStr = [];      % Local

        % Set dataset size string
        % channelParams.dataSetSizeStr = '20X100';

        % Phased antenna array configuration
        if isequal(nodeParams(1).arrayDimension,nodeParams(2).arrayDimension)
            paaCfg.arrayDimension = nodeParams.arrayDimension;
        else
            paaCfg.arrayDimension = strcat(nodeParams(1).arrayDimension,'_',nodeParams(2).arrayDimension);
        end

        % Beam selection
        switch phyParams.analogBeamforming
            case 'maxAllUserCapacity'
                % BS1: first compute capacity using complete channel matrix H for all the possible combinations of 
                % beams and choose the one which has maximum capacity 
                paaCfg.beamSelection = 'BS1';
            case 'maxMinAllUserSV'
                % BS3: first calculate minimum singular value using complete channel matrix H for all the possible 
                % combinations of beams and choose the one which has maximum minimum singular value
                paaCfg.beamSelection = 'BS3';
            case 'maxMinPerUserCapacity'
                % BS4: first compute per user capacity values and then compute minimum of these values for each possible 
                % combination. Finally, we choose the one which maximises the minimum  
                paaCfg.beamSelection = 'BS4';
            case 'maxMinMinPerUserSV'
                % BS5: first calculate minimum singular values considering per user channel matrix and then compute
                % minimum of these minimum singular values. Finally, we choose the one which maximizes
                % the minimum of these minimum singular values.
                paaCfg.beamSelection = 'BS5';
        end

        % Beam reduction
        if phyParams.dynamicBeamNumber<0
            paaCfg.beamReduction = 'BRo';
        else
            paaCfg.beamReduction = ['BR', num2str(phyParams.dynamicBeamNumber)];
        end

        % Input channel data set
        channelParams.chDataFoldStr = 'data_NISTQDChannel';
        channelParams.nistChPath = fullfile(simuParams.dataFoldStr,channelParams.chDataFoldStr);
        channelParams.nistChEnvPath = fullfile(channelParams.nistChPath,channelParams.EnvStr);
        assert(isfolder(channelParams.nistChEnvPath),'NIST QD channel environment dataset folder does not exist.');
        
        channelParams.paaCfg = paaCfg;

        if numel(phyParams.numSTSVec) == 1
            channelParams.numSTSStr = strcat('[',vec2str(phyParams.numSTSVec),']');
        else
            channelParams.numSTSStr = vec2str(phyParams.numSTSVec);
        end

        % Find correct label: search list of dir inside the environment directory
        dirChannels = dir(channelParams.nistChEnvPath);
        dataSetNameStrSearch = strcat('Data_',channelParams.EnvStr,'_',channelParams.RrayType,'_',channelParams.numSTSStr,'_', ...
            paaCfg.beamSelection,'_',paaCfg.beamReduction,'_',channelParams.ReflecOrder,'_',paaCfg.arrayDimension,'_', ...
            channelParams.dataSetSizeStr);

        indexCandidateChannelData = arrayfun(@(x) startsWith(x.name, dataSetNameStrSearch), dirChannels);

        % In case several folders are found with the same name, load the most recent channel
        folderFound = sum(indexCandidateChannelData); % Number of folder found
        assert(folderFound>0, 'Channel not found');
        candidateFolderNames = cell(folderFound,1);
        [candidateFolderNames{:}] = deal(dirChannels(indexCandidateChannelData).name);
        lastDash = unique(cellfun(@(x) find(x=='_', 1, 'last' ), candidateFolderNames));
        candidateDataStr = datetime(cellfun(@(x) (x(lastDash+1:end)), candidateFolderNames, 'UniformOutput', false)); % Find date of each folder found
        [~,candidateSorted] = sort(candidateDataStr, 'descend'); % Sort
        mostRecentChannel = candidateSorted(1); % Select most recent
        indexCandidateChannelData = find(indexCandidateChannelData);
        indexMostRecentChannel = indexCandidateChannelData(mostRecentChannel);
        channelParams.dataSetNameStr = dirChannels(indexMostRecentChannel).name; % Find correct label

        % Select channel dataset file
        channelParams.tdlMimoNorFlag = 1;

        channelParams.MatPath = fullfile(channelParams.nistChEnvPath,channelParams.dataSetNameStr);
        channelParams.MatName = 'selectedBeamsRealizations.mat';
        channelParams.MatFullPath = fullfile(channelParams.MatPath,channelParams.MatName);
        % Load channel dataset
        chanData = load(channelParams.MatFullPath, ...
            'antElemCases','beamFormingScheme','channelGain','delay','dopplerFactor','graphTxRx','graphTxRxOriginal', ...
            'orderOfReflection','RxComb','RxList','selectedBeamsIndex','TxComb','TxList');
        [channelParams.numRealizationSets,channelParams.numRealizationsPerSet] = size(chanData.channelGain);

        % Save selected dataset parameters into struct
        nistChan = struct;
        nistChan.RxComb = chanData.RxComb;
        nistChan.RxList = chanData.RxList;
        nistChan.TxComb = chanData.TxComb;
        nistChan.TxList = chanData.TxList;
        nistChan.antElemCases = chanData.antElemCases;
        nistChan.channelGain = cell(size(chanData.channelGain));
        nistChan.delay = cell(size(chanData.delay));
        nistChan.dopplerFactor = cell(size(chanData.dopplerFactor));
        nistChan.graphTxRx = chanData.graphTxRx;
        nistChan.graphTxRxOriginal = chanData.graphTxRxOriginal;
        nistChan.orderOfReflection = chanData.orderOfReflection;
        nistChan.selectedBeamsIndex = chanData.selectedBeamsIndex;
        channelParams.nistChan = nistChan;

        % Initilize location index
        numUseRealizationSets = length(channelParams.realizationSetIndexVec);
        if channelParams.realizationSetFlag == 0
            % realizationSetType: Combined
            numRunRealizationSets = 1;
            if numUseRealizationSets > 1
                refNumSTSVec = chanData.graphTxRx{1,channelParams.realizationSetIndexVec(1)};
                for idxLoc = 1:numUseRealizationSets
                    testNumSTSVec = chanData.graphTxRx{1,channelParams.realizationSetIndexVec(idxLoc)};
                    if any(testNumSTSVec~=refNumSTSVec)
                        error('numSTSVec should be same for all combined locations.');
                    end
                end
                channelParams.numCombRealizationSets = numUseRealizationSets;
            else
                if channelParams.realizationSetIndexVec(1) == 0
                    channelParams.numCombRealizationSets = channelParams.numRealizationSets;
                else
                    error('Non-zero scalar realizationSetIndexVec should use realizationSetFlag=1 as individual location.');
                end
            end
        else
            % realizationSetType: Individual
            numRunRealizationSets = numUseRealizationSets;
        end
        assert(numRunRealizationSets>0,'numRunRealizationSets should be > 0.');
    case 'sensNIST'
        addRequired(p,'phyParams');
        addRequired(p,'simuParams');
        addRequired(p,'nodeParams');
        parse(p, varargin{:});
        phyParams  = varargin{1};
        simParams = varargin{2};
        nodeParams  = varargin{3}; %#ok<NASGU> 

        %% Phase Antenna Array
        paaInfo = paaInit('Nodes', phyParams.numUsers+1, 'NumPaa', ones(1, phyParams.numUsers+1));

        %% User mobility
        userMobility = userMobilityInit(phyParams.numUsers+1,simParams.nTimeSamp);

        %% Config Channel
        channelInfo = channelDependentParams(simParams,paaInfo,userMobility); 
        channelParams = catstruct(channelInfo, channelParams); 

        %% Compute antenna codebook
        paaInfo = loadCodebook(paaInfo);

        %% Load Channel
        [rawMultiUserChannel, rawTargetInfo] = loadChannel(channelParams, simParams.scenarioPath);
        [H, delay] = getMultiUserChannel(rawMultiUserChannel,paaInfo,simParams.nTimeSamp);
        fullDigChannel  = getInterpChannel(H,delay, channelParams.numTaps, phyParams.fs*phyParams.cfgEDMG.NumContiguousChannels);
        chanData = analogBeamforming(fullDigChannel, paaInfo,phyParams, 'beamformingMethod', 'noBeamforming');
        chanData = chanData./sqrt(sum(sum(sum(abs(chanData).^2,1),2),3));
        channelParams.equivalentChannel = chanData;
        if ~isempty(sensParams)
            channelParams.targetInfo = getTargetInfo(rawTargetInfo,sensParams.pri);
            channelParams.ftm = getFtm(rawMultiUserChannel);
        end
    otherwise
        error('chanModel is not supported.');
end

varargout{1} = chanData;

end
