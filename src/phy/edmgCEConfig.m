function [P,N_EDMG_CEF]  =  edmgCEConfig(cfgEDMG)
%EDMGCECONFIG returns the EDMG CE mapping matrix and the total number of EDMG-CEF subfield
%
%   [P,N_EDMG_CEF]  =  edmgCEConfig(cfgEDMG)
%
%   P is the EDMG CE mapping matrix. It is a real matrix. The size of this
%   matrix depends on the number of space-time streams.
%
%   cfgEDMG is the format configuration object of type nist.edmgConfig which
%   specifies the parameters for the EDMG format.
%
%   2019~2020 NIST/CLT Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');

N_STS  = sum(cfgEDMG.NumSpaceTimeStreams,2);     % Total number of space-time streams

switch cfgEDMG.PHYType
    case 'SC'        
        if (N_STS <= 2)
            N_EDMG_CEF = 1;
            P = [+1; +1];
        elseif (N_STS <= 4)
            N_EDMG_CEF = 2;
            P = [+1 +1; ...
                +1 +1; ...
                +1 -1;
                +1 -1];
        else
            N_EDMG_CEF = 4;
            P = [+1 +1 +1 +1; ...
                +1 +1 +1 +1; ...
                +1 -1 +1 -1; ...
                +1 -1 +1 -1; ...
                +1 +1 -1 -1; ...
                +1 +1 -1 -1; ...
                +1 -1 -1 +1; ...
                +1 -1 -1 +1];
        end
    case 'OFDM'
        switch N_STS
            case 1
                P = [1 -1];
                N_EDMG_CEF  = 2;
            case 2
                P = [1 -1; ...
                     1  1];
                N_EDMG_CEF  = 2;
            case 3
                w3 = exp(-1j*2*pi/3);
                P = [1 -1 +1;...
                     1  -w3 w3^2;...
                     1 -w3^2 w3^4];
                 N_EDMG_CEF  = 3;
            case 4
                P = [1 -1 +1 +1;...
                     1  1 -1 +1;...
                     1  1  1 -1;...
                     -1 1  1  1; ...
                     ];
                 N_EDMG_CEF  = 4;
            case 5
                P = dftmtx(6);
                P(:,2) = -P(:,2);
                P(:,6) = -P(:,6);
                N_EDMG_CEF  = 6;

            case 6
                P = dftmtx(6);
                P(:,2) = -P(:,2);
                P(:,6) = -P(:,6);
                N_EDMG_CEF  = 6;
                
            case 7
                P44 = [1 -1 +1 +1;...
                     1  1 -1 +1;...
                     1  1  1 -1;...
                     -1 1  1  1; ...
                     ];
                 P = [P44, P44; P44, -P44];
                 N_EDMG_CEF  = 8;

            case 8
                P44 = [1 -1 +1 +1;...
                     1  1 -1 +1;...
                     1  1  1 -1;...
                     -1 1  1  1; ...
                     ];
                 P = [P44, P44; P44, -P44];
                 N_EDMG_CEF  = 8;

        end
end
