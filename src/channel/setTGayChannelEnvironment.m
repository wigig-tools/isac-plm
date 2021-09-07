function [tgayOut] = setTGayChannelEnvironment(tgayIn,chanEnvStr)
%setTGayChannelEnvironment Summary of this function goes here
%   tgayIn: TGayChannel object
%   chanEnvStr:
%       'OAH-D' is Matlab default setting of Open area hotspot;
%       'OAH-E' is Matlab example code setting of Open area hotspot;
%       'LHL' is Matlab default setting of Large hotel lobby;
%       'LR' is Nist's lecture room setting of Large hotel lobby;
%       'Customized' is customized setting, to be specified.
%   tgayOut: TGayChannel object with environment setting.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

if strcmp(chanEnvStr, 'OAH-SU-SISO')
    tgayIn.Environment               = 'Open area hotspot';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 270; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [6; 6; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
%     tgayIn.RandomStream              = 'mt19937ar with seed';
%     tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'LHL-SU-SISO')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [20 15 6];
    tgayIn.TransmitArray             = wlanURAConfig('Size',[5 5]);
    tgayIn.TransmitArrayPosition     = [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 270];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[5 5]);
    tgayIn.ReceiveArrayPosition      = [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'LHL-SU-MIMO1x1SS')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [20 15 6];
    tgayIn.UserConfiguration         = 'SU-MIMO 1x1';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 0; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];    % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'LHL-SU-MIMO1x1DD')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [20 15 6];
    tgayIn.UserConfiguration         = 'SU-MIMO 1x1';
    tgayIn.ArrayPolarization         = 'Dual, Dual';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [90; 90; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 0; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.RandomRays                = true;
    tgayIn.IntraClusterRays          = true;
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
    tgayIn.NormalizeChannelOutputs   = true;
%    tgayIn.RandomStream              = 'Global stream';
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'SCH-SU-MIMO1x1DD')
    tgayIn.Environment               = 'Street canyon hotspot';
    tgayIn.UserConfiguration         = 'SU-MIMO 1x1';
    tgayIn.ArrayPolarization         = 'Dual, Dual'; % 'Dual, Dual';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [90; 90; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 0; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.RandomRays                = true;
    tgayIn.IntraClusterRays          = true;
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
    tgayIn.NormalizeChannelOutputs   = true;
%    tgayIn.RandomStream              = 'Global stream';
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'OAH-SU-MIMO1x1DD')
    tgayIn.Environment               = 'Open area hotspot';
    tgayIn.UserConfiguration         = 'SU-MIMO 1x1';
    tgayIn.ArrayPolarization         = 'Dual, Dual';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [90; 90; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 0; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.RandomRays                = true;
    tgayIn.IntraClusterRays          = true;
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
    tgayIn.NormalizeChannelOutputs   = true;
%    tgayIn.RandomStream              = 'Global stream';
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'SCH-SU-MIMO2x2SS')
    tgayIn.Environment               = 'Street canyon hotspot';
    tgayIn.UserConfiguration         = 'SU-MIMO 2x2';
    tgayIn.ArraySeparation           = [1 1];      % [0.8 0.8];
    tgayIn.ArrayPolarization         = 'Single, Single';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [10; 10; 10];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [6; 6; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.BeamformingMethod         = 'Custom'; % 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = false; % true;
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
    tgayInfo = info(tgayIn);
    NTE = tgayInfo.NumTxElements;
    NTS = tgayInfo.NumTxStreams;
    NRE = tgayInfo.NumRxElements;
    NRS = tgayInfo.NumRxStreams;
    tgayIn.TransmitBeamformingVectors = ones(NTE,NTS)/sqrt(NTE);
    tgayIn.ReceiveBeamformingVectors = ones(NRE,NRS)/sqrt(NRE);
elseif strcmp(chanEnvStr, 'SCH-SU-MIMO2x2DD')
    tgayIn.Environment               = 'Street canyon hotspot';
    tgayIn.UserConfiguration         = 'SU-MIMO 2x2';
    tgayIn.ArraySeparation           = [1 1];      % [0.8 0.8];
    tgayIn.ArrayPolarization         = 'Dual, Dual';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [10; 10; 10];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [6; 6; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.BeamformingMethod         = 'Custom'; % 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = false; % true;
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
    tgayInfo = info(tgayIn);
    NTE = tgayInfo.NumTxElements;
    NTS = tgayInfo.NumTxStreams;
    NRE = tgayInfo.NumRxElements;
    NRS = tgayInfo.NumRxStreams;
    tgayIn.TransmitBeamformingVectors = ones(NTE,NTS)/sqrt(NTE);
    tgayIn.ReceiveBeamformingVectors = ones(NRE,NRS)/sqrt(NRE);
elseif strcmp(chanEnvStr, 'SCH-SU-MIMO2x2DD-HBF')
    tgayIn.Environment               = 'Street canyon hotspot';
    tgayIn.UserConfiguration         = 'SU-MIMO 2x2';
    tgayIn.ArraySeparation           = [1 1];      % [0.8 0.8];
    tgayIn.ArrayPolarization         = 'Dual, Dual';
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [10; 10; 10];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [6; 6; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [90; 0; 0];    % Degrees
    tgayIn.BeamformingMethod         = 'MIMO'; % 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = false; % true;
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
% Previous settings for VTC2020
elseif strcmp(chanEnvStr, 'OAH-D')
    tgayIn.Environment               = 'Open area hotspot';
    tgayIn.TransmitArray.Size        = wlanURAConfig('Size',[2 2]);
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 0];   % Degrees
    tgayIn.ReceiveArray.Size         = wlanURAConfig('Size',[2 2]);
    tgayIn.ReceiveArrayPosition      = [10; 0; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'OAH-E')
    tgayIn.Environment               = 'Open area hotspot';
    tgayIn.TransmitArray.Size        = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 270];   % Degrees
    tgayIn.ReceiveArray.Size         = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 1; 1.5];   % Meters 
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'LHL')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [20 15 6];
    tgayIn.TransmitArray.Size        = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 270];   % Degrees
    tgayIn.ReceiveArray.Size         = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'LHL5')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [20 15 6];
    tgayIn.TransmitArray.Size        = wlanURAConfig('Size',[5 5]);
    tgayIn.TransmitArrayPosition     = [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 270];   % Degrees
    tgayIn.ReceiveArray.Size         = wlanURAConfig('Size',[5 5]);
    tgayIn.ReceiveArrayPosition      = [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'LR')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.RoomDimensions            = [19,10,3];    % [20 15 6];
    tgayIn.TransmitArray.Size        = wlanURAConfig('Size',[5 5]);
    tgayIn.TransmitArrayPosition     = [2; 2; 2.5];    % [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 270];   % Degrees
    tgayIn.ReceiveArray.Size         = wlanURAConfig('Size',[5 5]);
    tgayIn.ReceiveArrayPosition      = [8; 5; 1.6];    % [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
elseif strcmp(chanEnvStr, 'IndoorMIMO2x2SS')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.UserConfiguration         = 'SU-MIMO 2x2';
    tgayIn.ArraySeparation           = [0.8 0.8];      % [0.8 0.8];
    tgayIn.ArrayPolarization         = 'Single, Single';
    tgayIn.RoomDimensions            = [10,5,3];    % [20 15 6];
    tgayIn.TransmitArray.Size        = [8 4]; % [4 4];
    tgayIn.TransmitArrayPosition     = [0-0.4;0;2.99];    % [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 180; 0];   % Degrees
    tgayIn.ReceiveArray.Size         = [4 4];    % [4 4];
    tgayIn.ReceiveArrayPosition      = [3-0.4;0; 1.6];    % [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'MIMO';  %'Maximum power ray';%'MIMO';
    tgayIn.NormalizeImpulseResponses = false;
elseif strcmp(chanEnvStr, 'IndoorMIMO2x2DD')
    tgayIn.Environment               = 'Large hotel lobby';
    tgayIn.UserConfiguration         = 'SU-MIMO 2x2';
    tgayIn.ArraySeparation           = [0.8 0.8];      % [0.8 0.8];
    tgayIn.ArrayPolarization         = 'Dual, Dual';
    tgayIn.RoomDimensions            = [10, 5, 3];    % [20 15 6];
    tgayIn.TransmitArray             = wlanURAConfig('Size',[4 4]);
    tgayIn.TransmitArrayPosition     = [0.4; 0; 2.99];    % [3; 1; 5];     % Meters
    tgayIn.TransmitArrayOrientation  = [0; 180; 0];   % Degrees
    tgayIn.ReceiveArray              = wlanURAConfig('Size',[4 4]);
    tgayIn.ReceiveArrayPosition      = [0.4; 0; 1.6];    % [8; 1; 1.5];   % Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % Degrees
    tgayIn.BeamformingMethod         = 'MIMO';  %'Maximum power ray';%'MIMO';
    tgayIn.NormalizeImpulseResponses = false;
    tgayIn.RandomStream              = 'mt19937ar with seed';
    tgayIn.Seed                      = 100;
elseif strcmp(chanEnvStr, 'Customized')
    % Set customized value
    tgayIn.Environment               = '.';
    tgayIn.RoomDimensions            = [20 15 6]; % x-axis, y-axis and z-axis for LHL
    tgayIn.TransmitArray.Size        = [2 2]; % URA 2x2
    tgayIn.TransmitArrayPosition     = [0; 0; 6];     % [x; y; z] Meters
    tgayIn.TransmitArrayOrientation  = [0; 0; 0];   % [bearing; downtilt; slant] in Degrees
    tgayIn.ReceiveArray.Size         = [2, 2];    % [4 4];
    tgayIn.ReceiveArrayPosition      = [10; 0; 1.5];    %  [x; y; z]Meters
    tgayIn.ReceiveArrayOrientation   = [0; 0; 0];     % [bearing; downtilt; slant] Degrees
    tgayIn.BeamformingMethod         = 'Maximum power ray';
    tgayIn.NormalizeImpulseResponses = true;
else
    error('chanEnvStr should be one of OAH-D, OAH-E, OAH2, LHL, LR.');
end
% if flag == 1
%     tgayIn.showEnvironment;
% end

tgayOut = tgayIn;
end
