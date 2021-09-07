function fadeSig = passBlockFadingChannel(txSig,tdlCir)
%passBlockFadingChannel Pass multi-path fading channel
%   This function passes the transmit signal sequence over block fading channel without adding noise.
%
%   Inputs:
%   txSig is the numSamp-by-numTxAnt matrix of transmit symbol sequency over multiple tranmsit antenna arrays.
%   tdlCir is the numUsers-length cell array of tapped delay line (TDL) channel impluse reponse (CIR), each entry is the 
%       numTxAnt-by-numRxAnt sub cell array, which includes numSamp-by-numTaps matrix.
%   
%   Output
%   fadeSig is the symbol sequneces after block fading channel

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

assert(~isempty(tdlCir),'tdlCir should not be empty.');
assert(size(txSig,2)==size(tdlCir{1},1),'numTxAnt does not match.');
numUsers = length(tdlCir);
fadeSig = cell(numUsers,1);
numSamp = size(txSig,1);
for iUser = 1:numUsers
    [numTxAnt,numRxAnt] = size(tdlCir{iUser});
    fadeSig{iUser} = zeros(numSamp,numRxAnt);
    for iUserRxAnt = 1:numRxAnt
        % Combined mumTxAnt channels with MU interference at iUserRxAnt
        for iTxA = 1:numTxAnt
            % Time-domain channel filtering
            fadSigTmp = conv(txSig(:,iTxA), tdlCir{iUser,1}{iTxA,iUserRxAnt}, 'full');
            fadSigTmp = fadSigTmp(1:numSamp,:);
            fadeSig{iUser}(:,iUserRxAnt) = fadSigTmp + fadeSig{iUser}(:,iUserRxAnt);
        end
    end
end


end

