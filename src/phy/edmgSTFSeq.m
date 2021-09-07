function STF_TONES = edmgSTFSeq(i_stf, varargin)
%STF_TONES = EDMGSTFSEQ returns EDMG-STF tones as defined in IEEE P802.11ay/D7.0. 
% 
% 
%   2019-2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(1,2);
if nargin==1
    NCB = 1;
else
    NCB = varargin{1};
end

LENGTH_STF_TONES =  352*NCB;
STF_TONES_L = zeros(1,LENGTH_STF_TONES/2);
STF_TONES_R = zeros(1,LENGTH_STF_TONES/2);
s = [1 1 1 1 -1 -1 -1 -1];

W_k = [1  1; ...
    1 -1; ...
    -1 1; ...
    -1 -1; ...
    1  1; ...
    1 -1; ...
    -1 1; ...
    -1 -1; ...
    ];

A{1} = [1 +1j +1j -1 -1j 1j -1 1 -1 +1j 1]; %A_0
B{1} = [-1 1 -1 +1j +1 +1 -1j -1j -1j +1 +1];%B_0

for k = 1:2    
    A{k+1} = [W_k(i_stf, k)*A{k},  B{k}];    
    B{k+1} = [W_k(i_stf, k)*A{k}, -B{k}];
end

STF_TONES_L(mod(0:LENGTH_STF_TONES/2,4)==1) = A{3};
STF_TONES_R(mod(0:LENGTH_STF_TONES/2,4)==2) = B{3};
STF_TONES = [STF_TONES_L, s(i_stf)*STF_TONES_R]; % missig  zeros around DC to match spatial matrix dimension. Will be added later

end