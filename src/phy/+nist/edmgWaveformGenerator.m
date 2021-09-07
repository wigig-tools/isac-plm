function [txWaveform,data] = edmgWaveformGenerator(dataBits,cfgEDMG,varargin)
% edmgWaveformGenerator WLAN waveform generation
%   WAVEFORM = nist.edmgWaveformGenerator(DATA,CFGEDMG) generates a waveform
%   for a given format configuration and information bits. The generated
%   waveform contains a single packet with no idle time. For OFDM based
%   formats, the data scrambler initial states is 93 and the packet is
%   windowed for spectral controls with a windowing transition time of 1e-7
%   seconds.
%
%   WAVEFORM is a complex Ns-by-Nt matrix containing the generated
%   waveform, where Ns is the number of time domain samples, and Nt is the
%   number of transmit antennas.
%
%   DATA is the information bits including any MAC padding to be coded
%   across the number of packets to generate, i.e., representing multiple
%   concatenated PSDUs. It can be a double or int8 typed binary vector.
%   Alternatively, it can be a scalar cell array or a vector cell array
%   with length equal to number of users. Each element of the cell array
%   must be a double or int8 typed, binary vector. When DATA is a vector or
%   scalar cell array, it applies to all users. When DATA is a vector cell
%   array, each element applies to a single user. For each user, the bit
%   vector applied is looped if the number of bits required across all
%   packets of the generation exceeds the length of the vector provided.
%   This allows a short pattern to be entered, e.g. [1;0;0;1]. This pattern
%   will be repeated as the input to the PSDU coding across packets and
%   users. The number of data bits taken from a data stream for the ith
%   user when generating a packet is given by the ith element of the
%   CFGEDMG.PSDULength property times eight.
%
%   CFGEDMG is a format configuration object of type EDMG. 
%   The properties of CFGEDMG are used to parameterize the
%   packets generated including the data rate and PSDU length.
%
%   WAVEFORM = nist.edmgWaveformGenerator(DATA,CFGEDMG,Name,Value) specifies
%   additional name-value pair arguments described below. When a name-value
%   pair is not specified, its default value is used.
%
%   'NumPackets'               The number of packets to generate. It must
%                              be a positive integer. The default value is
%                              1.
%
%   'IdleTime'                 The length in seconds of an idle period
%                              after each generated packet. The valid range
%                              depends on the format to generate. For DMG
%                              it must be 0 or greater than or equal to
%                              1e-6 seconds. For all other formats it must
%                              be 0 or greater than or equal to 2e-6
%                              seconds. The default value is 0 seconds.
%
%   'ScramblerInitialization'  Scrambler initial state(s), applied for DMG,
%                              S1G, VHT, HT, and non-HT OFDM formats. It
%                              must be a double or int8-typed scalar or
%                              matrix containing integer values. The valid
%                              range depends on the format to generate. For
%                              DMG Control PHY the valid range is between 1
%                              and 15 inclusive. For all other formats the
%                              the valid range is between 1 and 127
%                              inclusive. If a scalar is provided all
%                              packets are initialized with the same state
%                              for all users. Specifying a matrix allows a
%                              different initial state to be used per user
%                              and per packet. Each column specifies the
%                              initial states for a single user. If a
%                              single column is provided, the same initial
%                              states will be used for all users. Each row
%                              represents the initial state of each packet
%                              to generate. Internally the rows are looped
%                              if the number of packets to generate exceeds
%                              the number of rows of the matrix provided.
%                              For all formats except DMG, the default
%                              value is 93, which is the example state
%                              given in IEEE Std 802.11-2012 Section
%                              L.1.5.2. For the DMG format, the value
%                              specified will override the
%                              ScramblerInitialization property of the
%                              configuration object. The mapping of the
%                              initialization bits on scrambler schematic
%                              X1 to X7 is specified in IEEE Std
%                              802.11-2012, Section 18.3.5.5. For more
%                              information, see: <a href="matlab:doc('wlanwaveformgenerator')">wlanWaveformGenerator</a>
%                              documentation.
%
%   'WindowTransitionTime'     The windowing transition length in seconds,
%                              applied to OFDM based formats. For all
%                              formats except DMG it must be a nonnegative
%                              scalar and no greater than 16e-6 seconds.
%                              Specifying it as 0 turns off windowing. For
%                              all formats except DMG, the default value is
%                              1e-7 seconds. For DMG OFDM format it must be
%                              a nonnegative scalar and no greater than
%                              9.6969e-08 (256/2640e6) seconds. The default
%                              value for DMG format is 6.0606e-09
%                              (16/2640e6) seconds.

%   Copyright 2015-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Check number of input arguments
coder.internal.errorIf(mod(nargin, 2) == 1, 'nist:wlanWaveformGenerator:InvalidNumInputs');

% Validate the format configuration object is a valid type
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');
s = validateConfig(cfgEDMG);

% Get format
isEDMG = isa(cfgEDMG,'nist.edmgConfig');
isEDMGOFDM = isEDMG && strcmp(phyType(cfgEDMG),'OFDM');
isEDMGSC = isEDMG && strcmp(phyType(cfgEDMG),'SC');

overrideObjectScramInit = false;

% P-V pairs
% Define default values for EDMG WindowTransitionTime
winTransitTime = 16/2640e6; % Windowing length of 16

defaultScramblerInitialization = 93;

% Default values
defaultParams = struct('NumPackets', 1, ...
                    'IdleTime', 0, ...
                    'ScramblerInitialization', defaultScramblerInitialization, ...
                    'WindowTransitionTime', winTransitTime);

if nargin==2
    useParams = defaultParams;
else          
    % Extract each P-V pair
%     if isempty(coder.target) % Simulation path
%         p = inputParser;
% 
%         % Get values for the P-V pair or set defaults for the optional arguments
%         addParameter(p,'NumPackets',defaultParams.NumPackets);
%         addParameter(p,'IdleTime',defaultParams.IdleTime);
%         addParameter(p,'ScramblerInitialization',defaultParams.ScramblerInitialization);
%         addParameter(p,'WindowTransitionTime',defaultParams.WindowTransitionTime);
%         % Parse inputs
%         parse(p,varargin{:});
% 
%         useParams = p.Results;
%     else % Codegen path
%         pvPairs = struct('NumPackets', uint32(0), ...
%                          'IdleTime', uint32(0), ...
%                          'ScramblerInitialization', uint32(0), ...
%                          'WindowTransitionTime', uint32(0));
% 
%         % Select parsing options
%         popts = struct('PartialMatching', true);
% 
%         % Parse inputs
%         pStruct = coder.internal.parseParameterInputs(pvPairs,popts,varargin{:});
% 
%         % Get values for the P-V pair or set defaults for the optional arguments
%         useParams = struct;
%         useParams.NumPackets = coder.internal.getParameterValue(pStruct.NumPackets,defaultParams.NumPackets,varargin{:});
%         useParams.IdleTime = coder.internal.getParameterValue(pStruct.IdleTime,defaultParams.IdleTime,varargin{:});
%         useParams.ScramblerInitialization = coder.internal.getParameterValue(pStruct.ScramblerInitialization,defaultParams.ScramblerInitialization,varargin{:});
%         useParams.WindowTransitionTime = coder.internal.getParameterValue(pStruct.WindowTransitionTime,defaultParams.WindowTransitionTime,varargin{:});
%     end
% 
%     % Validate each P-V pair
%     % Validate useParams.NumPackets
%     validateattributes(useParams.NumPackets,{'numeric'},{'scalar','integer','>=',0},mfilename,'''NumPackets'' value');
%     % Validate useParams.IdleTime
%     validateattributes(useParams.IdleTime,{'numeric'},{'scalar','real','>=',0},mfilename,'''IdleTime'' value');
%     if isEDMG
%         minIdleTime = 1e-6;
%     else % S1G, VHT, HT, non-HT
%         minIdleTime = 2e-6;
%     end
%     coder.internal.errorIf((useParams.IdleTime > 0) && (useParams.IdleTime < minIdleTime),'nist:wlanWaveformGenerator:InvalidIdleTimeValue',sprintf('%1.0d',minIdleTime));
%     % Validate scramblerInit
%     if isEDMG && any(useParams.ScramblerInitialization~=93)
%         if wlan.internal.isDMGExtendedMCS(cfgFormat.MCS)
%             % At least one of the initialization bits must be
%             % non-zero, therefore determine if the pseudorandom
%             % part can be 0 given the extended MCS and PSDU length.
%             if all(wlan.internal.dmgExtendedMCSScramblerBits(cfgFormat)==0)
%                 minScramblerInit = 1; % Pseudorandom bits cannot be all zero
%             else
%                 minScramblerInit = 0; % Pseudorandom bits can be all zero
%             end
%             coder.internal.errorIf(any((useParams.ScramblerInitialization<minScramblerInit) | (useParams.ScramblerInitialization>31)),'wlan:wlanWaveformGenerator:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31);
%         else
%             coder.internal.errorIf(any((useParams.ScramblerInitialization<1) | (useParams.ScramblerInitialization>127)),'wlan:wlanWaveformGenerator:InvalidScramblerInitialization','SC/OFDM',1,127);
%         end
%         overrideObjectScramInit = true;
%     end
%     % Validate WindowTransitionTime
%     if isEDMGOFDM 
%         % Set maximum limits for windowing transition time based on bandwidth and format
%         maxWinTransitTime = 9.6969e-08; % Seconds
%         validateattributes(useParams.WindowTransitionTime,{'numeric'},{'real','scalar','>=',0,'<=',maxWinTransitTime},mfilename,'''WindowTransitionTime'' value');
%     end 
end
windowing = isEDMGOFDM && useParams.WindowTransitionTime > 0;

% isEDMG
numUsers = cfgEDMG.NumUsers;

% Cross validation
coder.internal.errorIf(all(size(useParams.ScramblerInitialization,2) ~= [1 numUsers]),'wlan:wlanWaveformGenerator:ScramInitNotMatchNumUsers');

psduLength = cfgEDMG.PSDULength;

% Validate that data bits are present if PSDULength is nonzero
if iscell(dataBits) % SU and MU
    % Data must be a scalar cell or a vector cell of length Nu
    coder.internal.errorIf(~isvector(dataBits) || all(length(dataBits) ~= [1 numUsers]), 'wlan:wlanWaveformGenerator:InvalidDataCell');
    
    for u = 1:length(dataBits)
        if ~isempty(dataBits{u}) && (psduLength(u)>0) % Data packet
            validateattributes(dataBits{u},{'double','int8'},{'real','integer','vector','binary'},mfilename,'each element in cell data input');
        else
            % Empty data check if not NDP
            coder.internal.errorIf((psduLength(u)>0) && isempty(dataBits{u}),'wlan:wlanWaveformGenerator:NoData');
        end
    end
    if isscalar(dataBits) 
        % Columnize and expand to a [1 Nu] cell
        dataCell = repmat({int8(dataBits{1}(:))},1,numUsers);
    else % Columnize each element
        numUsers = numel(dataBits); % One cell element per user
        dataCell = repmat({int8(1)},1,numUsers); 
        for u = 1:numUsers                
            dataCell{u} = int8(dataBits{u}(:));
        end
    end
else % SU and MU: Data must be a vector
    if ~isempty(dataBits) && any(psduLength > 0) % Data packet
        validateattributes(dataBits,{'double','int8'},{'real','integer','vector','binary'}, mfilename,'Data input');

        % Columnize and expand to a [1 Nu] cell
        dataCell = repmat({int8(dataBits(:))}, 1, numUsers);
    else % NDP
        % Empty data check if not NDP
        coder.internal.errorIf(any(psduLength > 0) && isempty(dataBits),'wlan:wlanWaveformGenerator:NoData');

        dataCell = {int8(dataBits(:))};
    end
end

% Number of bits in a PSDU for a single packet (convert bytes to bits)
numPSDUBits = psduLength*8;

% Repeat to provide initial state(s) for all users and packets
scramInit = repmat(useParams.ScramblerInitialization,1,numUsers/size(useParams.ScramblerInitialization,2)); % For all users
pktScramInit = scramInit(mod((0:useParams.NumPackets-1).',size(scramInit,1))+1, :);

% Get the sampling rate of the waveform
if isEDMGOFDM
    sr = 2640e6;
else
    % isEDMGSC
    sr = 1760e6;
end
numTxAnt = cfgEDMG.NumTransmitAntennas;    % To be checked
numPktSamples = s.NumPPDUSamples(1);    % Modified to use first column, To be checked

nonedmgFields = [wlan.internal.dmgSTF(cfgEDMG); wlan.internal.dmgCE(cfgEDMG)];
if isEDMGOFDM
    % In OFDM PHY preamble fields are resampled to OFDM rate
    nonedmgPreamble = edmgTDCyclicShift(wlan.internal.dmgResample(...
       nonedmgFields), cfgEDMG);
    edmgPreamble =  [edmgSTF(cfgEDMG); edmgCE(cfgEDMG)];
    % No brfield
else
    % isEDMGSC
    nonedmgPreamble = edmgTDCyclicShift(nonedmgFields, cfgEDMG); % Add by snb28
    edmgPreamble = [edmgSTF(cfgEDMG); edmgCE(cfgEDMG)];   % Add by snb28
    % No brfield
end

if windowing
    % Calculate parameters for windowing
    % IdleSample offset due to windowing
    wlength = 2*ceil(useParams.WindowTransitionTime*sr/2);
    bLen = wlength/2; % Number of samples overlap at the end of the packet
    % isEDMG
    % No waveform extension for the non-OFDM fields in the preamble
    aLen = 0;
    % No waveform extension due to windowing when BRP field is present
    bLen = bLen*(~wlan.internal.isBRPPacket(cfgEDMG));
    windowedPktLength = numPktSamples+bLen;
else
    % Define unused windowing variables for codegen
    wlength = 0;
    windowedPktLength = numPktSamples+wlength-1;
    aLen = 0;
    bLen = 0;
end

% Define a matrix of total simulation length
numIdleSamples = round(sr*useParams.IdleTime);
pktWithIdleLength = numPktSamples+numIdleSamples;
txWaveform = complex(zeros(useParams.NumPackets*pktWithIdleLength,numTxAnt));

for i = 1:useParams.NumPackets
    % Extract PSDU for the current packet
    psdu = getPSDUForCurrentPacket(dataCell, numPSDUBits, i);
    
    % Generate the PSDU with the correct scrambler initial state
    % Header and data scrambled so generate for each packet together
    % Override scrambler initialization in configuration object if supplied by the user to the waveform generator
    if overrideObjectScramInit
        cfgEDMG.ScramblerInitialization = pktScramInit(i,:);
    end

    lHeader = edmgTDCyclicShift(nist.edmgLHeader(psdu,cfgEDMG) ,cfgEDMG);
    nonedmgPortion = [nonedmgPreamble; lHeader];
    if isEDMGOFDM
        fieldLength = 1088*3/2;
    else % SC
        if cfgEDMG.NumUsers>1
            fieldLength = 1088;
        else
            fieldLength = 1024;
        end
    end
    edmgHeaderA = zeros(fieldLength,cfgEDMG.NumTransmitAntennas); % +++SB To add in future releases
    if cfgEDMG.NumUsers>1
        if isEDMGOFDM
            edmgHeaderB = zeros(512+edmgGIInfo(cfgEDMG), cfgEDMG.NumTransmitAntennas);%  +++SB To add in future releases
        else
            edmgHeaderB = zeros(512, cfgEDMG.NumTransmitAntennas);%  +++SB To add in future releases
        end
    else
        edmgHeaderB = [];
    end
    edmgPortion = [edmgHeaderA; edmgPreamble; edmgHeaderB];
    preamble = [nonedmgPortion; edmgPortion];

    

    % Construct packet from preamble and data, without brfields
    if isEDMGSC
        if sum(cfgEDMG.NumSpaceTimeStreams)>1
            switch cfgEDMG.SpatialMappingType
                case 'Custom'
                    if cfgEDMG.NumUsers==1
                        % SC SU-MIMO
                        data = nist.edmgData(psdu,cfgEDMG);
                        packet = [preamble; data];
                    else
                        % In SC MU-MIMO preamble and data are filter through a time domain
                        % precoder and the precoded sequence is stored in data.
                        data = nist.edmgData(psdu,cfgEDMG,'preamble',edmgPortion);
                        packet = [nonedmgPortion; data];
                    end
                case 'Direct'
                    if all(cellfun(@isempty,psdu))
                        data = [];
                    else
                        data = nist.edmgData(psdu,cfgEDMG);
                    end
                    % For channel sounding
                    packet = [preamble; data];         % without brfields

            end
        elseif sum(cfgEDMG.NumSpaceTimeStreams) == 1
            data = nist.edmgData(psdu,cfgEDMG);
            packet = [preamble; data];         % without brfields
        end
    elseif isEDMGOFDM
        if all(cellfun(@isempty,psdu))
            data = [];
        else
            data = nist.edmgData(psdu,cfgEDMG);
        end
        packet = [preamble; data];        % without brfields
    end
        
    if windowing
        % Window each packet
        if isEDMG
            %             windowedPacket = nist.edmgWindowing(packet, wlength, cfgFormat);    % To be checked
            windowedPacket = packet;
        end
        
        % Overlap-add the windowed packets
        if useParams.NumPackets==1 && numIdleSamples==0 % Only one packet which wraps
            txWaveform = windowedPacket(aLen+(1:numPktSamples), :);
            % Overlap start of packet with end
            txWaveform(1:bLen,:) = txWaveform(1:bLen,:)+windowedPacket(end-bLen+1:end,:);
            % Overlap end of packet with start
            txWaveform(end-aLen+1:end,:) = txWaveform(end-aLen+1:end,:)+windowedPacket(1:aLen,:);
        else
            if i==1 % First packet (which wraps)
                % First packet wraps to end of waveform
                txWaveform(1:(numPktSamples+bLen),:) = windowedPacket(1+aLen:end,:);
                txWaveform(end-aLen+1:end,:) = windowedPacket(1:aLen,:);
            elseif i==useParams.NumPackets && numIdleSamples==0 % Last packet which wraps
                % Last packet wraps to start of waveform
                startIdx = (i-1)*pktWithIdleLength-aLen+1;
                txWaveform(startIdx:end,:) = txWaveform(startIdx:end,:)+windowedPacket(1:end-bLen,:);
                txWaveform(1:bLen,:) = txWaveform(1:bLen,:)+windowedPacket(end-bLen+1:end,:);
            else % Packet does not wrap
                % Normal windowing overlap between packets
                idx = (i-1)*pktWithIdleLength-aLen+(1:windowedPktLength);
                txWaveform(idx,:) = txWaveform(idx,:)+windowedPacket;
            end
        end
    else
        % Construct entire waveform
        numPktSamples = length(packet);% +++SB define values based on scenarios
        txWaveform((i-1)*pktWithIdleLength+(1:numPktSamples),:) = packet;
    end
end
end

function psdu = getPSDUForCurrentPacket(dataCell,numPSDUBitsPerPacket,packetIdx)
    numUsers = length(dataCell); % == length(numPSDUBits)
    psdu = repmat({int8(1)},1,numUsers); % Cannot use cell(1, numUsers) for codegen
    for u = 1:numUsers
        idx = mod((packetIdx-1)*numPSDUBitsPerPacket(u)+(0:numPSDUBitsPerPacket(u)-1).',length(dataCell{u})) + 1;
        psdu{u} = dataCell{u}(idx);
    end
end

function y = windowingFunction(x,samplesPerSymbol,cpPerSymbol,wLength,Nt)
    % windowingFunction(...) returns the time-domain windowed signal for
    % the OFDM signal. The windowing function for OFDM waveform is defined
    % in IEEE Std 802.11-2016.
    assert(size(x,1)==sum(samplesPerSymbol));
    assert(all(size(cpPerSymbol)==size(samplesPerSymbol)));

    % Window length must be less than or equal to twice the CP length (ignore zeros)
    coder.internal.errorIf(wLength>(2*min(cpPerSymbol(cpPerSymbol>0))), ...
        'wlan:wlanWindowing:InvalidWindowLength');

    Ns = size(x,1); % Number of samples
    Nsym = size(samplesPerSymbol,2); % Number of OFDM symbols

    % Allocate output, the extra samples allow for rampup and down
    y = complex(zeros(Ns+wLength-1,Nt));

    % Offset in samples of each OFDM symbol
    startOffset = cumsum([0 samplesPerSymbol]);

    % For each OFDM symbol extract the portions which overlap, cyclic extend
    % and apply windowing equation. Preallocate additional first and last to
    % create rampup and rampdown
    prefixOverlap = complex(zeros(wLength-1,Nsym+2,Nt));
    postfixOverlap = complex(zeros(wLength-1,Nsym+2,Nt));
    if coder.target('MATLAB')
        for i = 1:Nsym
            % Standard defined windowing equation for each sample in extended
            % symbol
            [~,w] = wlan.internal.windowingEquation(wLength,samplesPerSymbol(i));

            % Extract data symbol
            dataSym = x(startOffset(i)+(1:samplesPerSymbol(i)),:);

            % Extend the symbol with a prefix to create the desired window
            % transition and apply windowing equation
            prefixOverlap(:,i+1,:) = permute( ...
                [dataSym((1:(wLength/2-1))+(samplesPerSymbol(i)-cpPerSymbol(i)-(wLength/2-1)),:); ...
                dataSym(1:(wLength/2),:)], ...
                [1 3 2]).*w(1:(wLength-1));

            % Extend the symbol with a postfix to create the desired window
            % transition and apply windowing equation
            postfixOverlap(:,i+1,:) = permute( ...
                [dataSym(end-(wLength/2-1)+(1:(wLength/2-1)),:); ...
                dataSym(cpPerSymbol(i)+(1:wLength/2),:)], ...
                [1 3 2]).*w(end-(wLength-2):end);
        end
    else
        for i = 1:Nsym
            % Standard defined windowing equation for each sample in extended
            % symbol
            [~,w] = wlan.internal.windowingEquation(wLength,samplesPerSymbol(i));

            % Extract data symbol
            dataSym = x(startOffset(i)+(1:samplesPerSymbol(i)),:);

            % Extend the symbol with a prefix to create the desired window
            % transition and apply windowing equation
            for j = 1:Nt
                prefixOverlap(:,i+1,j) = permute( ...
                    [dataSym((1:(wLength/2-1))+(samplesPerSymbol(i)-cpPerSymbol(i)-(wLength/2-1)),j); ...
                    dataSym(1:(wLength/2),j)], ...
                    [1 3 2]).*w(1:(wLength-1));

                % Extend the symbol with a postfix to create the desired window
                % transition and apply windowing equation
                tmp = w(end-(wLength-2):end);
                postfixOverlap(:,i+1,j) = permute( ...
                    [dataSym(end-(wLength/2-1)+(1:(wLength/2-1)),j); ...
                    dataSym(cpPerSymbol(i)+(1:wLength/2),j)], ...
                    [1 3 2]).*tmp(1:(wLength-2+1));
            end
        end
    end

    % Overlap the prefix and postfix regions, note first prefix region
    overlap = prefixOverlap(:,2:end,:)+postfixOverlap(:,1:end-1,:);

    % First samples at output will be the rampup i.e. overlap with zeros
    y(1:wLength/2-1,:) = overlap(1:wLength/2-1,1,:);

    % Construct windowed symbols from overlap regions and symbol samples
    for i = 1:Nsym
        % Extract symbol from input
        dataSym = x(startOffset(i)+(1:samplesPerSymbol(i)),:);

        % Extract start, middle and end portions and store
        startPortion = permute(overlap(wLength/2:end,i,:),[1 3 2]);
        middlePortion = dataSym((wLength/2)+1:end-(wLength/2-1),:);
        endPortion = permute(overlap(1:(wLength/2-1),i+1,:),[1 3 2]);
        idx = wLength/2-1+startOffset(i)+(1:samplesPerSymbol(i));
        y(idx,:) = [startPortion; middlePortion; endPortion];
    end

    % Last samples output will be rampdown i.e. overlap with zeros
    idx = wLength/2-1+startOffset(Nsym+1)+(1:wLength/2);
    y(idx,:) = permute(overlap(wLength/2:end,Nsym+1,:),[1 3 2]);
end