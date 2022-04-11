function [rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks, varargout] = ...
    edmgRxIdeal(rxDpSigSeq, simulationParams, phyParams, cfgSim, tdMimoChan, fdMimoChan)
%edmgRxIdeal EDMG PSDU recevier waveform generator interface
%   This function provides the interface of recovering the receiver waveforms for the EDMG PSDU format
%   (data-field of PPDU) with perfect channel estimation and synchronization.
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
%   2019-2021 NIST/CTL Jiayi.zhang

%   This file is available under the terms of the NIST License.

%#codegen

% Data Field Only
if strcmpi(phyParams.phyMode, 'OFDM')
    estCIRDp = [];
    estCFRDp = fdMimoChan;
else
    % SC mode
    estCIRDp = tdMimoChan;
    estCFRDp = [];
end

estNoiseVarDp = cell(phyParams.numUsers,1);
noiseVarLinTotSubc = simulationParams.noiseVarLin.TotSubc;
for iUser = 1:phyParams.numUsers
    if isscalar(noiseVarLinTotSubc)
        estNoiseVarDp{iUser} = noiseVarLinTotSubc * ones(1,phyParams.numSTSVec(iUser));
    elseif isvector(simulationParams.noiseVarLin.TotSubc) && length(noiseVarLinTotSubc)==phyParams.numUsers
        estNoiseVarDp{iUser} = noiseVarLinTotSubc(iUser) * ones(1,phyParams.numSTSVec(iUser));
    else
        error('The format of noiseVarLin.TotSubc is incorrect.');
    end
end

startOffsetDp = [];
cfOffset = [];

%% Data Processing at MIMO Receiver
[rxDpPsdu,detSymbBlks,eqSymbGrid,rxDataGrid,rxDataBlks] = edmgRxMIMOData(rxDpSigSeq,phyParams,simulationParams, ...
    estCIRDp,estCFRDp,estNoiseVarDp,startOffsetDp,cfOffset,phyParams.precScaleFactor,phyParams.svdChan);

varargout{1} = eqSymbGrid;

end