function y = dopplerConv(H,x)
%DOPPLERCONV returns the signal y received after filtering with a multipath
% time-varying channel.
%
%   Y = DOPPLERCONV(H,X)
%   X is the transmit signal of size Ns x Ntx where Ns is the number of samples
%   while Ntx is the number of transmitted signals.
%
%   H is the cell multi user channel. Each entry is a Nrx x Ntx cell array.
%   Each entry is a NP x ND where NP is the number of multi-paths
%   components and ND is the number of doppler instances.
%   ND should either 1 (No doppler) or ND >= Ns (enough doppler instances
%   to cover all the symbols).
%
%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

NUE = length(H);
y = cell(NUE,1);
Nsamp = size(x,1);

for ueID = 1: NUE
    H_ue = H{ueID};
    NRX  = size(H_ue,2);
    NTX  = size(H_ue,1);
    y{ueID} = zeros(Nsamp, NRX);
    
    for rx = 1:NRX
        for tx = 1:1:NTX
            h = H_ue{tx,rx}.';
            Ntaps = size(h,2);
            Nd  = size(h,1);
            assert(Nd == 1 || Nd >=Nsamp, ['ND should either 1 (No doppler)' ...
                'or ND >= Ns (enough doppler instances to cover all the symbols.'])
            x_delay = zeros(Nsamp+Ntaps-1,Ntaps);
            for i = 1:Ntaps
                x_delay(:,i) = conv(x(:,tx),[zeros(1,i-1), 1, zeros(1, Ntaps-i)]);
            end
            x_delay(Nsamp+1:end,:) = [];
            h=h(1:min(Nd,Nsamp ), :);
            y_tmp  = sum(bsxfun(@times, reshape(h, size(h,1), 1, []), ...
                reshape(x_delay, Nsamp, 1, [])), 3);
            y{ueID}(:,rx) = y{ueID}(:,rx) + y_tmp;
        end
    end
end
end