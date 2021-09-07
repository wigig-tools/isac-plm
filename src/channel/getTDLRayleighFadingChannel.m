function [tdlChan] = getTDLRayleighFadingChannel(numSamp,tapLen,arrivalDelay,pdpMethod)
%getTDLRayleighFadingChannel Generate Tap-delay-line (TDL) multi-path Rayleigh fading channel
% Inputs
%     numSamp: number of samples of channel realization
%     tapLen: number of taps
%     arrivalDelay: Starting arrival delay period in samples of all taps (gap between index 0 and first tap); 
%       = 0 for no delay (default)
%     pdpMethod: Method of power delay profile (PDP) for random channel generation
%       :'PS' for phase shift with equal distributed PDP normalized by sqrt sum of all tap power per sample; 
%       :'Equ' for Equal distributed PDP normalized by sqrt sum of all tap power per sample;
%       :'Exp' for Exponential distributed PDP normalized by sqrt sum of all tap power per sample.
% OUTPUT
%     tdlChan: TDL channel matrix with size (delay+tapLen) by numSamp

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

assert(numSamp>=1,'numSamp should be >= 1.');
assert(tapLen>=1,'tapLen should be >= 1.');
assert(arrivalDelay>=0,'arrivalDelay should be >= 0.');
assert(ismember(pdpMethod,{'PS','Equ','Exp'}),'pdpMethod should be one of PS, Equ, Exp');

if strcmp(pdpMethod,'PS')   % phase shift
    rndPhase= -pi + (2*pi).*rand(numSamp,tapLen);
    tdlCir = exp(1i*rndPhase);
    tdlCir = tdlCir ./ sqrt(sum(abs(tdlCir).^2,2));
else
    tdlReal = sqrt(1/2) * randn(numSamp,tapLen);    % Equal power
    tdlImag = sqrt(1/2) * randn(numSamp,tapLen);    % Equal power
    tdlCir = (tdlReal + 1i*tdlImag);
    if tapLen > 1
        if strcmp(pdpMethod,'Equ') % Equal power delay
            tdlCir = tdlCir ./ sqrt(sum(abs(tdlCir).^2,2));
        elseif strcmp(pdpMethod,'Exp') % Exponential power delay 
            tapPow = zeros(size(tdlCir));
            for iTap = 1:tapLen
                tapPow(:,iTap) = abs(tdlCir(:,iTap)).^2 * exp(-(iTap-1));
                tdlCir(:,iTap) = tdlCir(:,iTap) * sqrt(exp(-(iTap-1)));
            end
            tdlCir = tdlCir ./ sqrt(sum(tapPow,2));
        else
            error('tdlMethod should be PS, Equ, Exp.');
        end
    end
end

% Add tap delay
tdlChan = [zeros(arrivalDelay,numSamp); transpose(tdlCir)];

end

% End of function