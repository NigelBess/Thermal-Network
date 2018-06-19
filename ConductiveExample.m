%given
r1 = 10;
r2 = 15;
r3 = 50;

 %arbitrary
t1 = 400;
t8 = 300;

%network setup
n = Network;
n = n.Initialize(9);

%create all connections
n = n.Conn(1,2,r1);
n = n.Conn(2,3,r1);
n = n.Conn(2,4,r2);
n = n.Conn(4,3,r3);
n = n.Conn(3,5,r1);
n = n.Conn(4,9,r1);
n = n.Conn(5,7,r3);
n = n.Conn(9,6,r1);
n = n.Conn(6,7,r2);
n = n.Conn(9,8,r3);
n = n.Conn(6,8,r2);

%define isothermal nodes
n = n.IsoNode(1,t1);
n = n.IsoNode(8,t8);

%solve for equilibrium
n = n.Equilibrium;

%total heat from node 1 to 8 = heat from node 1 to 2
q = n.q(1,2);
rnet = (t1-t8)/q;
fprintf("Net Thermal Resistance: %f W/K\n\n",rnet)