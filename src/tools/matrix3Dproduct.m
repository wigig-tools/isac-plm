function M = matrix3Dproduct(M1,M2)
%%MATRIX3DPRODUCT Execute a matrix multiplication when the number of 
% dimension of M1 or M2 is > 2 and squeeze it
%

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.


if ndims(M1) == 3 && ismatrix(M2)
 
    SzM1 = size(M1);
    SzM2 = size(M2);
    M1_reshaped = reshape(permute(M1, [1 3 2]), SzM1(1)*SzM1(3), []);


    M_reshaped = M1_reshaped*M2;
    M= permute(reshape(M_reshaped.', SzM2(2), SzM1(1), []), [2 1 3]);

elseif ismatrix(M1) && ndims(M2) == 3
    SzM1 = size(M1);
    SzM2 = size(M2);
    M_reshaped = reshape(M2, SzM2(1), []);
    M = reshape(M1.'*M_reshaped, SzM1(2), SzM2(2),[]);
    
else
    error('')

end