function [mimoChanOut] = reformatSUMIMOChannel(mimoChanIn,domainType,varargin)
%reformatSUMIMOChannel Reformat MIMO channel at time or frequency domain in single-user basis.
%   This function reformat the MIMO channel in time or frequency domain for a specific user. When the function is used 
%   for reformating the output of channel estimator, it converts the numRxAnt-by-numTxAnt-by-numTaps 3D time-domain 
%   channel matrix array to a numTxAnt-by-numRxAnt cell array, each entry is a numTaps-by-1 vector; or converts the 
%   numSubc-by-numRxAnt-numTxAnt 3D frequency-domain channel matrix array to numSubc-by-numTxAnt-numRxAnt matrix array.
%   When this function is used for reformating the numTxAnt-by-numRxAnt time domain channel cell array with each entry
%   in numTaps-by-numSamp matrix, the output is numRxAnt-by-numTxAnt-by-maxTapLen-by-numSamp 4D channel matrix array.
%   
% Input
%   mimoChanIn is a numRxAnt-by-numTxAnt-by-numTaps 3D time-domain channel matrix array or numSubc-by-numRxAnt-numTxAnt
%       3D frequency-domain channel matrix array; or numTxAnt-by-numRxAnt time domain channel cell array with each entry
%       in numTaps-by-numSamp matrix.
%   
% Output
%   mimoChanOut is a numTxAnt-by-numRxAnt cell array, each entry is a numTaps-by-1 vector; 
%       or numSubc-by-numTxAnt-numRxAnt matrix array; 
%       or numRxAnt-by-numTxAnt-by-maxTapLen-by-numSamp 4D channel matrix array.
%
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if nargin>2
    maxTdlLen = varargin{1};
end
  
if strcmp(domainType,'TD') || strcmp(domainType,'TimeDomain')
    % Channel Impluse Response
    if iscell(mimoChanIn)
        % Check  [numTxAnt,numRxAnt] = size(mimoChanIn);
        mimoChanOut = reformatTDLMIMOChannelZeroPadding(mimoChanIn,maxTdlLen,'MatrixArray');
    else
        assert(isnumeric(mimoChanIn),'mimoChanIn should be numeric.');
        if ismatrix(mimoChanIn)
            numRxAnt = 1;
            numTxAnt = 1;
            [numTaps, numSamp] = size(mimoChanIn);
            if ~iscolumn(mimoChanIn)
                mimoChanIn = transpose(mimoChanIn);
            end
            mimoChanOut = cell(numTxAnt,numRxAnt);
            mimoChanOut{1,1} = mimoChanIn;
        elseif ndims(mimoChanIn) == 3
            [numRxAnt,numTxAnt,numTaps] = size(mimoChanIn);
            mimoChanOut = cell(numTxAnt,numRxAnt);
            for iTxAnt = 1:numTxAnt
                for iRxAnt = 1:numRxAnt
                    tdlChanVec = squeeze(mimoChanIn(iRxAnt,iTxAnt,:));
                    if ~iscolumn(tdlChanVec)
                        tdlChanVec = transpose(tdlChanVec);
                    end
                    mimoChanOut{iTxAnt,iRxAnt} = tdlChanVec;
                end
            end
        else
            error('Time-domain channel matrix mimoChanIn should be either 1-by-numSamp or numRxAnt-by-numTxAnt-by-numSamp.');
        end
    end
elseif strcmp(domainType,'FD') || strcmp(domainType,'FreqDomain')
    % Channel Frequency Response
    assert(isnumeric(mimoChanIn),'mimoChanIn should be numeric.');
    if isvector(mimoChanIn)
        if isrow(mimoChanIn)
            mimoChanIn = transpose(mimoChanIn);
        end
        mimoChanOut = mimoChanIn;
    elseif ndims(mimoChanIn) == 3
        numSubc = size(mimoChanIn,1);
        numRxAnt = size(mimoChanIn,2);
        numTxAnt = size(mimoChanIn,3);
        mimoChanOut = zeros(numSubc,numTxAnt,numRxAnt);
        for iTxAnt = 1:numTxAnt
            for iRxAnt = 1:numRxAnt
                mimoChanOut(:,iTxAnt,iRxAnt) = squeeze(mimoChanIn(:,iRxAnt,iTxAnt));
            end
        end
    else
        error('Frequency-domain channel matrix mimoChanIn should be either numSubc-by-1 or numSubc-by-numRxAnt-by-numTxAnt.');
    end
else
    error('domainType should be either TimeDomain (TD) or FreqDomain (FD).');
end

end

