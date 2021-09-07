function [refConst,evm] = edmgReferenceConstellation(cfgFormat)
%edmgReferenceConstellation Get EDMG reference constellation and error vector magnitude (EVM) for OFDM and SC mode
% 
% Input
%   cfgFormat is EDMG configuration object
% Outputs
%   refConst is a cell array of each user's reference constellation points
%   evm is a cell array of each user's EVM value
%
%   2019~2021 NIST/CTL Jiayi Zhang
%   This file is available under the terms of the NIST License.

%#codegen

assert(cfgFormat.NumUsers==length(cfgFormat.MCS),'numUsers is incorrect.')
refConst = cell(cfgFormat.NumUsers,1);
evm = cell(cfgFormat.NumUsers,1);

for iUser = 1:cfgFormat.NumUsers
    mcs = cfgFormat.MCS(iUser);
    switch cfgFormat.PHYType
        case 'SC'
            if ismember(mcs, 1:11)
                % BPSK/QPSK with phase shift by pi/4
                refConst{iUser} = qammod(0:3,4)/sqrt(2)*exp(1j*pi/4);
            elseif ismember(mcs, 12:16)
                % 16QAM phase shift by pi/2
                refConst{iUser} = qammod(0:15,16)/sqrt(10)*exp(1j*pi/2);
            elseif ismember(mcs, 17:21)
                % 64QAM phase shift by pi/2
                refConst{iUser} = qammod(0:63,64)/sqrt(42)*exp(1j*pi/2);
            else
                % Error
                error('Reference constellation not defined')
            end

        case 'OFDM'
            if ismember(mcs, 1)
                % DCM BPSK using regular QPSK constellation
                refConst{iUser} = qammod(0:3,4)/sqrt(2);
            elseif ismember(mcs, 2:10)
                % DCM QPSK using regular 16-QAM constellation
                refConst{iUser} = qammod(0:15,16)/sqrt(10);
            elseif ismember(mcs, 11:15)
                % 16QAM
                refConst{iUser} = qammod(0:15,16)/sqrt(10);
            elseif ismember(mcs, 16:20)
                % 64QAM
                refConst{iUser} = qammod(0:63,64)/sqrt(42);
            else
                error('Reference constellation not defined')
            end
        case 'Control'
            error('PHYType should be either OFDM or SC.');
    end

    evm{iUser} = comm.EVM('ReferenceSignalSource','Estimated from reference constellation', ...
        'ReferenceConstellation',refConst{iUser});

end

end