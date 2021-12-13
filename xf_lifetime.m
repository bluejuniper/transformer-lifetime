%% housekeeping
clear; clc; clf; hold on

options.vary_offset = true;



% load the ambient temperature data
% M = xlsread('Phoenix Temperature Dec 4 2011 to Dec 4 2012.xlsx');
M = readmatrix('phoenix_termperature_4_weeks_4_seasons.csv');
t = (1:size(M,1)); % time in hours

% Ka = M(:,end)' - 20; % temperature in C
Ka = M(:,end-1)';

th = mod(t,24);

% load the load profile data
M = readmatrix('ev_transformer_load.csv');
tl = M(2:end,1);
L = M(2:end,2); % EV
L = L/max(L);
L = interp1(tl,L,0:23,'pchip','extrap');
L = repmat(L,1,32);


tau_e = 71/60; % winding time constant in hours
delta_er = 75;


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


