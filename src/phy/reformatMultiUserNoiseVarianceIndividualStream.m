function [noiseVarOut] = reformatMultiUserNoiseVarianceIndividualStream(noiseVarIn,numSTSVec)
%reformatMultiUserNoiseVarianceIndividualStream Reformat multi-user individual noise variance in stream level
%   
%   [noiseVarDiag] = reformatMultiUserNoiseVarianceIndividualStream(noiseVarIn,numSTSVec) reformats the noise variance into
%       multi-user individual stream-level
%
%   Inputs:
%   noiseVarIn is the noise variance in one of the following formats: 
%       a scalar
%       a numSTSTot-length vector
%       a numUsers-by-numSTS matrix
%       a numUsers-length cell array, each cell holds a 1-by-numSTS vector
%
%   Output:
%   noiseVarOut is the numSTSTot-length noise variance vector

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

numSTSTot = sum(numSTSVec);
numUsers = length(numSTSVec);
if iscell(noiseVarIn)
    noiseVarOut = zeros(numSTSTot,1);
    for iUser = 1:numUsers
        stsIdx = sum(numSTSVec(1:iUser-1))+(1:numSTSVec(iUser));
        noiseVarOut(stsIdx,1) = noiseVarIn{iUser};
    end
else
    assert(isnumeric(noiseVarIn),'noiseVarIn should be numeric.');
    if isscalar(noiseVarIn)
        noiseVarOut = noiseVarIn * ones(numSTSTot,1);
    elseif isvector(noiseVarIn) && length(noiseVarIn)>1
        assert(length(noiseVarIn)==numSTSTot,'The length of noiseVar should be equal to numSTSTot.');
        noiseVarOut = noiseVarIn;
    elseif ismatrix(noiseVarIn) && ~isvector(noiseVarIn)
        assert(numel(noiseVarIn)==numSTSTot,'The total number of elements in noiseVarIn should be equal to numSTSTot.');
        assert(size(noiseVarIn,1) == numUsers,'The size of dim-2 in noiseVar should be numUsers');
        noiseVarOut = noiseVarIn(:);    
    else
        error('noiseVarIn should be one of scalr, vector or cell');
    end
end

end

