function sr = edmgSampleRate(cfgEDMG)
%edmgSampleRate Return the nominal sample rate
%
%   SR = edmgSampleRate(CFGFORMAT) returns the nominal sample rate for the
%   specified format configuration object, CFGFORMAT.
%
%   SR is the sample rate in samples per second.
%
%   CFGFORMAT is the EDMG format configuration object.
%
%   Example: Return sample rate for a VHT format configuration. 
%
%   cfgEDMG = nist.edmgConfig;
%   fs = edmgSampleRate(cfgEDMG)
%
%   Copyright 2017-2018 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

NCB = cfgEDMG.NumContiguousChannels;
if strcmp(phyType(cfgEDMG),'OFDM')
    sr = NCB*2640e6;
else
    sr = NCB*1760e6;
end


end
