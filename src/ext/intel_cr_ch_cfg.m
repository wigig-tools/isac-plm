% /*************************************************************************************
%    Intel Corp.
%
%    Project Name:  60 GHz Conference Room Channel Model
%    File Name:     cr_ch_cfg.m
%    Authors:       A. Lomayev, R. Maslennikov
%    Version:       5.0
%    History:       May 2010 created
%    Update:        Jiayi Zhang, NIST/CTL, 2018/04/10
%
%  *************************************************************************************
%    Description:
%
%    configuration function returns structure contained main parameters for
%    channel function cr_ch_model.m generating channel impulse response for
%    Conference Room (CR) environment
%
%    [cfg] = cr_ch_cfg()
%
%    Inputs: no inputs (Modified by adding inputs)
%
%    Outputs: configuration structure
%
%    cfg.field    - common parameters
%    cfg.cr.field - space temporal clusters distribution related parameters
%    cfg.bf.field - beamforming and antennas related parameters
%
%  *************************************************************************************/
function [cfg] = intel_cr_ch_cfg(sample_rate,ap_sp,Plos,tx_ant_type,rx_ant_type,tx_hpbw,rx_hpbw)

 
% COMMON PARAMETERS

cfg.Pnorm       = 1;        % normalization parameter: 0 - w/o normalization, 1 - apply normalization for output channel impulse response
cfg.sample_rate = sample_rate;  % 2.56;     % sample rate in [GHz] applied for continuous time to discrete time channel impulse response conversion

% CFG.CR SUBSTRUCTURE   

cfg.cr.ap_sp = ap_sp;           % parameter selects subscenario: 0 - STA-STA subscenario, 1 - STA-AP subscenario

cfg.cr.D    = 2;            % distance in [meters] between TX and RX, note that when the AP is placed near the ceiling distance D between TX and RX is set in horizontal plane
cfg.cr.Plos = Plos;            % LOS (Line-of-Sight) parameter, permitted values: 0 - corresponds to NLOS scenario, 1 - corresponds to LOS scenario

% probabilities for STA-STA subscenario
cfg.cr.Psta_1st_c  = 1;     % probability that the cluster is present (i.e. not blocked) for the 1st order reflections from ceiling
cfg.cr.Psta_1st_w  = 0.76;  % probability that the cluster is present (i.e. not blocked) for the 1st order reflections from walls
cfg.cr.Psta_2nd_wc = 0.963; % probability that the cluster is present (i.e. not blocked) for the 2nd order wall-ceiling (ceiling-wall) reflections
cfg.cr.Psta_2nd_w  = 0.825; % probability that the cluster is present (i.e. not blocked) for the 2nd order reflections from walls

% probabilities for STA-AP subscenario
cfg.cr.Pap_1st = 0.874;     % probability that the cluster is present (i.e. not blocked) for the 1st order reflections from walls
cfg.cr.Pap_2nd = 0.93;      % probability that the cluster is present (i.e. not blocked) for the 2nd order reflections from walls


% CFG.BF SUBSTRUCTURE (BEAMFORMING & ANTENNAS RELATED PARAMETERS)

cfg.bf.bf_alg = 0;          % beamforming algorithm: 0 - max power ray algorithm, 1 - max power exhaustive search algorithm

cfg.bf.matlab_c = 0;        % this flag selects Matlab or C function to perform exhaustive search in beamforming procedure: 0 - use Matlab function, 1 - use C function

% antenna type parameter selects antenna type in beamforming search procedure
cfg.bf.tx_ant_type = tx_ant_type;     % default: 1 % TX antenna type, permitted values: 0 - isotropic radiator, 1 - basic steerable directional antenna
cfg.bf.rx_ant_type = rx_ant_type;     % default: 1 % RX antenna type, permitted values: 0 - isotropic radiator, 1 - basic steerable directional antenna

% spherical sector bound for antenna beam search in beamformig procedure,
% MAX value is 90 degree
cfg.bf.tx_sec_bound = 90;   % TX sector bound
cfg.bf.rx_sec_bound = 90;   % RX sector bound

% half-power antenna beamwidth in [deg] applied for basic steerable directional antenna model
cfg.bf.tx_hpbw = tx_hpbw;   % default 30;        % TX antenna beamwidth
cfg.bf.rx_hpbw = rx_hpbw;   % default 30;        % RX antenna beamwidth

cfg.bf.ps     = 0;          % polarization support parameter: 0 - TX/RX polarization vectors are not applied, 1 - polarization is applied
cfg.bf.pol(1) = 0;          % antenna polarization type on TX side: 0 - linear in theta direction, 1 - linear in thi direction, 2 - LHCP, 3 - RHCP
cfg.bf.pol(2) = 0;          % antenna polarization type on RX side: 0 - linear in theta direction, 1 - linear in thi direction, 2 - LHCP, 3 - RHCP


% angles set using for exhaustive search at TX and RX sides

% select subscenario
switch (cfg.cr.ap_sp)
    case 0, % STA - STA
        % TX angles grid
        switch (cfg.bf.tx_ant_type)
            case 0, % isotropic radiator
                cfg.bf.tx_az = [0]; % azimuths in [deg]
                cfg.bf.tx_el = [0]; % elevations in [deg]
            case 1, % sterable directional antenna
                [cfg.bf.tx_az, cfg.bf.tx_el] = angles_grid(cfg.bf.tx_hpbw,cfg.bf.tx_sec_bound,0);
            otherwise,
                error('Prohibited value of "cfg.tx_ant_type" parameter');
        end
        
        % RX angles grid
        switch (cfg.bf.rx_ant_type)
            case 0, % isotropic radiator
                cfg.bf.rx_az = [0]; % azimuths in [deg]
                cfg.bf.rx_el = [0]; % elevations in [deg]
            case 1, % sterable directional antenna
                [cfg.bf.rx_az, cfg.bf.rx_el] = angles_grid(cfg.bf.rx_hpbw,cfg.bf.rx_sec_bound,0);
            otherwise,
                error('Prohibited value of "cfg.rx_ant_type" parameter');
        end
    case 1, % STA - AP
        % TX angles grid
        switch (cfg.bf.tx_ant_type)
            case 0, % isotropic radiator
                cfg.bf.tx_az = [0]; % azimuths in [deg]
                cfg.bf.tx_el = [0]; % elevations in [deg]
            case 1, % sterable directional antenna
                [cfg.bf.tx_az, cfg.bf.tx_el] = angles_grid(cfg.bf.tx_hpbw,cfg.bf.tx_sec_bound,0);
                cfg.bf.tx_el = 180 - cfg.bf.tx_el;
            otherwise,
                error('Prohibited value of "cfg.tx_ant_type" parameter');
        end
        
        % RX angles grid
        switch (cfg.bf.rx_ant_type)
            case 0, % isotropic radiator
                cfg.bf.rx_az = [0]; % azimuths in [deg]
                cfg.bf.rx_el = [0]; % elevations in [deg]
            case 1, % sterable directional antenna
                [cfg.bf.rx_az, cfg.bf.rx_el] = angles_grid(cfg.bf.rx_hpbw,cfg.bf.rx_sec_bound,0);
            otherwise,
                error('Prohibited value of "cfg.rx_ant_type" parameter');
        end
        
    otherwise,
        error('Prohibited value of "cfg.cr.ap_sp" parameter');
end

if ((cfg.bf.ps==1) && ( (cfg.bf.tx_ant_type == 0) || (cfg.bf.rx_ant_type == 0)))
    error('Modeling of polarization is unsupported for isotropic radiator');
end