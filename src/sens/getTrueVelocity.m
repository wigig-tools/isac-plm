function vTrue = getRadialVelocity(delay,ts)
%%GETRADIALVELOCITY radial veloity
% 
c = getConst('lightSpeed');

dR = (delay(2:end)-delay(1:end-1))*c;
vTrue = dR/ts;
end