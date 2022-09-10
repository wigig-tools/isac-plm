function [Hout, varargout] = analogBeamforming(H, codebook, ...
    beamformingMethod, varargin)
%%ANALOGBEAMFORMING  Analog Beamforming 
% 
%   Heq = ANALOGBEAMFORMING(H, C, PHY, BF) returns the equivalent
%   channel Heq given the full digital channel H, the codebook C and the
%   beamforming method spcefied as 'maxAnalogSnr', 'sweepRx', 'sweepTx' or 
%   'sweepTxRx', 'noBeamforming'.
%   
%   H is a cell array over time. Each entry is the full digital matrix as
%   receive antennas x transmit antennas x delay taps
%   H out is the matrix of size: receive chains x transmit chains x delay
%   taps x num of tx AWV x num of rx AWVs
%

% 2020-2022 NIST/CTL (steve.blandino@nist.gov)

%   This file is available under the terms of the NIST License.


%% Varargin processing
p = inputParser;
validationFcn = @(x) ismember(x, {'maxAnalogSnr', 'maxHybridSinr', ...
    'hybridMaxSnrZf', 'noBeamforming', 'sweepRx', 'sweepTx'});
assert(validationFcn(beamformingMethod), 'Wrong beamforming method')
addOptional(p,'nSta',1)

switch beamformingMethod
    case 'sweepRx'
        addOptional(p,'txbf', [])
    case  'sweepTx'
        addOptional(p,'rxbf', [])
end

parse(p, varargin{:});

switch beamformingMethod
    case 'sweepRx'
        txbf  = p.Results.txbf;
    case  'sweepTx'
        rxbf  = p.Results.rxbf;
end
nSta = p.Results.nSta;

%% Vars init
time = size(H,1);
infoScan = [];

% Single antenna tx and rx - No beamforming needed
if  all(size(H{1}, [1 2]) == [1 1])
    Hout = permute(reshape(cell2mat(H), 1,1, time,[]), [1 2 4 3]);
    txbf = 1;
    rxbf = 1;

else
    nodes = size(codebook,2);
NAp = nodes-nSta;
apId = 1:NAp;
staId = NAp+1:nodes;
paaInfoAp = codebook(apId);
paaInfoSta = codebook(staId);
    %% Get analog beamsteering
    switch beamformingMethod

        case 'noBeamforming'
            Hout = zeros(1,1,size(H{1},3), time);
            for t = 1:time
                Hout(:,:,:,t) = sum(sum(H{1},1),2);
            end

        case 'maxAnalogSnr'
            [Hout, txbf, rxbf, infoScan] = maxAnalogSnr(H, paaInfoAp,paaInfoSta);

        case 'sweepTx'
            [Hout, txbf] = sweepSingleSide(H, rxbf, paaInfoSta,'tx');

        case 'sweepRx'
            [Hout, rxbf] = sweepSingleSide(H, txbf,paaInfoSta, 'rx');

        case 'sweepTxRx'

        case 'maxHybridSinr'
            %         [Fa, Fd] = maxHybridSinr(H, paaInfo);

        case 'hybridMaxSnrZf'
            %         [Fa, Fd] = hybridMaxSnrZf(H, paaInfo);
    end

end

%% Prepare output
varargout{1}  = txbf;
varargout{2}  = rxbf;
varargout{3} = infoScan;


end