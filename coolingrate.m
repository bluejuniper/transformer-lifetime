function [Q,Qc,Qr] = coolingrate(Tinf,DT,params)

%% surface geometry
Ls = params.length;
Ws = params.width;
As = Ls*Ws; % surface area
epss = params.emissitity;
epssky = 0.75; % emissitivy of sky
vf = params.view_factor;

switch params.orientation
    case 'vertical'
        Lc = Ls;
    case 'horizontal'
        Lc = As/(2*Ls + 2*Ws);
end

kb = 5.67e-8; % no idea what this is 

%% air properties at 60 C
rhoa = 1.059; % density in kg/m^3
va = 1.896e-5; % kinematic viscosity in  m^2/2
ka = 0.02808; % thermal conductivity in W/m*K
alphaa = 2.632e-5; % thermal diffusitivity in m^2/s
betaa = 1/(273 + 60); % volume expansion coefficient in K^-1
Pra = 0.7202; % Prantl number

%% temperatures
Tinf = Tinf + 273; % ambient temperature in K
% DT = 30; % someting in K
Ts = Tinf + DT; % surface temperature
alt = 728; % altitude in m

% ALT_CORR = xlsread('ASHRAE Constants.xlsx');
falt = 1.049; % altitude correction factor

%% convection
g = 9.8; % acceleration due to gravity m/s^2
Ral = (g*betaa*(Ts - Tinf)*Lc^3/va^2)*Pra;

switch params.orientation
    case 'vertical'
        Nu = (0.825 + 0.387*Ral^(1/6)/(1 + (0.492/Pra)^(9/16))^(8/27))^2;
        Qr = (1/2)*kb*As*vf*(epss*Ts^4 - epss*Tinf^4) + (1/2)*kb*As*vf*(epss*Ts^4 - epssky*Tinf^4); % ratiation heat transfer
    case 'horizontal'
        Nu = 0.15*Ral^(1/3);
        Qr = kb*As*vf*(epss*Ts^4 - epssky*Tinf^4);
end
h = (ka/Lc)*Nu; % convection coefficient
Qc = (h/falt)*As*(Ts - Tinf); % convective heat transfer
Q = Qc + Qr; % total heat transfer from vertical wall


