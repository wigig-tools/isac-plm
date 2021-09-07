function [edmg_cef, edmg_stf, totalCFO] = edmgCFORecovery(edmg_preamble, coarseCFO, cfgEDMG)
%edmgCFORecovery compensates the CFO on edmg_stf and on edmg_cef and return the
% CFO estimated
%
%   [EDMG_CEF,EDMG_STF, TOTALCFO] = edmgCFORecovery(EDMG_PREAMBLE, COARSECFO, CFGEDMG) 
%   estimates the fine CFO and returns the total CFO.
%   In SC CFO is recovered from golay correlation in EDMG-CEF.
%   In OFDM CFO is recovered from EDMG-STF.
%   
%   2020~2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

fieldIndices = nist.edmgFieldIndices(cfgEDMG);
STFlen = fieldIndices.EDMGSTF(2)-fieldIndices.EDMGSTF(1)+1;
CEFlen = fieldIndices.EDMGCEF(2)-fieldIndices.EDMGCEF(1)+1;
edmg_stf = edmg_preamble(1:STFlen,:);
edmg_cef = edmg_preamble(STFlen+1:STFlen+CEFlen,:);

switch cfgEDMG.PHYType
    case 'SC'
        edmg_cef = compensateFrequencyOffset(edmg_cef,  coarseCFO);
        fineCFO = getFineCFOEstimateCEF(edmg_cef, cfgEDMG);
        edmg_cef = compensateFrequencyOffset(edmg_cef,fineCFO,1);

    case 'OFDM'
        edmg_stf= compensateFrequencyOffset(edmg_stf,coarseCFO);
        fineCFO = getFineCFOEstimateSTF(edmg_stf, cfgEDMG);
        edmg_cef = compensateFrequencyOffset(edmg_cef,  coarseCFO+fineCFO);
end

totalCFO = fineCFO+coarseCFO;

end