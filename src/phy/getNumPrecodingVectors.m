function [t, r] = getNumPrecodingVectors(cfgEDMG)

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