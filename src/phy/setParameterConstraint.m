function [simuParams, phyParams,chanCfg,nodeParams] = ...
    setParameterConstraint(simuParams, phyParams,chanCfg,nodeParams)
%setParameterConstraint Set constraints of parameters in different configurations.
%   All inputs and outpus are structs.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

assert(ismember(simuParams.debugFlag,[0,1,2]), 'debugFlag should be 0,1 or 2.');
assert(ismember(simuParams.dopplerFlag,[0,1]), 'dopplerFlag should be 0 or 1.');
assert(~isempty(simuParams.chanFlag),'Wrong Channel Model')
assert(ismember(simuParams.chanFlag,[0,1,2,3,4]),'chanFlag should be 0,1,2,3 or 4.');
assert(ismember(simuParams.mimoFlag,[-1,0,1,2]),'mimoFlag should be -1,0,1 or 2.');
assert(ismember(phyParams.processFlag,[0:6]),'processFlag should be 0~6.');
assert(ismember(phyParams.svdFlag,[0,1,2,3]),'svdFlag should be 0,1,2 or 3.');
assert(ismember(phyParams.powAlloFlag,[0,1,2,3]),'powAlloFlag should be 0,1,2 or 3.');
assert(ismember(phyParams.precAlgoFlag,[0:6]),'precAlgoFlag should be 0~6.');
assert(ismember(phyParams.equiChFlag,[0,1,2,3,4]),'equiChFlag should be 0,1,2,3 or 4.');
assert(ismember(phyParams.equaAlgoFlag,[0,1,2,3]),'equaAlgoFlag should be 0,1,2 or 3.');
assert(ismember(phyParams.precNormFlag,[0,1]),'precNormFlag should be 0 or 1.');
assert(ismember(phyParams.softCsiFlag,[0,1]),'softCsiFlag should be 0 or 1.');
assert(phyParams.symbOffset>=0 && phyParams.symbOffset<=1,'symbOffset should be >=0 and <=1.');


%% Set the remaining variables for the simulation.
phyParams.numSTSTot = sum(phyParams.numSTSVec);   % Num of total spatial streams for all active users
phyParams.numTxAnt = sum(phyParams.numSTSVec);       % Num of transmit antennas at BaseStation / Access Point
assert(ismember(phyParams.numUsers,1:8), 'numUsers should be 1 to 8.');
assert(ismember(phyParams.numTxAnt,1:8), 'numTxAnt should be  1 to 8.');
assert(ismember(phyParams.numSTSTot,1:8),'numSTSTot should be 1 to 8.');

% chanCfg.realizationSetIndex = 0;

if strcmp(chanCfg.chanModel,'AWGN')
    % AWGN Setup
    chanCfg.realizationSetIndex = 0;
    phyParams.svdFlag = checkInput(phyParams.svdFlag, 0, 'AWGN config. Set expected svdFlag value:');
    phyParams.powAlloFlag = checkInput(phyParams.powAlloFlag, 0, 'AWGN config. Set expected powAlloFlag value:');
    phyParams.precAlgoFlag = checkInput(phyParams.precAlgoFlag, 0, 'AWGN config. Set expected precAlgoFlag value:');
    phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 0, 'AWGN config. Set expected equiChFlag value:');
    phyParams.equaAlgoFlag = checkInput(phyParams.equaAlgoFlag, 0, 'AWGN config. Set expected equaAlgoFlag value:');
    simuParams.dopplerFlag = checkInput(simuParams.dopplerFlag, 0, 'AWGN config. Set expected dopplerFlag value:');
    assert(phyParams.numSTSVec==1,'numSTSVec should be 1.');
    assert(phyParams.numUsers==1,'numUsers should be 1.');
else
    % Fading Setup
    if strcmp(chanCfg.chanModel,'Rayleigh')
        chanCfg.realizationSetIndex = 0;
        assert(chanCfg.numTaps>0,'When using Rayleigh channel model, numTaps should be > 0.');
        assert(chanCfg.maxMimoArrivalDelay>=0,'When chanFlag=1, maxMimoArrivalDelay should be >= 0.');
    end

    if strcmp(chanCfg.chanModel,'NIST')
        chanCfg.realizationSetIndex = 0;
        assert(isnumeric(chanCfg.rxPowThresdB),'chanCfg.rxPowThresdB should be numeric.');
        if isempty(chanCfg.rxPowThresdB)
            chanCfg.rxPowThresType = checkInput(chanCfg.rxPowThresType,'Inactivated', ...
                'Empty rxPowThresdB set rxPowThresType as Inactivated.');
        elseif isscalar(chanCfg.rxPowThresdB)
            assert(strcmp(chanCfg.rxPowThresType,'Static') || strcmp(chanCfg.rxPowThresType,'Dynamic'), ...
                'Scalar rxPowThresdB should use Static or Dynamic rxPowThresType.');
        else
            error('chanCfg.rxPowThresdB should be either empty or scalar.');
        end
        if strcmp(chanCfg.rxPowThresType,'Inactivated')
            chanCfg.rxPowThresdB = checkInput(chanCfg.rxPowThresdB,[], ...
                'Inactivated rxPowThresType set rxPowThresdB as empty.');
        elseif strcmp(chanCfg.rxPowThresType,'Static') || strcmp(chanCfg.rxPowThresType,'Dynamic')
            assert(isscalar(chanCfg.rxPowThresdB)&&(chanCfg.rxPowThresdB>=0), ...
                'Static or Dynamic rxPowThresType requires rxPowThresdB as a scalar >=0.');
        else
            error('chanCfg.rxPowThresType should be Inactivated, Static or Dynamic.');
        end
    end

    if strcmp(phyParams.phyMode,'OFDM')
        if phyParams.equiChFlag == 0
            phyParams.equaAlgoFlag = checkInput(phyParams.equaAlgoFlag, 0, 'Set expected equaAlgoFlag value:');
        end
    elseif strcmp(phyParams.phyMode,'SC')
        assert(phyParams.equiChFlag~=0,'When SC, equiChFlag should not be 0.');
        assert(phyParams.equaAlgoFlag~=0,'When SC, equaAlgoFlag should not be 0.');
    else
        error('phyMode should be either OFDM or SC.');
    end

    if simuParams.psduMode == 0
        phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 1, 'PPDU config. Set expected equiChFlag value:');
        if strcmp(simuParams.metricStr,'SE')
            warning('SE for PPDU requires validation.');
            % Set for estimated channel based on  NDP
            if phyParams.processFlag ~= 0
                if strcmp(phyParams.phyMode,'SC') && phyParams.precAlgoFlag == 5
                    phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 3, 'Set expected equiChFlag value:');
                    error('SE of SC mode for PPDU requires debugging.');
                else
                    phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 2, 'Set expected equiChFlag value:');
                end
            end
        end
        assert(phyParams.equaAlgoFlag~=0,'When packetType includes preamble, equaAlgoFlag should not be 0.');
    else
    end

    if phyParams.svdFlag == 0
        if phyParams.precAlgoFlag == 0
            % Non Tx precoding, use Rx MIMO detection
            phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP,'Direct', 'Set expected smTypeNDP value:');
            phyParams.smTypeDP = checkInput(phyParams.smTypeDP,'Direct', 'Set expected smTypeDP value:');
            if phyParams.powAlloFlag == 0
                assert(phyParams.equiChFlag==1,'When svdFlag=0, precAlgoFlag=0, powAlloFlag=0, no Tx precoding, use Rx MIMO detection. equiChFlag should be 1.');
            end
            assert(phyParams.equaAlgoFlag~=0,'When svdFlag=0, precAlgoFlag=0, no Tx precoding, use Rx MIMO detection. equaAlgoFlag should not be 0.');
        else
            phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP, {'Hadamard','Fourier'}, 'smTypeNDP config. Set expected smTypeDP value:');
            phyParams.smTypeDP = checkInput(phyParams.smTypeDP, {'Custom','Hadamard','Fourier'}, 'smTypeDP config. Set expected smTypeDP value:');
        end
    else
        if ismember(phyParams.svdFlag,[1,2])
            assert(phyParams.powAlloFlag~=1,'powAlloFlag should be either 0 or 2.');
        elseif phyParams.svdFlag == 3
            assert(phyParams.precAlgoFlag==1,'precAlgoFlag should be 1.');
        end
        if phyParams.precAlgoFlag == 0
            % Channel SVD, Tx V pre-coding using matched filtering, Rx equalization
            if phyParams.numTxAnt == 1
                phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP,'Direct', 'Set expected smTypeNDP value:');
                phyParams.smTypeDP = checkInput(phyParams.smTypeDP,'Direct', 'Set expected smTypeDP value:');
                phyParams.equiChFlag = checkInput(phyParams.equiChFlag, 1, 'Set expected equiChFlag value:');
            else
                phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP, {'Hadamard','Fourier'}, 'smTypeNDP config. Set expected smTypeDP value:');
                phyParams.smTypeDP = checkInput(phyParams.smTypeDP, {'Custom','Hadamard','Fourier'}, 'smTypeDP config. Set expected smTypeDP value:');
            end
        else
            phyParams.smTypeNDP = checkInput(phyParams.smTypeNDP, {'Hadamard','Fourier'}, 'smTypeNDP config. Set expected smTypeDP value:');
            phyParams.smTypeDP = checkInput(phyParams.smTypeDP, {'Custom','Hadamard','Fourier'}, 'smTypeDP config. Set expected smTypeDP value:');
        end
    end
end

if phyParams.numSTSTot == 1
    if phyParams.numTxAnt == 1
        % SISO
        simuParams.mimoFlag = checkInput(simuParams.mimoFlag, 0, 'Switched MIMO flag to');
        simuParams.mimoFlagStr = 'SISO';
        assert(phyParams.numUsers == 1,'In SISO case, numUsers should be 1.');
    end
else
    if phyParams.numUsers == 1
        % SU
        simuParams.mimoFlag = checkInput(simuParams.mimoFlag, 1, 'Switched MIMO flag to');
        simuParams.mimoFlagStr = 'SU-MIMO';
    elseif phyParams.numUsers > 1
        % MU
        simuParams.mimoFlag = checkInput(simuParams.mimoFlag, 2, 'Switched MIMO flag to');
        simuParams.mimoFlagStr = 'MU-MIMO';
    else
        error('In SU/MU-MIMO case, numUsers should be 1 or >1.');
    end
end

if strcmp(phyParams.phyMode,'OFDM')
    assert(ismember(phyParams.processFlag,0:4),'processFlag should be 0~4.');
    assert(ismember(phyParams.precAlgoFlag,0:4),'precAlgoFlag should be 0~4.');
else
    % SC
    if phyParams.numUsers == 1
        assert(ismember(phyParams.processFlag,0:5),'processFlag should be 0~5.');
        assert(ismember(phyParams.precAlgoFlag,0:5),'precAlgoFlag should be 0~5.');
    else
        assert(phyParams.processFlag==5,'processFlag should be 5.');
        assert(phyParams.precAlgoFlag==5,'precAlgoFlag should be 5.');
    end
    phyParams.softCsiFlag = checkInput(phyParams.softCsiFlag, 0, 'SC config. Set expected softCsiFlag value:');
end

if simuParams.snrAntNormFlag == 0
    % SNR All Ant
    simuParams.snrAntNormFactor = 1;
    simuParams.snrAntNormStr = 'allAnt';
elseif simuParams.snrAntNormFlag == 1
    % SNR Per Ant
    simuParams.snrAntNormFactor = 1/numSTSTot;
    simuParams.snrAntNormStr = 'perAnt';
end

assert(any([1,strcmp(phyParams.smTypeNDP,{'Direct','Hadamard','Fourier','Custom'})]),'smTypeNDP should be one of (1,Direct,Hadamard,Fourier,Custom).');
assert(any([1,strcmp(phyParams.smTypeDP,{'Direct','Hadamard','Fourier','Custom'})]),'smTypeDP should be one of (1,Direct,Hadamard,Fourier,Custom).');


if strcmp(phyParams.smTypeDP,'Direct')
    simuParams.csit = '';
else
    if simuParams.psduMode == 0
        simuParams.csit = 'estimated';
    else
        simuParams.csit = 'ideal';
    end
end

if strcmp(chanCfg.chanModel,'sensing')
    assert((phyParams.numUsers+1) == length(nodeParams), 'Node Params not defined')
end

%% MULTI-STATIC PPDU
if phyParams.msSensing ==1
    assert(simuParams.psduMode == 0, 'Multi-Static EDMG requires PPDU transmission. Set psduMode = 0' )
    assert(strcmp(phyParams.phyMode, 'SC'), 'Multi-Static Sensing PPDU is defined for SC' )
    assert(all(phyParams.numSTSVec==1), 'EDMG Multi-Static Sensing is defined for single space-time stream SC PPDUs only')
    if phyParams.lenPsduByt ~= 0
        phyParams.lenPsduByt = 0;
        warning('In a PPDU in which the the msSensing is set to 1, lenPsduByt is set to 0 and the length of the data field is 0 chips')
    end

    %   TRN
    assert(mod((phyParams.unitM+1)/phyParams.unitN,1)==0, ['The value of the EDMG TRN-Unit M field plus one' ...
        'shall be an integer multiple of the value indicated in the EDMG TRN-Unit N'])

    if strcmp(phyParams.packetType, 'TRN-T') && phyParams.unitN == 1
        assert(phyParams.trainingLength<=2040/(phyParams.unitM+1), ...
            ['In an EDMG BRP-TX PPDU with EDMG TRN-Unit N field equal to 0, ' ...
            'the EDMG TRN Length field shall be less than or equal to 2040/M.'] )
    end

end

end
