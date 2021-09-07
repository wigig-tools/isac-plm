function est = edmgSTFNoiseEstimate(stf, mode)
%edmgSTFNoiseEstimate Estimate noise power using DMG-STF
%
%   EST = edmgSTFNoiseEstimate(STF, MODE) estimates the noise power in watts using the EDMG-STF symbols.

%   STF is a complex Ns-by-1 vector where Ns is the number of time domain
%   samples in the EDMG-STF. Both EDMG OFDM and SC PHY types are supported. 

%   Copyright 2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Steve Blandino

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,2);
nargoutchk(0,1);

validateattributes(stf, {'double'}, {'2d','finite'}, mfilename, 'signal input');

if strcmp(mode, 'OFDM')
    Nblks = 30;
else
    Nblks = 19;
end

L = Nblks*128; % Length of STF field of DMG SC PHY
if size(stf, 1) < L 
    est = [];
    return;
end

L = 128; % Block size
% Skip first block (use it as a GI) and ignore last block. Only 15 of the
% 17 blocks are used to estimate the noise power
Nblks = Nblks-2;
stfBlk = reshape(stf(1+L:end-L,:),L,Nblks,[]);

est = reshape(squeeze(sum(sum(abs(diff(stfBlk,[],2)).^2))./(L*(Nblks-1)*2)),1,[]);   

end