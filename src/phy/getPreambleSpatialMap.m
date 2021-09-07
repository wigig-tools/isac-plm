function normQ = getPreambleSpatialMap(cfgEDMG,varargin)
%GETPREAMBLESPATIALMAP in OFDM mode returns the Q [NTONES x numTx x numSTS]
%spatial matrix that is applyied to EDMG-STF and EDMG-CEF. In SC Q is a
%single tap precoder [numTx x numSTS]
%
%
%   Q = GETPREAMBLESPATIALMAP(cfgEDMG)
%
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

narginchk(1,2);

phyType = cfgEDMG.PHYType;
numSTS  = sum(cfgEDMG.NumSpaceTimeStreams,2);    % Total number of space-time streams
numTx   = cfgEDMG.NumTransmitAntennas;
mapping = cfgEDMG.PreambleSpatialMappingType;
numSTSVec = cfgEDMG.NumSpaceTimeStreams;

switch phyType
    case 'SC'
        switch mapping
            case 'Hadamard'
                Q = hadamard(8);
                normQ = Q(1:numSTS, 1:numTx)/sqrt(numTx).';
            case 'Fourier'
                [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
                normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx).';
            case 'Custom'
                normQ = cfgEDMG.SpatialMappingMatrix;
            case 'Direct'
                assert(numTx==numSTS, 'Direct precoding only possible if Nsts = Ntx');
                normQ = eye(numTx);
            otherwise
                error('mappingType is incorrect.');
        end
    case 'OFDM'
        [ofdmInfo,~] = nist.edmgOFDMInfo(cfgEDMG);
        switch mapping
            case 'Hadamard'
                Q = hadamard(8);
                normQ = Q(1:numSTS, 1:numTx)/sqrt(numTx);
                normQ = permute(repmat(normQ, [1 1 ofdmInfo.NTONES]), [3 2 1]);
            case 'Fourier'
                [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
                normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
                normQ = permute(repmat(normQ, [1 1 ofdmInfo.NTONES]), [3 2 1]);
            case 'Custom'
                    normQ = cfgEDMG.SpatialMappingMatrix;
            case 'Direct'
                assert(numTx==numSTS, 'Direct precoding only possible if Nsts = Ntx');
                normQ = eye(numTx);
                normQ = permute(repmat(normQ, [1 1 ofdmInfo.NTONES]), [3 2 1]);
            otherwise
                error('mappingType is incorrect.');
        end
end
