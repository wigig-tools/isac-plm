function fdMimoChan = getMIMOChannelFrequencyResponse(tdMimoChan,fftLength)
%getMIMOChannelFrequencyResponse get MIMO channel frequency response
%   This function gets MIMO channel frequency response (CFR) from various format of time domain channel impluse
%   response for single user or multi-user MIMOs.
%   
%   Inputs:
%   tdlMimoChan is the time domain MIMO channel, either a numUsers-length cell array with each entry having a 
%       numTxAnt-by-numSTSTot cell subarraies for MU-MIMO; or a numTxAnt-by-numSTSTot cell array with each entry 
%       having numTaps-by-numSamps matrix for SU-MIMO; or a numTxAnt-by-numSTSTot-by-maxTapLen-by-numSamp 4D matrix.
%   fftLength is the length of FFT/IFFT operation
%   
%   Output:
%   fdMimoChan is either the numUser-length MU MIMO CFR cell array, each entry is a 
%       fftSize-by-numSamp-by-numTx-by-numSTS 4D matrix of single user MIMO CFR;
%       or a fftSize-by-numSamp-by-numTx-by-numSTS 4D matrix of single user MIMO CFR.
%   
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen


if iscell(tdMimoChan{1,1})
    numUsers = length(tdMimoChan);
    fdMimoChan = cell(numUsers,1);
    for iUser = 1:numUsers
        fdMimoChan{iUser} = getSUMIMOChannelFrequencyResponse(tdMimoChan{iUser},fftLength);
    end
else
    fdMimoChan = getSUMIMOChannelFrequencyResponse(tdMimoChan,fftLength);
end

end % End of function
