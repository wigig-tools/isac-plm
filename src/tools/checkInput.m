function userConfig = checkInput(userConfig, expectedConfig, msg)
%checkInput
% Inputs
%   userConfig is the configurated variable to be checked
%   expectedConfig is the expected configuration in either single or multiple elements.
%   msg is the message
% Output
%   userConfig is the updated configuration

%   2019~2021 NIST/CTL Steve Blandino, Jiayi Zhang

%   This file is available under the terms of the NIST License.

%#codegen

if numel(expectedConfig) > 1
    if ~ismember(userConfig, expectedConfig)
        if iscell(expectedConfig)
            userConfig = expectedConfig{1};
            defaultConfig = expectedConfig{1};
        else
            userConfig = expectedConfig(1);
            defaultConfig = expectedConfig(1);
        end
        if isempty(msg)
            msg = 'Error in config. Set default value';
        end
        warning( [msg ': %d'], defaultConfig);
    end
else
    if ~isequal(userConfig, expectedConfig)
        userConfig = expectedConfig;
        defaultConfig = expectedConfig;
        if isempty(msg)
            msg = 'Error in config. Set default value';
        end
        warning( [msg ': %d.\n'], defaultConfig);
    end
end
    
end