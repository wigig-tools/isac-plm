function y = edmgSCTDMIMODectect(x,userIdx,numSTSVec,varargin)
%edmgSCTDMIMODectect EDMG Single-Carrier Time-Domain MIMO Detector for Indirect Spatial Mapping
%   This function provides time-domain indirect spatial mapping MIMO decoder for EDMG SC mode individual user's 
%   received signal, both normalized discrete Fourier matrix and Hadamard matrix are supported.
% Input
%   x is a received symbol block matrix with size of numChip-by-numSTS or numChip-by-numBlks-by-numSTS 
%   userIdx is a user index scalar
%   numSTSVec is a 1-by-numUsers number of space-time stream vector for multiple users
%   varargin is an optional indirect spatial mapping matrix with size numSTS-by-numTx
% Output
%   y is the detected symbol matrix with size numChip-by-numSTS or numChip-by-numBlks-numSTS

%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if iscolumn(x)
    % SISO
        y = x;
elseif ismatrix(x) && size(x,2)>1
    [numChip,numSTS] = size(x);
    if numSTSVec(userIdx) ~= numSTS
        error('numSTSVec(userIdx) should be equal to numSTS.');
    end
    % Initialize output
    y = complex(zeros(numChip,numSTS));

    if isempty(varargin{1})  % || isscalar(varargin{1}) 
        y = x;
    elseif isa(varargin{1},'double')
        stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
        mapMatrix = varargin{1};    % Nsts-by-Ntx
        matQ = mapMatrix(1:numSTS, :);
        normQ = matQ * sqrt(numSTS)/norm(matQ,'fro'); % Normalization
        for iChip = 1:numChip
            y(iChip,:) = reshape(x(iChip,:),[1,numSTS]) / (normQ(:,stsIdx)); % A*INV(B)
        end
    elseif isa(varargin{1},'struct')
        csiSvd = varargin{1};
        eqChEstFlag = varargin{2};
        if eqChEstFlag == 4
            matQ = permute(csiSvd.precodMat,[2 1]); % Nsts-by-Ntx
            normQ = matQ * sqrt(numSTS)/norm(matQ,'fro'); % Normalization
            for iChip = 1:numChip
                y(iChip,:) = reshape(x(iChip,:),[1,numSTS]) / (normQ(:,1:numSTS)); % A*INV(B)
            end
        elseif eqChEstFlag == 5
            matQ = conj(permute(csiSvd.postcodMat{userIdx},[2 1]));  % Nsts-by-Nsts
            normQ = matQ * sqrt(numSTS)/norm(matQ,'fro'); % Normalization
            for iChip = 1:numChip
                y(iChip,:) = normQ(:,1:numSTS) * reshape(x(iChip,:),[numSTS,1]); % A*INV(B)
            end
        else
            error('eqChEstFlag should be 4 or 5.'); 
        end
    end
elseif ndims(x) == 3
    [numChip,numBlks,numSTS] = size(x);
    if numSTSVec(userIdx) ~= numSTS
        error('numSTSVec(userIdx) should be equal to numSTS.');
    end
    % Initialize output
    y = complex(zeros(numChip,numBlks,numSTSVec(userIdx)));

    if isempty(varargin{1})  % || isscalar(varargin{1}) 
        y = x;
    elseif isa(varargin{1},'double')
        stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
        mapMatrix = varargin{1};    % Nsts-by-Ntx
        matQ = mapMatrix(stsIdx, :);
        normQ = matQ * sqrt(numSTS)/norm(matQ,'fro'); % Normalization
        for iChip = 1:numChip
            for iBlk = 1:numBlks
                invQ = normQ' *inv(normQ * normQ'); % 
                y(iChip,iBlk,:) =  reshape(x(iChip,iBlk,:),[1,numSTS]) * invQ;
            end
        end
    elseif isa(varargin{1},'struct')
        csiSvd = varargin{1};
        stsIdx = sum(numSTSVec(1:userIdx-1))+(1:numSTSVec(userIdx));
        eqChEstFlag = varargin{2};
        if eqChEstFlag == 3 % 1
            matQ = permute(csiSvd.precodMat(:,stsIdx),[2 1]); % Nsts-by-Ntx
            normQ = matQ * sqrt(numSTS)/norm(matQ,'fro'); % Normalization
            for iChip = 1:numChip
                for iBlk = 1:numBlks
                    y(iChip,iBlk,:) = reshape(x(iChip,iBlk,:),[1,numSTS]) * pinv(normQ); % A*INV(B)
                end
            end
        else
            error('eqChEstFlag should be 1 or 3.');   
        end
    end
else
    error('ndims(x) should be between 1 to 3.');
end


end