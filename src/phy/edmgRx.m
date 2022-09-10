function [syncError, rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks, cirEst]  = ...
    edmgRx(rxDpSigSeq, phyParams, simParams, varargin)
%%EDMGRX wrapper function 
%
%   See also EDMGRXFULL, EDMGRXIDEAL

%   2019-2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


%% Receiver processing
    if simParams.psduMode == 0
        %Full receiver
        [syncError, rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks, ~,cirEst] = ...
            edmgRxFull(rxDpSigSeq, phyParams, simParams);        
    else
        channel = varargin{1};   
        cirEst = channel.tdMimoChan;
        %Ideal receiver
        [rxDpPsdu,detSymbBlks,rxDataGrid,rxDataBlks] = ...
            edmgRxIdeal(rxDpSigSeq, simParams, phyParams, ...
            channel.tdMimoChan, channel.fdMimoChan);
    end