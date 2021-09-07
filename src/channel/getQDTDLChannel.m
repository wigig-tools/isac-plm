function [tdlCir,varargout] = getQDTDLChannel(cfgEDMG,cfgChan,chanData,numDoppler,varargin)
%getQDTDLChannel Get the NIST Q-D tapped-delay line channel model
%   This function creates the NIST QD tapped delay line (TDL) channel impluse response (CIR) from pre-generated QD 
%   channel realzation dataset of CIR
% 
%   Inputs:
%   cfgEDMG is the EDMG configuration ojbect
%   chanCfg is the channel configuration struct
%   chanData is the instantaneous channel realization struct
%   numDoppler is the number of Doppler samples
%   varargin is optional SNR value in dB
%   
%   Outputs:
%   tdlCir is the time domain TDL CIR for SISO, SU/MU-MIMO
%
%   NIST/CTL 2019~2021 <jiayi.zhang@nist.gov>

%#codegen

narginchk(4,5);
assert(isnumeric(cfgChan.rxPowThresdB) && ...
    ((isscalar(cfgChan.rxPowThresdB)&&(cfgChan.rxPowThresdB>=0)) || isempty(cfgChan.rxPowThresdB)), ...
    'cfgChan.rxPowThresdB should be numeric, either a scalar or empty.');

if nargin==4
    if strcmp(cfgChan.rxPowThresType,'Inactivated')
        assert(isempty(cfgChan.rxPowThresdB),'Inactivated rxPowThresType set rxPowThresdB as empty.');
        rxPowThresdB = nan;
    elseif strcmp(cfgChan.rxPowThresType,'Static')
        assert(isscalar(cfgChan.rxPowThresdB)&&(cfgChan.rxPowThresdB>=0), ...
            'Static rxPowThresType requires rxPowThresdB as a scalar >=0.');
        rxPowThresdB = cfgChan.rxPowThresdB;
    else
        error('Dynamic rxPowThresType requires SNR input.');
    end
else
    % With SNR input
    snrLog = varargin{1};
    if strcmp(cfgChan.rxPowThresType,'Inactivated')
        assert(isempty(cfgChan.rxPowThresdB),'Inactivated rxPowThresType set rxPowThresdB as empty.');
        rxPowThresdB = nan;
    elseif strcmp(cfgChan.rxPowThresType,'Static')
        assert(isscalar(cfgChan.rxPowThresdB)&&(cfgChan.rxPowThresdB>=0), ...
            'Static rxPowThresType requires rxPowThresdB as a scalar >=0.');
        rxPowThresdB = cfgChan.rxPowThresdB;
    elseif strcmp(cfgChan.rxPowThresType,'Dynamic')
        assert(isscalar(cfgChan.rxPowThresdB)&&(cfgChan.rxPowThresdB>=0), ...
            'Dynamic rxPowThresType requires rxPowThresdB as a scalar >=0.');
        if cfgChan.rxPowThresdB<snrLog
        % dynamic rxPowThresdB given by snrLog
            rxPowThresdB = snrLog;
        else
            rxPowThresdB = cfgChan.rxPowThresdB;
        end
    else
        error('cfgChan.rxPowThresType should be Inactivated, Static or Dynamic.');
    end
end

% Get sampling rate
fs = nist.edmgSampleRate(cfgEDMG);

[tdlCir,maxTapLen] = getQDTDLMUMIMOChannel(chanData.channelGain,chanData.delay,chanData.dopplerFactor, ...
    chanData.TxComb,chanData.RxComb, ...
    numDoppler,fs,cfgEDMG.NumTransmitAntennas,cfgEDMG.NumSpaceTimeStreams, ...
    cfgChan.numTaps, cfgChan.tdlType,rxPowThresdB,cfgChan.tdlMimoNorFlag);

varargout{1} = maxTapLen;

end

