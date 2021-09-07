function y = edmgWindowing(x,wLength,cfgEDMG)                 
%dmgWindowing Window time-domain OFDM symbols for DMG OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgWindowing(X,WLENGTH,CFGDMG)returns the time-domain windowed
%   signal for the DMG OFDM PHY. The windowing function for OFDM waveform
%   is defined in IEEE Std 802.11ad-2012, Section 21.3.5.2.
%
%   X is a complex Ns-by-1 vector array containing the time-domain waveform
%   for OFDM PHY.
%
%   WLENGTH is the windowing length in samples to apply. When WLENGTH is
%   zero, no windowing is applied.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   See also wlanWaveformGenerator

%   Copyright 2016 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL, Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen
if wLength == 0
    y = x; % No windowing for window length of zero
    return;
end

numSamp = size(x,1); % Number of samples
numTx = size(x,2);
% numTx = cfgEDMG.NumTransmitAntennas;

% Allocate output, the extra samples allow for rampup and down
y = complex(zeros(numSamp+wLength-1,numTx));

ofdmInfo = nist.edmgOFDMInfo(cfgEDMG);

symLength = ofdmInfo.NFFT+ofdmInfo.NGI; % OFDM symbol length in samples
[index,mag] = wlan.internal.windowingEquation(wLength,symLength);
GILength = ofdmInfo.NGI;

% Get field indices
fieldIndex = nist.edmgFieldIndices(cfgEDMG);

for iTx = 1:numTx
    % Get Header plus Data fields of the packet
    ofdmField = x(fieldIndex.DMGHeader(1):fieldIndex.EDMGData(2),iTx);

    % Reshape by SymLength-by-NumSym
%     ofdmSym = reshape(ofdmField,symLength,length(ofdmField)/symLength);
    ofdmSym = reshape(ofdmField,symLength,[]);
    % Extend symbol length before windowing
    ofdmSymExtended = [ofdmSym(end-(abs(index(1))+GILength)+1:end-GILength,:,:); ...
           ofdmSym; ofdmSym(GILength+(1:wLength/2),:,:)];

    % Apply windowing on the extended symbol portion 
    ofdmSymTappered =  bsxfun(@times,ofdmSymExtended,mag);

    % Window data section
    ofdmSymWindowed = wlan.internal.windowSymbol(ofdmSymTappered,wLength);

    % Get prefix samples of first windowed symbol in OFDM portion
    prefixOFDMSym = ofdmSymWindowed(1:wLength/2-1,:);

    % Get the last preamble samples before the header + data portion
    suffixPreamble = x(fieldIndex.DMGCE(2)-wLength/2+2:fieldIndex.DMGCE(2),iTx);

    % Overlap and add the prefix samples of the preamble field with the suffix of the data field
    preambleSymWindowed = suffixPreamble+prefixOFDMSym;

    if isempty(fieldIndex.EDMGTRN)
        % Append the windowed symbols with the preamble field
        y(:,iTx) = [x(1:fieldIndex.DMGCE(2)-wLength/2+1,iTx); preambleSymWindowed;ofdmSymWindowed(wLength/2:end)];
    else
        % Get suffix samples of last windowed OFDM symbol
        suffixOFDMSym = ofdmSymWindowed(end-wLength/2+1:end);

        % Add the start of BRP samples
        prefixBRP = x(fieldIndex.EDMGTRN(1):fieldIndex.EDMGTRN(1)+wLength/2-1,iTx); 

        % Overlap and add the prefix samples of the preamble field with the suffix of the data field
        brpSymWindowed = prefixBRP+suffixOFDMSym;

        % Concatenate preamble, header, data and BRP fields after windowing
        y(:,iTx) = [x(1:fieldIndex.DMGCE(2)-wLength/2+1,iTx); ...
            preambleSymWindowed; ...
            ofdmSymWindowed(wLength/2:end-wLength/2);...
            brpSymWindowed;
            x(fieldIndex.DMGTRN(1)+wLength/2:end,iTx)];
    end
       
end

end
