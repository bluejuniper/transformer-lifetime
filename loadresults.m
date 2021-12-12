results_dir = 'C:\Users\305232\OUO\GmdConsequences\wecc_apr_2019_20hs3ap_pwver21_draft7_nw_wa_gic_blake_20031120_3d';
results_files = dir(results_dir);

nt = length(results_files)

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

% rate_a = zeros([nb 1]);
% s_fr = zeros([nb 1]);

xfs = [];
xf_ids = zeros([1 nb]);

for i = 1:nb
    br_name = branch_keys{i};
    br = branch_struct.(br_name);

    if isfield(br,'type') && strcmp(br.type,'xf')
        fprintf('Adding branch %s %d/%d\n',br_name,i,nb)
    
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

xf_ids = sparse(xf_ids);
nx = length(xfs);

rate_a = zeros([nt nx]);
s_fr = zeros([nt nx]);

for i = 1:nx
    rate_a(i) = xfs.rate_a;
end

xf_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/xf_data.mat';

fprintf('Start saving...\n')
save(xf_file,'xfs','rate_a')
fprintf('Done saving\n')

%% Read results data
data = [];

for i = 1:10
    fname = sprintf('%s\\movie_%d.json', results_dir, i);
    fprintf('Reading %d/%d\n',i,nt);
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);
    
    data = [data val];

    branches = val.result.solution.branch;

    for j = 1:length(xf_ids)
        xf_key = sprintf('x%d',xf_ids(j));

        if isfield(branches,xf_key)
            xf = branches.(xf_key);
            s_fr(i,j) = sqrt(xf.pf^2 + xf.qf^2);
        end
    end
end

%% Save data
xf_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/xf_data.mat';
data_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/data.mat';

fprintf('Start saving...\n')
save(data_file,'data')
fprintf('Done saving\n')