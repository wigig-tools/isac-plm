classdef edmgConfig < wlan.internal.ConfigBase
%nist.edmgConfig Create a enhanced directional multi-gigabit (EDMG) format configuration object - NIST version
%   CFGDMG = nist.edmgConfig creates a directional 60 GHz format
%   configuration object. This object contains the transmit parameters for
%   the DMG format of IEEE 802.11 standard.
%
%   CFGDMG = nist.edmgConfig(Name,Value) creates a DMG object, CFGDMG, with
%   the specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   nist.edmgConfig methods:
%
%   phyType - DMG PHY modulation type
%
%   nist.edmgConfig properties:
%
%   MCS                     - Modulation and coding scheme
%   TrainingLength          - Training field length
%   PacketType              - Packet training field type
%   BeamTrackingRequest     - Indicates beam tracking is requested
%   TonePairingType         - Tone pairing type
%   DTPGroupPairIndex       - Specify the DTP group pair indexing
%   DTPIndicator            - Indicate DTP update
%   PSDULength              - PSDU length
%   ScramblerInitialization - Scrambler initialization
%   AggregatedMPDU          - Aggregation indication
%   LastRSSI                - Indicates the received power level of the last packet
%   Turnaround              - Turnaround indication
%   PHYType
%   NumUsers
%   UserPositions
%   NumTransmitAntennas
%   NumSpaceTimeStreams
%   SpatialMappingType
%   SpatialMappingMatrix
%   Beamforming
%   STBC
%   GuardIntervalType
%   NumContiguousChannels
%
%   Reference:
%       IEEE Std 802.11-2016
%       IEEE Std 802.11-2020
%       IEEE P802.11ay Draft 7.0

%   Copyright 2016-2017 The MathWorks, Inc.
%   Revision 2019~2021 NIST/CTL Jiayi Zhang

%   This file is available under the terms of the MathWorks Limited License.
%   You should have received a copy of this license with the NIST [IEEE 802.11ay] source
%   code; see the file MATHWORKS-LIMITED-LICENSE.docx.

%#codegen
    
properties (Access = public)
    %MCS Modulation and coding scheme
    %   Specify the modulation and coding scheme as an integer from 0 to
    %   24. The default value is 0.
    MCS = 0;
    %TrainingLength Training field length
    %   Specify the number of training fields as an integer from 0 to 64,
    %   in multiples of 4. The default value is 0.
    TrainingLength = 0;
    %PacketType Packet training field type
    %   Specify the packet training field type as 'TRN-R' or 'TRN-T'. This
    %   property applies when TrainingLength>0. The default value is
    %   'TRN-R'.
    PacketType = 'TRN-R';
    %SubfieldSeqLength Subfield Seqence Lengt
    % Specify the length of the Golay sequence used to transmit the TRN 
    % subfields present in the TRN field of the PPDU and is set as 128,256 
    % or 64. This property applies when TrainingLength>0. The default value
    % is 128.
    SubfieldSeqLength = 128;
    %UnitP TRN-Unit P
    % For EDMG BRP-TX and EDMG BRP-RX/TX PPDUs, the value of this field 
    % describes the number of TRN subfields in a TRNUnit that are 
    % transmitted using the same AWV used in the transmission of the 
    % preamble and Data fields. Possible values for this field are 0,1,2,4
    UnitP = 2;
    %UnitM TRN-Unit M
    % For EDMG BRP-TX PPDUs, the transmitter may change the AWV at the 
    % beginning of each set of N TRN subfields present in the last M 
    % TRN subfields of each TRN-Unit in the TRN field, where M is the value
    % of this field plus one and the value of N is indicated by UnitN. 
    % For EDMG BRP-RX/TX PPDUs, the value of this field plus one indicates 
    % the number of TRN subfields in a TRN-Unit transmitted with the same 
    % AWV following a possible AWV change.
    UnitM = 1;
    %UnitN TRN-Unit N
    % The value of this field indicates the number of consecutive TRN 
    % subfields within EDMG TRNUnitM that are transmitted using the same 
    % AWV. Possible values for this field
    % are as follows: 1,2,3,4,8
    UnitN = 1;
    %UnitRxPerUnitTx RX TRN-Units per Each TX TRN-Unit
    % The value of this field plus one indicates the number of consecutive
    % TRN-Units in the TRN field for which the transmitter remains with the
    % same transmit AWV
    UnitRxPerUnitTx = 54;
    %BeamTrackingRequest Indicates beam tracking is requested
    %   Set to true to indicate beam tracking is requested. The default is
    %   false. This property applies when TrainingLength>0.
    BeamTrackingRequest = false;
    %TonePairingType Tone pairing type
    %   Specify the tone mapping type as 'Static' or 'Dynamic'. The default
    %   value is 'Static'. This property applies when OFDM and DCM BPSK or
    %   DCM QPSK modulation is used, when MCS is from 1 to 10.
    TonePairingType = 'Static';
    %DTPGroupPairIndex Specify the DTP group pair indexing
    %   Specify the DTP group pair index for each pair as a 42-by-1 vector
    %   of integers. Element values must be in the range 0 to 41. There
    %   must be no duplicate elements. This property applies when OFDM MCS is
    %   from 1 to 10 and when ToneParingType is 'Dynamic'
    DTPGroupPairIndex = (0:41).';
    %DTPIndicator Enable DTP update indication
    %   Bit flip used to indicate DTP update. Set this property to true or
    %   false. The default value is false. This property applies when OFDM MCS
    %   is from 1 to 10 and when ToneParingType is 'Dynamic'.
    DTPIndicator = false;
    %PSDULength PSDU length
    %   Specify the PSDU length in bytes as an integer from 1 to 262143.
    %   The default value is 1000.
    PSDULength = 1000;
    %ScramblerInitialization Scrambler initialization
    %   Specify the scrambler initialization as a double or int8 between 1
    %   and 127, inclusive, or int8-typed binary 7-by-1 column vector. When 
    %   MCS is 0 the valid range is limited to between 1 and 15 inclusive, 
    %   corresponding to a 4-by-1 column vector. The default is 2.
    ScramblerInitialization = 2;
    %AggregatedMPDU Aggregation indication
    %   Set to true to indicate this is a packet with A-MPDU aggregation.
    %   The default is false.
    AggregatedMPDU = false;
    %LastRSSI Indicates the received power level of the last packet
    %   Specify the received power level as an integer from 0 to 15.
    LastRSSI = 0;
    %Turnaround Turnaround indication
    %   Set to true to indicate the STA is required to listen for an
    %   incoming PPDU immediately following the transmission. The default
    %   is false.
    Turnaround = false;
    %*************************************************************************** Add for EDMG
    %PHY TYPE
    %   Specify the PHY type (mode) as one of 'Control' | 'SC' | 'OFDM'.
    PHYType = 'OFDM';
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160'. The default value of this property is 'CBW80'.
%     ChannelBandwidth = 'CBW80';
    %NumUsers Number of users
    %   Specify the number of users as an integer scalar between 1 and 8,
    %   inclusive. The default value of this property is 1.
    NumUsers = 1;
    %UserPositions User positions
    %   Specify the user positions as an integer row vector with length
    %   equal to NumUsers and elements between 0 and 3, inclusive, in a
    %   strictly increasing order. This property applies when you set the
    %   NumUsers property to 2, 3 or 4. The default value of this property
    %   is [0 1].
%     UserPositions = [0 1];
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as an integer scalar
    %   between 1 and 8, inclusive. The default value of this property is
    %   1.
    NumTransmitAntennas = 1;
    %NumSpaceTimeStreams Number of space-time streams per user
    %   Specify the number of space-time streams as integer scalar or row
    %   vector with length equal to NumUsers. For a scalar, it must be
    %   between 1 and 8, inclusive. For a row vector, all elements must be
    %   between 1 and 4, inclusive, and sum to no larger than 8. The
    %   default value of this property is 1.
    NumSpaceTimeStreams = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' | 'Hadamard'
    %   | 'Fourier' | 'Custom'. The default value of this property is
    %   'Direct', which applies when the sum of the elements in
    %   NumSpaceTimeStreams is equal to NumTransmitAntennas.
    SpatialMappingType = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size
    %   NstsTotal-by-Nt, where NstsTotal is the sum of the elements in the
    %   NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-
    %   NstsTotal-Nt, where Nst is the number of occupied subcarriers
    %   determined by the ChannelBandwidth property. Specifically, Nst is
    %   56 for 'CBW20', 114 for 'CBW40', 242 for 'CBW80' and 484 for
    %   'CBW160'. In this case, each occupied subcarrier can have its own
    %   spatial mapping matrix. In either 2D or 3D case, the spatial
    %   mapping matrix for each subcarrier is normalized. The default value
    %   of this property is 1.
    PreambleSpatialMappingType = 'Hadamard';
    %PreambleSpatialMappingType Preamble Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size
    %   NstsTotal-by-Nt, where NstsTotal is the sum of the elements in the
    %   NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-
    %   NstsTotal-Nt, where Nst is the number of occupied subcarriers
    %   determined by the ChannelBandwidth property. Specifically, Nst is
    %   56 for 'CBW20', 114 for 'CBW40', 242 for 'CBW80' and 484 for
    %   'CBW160'. In this case, each occupied subcarrier can have its own
    %   spatial mapping matrix. In either 2D or 3D case, the spatial
    %   mapping matrix for each subcarrier is normalized. The default value
    %   of this property is 1.
    SpatialMappingMatrix = 1;
    %Beamforming Enable beamforming
    %   Set this property to true when the specified SpatialMappingMatrix
    %   property is a beamforming steering matrix(ces). This property
    %   applies when you set the NumUsers property to 1 and the
    %   SpatialMapping property to 'Custom'. The default value of this
    %   property is true.
    Beamforming = true;
    %STBC Enable space-time block coding
    %   Set this property to true to enable space-time block coding in the
    %   data field transmission. This property applies when you set the
    %   NumUsers property to 1. The default value of this property is
    %   false.
    STBC = false;
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length type as one of Short, 
    % Normal, Long. The default is Normal.
    GuardIntervalType = 'Normal';
    % Number of contiguous 2.16 GHz channels (NCB)
    %   Set the number of contiguous 2.16 GHz channels, NCB = 1 for 2.16 GHz and 2.16+2.16 GHz, 
    % NCB = 2 for 4.32 GHz and 4.32+4.32 GHz, NCB = 3 for 6.48 GHz, and NCB = 4 for 8.64 GHz channel
    % Default NCB = 1.
    NumContiguousChannels = 1;
    % Set to 1 to Indicates that the PPDU is an EDMG Multi-Static Sensing PPDU
    % Set to 0 otherwise
    MsSensing = 0;
end

properties(Constant, Hidden)
    PHYType_Values = {'Control','SC','OFDM'};   % Add for EDMG 11ay
    PacketType_Values = {'TRN-R','TRN-T'};
    TonePairingType_Values = {'Static','Dynamic'};
    GuardIntervalType_Values = {'Short','Normal','Long'};
end

methods
  function [obj,varargout] = edmgConfig(varargin)
      
    nargoutchk(0,3);
    
    obj@wlan.internal.ConfigBase( ...
        'PHYType','OFDM', ...
        'PacketType','TRN-R', ...
        'TonePairingType','Static', ...
        varargin{:});
    
    if nargout>1
        [info,chara] = edmgPHYInfoCharacteristics(obj);
        varargout{1} = info;
        varargout{2} = chara;
    end
  end

  function obj = set.MCS(obj,val)
    propName = 'MCS';
%     validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',24},[class(obj) '.' propName],propName);
    % Add for EDMG
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',0,'<=',24}, [class(obj) '.' propName], propName);
    coder.internal.errorIf(length(val) > 8, 'wlan:shared:InvalidMUMCS', 8);
    obj.(propName) = val;
  end
  
  function obj = set.PSDULength(obj, val)
    propName = 'PSDULength';
%     validateattributes(val,{'numeric'},{'real','integer','scalar','>=',1,'<=',262143},[class(obj) '.' propName],propName);
    validateattributes(val,{'numeric'},{'real','integer','row','>=',0,'<=',262143},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.ScramblerInitialization(obj, val)
    propName = 'ScramblerInitialization';
    if isscalar(val) 
        validateattributes(val,{'double','int8'},{'real','integer','column','nonempty','>=',1,'<=',127},[class(obj) '.' propName],propName);
    elseif iscolumn(val)  % [7, 1]
        coder.internal.errorIf(any((val~=0) & (val~=1)) || ~((size(val,1)==7)||(size(val,1)==4)),'nist:edmgConfig:InvalidScramInitValue');
        % Check for non-zero seed initialization
        coder.internal.errorIf(any(sum(val) == 0),'nist:edmgConfig:InvalidScramInitValue');
    elseif isrow(val)  % support multiple users
        validateattributes(val,{'double','int8'},{'real','integer','row','nonempty','>=',1,'<=',127},[class(obj) '.' propName],propName);
    else
        % Check for row or matrix input
        error('InvalidScramInitValue of nist.edmgConfig.');
    end
    obj.(propName) = val;
  end

  function obj = set.TrainingLength(obj, val)
    propName = 'TrainingLength';
    % Training length must be a multiple of 4, <= 64, and >= 0
    validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',255},[class(obj) '.' propName],propName);
%     coder.internal.errorIf(mod(val,4)~=0,'nist:edmgConfig:InvalidTrainingLength');
    obj.(propName) = val;
  end


  function obj = set.SubfieldSeqLength(obj, val)
      propName = 'SubfieldSeqLength';
      % Training length must be a multiple of 4, <= 64, and >= 0
      validateattributes(val,{'numeric'},{'real','integer','scalar','>=',64,'<=',256},[class(obj) '.' propName],propName);
      assert(ismember(val,[64 128 256])==1,'nist:edmgConfig:SubfieldSeqLength should be defined as 64, 128 or 256');
      obj.(propName) = val;
  end

  function obj = set.UnitP(obj, val)
      propName = 'UnitP';
      validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',4},[class(obj) '.' propName],propName);
      assert(ismember(val,[0,1,2,4])==1,'nist:edmgConfig:SubfieldSeqLength should be defined as 0,1,2,4');
      obj.(propName) = val;
  end

  function obj = set.UnitM(obj, val)
      propName = 'UnitM';
      validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',16},[class(obj) '.' propName],propName);
      obj.(propName) = val;
  end

  function obj = set.UnitN(obj, val)
      propName = 'UnitN';
      validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',4},[class(obj) '.' propName],propName);
      assert(ismember(val,1:4)==1,'nist:edmgConfig:SubfieldSeqLength should be defined as 1,2,3 or 4');
      obj.(propName) = val;
  end

  function obj = set.UnitRxPerUnitTx(obj, val)
      propName = 'UnitRxPerUnitTx';
      validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',255},[class(obj) '.' propName],propName);
      obj.(propName) = val;
  end

  
  function obj = set.PacketType(obj,val)
    propName = 'PacketType';
    val = convertStringsToChars(val);
    validateEnumProperties(obj,propName,val);
    obj.(propName) = ''; 
    obj.(propName) = val;
  end
  
  function obj = set.TonePairingType(obj,val)
    propName = 'TonePairingType';
    val = convertStringsToChars(val);
    validateEnumProperties(obj,propName,val);
    obj.(propName) = ''; 
    obj.(propName) = val;
  end
  
  function obj = set.DTPIndicator(obj,val)
    propName = 'DTPIndicator';
    validateattributes(val,{'logical'},{'scalar'},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.Turnaround(obj,val)
    propName = 'Turnaround';
    validateattributes(val,{'logical'},{'scalar'},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.AggregatedMPDU(obj,val)
    propName = 'AggregatedMPDU';
    validateattributes(val,{'logical'},{'scalar'},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end  
  
  function obj = set.LastRSSI(obj,val)
    propName = 'LastRSSI';
    validateattributes(val,{'numeric'},{'real','integer','scalar','>=',0,'<=',15},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end  
  
  function obj = set.BeamTrackingRequest(obj,val)
    propName = 'BeamTrackingRequest';
    validateattributes(val,{'logical'},{'scalar'},[class(obj) '.' propName],propName);
    obj.(propName) = val;
  end  
  
  function obj = set.DTPGroupPairIndex(obj,val)
    propName = 'DTPGroupPairIndex';
    validateattributes(val,{'numeric'},{'real','integer','column','>=',0,'<=',41,'size',[42 1]},[class(obj) '.' propName],propName);
    % Ensure all indices are accounted for (0:41)
    coder.internal.errorIf(~isempty(setdiff(0:41,sort(val))),'nist:edmgConfig:InvalidDTPGroupPairIndex');
    obj.(propName) = val;
  end  
  
%%   Add for EDMG
  function obj = set.PHYType(obj,val)
    propName = 'PHYType';
    val = convertStringsToChars(val);
    validateEnumProperties(obj, propName, val);
    obj.(propName) = ''; 
    obj.(propName) = val;
  end

%   function obj = set.ChannelBandwidth(obj,val)
%     propName = 'ChannelBandwidth';
%     val = convertStringsToChars(val);
%     validateEnumProperties(obj, propName, val);
%     obj.(propName) = ''; 
%     obj.(propName) = val;
%   end

  function obj = set.NumUsers(obj, val)
    propName = 'NumUsers';
    validateattributes(val, {'numeric'}, {'real','integer','scalar','>=',1,'<=',8}, [class(obj) '.' propName], propName); 
    obj.(propName)= val;
  end

%   function obj = set.UserPositions(obj, val)
%     propName = 'UserPositions';
%     validateattributes(val, {'numeric'}, {'real','integer','row','>=',0,'<=',3,'increasing'}, [class(obj) '.' propName], propName);
%     obj.(propName) = val;                
%   end

  function obj = set.NumTransmitAntennas(obj, val)
    propName = 'NumTransmitAntennas';
    validateattributes(val, {'numeric'}, {'real','integer','scalar','>=',1,'<=',8}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end

  function obj = set.NumSpaceTimeStreams(obj, val)
    propName = 'NumSpaceTimeStreams';
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',1,'<=',8}, [class(obj) '.' propName], propName);
    coder.internal.errorIf(~isscalar(val) && ((length(val) > 8) || any(val > 8) || sum(val) > 8), 'wlan:shared:InvalidMUSTS', 8, 8, 8); 
    obj.(propName) = val;
  end

  function obj = set.SpatialMappingType(obj, val)
    propName = 'SpatialMappingType';
    val = convertStringsToChars(val);
%     validateEnumProperties(obj, propName, val);
    obj.(propName) = ''; 
    obj.(propName) = val;
  end

  function obj = set.SpatialMappingMatrix(obj, val)
    propName = 'SpatialMappingMatrix';
%     validateattributes(val, {'double'}, {'3d','finite','nonempty'}, [class(obj) '.' propName], propName); 

%     is3DFormat = (ndims(val) == 3) || (iscolumn(val) && ~isscalar(val));
%     numSTS = size(val, 1+is3DFormat);
%     numTx  = size(val, 2+is3DFormat);
%     numST = [56 114 242 484]; % Total number of occupied subcarriers
%     coder.internal.errorIf((is3DFormat && ~any(size(val, 1) == numST)) || (numSTS > 8) || (numTx > 8) || (numSTS > numTx), ...
%         'wlan:shared:InvalidSpatialMapMtxDim', 8, '56, 114, 242 or 484');
    obj.(propName) = val;
  end
  
  function obj = set.Beamforming(obj, val)
    propName = 'Beamforming';
    validateattributes(val, {'logical'}, {'scalar'}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end

  function obj = set.STBC(obj, val)
    propName = 'STBC';
    validateattributes(val, {'logical'}, {'scalar'}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end
  
  function obj = set.GuardIntervalType(obj, val)
    propName = 'GuardIntervalType';
    val = convertStringsToChars(val);
    validateEnumProperties(obj, propName, val);
    obj.(propName) = ''; 
    obj.(propName) = val;
  end
  
  % End 
  
  %%
  function type = phyType(obj)
    %phyType Get EDMG PHY modulation type
    %   Returns the EDMG PHY modulation method as a character vector, based
    %   on the current configuration. PHY type is one of 'Control', 'SC' or
    %   'OFDM'.
    if strcmp(obj.PHYType,'Control')
        type = 'Control';
    elseif strcmp(obj.PHYType,'SC')
        type = 'SC';
    elseif strcmp(obj.PHYType,'OFDM')
        type = 'OFDM';
    else
        error('PHY type should be one of Control, SC or OFDM.');
    end
  end
  
  function varargout = validateConfig(obj,varargin)
    % validateConfig Validate the wlanDMGConfig object
    %   validateConfig(CFGDMG) validates the dependent properties for the
    %   specified wlanDMGConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes.
    %
    %   validateConfig(CFGDMG,MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'Scrambler' - validates scrambler initialization
    %       'Length' - validates PSDULength for MCS0, and TXTIME
    %       'Full' - validates all above
    
    narginchk(1,2);
    nargoutchk(0,1);
    if (nargin==2)
        mode = varargin{1};
    else
        mode = 'Full';
    end

    switch mode
        case 'Scrambler'
            % Validate scrambler initialization
            validateScramblerInitialization(obj);
            
        case 'Length'
            % Validate PSDULength and TXTIME, and return waveform information
            s = validateMCSLength(obj);
            
        otherwise
            % Validate full object and return waveform information
            validateScramblerInitialization(obj);
            s = validateMCSLength(obj);
    end
    
    if nargout==1
        varargout{1} = s;
    end
  end    
end   

methods (Access = protected)
  function flag = isInactiveProperty(obj, prop)
    flag = false;
    if strcmp(prop,'TonePairingType')
        % Hide DTP related properties unless configuration is OFDM SQPSK or
        % QPSK
        flag = ~(obj.MCS>=13 & obj.MCS<=17);
    elseif any(strcmp(prop,{'DTPIndicator','DTPGroupPairIndex'}))
        % Hide DTPIndicator and DTPGroupPairIndex if dynamic tone mapping
        % is not used or the modulation scheme is not OFDM SQPSK or QPSK
        flag = ~(obj.MCS>=13 & obj.MCS<=17) | ~strcmp(obj.TonePairingType,'Dynamic');
    elseif any(strcmp(prop,{'PacketType'}))
        % Hide PacketType when TrainingLength is 0
        flag = obj.TrainingLength==0;
    elseif any(strcmp(prop,{'AggregatedMPDU','LastRSSI'}))
        % Hide AggregatedMPDU and LastRSSI for control PHY
        flag = strcmp(phyType(obj),'Control');   % isControlConfig(obj);
    elseif strcmp(prop,'BeamTrackingRequest')
        % Hide BeamTrackingRequest for control PHY of when TrainingLength
        % is 0
%         flag = isControlConfig(obj) | obj.TrainingLength==0;
        flag = strcmp(phyType(obj),'Control')  | obj.TrainingLength==0;
    end
  end
end

methods (Access = private)
  function s = privInfo(obj)
    %privInfo Returns information relevant to the object
    %   S = privInfo(CFGDMG) returns a structure, S, containing the
    %   relevant information for the wlanDMGConfig object, CFGDMG.
    %   The output structure S has the following fields:
    %
    %   TxTime         - The time in microseconds, required to
    %                    transmit the PPDU.

    % Calculate number of OFDM symbols
    txTime = plmeTXTIMEPrimitive(obj); % microseconds    
    [info,~] = edmgPHYInfoCharacteristics(obj);
    
    if strcmp(phyType(obj),'OFDM')  % isOFDMConfig(obj)
        numPPDUSamples = ceil(txTime/(info.TS*1e6));
    else % SC or control
        numPPDUSamples = ceil(txTime/(info.TC*1e6));
    end

    s = struct(...
        'NumPPDUSamples', numPPDUSamples, ...
        'TxTime',         txTime, ...
        'PSDULength',     obj.PSDULength); 
  end
  
  function s = validateMCSLength(obj)
    %ValidateMCSLength Validate MCS and Length properties for
    %   wlanDMGConfig configuration object
    s = privInfo(obj);
    
    % Validate PSDULength is between 14 and 1023, inclusive, for control PHY
%     coder.internal.errorIf(isControlConfig(obj)&&(obj.PSDULength<14||obj.PSDULength>1023),'nist:edmgConfig:InvalidPSDULength')
    coder.internal.errorIf(strcmp(phyType(obj),'Control')&&(obj.PSDULength<14||obj.PSDULength>1023),'nist:edmgConfig:InvalidPSDULength')
    
    % Validate txTime
    aPPDUMaxTime = 2e3; % Max microseconds, aPPDUMaxTime, Table 21-31
    coder.internal.errorIf(s.TxTime>aPPDUMaxTime,'wlan:shared:InvalidPPDUDuration',round(s.TxTime),aPPDUMaxTime);
  end
  
  function validateScramblerInitialization(obj)
    if strcmp(phyType(obj),'Control')   % isControlConfig(obj)
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<1) | (obj.ScramblerInitialization>15)), ...
                'nist:edmgConfig:InvalidScramblerInitialization','Control',1,15,4);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=4) ...
                || all(obj.ScramblerInitialization==0) || (size(obj.ScramblerInitialization,1)~=4), ...
                'nist:edmgConfig:InvalidScramblerInitialization','Control',1,15,4);
        end
    % Add 11ad-extend
    elseif wlan.internal.isDMGExtendedMCS(obj.MCS)
        % At least one of the initialization bits must be non-zero,
        % therefore determine if the pseudorandom part can be 0 given the
        % extended MCS and PSDU length.
        if all(wlan.internal.dmgExtendedMCSScramblerBits(obj)==0)
            minScramblerInit = 1; % Pseudorandom bits cannot be all zero
        else
            minScramblerInit = 0; % Pseudorandom bits can be all zero
        end
        
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<minScramblerInit) | (obj.ScramblerInitialization>31)), ...
                'nist:edmgConfig:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31,5);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=5) ...
                || (minScramblerInit&&all(obj.ScramblerInitialization==0)) || (size(obj.ScramblerInitialization,1)~=5), ...
                'nist:edmgConfig:InvalidScramblerInitialization','SC extended MCS',minScramblerInit,31,5);
        end
    else
        if isscalar(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any((obj.ScramblerInitialization<1) | (obj.ScramblerInitialization>127)), ...
                'nist:edmgConfig:InvalidScramblerInitialization','SC/OFDM',1,127,7);
        elseif isrow(obj.ScramblerInitialization)
            % Check for correct range
            coder.internal.errorIf(any(any(obj.ScramblerInitialization<1) | any(obj.ScramblerInitialization>127)), ...
                'nist:edmgConfig:InvalidScramblerInitialization','SC/OFDM',1,127,7);
        else
            % Check for non-zero binary vector
            coder.internal.errorIf( ...
                any((obj.ScramblerInitialization~=0) & (obj.ScramblerInitialization~=1)) || (numel(obj.ScramblerInitialization)~=7) ...
                || all(obj.ScramblerInitialization==0) || (size(obj.ScramblerInitialization,1)~=7), ...
                'nist:edmgConfig:InvalidScramblerInitialization','SC/OFDM',1,127,7);
        end
    end 
  end
  
  % TXTIME calculation in Section 21.12.3 IEEE 802.11ad-2012
  %   TXTIME is the transmission time in microseconds
  function TXTIME = plmeTXTIMEPrimitive(obj)
    
    [phyInfo,phyChara] = edmgPHYInfoCharacteristics(obj);
    TC = phyInfo.TC;
    FS = phyInfo.FS;
    
    TSEQ = 128*TC; % 72.7 nanoseconds, Table 21-4
    Length = obj.PSDULength;
    if wlan.internal.isBRPPacket(obj)
        NTRN = obj.TrainingLength/4;  % Training field length defined in header, assume number of groups of 4
    else
        NTRN = 0;
    end
    TTRN_Unit = 4992*TC;     % aBRPTRNBlock*TC, Table 21-31
    NUM_USERS = obj.NumUsers;

    if strcmp(phyType(obj),'Control')   % isControlConfig(obj)
        TSTF_CP = 50*TSEQ; % Control PHY short training field duration, 3.636 microseconds, Table 21-4
        TCE_CP = 9*TSEQ;   % Control PHY channel estimation field duration, 655 nanoseconds, Table 21-4
        LL_HEADER = 5;
        LEDMG_HEADER_A = 9;
        LEDMG_HEADER_A2 = 3;

        NCW = 1 + ceil((Length + LEDMG_HEADER_A2)*8/168);
        THEADERS = ((Length + LL_HEADER +LEDMG_HEADER_A)*8 + 168*NCW)*TC*32;
        TXTIME = TSTF_CP+TCE_CP+THEADERS+NTRN*TTRN_Unit;
    else
        TL_STF = 17*TSEQ; % SC/OFDM PHY short training field duration, 1236 nanoseconds, Table 21-4
        TL_CE = 9*TSEQ;   % SC/OFDM PHY channel estimation field duration, 655 nanoseconds, Table 21-4
                
        % IEEE Std. 802.11-2016, Table 20-31
        alpha = phyChara.aBRPminSCblocks;
        beta = phyChara.aSCBlockSize;
        gamma = phyChara.aSCGILength;
        delta = phyChara.aBRPminOFDMblocks;
        
        % Get guard interval information
        [NGI,TGI] = edmgGIInfo(obj);
       
        if strcmp(phyType(obj),'SC')   % isSCConfig(obj)
            TL_Header = 1024*TC; % Header duration, 0.582e3 Nanoseconds , Table 21-4

            % SC PHY
            info = edmgSCInfo(obj);
            
            % Get maximum number of SC symbol blocks over all users
            NBLKS = getMaxNumberBlocks(obj);
            
            if NUM_USERS==1
                TEDMG_HEADER_A = 1024*TC;
                TEDMG_STF = 0;
                TEDMG_CEF = 0;
                TEDMG_HEADER_B = 0;

            elseif NUM_USERS>1
                TEDMG_HEADER_A = 1088*TC;
                TEDMG_STF = 2432*TC;
                [~, N_EDMG_CEF]  =  edmgCEConfig(obj);
                TEDMG_CEF = (1152+1280*(N_EDMG_CEF-1))*TC;
                TEDMG_HEADER_B = 512*TC;

            end
            
            TData = (NBLKS*info.NFFT+NGI)*TC;
            
            if NTRN>0
%                 TXTIME = TSTF+TCE+Theader+max(TData,(alpha*beta+gamma)*TC)+NTRN*TTRN_Unit;
                TTRN = NTRN*TTRN_Unit;
            else
%                 TXTIME = TSTF+TCE+Theader+TData;
                TTRN = 0;
            end
            
            TXTIME = TL_STF +  TL_CE + TL_Header + TEDMG_HEADER_A + ...
                TEDMG_STF + TEDMG_CEF + TEDMG_HEADER_B + TData+  TTRN;
        else
            % OFDM PHY
            info = nist.edmgOFDMInfo(obj);
            TDFT = info.NFFT/FS;
            TSYM = TDFT+TGI; % Symbol duration, 0.242e3 nanoseconds, Table 21-4
            TL_Header = TSYM;  % Header duration, 0.242e3 nanoseconds (Tsym), Table 21-4

            TEDMG_HEADER_A = 1088*TC;
            TEDMG_STF = 3840/FS;
            [~, N_EDMG_CEF]  =  edmgCEConfig(obj);
            TEDMG_CEF = 704*N_EDMG_CEF/FS;
           
            if NUM_USERS==1
                TEDMG_HEADER_B = 0;
            elseif NUM_USERS>1
                TEDMG_HEADER_B = (info.NFFT + NGI)/FS;
            end
            
            % Get maximum number of OFDM symbols over all users
            NSYMS = getMaxNumberBlocks(obj);
            
            TData = NSYMS*TSYM;
            
            if NTRN>0
%                 TXTIME = TSTF+TCE+Theader+max(TData,delta*TSYM)+NTRN*TTRN_Unit;
                TTRN = NTRN*TTRN_Unit;
            else
%                 TXTIME = TSTF+TCE+Theader+TData;
                TTRN = 0;
            end
            
            TXTIME = TL_STF +  TL_CE + TL_Header + TEDMG_HEADER_A + ...
                TEDMG_STF + TEDMG_CEF + TEDMG_HEADER_B + TData+  TTRN;
        end
    end
    
    TXTIME = TXTIME*1e6; % Convert seconds to microseconds
  end
  
end

end