function symbols_out = qamHalfPiRotate(symbols_in,ccw)
%qamHalfPiRotate rotates QAM symbols to pi/2-QAM when ccw is 1.
% It derotates the symbols from pi/2-QAM to QAM if ccw is -1
%  Syntax: symbols_out = qamHalfPiRotate(symbols_in, ccw)
%  
%  Returns in output symbols_out the symbols symbols_in after rotation

%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

symbols_out = symbols_in; % initialisation
symbols_out(3:4:end) = -symbols_in(3:4:end);

if ccw == 1
    symbols_out(2:4:end) = 1i*symbols_in(2:4:end);
    symbols_out(4:4:end) = -1i*symbols_in(4:4:end);
elseif ccw == -1
    symbols_out(2:4:end) = -1i*symbols_in(2:4:end);
    symbols_out(4:4:end) = 1i*symbols_in(4:4:end);
else
    error('invalid ccw')
end

end