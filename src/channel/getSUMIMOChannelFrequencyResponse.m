function mimoCfr = getSUMIMOChannelFrequencyResponse(mimoCir,fftSize)
%getSUMIMOChannelFrequencyResponse Get the channel frequency response for single user MIMO channel
%   This function generate the single-user SU MIMO channel frequency response (CFR) based on the users time-domain
%   MIMO channel impluse response (CIR).
%
% Input:
%   mimoCir is the single user MIMO channel impuluse respose. It can be a numTx-by-numSTS cell array, each entry
%       is a maxTapLen-by-numSamp matrix. Otherwise, it can be a numSTS-by-numTx-by-maxTapLen-by-numSamp 4D matrix.
%   fftSize is the length of FFT/IFFT operation
%   
% Output:
%   mimoCfr is a fftSize-by-numSamp-by-numTx-by-numSTS 4D matrix of single user MIMO channel frequency response.
%   
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen


% MIMO
if iscell(mimoCir)
    [numTx,numSTS] = size(mimoCir);
    maxTapLen = unique(cellfun(@(x) size(x,1), mimoCir));
    numSamp = unique(cellfun(@(x) size(x,2), mimoCir));
    assert(length(numSamp) ==1, 'TDL should have same number of doppler samples');
%     assert(length(maxTapLen) ==1, 'TDL should have same number of delay samples');
%     if length(maxTapLen)>1
%         maxTapLen = max(maxTapLen);
%     end
    mimoCfr = zeros(fftSize,numSamp,numTx,numSTS);
    for iTxA = 1:numTx
        for iRx = 1:numSTS
            tdlCir = mimoCir{iTxA,iRx};
            mimoCfr(:,:,iTxA,iRx) = getSISOChannelFrequencyResponse(tdlCir,fftSize); % Nfft-by-Nt-by-Nr
        end
    end
else
    [numSTS,numTx,maxTapLen,numSamp] = size(mimoCir);
    mimoCfr = zeros(fftSize,numSamp,numTx,numSTS);
    for iTxA = 1:numTx
        for iRx = 1:numSTS
            tdlCir = squeeze(mimoCir(iRx,iTxA,:,:));
            mimoCfr(:,:,iTxA,iRx) = getSISOChannelFrequencyResponse(tdlCir,fftSize); % Nfft-by-Nt-by-Nr
        end
    end
end

end
% End of function


function chanPostFFTShift = getSISOChannelFrequencyResponse(tdlChan,fftSize)

assert(ismatrix(tdlChan),'The tdlChan should be a maxTapLen-by-numSamp matrix.');

chanPostFFT = fft(tdlChan,fftSize,1);
if isreal(chanPostFFT)
    chanPostFFTShift = complex(fftshift(chanPostFFT,1), 0);
else
    chanPostFFTShift = fftshift(chanPostFFT,1);
end

end
% End of function

