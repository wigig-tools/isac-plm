function plotComparisonConstellation(refConst,evm,rxSymbGrid,detSymbGrid,numUsers,numSTSVec,varargin)
%plotComparisonConstellation Plot figure to comparison constellations
% Input
%   refConst is a cell array of each user's reference constellation points
%   evm is a cell array of each user's EVM value
%   rxSymbGrid and detSymbGrid are the numUsers-length cell arrays, each entry having a 3D matrix 
%       of either numSD-by-numBlock-by-numSTS for OFDM or (NFFT-NGI)-by-NBlks-NSTS for SC.
%   numUsers is a number of users scalar.
%   numSTSVec is a number of STS vector.
%   varargin is an optional figure handle;
% 
%   2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

narginchk(6,7);

if nargin==7
    fig = varargin{1};
else
    fig = figure;
end

for iUser = 1:numUsers
    fig.Name = sprintf('User:%d',iUser);
    fig.Position(1) = 100+300*(numUsers-iUser);
    fig.Position(2) = 400;
    for iSTS = 1:numSTSVec(iUser)
        rxSymbSeq = reshape(rxSymbGrid{iUser}(:,:,iSTS),[],1);
        detSymbSeq = reshape(detSymbGrid{iUser}(:,:,iSTS),[],1);
        % Plot subfigure for received symbol sequence
        subplot(numSTSVec(iUser),2, iSTS*2-1);
        plot(real(rxSymbSeq), imag(rxSymbSeq), 'b.');
        hold on
        plot(real(refConst{iUser}), imag(refConst{iUser}), 'r+');
        hold off
        axis equal, title('Before Equalization'), axis off
        % Plot subfigure for detected symbol sequence
        subplot(numSTSVec(iUser),2, iSTS*2);
        plot(real(detSymbSeq), imag(detSymbSeq), 'b.');
        hold on
        plot(real(refConst{iUser}), imag(refConst{iUser}), 'r+');
        hold off
        axis equal, title(['After Equalization: ', num2str(evm{iUser}(iSTS)), ' dB']), axis off
    end
end
% hold off
% refreshdata
drawnow
                    
end

% End of file