function out = edmgTDCyclicShift(in, cfgEDMG, varargin)
%WLANTDCYCLICSHIFT Cyclic shift delay insertion in time domain.
%
%   OUT = WLANTDCYCLICSHIFT(IN, cfgEDMG) applies a spatial expansion with cyclic
%   shift diversity with Nc equal to 4 (29.4.7.2.1)
%   Nc is the shift value in samples
%
%   OUT = WLANTDCYCLICSHIFT(IN, cfgEDMG, 'NC', NC) applies a cyclic shift of NC
%   samples
%
%   2019~2021 NIST/CTL, Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

%% Initial actions
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

p = inputParser;
addParameter(p,'NC', 4);
parse(p, varargin{:});
NC  = p.Results.NC;

N_TX = cfgEDMG.NumTransmitAntennas;

%% Spatial expansion
out = zeros(length(in), N_TX);
for i_tx = 1:N_TX
    out(:, i_tx) = circshift(in, (i_tx-1)*NC)/sqrt(N_TX);
end
end