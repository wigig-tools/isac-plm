function gainInt = sincInterp(gain,delay,n,w, firstMpc, varargin)
%%SINCINTERP    Ideal band limited interpolation
%
%   Y = SINCINTERP(X, T, N, W, T0) return the signal Y sampled at integer
%   spacings given the input signal X sampled at T. The lenght of Y is N.
%   The sampling time is computed from T0, with a sampling frequency of W
%   Hz.
%
%   Y = SINCINTERP(..., 'offset', O) specifies an offset of the sampling
%   time, such that the first sample is at T0-1/w*O.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Input processing
p = inputParser;
addParameter(p,'offset', 10);
parse(p, varargin{:});
offset = p.Results.offset;
gain = gain(:);

%% Dependent params
sampTime = 1/w;
startInterp =  firstMpc - offset*sampTime;

%% Interpolation
ts = startInterp:sampTime:startInterp+sampTime*(n-1);
[delay, id] = sort(delay, 'ascend');
gain = gain(id);
[Ts,T] = ndgrid(ts,delay);

gainInt= sinc((Ts - T)*w)*gain;

end