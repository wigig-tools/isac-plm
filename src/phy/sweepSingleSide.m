function [Hbft,  bfvec2] = sweepSingleSide(H,bfvec1, cb, side, varargin)
%%SWEEPSINGLESIDE Analog beamforming sweep
%
%      [Heq,  bfvec] = SWEEPSINGLESIDE(H,bfvec1, cb, side) applies the
%      analog beamforming relative to the angles in the codebook cb on the
%      full digital channel H. The analog beamforming is applied as
%      specified by the string side, on the 'tx' or the 'rx'. On the other
%      side of the link the beamforming vector bfvec1 is applied.
%      The function returns the equivalent channel Heq for each analog
%      beamforming and the relative beamforming vectors%

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

p = inputParser;
addParameter(p,'paa', [1 1]);

parse(p, varargin{:});
paaNodes  = p.Results.paa;

time = size(H,1);

%% Get beamforming vectors

bfvec2 =  getRxBeamformingVectors(cb,'paa', paaNodes);

for t = 1:time
    Ht = H{t};
    switch side
        case 'tx'
            Hbft(1,1,:,:,:) = applyAwv(Ht, bfvec2/sqrt(size(bfvec2,1)), bfvec1/sqrt(size(bfvec1,1)));
        case 'rx'
            Hbft(1,1,:,:,:) = applyAwv(Ht, bfvec1/sqrt(size(bfvec1,1)), bfvec2/sqrt(size(bfvec2,1)));

    end
end

end