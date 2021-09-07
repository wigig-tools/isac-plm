function phyParams = setTxRxProcessParams(phyParams, varargin)
%setTxRxProcessParams Setup Tx/Rx signal processing
% Input
%   phyParams is a struct holding PHY parameters 
%   svdFlag (SVD Precoding flag):             = 0:Non, = 1:SVD(V-EPA/OPA), = 2:SVD(VS-SPA), = 3:SVD(BD)
%   powAlloFlag (Power allocation flag):      = 0: Non (EPA)
%   precAlgoFlag (Precoding algorithm flag):      = 0:Non, = 1:ZF, = 2:MMSE, = 3:MF
%   equiChFlag (Equivalent Channel Flag):     = 0:Non, = 1:H, = 2:H*V (H*Q), = 3:inv(S)*U
%   equaAlgoFlag (Equalization algorithm flag):   = 0:Non, = 1:ZF, = 2:MMSE, = 3:MF;
%   
% Output
%   phyParams is returned with update

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

switch phyParams.processFlag
    
    case 0
        % Rx detection/equalization only with ZF/MMSE
        phyParams.svdFlag = 0;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 0;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 1;
        phyParams.equaAlgoFlag = 2;    % 1;   % 2;
        
    case 1
        % Tx precoding with ZF/MMSE
        phyParams.svdFlag = 0;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 2;   % 1;   % 2;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 2;
        phyParams.equaAlgoFlag = 2;   % 1;   % 2;
        
    case 2
        % SU-MIMO Tx precoding with ZF/MMSE based V-matrix
        phyParams.svdFlag = 1;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 2;   % 1;   % 2;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 2;
        phyParams.equaAlgoFlag = 2;   % 1;   % 2;
        
    case 3
        % MU-MIMO Tx precoding with ZF/MMSE based V-matrix and singular value
        phyParams.svdFlag = 2;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 2;   % 1;   % 2;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 2;
        phyParams.equaAlgoFlag = 2;   % 1;   % 2;
        
    case 4
        % MU-MIMO Tx precoding with BD-ZF
        phyParams.svdFlag = 3;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 1;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 2;
        phyParams.equaAlgoFlag = 2;   % 1; %  2;
        
    case 5
        % SC MU-MIMO TD-Multi-Tap Tx precoding with polyMatConv        
        assert(strcmp(phyParams.phyMode,'SC'),'phyMode should be SC.')
        phyParams.svdFlag = 0;
        phyParams.powAlloFlag = 0;
        phyParams.precAlgoFlag = 5;
        phyParams.precNormFlag = 0;
        phyParams.equiChFlag = 3;
        phyParams.equaAlgoFlag = 2;   % 1;    % 2;

    otherwise
        % Custom
        error('processFlag should be 1~5.');
end

end