function [NGI,TGI] = edmgGIInfo(cfgEDMG,varargin)
%edmgGIInfo Get different types of guard interval duration and sample length for both EDMG OFDM and SC modes 
% Input
%   cfgEDMG is EDMG system object
% Outputs
%   NGI: GI length in samples
%   TGI: GI duration in seconds

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(1,2);
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');
if nargin>1
    assert(ismember(varargin{1},{'Short','Normal','Long'}),'force to a given type.');
    giType = varargin{1};
else
    giType = cfgEDMG.GuardIntervalType;
end

if strcmp(cfgEDMG.PHYType,'SC')
    % Draft P802.11ay D7.0 Table 28-47 EDMG SC mode timing related parameters
    if strcmp(giType,'Short')
        nGI = 32;
        tGI = 18.18e-9; % seconds
    elseif strcmp(giType,'Normal')
        nGI = 64;
        tGI = 36.36e-9; % seconds
    elseif strcmp(giType,'Long')
        nGI = 128;
        tGI = 72.72e-9; % seconds
    else
        error('GI type of SC should be one of Short, Normal, Long.');
    end
elseif strcmp(cfgEDMG.PHYType,'OFDM')
    % Draft P802.11ay D7.0 Table 28-62 EDMG OFDM mode timing related parameters
    if strcmp(giType,'Short')
        nGI = 48;
        tGI = 18.18e-9; % seconds
    elseif strcmp(giType,'Normal')
        nGI = 96;
        tGI = 36.36e-9; % seconds
    elseif strcmp(giType,'Long')
        nGI = 192;
        tGI = 72.72e-9; % seconds
    else
        error('GI type of SC should be one of Short, Normal, Long.');
    end
else
    error('PHY type should be one of Control, SC or OFDM.');
end

NGI = nGI * cfgEDMG.NumContiguousChannels;
TGI = tGI;

end