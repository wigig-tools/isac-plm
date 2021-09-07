function y = edmgHeaderB(cfgEDMG)
%edmgHeaderB EDMG header B processing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgHeaderB(CFGEDMG) generates the EDMG format Header-B field time-domain
%   waveform for SC and OFDM PHYs.
%
%   Y is the time-domain EDMG Header-B field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   CFGEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   Y = edmgHeader(PSDU,CFGEDMG) generates the EDMG format Header-B field
%   time-domain waveform for Control PHY.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

narginchk(1,2); % Expect at least 1 input;

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

coder.internal.errorIf(strcmp(phyType(cfgEDMG),'Control'),'nist:edmgHeaderB:NoPSDUControl');

for u=1:cfgEDMG.NumUsers
    headerBits = nist.edmgHeaderBBits(cfgEDMG,u);

    % Encode header bits
    encodedBits = nist.edmgHeaderEncode(headerBits,cfgEDMG,'EDMG-Header-B',u);

    % Modulate header bits
    y = nist.edmgHeaderModulate(encodedBits,cfgEDMG);
end

end