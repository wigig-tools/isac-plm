function [loadCache, cachePath] =  checkCacheValidity(scenarioPath)
%CHECKCACHEVALIDITY

% CHECKCACHEVALIDITY(p) search in the scenario path p if a chache file is
% available. Return 1 if the chache is available
%
% [cv, cp] = CHECKCACHEVALIDITY(p) search in the path p if a chache file is
% available. Return 1 if the chache is available and the chache path cp.

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


cachePath = fullfile(scenarioPath, 'cache.mat');
loadCache = 0;
if isfile(cachePath)
    fileChannel = dir(fullfile(scenarioPath, 'Input/qdChannel/'));
    fileChannel(1:2) = [];
    fileCodebook = dir(fullfile(pwd, 'src/data/'));
    fileCodebook(1:2) = [];
    fileInput = dir(fullfile(scenarioPath, 'Input'));
    fileInput(1:2) = [];
    fileCache = dir(cachePath);
    loadCache = all([[fileChannel.datenum], [fileCodebook.datenum],[fileInput.datenum]]<fileCache.datenum);
end
end