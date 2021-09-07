function y = edmgSCSpatialMap(x,mappingType,mapMatrix,numTx,varargin)
%edmgSCSpatialMap Spatial mapping for EDMG SC
%
%   Y = edmgSCSpatialMap(X, MAPPINGTYPE, MAPPINGMATRIX, NUMTX, NUMSTSVEC, VARARGIN) performs spatial
%   mapping from space-time streams to transmit antennas.
%   
%   Inputs:
%   X is a numSym-by-numSTS matrix, where numSTS represents the number of space-time streams. 
%   mappingType can be one of 'Direct', 'Hadamard', 'Fourier' and 'Custom'.
%   mapMatrix is a numSTS-by-NUMTX or numSTS-by-NUMTX-by-numTaps spatial mapping matrix(ces) that apply only 
%       when the MAPPINGTYPE input is 'Custom'.        
%   numTx is the number of transmit antennas.
%   numSTSVec is the numUsers-length vecotr, each entry is the number of space-time streams of that user.
%   varargin are optional preamble or brfield.
%   
%   Output:
%   Y is a numSym-by-NUMTX matrix, where numSym represents the number of SC symbols.

%   Copyright 2015-2017 The MathWorks, Inc.
%   Revision 2020~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(4,8);
p = inputParser;
addParameter(p,'preamble', []);
addParameter(p,'brfield', []);

parse(p, varargin{:});
preamble = p.Results.preamble;
brfield  = p.Results.brfield;

[numChip,numSTS] = size(x);

if isempty(mapMatrix) || isscalar(mapMatrix)
    y = x;
elseif ismatrix(mapMatrix)
    % numSTS-by-NUMTX 2D precoding matirx
    % Initialize output
    y = complex(zeros(numChip,numTx));
    switch mappingType
        case 'Direct'
            y = x;
        case 'Hadamard'
            Q = hadamard(8);
            normQ = Q(1:numSTS, 1:numTx)/sqrt(numTx);
            for iChip = 1:numChip
                y(iChip,:) = x(iChip,:) * normQ;
            end
        case 'Fourier'
            % The following can be obtained from dftmtx(numTx) which however does not generate code
            [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
            normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
            for iChip = 1:numChip
                y(iChip,:) = x(iChip,:) * normQ;
            end
        otherwise  % case 'Custom'
            if size(mapMatrix,1)<=8
                % MappingMatrix is Nsts-by-Ntx
                % Precoder is already normalized.
                normQ = mapMatrix(1:numSTS,:); 
                for iChip = 1:numChip
                    y(iChip,:) = x(iChip,:) * normQ(:,1:numTx); % index for codegen
                end
            else
                error('NSTS is max of 8.');
            end
    end
elseif ndims(mapMatrix)==3
    % numSTS-by-NUMTX-by-numTaps 3D precoding matrix
    % Attach preamble and brfield when available and precode the whole PPDU. 
    x = [preamble; x; brfield];
    [numChip,~] = size(x);
    % Get the normalized precoder.
    normQ = mapMatrix(1:numSTS,:,:);     
    % Apply time-domain multi-tap precoder
    yFull = PolyMatConv(normQ(:,:,1:end),permute(x,[2,3,1]));
    yCut = yFull(:,:,1:numChip);
    y = permute(yCut,[3,1,2]);
else
    error('mapMatrix should be either 2-D or 3-D.');
end

end


