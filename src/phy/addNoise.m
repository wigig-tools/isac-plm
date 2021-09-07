function rxNoisySig = addNoise(rxSig, noiseVarLin)
%addNoise Adding Gassuain Noise at MIMO receiver at each user
%   This function applies additive white Gaussian noise to received signals on each users' MIMO receiver
%   
% Inputs:
%   rxSig is the numUsers-length received signal cell array, each entry is numSamp-by-numRxAnt matrix.
%   noiseVarLin is the noise variance in linear.
%
% Output
%   rxNoisySig is the the numUsers-length received signal cell array after applying noise, each entry is 
%       numSamp-by-numRxAnt matrix.

%   2019-2020 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%# codegen

assert(iscell(rxSig) && isvector(rxSig),'rxSig should be cell array vector.');
numUsers = length(rxSig);

if isscalar(noiseVarLin)
    noiseVarLinActSubc = noiseVarLin*ones(1,numUsers);
elseif isvector(noiseVarLin) && length(noiseVarLin)==numUsers
    noiseVarLinActSubc = noiseVarLin;
elseif iscell(noiseVarLin) && length(noiseVarLin)==numUsers
    noiseVarLinActSubc = cell2mat(noiseVarLin);
else
    error('The format of noiseVarLin is incorrect.');
end


rxNoisySig = cell(numUsers,1);
for iUser = 1:numUsers
    numRxAnt = size(rxSig{iUser},2);
    sigLen = size(rxSig{iUser},1);
    rxNoisySig{iUser} = zeros(sigLen,numRxAnt);
    for iUserRxAnt = 1:numRxAnt
        sizefadSigSeqPerUser = size(rxSig{iUser}(:,iUserRxAnt));
        noise = sqrt(noiseVarLinActSubc(iUser)/2) * (randn(sizefadSigSeqPerUser)+ 1i * randn(sizefadSigSeqPerUser));
        rxNoisySig{iUser}(:,iUserRxAnt) = rxSig{iUser}(:,iUserRxAnt) + noise;
    end
end

end