%% housekeeping
clear; clc

options.vary_offset = true;

heating_file = 'C:/Users/305232/OUO/gmd-cascade/data/xf_heating/heating_data.mat';
load(heating_file)

Ka = 25;
t0 = t(1:10)/60; % use time in minutes
[t,ia] = unique(t0);


tau_e = 71/60; % winding time constant in hours
delta_er = 75;
L0 = s_fr_norm(1:10,1);
L = L0(ia);

%% ode parameters
Dt = mean(diff(t));

Ko0 = 20; % initial oil temperature rise
y0 = [Ko0];


odeparams = struct;
odeparams.tau_e = tau_e;
odeparams.delta_er = delta_er;


odeparams.Ka = Ka;
odeparams.ke = L;
odeparams.t = t;


%% calculations
Kw = zeros(1,length(t));

mylpt = @(t,y) lpt(t,y,odeparams);
odeset('RelTol',1e-2,'AbsTol',[1e-4 1e-4 1e-5]);
[ts,y] = ode23(mylpt,[min(t) max(t)],y0,options);  
Ko = interp1(ts,y,t);

% calculate the lifetime
Koss = Ko(25:end);
Dt_ = diff(t(24:end));

Faa = exp(15e3/368 - 15e3./(273 + Koss));
Feqa = sum(Faa.*Dt_)/sum(Dt_);

Y = 22/Feqa;
fprintf('Lifetime (years): %6.2f\n',Y);
 

%%
figure(1)

subplot 311
plot(t,Ko)
ylabel('Top-oil (C)')
grid on

subplot 312 
plot(t,Ka,'r')
ylabel('Ambient (C)')
grid on

subplot 313
plot(t,L,'k')
ylabel('Load Power')
grid on


