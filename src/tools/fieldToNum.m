function params = fieldToNum(params, field, validValues, varargin)
% INPUTS:
% - para: structure to convert numeric fields in-place
% - field: field name of the target numeric field
% - validValues: set of valid numerical values on which assert is done
% - defaultValue: if field not found, set value to this default
% OUTPUT: para, in-place update

%   2019~2021 NIST/CTL Steve Blandino

%   This file is available under the terms of the NIST License.

%#codegen

p = inputParser;
addParameter(p, 'defaultValue', [])
addParameter(p, 'step', 0)
parse(p, varargin{:});
defaultValue = p.Results.defaultValue;
step = p.Results.step;

if isfield(params, field)
    if ~isnan(str2double(params.(field)))
        params.(field) = str2double(params.(field));
    else
        if ~isempty(str2num(params.(field))) %#ok<ST2NM>
            params.(field) =  str2num(params.(field)); %#ok<ST2NM>
        end
    end
else
    params.(field) = defaultValue;
end

if ~isempty(validValues)    
    if step == 0
        assert(all(ismember(params.(field), validValues)),...
            ['Invalid value ', num2str(params.(field)), ' for field ', field])
    else
        if step == eps %continue values
            printValue = params.(field);
            if ismatrix(printValue)
                printValue= printValue(:).';
            end
            assert(all(all(params.(field)>=validValues(1))) && all(all(params.(field)<=validValues(2))),...
                ['Invalid value ', num2str(printValue), ' for field ', field])
        else %Discrete window
            assert(all(ismember(params.(field), validValues(1):step:validValues(2))),...
                ['Invalid value ', num2str(params.(field)), ' for field ', field])
        end
    end
end
end