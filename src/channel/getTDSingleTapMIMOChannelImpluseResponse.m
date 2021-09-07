function [oneTapMimoCir,oneTapMimoIdx] = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan,numTxAnt,numSTSVec)
%getTDSingleTapMIMOChannelImpluseResponse Get time-domain one-tap MIMO channel impluse response 
%   
%   [oneTapMimoCir,oneTapMimoIdx] = getTDSingleTapMIMOChannelImpluseResponse(tdMimoChan,numTxAnt,numSTSVec) returns the time-domain one-tap 
%       MIMO channel impluse response and the corresponding index
%
%  Inputs:
%   tdlMimoChan is the time domain MIMO channel, either a numUsers-length cell array with each entry having a 
%       numTxAnt-by-numSTSTot cell subarraies for MU-MIMO; or a numTxAnt-by-numSTSTot cell array with each entry 
%       having numTaps-by-numSamps matrix for SU-MIMO; or a numTxAnt-by-numSTSTot-by-maxTapLen-by-numSamp 4D matrix.
%   numTxAnt is the number of transmit antennas (RF chains).
%   numSTSVec is a numUsers-length row vecotr, each entry is the number of space-time streams of that user.
%   
%  Output:
%   oneTapMimoCir is a numTxAnt-by-numSTSTot MIMO CIR matrix. The numSTSTot is sum of numSTSVec.
%   oneTapMimoIdx is a numTxAnt-by-numSTSTot MIMO CIR index matrix, each entry is the the index of max power tap. 

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(iscell(tdMimoChan),'tdSuMimoChan should be numTxAnt-by-numSTS cell array for single user.');
oneTapMimoCir = complex(zeros(numTxAnt,numSTSVec));
oneTapMimoIdx = complex(zeros(numTxAnt,numSTSVec));

if isscalar(numSTSVec) && size(tdMimoChan,1)==numTxAnt 
    for iTxA = 1:numTxAnt
        for iUserRxAnt = 1:numSTSVec
            tdlCir = tdMimoChan{iTxA,iUserRxAnt};
            [val, idx] = max(abs(tdlCir));
            oneTapMimoCir(iTxA,iUserRxAnt) = tdlCir(idx); % /abs(tapVec(idx));
            oneTapMimoIdx(iTxA,iUserRxAnt) = idx;
        end
    end
else
    % numSTS = numSTSVec
    numSTSTot = sum(numSTSVec);
    assert(length(tdMimoChan)==length(numSTSVec),'length of tdMimoChan) and numSTSVec should be same.')
    numUsers = length(numSTSVec);
    oneTapMimoCir = zeros(numTxAnt,numSTSTot);
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1)); % +(1:numSTSVec(iUser));
        for iTxA = 1:numTxAnt
            for iUserRxAnt = 1:numSTSVec(iUser)
                tdlCir = tdMimoChan{iUser}{iTxA,iUserRxAnt};
                [val, idx] = max(abs(tdlCir));
                oneTapMimoCir(iTxA,stsIdx+iUserRxAnt) = tdlCir(idx); % /abs(tapVec(idx));
                oneTapMimoIdx(iTxA,stsIdx+iUserRxAnt) = idx;
            end
        end
    end
end

end

