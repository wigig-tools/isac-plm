function softBits = edmgDataDemap(sym,noiseVarEst,userIdx,varargin)
%edmgDataDemap DMG Data field Demodulation for OFDM, SC and Control PHY
%
%   SOFTBITS = edmgDataDemap(SYM,NOISEVAREST,cfgEDMG) performs
%   demapping of the symbols SYM given the noise variance NOISEVAREST and
%   the EDMG configuration object cfgEDMG.
%
%   SOFTBITS = edmgDataDemap(SYM,NOISEVAREST,CSI,cfgEDMG) performs demapping
%   of the symbols with additional CSI information. The CSI is only used
%   for OFDM PHY.

%   Copyright 2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(4,5);

csiFlag = 0;
if isa(varargin{1},'nist.edmgConfig')
    cfgEDMG = varargin{1};
else 
    csi = varargin{1};
    cfgEDMG = varargin{2};
    csiFlag = 1;
end
validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

phyType = cfgEDMG.PHYType;

% Validate input sizes for OFDM, SC and Control PHY
switch phyType
    case 'SC'
        % Validate input size for SC PHY
        narginchk(4,4);
        scInfo = edmgSCInfo(cfgEDMG);
        numBlksMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgSCEncodingInfo(cfgEDMG,userIdx,numBlksMax);
        numDataSymPerBlk = scInfo.NDSPB;    % blkSize-Ngi; % Block size
        if any(size(sym,1) ~= numDataSymPerBlk)
            coder.internal.error('wlan:shared:IncorrectSCNsym',size(sym,1));
        end
        if any(size(sym,2) < parms.NBLKS)
            coder.internal.error('wlan:shared:IncorrectSCNblks',parms.NBLKS,size(sym,2));
        end
        sym = sym(:,1:parms.NBLKS); % Extract the minimum input signal length required to process the SC PHY
    case 'OFDM'
        % Validate input size for OFDM PHY
        narginchk(4,5);
        ofdmInfo = nist.edmgOFDMInfo(cfgEDMG);
        numSymbMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgOFDMEncodingInfo(cfgEDMG,userIdx,numSymbMax);
        if any(size(sym,1) ~= ofdmInfo.NSD)
            coder.internal.error('wlan:shared:IncorrectOFDMSC',size(sym,1));
        end
        if any(size(sym,2) ~= parms.NSYMS)
            coder.internal.error('wlan:dmgDataDemap:IncorrectOFDMNsym',parms.NSYMS,size(sym,2));
        end
       
        % Validate CSI input 
        if csiFlag
            validateattributes(csi,{'double'},{'real','column','finite'},mfilename,'CSI');
            if size(csi,1) ~= ofdmInfo.NSD
                coder.internal.error('wlan:shared:InvalidCSISize',size(csi,1));
            end
        end
        sym = sym(:,1:parms.NSYMS); % Extract the minimum input signal length required to process the OFDM PHY
    otherwise 
        % Validate input size for Control PHY
        SF = 32; % Spreading factor
        headerIndex = nist.edmgFieldIndices(cfgEDMG,'DMG-Header');    % Modified
        dataIndex = nist.edmgFieldIndices(cfgEDMG,'DMG-Data');    % Modified
        headerLength = headerIndex(2)-headerIndex(1)+1;
        dataLength = dataIndex(2)-dataIndex(1)+1;
        minInputLength = double((dataLength+headerLength)/SF);
        if any(size(sym,1) < minInputLength)
            coder.internal.error('wlan:shared:IncorrectControlSym',minInputLength,size(sym,1));
        end
        sym = sym(1:minInputLength,1); % Extract the minimum input signal length required to process the Control PHY
end

mcsTable = nist.edmgMCSRateTable(cfgEDMG);
numTxAnt = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams; % [1 Nu]
numSTSTot = sum(numSTSVec);
numSS = numSTSVec(userIdx);

switch phyType
    case 'OFDM'
        mcsNBPSCS = mcsTable.NBPSCS(userIdx);
        switch mcsNBPSCS
            case 1 % MCS 1~5
                % Static tone pairing, IEEE P802.11ay Draft 7.0 Section 28.6.9.3.3 DCM BPSK modulation             
                k = (0:(ofdmInfo.NSD/2-1)).';
                pk = k+ofdmInfo.NSD/2;
                % Combine DCM BPSK symbols
                demappedData = sqpskCombine(sym,k,pk);
                % Demap DCM BPSK
                softBits = wlanConstellationDemap(demappedData,noiseVarEst/2,2);
                % Combine CSI of symbols and apply
                if nargin == 5 % with CSI
                    csiComb = sqpskCombine(csi,k,pk);
                    softBits = wlan.internal.applyCSI(softBits,csiComb,2);
                end
            case 2 % MCS 6~10               
                % Static tone pairing, IEEE P802.11ay Draft 7.0 Section 28.6.9.3.5 DCM QPSK modulation
                k = (0:(ofdmInfo.NSD/2-1)).';
                pk = k+ofdmInfo.NSD/2;
                
                % Demap DCM QPSK
                if nargin == 4 % No CSI
                    softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk);
                else % with CSI
                    softBits = wlan.internal.dmgQPSKDemodulate(sym,noiseVarEst,k,pk,csi);
                end
            otherwise % MCS 11~20
                % De-Interleave for 16-QAM & 64-QAM in 11ay
                [Nx, Ny] = configMatrixInterleaver(phyType,ofdmInfo.NCB, ofdmInfo.NSD, numSS, mcsNBPSCS, parms.LCW);
                deIntrlvSymb = matdeintrlv(sym,Nx,Ny);
                
                % Demap symbols
                softBits = wlanConstellationDemap(deIntrlvSymb,noiseVarEst,mcsNBPSCS);
                if nargin == 5 % With CSI
                    % De-Interleave and applyfor CSI tones in 11ay
                    csiComb = matdeintrlv(csi,Nx,Ny);
                    softBits = wlan.internal.applyCSI(softBits,csiComb,mcsNBPSCS);
                end
        end
    case 'SC'
        mcsNCBPSS = mcsTable.NCBPSS(userIdx);
        % Remove pi/2 rotation
        deroSymb = wlan.internal.dmgDerotate(sym);
        switch mcsNCBPSS
            case 1  % pi/2-BPSK
                softBits = wlanConstellationDemap(deroSymb,noiseVarEst,1);
            case 2  % pi/2-QPSK
                softBits = wlanConstellationDemap(deroSymb,noiseVarEst,2,-pi/4);
            case 4  % pi/2-16QAM
                softBits = wlanConstellationDemap(deroSymb,noiseVarEst,4);
            otherwise   % pi/2-64QAM
                % De-Interleave for 64-QAM in 11ay
                [Nx, Ny] = configMatrixInterleaver(phyType,scInfo.NCB, scInfo.NDSPB, numSS, mcsNCBPSS, parms.LCW);
                deIntrlvSymb = matdeintrlv(deroSymb,Nx,Ny);
                % Demap symbols
                softBits = wlanConstellationDemap(deIntrlvSymb,noiseVarEst,mcsNCBPSS);
        end
          
    otherwise % Control PHY
        % DBPSK demodulation
        softBits = wlan.internal.dbpskDemodulate(sym,noiseVarEst);
end
        
end

function y = sqpskCombine(x,k,pk)
    y = (x(k+1,:)+conj(x(pk+1,:)))/2;
end

