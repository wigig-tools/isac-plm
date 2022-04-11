function paaInfo = loadCodebook(paaInfo, varargin)
%LOADCODEBOOK Load antenna codebook.
%
%   P = LOADCODEBOOK(Pin) return the PAA information in the struct P

%   P = GENERATECODEBOOK(.., 'codebookName', value, ...) specify codebook
%   file

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%% Varargin processing
p = inputParser;
addParameter(p,'codebookName',[])

parse(p, varargin{:});
codebookName = p.Results.codebookName;

%% Dependent params
azimuthCount = 361;
nodes = length(paaInfo);

for idNode = 1:nodes
    arraySize = [ paaInfo(idNode).NumAntennaVert paaInfo(idNode).NumAntennaHor];

    if isempty(codebookName)
        codebookName = sprintf('cbH%dV%d.txt', arraySize);
    end

    fileID = fopen(codebookName);

    output.numRFChains = str2double(fgetl(fileID));
    output.numAntennas = str2double(fgetl(fileID));
    for rfID = 1:output.numRFChains
        for antennaID = 1: output.numAntennas
            output(rfID,antennaID).antennaID = str2double(fgetl(fileID));
            output(rfID,antennaID).rfID  = str2double(fgetl(fileID));
            output(rfID,antennaID).azimuthOrientationDegree = str2double(fgetl(fileID));
            output(rfID,antennaID).elevationOrientationDegree = str2double(fgetl(fileID));
            output(rfID,antennaID).numElements = str2double(fgetl(fileID));
            output(rfID,antennaID).elementsPosition = reshape(str2num(fgetl(fileID)),3,[]); %#ok<ST2NM>
            output(rfID,antennaID).phaseQuantizationBits =  str2double(fgetl(fileID));
            output(rfID,antennaID).ampQuantizationBits =  str2double(fgetl(fileID));
            for i = 1:azimuthCount
                output(rfID,antennaID).elementDirectivity(i,:) = str2num(fgetl(fileID)); %#ok<ST2NM>
            end
            for ant = 1:output(rfID,antennaID).numElements
                for i = 1:azimuthCount
                    complexSplit = str2num(fgetl(fileID));%#ok<ST2NM>
                    amplitude = complexSplit(1:2:end);
                    phase = complexSplit(2:2:end);
                    output(rfID,antennaID).sv_3d(i,:, ant) = amplitude.*(cos(phase) +1j*sin(phase));
                end
            end
            output(rfID,antennaID).quasiAWV = str2num(fgetl(fileID));
            output(rfID,antennaID).numSectors= str2double(fgetl(fileID));

            for sectorId = 1: output.numSectors
                output(rfID,antennaID).sectorID(sectorId) = str2double(fgetl(fileID));
                output(rfID,antennaID).SectorType(sectorId) = str2double(fgetl(fileID));
                output(rfID,antennaID).SectorUsage(sectorId)= str2double(fgetl(fileID));
                az(sectorId) = str2double(fgetl(fileID));
                elev(sectorId) = str2double(fgetl(fileID));
                complexSplit = str2num(fgetl(fileID));
                amplitude = complexSplit(1:2:end);
                phase = complexSplit(2:2:end);
                output(rfID,antennaID).weightingVector(:,sectorId)= amplitude.*(cos(phase) +1j*sin(phase));
            end
            output(rfID,antennaID).steeringAngle = [az(:), elev(:)];
        end
    end
    paaInfo(idNode).codebook = output;

end
fclose(fileID);
end