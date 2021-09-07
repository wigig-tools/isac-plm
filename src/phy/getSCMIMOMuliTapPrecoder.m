function [precodMat,detCir] = getSCMIMOMuliTapPrecoder(tdMimoChan,numTxAnt,numSTSVec,varargin)
%getSCMIMOMuliTapPrecoder Time-Tomain Multi-Tap Precoder for Single-Carrier Mode
%   
%   [precodMat] = getSCMIMOMuliTapPrecoder(tdMimoChan,numTxAnt,numSTSVec) returnes single-carrier MIMO multi-tap 
%       precoding matrix based on matrix determination and adjugate of channel matrix.
%
%   Inputs:
%   tdMimoChan is a numUsers-length cell array of time-domain MIMO channels. Each cell holds the user's time-domain
%       MIMO channel impluse response (CIR), each entry is a numTxAnt-by-numRxAnt subcell array, which contains the 
%       maxTdlLen-by-1 column vectors. maxTdlLen is the maximum TDL tap length.
%   numTxAnt is the number of transmit antennas (RF chains).
%   numSTSVec is a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   varargin is optional.
%   
%   Output:
%   precodMat is a numTxAnt-by-numSTSTot-by-maxPowIdx time-domain multi-user precoding matrix.
%   detCir is a 1-by-1-by-maxPowIdx time-domain determination matrix of MU CIR.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(3,4);
assert(iscell(tdMimoChan),'tdMimoChan should be a cell array.');

if nargin==3
    % reformat MU-MIMO CIR
    tdMuMimoChan = reformatMUMIMOChannelImpluseResponse(tdMimoChan,numTxAnt,numSTSVec);
    % Get effective taps
    idxCir = find(squeeze(10*log10(sum(sum(abs(tdMuMimoChan(:,:,1:end)).^2)))>-100));
    if ~isempty(idxCir)
        tdMuMimoChan = tdMuMimoChan(:,:,idxCir(1):idxCir(end));
    end
    % Time-doamin MU multi-tap Precoding
    numSTSTot = size(tdMuMimoChan,1);
    % Calculate determination of channel matrix
    detCir = getDet(tdMuMimoChan);
    % Calculate adjugate matrix of channel matrix
    adjCir = getAdj(tdMuMimoChan);
    if any(detCir ~= zeros(size(detCir)))
        weight = adjCir;
    else
        weight = eye(numSTSTot,numTxAnt);
    end
% else
%     numUsers = length(numSTSVec);
%     % reformat MU-MIMO CIR
%     tdMuMimoChan = reformatMUMIMOChannelImpluseResponse(tdMimoChan,numTxAnt,numSTSVec);
%     % Get effective taps
%     idxCir = find(squeeze(10*log10(sum(sum(abs(tdMuMimoChan(:,:,1:end)).^2)))>-100));
%     if ~isempty(idxCir)
%         tdMuMimoChan = tdMuMimoChan(:,:,idxCir(1):idxCir(end));
%     end
%     Time-doamin MU multi-tap Precoding
%     numSTSTot = size(tdMuMimoChan,1);
%     [tdAntSelcMimoChan,idxMap] = getMUMIMOAntennaSelection(tdMuMimoChan,numSTSVec);
%     for iUser = 1:numUsers
%         stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
%         % Calculate determination of channel matrix
%         detCir = getDet(tdAntSelcMimoChan{iUser});
%         % Calculate adjugate matrix of channel matrix
%         adjCir = getAdj(tdAntSelcMimoChan{iUser});
%         if any(detCir ~= zeros(size(detCir)))
%             weight(stsIdx,idxMap{iUser},:) = adjCir;
%         else
%             weight(stsIdx,stsIdx,:) = eye(numSTSVec(iUser),numSTSVec(iUser));
%         end
%     end
end
% Limit number of taps of precoding matrix
idxWeight = find(squeeze(10*log10(sum(sum(abs(weight(:,:,1:end)).^2)))>-100));
if ~isempty(idxWeight)
    weight = weight(:,:,idxWeight(1):idxWeight(end));
end
precodMat = permute(weight,[2,1,3]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tdSuMimoChan,idxMap] = getMUMIMOAntennaSelection(tdMuMimoChan,numSTSVec)
% Get the MU-MIMO Channel via Antenna Selection
    numUsers = length(numSTSVec);
    numTxAnt = size(tdMuMimoChan,2);
    idxTxAnt = [1:numTxAnt];
    idxArg = 0;
    idxMap = cell(numUsers,1);
    tdSuMimoChan = cell(numUsers,1);
    % Get combination of choosing numSTS elements from vector idxTxAnt 
    for iUser = 1:numUsers
        numSTS = numSTSVec(iUser);
        if idxArg ~= 0
            idxTxAnt(comb(idxArg,:)) = [];
        end
        comb = nchoosek(idxTxAnt,numSTS);
        detSuChan = [];
        for iComb = 1:size(comb,1)
            stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
            antIdx = comb(iComb,:);
            suMimoChan = tdMuMimoChan(stsIdx,antIdx,:);
            detSuChan(iComb,:) = squeeze(getDet(suMimoChan));
        end
        [~,idxArg] = max(sum(abs(detSuChan),2),[],1);
        tdSuMimoChan{iUser} = tdMuMimoChan(stsIdx,comb(idxArg,:),:);
        idxMap{iUser} = comb(idxArg,:);
    end
end
