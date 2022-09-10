function indices = edmgFieldIndices(cfgEDMG, varargin)
%edmgFieldIndices Generate field indices for WLAN packet
%
%   INDICES = edmgFieldIndices(CFGEDMG) returns the start and end
%   time-domain sample indices for all fields in a packet relative to the
%   first sample in a packet.
%
%   INDICES is a structure array of field names for the specified
%   configuration and contains the start and end indices of all fields in a
%   packet.
%
%   CFGEDMG is a format configuration object of type nist.edmgConfig.
%
%   INDICES = edmgFieldIndices(CFGEDMG, FIELDNAME) returns the start and
%   end time-domain sample indices for the specified FIELDNAME in a packet.
%   INDICES is a row vector of size two representing the start and end
%   sample indices of the specified field.
%
%   FIELDNAME is a character vector or string specifying the field of
%   interest and depends on the type of CFGEDMG:
%
%     For nist.edmgConfig, the fields of interest 'DMG-STF', 'DMG-CE', 
%     'DMG-Header', and 'DMG-Data' are common for all EDMG PHY formats.

%   Copyright 2015-2018 The MathWorks, Inc.
%   Revision 2019-2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen

% Validate input is a class object
validateattributes(cfgEDMG, {'nist.edmgConfig'}, {'scalar'}, mfilename, 'format configuration object');

narginchk(1,2)
if nargin == 1
    
    if isa(cfgEDMG, 'nist.edmgConfig')
        indSTF = getEDMGIndices(cfgEDMG,'DMG-STF');
        indCEF = getEDMGIndices(cfgEDMG,'DMG-CE');
        indHeader = getEDMGIndices(cfgEDMG,'DMG-Header');
        indEDMGHeaderA = getEDMGIndices(cfgEDMG,'EDMG-Header-A');
        indEDMGSTF = getEDMGIndices(cfgEDMG,'EDMG-STF');
        if cfgEDMG.MsSensing == 0
            indEDMGCEF = getEDMGIndices(cfgEDMG,'EDMG-CEF');
            indEDMGHeaderB = getEDMGIndices(cfgEDMG,'EDMG-Header-B');
            indData = getEDMGIndices(cfgEDMG,'EDMG-Data');

            indices = struct(...
                'DMGSTF',         indSTF, ...
                'DMGCE',          indCEF, ...
                'DMGHeader',      indHeader, ...
                'EDMGHeaderA',    indEDMGHeaderA, ...
                'EDMGSTF',        indEDMGSTF, ...
                'EDMGCEF',        indEDMGCEF, ...
                'EDMGHeaderB',    indEDMGHeaderB, ...
                'EDMGData',       indData ...
                ...%'DMGAGC',         indAGC, ...
                ...%'DMGAGCSubfields',indAGCsf, ...
                ...%'DMGTRN',         indTRN, ...
                ...%'DMGTRNCE',       indTRNCE,...
                ...%'DMGTRNSubfields',indTRNSF
                );
        elseif cfgEDMG.MsSensing == 1
            indSync = getEDMGIndices(cfgEDMG,'EDMG-SYNC');
            indTRN = getEDMGIndices(cfgEDMG,'EDMG-TRN');
            indTRNUNITS = getEDMGIndices(cfgEDMG,'EDMG-TRNUNIT');
            indTRNSubfields = getEDMGIndices(cfgEDMG,'EDMG-TRNSubfields');
            indTRNUnitP = getEDMGIndices(cfgEDMG,'EDMG-TRNUnitP');
%             indTRNUNITS
%         elseif strcmpi(fieldType, 'EDMG-TRNSubfields')
%     agcInd = getEDMGIndicesRaw(format,'EDMG-AGC'); % Previous field
%     fieldStart = double(agcInd(2))+1;    
%     if strcmp(phyType(format),'OFDM')
%         NumCESamples = 1152*(3/2);
%         fieldLength = 640*(3/2);
%     else % Control/SC
%         NumCESamples = 1152;
%         fieldLength = 640;
%     end
%     if wlan.internal.isBRPPacket(format)
%         numTRN = format.TrainingLength;
%     else
%         numTRN = 0;
%     end
%     indStart = fieldStart+(NumCESamples*ceil((1:numTRN).'/4))+(0:fieldLength:(fieldLength*numTRN-1)).';
%     indEnd = indStart+fieldLength-1; = getEDMGIndices(cfgEDMG,'EDMG-TRNUNIT');

            indices = struct(...
                'DMGSTF',         indSTF, ...
                'DMGCE',          indCEF, ...
                'DMGHeader',      indHeader, ...
                'EDMGHeaderA',    indEDMGHeaderA, ...
                'EDMGSTF',        indEDMGSTF, ...
                'EDMGSYNC',       indSync, ...
                'EDMGTRN',        indTRN, ...
                'EDMGTRNUNITS',   indTRNUNITS, ...                
                'TRNSubfields', indTRNSubfields, ...
                'TRNUnitP',indTRNUnitP ...
                );

        end
        
%         indAGC = getEDMGIndices(cfgEDMG,'EDMG-AGC');
%         indAGCsf = getEDMGIndices(cfgEDMG,'EDMG-AGCSubfields');       
    end
    
else
    fieldType = varargin{1};
    
    if isa(cfgEDMG,'nist.edmgConfig')
        coder.internal.errorIf(~(ischar(fieldType) || (isstring(fieldType) && isscalar(fieldType))) || ...
            ~any(strcmpi(fieldType,{'DMG-STF','DMG-CE','DMG-Header', ...
            'EDMG-Header-A','EDMG-STF','EDMG-CEF','EDMG-Header-B','EDMG-Data', ...
%             'DMG-AGC','DMG-TRN','DMG-AGCSubfields','DMG-TRNSubfields','DMG-TRNCE'
            })), ...
            'nist:wlanFieldIndices:InvalidFieldTypeEDMG');
        indices = getEDMGIndices(cfgEDMG, fieldType);
    end
    
end
end

function out = getEDMGIndices(varargin)
    tmpOut = getEDMGIndicesRaw(varargin{:});
    
    % If the end indice is less than the start then return empty indices to
    % indicate field not present
    if ~isempty(tmpOut) && tmpOut(end)<tmpOut(1)
        out = zeros(0,2,'uint32');
    else
        out = tmpOut;
    end
end

function out = getEDMGIndicesRaw(format, fieldType)
coder.varsize('indStart','indEnd',[64 1],[1 0]);

if strcmpi(fieldType, 'DMG-STF')
    indStart = 1;
    switch phyType(format)
        case 'Control'
            fieldLength = 128*50;
        case 'OFDM'
            fieldLength = 128*17*(3/2);
        otherwise % SC
            fieldLength = 128*17;
    end
    indEnd = indStart+fieldLength-1;
elseif strcmpi(fieldType, 'DMG-CE')
    prevInd = getEDMGIndicesRaw(format,'DMG-STF'); % Previous field
    indStart = double(prevInd(2))+1;
    if strcmp(phyType(format),'OFDM')
        fieldLength = 128*9*(3/2);
    else % Control/SC
        fieldLength = 128*9;
    end
    indEnd = indStart+fieldLength-1;
elseif strcmpi(fieldType, 'DMG-Header')
    prevInd = getEDMGIndicesRaw(format,'DMG-CE'); % Previous field
    indStart = double(prevInd(2))+1;
    switch phyType(format)
        case 'Control'
            fieldLength = 0; % It is included in following field
        case 'OFDM'
            info = nist.edmgOFDMInfo(format);
            fieldLength = 512+(info.NGI);
        otherwise % SC
            fieldLength = 1024;
    end
    indEnd = indStart+fieldLength-1;
elseif strcmpi(fieldType, 'EDMG-Header-A')
    prevInd = getEDMGIndicesRaw(format,'DMG-Header'); % Previous field
    indStart = double(prevInd(2))+1;
    switch phyType(format)
        case 'Control'
            Length = format.PSDULength;
            L_Header = 5;
            L_EDMG_Header_A  = 9;
            L_EDMG_Header_A2 = 3;
            Ncw = 1+ceil((Length+L_EDMG_Header_A2)*8/168);
            fieldLength = (Length+L_Header+L_EDMG_Header_A)*8+168*Ncw*32;
        case 'OFDM'
            fieldLength = 1088*3/2;
        otherwise % SC
            if format.NumUsers==1
                fieldLength = 1024;
            elseif format.NumUsers>1
                fieldLength = 1088;
            end
            
    end
    indEnd = indStart+fieldLength-1;

elseif strcmpi(fieldType, 'EDMG-STF')
    prevInd = getEDMGIndicesRaw(format,'EDMG-Header-A'); % Previous field
    indStart = double(prevInd(2))+1;
    switch phyType(format)
        case 'Control'
            fieldLength = 0; % Not defined
        case 'OFDM'
            fieldLength = 3840;
        otherwise % SC
            fieldLength = 2432;
    end
    indEnd = indStart+fieldLength-1;

elseif strcmpi(fieldType, 'EDMG-CEF')
     prevInd = getEDMGIndicesRaw(format,'EDMG-STF'); % Previous field
    indStart = double(prevInd(2))+1;
    [~, N_EDMG_CEF]  =  edmgCEConfig(format);

    switch phyType(format)
        case 'Control'
            fieldLength = 0; % Not defined
        case 'OFDM'
            fieldLength = 704*N_EDMG_CEF;
        otherwise % SC
            fieldLength  = 1152 +1280*(N_EDMG_CEF-1);
    end
    indEnd = indStart+fieldLength-1;
    
elseif strcmpi(fieldType, 'EDMG-Header-B')
    
     prevInd = getEDMGIndicesRaw(format,'EDMG-CEF'); % Previous field
     indStart = double(prevInd(2))+1;

    switch phyType(format)
        case 'Control'
            fieldLength = 0; % Not defined
        case 'OFDM'
            info = nist.edmgOFDMInfo(format);
            if format.NumUsers==1
                fieldLength  = 0;
            elseif format.NumUsers>1
                fieldLength  = 512+info.NGI;
            end
        otherwise % SC
            if format.NumUsers==1
                fieldLength  = 0;
            elseif format.NumUsers>1
                fieldLength  = 512;
            end
    end
    indEnd = indStart+fieldLength-1;
    
elseif strcmpi(fieldType, 'EDMG-Data')
    prevInd = getEDMGIndicesRaw(format,'EDMG-Header-B'); % Previous field
    indStart = double(prevInd(2))+1;
    validateConfig(format,'Length');
    switch phyType(format)
        case 'Control'
            parms = edmgControlEncodingInfo(format);   % Modified
            fieldLength = (11*8+(format.PSDULength-6)*8+parms.NCW*168)*32-8192;
        case 'OFDM'
            NSYMS = getMaxNumberBlocks(format);
            info = nist.edmgOFDMInfo(format);
            fieldLength = NSYMS*(info.NFFT+(info.NGI));
        otherwise % SC
            NBLKS = getMaxNumberBlocks(format);
            info = edmgSCInfo(format);
            fieldLength = (NBLKS*info.NFFT+info.NGI);
    end
    indEnd = indStart+fieldLength-1;
% elseif strcmpi(fieldType, 'EDMG-AGC')
%     prevInd = getEDMGIndicesRaw(format,'EDMG-Data'); % Previous field
%     indStart = double(prevInd(2))+1;
%     if wlan.internal.isBRPPacket(format)
%         numTRN = format.TrainingLength;
%     else
%         numTRN = 0;
%     end
%     if strcmp(phyType(format),'OFDM')
%         fieldLength = 320*(3/2)*numTRN;
%     else % Control/SC
%         fieldLength = 320*numTRN;
%     end
%     indEnd = indStart+fieldLength-1;
%     
% elseif strcmpi(fieldType, 'EDMG-AGCSubfields')
%     prevInd = getEDMGIndicesRaw(format,'EDMG-Data'); % Previous field
%     fieldStart = double(prevInd(2))+1;
%     if wlan.internal.isBRPPacket(format)
%         numTRN = format.TrainingLength;
%     else
%         numTRN = 0;
%     end
%     if strcmp(phyType(format),'OFDM')
%         fieldLength = 320*(3/2);
%     else % Control/SC
%         fieldLength = 320;
%     end
%     indStart = fieldStart+(0:fieldLength:(fieldLength*numTRN)-1).';
%     indEnd = indStart+fieldLength-1;
elseif strcmpi(fieldType, 'EDMG-SYNC')
    prevInd = getEDMGIndicesRaw(format,'EDMG-STF'); % Previous field
    indStart = double(prevInd(2))+1;
    TRN_BL = 128;
    fieldLength  = 18 * TRN_BL *format.NumContiguousChannels*format.NumUsers;
    indEnd = indStart+fieldLength-1;
    
elseif strcmpi(fieldType, 'EDMG-TRN')
%     prevInd = getEDMGIndicesRaw(format,'EDMG-AGC'); % Previous field
    prevInd = getEDMGIndicesRaw(format,'EDMG-SYNC'); % Previous field
    indStart = double(prevInd(2))+1;
    if wlan.internal.isBRPPacket(format) && format.MsSensing == 0
        prevInd = getEDMGIndicesRaw(format,'EDMG-Data'); % Previous field
        indStart = double(prevInd(2))+1;
        numTRNUnits = format.TrainingLength/4;
        if strcmp(phyType(format),'OFDM')
            fieldLength = (3/2)*(640*4+1152)*numTRNUnits;
        else % Control/SC
            fieldLength = (640*4+1152)*numTRNUnits;
        end
    elseif format.MsSensing == 1
        sfLen = format.SubfieldSeqLength*6;
        numTRNUnits = format.TrainingLength;
        switch format.PacketType
            case 'TRN-T'
                fieldLength = sfLen*format.UnitP + numTRNUnits*sfLen*(format.UnitP+ format.UnitM+1);
            case 'TRN-TR'
                fieldLength = sfLen*format.UnitP + sfLen*(format.UnitP+format.UnitM+1)*(format.UnitRxPerUnitTx+1)*numTRNUnits;
            case 'TRN-R'
                fieldLength = 10*sfLen*numTRNUnits;
        end
    else
        fieldLength = 0;
    end
    
    indEnd = indStart+fieldLength-1;
elseif strcmpi(fieldType, 'EDMG-TRNUNIT')
    prevInd = getEDMGIndicesRaw(format,'EDMG-SYNC'); % Previous field
    fieldStart = double(prevInd(2))+1; 
    if format.MsSensing == 0
        if strcmp(phyType(format),'OFDM')
            NumCESamples = 1152*(3/2);
            fieldLength = 640*(3/2);
        else % Control/SC
            NumCESamples = 1152;
            fieldLength = 640;
        end
        if wlan.internal.isBRPPacket(format)
            numTRN = format.TrainingLength;
        else
            numTRN = 0;
        end
        indStart = fieldStart+(NumCESamples*ceil((1:numTRN).'/4))+(0:fieldLength:(fieldLength*numTRN-1)).';
    else
        switch format.PacketType
            case 'TRN-T'
                NumCESamples = format.UnitP * format.SubfieldSeqLength *6;
                fieldLength  = (format.UnitM+1) * format.SubfieldSeqLength *6;
                TRNLen = NumCESamples+fieldLength;

            case 'TRN-TR'
                NumCESamples = format.UnitP * format.SubfieldSeqLength *6;
                fieldLength  = ((format.UnitM+1) * format.SubfieldSeqLength *6);
                TRNLen = (NumCESamples+fieldLength)*(format.UnitRxPerUnitTx+1)*format.TrainingLength;

            case 'TRN-R'
                TRNLen  = 10 * format.SubfieldSeqLength *6;
        end
        indStart = (fieldStart:TRNLen:fieldStart+(TRNLen-1)*format.TrainingLength).';
        indEnd = indStart+TRNLen-1;
    end
elseif strcmpi(fieldType, 'EDMG-TRNSubfields')
    prevInd = getEDMGIndicesRaw(format,'EDMG-SYNC'); % Previous field
    fieldStart = double(prevInd(2))+1;
    SubFieldLen =  format.SubfieldSeqLength *6;

    switch format.PacketType
        case 'TRN-T'
            NumCESamples = format.UnitP * SubFieldLen;
            fieldLength  = (format.UnitM+1) * SubFieldLen;
            TRNLen = NumCESamples+fieldLength;
            indStart = (fieldStart:SubFieldLen:(fieldStart+TRNLen*(format.TrainingLength)-1)).';
            indStart = reshape(indStart, [], format.TrainingLength);
            indStart = reshape(indStart(format.UnitP+1:end,:), [],1);
            indEnd = indStart+SubFieldLen-1;
 
        case 'TRN-TR'
            NumCESamples = format.UnitP * SubFieldLen;
            fieldLength  = ((format.UnitM+1) * SubFieldLen);
            TRNLen = (NumCESamples+fieldLength)*(format.UnitRxPerUnitTx+1)*format.TrainingLength;
            indStart = (fieldStart:SubFieldLen:(fieldStart+TRNLen-1)).';
            indStart = reshape(indStart.', [], format.TrainingLength*(format.UnitRxPerUnitTx+1));
            indStart = reshape(indStart(format.UnitP+1:end,:), [],1);

        case 'TRN-R'
            indStart = (fieldStart:SubFieldLen:(fieldStart+SubFieldLen*(10*format.TrainingLength-1))).';
            indEnd = indStart+SubFieldLen-1;
    end


elseif strcmpi(fieldType, 'EDMG-TRNUnitP')
    prevInd = getEDMGIndicesRaw(format,'EDMG-SYNC'); % Previous field
    fieldStart = double(prevInd(2))+1;
    SubFieldLen =  format.SubfieldSeqLength *6;

    switch format.PacketType
        case 'TRN-T'
            NumCESamples = format.UnitP * SubFieldLen;
            fieldLength  = (format.UnitM+1) * SubFieldLen;
            TRNLen = NumCESamples+fieldLength;
            indStart = (fieldStart:SubFieldLen:(fieldStart+TRNLen*(format.TrainingLength)-1)).';
            indStart = reshape(indStart, [], format.TrainingLength);
            indStart = reshape(indStart(1:format.UnitP,:), [],1);
            indEnd = indStart+SubFieldLen-1;
 
        case 'TRN-TR'
            NumCESamples = format.UnitP * SubFieldLen;
            fieldLength  = ((format.UnitM+1) * SubFieldLen);
            TRNLen = (NumCESamples+fieldLength)*(format.UnitRxPerUnitTx+1)*format.TrainingLength;
            indStart = (fieldStart:SubFieldLen:(fieldStart+TRNLen-1)).';
            indStart = reshape(indStart.', [], format.TrainingLength*(format.UnitRxPerUnitTx+1));
            indStart = reshape(indStart(format.UnitP+1:end,:), [],1);

        case 'TRN-R'
            indStart = [];
            indEnd = [];
    end






    %         NumCESamples = 1152;
%         fieldLength = 640;
%     if wlan.internal.isBRPPacket(format)
%         numTRN = format.TrainingLength;
%     else
%         numTRN = 0;
%     end
%     indStart = fieldStart+(NumCESamples*ceil((1:numTRN).'/4))+(0:fieldLength:(fieldLength*numTRN-1)).';
%     indEnd = indStart+fieldLength-1;




%     indEnd = indStart+fieldLength-1;
% else % strcmpi(fieldType, 'DMG-TRNCE')
%     agcInd = getEDMGIndicesRaw(format,'EDMG-AGC'); % Previous field
%     fieldStart = double(agcInd(2))+1;
%     if strcmp(phyType(format),'OFDM')
%         fieldLength = 1152*(3/2);
%         numTRNSamples = 640*4*(3/2);
%     else % Control/SC
%         fieldLength = 1152;
%         numTRNSamples = 640*4;
%     end
%     if wlan.internal.isBRPPacket(format)
%         numTRNUnits = format.TrainingLength/4;
%     else
%         numTRNUnits = 0;
%     end
%     indStart = fieldStart+((fieldLength+numTRNSamples)*((1:(numTRNUnits)).'-1));
%     indEnd = indStart+fieldLength-1;
end
out = uint32([indStart, indEnd]);

end

