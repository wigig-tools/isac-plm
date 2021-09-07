function [tdMimoCir,fdMimoCfr] = getMUMIMOChannelResponse(chanModel,numSamp,fftSize,cfgEDMG,chanCfg,varargin)
%getMUMIMOChannelResponse Get multi-user MIMO channel coefficients
%   This function gets the multi-user (MU) MIMO channel coefficients including the TDL channel impluse response (CIR) and
%   frequency domain channel frequency response (CFR) for various channel models
%
%   Inputs
%   chanModel is the channel model type, ='Rayleigh': random Rayleigh multi-path channel model, 
%       ='MatlabTGay': MATLAB TGay channel model; ='Intel': Intel 60GHz channel model; ='NIST': NIST QD 11ay channel model
%   numSamp is the number of samples for Doppler spread.
%   fftSize is the length of FFT/IFFT operation
%   cfgEDMG is the EDMG configuration ojbect
%   chanCfg is the channel configuration struct
%   varargin{1} is the channel ojbect of MATLAB and NIST channel models
% 
%   Outputs:
%   tdMimoCir is the numUser-length time domain tapped delay line (TDL) CIR cell array, each entry is a numTxAnt-by-
%       numSTS sub cell array, which contains the numTaps-by-numSamp matrix.
%   fdMimoCfr is the numUser-length frequency domain CFR cell array, each entry is a fftSize-by-numTxAnt-by-numSTS 3D
%       matrix

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if isa(cfgEDMG,'nist.edmgConfig')
    numUsers = cfgEDMG.NumUsers;
    numTxAnt = cfgEDMG.NumTransmitAntennas;
    numSTSVec = cfgEDMG.NumSpaceTimeStreams;
else
    numUsers = 1;
    numTxAnt = 1;
    numSTSVec = 1;
end

narginchk(5,6);

if strcmp(chanModel,'Rayleigh') || strcmp(chanModel,'Intel')
    assert(numSamp==1,'chanFlag = 1 or 3 supports numSamp=1 only.');
    
    % Creat block fading for numUsers by numTxAnt
    tdMimoCir = cell(numUsers,1);
    fdMimoCfr = cell(numUsers,1);
    for iUser = 1:numUsers
        tdMimoCir{iUser} = cell(numTxAnt,numSTSVec(iUser));
        fdMimoCfr{iUser} = zeros(fftSize,numSamp, numTxAnt,numSTSVec(iUser));
        for iTxA = 1:numTxAnt
            for iUserRxA = 1:numSTSVec(iUser)
                switch chanModel
                    case 'Rayleigh'
                        if chanCfg.maxMimoArrivalDelay > 0
                            mimoArrivalDelay = randi(chanCfg.maxMimoArrivalDelay);
                        else
                            mimoArrivalDelay = 0;
                        end
                        tdlChan = getTDLRayleighFadingChannel(numSamp,chanCfg.numTaps,mimoArrivalDelay,chanCfg.pdpMethodStr);
                    case 'Intel'
                        tdlChanVec = intel_cr_ch_model(chanCfg.sampleRate,chanCfg.apSp,chanCfg.pLos,chanCfg.txAntType,...
                            chanCfg.rxAntType,chanCfg.txHpbw,chanCfg.rxHpbw);
                        tdlChan = transpose(tdlChanVec);
                end
                tdMimoCir{iUser}{iTxA,iUserRxA} = tdlChan;
            end
        end
    end
elseif strcmp(chanModel,'MatlabTGay') || strcmp(chanModel,'NIST')
    assert(nargin==6,'chanModel requires optional input.');
    tgayChannel = varargin{1};
    switch chanModel
        case 'MatlabTGay'
            tdlType = chanCfg.tdlType;
            normFlag = chanCfg.tdlMimoNorFlag;
            tdMimoCir = genTGayTDLChannel(tgayChannel,numSamp,numTxAnt,numSTSVec,tdlType,normFlag); 
        case 'NIST'
            tdMimoCir = tgayChannel;
    end
else
    error('chanFlag should be one of 1,2,3 or 4.');
end
fdMimoCfr = getMIMOChannelFrequencyResponse(tdMimoCir,fftSize);

end

% End