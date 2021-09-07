function y = dmgRxOFDMResample(x)
%dmgRxOFDMResample Filter preamble and BRP field in OFDM packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgResample(X) resamples and filters the preamble and BRP field in
%   DMG OFDM packet.
%
%   Y is the upsampled and filtered time-domain preamble or BRP field. It
%   is a complex matrix of size Ny-by-1, where Ny represents the number of
%   time-domain samples.
%
%   X is the time-domain preamble or BRP field. It is a complex matrix of
%   size Nx-by-1, where Nx represents the number of time-domain samples.

%   Copyright 2016 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Steve Blandino

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% If empty input then return empty output of same size
if isempty(x)
    y = complex(zeros(0,1));
    return
end

% Resample input signal: Std IEEE 802.11ad-2012, Section 21.3.6.4.1

% Upsample by 2
a = upsample(x,2);

% Filter
h = filterWeights;
K = numel(h);
b = filter(h,1,[a; zeros((K-1)/2-1,size(x,2))]);

% Downsample by 3
y = downsample(b((K-((K-1)/2)):end,:),3);
% y = yt(:,1); % For codegen

end

function out = filterWeights

% IEEE Std 802.11ad-2012, Section 21.3.6.4.2
h = [-1, 0, 1, 1, -2, -3, 0, 5, 5, -3, -9, -4, 10, 14, -1, -20, -16, 14, ...
     33, 9, -35, -42, 11, 64, 40, -50, -96, -15, 120, 126, -62, -256, ...
     -148, 360, 985, 1267, 985, 360, -148, -256, -62, 126, 120, -15, -96, ...
     -50, 40, 64, 11, -42, -35, 9, 33, 14, -16, -20, -1, 14, 10, -4, -9, ...
     -3, 5, 5, 0, -3, -2, 1, 1, 0, -1].';

% Normalized filter weights
out = (sqrt(3)*h)./sqrt(sum(abs(h).^2));

end
