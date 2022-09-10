function params =  configPhy(scenarioPath, varargin)
%CONFIGPHY loads the 802.11ay PHY parameters 
%   CONFIGPHY(FOLDERPATH) loads the 802.11ay simulation parameters 
%   from phyConfig.txt relative to the scenarios in FOLDERPATH
%   and it checks if the loaded parameters are in the expected range.
%
%   P = CONFIGPHY(FOLDERPATH) returns the parameter structure P.
%   P field:
%       phyMode: PHY mode specified as 'OFDM' or 'SC'. (Default 'OFDM')
%
%       lenPsduByt: Length of PSDU in byte specifies as positive scalar.
%       (Default = 4096)
%
%       giType : Guard Interval type specified as 'Short' or 'Long'
%
%       numSTSVec: Number of spatial streams specified as 1-by-STAs vector
%       of positive integers in the range 1-8 such that sum(numSTSVec)<=8.
%       (Default = 1)
%
%       smTypeNDP: Spatial multiplexing matrix of the preamble
%       (non-data-packet). It is specified as 'Hadamard', 'Fourier', 
%       'Custom' or 'Direct'. (Default is 'Direct')
%
%       smTypeDP: Spatial multiplexing matrix of the data 
%       (data-packet). It is specified as 'Hadamard', 'Fourier', 
%       'Custom' or 'Direct'. (Default is 'Direct')
%
%       mcs: Modulation and coding scheme index in the range 1-12. (Default
%       = 6).
%
%       analogBeamforming: Analog beamforming scheme specified as 
%       'maxCapacity' or 'maxMinCapacity'. This value is used if chanModel
%       in simulationConfig.txt is specified as NIST. (Default 'maxCapacity')
%
%       dynamicBeamNumber: Dynamic stream allocation. Select only the 
%       streams among numSTSVec with high SINR. It is specified as a scalar
%       between 0-20 indicating the condition number of a SU-MIMO matrix.
%       (0: OFF)
%
%       processFlag: 0-5 (Default 0)
%
%       symbOffset: Symbol sampling offset, specified as values from 0 to
%       1. When symbOffset is 0, no offset is applied. When symbOffset is 
%       1 an offset equal to the GI length is applied. (Default 0.75)
%
%       softCsiFlag is specified as 0 or 1. (Default 1)
%
%       ldpcDecMethod is specified as 'norm-min-sum'
%
%   See also CONFIGSIMULATION, CONFIGCHANNEL

%   2019-2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

p = inputParser;

defaultMode = false;
checkInputValidity = @(x) islogical(x);
addOptional(p,'isac',defaultMode,checkInputValidity)
parse(p,varargin{:})
isIsac = p.Results.isac;


%% Load params
cfgPath = fullfile(scenarioPath, 'Input/phyConfig.txt');
paramsList = readtable(cfgPath,'Delimiter','\t', 'Format','%s %s' );
paramsCell = (table2cell(paramsList))';
params = cell2struct(paramsCell(2,:), paramsCell(1,:), 2);

%% Check validity
if isIsac
    defaultPhyMode = 'SC';
    defaultLenPsduByt = 0;
    defaultSoftCsiFlag = 0;
else
    defaultPhyMode = 'OFDM';
    defaultLenPsduByt = pow2(12);
    defaultSoftCsiFlag = 1;
end

params = fieldToNum(params, 'phyMode', {'SC', 'OFDM'}, 'defaultValue', defaultPhyMode);
params = fieldToNum(params, 'packetType', {'TRN-R', 'TRN-T','TRN-TR'},'defaultValue', 'TRN-R');
params = fieldToNum(params, 'lenPsduByt', [0 pow2(16)], 'step', eps, 'defaultValue', defaultLenPsduByt);
params = fieldToNum(params, 'giType', {'Short', 'Normal', 'Long'}, 'defaultValue', 'Short');
params = fieldToNum(params, 'numSTSVec', [1 8], 'step', 1, 'defaultValue', 1);
params = fieldToNum(params, 'smTypeNDP', {'Hadamard', 'Fourier', 'Custom', 'Direct'}, 'defaultValue', 'Direct');
params = fieldToNum(params, 'smTypeDP', {'Hadamard', 'Fourier', 'Custom', 'Direct'}, 'defaultValue', 'Direct');
if strcmp(params.phyMode,'OFDM')
    params = fieldToNum(params, 'mcs', [1 20], 'step', 1, 'defaultValue', 1);
else
    params = fieldToNum(params, 'mcs', [1 21], 'step', 1, 'defaultValue', 2);
end
params = fieldToNum(params, 'analogBeamforming', {'maxAllUserCapacity', 'maxMinAllUserSV', 'maxMinPerUserCapacity', 'maxMinMinPerUserSV'}, 'defaultValue', 'maxAllUserCapacity');
params = fieldToNum(params, 'dynamicBeamNumber', [-1 20],'step', eps, 'defaultValue', 0);
params = fieldToNum(params, 'processFlag', [0 5], 'step', 1, 'defaultValue', 0);
params = fieldToNum(params, 'symbOffset', [0 1], 'step', eps, 'defaultValue', 0.75);
params = fieldToNum(params, 'softCsiFlag', [0 1], 'step', 1, 'defaultValue', defaultSoftCsiFlag);
params = fieldToNum(params, 'ldpcDecMethod', {'norm-min-sum'}, 'defaultValue', 'norm-min-sum');
params = fieldToNum(params, 'msSensing', [0 1], 'defaultValue', 0);
if params.msSensing ==1
    params = fieldToNum(params, 'unitP', [0 1 2 4],  'defaultValue', 2);
    params = fieldToNum(params, 'unitM', [0 2^4-1], 'step', 1, 'defaultValue', 5);
    params = fieldToNum(params, 'unitN', [1 2 3 4 8], 'defaultValue', 3);
    params = fieldToNum(params, 'unitRxPerUnitTx', [0 2^8-1], 'step', 1, 'defaultValue', 0);
    params = fieldToNum(params, 'subfieldSeqLength', [128 256 64], 'defaultValue', 128);
    params = fieldToNum(params, 'trainingLength', [0 2^8-1], 'step', 1, 'defaultValue', 10);
end

end

