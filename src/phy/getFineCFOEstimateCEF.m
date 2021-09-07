function fineCFO = getFineCFOEstimateCEF(edmgCef, cfgEDMG)
%GETFINECFOESTIMATECEF estimate the fine carry-frequency offset (CFO) in SC mode.
%
%   fineCFO = getFineCFOEstimateCEF(EDMG_CEF_IN, cfgEDMG) 
%   returns the fine CFO.
%
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

NTX = cfgEDMG.NumTransmitAntennas;
NCB = cfgEDMG.NumContiguousChannels;
NRX = size(edmgCef,2);
fineCFO = zeros(NRX,NTX);
golayLen = 128*NCB;
GuvLen   = 4*golayLen;

m = 0;
for ists = 1:NTX
    
    [Ga, Gb] = nist.edmgGolaySequence(golayLen, ists);
    
    Gu_512 = [-Gb; -Ga; Gb; -Ga];
    Gv_512 = [-Gb; Ga; -Gb; -Ga];
    
    for irx = 1:NRX
        gucor = xcorr(edmgCef(:,irx), (Gu_512));
        gvcor = xcorr(edmgCef(:,irx), (Gv_512));
        
        [val, indx] =  max(abs(gucor(1:end-GuvLen)));
        rotAngle       = -angle(gucor(indx)*conj(gvcor(indx+GuvLen)));
        fineCFOtmp = rotAngle/(2*pi*GuvLen);
          
        if val>m
            fineCFO = fineCFOtmp;
            m = val;
        end
    end
end

end
