function [tdlCirMuMimo] = genTGayTDLChannel(tgayChan,numSamp,numTxAnt,numSTSVec,tdlType,normFlag)
%genTGayTDLChannel Generate Matlab TGay TDL channel
%   This function generates the TDL channel model for Matlab TGay channel with Doppler spreads.
%   
% Inputs:
%   tgayChan is the numUsers-length cell column array, whose entries are the Matlab TGay channel objects for number 
%       of MIMO users. 
%   numSamp is the number of samples for Doppler spreads
%   numTxAnt is the number of Tx antenna chains, each chain connects to a PAA.
%   numSTSVec is the numUsers-length row vector, each element is the number of STS of that user.
%   tdlType is type of TDL model, 'Impulse' or 'Sinc'.
%   normFlag is normalization control flag for MU-MIMO channel
%   
% Output:
%   tdlCirMuMimo is numUsers-length time domain TDL MU-MIMO CIR cell array, each entry is the numTxAnt-by-numSTS
%       sub cell array, having a maxTapLen-by-numSamp matrix.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

numSTSTot = sum(numSTSVec);
if iscell(tgayChan)
    numUsers = length(tgayChan);
    muTapGain = cell(numTxAnt,numSTSTot);
    maxTdlLen = zeros(numUsers,1);
    doppSampLen = cell(numUsers,1);
    for iUser = 1:numUsers
        tgayChanSu = clone(tgayChan{iUser});
        [suTapGain,tapLen,doppSampLen{iUser}] = genTGayTDLSUMIMOChannel(tgayChanSu,numSamp,tdlType); % numSamp = 1;
        maxTdlLen(iUser,1) = max(tapLen(:));
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        for iTxA = 1:numTxAnt
            numRxAnt = numSTSVec(iUser);
            for iRxA = 1:numRxAnt
                muTapGain{iTxA,stsIdx(iRxA)} = transpose(suTapGain{iTxA,iRxA});
            end
        end
    end
    muMaxTdlLen = max(maxTdlLen(:));
    tdlCirMuMimo = normalizeMUMIMOMultiPathChannel(muTapGain,numTxAnt,numSTSVec,normFlag,muMaxTdlLen);
else
    error('tgayChan should be a cell array.');
end

end

function [chanTdl,tapLen,sampLen,tapNorm] = genTGayTDLSUMIMOChannel(tgayChan,numSamp,tdlType,varargin)

narginchk(3,4);
if nargin == 4
    normFlag = varargin{1};
end
tgayChan.release;
chInfo = info(tgayChan);
txTest = complex(ones(numSamp,chInfo.NumTxStreams),zeros(numSamp,chInfo.NumTxStreams));

%% TGayChannel R2020a block fading
[~,cirTap] = tgayChan(txTest);
sampLen = size(cirTap,1);     % length of Doppler samples
chInfo = info(tgayChan);
if iscell(chInfo.PathDelays)  
    maxTapId = max(reshape(cellfun(@(x) length(x), chInfo.PathDelays), [],1));
end

tapLen = zeros(chInfo.NumTxStreams,chInfo.NumRxStreams);    % length TDL taps
chanTdlStream = cell(chInfo.NumTxStreams,chInfo.NumRxStreams);
tapNorm = zeros(chInfo.NumTxStreams,chInfo.NumRxStreams);
for iRx = 1:chInfo.NumRxStreams
    for iTx = 1:chInfo.NumTxStreams
        if iscell(chInfo.PathDelays)
            txPaaIdx = ceil(iTx/2);
            rxPaaIdx = ceil(iRx/2);
            delay = transpose(chInfo.PathDelays{txPaaIdx,rxPaaIdx});
            delay(end+1:maxTapId) = delay(end);            
            [~, alphaMat] = getTDLTapIndices(tgayChan.SampleRate,delay,tdlType);
        else
            [~, alphaMat] = getTDLTapIndices(tgayChan.SampleRate,transpose(chInfo.PathDelays),tdlType);
        end
        chanTdlStream{iTx,iRx} = squeeze(cirTap(:,:,iTx,iRx)) * alphaMat;
        tapLen(iTx,iRx) = size(chanTdlStream{iTx,iRx},2);
        tapNorm(iTx,iRx) = norm(chanTdlStream{iTx,iRx}(1,:),'fro');
    end
end
if nargin == 3
    chanTdl = chanTdlStream;
else
    normFactor = sqrt(norm(tapNorm,'fro'));
    chanTdl = cell(chInfo.NumTxStreams,chInfo.NumRxStreams);
    for iRx = 1:chInfo.NumRxStreams
        for iTx = 1:chInfo.NumTxStreams
            if normFlag == 0
                chanTdl{iTx,iRx} = chanTdlStream{iTx,iRx};
            elseif normFlag == 1
                chanTdl{iTx,iRx} = sqrt(chInfo.NumTxStreams*chInfo.NumRxStreams) *chanTdlStream{iTx,iRx}/normFactor;
            end
        end
    end
end

end

