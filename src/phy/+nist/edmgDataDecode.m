function [dataBits,numIterations,parityCheck] = edmgDataDecode(x,cfgEDMG,userIdx,...
    algChoice,alphaBeta,maxNumIter,earlyTermination)
%edmgDataDecode Decode data bits for Control, SC and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DATABITS = edmgDataDecode(X,CFGDMG) decodes the input X using a DMG LDPC
%   code at the specified rate. DATABITS is the soft decision decoded
%   information bits.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig, which
%   specifies the parameters for the EDMG format.
%
%   ALGCHOICE specifies the LDPC decoding algorithm as one of these values:
%     0 - Belief Propagation
%     1 - Layered Belief Propagation
%     2 - Layered Belief Propagation with Normalized Min-Sum approximation
%     3 - Layered Belief Propagation with Offset Min-Sum approximation
%
%   ALPHABETA specifies the scaling factor (if the Normalized Min-Sum
%   approximation is used) or the offset factor (if the Offset Min-Sum
%   approximation is used). Its value is irrelevant for the other two LDPC
%   algorithms but still needed.
%
%   MAXNUMITER specifies the number of decoding iterations required to
%   decode the input X.
%
%   EARLYTERMINATION specifies if the conditions for an early termination
%   should be checked. If true, after each iteration, ldpcDecodeCore will
%   determine independently for each column of X if all parity checks are
%   satisfied, and will stop for column(s) with all parity checks
%   satisfied; otherwise, the function will execute exactly MAXNUMITER
%   iterations.
%
%   [...,NUMITERATIONS] = dmgDataDecode(...) returns the actual number of
%   LDPC decoding iterations, one per codeword. NUMITERATIONS is NumCW-by-1
%   vector, where NumCW is the number of codewords.
%
%   [...,PARITYCHECK] = dmgDataDecode(...) returns the parity check per
%   codeword. The PARITYCHECK is NumInp-by-NumCW matrix, where NumInp is
%   the number of information bits within a codeword and NumCW is the
%   number of codewords.

%   Copyright 2017-2019 The MathWorks, Inc.   
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% If input X is empty then do not attempt to decode; return empty
if isempty(x)
    dataBits = zeros(0,1,'int8');
    numIterations = [];
    parityCheck = [];
    return;
end

% LCW = 672; % Codeword length
scramInit = nist.edmgScramblerInitializationBits(cfgEDMG,userIdx);
mcsTable = nist.edmgMCSRateTable(cfgEDMG);
codeRate = mcsTable.Rate(userIdx);
codeRepetition = mcsTable.Repetition(userIdx);

switch phyType(cfgEDMG)
    case 'Control'
        % Decode first codeword from header field
        [~,dataDecode] = edmgHeaderDecode(x,cfgEDMG,maxLDPCIterationCount,iterationTerminationCondition);   % Modified
        LCW = 672; % Codeword length % Add 
        x = x(257:end,1); % Get data field
        parms = edmgControlEncodingInfo(cfgEDMG);   % Modified
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW;
        blkLength = LCW-LCWD+parms.LDPCW;
        % Extract bits for middle codewords
        bitsMiddleCW = x(1:blkLength*(parms.NCW-2),1);
        
        if isempty(bitsMiddleCW)
            middleCWdecoded = zeros(0,0,'int8');
        else
            middleCW = reshape(bitsMiddleCW,blkLength,parms.NCW-2);
            % Append extra LLR bits to extend the size of each block to 672
            extraBits = realmax*ones(LCW-size(middleCW,1),parms.NCW-2);     % Replaced realmax by 1e99
            blkMiddleCW = [middleCW(1:parms.LDPCW,:); extraBits; middleCW(parms.LDPCW+1:end,:)];
            decodedMiddleCW = wlan.internal.ldpcDecodeCore(blkMiddleCW,rate,algChoice,alphaBeta,maxNumIter,earlyTermination);
            middleCWdecoded = decodedMiddleCW(1:parms.LDPCW,:);
        end
      
        % Extract bits for the last codeword
        blkLength = LCW-LCWD+parms.LDPLCW;
        lastCW = x(end-(blkLength-1):end,1);
        % Append extra LLR bits to extend the size of each block to 672
        extraBits = realmax*ones(LCW-size(lastCW,1),1);
        blkEndCW = [lastCW(1:parms.LDPLCW,1); extraBits; lastCW(parms.LDPLCW+1:end,1)];
        [decodedLastCW,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(blkEndCW,rate,algChoice,alphaBeta,maxNumIter,earlyTermination);
        endCWdecoded = decodedLastCW(1:parms.LDPLCW,1);

        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        headerBits = zeros(88-5,1,'int8'); % Dummy header bits
        descrambledBits = wlanScramble([headerBits; middleCWdecoded(:); endCWdecoded],scramInit); % Extract data bits
        dataBits = [dataDecode;descrambledBits(parms.LDPFCW-6+2:end,1)];
    case 'OFDM'
        numSymbMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgOFDMEncodingInfo(cfgEDMG,userIdx,numSymbMax);
        % Only process the valid input length size
        symBits = x(:);
        symBitsRmSymPad = symBits(1:end-parms.NSYM_PAD);     % Jane added for 11ay
        blk = reshape(symBitsRmSymPad,parms.LCW,parms.NCW); % Reshape into blocks
        if isequal(parms.LCW,672)
            reconBlk = blk;
            [decodedBits,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(reconBlk,codeRate,algChoice,alphaBeta,maxNumIter,earlyTermination);
        elseif isequal(parms.LCW,624) && isequal(codeRate,7/8)
            % Add puctured 48 parity bits and decode with 13/16 rate
            reconBlk = [blk(1:546,:); zeros(48,parms.NCW); blk(546+1:end,:)];
            [decodedBits,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(reconBlk,13/16,algChoice,alphaBeta,maxNumIter,earlyTermination);
        else
            error('LCW should be either 672 or 624.');
        end        
        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        scramHeaderBits = zeros(64-7,1,'int8');
        % IEEE P802.11ay Draft 4.0 29.6.9.2.3
        allBits = [scramHeaderBits; decodedBits(:)];
        descrambledBits = nist.edmgScramble(allBits,scramInit,0);
        dataBits = descrambledBits(numel(scramHeaderBits)+1:end-parms.NDATA_PAD); 
    otherwise % SC PHY
        numBlksMax = getMaxNumberBlocks(cfgEDMG);
        parms = nist.edmgSCEncodingInfo(cfgEDMG,userIdx,numBlksMax);
        LZ = parms.LCW/(2*codeRepetition);   % Modified
        blkBits = x(:);
        blkBitsRmBlkPad = blkBits(1:end-parms.NBLK_PAD,1);
        blk = reshape(blkBitsRmBlkPad,parms.LCW,parms.NCW); % Reshape into blocks of size 672 
        
        if codeRepetition == 1 
            if isequal(parms.LCW,672)
                reconBlk = blk;
                [decodedCW,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(reconBlk,codeRate,algChoice,alphaBeta,maxNumIter,earlyTermination);
            elseif isequal(parms.LCW,624) && isequal(codeRate,7/8)
                % Add puctured 48 parity bits and decode with 13/16 rate
                reconBlk = [blk(1:546,:); zeros(48,parms.NCW); blk(546+1:end,:)];
                [decodedCW,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(reconBlk,13/16,algChoice,alphaBeta,maxNumIter,earlyTermination);
            else
                error('LCW should be either 672 or 624, when repetition = 1.');
            end
        elseif codeRepetition == 2
            if isequal(parms.LCW,672) && isequal(codeRate,1/2)
                % Append extra LLR bits to extend the size to 672
                extraBits = realmax*ones(LZ,parms.NCW);
                repetitionBlk = wlan.internal.descrambleLLRs(blk(LZ+(1:LZ),:));
                blkCW = [blk(1:LZ,:) + repetitionBlk; extraBits; blk(2*LZ+1:end,:)];
                [decodedCW,numIterations,parityCheck] = wlan.internal.ldpcDecodeCore(blkCW,codeRate,algChoice,alphaBeta,maxNumIter,earlyTermination);
                decodedCW = decodedCW(1:LZ,:);
            else
                error('LCW should be 672, when repetition = 2.');
            end
        else
            error('Repetition should be either 1 or 2.');    
        end
        
        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        scramHeaderBits = zeros(64-7,1,'int8');
        allBits = [scramHeaderBits; decodedCW(:)];
        descrambledBits = nist.edmgScramble(allBits,scramInit,0);
        dataBits = descrambledBits(numel(scramHeaderBits)+1:end-parms.NDATA_PAD); 
end

end


