clear; clc;

xf_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/xf_data.mat';
fprintf('Start loading xfs...\n')
load(xf_file)
fprintf('Done\n')


%% Save data
heating_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/heating_data.mat';

fprintf('Start loading heating data...\n')
load(heating_file)
% save('-nocompression',data_file,'data')
fprintf('Done\n')