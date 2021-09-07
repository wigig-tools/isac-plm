function out = compensateFrequencyOffset(in,  foffset, varargin)
%COMPENSATEFREQUENCYOFFSET compensate the frequency offset on the input signal
%
%   OUT = COMPENSATEFREQUENCYOFFSET(IN, FOFFSET) applies the specified
%   frequency offset to the input signal.
%
%   OUT is the frequency-offset  compensated output of the same size as IN.
%   IN is the complex 2D array input.
%   FOFFSET is the normalized frequency offset to apply to the input.
%
%   OUT = COMPENSATEFREQUENCYOFFSET(IN, FOFFSET, DELAY) applies the     
%   specified frequency offset to the input signal starting with an intial 
%   phase shift.

%   2020~2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

if isempty(varargin)
    delay = 0;
else
    delay = varargin{1};
end
out = zeros(size(in));

t = (delay + (0:length(in)-1).');
for i = 1:size(in, 2)
    out(:, i) = in(:, i) .* exp(-1j*2*pi*foffset*t);
end


end