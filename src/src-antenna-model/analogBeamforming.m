function [Hout, varargout] = analogBeamforming(H, paaInfo,phyParams, varargin)
%%ANALOGBEAMFORMING returns the matrix of dimension:
% digital rx chain x digital tx chain x taps x time

% NIST-developed software is provided by NIST as a public service. You may 
% use, copy and distribute copies of the software in any medium, provided 
% that you keep intact this entire notice. You may improve,modify and 
% create derivative works of the software or any portion of the software, 
% and you may copy and distribute such modifications or works. Modified 
% works should carry a notice stating that you changed the software and 
% should note the date and nature of any such change. Please explicitly 
% acknowledge the National Institute of Standards and Technology as the 
% source of the software. NIST-developed software is expressly provided 
% "AS IS." NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR
% ARISING BY OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED 
% WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
% NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS 
% THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, 
% OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY
% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS THEREOF,
% INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY, RELIABILITY,
% OR USEFULNESS OF THE SOFTWARE.
% 
% You are solely responsible for determining the appropriateness of using 
% and distributing the software and you assume all risks associated with 
% its use,including but not limited to the risks and costs of program 
% errors, compliance with applicable laws, damage to or loss of data, 
% programs or equipment, and the unavailability or interruption of 
% operation. This software is not intended to be used in any situation 
% where a failure could cause risk of injury or damage to property. 
% The software developed by NIST employees is not subject to copyright 
% protection within the United States.
%
% 2020 NIST/CTL (steve.blandino@nist.gov)

%% Varargin processing
p = inputParser;
validationFcn = @(x) ismember(x, {'maxAnalogSnr', 'maxHybridSinr', 'hybridMaxSnrZf', 'noBeamforming'});
addOptional(p,'beamformingMethod','maxAnalogSnr',validationFcn)
parse(p, varargin{:});
beamformingMethod  = p.Results.beamformingMethod;
assert(strcmp(beamformingMethod, 'noBeamforming'), 'Analog beamforming not implemented')

%% Vars init
Fa = [];
Fd = [];
time = size(H,1);
NSta = phyParams.numUsers;
nodes = size(paaInfo,2);
NAp = nodes-NSta;
apId = 1:NAp;
staId = NAp+1:nodes;
paaInfoAp = paaInfo(apId);
paaInfoSta = paaInfo(staId);

for ap = 1:NAp
    digitalChainAp(ap) = paaInfoAp(ap).NumPaa;
    antennasAp(ap) = paaInfoAp(ap).NumAntenna;
    numStreams = sum(phyParams.numSTSVec);
    FaTmp = num2cell(ones(antennasAp(ap),digitalChainAp(ap)),1);
    Fa(:,:,ap) = blkdiag(FaTmp{:});
    Fd(:,:,ap) = eye(digitalChainAp(ap), numStreams);
end

for sta = 1:NSta
    digitalChainSta(sta) = paaInfoSta(sta).NumPaa;
    antennasSta(sta) = paaInfoSta(sta).NumAntenna;
    numStreams = phyParams.numSTSVec(sta);
    WaTmp =  num2cell(ones(antennasSta(sta),digitalChainSta(sta)),1);
    Wa(:,:,sta) = blkdiag(WaTmp{:});
    Wd(:,:,sta) = eye(digitalChainSta(sta), numStreams);
end
splitWa =  num2cell(Wa,1); 
Wa = blkdiag(splitWa{:});

%% Get analog beamsteering
switch beamformingMethod

    case 'noBeamforming'
         
        for t = 1:time
            Ht = matrix3Dproduct(H{t},Fa);
            Hout(:,:,:,t) = matrix3Dproduct(Wa, Ht);
        end
        
        
    case 'maxAnalogSnr'
%         Fa = maxAnalogSnr(H, paaInfo);
    case 'maxHybridSinr'
%         [Fa, Fd] = maxHybridSinr(H, paaInfo);

    case 'hybridMaxSnrZf'
%         [Fa, Fd] = hybridMaxSnrZf(H, paaInfo);

end

%% Apply analog beamforming



%% Prepare output
varargout{1}  = Fa;
varargout{2}  = Wa;


end