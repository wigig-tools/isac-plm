function constValue = getConst(constName)
%%GETCONST Constants
%
%   V = GETCONST(N) returns the value of the constant V specified by the
%   name N. N can be any entry from the following list:
%
%   N              Description
%   ------------------------------
%   'lightSpeed'       The speed of light in vacuum (meter/second)

%   2022 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.

switch(constName)
    case 'lightSpeed'
        constValue = 299792458;
    otherwise
        error('Constant not defined')
end
end