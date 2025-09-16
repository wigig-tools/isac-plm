function output = isac(simParams,phyParams,sensParams,channelParams,snrdb, varargin)
%%ISAC Integrated sensing and communication
%
%   RES = ISAC(SIM, PHY, CH, SNR) end-to-end communication simulation with
%   passive sensing. SIM is the simulation configuration structure, PHY is
%   the PHY configuration structure, CH is the channel configuration
%   structure and SNR is a scalar value
%
%   2022 NIST/CTL Steve Blandino, Neeraj Varshney


p = inputParser;
defaultMcsIdx = 1;
isInteger = @(x) isequal(x, round(x));
addParameter(p,'mcsIndex',defaultMcsIdx,isInteger);
parse(p,varargin{:});

runSensProcessing = p.Results.mcsIndex ==1; % Run sensing only for first MCS
runSensProcessing = runSensProcessing & ...
    any(ismember(["bistatic-trn", "passive-ppdu"], phyParams.cfgEDMG.SensingType));

% Account for noise energy in nulls so the SNR is defined per
% active subcarrier
noiseVarLin = getAWGNVariance(snrdb,simParams.snrMode,...
    simParams.snrAntNormFactor,phyParams.cfgEDMG);
simParams.noise.flag = simParams.noiseFlag;
simParams.noise.varLinActSubc = noiseVarLin.ActSubc;
simParams.noise.varLinTotSubc = noiseVarLin.TotSubc;
numUsers = phyParams.numUsers;

% Loop to simulate multiple packets
numBitErrors = zeros(1,numUsers);
numPacketErrors = zeros(1,numUsers);
packetLoopTimeStart = tic;
evmSumSTS = zeros(1,numUsers);
numSuccessPkt = 0;
csiSens = cell(1, simParams.nTimeSamp);
codebook = channelParams.codebook;
[searchTx,searchRx] = getNumAwv(phyParams.cfgEDMG,codebook);
snrSens = zeros(searchTx*searchRx, simParams.nTimeSamp);

rng(simParams.snrSeed); % Set Random Seeds - Same random per SNR loop.

t1 = tic;
for numPkt= 1: simParams.nTimeSamp
    %% Generate SU/MU-MIMO TDL Channel
    
    phyParams.precScaleFactor = 1; %SISO assumption
    phyParams.svdChan = [];        %SISO assumption

    %% MIMO Waveform
    [txSig,txDpPsdu] = edmgTx(phyParams.cfgEDMG,simParams);

    switch phyParams.cfgEDMG.SensingType
        case 'bistatic-trn'
            h = channelParams.fullDigChannel(numPkt);
            [rxSig, phyParams.trnBf{numPkt}] = ...
                getPrecodedRxSignal(txSig, h , codebook, phyParams);
            rxSig = getNoisyRxSignal(rxSig, 1, simParams.noise);

        case 'passive-beacon'
            h = channelParams.fullDigChannel(numPkt);
            rxSig = getPrecodedRxBeacon(txSig, h , codebook, simParams.noise);

        case 'passive-ppdu'
            channel.tdMimoChan = channelParams.fullDigChannel{numPkt};
            channel.fdMimoChan = fft(channel.tdMimoChan,phyParams.fftLength,3);
            rxSig = getNoisyRxSignal(txSig, ...
                channel.tdMimoChan, simParams.noise);
    end

    %% Receiver signal processing
    [syncError, rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks, cir, trn,preamble]  = ...
        edmgRx(rxSig, phyParams, simParams);
    
    if any(syncError==0)
        csiSens(numPkt) = cir{1}; %SISO assumption
        switch phyParams.cfgEDMG.SensingType
            case 'passive-beacon'
                snrSens(:,numPkt) = preamble.legacy.snr;
            case 'bistatic-trn'
                snrSens(1:length(trn.snr), numPkt) = trn.snr;
            case 'passive-ppdu'
               snrSens(numPkt) = preamble.edmg.snrEst;
        end
       
    end

    if all(syncError)
        numPacketErrors = numPacketErrors+1;
        continue; % Go to next loop iteration
    end

    %% Calculate EVM on received symbols
   if  any(ismember(["passive-ppdu", "none"], phyParams.cfgEDMG.SensingType))
        [refConstellation,EVM] = edmgReferenceConstellation(phyParams.cfgEDMG);
        evmIndiSTS = cell(numUsers,1);
        for iUser = 1:numUsers
            for iSTS = 1:phyParams.numSTSVec(iUser)
                evmIndiSTS{iUser}(iSTS)= 20*log10(mean(step(EVM{iUser}, ...
                    detSymbBlks{iUser}(:,:,iSTS))/100));
            end
        end

        %% Plot Symbol Constellation
        if simParams.debugFlag == 1
            if strcmpi(phyParams.phyMode,'OFDM')
                plotComparisonConstellation(refConstellation,evmIndiSTS,...
                    rxDataGrid,detSymbBlks,numUsers,phyParams.numSTSVec);
            else
                plotComparisonConstellation(refConstellation,evmIndiSTS,...
                    rxDataBlks,detSymbBlks,numUsers,phyParams.numSTSVec, gcf);
            end
        end

        %% Get bit and packet errors per packet per user
        for iUser = 1:numUsers
            % Bit error rate
            bitError = biterr(txDpPsdu{iUser},rxDpPsdu{iUser});
            numBitErrors(iUser) = numBitErrors(iUser) + bitError;

            % Determine if any bits are in error, i.e. a packet error
            pktErrDp = any(bitError);
            numPacketErrors(iUser) = numPacketErrors(iUser) + pktErrDp;
            % Get EVM
            evmSumSTS(iUser) = evmSumSTS(iUser)+mean(10.^(evmIndiSTS{iUser}/20));
        end
    end
    numSuccessPkt = numSuccessPkt+1;
    if mod(numSuccessPkt,round(simParams.nTimeSamp/100*10)) ==0 
        t2 = toc(t1);
        fprintf('Estimated time remaining: %d s\n', max(round(10*t2/(numSuccessPkt/round(simParams.nTimeSamp/100*10))-t2),0))
    end
end

%% Sensing signal processing
if ~isempty(sensParams) && runSensProcessing
    %% Threshold based sensing measurement and reporting
    [csiSens, thInfo] = csiReport(csiSens,phyParams,sensParams);    
    csiSens = recoverSparseCsi(csiSens,sensParams);
    %% Sensing Processing
    [rEst, vEst, aEst, rda, sensInfo, rflSub] = sensingProcessing(csiSens, phyParams, sensParams, channelParams.ftm, channelParams.codebook);
   
    %% Results
    sensRes = getSensingPerformance(rEst, vEst, channelParams.targetInfo, aEst, phyParams.packetType);
    sensRes.rda = rda;    
    sensRes.rflSub = rflSub;
     if strcmp(phyParams.cfgEDMG.SensingType, 'passive-ppdu')  || ~isfield(sensInfo, "axAngle")
         angleLen = 1;
     else
         angleLen = size(sensInfo.axAngle,1);
     end
    sensRes.beamSnr = snrSens(1:angleLen,:)';
    
    %% Info
    sensInfo = getSensInfo(sensInfo,channelParams,phyParams,simParams,sensParams,thInfo);

else
    sensRes = [];
    sensInfo = [];
    if strcmp(phyParams.cfgEDMG.SensingType, 'passive-beacon')
            sensRes.beamSnr = snrSens';
            sensInfo.axAngle = codebook(1).steeringAngle;
    end
end

% Loop processing time cost
packetLoopTimeEnd = toc(packetLoopTimeStart);
packetLoopTimeAve = packetLoopTimeEnd/(numPkt-1);
runTimeTotPkt= duration(seconds(packetLoopTimeEnd),'Format','hh:mm:ss.SS');
runTimePerPkt = duration(seconds(packetLoopTimeAve),'Format','hh:mm:ss.SS');

%% Calculate average BER and PER
% Calculate bit error rate (BER)
numBits = (numSuccessPkt(1)-1)*phyParams.numDataBitsPerPkt; % PSDULength in bytes
berUsers = numBitErrors./numBits;
berEachUser(1,:) = berUsers;
berPerUser(1,1) = sum(numBitErrors)/(sum(numBits));

% Calculate packet error rate (PER) at SNR point
perUsers = numPacketErrors/(numPkt(1)-1);
perEachUser(1,:) = perUsers;
perPerUser(1,1) = sum(numPacketErrors)/(numUsers*(numPkt(1)-1));

% Calculate EVM at SNR point
evmUsers = 20*log10(evmSumSTS/(numPkt(1)-1));
evmEachUser(1,:) = evmUsers;
evmPerUser(1,1) = 20*log10(sum(evmSumSTS)/(numUsers*(numPkt(1)-1)));

% Calculate data rate of individual users
gbitRateUsers = getActualGigabitDataRate(perUsers,phyParams.cfgEDMG);
gbitRateIndiUser(1,:) = gbitRateUsers;
gbitRateAvgUser(1,1) = mean(gbitRateUsers,2);
gbitRateSumUser(1,1) = sum(gbitRateUsers,2);

%% Print results in commmand line
% Print average user error rate
if ~simParams.isTest
    fprintf('MCS\tSNR\tEVM\tBER\tPER\tGbitRateAve\tGbitRateSum\tnumComPkt\tnumPkt\trunTimePerPkt\trunTimeTotPkt\n');
    fprintf(simParams.fileID,'## MCS\tSNR\tEVM\tBER\tPER\tGbitRateAve\tGbitRateSum\tnumComPkt\tnumPkt\trunTimePerPkt\trunTimeTotPkt\r\n');
    fprintf('%s\t%.2f\t%.2f\t%f\t%f\t%f\t%f\t%d\t%d\t%s\t%s\n',vec2str(phyParams.cfgEDMG.MCS),snrdb(1), ...
        evmPerUser(1,1), berPerUser(1,1), perPerUser(1,1), ...
        gbitRateAvgUser(1,1), gbitRateSumUser(1,1), ...
        numSuccessPkt(1)-1, numPkt(1)-1, runTimePerPkt, runTimeTotPkt);
    % Print individual users error rates
    for iUser = 1:numUsers
        fprintf('\t\tUser#%d:\t%.2f\t%f\t%f\t%f\n',iUser, evmUsers(1), ...
            berUsers(iUser), perUsers(iUser), gbitRateUsers(iUser));
    end
end

output.berEachUser=berEachUser;
output.perEachUser=perEachUser;
output.evmEachUser=evmEachUser;
output.berPerUser=berPerUser;
output.perPerUser=perPerUser;
output.evmPerUser=evmPerUser;
output.gbitRateIndiUser=gbitRateIndiUser;
output.gbitRateAvgUser=gbitRateAvgUser;
output.gbitRateSumUser=gbitRateSumUser;
output.numSuccessPkt=numSuccessPkt;
output.sensRes = sensRes;
output.sensInfo = sensInfo;
if simParams.saveCsi
    output.csi = csiSens;
end