function [zpChan] = reformatTDLMIMOChannelZeroPadding(tdlMimoChan,outputType,varargin)
%reformatTDLMimoChanZeroPadding Zero padding
%   This function reformats the tapped delay line MIMO channel with zero padding at each MIMO subchannel per Doppler
%   spread samples.
%   Input:
%   tdlMimoChan is time-domain channel impluse response TDL with the format of either a numTxAnt-by-numSTS cell 
%       array whose entries are maxTapLen-by-numSamp matricies; or a numSTS-by-numTxAnt-by-maxTapLen-by-numSamp 
%       4-D matrix. 
%   outputType is either a 'MatrixArray' string or 'CellArray' string.
%   varargin{1} is the scalar of maxNumTaps. It is optional controllor to set the maximum number of TDL taps for zero
%       padding.
%   Output:
%   zpChan is the channel impluse response TDL matrix with zero padding, either a numTxAnt-by-numSTS cell 
%       array whose entries are maxTapLen-by-numSamp matricies; or a numSTS-by-numTxAnt-by-maxTapLen-by-numSamp 
%       4-D matrix. 
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if iscell(tdlMimoChan)
    % tdlMimoChan should be a numTxAnt-by-numSTSTot cell array.
    assert(all(reshape(cellfun(@(x) ismatrix(x), tdlMimoChan), [],1)),...
        'Any cell entries of tdlMimoChan should be a TDL matrix.');
    [numTxAnt,numSTS] = size(tdlMimoChan);
    maxTapLen = unique(cellfun(@(x) size(x,1), tdlMimoChan));
    numSamp = unique(cellfun(@(x) size(x,2), tdlMimoChan));
    if ~isscalar(maxTapLen)
        maxTapLen = max(maxTapLen);
    end
    assert(length(numSamp) ==1, 'TDL should have same number of doppler samples');
elseif ndims(tdlMimoChan) >= 3
    [numSTS,numTxAnt,maxTapLen,numSamp] = size(tdlMimoChan);
else
    error('tdlMimoChan should be either a numTxAnt-by-numSTS cell array or a 4-D matrix.');
end

if nargin == 3
    maxNumTaps = varargin{1};
    if maxNumTaps ~= maxTapLen && ~isempty(maxNumTaps)
        maxTapLen = maxNumTaps;
    end
end


if strcmp(outputType,'MatrixArray')
    zpChan = zeros(numSTS,numTxAnt,maxTapLen,numSamp);
elseif strcmp(outputType,'CellArray')
    zpChan = cell(numTxAnt,numSTS);
else
    error('outputType should be either MartrixArray or CellArray');
end

for iTxA = 1:numTxAnt
    for iSTS = 1:numSTS
        if iscell(tdlMimoChan)
            tdlTaps = tdlMimoChan{iTxA,iSTS};
        else
            tdlTaps = reshape(tdlMimoChan(iSTS,iTxA,:,:),[],numSamp);
        end
        tempTdlLen = size(tdlTaps,1);
        if  tempTdlLen < maxTapLen
            if strcmp(outputType,'MatrixArray')
                zpChan(iSTS,iTxA,:,:) = [tdlTaps; zeros(maxTapLen-tempTdlLen,numSamp)]; %+++SB check this case
            elseif strcmp(outputType,'CellArray')
                zpChan{iTxA,iSTS} = [tdlTaps; zeros(maxTapLen-tempTdlLen,numSamp)];
            else
            end
        else
            if strcmp(outputType,'MatrixArray')
                zpChan(iSTS,iTxA,:,:) = tdlTaps(1:maxTapLen,:);
            elseif strcmp(outputType,'CellArray')
                zpChan{iTxA,iSTS} = tdlTaps(1:maxTapLen,:);
            else
            end
        end
    end
end


end

