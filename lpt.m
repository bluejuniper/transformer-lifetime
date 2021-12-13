function dy = xf(t,y,params)

tau_e = params.tau_e;
delta_er = params.delta_er;

ke = interp1(params.t,params.ke,t);
% Ka = interp1(params.t,params.Ka,t);
Ka = params.Ka;

delta_eu = Ka + delta_er*ke^2;
dy = (1/tau_e)*(delta_eu - y);

