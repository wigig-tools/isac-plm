function [rda, info, results, estimation] = readIsacPlmOutput(pathScenario)
% READISACPLMOUTPUT Read ISAC PLM JSON output
%
%   [RDA, I, R, E] = READISACPLMOUTPUT(P) 
%   Load the JSON files in the folder P/Output/sensing and return the
%   structure obtained from the JSON files:
%   RDA: rda.json
%   I : sensingInfo.json
%   R : sensingResults.json
%   E : targetEstimationg.json
%
%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

dirPathChan = fullfile(pathScenario,'Output/sensing');

%% RDA
fid = fopen(fullfile(dirPathChan,'rda.json'));
if ~fid
    rda = [];
    warning('Error reading rda.json')
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
if ~fid
    info = [];
    warning('Error reading sensingInfo.json')
else

    Nlines = 1;
    info = struct('axVelocity', cell(1,Nlines), ...
        'axFastTime', cell(1,Nlines), ...
        'timeOffset', cell(1,Nlines), ...
        'axDopFftTime', cell(1,Nlines), ...
        'axPri', cell(1,Nlines), ...
        'axAngle', cell(1,Nlines),...
        'gtRange', cell(1,Nlines),...
        'gtVelocity', cell(1,Nlines),...
        'gtAz', cell(1,Nlines),...
        'gtEl', cell(1,Nlines)...
        );

    while ~feof(fid)
        tline = fgetl(fid);
        if Nlines ==1 && ~contains(tline,'gtAz')
            info = rmfield(info, "gtAz");
            info = rmfield(info, "gtEl");
            info = rmfield(info, "axAngle");
        end
        info(Nlines) = jsondecode(tline);
        Nlines = Nlines+1;
    end

    fclose(fid);
end

%% sensingResults
fid = fopen(fullfile(dirPathChan,'sensingResults.json'));
if ~fid
    results = [];
    warning('Error reading sensingResults.json')
else

    Nlines = 1;
    results = struct('snr', cell(1,Nlines), ...
        'rangeNMSEdB', cell(1,Nlines), ...
        'velocityNMSEdB', cell(1,Nlines), ...
        'rangeMSEdB', cell(1,Nlines), ...
        'velocityMSEdB', cell(1,Nlines), ...
        'azErr', cell(1,Nlines),...
        'elErr', cell(1,Nlines) ...
        );

    while ~feof(fid)
        tline = fgetl(fid);
        if Nlines ==1 && ~contains(tline, 'azErr')
            results = rmfield(results, "azErr");
            results = rmfield(results, "elErr");
        end
        results(Nlines) = jsondecode(tline);
        Nlines = Nlines+1;
    end

    fclose(fid);
end

%% targetEstimation
fid = fopen(fullfile(dirPathChan,'targetEstimation.json'));
if ~fid
    estimation = [];
    warning('Error reading targetEstimation.json')
else

    Nlines = 1;
    estimation = struct('range', cell(1,Nlines), ...
        'velocity', cell(1,Nlines), ...
        'angleAz', cell(1,Nlines), ...
        'angleEl', cell(1,Nlines) ...
        );

    while ~feof(fid)
        tline = fgetl(fid);
        if Nlines ==1 && ~contains(tline,'angleAz')
            estimation = rmfield(estimation, "angleAz");
            estimation = rmfield(estimation, "angleEl");
        end
        estimation(Nlines) = jsondecode(tline);
        Nlines = Nlines+1;
    end

    fclose(fid);
end