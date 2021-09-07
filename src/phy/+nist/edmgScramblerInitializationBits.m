function y = edmgScramblerInitializationBits(cfgEDMG,varargin) 
%dmgScramblerInitializationBits DMG scrambler initialization bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgScramblerInitializationBits(CFGDMG) return the scrambler
%   initialization bits as 7-by-1 binary column vector. The scrambler
%   initialization bits B7-B1 are mapped to X7-X1 as specified in IEEE Std
%   802.11ad-2012, Section 21.3.9.  
%
%   CFGDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2020~20201 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

if nargin == 2
    userIdx = varargin{1};
else
    userIdx = [];
end

if strcmp(phyType(cfgEDMG),'Control')
    if isscalar(cfgEDMG.ScramblerInitialization)
        y = [1; 1; 1; int8(de2bi(cfgEDMG.ScramblerInitialization(1),4,'left-msb')).'];
    else
        y = [1; 1; 1; int8(cfgEDMG.ScramblerInitialization(1:4))];
    end
else
    if isempty(userIdx)
        % Single-user mode
        if isscalar(cfgEDMG.ScramblerInitialization(1))
            y = int8(de2bi(cfgEDMG.ScramblerInitialization(1),7,'left-msb')).';
        else
            y = int8(cfgEDMG.ScramblerInitialization);
        end
    else
        % Multi-user mode
        if isscalar(cfgEDMG.ScramblerInitialization)
            y = int8(de2bi(cfgEDMG.ScramblerInitialization(1),7,'left-msb')).';
        elseif iscolumn(cfgEDMG.ScramblerInitialization)
            y = int8(cfgEDMG.ScramblerInitialization);
        elseif isrow(cfgEDMG.ScramblerInitialization)
            y = int8(de2bi(cfgEDMG.ScramblerInitialization(userIdx),7,'left-msb')).';
        else
            error('InvalidScramInitValue of nist.edmgConfig.');
        end
    end
end
end