function EDMG_CEF= edmgCEFSeq(i_stf_vec, varargin)
%EDMG_CEF= EDMGCEFSEQ returns EDMG-CEF tones as defined
% in Table 157 through Table 164 of IEEE P802.11ay/D4.0. 
% 
% 
%   2019~2021 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

NCB  = 1;

for  n = 1:length(i_stf_vec)
    
    i_stf = i_stf_vec(n);
    % Following procedure needs further investigation.
    % doc.: IEEE 802.11-17/0595r0
    if 0
        W_k = [1  -1 1j -1j; ...
            -1j  1 -1j -1j; ...
            1 -1j +1 -1j; ...
            -1  1  -1 -1j; ...
            1  1j -1 -1j; ...
            -1  1j +1 -1j; ...
            1j -1j -1j -1j; ...
            1  1 +1j -1j; ...
            ]; %#ok<UNRCH>
        
        A{1} = [1 +1j +1j -1 -1j 1j -1 1 -1 +1j 1]; %A_0
        B{1} = [-1 1 -1 +1j +1 +1 -1j -1j -1j +1 +1];%B_0
        
        for k = 1:4
            A{k+1} = [W_k(i_stf, k)*A{k},  B{k}];
            B{k+1} = [W_k(i_stf, k)*A{k}, -B{k}];
        end
        
        SeqLeft = B{5};
        SeqRight = A{5};
    end
    
    SeqLeft = generateSeqLeft(i_stf, NCB);
    SeqRight = generateSeqRight(i_stf, NCB);
    
    
    EDMG_CEF(:,n)  = [SeqLeft, SeqRight];
end
end