base_dir = 'C:\Users\305232\Results\gmd_cascade_results';
scenario = 'wecc_apr_2019_20hs3ap_pwver21_draft7_nw_wa_gic_blake_20031120_3d';
results_dir = sprintf('%s\\%s', base_dir, scenario);
results_glob = sprintf('%s\\%s\\*.json', base_dir, scenario);
results_files = dir(results_glob);

nt = length(results_files);

% read in the inital file
fname = sprintf('%s\\movie_1.json', results_dir);
fprintf('Reading inital frame\n');
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);
branch_struct = val.net.branch;
branch_keys = fields(branch_struct);
nb = length(branch_keys)

xfs = [];
xf_ids = zeros([1 nb]);

for i = 1:nb
    br_name = branch_keys{i};
    br = branch_struct.(br_name);

    if isfield(br,'type') && strcmp(br.type,'xf')
        fprintf('Adding branch %s %d\\%d\n',br_name,i,nb);
    
        xf = struct();
        xf.index = br.index;
        xf.f_bus = br.f_bus;
        xf.t_bus = br.t_bus;
        xf.ckt = br.ckt;
        xf.rate_a = br.rate_a;      
        xf.sub_id = br.sub_id;
        xfs = [xfs xf];
        xf_ids(i) = xf.index;
    end
end

fprintf('\n');

xf_ids = xf_ids(xf_ids ~= 0);
nx = length(xfs);

t = zeros([1 nt]);
rate_a = zeros([1 nx]);
s_fr = zeros([nt nx]);
ieff = zeros([nt nx]);

for i = 1:nx
    rate_a(i) = xfs(i).rate_a;
end

% xf_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/xf_data.mat';
% fprintf('Start saving...\n')
% save('-nocompression',xf_file,'xfs','rate_a')
% fprintf('Done saving\n')

%% Read results data
% for i = 1:nt
for i = 1:5
    fname = sprintf('%s\\movie_%d.json', results_dir, i);
    fprintf('Reading %d/%d\n',i,nt);
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);
    t(i) = val.t;
    
    oname = replace(fname,'.json','.mat');
    fprintf('Saving to %s\n\n',oname);
    save('-nocompression',oname,'val');

    branches = val.net.branch;
    sbranches = val.result.solution.branch;

    for j = 1:length(xf_ids)
        xf_key = sprintf('x%d',xf_ids(j));

        if isfield(branches,xf_key)
            xf = branches.(xf_key);

            if isfield(xf,'ieff')
                ieff(i,j) = xf.ieff;
            end
        end

        if isfield(sbranches,xf_key)
            xf = sbranches.(xf_key);
            s_fr(i,j) = sqrt(xf.pf^2 + xf.qf^2);
        end
    end
end

%% Save data
s_fr_norm = zeros(size(s_fr));

for i = 1:nx
    s_fr_norm(:,i) = s_fr(:,i)/rate_a(i);
end

% heating_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/heating_data.mat';
% fprintf('Start saving...\n')
% save('-nocompression',heating_file,'xfs','rate_a','s_fr','s_fr_norm','t')
% fprintf('Done saving\n')