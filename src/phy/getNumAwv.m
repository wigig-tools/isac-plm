function [t, r] = getNumAwv(cfgEDMG,codebook)
%%GETNUMAWV Return the number of Tx and Rx AWV

% [T, R] = GETNUMAWV(cfgEDMG,codebook) returns the number of AWVs T scanned
% at transmitter and the number of AWVs R scanned at the receiver, given
% the EDMG object and the codebook structure.

% 2021-2023 NIST/CTL Steve Blandino

% This file is available under the terms of the NIST License.

switch cfgEDMG.SensingType
    case 'bistatic-trn'
        switch cfgEDMG.PacketType
            case 'TRN-T'
                r = 1;
                t = cfgEDMG.TrainingLength*(cfgEDMG.UnitM+1)/cfgEDMG.UnitN;
            case 'TRN-R'
                t = 1;
                r = 10*cfgEDMG.TrainingLength;
            case 'TRN-TR'
                r = (cfgEDMG.UnitRxPerUnitTx+1)*(cfgEDMG.UnitM+1);
                t = cfgEDMG.TrainingLength;
        end
    case 'passive-ppdu'
        r = 1;
        t = 1;
    case 'passive-beacon'
        r =1;
        t =codebook(1).numSectors;

end