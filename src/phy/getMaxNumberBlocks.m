function [numBlksMax,varargout] = getMaxNumberBlocks(cfgEDMG)
%getMaxNumberBlocks Compute the maximum number of SC symbol blocks over all users
%
%   Input:
%   cfgEDMG is the EDMG configuration object.
%   Outputs:
%   numBlksMax is the maximum number of SC symbol blocks or OFDM symbols over all users
%   varargout is the optional user index of the user's orignal number of SC symbol blocks 
%   or OFDM symbols same to numBlksMax.
%   
%   2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

% IEEE P802.11ay Draft 7.0, Section 28.6.9.2.4 MU PPDU padding
if strcmp(cfgEDMG.PHYType,'OFDM')
    userIdxMax = 1;
    numSymbMax = 0;
    for u = 1:cfgEDMG.NumUsers
        info = nist.edmgOFDMEncodingInfo(cfgEDMG,u);
        % Looking for the maximum number of OFDM symbols
        if numSymbMax < info.NSYMS
            numSymbMax = info.NSYMS;
            userIdxMax = u;
        end
    end
    numBlksMax = numSymbMax;
% IEEE P802.11ay Draft 7.0, Section 28.6.9.2.4 MU PPDU padding
elseif strcmp(cfgEDMG.PHYType,'SC')
    userIdxMax = 1;
    numBlksMax = 0;
    for u = 1:cfgEDMG.NumUsers
        info = nist.edmgSCEncodingInfo(cfgEDMG,u);
        % Looking for the maximum number of SC blocks
        if numBlksMax < info.NBLKS
            numBlksMax = info.NBLKS;
            userIdxMax = u;
        end
    end
else
    error('PHYType should be either OFDM or SC.');
end

if nargout>1
    varargout{1} = userIdxMax;
end

end

