% /*************************************************************************************
%    Intel Corp.
%
%    Project Name:  60 GHz Conference Room Channel Model
%    File Name:     cr_ch_model.m
%    Authors:       A. Lomayev, R. Maslennikov
%    Version:       5.0
%    History:       May 2010 created
%    Update:        Jiayi Zhang, NIST/CTL, 2018/04/10
%
%  *************************************************************************************
%    Description:
%
%    function returns channel impulse response for Conference Room (CR) environment
%
%    [imp_res] = cr_ch_model()
%
%    Inputs:
%       no inputs, parameters are set in cr_ch_cfg.m configuration file
%       Modified by adding inputs
%
%    Outputs:
%
%       1. imp_res - channel impulse response
%
%  *************************************************************************************/
function [imp_res] = intel_cr_ch_model(sample_rate,ap_sp,Plos,tx_ant_type,rx_ant_type,tx_hpbw,rx_hpbw)
% clc

% load configuration structure <- cr_ch_cfg.m
% cfg = cr_ch_cfg;
cfg = intel_cr_ch_cfg(sample_rate,ap_sp,Plos,tx_ant_type,rx_ant_type,tx_hpbw,rx_hpbw); % Modified by adding inputs

% generate space-time channel impulse response realization
ch = gen_cr_ch(cfg.cr,cfg.bf.ps,cfg.bf.pol);

% apply beamforming algorithm
[imp_res,toa] = beamforming(cfg.bf,ch);

% continuous time to descrete time conversion
imp_res = ct2dt(imp_res,toa,cfg.sample_rate);

% normalization according to Pnorm parameter
if (cfg.Pnorm)
    imp_res = imp_res./norm(imp_res);
end