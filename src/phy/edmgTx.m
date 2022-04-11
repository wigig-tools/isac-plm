function [txSigSeq,txPSDU] = edmgTx(cfgEDMG,simParams)
%edmgTx EDMG PPDU/PSDU transmiiter waveform generator
%   This function generates the transmiiter waveforms for either the EDMG PHY protocol data unit (PPDU) format or the
%   EDMG PHY service data unit (PSDU) format, i.e. PPDU data-field only format. Specifically, the EDMG PPDU format 
%   supports the non-data packet (NDP) or data packet (DP). Both the EDMG OFDM and SC PHY modes are supported.
%
%   Inputs
%       cfgEDMG: configuration object of nist.edmgConfig
%       cfgSim:  configuration structure of simulation parameters
%       varargin:   reservation for transmission delay and zero-padding for EDMG PPDU format.
%   Outputs
%       txSigSeq: transmitted EDMG PPDU/PSDU waveform sequence
%       txPSDU: txPSDU is the PHY service data unit input to the PHY. It is a double or int8 typed column vector of 
%               length cfgEDMG.PSDULength*8, with each element representing a bit.
%
%   2019-2020 NIST/CTL <jiayi.zhang@nist.gov>

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

narginchk(2,6);
pktFormatFlag = simParams.pktFormatFlag;
assert(ismember(pktFormatFlag, [0,1]), 'pktFormatFlag should be either 0 or 1.')
numBitsPerPkt = cfgEDMG.PSDULength*8;
numUsers = cfgEDMG.NumUsers;

%% Data processing at Transmitter
if pktFormatFlag == 0
    % Select flag for EDMG PPDU transmitted waveform generator
    %     if cfgEDMG.PSDULength == 0
    % NDP includes an empty PSDU
    %         txPSDU = [];
    % Generate an EDMG PPDU NDP transmitted waveform
    %         txSigSeq = nist.edmgWaveformGenerator(txPSDU,cfgEDMG);
    %     else
    % DP includes a non-empty PSDU
    delay = simParams.delay;
    zp = simParams.zeroPadding;
    txPSDU = cell(numUsers,1);
    for iUser = 1:numUsers
        % Create the transmitted PSDU per user
        txPSDU{iUser} = randi([0 1],numBitsPerPkt(iUser),1); % PSDULength in bytes
    end
    % Generate an EDMG PPDU DP transmitted waveform
    txSigSeq = nist.edmgWaveformGenerator(txPSDU,cfgEDMG);
    % Add delay and ZP to transmitted EDMG PPDU
    numSTSTot = sum(cfgEDMG.NumSpaceTimeStreams,2);
    txSigSeq = [zeros(delay,numSTSTot); txSigSeq; zeros(zp,numSTSTot)];
elseif pktFormatFlag == 1
    assert(all(cfgEDMG.PSDULength>0), 'cfgEDMG.PSDULength should be > 0');
    % Select flag for EDMG PSDU (data-field only) transmited waveform generator
    txPSDU = cell(numUsers,1);
    for iUser = 1:numUsers
        % Generate PSDU per uer
        txPSDU{iUser} = randi([0 1],numBitsPerPkt(iUser),1); % PSDULength in bytes
    end
    % Generate an EDMG PSDU (data-field only) transmited waveform
    txSigSeq = nist.edmgData(txPSDU,cfgEDMG);
end

end