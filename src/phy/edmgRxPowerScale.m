function [y,csi] = edmgRxPowerScale(x,cfgEDMG,scaleFactor,varargin)
%edmgRxPowerScale The receiver power scaling operation for EDMG OFDM and SC modes. For SISO-OFDM, the receiver power
%   of x is scaled if transmit pre-equalization is adopted. For MIMO-OFDM and SC modes, the receiver power is scaled when 
%   transmitter precoding is adopted.
%   Input:
%       x is received signal. In OFDM mode, x is a numSD-by-numBlock-by-numSTS matrix. numSD is number of activated subcarrier 
%           for data transsmissions. numSTS is the number of space-time streams and it becomes 1 in SISO scenario.
%       cfgEDMG is the configuration object of EDMG transmission.
%       scaleFactor is a normalization factor of precoder, it can be a numActiveSub-length vector for OFDM; or
%       a scalar for SC.
%       varargin is option for place holding.
%   Output:
%       y is a scaled version of x, with the same size of x.
%       csi is the power coefficiencts of scaling factor with size of numSD-by-numSTS.
%
%   2020~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(3,4);

if nargin == 4
    eqMimoChan = varargin{1};
end

[numDataSubc,~,numSTS] = size(x);
y = zeros(size(x));
csi = ones(numDataSubc,numSTS);

if isscalar(scaleFactor)
    y = x ./ scaleFactor;
else
    if strcmp(cfgEDMG.PHYType,'OFDM')
        [ofdmInfo,~,ofdmCfg] = nist.edmgOFDMInfo(cfgEDMG);
        assert(numDataSubc==ofdmInfo.NSD,'numDataSubc of OFDM should be NSD.');
        for iSubc = 1:numDataSubc
            y(iSubc,:,:) = x(iSubc,:,:) ./ scaleFactor(ofdmCfg.DataIndices(iSubc));
            if nargin == 4
                subEqMimoChan = squeeze(eqMimoChan(iSubc,:,:));
                csi(iSubc,:) = diag(subEqMimoChan*subEqMimoChan');
            end
        end
    else
        scInfo = edmgSCInfo(cfgEDMG);
        assert(numDataSubc==scInfo.NFFT,'numDataSubc of SC should be NFFT.');
        for iSubc = 1:numDataSubc
            y(iSubc,:,:) = x(iSubc,:,:) ./ scaleFactor;
        end    
    end
end

end