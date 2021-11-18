function [Q,Qc,Qr] = xfcooling(Ka,DK,params)

[Qns,Qcns,Qrns] = coolingrate(Ka,DK,params.ns);
[Qew,Qcew,Qrew] = coolingrate(Ka,DK,params.ew);
[Qh,Qch,Qrh] = coolingrate(Ka,DK,params.horiz);

Q = 2*Qns + 1*Qew + Qh;
Qc = 2*Qcns + 1*Qcew + Qch;
Qr = 2*Qrns + 1*Qrew + Qrh;