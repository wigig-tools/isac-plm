function y = edmgLHeader(varargin)
%edmgLHeader EDMG L-header processing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgLHeader(CFGEDMG) generates the EDMG format L-Header field time-domain
%   waveform for SC and OFDM PHYs.
%
%   Y is the time-domain EDMG Header field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   Y = edmgLHeader(PSDU,CFGDMG) generates the EDMG format L-Header field
%   time-domain waveform for Control PHY.
%
%   PSDU is a column vector containing the PSDU bits.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,2); % Expect at least 1 input;

% nist.edmgConfig
if isa(varargin{1},'nist.edmgConfig')
    cfgEDMG = varargin{1};
    coder.internal.errorIf(strcmp(phyType(cfgEDMG),'Control'),'nist:edmgLHeader:NoPSDUControl');
    psdu = zeros(0,1); % Empty PSDU
else
    narginchk(2,2);
    psdu = varargin{1};
    cfgEDMG = varargin{2};
end

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

headerBits = nist.edmgLHeaderBits(cfgEDMG);

% Encode header bits
encodedBits = nist.edmgHeaderEncode(headerBits,psdu,cfgEDMG,'L-Header');

% Modulate header bits
y = nist.edmgHeaderModulate(encodedBits,cfgEDMG);

end