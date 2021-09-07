function nsamp =  getChannelDopplerSamples(index,isDopplerOn, varargin)
%GETCHANNELDOPPLERSAMPLES returns the number of doppler samples for each
%channel tap. 
%  
%   N = GETCHANNELDOPPLERSAMPLES(I,DOPPLER) returns the number of 
%   doppler samples N based one the length of the packet with field index 
%   I. DOPPLER defines if doppler effect is used in the simulation 
%   specified as 0 (static) or 1 (doppler). N is 1 in static environments.
%
%   N = GETCHANNELDOPPLERSAMPLES(I,DOPPLER, S1, S2, ..,, SN) returns the 
%   number of doppler samples nsamp based one the length of the  packet 
%   with field index index adding the extra samples S1, S2, .., SN.
%
%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

extraSamples = sum(cell2mat(varargin));
if isDopplerOn
    nsamp = index.EDMGData(2)+extraSamples;
else
    nsamp = 1;
end

end