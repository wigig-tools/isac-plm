function [syncError, rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks, varargout] = edmgRxFull(rxDpSigSeq, phyParams, simParams)
%edmgRxIdeal EDMG PPDU recevier waveform generator interface
%   This function provides the interface of recovering the receiver waveforms for the EDMG PPDU format
%   with impfect channel estimation and synchronization error.
% 
%   Inputs
%       rxSigSeq: received signal sequence held in numUsers-length cell array
%       simulationParams:  parameter struct of simulation configuration
%       phyParams: parameter struct of PHY configuration
%       cfgSim:  configuration structure of simulation parameters
%       tdMimoChan: time-domain MIMO channel impluse response (CIR) held in numUsers-length cell array
%       fdMimoChan: frequency-domain MIMO channel frequency response(CFR) held in numUsers-length cell array
%       
%   Outputs
%       syncError: synchronization error flag in false or true.
%       rxDpPsdu: the multiple users' PSDU after data bits recoveray at receiver held in numUsers-length cell array.
%       detSymbBlks:   the multiple user's data symbol blocks after MIMO detection/equalization at receiver held
%                       in numUsers-length cell array. The detDataSymbs of the SC mode is a time-domain data symbol
%                       block after frequency-domain detection/equalization; while the detDataSymbs of the OFDM mode
%                       is the same to eqSymbGrid.
%       rxDataGrid: the frequency-domain data-field symbol grid at receiver held in numUsers-length cell array.
%                   In SC mode, the rxDataGrid is the symbol grid after FFT operation; while in the OFDM mode,
%                   the rxDataGrid is the symbol grid after OFDM demodulation.
%       rxDataBlks: the time-domain data-field symbol block at SC receiver held in numUsers-length cell array.
%       varargout{1}: eqSymbGrid: the multiple user's data symbol block at frequency-domain after MIMO detection/equalization at
%                       receiver held in numUsers-length cell array.
%   
%   2019-2023 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

fieldIndices = nist.edmgFieldIndices(phyParams.cfgEDMG);
syncError = false;
rxDpPsdu = [];
detSymbBlks = [];
rxDataGrid = [];
rxDataBlks = [];
varargout{1} = [];
trn = [];
preambleDp = [];
if ~iscell(rxDpSigSeq) && isvector(rxDpSigSeq) && ~strcmp(phyParams.cfgEDMG.SensingType,'passive-beacon')
    rxDpSigSeqCell{1} = rxDpSigSeq;
    rxDpSigSeq = rxDpSigSeqCell;
end
cfgEDMG = phyParams.cfgEDMG;
%% Per User processing
% Data Field with STF/CTF
pktErrDp = cell(phyParams.numUsers,1);
startOffsetDp = cell(phyParams.numUsers,1);
estNoiseVarDp = cell(phyParams.numUsers,1);
estCIRDp = cell(phyParams.numUsers,1);
estCFRDp = cell(phyParams.numUsers,1);
cfOffset = cell(phyParams.numUsers,1);

syncMargin = phyParams.giLength-round(phyParams.symbOffset*phyParams.giLength);

for iUser = 1:phyParams.numUsers
    switch cfgEDMG.SensingType
        case 'passive-beacon'
            [pktErrDp{iUser}, startOffsetDp{iUser}, preambleDp] = dmgRxBeaconProcess(rxDpSigSeq, ...
                cfgEDMG, 'syncMargin', syncMargin);
        case {'passive-ppdu' , 'none'}
            [pktErrDp{iUser}, startOffsetDp{iUser}, preambleDp] = edmgRxPreambleProcess(rxDpSigSeq{iUser}, ...
                cfgEDMG,'userIdx', iUser, 'syncMargin', syncMargin);
            if pktErrDp{iUser} || (startOffsetDp{iUser}+fieldIndices.EDMGData(2) > size(rxDpSigSeq{iUser},1))
                syncError = true;
                varargout{1} = [];
                varargout{2} = [];
                return;
            end
        case 'bistatic-trn'
            [pktErrDp{iUser}, startOffsetDp{iUser}, preambleDp, trn] = edmgRxTrnProcess(rxDpSigSeq{iUser}, ...
                cfgEDMG,'userIdx',iUser, 'syncMargin', syncMargin);
            if pktErrDp{iUser}
                syncError = true;
                varargout{1} = [];
                varargout{2} = [];
                return;
            end
    end


    estNoiseVarDp{iUser} = 1./preambleDp.edmg.snrEst;
    if strcmpi(phyParams.phyMode, 'OFDM')
        estCFRDp{iUser} = reformatSUMIMOChannel(preambleDp.edmg.chanEst,'FD');
        cfOffset{iUser} = preambleDp.edmg.CFO;
        fullBandCfr = zeros(phyParams.ofdmInfo.NFFT, size(estCFRDp{iUser},2), size(estCFRDp{iUser},3));
        fullBandCfr(phyParams.activeSubcIdx,:,:) =estCFRDp{iUser} ;
        estCIRDp{iUser} = {ifft(fullBandCfr, [],1)};
    else
        % SC
        switch cfgEDMG.SensingType
            case 'passive-beacon'
                estCIRDp{iUser} = preambleDp.legacy.chanEstTd;
            case 'bistatic-trn'
                estCIRDp{iUser} = preambleDp.edmg.chanEst;
            case {'passive-ppdu' ,'none'}
                estCIRDp{iUser} = reformatSUMIMOChannel(preambleDp.edmg.chanEst,'TD');
        end
        estCFRDp{iUser} = [];
        cfOffset{iUser} = preambleDp.edmg.CFO;
    end
end

if any(ismember(["passive-ppdu", "none"], cfgEDMG.SensingType))
    if any(cell2mat(pktErrDp)) || ...
            any(cell2mat(startOffsetDp)+double(fieldIndices.EDMGData(2)) > ...
            cell2mat(cellfun(@(x) size(x,1), rxDpSigSeq, 'UniformOutput', false)))
        syncError = true;
        varargout{1} = [];
        varargout{2} = [];
        return;
    end
else
    syncError = cell2mat(pktErrDp);
end

%% Data Processing at MIMO Receiver
if any(ismember(["passive-ppdu", "none"], cfgEDMG.SensingType))
    [rxDpPsdu,detSymbBlks,eqSymbGrid,rxDataGrid,rxDataBlks] = edmgRxMIMOData(rxDpSigSeq,phyParams,simParams, ...
        estCIRDp,estCFRDp,estNoiseVarDp,startOffsetDp,cfOffset,phyParams.precScaleFactor,phyParams.svdChan);
else
    rxDpPsdu = []; detSymbBlks=[];eqSymbGrid=[];rxDataGrid=[];rxDataBlks=[];
end

varargout{1} = eqSymbGrid;
varargout{2} = estCIRDp;
varargout{3} = trn;
varargout{4} = preambleDp;
end