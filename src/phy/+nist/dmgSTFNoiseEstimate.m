function est = dmgSTFNoiseEstimate(stf)
%dmgSTFNoiseEstimate Estimate noise power using DMG-STF
%
%   EST = dmgSTFNoiseEstimate(STF) estimates the mean noise power in
%   watts using the DMG-STF symbols, assuming 1ohm resistance.
%
%   STF is a complex Ns-by-1 vector where Ns is the number of time domain
%   samples in the DMG-STF. Only DMG SC PHY type is supported. 

%   Copyright 2017 The MathWorks, Inc.

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,1);
nargoutchk(0,1);

validateattributes(stf, {'double'}, {'2d','finite'}, mfilename, 'signal input');

L = 2176; % Length of STF field of DMG SC PHY
if size(stf, 1) < L 
    est = [];
    return;
end

L = 128; % Block size
% Skip first block (use it as a GI) and ignore last block. Only 15 of the
% 17 blocks are used to estimate the noise power
Nblks = 15;
stfBlk = reshape(stf(1+L:end-L,:),L,Nblks,[]);
est = sum(sum(sum(abs(diff(stfBlk,[],2)).^2)))./(L*(Nblks-1)*2);

end