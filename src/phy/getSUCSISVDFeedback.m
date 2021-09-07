function [U,S,V] = getSUCSISVDFeedback(chanEst,mode)
%getSUCSISVDFeedback Computes the channel state information (CSI) feedback matrix of individual user for each subcarrier based on 
%   Singular value decomposition (SVD).
%
% Inputs
%   chanEst is 2D  Nsts-by-Nr or 3D Nst-by-Nsts-by-Nr channel matrix
%   mode is label of '2D' or '3D'
% Outpus
%   U is numST-by-numRx-by-numRx matirx holding left singular vector for combiner
%   S is numST-by-numRx-by-numRx matirx holding singular values for power allocation
%   V is numST-by-numSTS-by-numRx matrix holding right singular vector for precoder
    
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if strcmp(mode,'2D')
    % chanEst Nsts-by-Nr
%     [numSTS,numRx] = size(chanEst);
    chanEstPerm = permute(chanEst, [2 1]); % Nr-by-Nsts
    % Compute the feedback matrix using singular value decomposition
    % for the streams allocated to the user
    [U, S, V] = svd(chanEstPerm, 'econ');
elseif strcmp(mode,'3D')
    % chanEst Nst-by-Nsts-by-Nr
    [numST,numSTS,numRx] = size(chanEst);
    chanEstPerm = permute(chanEst, [3 2 1]); % Nr-by-Nsts-by-Nst
    % Compute the feedback matrix using singular value decomposition
    % for the streams allocated to the user
    U = complex(zeros(numST, numRx, numRx)); % Nst-by-Nr-by-Nr
    S = complex(zeros(numST, numRx, numRx)); % Nst-by-Nr-by-Nr
    V = complex(zeros(numST, numSTS, numRx)); % Nst-by-Nsts-by-Nr
    for i = 1:numST
        [U(i,:,:), S(i,:,:), V(i,:,:)] = svd(chanEstPerm(:,:,i), 'econ');
    end
    % mat = V;
else
    if ismatrix(chanEst)
        % chanEst Nsts-by-Nr
    %     [numSTS,numRx] = size(chanEst);
        chanEstPerm = permute(chanEst, [2 1]); % Nr-by-Nsts
        % Compute the feedback matrix using singular value decomposition
        % for the streams allocated to the user
        [U, S, V] = svd(chanEstPerm, 'econ');
    elseif ndims(chanEst) == 3
        % chanEst Nst-by-Nsts-by-Nr
        [numST,numSTS,numRx] = size(chanEst);
        chanEstPerm = permute(chanEst, [3 2 1]); % Nr-by-Nsts-by-Nst
        % Compute the feedback matrix using singular value decomposition
        % for the streams allocated to the user
        U = complex(zeros(numST, numRx, numRx)); % Nst-by-Nr-by-Nr
        S = complex(zeros(numST, numRx, numRx)); % Nst-by-Nr-by-Nr
        V = complex(zeros(numST, numSTS, numRx)); % Nst-by-Nsts-by-Nr
        for i = 1:numST
            [U(i,:,:), S(i,:,:), V(i,:,:)] = svd(chanEstPerm(:,:,i), 'econ');
        end
        % mat = V;
    end
end

end

% [EOF]
