function y = edmgData(psdu,cfgEDMG,varargin)
%edmgData EDMG Data field processing of the PSDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgData(PSDU,CFGDMG) generates the EDMG format Data field
%   time-domain waveform for the input PLCP Service Data Unit (PSDU).
%
%   Y is the time-domain EDMG Data field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   PSDU is the PHY service data unit input to the PHY. It is a double
%   or int8 typed column vector of length CFGDMG.PSDULength*8, with each
%   element representing a bit.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang, Steve Blandino

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(2,6)
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

%% Varargin processing
p = inputParser;
addParameter(p,'precNorm', 0);
addParameter(p,'preamble', []);
addParameter(p,'brfield', []);

parse(p, varargin{:});
preamble = p.Results.preamble;
brfield = p.Results.brfield;

% Set up implicit parameters
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
numUsers = cfgEDMG.NumUsers;
numSTSVec = cfgEDMG.NumSpaceTimeStreams; % [1 Nu]
numSTSTot = sum(numSTSVec);
numTxAnt = cfgEDMG.NumTransmitAntennas;
spatialMapType = cfgEDMG.SpatialMappingType;
spatialMapMat = cfgEDMG.SpatialMappingMatrix;

if strcmp(phyType(cfgEDMG),'Control')
    % Encode header and data together due to differential encoding
    headerBits = nist.edmgLHeaderBits(cfgEDMG);
    encHeaderBits = nist.edmgHeaderEncode(headerBits,psdu,cfgEDMG);
    encDataBits = nist.edmgDataEncode(psdu,cfgEDMG);
    % Modulate
    yT = nist.edmgDataModulate([encHeaderBits; encDataBits],cfgEDMG);
    % Strip out the encoded data from differential modulation
    y = yT((8192+1):end);
elseif strcmp(phyType(cfgEDMG),'OFDM') % OFDM PHY
    % Modified OFDM PHY supports MU-MIMO
    [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
    fftLen = ofdmInfo.NFFT;
    giLen = ofdmInfo.NGI;
    ofdmNormalFactor = ofdmInfo.NormalizationFactor;
    numOfdmSymbMax = getMaxNumberBlocks(cfgEDMG);
    [activeSubcIdx,~] = sort([ofdmInd.DataIndices; ofdmInd.PilotIndices]);
    % Get data subcarriers for each symbol and space-time stream for all users
    muDataGrid = complex(zeros(fftLen,numOfdmSymbMax,numSTSTot));
    for u = 1:numUsers
        % Encode data
        encodedBits = nist.edmgDataEncode(psdu{u},cfgEDMG,u);
        % Parse encoded data into streams
        streamParsedData = nist.edmgStreamParse(encodedBits,mcsTable.NSS(u),mcsTable.NCBPS(u), mcsTable.NBPSCS(u));
        % Creat ST stream for each user
        for uSTS = 1:numSTSVec(u)
            % Modulate
            moduDataGrid = nist.edmgDataModulate(streamParsedData(:,uSTS),cfgEDMG,u);
            numOfdmSymbIndiUser = size(moduDataGrid,2);
            muDataGrid(:,1:numOfdmSymbIndiUser,sum(numSTSVec(1:u-1))+uSTS) = moduDataGrid;
        end
    end
    % Spatial Mapping
    spatialMappedGrid = nist.edmgOFDMSpatialMap(muDataGrid,spatialMapType,spatialMapMat,numTxAnt,activeSubcIdx);
    % OFDM modulate with MIMO transmit power normalization
    y = wlan.internal.wlanOFDMModulate(spatialMappedGrid,giLen)*ofdmNormalFactor/sqrt(numSTSTot);
else % SC PHY
    scInfo = edmgSCInfo(cfgEDMG);
    fftLen = scInfo.NFFT;
    giLen = scInfo.NGI;
    numScBlk = getMaxNumberBlocks(cfgEDMG);
    muDataStreams = complex(zeros(fftLen*numScBlk+giLen,numSTSTot));
    % Get data subcarriers for each symbol and space-time stream for all users
    for u = 1:numUsers
        % Encode data
        encodedBits = nist.edmgDataEncode(psdu{u},cfgEDMG,u);
        % Parse encoded data into streams
        streamParsedData = nist.edmgStreamParse(encodedBits,mcsTable.NSS(u),mcsTable.NCBPS(u),mcsTable.NCBPSS(u));
        % Creat ST stream for each user
        for uSTS = 1:numSTSVec(u)
            % Modulate
            moduDataBlks = nist.edmgDataModulate(streamParsedData(:,uSTS),cfgEDMG,u);
            muDataStreams(:,sum(numSTSVec(1:u-1))+uSTS) = moduDataBlks*sqrt(1/numSTSTot);
        end
    end
    % Spatial Mapping
    y = nist.edmgSCSpatialMap(muDataStreams,spatialMapType,spatialMapMat,numTxAnt,'preamble',preamble,'brfield',brfield);
end

end
