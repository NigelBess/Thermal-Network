clc
clear
%given
t1 = 300;
t3 = 500;
r12 = 10;
r23 = 12;

%boltzman constant
sig = 5.67E-8;

%initialize networks
c = Network; % conductive
r = Network; % radiative
c = c.Initialize(2);
r = r.RadInit(2);

%connections
c = c.Conn(1,2,r12);
r = r.Conn(1,2,r23);

%isothermal nodes
c = c.IsoNode(1,t1);
r = r.IsoNode(2,sig*(t3^4));%black body radiation

%set initial conditions to solve for time constants.
%I will choose t2 = 400 as an initial condition. (arbitrary)
c.t(2) = 400;
r.t(1) = sig*(400^4);

%prep
c = c.Prep;
r = r.Prep;

%choose the smallest recommended time step
dt = min([c.dt r.dt]);
c.dt = dt;
r.dt = dt;

for i = 1:10000%manually iterate 10000 times (arbitrary large number)
c = c.CalcHeat;
r = r.CalcHeat;
c = c.ApplyHeat;
r = r.ApplyHeat;

%convert black body radiation to temperature
t2Rad = (r.t(1)/sig)^(1/4);

%equilibriate temperature between the two networks
tAv = (t2Rad+c.t(2))/2;

c.t(2) = tAv;
r.t(1) = sig*(tAv^4);
end
fprintf("Equilibrium Temperature of Node 2: %f K\n\n",c.t(2))