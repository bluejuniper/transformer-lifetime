function dy = xf(t,y,params)

Kpl = params.Kpl;
Kpu = params.Kpu;
Co = params.Co;
Cx = params.Cx;
cp1 = params.cp1;
cp2 = params.cp2;
mp = params.mp;
Ptr = params.Ptr;
Ptnl = params.Ptnl;
F = params.F;
Roa = params.Roa;
Cw = params.Cw;
tau_w = params.tau_w;

L = interp1(params.t,params.L,t);
Ka = interp1(params.t,params.Ka,t);
Ps = interp1(params.t,params.Ps,t);
% Ps = 5;

DKoa = y(1);
DKwo = y(2);

if params.use_deep_space
    Pcooling = xfcooling(Ka,0.84*DKoa,params.cooling);
    Roa = DKoa/Pcooling;
    if Roa < 0.04
        Roa = 0.04;
    end
    
    if Roa > 0.06
        Roa = 0.06;
    end
end

if (Kpl <= (DKoa + Ka)) && ((DKoa + Ka) <= Kpu)
    C = Co + Cx + 0.86*cp1*mp;
else
    C = Co + Cx + 0.86*cp2*mp;
end

Pt = Ptr*(L.^2*F + 1)/(F + 1) + 0*Ps; % total power losses at the previous time
Pcu = (Ptr - Ptnl)*L.^2; % copper losess at the previous time
tau = Roa*C;

if false && params.use_deep_space 
    DKoa = (Pt - Pcooling)/C;
else
    DKoa = Pt/C - (1/tau)*DKoa;
end

DKwo = Pcu/Cw - (1/tau_w)*DKwo;

dy = [DKoa DKwo]';