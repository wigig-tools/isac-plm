function sv = getSteeringVectors(az, el, steeringAll)
%%GETSTEERINGVECTORS Steering Vectors
%
%   GETSTEERINGVECTORS(AZ, EL, SV) return the steering vectors relative to
%   the azimuth vector (Delay x 1) AZ and elevation (Delay x 1) EL. SV is
%   the steering vector library sampled at 1deg in azimuth and elevation
%   (dimension 361x181x2).
%

%   2022 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

if ~iscell(az)
    azId = round(az)+1;
    elId = round(el)+1;
    
    sv = steeringAll(azId,elId,:);
    svReshape=reshape(sv,1,numel(azId)*numel(elId),[]);
    sv=squeeze(svReshape(1,1:numel(azId)+1:end,:)).';
%     sv = shiftdim(reshape(sv, [], size(azId,1), size(azId,2)),1);
else
    n = length(az);
    svTime = cell(n,1);
    azId =cellfun(@(x) round(x)+1, az, 'UniformOutput', false);
    elId =cellfun(@(x) round(x)+1, el, 'UniformOutput', false);
    for i = 1:n
            sv = steeringAll(azId{i},elId{i},:);
            svReshape=reshape(sv,1,numel(azId{i})*numel(elId{i}),[]);
            sv=squeeze(svReshape(1,1:numel(azId{i})+1:end,:)).';
            svTime{i} = shiftdim(reshape(sv, [], size(azId{i},1), size(azId{i},2)),1);
    end    
    sv = svTime;
end
end