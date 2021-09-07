function [dataBits,softBits] = edmgDataBitRecover(rx,noiseVarEst,userIdx,varargin)
%edmgDataBitRecover Recover data bits from EDMG Data field
%
%   DATABITS = edmgDataBitRecover(RX,NOISEVAREST,CFGEDMG) recovers the
%   data bits given the Data field from a EDMG transmission (OFDM, SC, or
%   Control PHY), the noise variance estimate, and the EDMG configuration
%   object.
%
%   DATABITS is an int8 column vector of length 8*CFGEDMG.PSDULength
%   containing the recovered information bits.
%
%   The contents and size of RX are physical layer dependent:
%
%   SC PHY:      RX is the time-domain DMG-Data field signal, specified
%                as a (NFFT-NGI)-by-Nblks matrix of real or complex values, where
%                448 is the number of symbols in a DMG-Data symbol and
%                Nblks is the number of DMG-Data blocks.
%
%   OFDM PHY:    RX is the demodulated DMG-Data field OFDM symbols,
%                specified as a Nsd-by-Nsym matrix of real or complex
%                values, where Nsd is the number of data subcarriers in the
%                DMG-Data field and Nsym is the number of OFDM symbols.
%
%   Control PHY: RX is the time-domain signal containing the header
%                and data fields, specified as an Nb-by-1 column vector of
%                real or complex values, where Nb is the number of despread
%                symbols.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig, which
%   specifies the parameters for the DMG format.
%
%   DATABITS = edmgDataBitRecover(...,CSI,CFGEDMG) uses the channel state
%   information to enhance the demapping of OFDM subcarriers. CSI is a
%   336-by-1 column vector of real values, where 336 is the number of data
%   subcarriers in the DMG-Data field. The CSI input is only required for
%   OFDM PHY.
%
%   DATABITS = edmgDataBitRecover(...,Name,Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'LDPCDecodingMethod'        Specify the LDPC decoding algorithm as one
%                               of these values:
%                               - 'bp'            : Belief propagation (BP)
%                               - 'layered-bp'    : Layered BP
%                               - 'norm-min-sum'  : Normalized min-sum
%                               - 'offset-min-sum': Offset min-sum
%                               The default is 'bp'.
%
%   'MinSumScalingFactor'       Specify the scaling factor for normalized
%                               min-sum LDPC decoding algorithm as a scalar
%                               in the interval (0,1]. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'norm-min-sum'. The
%                               default is 0.75.
%
%   'MinSumOffset'              Specify the offset for offset min-sum LDPC
%                               decoding algorithm as a finite real scalar
%                               greater than or equal to 0. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'offset-min-sum'. The
%                               default is 0.5.
%
%   'MaximumLDPCIterationCount' Specify the maximum number of iterations in
%                               LDPC decoding as a positive scalar integer.
%                               The default is 12.
%
%   'EarlyTermination'          To enable early termination of LDPC
%                               decoding, set this property to true. Early
%                               termination applies if all parity-checks
%                               are satisfied before reaching the number of
%                               iterations specified in the
%                               'MaximumLDPCIterationCount' input. To let
%                               the decoding process iterate for the number
%                               of iterations specified in the
%                               'MaximumLDPCIterationCount' input, set this
%                               argument to false. The default is false.
%

%   Copyright 2017-2019 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Check minimum and maximum number of input arguments
narginchk(3,14);

% If input rx is empty then do not attempt to decode; return empty
if isempty(rx)
    dataBits = zeros(0,1,'int8');
    return;
end

csiFlag = 0;
% Modified to nist.edmgConfig
if isa(varargin{1},'nist.edmgConfig')
    % If no CSI input is present
    cfgEDMG = varargin{1};
    csi = [];
elseif nargin>4 && isa(varargin{2},'nist.edmgConfig') 
    csi = varargin{1};
    cfgEDMG = varargin{2};
    csiFlag = 1;
else
    coder.internal.error('wlan:shared:ExpectedDMGObject');
end

% Validate configuration object
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% Input CSI is only required for OFDM PHY
coder.internal.errorIf(~isempty(csi) && ~strcmp(phyType(cfgEDMG),'OFDM'),'wlan:shared:InvalidInputCSI');

% Validate and parse P-V pair optional inputs
coder.internal.errorIf((length(varargin)-(1+csiFlag))==1,'wlan:shared:InvalidNumOptionalInputs');
ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{2+csiFlag:end});

% Validate input
% validateattributes(rx,{'double'},{'2d','finite'},mfilename,'input');
        
% Validate input noise estimate
validateattributes(noiseVarEst,{'double'},{'real','scalar','nonnegative','finite'},mfilename,'noiseVarEst'); 

mcsTable = nist.edmgMCSRateTable(cfgEDMG);
numSS = mcsTable.NSS(userIdx); % Number of spatial streams

numSeg = 1; % Num of segments
numES = 1; % Num of encoded stream

switch cfgEDMG.PHYType
    case 'SC'
        numCBPS = mcsTable.NCBPS(userIdx);
        numCBPSS = mcsTable.NCBPSS(userIdx);
        numDataSubb = size(rx,1); % Nsd is num of data subbands.
        numBlksMax = getMaxNumberBlocks(cfgEDMG);
        encodeInfo = nist.edmgSCEncodingInfo(cfgEDMG,userIdx,numBlksMax);
        numScBlks = encodeInfo.NBLKS;
        softBits = zeros(numCBPSS*numDataSubb,numScBlks,numSS);
    case 'OFDM'
        numCBPS = mcsTable.NCBPS(userIdx); % number of coded bits per OFDM symbol, equal to (NUMBPSCS*numSS*Nsd)
        numDataSubc = size(rx,1); % Nsd is num of data subcarriers.
        % numCBPSS = numCBPS/numSS; % Ncbpss is the number of coded bits per OFDM symbol per spatial stream
        numBPSCS = mcsTable.NBPSCS(userIdx); % number of coded bits per subcarrier per spatial stream.
%         numDBPS = mcsTable.NDBPS; % Nsd * NUMBPSCS
        numSymbMax = getMaxNumberBlocks(cfgEDMG);
        encodeInfo = nist.edmgOFDMEncodingInfo(cfgEDMG,userIdx,numSymbMax);
        numOfdmSymb = encodeInfo.NSYMS;
        softBits = zeros(numBPSCS*numDataSubc,numOfdmSymb,numSS);
    otherwise
        % Control
        error('Control mode is not supported.');
end

for iSS = 1:numSS
    if csiFlag
        softBits(:,:,iSS) = nist.edmgDataDemap(rx(:,:,iSS),noiseVarEst,userIdx,csi(:,iSS),cfgEDMG);
    else 
        softBits(:,:,iSS) = nist.edmgDataDemap(rx(:,:,iSS),noiseVarEst,userIdx,cfgEDMG);
    end
end


% Stream deparsing
softBitsReshape = reshape(softBits, [], numSS, numSeg); % [(Ncbpssi*Nsym),Nss,Nseg]
switch cfgEDMG.PHYType
    case 'SC'
        streamDeparserOut = nist.edmgStreamDeparse(softBitsReshape, numES, numCBPS, numCBPSS); %
    case 'OFDM'
        streamDeparserOut = nist.edmgStreamDeparse(softBitsReshape, numES, numCBPS, numBPSCS); %
    otherwise
        % Control
        error('Control mode is not supported.');
end

% LDPC Decoding
dataBits = nist.edmgDataDecode(streamDeparserOut,cfgEDMG,userIdx, ...
    ldpcParams.algChoice,ldpcParams.alphaBeta,ldpcParams.MaximumLDPCIterationCount,ldpcParams.EarlyTermination);

end
