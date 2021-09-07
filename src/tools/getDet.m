function [detH] = getDet(H)
% Compute determinant of a square matrix H

%   2019~2021 NIST/CTL Jian Wang, Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

numRows = size(H,1);
numCols = size(H,2);
assert(numRows == numCols,'Dim1 and Dim2 of H should be same.');

detH = 0;
if (numRows== 1)
    detH = H;
else
    for idx = 1:numCols
        detTemp = getDet(H(2: size(H,1), [1:(idx-1), idx+1 : size(H,2)],:));
        detH = detH + (-1)^(1+idx) * PolyMatConv(H(1,idx,:),detTemp);
    end
end


end