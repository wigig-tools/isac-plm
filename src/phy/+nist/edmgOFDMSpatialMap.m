function y = edmgOFDMSpatialMap(x,mappingType,mapMatrix,numTx,dataAndPilotIdx)
%edmgOFDMSpatialMap Spatial mapping for EDMG OFDM
%
%   Y = edmgOFDMSpatialMap(X, MAPPINGTYPE, MAPPINGMATRIX, NUMTX, NUMSTSVEC, DATAANDPILOTIDX, VARARGIN) performs spatial
%   mapping from space-time streams to transmit antennas.
%   
%   Inputs:
%   X is a FFTLen-by-numSym-by-numSTS or numST-by-numSym-by-numSTS matrix, where numSTS represents the number of 
%       space-time streams. When FFTLen is 512, the null subcarrier locations in EDMG portion of a waveform are 
%       assumed and enforced.
%   mappingType can be one of 'Direct', 'Hadamard', 'Fourier' and 'Custom'.
%   mapMatrix is a numSTS-by-NUMTX, FFTLen-by-numSTS-by-NUMTX or numST-by-numSTS-by-NUMTX spatial mapping matrix(ces) 
%       that apply only when the MAPPINGTYPE input is 'Custom'. 
%   numTx is the number of transmit antennas.
%   dataAndPilotIdx is an index vector of active subcarriers, which includes both data and pilots.
%   
%   Output:
%   Y is a FFTLen-by-numSym-by-NUMTX or numST-by-numSym-by-NUMTX matrix, where FFTLen represents the FFT length, 
%   numST represents the number of data plus pilot subcarriers, numSym represents the number of OFDM
%   symbols, and NUMTX represents the number of transmit antennas.

%   Copyright 2015-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% numCarriers can be either FFTLen or numST
[numCarriers,numSym,numSTS] = size(x);

% Add for EDMG
assert(isvector(dataAndPilotIdx),'dataAndPilotIdx should be a index list vector.');

% Initialize output
y = complex(zeros(numCarriers, numSym, numTx));

if isempty(mapMatrix) || isscalar(mapMatrix)
    y = x;
else
    % Section 20.3.10.11.1 in IEEE Std 802.11-2012.
    switch mappingType
      case 'Direct'
        y = x;
      case 'Hadamard'
        Q = hadamard(8);
        normQ = Q(1:numSTS, 1:numTx)/sqrt(numTx);
        xP = permute(x, [1 3 2]); % Permute to Nst-by-Nsts-by-Nsym
        for isym = 1:numSym
            y(dataAndPilotIdx, isym, :) = xP(dataAndPilotIdx, :, isym) * normQ;
        end
      case 'Fourier'
        % The following can be obtained from dftmtx(numTx) which however does not generate code
        [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
        normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
        xP = permute(x, [1 3 2]); % Permute to Nst-by-Nsts-by-Nsym
        for isym = 1:numSym
            y(dataAndPilotIdx, isym, :) = xP(dataAndPilotIdx, :, isym) * normQ;
        end
      otherwise  % case 'Custom'
        if size(mapMatrix, 1) <= 8
            % MappingMatrix is Nsts-by-Ntx
            xP = permute(x, [1 3 2]); % Permute to Nst-by-Nsts-by-Nsym
            % Precoder is already normalized.
            normQ = mapMatrix(1:numSTS, :);
            for isym = 1:numSym
                y(dataAndPilotIdx, isym, :) = xP(dataAndPilotIdx, :, isym) * normQ(:, 1:numTx); % index for codegen
            end
        else
            % MappingMatrix is Nst-by-Nsts-by-Ntx
            xP = permute(x, [2 3 1]); % Permute to Nsym-by-Nsts-by-Nst
            yP = complex(zeros(numSym, numTx, numCarriers));
            mappingMatrixP = permute(mapMatrix(: , 1:numSTS, :), [2 3 1]);
            for idx = 1:length(dataAndPilotIdx)
                    freqIdx = dataAndPilotIdx(idx);
                    Q = reshape(squeeze(mappingMatrixP(:, :, idx)),[numSTS numTx]);  
                    % Precoder is already normalized.
                    normQ = Q(1:numSTS,:); 
                    xTemp = reshape(squeeze(xP(1:numSym, 1:numSTS, freqIdx)),[numSym numSTS]);
                    yP(:, :, freqIdx) = xTemp(1:numSym,1:numSTS) * normQ(:,1:numTx);
            end
            y = permute(yP, [3 1 2]);
        end
    end
end

end

