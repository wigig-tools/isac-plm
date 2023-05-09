function [rda, info, results, estimation, csi] = readIsacPlmOutput(pathScenario)
% READISACPLMOUTPUT Read ISAC PLM JSON output
%
%   [RDA, I, R, E, C] = READISACPLMOUTPUT(P)
%   Load the JSON files in the folder P/Output/sensing and return the
%   structure obtained from the JSON files:
%   RDA: rda.json
%   I : sensingInfo.json
%   R : sensingResults.json
%   E : targetEstimationg.json
%   C  : csi.json
%
%   2022-2023 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

dirPathChan = fullfile(pathScenario,'Output/sensing');

%% RDA
fid = fopen(fullfile(dirPathChan,'rda.json'));
if fid<0
    rda = [];
    disp(['[', 8, 'Warning: rda.json not available]', 8])

else

    Nlines = 1;
    rda = struct('snr', cell(1,Nlines), ...
        'sensInstanceId', cell(1,Nlines), ...
        'axisRange', cell(1,Nlines), ...
        'axisVelocity', cell(1,Nlines), ...
        'axisAngle', cell(1,Nlines), ...
        'reflectionPower', cell(1,Nlines)...
        );

    while ~feof(fid)
        tline = fgetl(fid);
        rda(Nlines) = jsondecode(tline);
        Nlines = Nlines+1;
    end

    fclose(fid);
end
%% sensingInfo
fid = fopen(fullfile(dirPathChan,'sensingInfo.json'));
if fid<0
    info = [];
    disp(['[', 8, 'Warning: sensingInfo.json not available]', 8])

else
    Nlines = 1;
    while ~feof(fid)
        tline = fgetl(fid);
        info(Nlines) = jsondecode(tline); %#ok<AGROW>
        Nlines = Nlines+1;
    end

    fclose(fid);
end

%% sensingResults
fid = fopen(fullfile(dirPathChan,'sensingResults.json'));
if fid<0
    results = [];
    disp(['[', 8, 'Warning: sensingResults.json not available]', 8])
else

    Nlines = 1;
    while ~feof(fid)
        tline = fgetl(fid);
        results(Nlines) = jsondecode(tline); %#ok<AGROW>
        Nlines = Nlines+1;
    end

    fclose(fid);
end

%% targetEstimation
fid = fopen(fullfile(dirPathChan,'targetEstimation.json'));
if fid<0
    estimation = [];
    disp(['[', 8, 'Warning: targetEstimation.json not available]', 8])
else

    Nlines = 1;
    while ~feof(fid)
        tline = fgetl(fid);
        estimation(Nlines) = jsondecode(tline); %#ok<AGROW>
        Nlines = Nlines+1;
    end

    fclose(fid);
end

%% csi
fid = fopen(fullfile(dirPathChan,'csi.json'));
if fid<0
    csi = [];
    disp(['[', 8, 'Warning: csi.json not available]', 8])
else
    Nlines = 1;

    while ~feof(fid)
        tline = fgetl(fid);
        csi(Nlines) = jsondecode(tline); %#ok<AGROW>
        Nlines = Nlines+1;
    end
end