function [y,d,varargout] = edmgDataModulate(bits,cfgEDMG,varargin)
%edmgDataModulate DMG data modulation
%
%   Y = edmgDataModulate(BITS,CFGDMG) generates the DMG format Data field
%   time-domain waveform.
%
%   Y is the time-domain EDMG Data field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   BITS is the encoded data bits. It is of size N-by-1 of type uint8,
%   where N is the number of LDPC encoded header bits.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   [Y,D] = edmgDataModulate(...) additionally returns diagnostic
%   information. For Control PHY, D is the symbols before spreading. For
%   OFDM PHY, D is the modulated symbols on data subcarriers. For SC PHY, D
%   is not assigned.

%   Copyright 2016-2018 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

nargoutchk(0,3);
if nargin > 2
    userIdx = varargin{1};
else
    userIdx = 1;
end

phyType = cfgEDMG.PHYType;
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
numTxAnt = cfgEDMG.NumTransmitAntennas;
numSTSVec = cfgEDMG.NumSpaceTimeStreams; % [1 Nu]
numSTSTot = sum(numSTSVec);
numSS = numSTSVec(userIdx);

switch phyType
    case 'Control'
        % 21.4.3.3.4 DBPSK Modulation
        d = dpskmod(int32(~bits),2);
        varargout{1} = d; % Symbols before spreading

        % 21.4.3.3.5 Spreading
        y = wlan.internal.dmgControlSpread(d);
        
    case 'OFDM'
        % IEEE 802.11ay D7.0 Section 28.6.9.2
        numSymbMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgOFDMEncodingInfo(cfgEDMG,userIdx,numSymbMax);
        [ofdmInfo,ofdmInd] = nist.edmgOFDMInfo(cfgEDMG);
        grid = complex(zeros(ofdmInfo.NFFT,parms.NSYMS));
        mcsNBPSCS = mcsTable.NBPSCS(userIdx);
        mcsNCBPSS = mcsTable.NCBPS(userIdx)/numSS;
        switch mcsNBPSCS
            case 1 % MCS 1-5
                % IEEE P802.11ay D7.0 Section 29.6.9.3.3 DCM BPSK
                bb = reshape(bits,mcsNCBPSS,parms.NSYMS);
                x1 = wlanConstellationMap(bb(1:2:end,:),1);
                x2 = wlanConstellationMap(bb(2:2:end,:),1);
                % Apply DCM mapping matrix
                W = sqrt(1/2)*[1 1i; 1 -1i]; % DCM mapping matrix
                d = complex(zeros(ofdmInfo.NSD/2,2,parms.NSYMS));
                for q = 1:parms.NSYMS
                    d(:,:,q) = (W*[x1(:,q), x2(:,q)].').';
                end
                
                % Map to subcarriers with static tone pairing
                k = (0:(ofdmInfo.NSD/2-1)).';
                pk = k+ofdmInfo.NSD/2;
                grid(ofdmInd.DataIndices(k+1),:) = reshape(d(:,1,:),ofdmInfo.NSD/2,parms.NSYMS);
                grid(ofdmInd.DataIndices(pk+1),:) = reshape(d(:,2,:),ofdmInfo.NSD/2,parms.NSYMS);
                
            case 2 % MCS 6-10
                % IEEE P802.11ay D7.0 Section 29.6.9.3.5 DCM QPSK                
                d = wlan.internal.dmgQPSKModulate(bits);
                
                % Map to subcarriers with static tone pairing
                k = (0:(ofdmInfo.NSD/2-1)).';
                pk = k+ofdmInfo.NSD/2;
                grid(ofdmInd.DataIndices(k+1),:) = reshape(d(:,1),ofdmInfo.NSD/2,parms.NSYMS);
                grid(ofdmInd.DataIndices(pk+1),:) = reshape(d(:,2),ofdmInfo.NSD/2,parms.NSYMS);

            case 4 % MCS 11-15
                % IEEE 802.11-2016 DMG Section 20.5.3.2.4.4 16-QAM modulation
                % IEEE P802.11ay D7.0 Section 29.6.9.3.6 16QAM
                c = wlanConstellationMap(bits,4);
                d = reshape(c,ofdmInfo.NSD,parms.NSYMS);
                
                % IEEE P802.11ay Draft 7.0 Section 28.6.9.3.9 Interleaver
                [Nx, Ny] = configMatrixInterleaver(phyType,ofdmInfo.NCB, ofdmInfo.NSD, numSS, mcsNBPSCS, parms.LCW);
                dIntrlv = matintrlv(d,Nx,Ny);
                grid(ofdmInd.DataIndices,:) = dIntrlv;
                
            otherwise
                % 6 % MCS 16-20
                % IEEE 802.11ad-2016 Section 20.5.3.2.4.5 64QAM Modulation
                % IEEE P802.11ay D7.0 Section 29.6.9.3.7 64-QAM
                c = wlanConstellationMap(bits,6);
                d = reshape(c,ofdmInfo.NSD,parms.NSYMS); % Replaced bits by d
                
                % IEEE 802.11ay D7.0 Section 28.6.9.3.9 Interleaver
                [Nx, Ny] = configMatrixInterleaver(phyType,ofdmInfo.NCB, ofdmInfo.NSD, numSS, mcsNBPSCS, parms.LCW);
                dIntrlv = matintrlv(d,Nx,Ny);
                grid(ofdmInd.DataIndices,:) = dIntrlv;
                
        end
        varargout{1} = grid(ofdmInd.DataIndices,:);

        % Generate pilot sequence (Section 21.5.3.2.5) and map
        grid(ofdmInd.PilotIndices,:) = wlan.internal.dmgPilots(parms.NSYMS,1); % p_(N+1)Pk

        % Add for EDMG
        y = grid;

    otherwise % Single carrier PHY
        % IEEE 802.11ay D7.0 Section 28.5.9.4
        numBlksMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgSCEncodingInfo(cfgEDMG,userIdx,numBlksMax);
        scInfo = edmgSCInfo(cfgEDMG);
        mcsNCBPSS = mcsTable.NCBPSS(userIdx);
        
        % Constellation mapping
        switch mcsNCBPSS
            case 1
                % pi/2-BPSK
                sd = wlanConstellationMap(bits,mcsNCBPSS);
                % pi/2 rotation per sample, equivalent to s = sd.*exp(1i*pi*(0:size(sd,1)-1).'/2);
                s = sd.*repmat(exp(1i*pi*(0:3).'/2),size(sd,1)/4,1);
            case 2
                % pi/2-QPSK
                sd = wlanConstellationMap(bits,mcsNCBPSS,-pi/4);
                % pi/2 rotation per sample, equivalent to s = sd.*exp(1i*pi*(0:size(sd,1)-1).'/2);
                s = sd.*repmat(exp(1i*pi*(0:3).'/2),size(sd,1)/4,1);
            case 4
                % pi/2-16-QAM
                sd = wlanConstellationMap(bits,mcsNCBPSS);
                % pi/2 rotation per sample, equivalent to s = sd.*exp(1i*pi*(0:size(sd,1)-1).'/2);
                s = sd.*repmat(exp(1i*pi*(0:3).'/2),size(sd,1)/4,1);
            otherwise
                % pi/2-64-QAM
                sd = wlanConstellationMap(bits,mcsNCBPSS);

                % Add block interleaver
                d = reshape(sd,scInfo.NDSPB,parms.NBLKS); % Replaced bits by d
                % Interleaving for pi/2-64-QAM
                [Nx, Ny] = configMatrixInterleaver(phyType,scInfo.NCB, scInfo.NDSPB, numSS, mcsNCBPSS, parms.LCW);
                dInterlv = matintrlv(d,Nx,Ny);
                dd = reshape(dInterlv,[scInfo.NDSPB*parms.NBLKS,1]);
                
                % pi/2 rotation per sample, equivalent to s = sd.*exp(1i*pi*(0:size(sd,1)-1).'/2);
                s = dd.*repmat(exp(1i*pi*(0:3).'/2),size(dd,1)/4,1);
        end
                
        % Apply blocking, add guard interval and postfix
        y = nist.edmgSymBlkGIInsert(scInfo,s,true);
end
end


