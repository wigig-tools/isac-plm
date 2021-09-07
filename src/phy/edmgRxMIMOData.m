function [rxMUPSDU,detDataSymbs,eqSymbGrid,rxDataGrid,rxDataBlks,fdEqualizer] = edmgRxMIMOData( ...
    rxSigSeq,cfgEDMG,cfgSim,tdMimoChan,fdMimoChan,noiseVarLin,varargin)
%edmgRxMIMOData EDMG PPDU/PSDU recevier waveform generator
%   This function recovers the receiver waveforms for either the EDMG PPDU format or the
%   EDMG PSDU (data-field only) format. The EDMG PPDU format supports the non-data packet (NDP) or data packet
%   (DP).
% 
%   Inputs
%       rxSigSeq: received signal sequence held in numUsers-length cell array
%       cfgEDMG: configuration object of nist.edmgConfig
%       cfgSim:  configuration structure of simulation parameters
%       tdMimoChan: time-domain MIMO channel impluse response (CIR) held in numUsers-length cell array
%       fdMimoChan: frequency-domain MIMO channel frequency response(CFR) held in numUsers-length cell array
%       noiseVarLin:    noise variances in linear scale
%       varargin:   reservation for transmission startOffset and/or SVD struct for EDMG PPDU format.
%                   nargin = 7: varargin{1} is either the receiver startOffset EDMG PSDU format OR SVD struct for 
%                               precoding.
%                   nargin = 8: varargin{1} is the receiver startOffset EDMG PSDU format; varargin{2} is the SVD 
%                               struct for precoding.
%                   nargin = 9: varargin{1} is the receiver startOffset EDMG PSDU format; varargin{2} is the SVD 
%                               struct for precoding; varargin{3} is the carrier frequency offset (CFO) value. 
%   Outputs
%       rxMUPSDU: the multiple users' PSDU after data bits recoveray at receiver held in numUsers-length cell array.
%       detDataSymbs:   the multiple user's data symbol blocks after MIMO detection/equalization at receiver held 
%                       in numUsers-length cell array. The detDataSymbs of the SC mode is a time-domain data symbol 
%                       block after frequency-domain detection/equalization; while the detDataSymbs of the OFDM mode
%                       is the same to eqSymbGrid.
%       eqSymbGrid: the multiple user's data symbol block at frequency-domain after MIMO detection/equalization at 
%                       receiver held in numUsers-length cell array.
%       rxDataGrid: the frequency-domain data-field symbol grid at receiver held in numUsers-length cell array. 
%                   In SC mode, the rxDataGrid is the symbol grid after FFT operation; while in the OFDM mode, 
%                   the rxDataGrid is the symbol grid after OFDM demodulation.
%       rxDataBlks: the time-domain data-field symbol block at SC receiver held in numUsers-length cell array. 
%       fdEqualizer: the multiple user's frequency-domain equalization weights held in numUsers-length cell array.
%                   Each entry is a size numSD-by-numRx-by-numSTS 3D matrix, where numSD is the number of data
%                   subcarriers, numRx is the number of receiver RF chains, numSTS is the number of space-time streams
%                   of the specfic user.
%   
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

narginchk(6,10);

phyMode = cfgEDMG.PHYType;
numUsers = cfgEDMG.NumUsers;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;
numTxAnt = cfgEDMG.NumTransmitAntennas;
spatialMapType = cfgEDMG.SpatialMappingType;
spatialMapMat = cfgEDMG.SpatialMappingMatrix;

numSTSTot = sum(numSTSVec);
pktFormatFlag = cfgSim.pktFormatFlag;
chanFlag = cfgSim.chanFlag;
dopplerFlag = cfgSim.dopplerFlag;
mimoFlag = cfgSim.mimoFlag;
processFlag = cfgSim.processFlag;
svdFlag = cfgSim.svdFlag;
precAlgoFlag = cfgSim.precAlgoFlag;
equiChFlag = cfgSim.equiChFlag;
equaAlgoFlag = cfgSim.equaAlgoFlag;
equaAlgoStr = cfgSim.equaAlgoStr;
softCsiFlag = cfgSim.softCsiFlag;
ldpcDecMethod = cfgSim.ldpcDecMethod;

assert(ismember(pktFormatFlag, [0,1]), 'pktFormatFlag should be either 0 or 1.')
assert(ismember(mimoFlag, [0,1,2]), 'pktFormatFlag should be either 0 or 1.')

if pktFormatFlag == 0
    % PPDU
    scaleFactor = 1;
    svdChan = [];
    if nargin == 7
        startOffset = varargin{1};
        CFO = [];
    elseif nargin == 8
        startOffset = varargin{1};
        CFO = varargin{2};
    elseif nargin == 9
        startOffset = varargin{1};
        CFO = varargin{2};
        scaleFactor = varargin{3};
    elseif nargin == 10
        startOffset = varargin{1};
        CFO = varargin{2};
        scaleFactor = varargin{3};
        svdChan = varargin{4};
    else
        error('nargin should be >= 7 in PPDU format.');
    end
else
    % PSDU pktFormatFlag = 1
    scaleFactor = 1;
    svdChan = [];
    startOffset = [];
    CFO = [];
    if nargin == 6
    elseif nargin == 7
        scaleFactor = varargin{1};
    elseif nargin == 8
        scaleFactor = varargin{1};
        svdChan = varargin{2};
    elseif nargin == 9
        startOffset = varargin{1};
        CFO = varargin{2};
        scaleFactor = varargin{3};
    elseif nargin == 10
        startOffset = varargin{1};
        CFO = varargin{2};
        scaleFactor = varargin{3};
        svdChan = varargin{4};
    else
        error('nargin should be >= 6 in PSDU format.');
    end
    
end

if pktFormatFlag && chanFlag ~= 0
    if strcmp(phyMode,'OFDM')
        % channel estimation of the first doppler realization
        fdMimoChan = cellfun(@(x) squeeze(x(:,1,:,:)), fdMimoChan, ...
            'UniformOutput', false); % Remove doppler dimension assuming ideal
    elseif strcmp(phyMode,'SC')
        % channel estimation of the first doppler realization
        selectFirstTdl = @(y) cellfun(@(x) x(:, 1), y, 'UniformOutput', false);
        tdMimoChan = cellfun(@(x) selectFirstTdl(x),tdMimoChan, ...
            'UniformOutput', false);  % Remove doppler dimension assuming ideal
    end
end
        
if chanFlag ~= 0
    if equiChFlag < 2
        eqMapObj = [];
    elseif equiChFlag == 2
        eqMapObj = spatialMapMat;
    elseif equiChFlag >= 3
        eqMapObj = svdChan;
    else
        error('equiChFlag should be one of 0,1,2,3.');
    end
    
    if svdFlag == 0
        scMapObj = spatialMapMat;
    else
        scMapObj = svdChan;
    end
else
    scMapObj = spatialMapMat;
end


if isempty(tdMimoChan)
    for iUser = 1:numUsers
        tdMimoChan{iUser} = [];
    end
end
if isempty(fdMimoChan)
    for iUser = 1:numUsers
        fdMimoChan{iUser} = [];
    end
end

%% Receiver processing
rxDataGrid = cell(numUsers,1);
rxDataBlks = cell(numUsers,1);
eqSymbGrid = cell(numUsers,1);
detDataSymbs = cell(numUsers,1);
rxMUPSDU = cell(numUsers,1);
fdEqualizer = cell(numUsers,1);

% Post processing at each Rx User
for iUser = 1:numUsers
    stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
    
    if isempty(scaleFactor)
        beta = 1;
    elseif iscell(scaleFactor)
        beta = scaleFactor{iUser};
    else
        beta = scaleFactor;
    end
        
    if strcmp(phyMode,'OFDM')
        % Encoding information
        numOfdmSymbMax = getMaxNumberBlocks(cfgEDMG);
        encodeParms = nist.edmgOFDMEncodingInfo(cfgEDMG,iUser,numOfdmSymbMax);
        numOfdmSymbIndiUser = encodeParms.NSYMS;
        [ofdmInfo,~,ofdmCfg] = nist.edmgOFDMInfo(cfgEDMG);
        numDataSubc = ofdmInfo.NSD; % Number of data carrying subcarriers
        rxDataGrid{iUser} = zeros(numDataSubc,numOfdmSymbMax,numSTSVec(iUser));
    elseif strcmp(phyMode,'SC')
        % SC
        scInfo = edmgSCInfo(cfgEDMG);
        numGI = scInfo.NGI;
        lenFFT = scInfo.NFFT;
        numScBlksMax = getMaxNumberBlocks(cfgEDMG);
        encodeParms = nist.edmgSCEncodingInfo(cfgEDMG,iUser,numScBlksMax);
        numScBlksIndiUser = encodeParms.NBLKS;
        numDataSubc = scInfo.NTONES;
        rxDataGrid{iUser} = zeros(numDataSubc,numScBlksMax,numSTSVec(iUser));
    else
        error('phyMode should be either OFDM and SC.');
    end

    %% Channel estimation
    if chanFlag == 0   % AWGN
        % Set channel gains to 1 as AWGN channel
        dataFdMimoChan = complex(ones(numDataSubc,numSTSTot,numSTSVec(iUser)));
    else
        % Obtain FD estimated channel on data subcarriers
        if strcmp(phyMode,'OFDM')
            dataFdMimoChan = getFDEquivalentMIMODataChannel(iUser,tdMimoChan{iUser},fdMimoChan{iUser},equiChFlag,cfgEDMG,eqMapObj);
        else
            % SC
            if equiChFlag == 3
                dataFdMimoChan = squeeze(getFDEquivalentMIMODataChannel(iUser,tdMimoChan,fdMimoChan{iUser},equiChFlag,cfgEDMG,scaleFactor));
            else
                dataFdMimoChan = squeeze(getFDEquivalentMIMODataChannel(iUser,tdMimoChan,fdMimoChan{iUser},equiChFlag,cfgEDMG,eqMapObj));
            end
        end
    end

    %% Get noise variance estimation of the current user
    if iscell(noiseVarLin)
        noiseVarEst = numTxAnt * mean(noiseVarLin{iUser});
    elseif ismatrix(noiseVarLin) && size(noiseVarLin,1)==numUsers
        noiseVarEst = numTxAnt * mean(noiseVarLin(iUser,:));
    elseif isvector(noiseVarLin) && length(noiseVarLin)==numSTSTot
        noiseVarEst = numTxAnt * mean(noiseVarLin(stsIdx));
    elseif isvector(noiseVarLin) && length(noiseVarLin)==numSTSVec(iUser)
        noiseVarEst = numTxAnt * mean(noiseVarLin);
    elseif isscalar(noiseVarLin)
        noiseVarEst = numTxAnt * noiseVarLin;
    else
        error('noiseVarLin format is incorrect.');
    end

    if pktFormatFlag == 0
        %% Extract data field and Compensate CFO 
        % Get Indices of fields within the packet
        fieldIndices = nist.edmgFieldIndices(cfgEDMG);
        if strcmp(phyMode,'OFDM')
            % Extract data field from received signal sequences
            rxDataSeq = rxSigSeq{iUser}(startOffset{iUser} + (fieldIndices.EDMGData(1):fieldIndices.EDMGData(2)),:);
            % Compensate for CFO
            delay = double(fieldIndices.EDMGCEF(2)-fieldIndices.EDMGCEF(1)+1);
            rxDataSeq = compensateFrequencyOffset(rxDataSeq, CFO{iUser}, delay);
            symbOffset = cfgSim.symbOffset;
        else
            % SC - Extract data field (ignore first GI)
            % Extract data field from received signal sequences
            rxDataSeq = rxSigSeq{iUser}(startOffset{iUser} + (fieldIndices.EDMGData(1) + numGI:fieldIndices.EDMGData(2)),:);
            % Compensate for CFO
            delay = double(fieldIndices.EDMGCEF(2)-fieldIndices.EDMGCEF(1)+1+numGI);
            rxDataSeq = compensateFrequencyOffset(rxDataSeq, CFO{iUser}, delay);
        end
    else
        % if pktFormatFlag == 1
        if strcmp(phyMode,'OFDM')
            % OFDM demodulate
            rxDataSeq = rxSigSeq{iUser};
            symbOffset = cfgSim.symbOffset;
        else
            % SC
            rxDataSeq = rxSigSeq{iUser};
        end
    end

    
    %% Data Field Processing
    if strcmp(phyMode,'OFDM')
        %   OFDM demodulate with MIMO receiver power de-normalization
        rxSymbGrid = nist.edmgOFDMDemodulate(rxDataSeq,cfgEDMG,'OFDMSymbolOffset',symbOffset)*sqrt(numSTSTot);
        % Discard pilots, get data subcarriers only.
        rxDataGrid{iUser} = rxSymbGrid(ofdmCfg.DataIndices,:,:);
    else
        % SC
        if pktFormatFlag == 0
            rxDataBlks{iUser} = reshape(rxDataSeq,[numDataSubc,numScBlksMax,numSTSVec(iUser)]);
        else
            symbOffset = cfgSim.symbOffset;
            sampleOffset = numGI-round(symbOffset*numGI);
            % Shift FFT window and remove equivalent of 1 GI (part at the
            % beginning, part at the end
            rxDataRmGI = rxDataSeq(1+numGI-sampleOffset:end-sampleOffset,:);
            % Align numDataSubc length SC symbols
            rxDataSeqReshape = reshape(rxDataRmGI,[numDataSubc,numScBlksMax,numSTSVec(iUser)]);
            % Bring residual GI from start to end of SC symbol  
            rxDataBlks{iUser} = rxDataSeqReshape([1+sampleOffset:numDataSubc 1:sampleOffset] ,:,:);
        end
        
        % MIMO receiver power de-normalization
        rxDataBlks{iUser} = rxDataBlks{iUser} * sqrt(numTxAnt);
        % DFT operation transform from TD to FD
        rxDataGrid{iUser} = fftshift(fft(rxDataBlks{iUser}, lenFFT, 1), 1) / sqrt(lenFFT);
    end
   
    %% Equalization
    if equaAlgoFlag == 0
        % No equalization, received power should be scaled.
        [rxDataGrid{iUser},softCsiGain] = edmgRxPowerScale(rxDataGrid{iUser},cfgEDMG,beta,dataFdMimoChan);
        eqSymbGrid{iUser} = rxDataGrid{iUser};
        fdEqualizer{iUser} = 1./beta;
    elseif equaAlgoFlag == 1
        % ZF
        [eqSymbGrid{iUser},softCsiGain,fdEqualizer{iUser}] = nist.edmgMIMOEqualize(rxDataGrid{iUser},dataFdMimoChan,equaAlgoStr);
    elseif equaAlgoFlag == 2
        % MMSE
        [eqSymbGrid{iUser},softCsiGain,fdEqualizer{iUser}] = nist.edmgMIMOEqualize(rxDataGrid{iUser},dataFdMimoChan,equaAlgoStr,noiseVarEst);
    elseif equaAlgoFlag == 3
        % MF
        [eqSymbGrid{iUser},softCsiGain,fdEqualizer{iUser}] = nist.edmgMIMOEqualize(rxDataGrid{iUser},dataFdMimoChan,equaAlgoStr);
    else
        error('equaFlag should be 0, 1, 2 or 3.');
    end
    
    % Recover data
    if strcmp(phyMode,'OFDM')
        % FD MIMO decoding
        detDataSymbs{iUser} = zeros(numDataSubc,numOfdmSymbIndiUser,numSTSVec(iUser));
        if (strcmp(spatialMapType,'Fourier') || strcmp(spatialMapType,'Hadamard')) && (equiChFlag == 1)
            for iSubc = 1:numDataSubc
                rxDataSubcMimoSymbs = reshape(squeeze(eqSymbGrid{iUser}(iSubc,:,:)),numOfdmSymbIndiUser,numSTSVec(iUser));
                detDataSymbs{iUser}(iSubc,:,:) = rxDataSubcMimoSymbs * permute(spatialMapMat,[2,1])';
            end
        else
            detDataSymbs{iUser} = eqSymbGrid{iUser};
        end
        if softCsiFlag
            rxMUPSDU{iUser} = nist.edmgDataBitRecover(detDataSymbs{iUser},noiseVarEst,iUser,softCsiGain,cfgEDMG,'LDPCDecodingMethod',ldpcDecMethod);
        else
            rxMUPSDU{iUser} = nist.edmgDataBitRecover(detDataSymbs{iUser},noiseVarEst,iUser,cfgEDMG,'LDPCDecodingMethod',ldpcDecMethod);
        end
    else
        % SC
        % IDFT operation transform from FD to TD
        eqSymbBlks = ifft(ifftshift(eqSymbGrid{iUser},1), lenFFT, 1) * sqrt(lenFFT);
        
        % TD MIMO decoding
        if (strcmp(spatialMapType,'Fourier') || strcmp(spatialMapType,'Hadamard')) && (equiChFlag == 1)
            detSymbBlks = edmgSCTDMIMODectect(eqSymbBlks,iUser,numSTSVec,scMapObj,equiChFlag);
        else
            detSymbBlks = eqSymbBlks;
        end
        
        % Discard GI from all blocks
        detDataSymbs{iUser} = detSymbBlks(1:end-numGI,1:numScBlksIndiUser,:);
        rxMUPSDU{iUser} = nist.edmgDataBitRecover(detDataSymbs{iUser},noiseVarEst,iUser,cfgEDMG,'LDPCDecodingMethod',ldpcDecMethod);
    end
end % End of Rx User


end



% End of file