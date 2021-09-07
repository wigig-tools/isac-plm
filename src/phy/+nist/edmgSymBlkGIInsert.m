function y = edmgSymBlkGIInsert(scInfo,x,varargin)
%edmgSymBlkGIInsert EDMG SC PHY blocking and GI insertion
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = edmgSymBlkGIInsert(X) blocks and inserts a GI according to IEEE
%   P802.11ay Draft 7.0. A GI is not appended to the end of the
%   waveform.
%
%   Y = edmgSymBlkGIInsert(X,APPENDPOSTFIX) appends a GI postfix if
%   APPENDPOSTFIX is true.

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.


%#codegen

% Optional argument to append GI
narginchk(1,4)  % (1,2)
if nargin==3 % 1
    postfixGI = varargin{1};
    numDataSymPerBlk = scInfo.NDSPB; % 448; % Symbols
    GI = scInfo.NGI;
elseif nargin==4
    postfixGI = varargin{1};
    numDataSymPerBlk= varargin{2};
    GI = scInfo.NFFT-numDataSymPerBlk;
else
    postfixGI = false;
    numDataSymPerBlk = scInfo.NDSPB; % 448; % Symbols
    GI = scInfo.NGI;

end

numBlks = size(x,1)/numDataSymPerBlk;
% numBlks = floor(size(x,1)/numDataSymPerBlk);

% Block data and add GI with pi/2 rotation per sample
Ga = wlanGolaySequence(GI);
yt = [repmat(rotate(Ga),1,numBlks); reshape(x,numDataSymPerBlk,numBlks)];

% Add postfix GI with pi/2 rotation per sample
if postfixGI
    y = [yt(:); rotate(Ga)];
else
    y = yt(:);
end
end

% pi/2 rotation per sample
function y = rotate(x)
    % Equivalent to: y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end