function mcsTable = edmgMCSRateTable(cfgEDMG)
%getRateTable Select the Rate parameters for EDMG OFDM/SC formats
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   mcsTable = getRateTable(CFGFORMAT) returns the modulation and coding
%   parameters for the format configuration object CFGFORMAT. 

% References:
% [1] IEEE Std 802.11ad-2012
% [2] IEEE Std 802.11-2016
% [3] IIEE TGay Spec D7.0

%   Copyright 2015-2018 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

validateattributes(cfgEDMG,{'nist.edmgConfig'},{'scalar'},mfilename,'EDMG format configuration object');
        
if strcmp(cfgEDMG.PHYType, 'OFDM')
    ofdmInfo = nist.edmgOFDMInfo(cfgEDMG);
    mcsTable = getEDMGMCSTable(cfgEDMG, ofdmInfo.NSD);
else
    % Control or SC Mode
    mcsTable = getEDMGMCSTable(cfgEDMG, []);
end

end


function mcsTable = getEDMGMCSTable(cfgFormat, NSD)

numUsers = cfgFormat.NumUsers;
numSS = cfgFormat.NumSpaceTimeStreams / (((numUsers == 1) && cfgFormat.STBC) + 1);
% MCS = repmat(cfgFormat.MCS, 1, numUsers/length(cfgFormat.MCS));
MCS = cfgFormat.MCS;

[rate, NCBPSS, NBPSCS, NCBPS, NDBPS, NCWMIN, repetition] = deal(zeros(1, numUsers));

for u = 1:numUsers
    [rate(u), NCBPSS(u), NBPSCS(u), NCBPS(u), NDBPS(u), NCWMIN(u), repetition(u)] = ...
        getEDMGMCSTableForOneUser(MCS(u), NSD, numSS(u));
end
mcsTable = struct( ...
    'Rate',       rate, ...
    'NCBPSS',     NCBPSS, ...
    'NBPSCS',     NBPSCS, ...
    'NCBPS',      NCBPS, ...
    'NDBPS',      NDBPS, ...
    'NCWMIN',     NCWMIN, ...
    'Repetition', repetition, ...
    'NSS',        numSS, ...  % Add for EDMG
    'NSD',        NSD ...  % Add for EDMG
    );
end


function [rate, NCBPSS, NBPSCS, NCBPS, NDBPS, NCWMIN, repetition] = getEDMGMCSTableForOneUser(mcs, Nsd, Nss)
    
    if isempty(Nsd)
    % Control or SC modulation
        switch mcs
            % Control, Table 28-48
            case 0 % 'DBPSKK'
                NCBPSS = 1;
                rate = 1/2;
                repetition = 1;
                NCWMIN = 0; % Not applicable for MCS0 but include for codegen
            % SC, Table 21-18 
            case 1 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 1/2;
                repetition = 2;
                NCWMIN = 12;
            case 2 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 1/2;
                repetition = 1;
                NCWMIN = 12;
            case 3 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 5/8;
                repetition = 1;
                NCWMIN = 12;
            case 4 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 3/4;
                repetition = 1;
                NCWMIN = 12;
            case 5 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 13/16;
                repetition = 1;
                NCWMIN = 12;
            case 6 % 'pi/2-BPSK'
                NCBPSS = 1;
                rate = 7/8;
                repetition = 1;
                NCWMIN = 12;    % Not 12
%                 error('NCWMIN is not defined for MCS6 (7/8 pi/2-BPSK).');
            case 7 % 'pi/2-QPSK'
                NCBPSS = 2;
                rate = 1/2;
                repetition = 1;
                NCWMIN = 23;
            case 8 % 'pi/2-QPSK'
                NCBPSS = 2;
                rate = 5/8;
                repetition = 1;
                NCWMIN = 23;
            case 9 % 'pi/2-QPSK'
                NCBPSS = 2;
                rate = 3/4;
                repetition = 1;
                NCWMIN = 23;
            case 10 % 'pi/2-QPSK'
                NCBPSS = 2;
                rate = 13/16;
                repetition = 1;
                NCWMIN = 23;
            case 11 % 'pi/2-QPSK'
                NCBPSS = 2;
                rate = 7/8;
                repetition = 1;
                NCWMIN = 25;    % Not 23;
            case 12 % 'pi/2-16QAM'
                NCBPSS = 4;
                rate = 1/2;
                repetition = 1;
                NCWMIN = 46;
            case 13 % 'pi/2-16QAM'
                NCBPSS = 4;
                rate = 5/8;
                repetition = 1;
                NCWMIN = 46;
            case 14 % 'pi/2-16QAM'
                NCBPSS = 4;
                rate = 3/4;
                repetition = 1;
                NCWMIN = 46;
            case 15 % 'pi/2-16QAM'
                NCBPSS = 4;
                rate = 13/16;
                repetition = 1;
                NCWMIN = 46;
            case 16 % 'pi/2-16QAM'
                NCBPSS = 4;
                rate = 7/8;
                repetition = 1;
                NCWMIN = 49;    % Not 46
            case 17 % 'pi/2-64QAM'
                NCBPSS = 6;
                rate = 1/2;
                repetition = 1;
                NCWMIN = 69;
            case 18 % 'pi/2-64QAM'
                NCBPSS = 6;
                rate = 5/8;
                repetition = 1;
                NCWMIN = 69;
            case 19 % 'pi/2-64QAM'
                NCBPSS = 6;
                rate = 3/4;
                repetition = 1;
                NCWMIN = 69;
            case 20 % 'pi/2-64QAM'
                NCBPSS = 6;
                rate = 13/16;
                repetition = 1;
                NCWMIN = 69;
            case 21 % 'pi/2-64QAM'
                NCBPSS = 6;
                rate = 7/8;
                repetition = 1;
                NCWMIN = 74;    % Not 69;
            otherwise
                error('MCS is not supported.');
        end
        NBPSCS = 0; % Not required but include for codegen
        NCBPS = NCBPSS * Nss;
        NDBPS = NCBPS*rate / repetition;
    else
        % Nsd = 336; % Number of data subcarriers
        switch mcs
            % OFDM, P802.11ay 28-68
            case 1 % DCM BPSK
                NBPSCS = 1; 
                rate  = 1/2;
            case 2 % DCM BPSK
                NBPSCS = 1;
                rate  = 5/8;
            case 3 % DCM BPSK
                NBPSCS = 1; 
                rate  = 3/4;
            case 4 % DCM BPSK
                NBPSCS = 1;
                rate  = 13/16;
            case 5 % DCM BPSK
                NBPSCS = 1;
                rate  = 7/8;
            case 6 % DCM QPSK
                NBPSCS = 2;
                rate  = 1/2;
            case 7 % DCM QPSK
                NBPSCS = 2;
                rate  = 5/8;
            case 8 % DCM QPSK
                NBPSCS = 2;
                rate  = 3/4;
            case 9 % DCM QPSK
                NBPSCS = 2;
                rate  = 13/16;
            case 10 % DCM QPSK
                NBPSCS = 2;
                rate  = 7/8;
            case 11 % 16-QAM
                NBPSCS = 4;
                rate  = 1/2;
            case 12 % 16-QAM
                NBPSCS = 4;
                rate  = 5/8;
            case 13 % 16-QAM
                NBPSCS = 4;
                rate  = 3/4;
            case 14 % 16-QAM
                NBPSCS = 4;
                rate  = 13/16;
            case 15 % 16-QAM
                NBPSCS = 4;
                rate  = 7/8;
            case 16 % 64-QAM
                NBPSCS = 6;
                rate  = 1/2;
            case 17 % 64-QAM
                NBPSCS = 6;
                rate  = 5/8;
            case 18 % 64-QAM
                NBPSCS = 6;
                rate  = 3/4;
            case 19 % 64-QAM
                NBPSCS = 6;
                rate  = 13/16;
            case 20 % 64-QAM
                NBPSCS = 6;
                rate  = 7/8;
            otherwise 
                error('MCS is not supported.');
        end    
        repetition = 1; % Not required but include for codegen
        NCWMIN = 0;     % Not required but include for codegen
        NCBPSS = Nsd * NBPSCS;
        NCBPS = NCBPSS * Nss;
        NDBPS = NCBPS * rate / repetition;
    end
end
