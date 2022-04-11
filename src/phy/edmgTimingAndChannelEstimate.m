function [startOffset,cfrEst,cirEst] = edmgTimingAndChannelEstimate(preamble,fs, varargin)
%edmgTimingAndChannelEstimate EDMG single carrier symbol timing and channel estimation for OFDM and SC modes
%
%   [STARTOFFSET,CFREST,CIREST,VARARGOUT] = edmgTimingAndChannelEstimate(PREAMBLE,FS,VARARGIN) returns
%   the symbol timing offset, and the frequency domain channel estimate.
%   The symbol timing offset is selected to minimize the energy of the channel impulse response out with 
%   the guard interval. Both the SC PHY and OFDM PHY are supported.
% 
%   STARTOFFSET is the estimated offset between the first input sample of
%   PREAMBLE, and the start of the STF.
%
%   CFREST and CIREST are the complex column vectors of length 512 containing the
%   frequency- and time domain channel estimates, respectively, for each symbol in a block.
%
%   PREAMBLE is a complex column vector containing the EDMG-STF, EDMG-CE and EDMG header field symbols.

%   2020-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

p = inputParser;
addParameter(p, 'margin', 0)
parse(p, varargin{:});
margin = p.Results.margin;

if fs == 2.64e9
    [startOffset,cfrEst,cirEst] = edmgOFDMTimingAndChannelEstimate(preamble, 'margin', margin);
elseif fs == 1.76e9
    [startOffset,cfrEst,cirEst] = nist.edmgSCTimingAndChannelEstimate(preamble);
else
    error('fs should be either 2.64e9 or 1.76e9.');
end


end