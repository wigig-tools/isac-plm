function flag = iseye(A)
%iseye Check if matrix A is an identity matrix, return logical 1 for ture, and logical 0 for false otherwise.
%
% Input
%   A is a M-by-N matrix.
%   
% Output
%   flag is a logical flag.

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

assert(ismatrix(A),'input A should be a matrix.');

flag = isdiag(A) && all(abs(diag(A) - 1) < eps);

end