function [gigabitRate] = getActualGigabitDataRate(perIndi,cfgEDMG,varargin)
% Calculate MCS-specfic throughput
%   Input
%   perIndi is a numSNR-by-numUsers PER matrix
%   cfgEDMG is an EDMG object
%   varargin{1} is an optional 1-by-numUsers MCS index
%   
%   Output
%   gigabitRate is numSNR-by-numUsers data rate matrix in Gigabit/sec

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(2,3);

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if nargin > 2
    mcsIndex = varargin{1};
    if ~isequal(cfgEDMG.MCS,mcsIndex)
        cfgEDMG.MCS = mcsIndex;
    end
end

mcsTable = nist.edmgMCSRateTable(cfgEDMG);
fs = nist.edmgSampleRate(cfgEDMG);
[numSNR,numUsers] = size(perIndi);
dataRateIndi = zeros(numSNR,numUsers);
if strcmp(cfgEDMG.PHYType,'OFDM')
    ofdmInfo = nist.edmgOFDMInfo(cfgEDMG);
    for u = 1:numUsers
        dataRateIndi(:,u) = mcsTable.NDBPS(u) * (1-perIndi(:,u)) * fs / ofdmInfo.NFFT;
%             dataRateIndi(:,u) = ofdmInfo.NSD * mcsTable.NBPSCS(u) * mcsTable.NSS(u) * mcsTable.Rate(u) * (1/mcsTable.Repetition(u)) ...
%                 * (1-perIndi(:,u)) * fs / ofdmInfo.NFFT;
    end
else
    % SC
    for u = 1:numUsers
        dataRateIndi(:,u) = mcsTable.NDBPS(u) * (1-perIndi(:,u)) * fs;
    end
end

gigabitRate = dataRateIndi * 1e-9;

end