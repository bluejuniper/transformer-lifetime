%% housekeeping
clear; clc; clf; hold on

options.vary_offset = true;

%% transformer parameters
Pr = 25; % rating in kVA
Ptnl = 118; % total losses at no-load
Ptr = 437; % total losses at rated power
F = Ptr/Ptnl;

% specific heat of midel at 80 C: 2023 J/(kg*K)
% volumetric density of midel at 80 C: 926 kg/m^3
% volume of 50 kVA xf: 33 gal
% volume of 25 kVA xf: 18 gal
% adjustment factor for top-oil temp (rather than avg temp): 0.86
% 1 Wh = 3600 J
% 1 m^3 = 264 gal
% Vo_gal = 18;
% Vo_gal = 85;
Vo_gal = 18;
gal_per_m3 = 264;
midel_kg_per_m3 = 926;
mo_kg = Vo_gal * (1/gal_per_m3) * (midel_kg_per_m3);

co_J_per_kg = 2023;
J_per_Wh = 3600;
co_Wh_per_kg = co_J_per_kg/J_per_Wh;

Co = mo_kg * co_J_per_kg * (1/J_per_Wh) * 0.86;

liters_per_gal = 3.785;
Vo_liters = Vo_gal*liters_per_gal;

phasechange_kg_per_m3 = 800;

% weight of a dry-type 50 kVA xf: 178 kg
% weight of a dry-type 25 kVA xf: 134 kg
% thermal capacity per kg: (0.0272 + 0.01814)/2
Cx = 3.038; % heat capacity of tank, fittings, core and coil in Wh/K

DKoar = 38.3; % top-oil temperature rise at rated load in K
DKwor = 20.3; % hot-spot-to top-oil gradient at rated current in K
% DKwor = 10;

%% phase-change material parameters
% offset = 3;
% offset_range = [0 10 20];
offset_range = 0:3:24;
offset_range = [0 15];


cp1 = 7.78; % W*min/Kg*K or 28,000 J/Kg*K
cp2 = 0.56; % W*min*Kg/KpK 2,000 J/Kg*K

% load the ambient temperature data
% M = xlsread('Phoenix Temperature Dec 4 2011 to Dec 4 2012.xlsx');
M = readmatrix('phoenix_termperature_4_weeks_4_seasons.csv');
t = (1:size(M,1)); % time in hours

% Ka = M(:,end)' - 20; % temperature in C
Ka = M(:,end-1)';

th = mod(t,24);

% if options.vary_offset
%     Ka = 30*ones(size(Ka));
% end

% load the load profile data
M = readmatrix('ev_transformer_load.csv');
tl = M(2:end,1);
L = M(2:end,2); % EV
L = L/max(L);
L = interp1(tl,L,0:23,'pchip','extrap');
L = repmat(L,1,32);
% L = 1.25*L(:);
% L = 1.2*L(:);
L = 1.3*L(:);
% L = 1.33*L(:);

% if options.vary_offset
%     L = 1.4*ones(size(L));
% end
% L(t >= 10 & t < 20) = 0;
% L(t >= 30 & t < 40) = 0;
% L(t >= 50 & t < 60) = 0;

% pricing data
pricing_o_dollars_per_liter = 2;
pricing_p_dollars_per_lb = 3.23;

lb_per_kg = 2.2;

%% load the solar loading data
% load solar_load
Ps = 1000*ones(1,length(L));

% calculate system parameters
% Roa = DKoar/(Ptr + max(Ps)); % top-oil thermal resistance
Roa = DKoar/(Ptr + mean(Ps)); % top-oil thermal resistance
Rwo = DKwor/(Ptr - Ptnl); % winding thermal resistance

tau_w = 10/60; % winding time constant in hours
Cw = tau_w/Rwo; % heat capacity of winding

%% transformer cooling rate data

%% ode parameters
Dt = mean(diff(t));

DKoa0 = 20; % initial oil temperature rise
DKwo0 = 0;
y0 = [DKoa0; DKwo0];

mp_range = [0 5 10 15 20 40];
mp_range = [0 10];
% mp_range = [20 40 60 80];
% mp_range = [0 25];
% mp_range = 0;

if options.vary_offset
    mp_range = offset_range;
end

mp = 17.5;

odeparams = struct;

odeparams.Co = Co;
odeparams.Cx = Cx;
odeparams.cp1 = cp1;
odeparams.cp2 = cp2;
odeparams.Ptr = Ptr;
odeparams.Ptnl = Ptnl;
odeparams.F = F;
odeparams.Roa = Roa;
odeparams.Cw = Cw;
odeparams.tau_w = tau_w;

odeparams.Ka = Ka;
odeparams.L = L;
odeparams.Ps = Ps;
odeparams.t = t;

odeparams.use_deep_space = true;

% north-south vertical plate
odeparams.cooling.ns.length = 0.62; % length in m
odeparams.cooling.ns.width = 0.74; % width in m
odeparams.cooling.ns.emissitity = 0.95; % emissivity
odeparams.cooling.ns.view_factor = 1; % view factor
odeparams.cooling.ns.orientation = 'vertical';

% east-west vertical plate
odeparams.cooling.ew.length = 0.62; % length in m
odeparams.cooling.ew.width = 0.72; % width in m
odeparams.cooling.ew.emissitity = 0.95; % emissivity
odeparams.cooling.ew.view_factor = 1; % view factor
odeparams.cooling.ew.orientation = 'vertical';

% horizontal plate
odeparams.cooling.horiz.length = 0.72; % height in m
odeparams.cooling.horiz.width = 0.74; % width in m
odeparams.cooling.horiz.emissitity = 0.95; % emissivity
odeparams.cooling.horiz.view_factor = 1; % view factor
odeparams.cooling.horiz.orientation = 'horizontal';

%% calculations
DKoa = zeros(length(mp_range),length(t));
DKwo = zeros(length(mp_range),length(t));

for k = 1:length(mp_range) % mass in kg
    % for mp = 0
    if options.vary_offset
        offset = offset_range(k);
    else
        mp = mp_range(k);
    end

    Kpl = 78.5 - offset; % lower temperature bound of phase changing
    Kpu = 86 - offset; % upper temperature bound of phase changing
    
    odeparams.Kpl = Kpl;
    odeparams.Kpu = Kpu;
    odeparams.mp = mp;
    xf25 = @(t,y) xf(t,y,odeparams);

    %     [ts,y] = ode45(xf25,[min(t) max(t)],y0);
    odeset('RelTol',1e-2,'AbsTol',[1e-4 1e-4 1e-5]);
    [ts,y] = ode23(xf25,[min(t) max(t)],y0,options);  
    DKoa(k,:) = interp1(ts,y(:,1),t);
    DKwo(k,:) = interp1(ts,y(:,2),t);
    
    % calculate the lifetime
    Kw = Ka(25:end) + DKoa(k,25:end) + DKwo(k,25:end);
    Dt_ = diff(t(24:end));
    
    Faa = exp(15e3/368 - 15e3./(273 + Kw));
    Feqa = sum(Faa.*Dt_)/sum(Dt_);
    
    cost_o = pricing_o_dollars_per_liter * liters_per_gal * Vo_gal;
    cost_p = pricing_p_dollars_per_lb * lb_per_kg * mp;
    cost = cost_o + cost_p;
    Y = 22/Feqa;
    
    Vp_gal = mp * (1/phasechange_kg_per_m3) * gal_per_m3;
    fprintf('mp: %3.0f, Y: %6.2f, cost_o: %7.2f, cost_p: %7.2f, cost: %7.2f, Vp: %6.2f\n',...
        mp,Y,cost_o,cost_p,cost,Vp_gal);
    
end

%%
figure(1)

subplot 411
plot(t,ones(length(mp_range),1)*Ka + DKoa + DKwo,'r-')
ylabel('Hot-Spot (C)')
grid on

subplot 412
plot(t,ones(length(mp_range),1)*Ka + DKoa,'b-')
ylabel('Top-oil (C)')
grid on

subplot 413
plot(t,Ka,'r')
ylabel('Ambient (C)')
grid on

subplot 414
plot(t,Pr*L,'r')
ylabel('Load Power')
grid on


