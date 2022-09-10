function H = getInterpChannel(channel,delay, fs, varargin)
%%GETINTERCHANNEL returns the digital MIMO matrix at each antenna element
% 
% H = GETINTERCHANNEL(C ,D, NS, Fs) returns the
% baseband MIMO matrix H, given the propagation channel taps C, the delay D
% the number of taps requested NS and sampling rate Fs.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Get params 
T = size(channel,1);
[nRx, nTx] = size(channel{1});

%% Var Init
H = cell(T,1);
sumRxAnt =0;
sumTxAnt = 0;
minDel = zeros(1,T);
maxDel = zeros(1,T);

for i = 1:T
    minDelMimoMat = cellfun(@min, delay{i});
    maxDelMimoMat = cellfun(@max, delay{i});
    minDel(i) = min(minDelMimoMat(:));
    maxDel(i) = max(maxDelMimoMat(:));
end

firstMpc = min(minDel);
lastMpc = max(maxDel);
samples = ceil((lastMpc-firstMpc)*fs);

p = inputParser;
addParameter(p,'samples', samples);
addParameter(p,'offset', 10);
parse(p, varargin{:});
samples = p.Results.samples;
offset = p.Results.offset;
startInterp =  firstMpc - offset*1/fs;
endInterp = startInterp+1/fs*(samples+offset-1);
xq = startInterp:1/fs:endInterp;
%% Interpolation 
% For each channel in time
for t = 1:T 
    ch = channel{t};
    dl = delay{t};
    % For each rx digital chain 
    for rx = 1:nRx
        % For each tx digital chain
        for tx = 1:nTx
            nRxAnt = size(ch{rx,tx},1);
            nTxAnt = size(ch{rx,tx},2);
            % For each rx antennas
            for rxAnt = 1:nRxAnt
                % For each tx antenna
                for txAnt = 1:nTxAnt
                    % Get channel
                    h= ch{rx,tx}(rxAnt,txAnt,:);
                    % Get delay
                    tau = dl{rx,tx};
                    % Interpolate
%                     H{t}(sumRxAnt+rxAnt,sumTxAnt+txAnt,:) = sincInterp(h,tau, samples,fs,firstMpc);
                    H{t}(sumRxAnt+rxAnt,sumTxAnt+txAnt,:) = sincInterp(tau, h, xq, fs);

                end
            end
            sumTxAnt = sumTxAnt + nTxAnt;
        end
        sumTxAnt = 0;
        sumRxAnt = sumRxAnt + nRxAnt;
    end
    sumRxAnt = 0;
end
end