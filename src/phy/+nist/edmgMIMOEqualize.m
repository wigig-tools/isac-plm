function [y, CSI, W] = edmgMIMOEqualize(x, chanEst, eqMethod, varargin)
%edmgMIMOEqualize Perform frequency-domain MIMO channel equalization. 
%
%   [Y, CSI, W] = edmgMIMOEqualize(X, CHANEST, eqMethod, varargin) performs equalization when X is not empty, 
%   by using the signal input X and the channel estimation input CHANEST, and returns the estimation of transmitted 
%   signal in Y, the soft channel state information in CSI and the equalization weight in W. 
%   By contrast, when X is empty, the function retures Y as empty, only CSI and W is calculated.
%   
%   Inputs:
%   The input X and CHANEST can be double precision 2-D matrices or 3-D arrays with real or complex values. 
%   When the input x is not empty, X is of size Nsd x Nsym x Nr, where Nsd represents the number of data subcarriers 
%   (frequency domain), Nsym represents the number of OFDM symbols (time domain), and Nr represents the number of 
%   receive antennas (spatial domain). 
%   CHANEST is of size Nsd x Nsts x Nr, where Nsts represents the number of space-time streams. 
%   eqMethod is the string of equalization method to be used:
%       'ZF' - The zero-forcing (ZF) method, 
%       'MMSE' - minimum-mean-square-error (MMSE) method,
%       'MF' - matched filter method.
%   VARARGIN{1} is the noise variance input NOISEVAR in a double precision, real, nonnegative scalar.
%
%   Outputs:
%   The double precision output Y is of size Nsd x Nsym x Nsts. Y is complex when either X or CHANEST is complex 
%   and is real otherwise. 
%   CSI is a real matrix of size Nsd-by-Nsts containing the soft channel state information.
%   W is complex-valued equalization weight matrix with size Nsd x Nr x Nsts.

%   Copyright 2015-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Input validation
narginchk(3, 4);

% validateattributes(x, {'double'}, {'3d','finite','nonempty'}, 'edmgMIMOEqualize:InSignal', 'signal input');
% validateattributes(chanEst, {'double'}, {'3d','finite','nonempty'}, 'edmgMIMOEqualize:ChanEst', 'channel estimation input');   
coder.internal.errorIf(~strcmp(eqMethod, 'ZF') && ~strcmp(eqMethod, 'MMSE') && ~strcmp(eqMethod, 'MF'), ...
    'nist:edmgMIMOEqualize:InvalidEqMethod');

if ~isempty(x)
    coder.internal.errorIf(size(x, 1) ~= size(chanEst, 1), 'nist:edmgMIMOEqualize:UnequalFreqCarriers');
    coder.internal.errorIf(size(x, 3) ~= size(chanEst, 3), 'nist:edmgMIMOEqualize:UnequalNumRx');
end

if strcmp(eqMethod, 'MMSE')
    narginchk(4,4);
%     validateattributes(varargin{1}, {'double'}, {'real','scalar','nonnegative','finite','nonempty'}, ...
%         'wlanEqualizer:noiseVarEst', 'noise variance estimation input'); 
    noiseVarEst = varargin{1};
else % ZF
    noiseVarEst = 0;
end

% Perform equalization
numSD  = size(chanEst, 1);
numTx  = size(chanEst, 2);
numRx  = size(chanEst, 3);

if ~isempty(x)
    numSym = size(x, 2);
    y = complex(zeros(numSD, numSym, numTx));
else
    y = [];
end

CSI = zeros(numSD, numTx); % Pre-allocation here for code generation
W = zeros(numSD, numRx, numTx);

if (numTx == 1 && numRx == 1)
    % SISO
    chanEstSISO = chanEst(:, 1, 1); % For codegen
    if strcmp(eqMethod, 'MF') % add MF
        CSI = ones(numSD,1);
    else
        CSI = real(chanEstSISO.*conj(chanEstSISO)) + noiseVarEst;
    end
    W = conj(chanEstSISO)./CSI;
    if ~isempty(x)
        y =  bsxfun(@times, x(:, :, 1), W);
    end
elseif (numTx == 1 && numRx > 1)
    % SIMO
    chanEstSIMO = chanEst(:, 1, :); % For codegen
    chanEst2D = reshape(chanEstSIMO, size(chanEst, 1), numRx);    
    if strcmp(eqMethod, 'MF') % add MF
        CSI = ones(size(diag(chanEst2D*chanEst2D')));
    else
        CSI = real(diag(chanEst2D*chanEst2D')) + noiseVarEst;
    end
    W = bsxfun(@rdivide, conj(chanEstSIMO), CSI);
    if ~isempty(x)
        y = bsxfun(@rdivide, sum(bsxfun(@times, x, conj(chanEstSIMO)), 3), CSI);
    end
elseif (numTx > 1 && numRx == 1) 
    % MISO
    chanEstMISO = chanEst(:, :, 1); % For codegen
    chanPower = real(chanEstMISO.*conj(chanEstMISO));
    if strcmp(eqMethod, 'ZF')
        CSI = chanPower; 
    elseif strcmp(eqMethod, 'MMSE') % Use Schur complement formula
        CSI = noiseVarEst + noiseVarEst*chanPower./ (bsxfun(@minus, sum(chanPower, 2), chanPower) + noiseVarEst);
    else
        % add MF
        CSI = ones(size(chanPower));
    end
    chanEstInv = bsxfun(@rdivide, conj(chanEstMISO), sum(chanPower, 2)+noiseVarEst);
    chanEstInvPermute = permute(chanEstInv, [1 3 2]);
    W = chanEstInvPermute;
    if ~isempty(x)
        y = bsxfun(@times, x(:, :, 1), chanEstInvPermute); % Indexing for codegen
    end
elseif (numTx > numRx) && strcmp(eqMethod, 'ZF') 
    % MIMO: singular channel matrix using ZF
    CSI = sum(real(chanEst .* conj(chanEst)), 3);
    for idx = 1:size(chanEst, 1)
        Wsubc = pinv(reshape(chanEst(idx,:,:), numTx, numRx));
        W(idx,:,:) = Wsubc;
        if ~isempty(x)
            y(idx, :, 1:numTx) = reshape(x(idx, :, :), numSym, numRx) * Wsubc; 
        end
    end
elseif strcmp(eqMethod, 'MF')
    % Add MIMO: Matched filtering
    numSym = size(x, 2);
    y = complex(zeros(size(x, 1), numSym, numTx));
    for idx = 1:size(chanEst, 1)
        H = reshape((chanEst(idx,:,:)), numTx, numRx);
        invH = eye(numTx);   % for MF
        Wsubc = H' * invH;
        W(idx,:,:) = Wsubc;
        CSI(idx, :)  = 1./real(diag(invH));
        if ~isempty(x)
            y(idx, :, 1:numTx) = reshape(x(idx, :, :), numSym, numRx) * Wsubc;
        end
    end
else
    % MIMO: numTx > numRx using MMSE or numTx <= numRx using ZF or MMSE
    numSym = size(x, 2);
    y = complex(zeros(size(x, 1), numSym, numTx));
    for idx = 1:size(chanEst, 1)
        H = reshape((chanEst(idx,:,:)), numTx, numRx);
        invH = inv(H*H'+noiseVarEst*eye(numTx));
        Wsubc = H' * invH;
        W(idx,:,:) = Wsubc;
        CSI(idx, :)  = 1./real(diag(invH));
        if ~isempty(x)
            y(idx, :, 1:numTx) = reshape(x(idx, :, :), numSym, numRx) * Wsubc;
        end
    end
end

end
