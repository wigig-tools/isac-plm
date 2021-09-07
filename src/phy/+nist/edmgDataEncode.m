function y = edmgDataEncode(psdu,cfgEDMG,userIdx)
%edmgDataEncode Encode data bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgDataEncode(PSDU,CFGDMG) generates the DMG LDPC encoded bits for
%   the data field for Control, Single Carrier and OFDM PHYs.
%
%   Y is of size N-by-1 of type uint8, where N is the number of LDPC
%   encoded pay load bits.
%
%   PSDU is the PLCP service data unit input to the PHY. It is a double or
%   int8 typed column vector of length cfgDMG.PSDULength*8.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% If PSDU is empty then do not attempt to encode it; return empty
if isempty(psdu)
    y = zeros(0,1,'int8');
    return;
end

% Generate header bits to allow state of scrambler for data section to be
% determined
if cfgEDMG.NumUsers==1
    headerBits = nist.edmgLHeaderBits(cfgEDMG);
else
    headerBits = nist.edmgHeaderBBits(cfgEDMG,userIdx);
end

% LCW = 672; % Codeword length
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
codeRate = mcsTable.Rate(userIdx);
codeRepetition = mcsTable.Repetition(userIdx);

scramInit = nist.edmgScramblerInitializationBits(cfgEDMG,userIdx);

switch phyType(cfgEDMG)
    case 'Control'
        % Scramble header and PSDU bits together to ensure scrambler is in
        % correct state for each section 
        scramAllBits = [headerBits(1:5); wlanScramble([headerBits(6:end); psdu],scramInit)];
        
        % LDPC Encoding of header bits
        parms = edmgControlEncodingInfo(cfgEDMG);
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*parms.LCW; % Modified

        % LDPC encoding of middle CWs
        % Extract bits for middle codewords
        bitsMiddleCW = scramAllBits(parms.LDPFCW+1:end-parms.LDPLCW);
        % Create a block of data words of length 502 by padding zeros
        middleCW = reshape(bitsMiddleCW,parms.LDPCW,parms.NCW-2);
        blkMiddleCW = [middleCW; zeros(LCWD-size(middleCW,1),parms.NCW-2)];
        parityBits = wlan.internal.ldpcEncodeCore(blkMiddleCW,rate);
        ldpcMiddleCW = [middleCW; parityBits];

        % LDPC encoding of last CW
        lastCW = scramAllBits(end-parms.LDPLCW+1:end);
        % Generate parity matrix for each data word
        blkLastCW = [lastCW; zeros(LCWD-parms.LDPLCW,1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkLastCW,rate);
        % Create LDPC encoded data by removing zeros
        ldpcLastCW = [lastCW; parityBits];
        y = [ldpcMiddleCW(:); ldpcLastCW(:)];
        
    case 'SC' 
        % IEEE 802.11ay D7.0 Section 28.5.9.4.3 LDPC encoding
        % LDPC Encoding of data bits   
        numBlksMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgSCEncodingInfo(cfgEDMG,userIdx,numBlksMax);
        
        % Scramble header, PSDU and padding bits together to ensure
        % scrambler is in correct state for each section
        scramHeaderBits = nist.edmgScramble(headerBits(8:end),scramInit,0);
        allBits = [scramHeaderBits; psdu; zeros(parms.NDATA_PAD,1); zeros(parms.NBLK_PAD,1)];
        scramAllBits = nist.edmgScramble(allBits,scramInit,0);
        
        % Extract data bits and block padding bits from scrambled stream
        scramDataBits = scramAllBits(numel(headerBits(8:end))+(1:(numel(psdu)+parms.NDATA_PAD)));
        scramBlkPadBits = scramAllBits(end-parms.NBLK_PAD+1:end);
        if codeRepetition == 1
            blkCW = reshape(scramDataBits,parms.LCW*codeRate,parms.NCW); % Reshape into blocks % Modified
            % Generate parity bits
            if isequal(parms.LCW,672)
                parityBits = wlan.internal.ldpcEncodeCore(blkCW,codeRate);
                ldpcEncodedBits = [blkCW; parityBits];
            elseif isequal(parms.LCW,624) && isequal(codeRate,7/8)
                % Generate parity bits with 13/16 rate
                parityBits = wlan.internal.ldpcEncodeCore(blkCW,13/16);
                ldpcEncodedBits = [blkCW; parityBits(49:end,:)]; % Remove first 48 parity bits
            else
                error('LCW should be either 672 or 624, when repetition = 1.');
            end
        elseif codeRepetition == 2
           LZ = parms.LCW/(2*codeRepetition);
           blkCW = [reshape(scramDataBits,LZ,parms.NCW); zeros(LZ,parms.NCW)];
           if isequal(parms.LCW,672) && isequal(codeRate,1/2)
               % Generate parity bits with block concatenated with zeros
               parityBits = wlan.internal.ldpcEncodeCore(blkCW,codeRate);
               % Scramble the data portion of the code word
               scramBlkCW = coder.nullcopy(zeros(LZ,parms.NCW)); % Preinitialize
               for n = 1:parms.NCW
                    scramBlkCW(:,n) = nist.edmgScramble(blkCW(1:LZ,n),ones(7,1),0);
               end
               ldpcEncodedBits = [blkCW(1:LZ,:); scramBlkCW; parityBits];
           else
               error('LCW should be 672, when repetition = 2.');
           end
        else
            error('Repetition should be either 1 or 2.');
        end
        
        % Add padded bits - Section 21.6.3.2.3.3, page 474, Step 4-5
        y = [ldpcEncodedBits(:); scramBlkPadBits];
      
    otherwise % OFDM
        numSymbMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgOFDMEncodingInfo(cfgEDMG,userIdx,numSymbMax);
        % IEEE P802.11ay D7.0 28.6.9.2.3
        % Scramble header and PSDU bits together to ensure scrambler is in
        % correct state for PSDU scrambling
        scramHeaderBits = nist.edmgScramble(headerBits(8:end),scramInit,0);
        allBits = [scramHeaderBits; psdu; zeros(parms.NDATA_PAD,1); zeros(parms.NSYM_PAD,1)];
        
        % Scramble data portion (with header continuation)
        scramAllBits = nist.edmgScramble(allBits,scramInit,0);
        scramDataBits = scramAllBits(numel(headerBits(8:end))+(1:(numel(psdu)+parms.NDATA_PAD))); % Extract scrambled data bits 
        scramSymPadBits = scramAllBits(end-parms.NSYM_PAD+1:end);
        
        % Data Encode
        LCWD = codeRate*parms.LCW; % Block length of LDPC data % Modified
        blkCW = reshape(scramDataBits,LCWD,parms.NCW);                % Reshape into blocks 
        
        % Generate parity bits
        if isequal(parms.LCW,672)
            parityBits = wlan.internal.ldpcEncodeCore(blkCW,codeRate);
            ldpcEncodedBits = [blkCW; parityBits];
        elseif isequal(parms.LCW,624) && isequal(codeRate,7/8)
            % Generate parity bits with 13/16 rate
            parityBits = wlan.internal.ldpcEncodeCore(blkCW,13/16);
            ldpcEncodedBits = [blkCW; parityBits(49:end,:)]; % Remove first 48 parity bits
        else
            error('LCW should be either 672 or 624.');
        end
        y = [ldpcEncodedBits(:); scramSymPadBits];

end
