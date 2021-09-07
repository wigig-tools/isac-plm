function adjH = getAdj(H)
%getAdjugateMatrix
%   Calculate adjugate matrix of input matrix
    
%   2019~2021 NIST/CTL Jian Wang, Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

numRows = size(H,1);
numCols = size(H,2);
rowRange = 1:numRows;
columnRange = 1:numCols;

for i = 1:numRows
    for j = 1:numCols
        if size(H,1)==size(H,2)
            if j == 1
                rowRange = 2 : size(H,1);
            elseif j == size(H,1)
                rowRange = 1 : size(H,1)-1;
            elseif (j > 1) && (j < size(H,1))
                rowRange = [1 : j-1, j+1: size(H,1)];
            end
            if i == 1
                columnRange = 2 : size(H,2);
            elseif i == size(H,2)
                columnRange = 1 : size(H,2)-1;
            elseif (i > 1) && (i < size(H,2))
                columnRange = [1 : i-1, i+1: size(H,2)];
            end

            adjH(i, j, :) = (-1)^(i+j)* getDet(H(rowRange, columnRange,:));
        else
            error('Dim1 and Dim2 of H should be same.');
        end
    end
end

end