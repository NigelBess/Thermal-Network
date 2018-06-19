clear
clc

%given
t11 = 300;
q63 = 20;
endTime = 100;
r1 = 10;
r2 = 50;
c = 0.1;

%network setup
g = Network;
g = g.GridInit(7,5);

%initial conditions
g.t(:) = 300; 

%heat capacitance
g.cap(:) = c;

%connections
g = g.GridConnect(r1);
g = g.GridConnect(r2,[4 2],[5 5]);
g = g.Conn([2,2],[3,3],r2);

%isothermal node and heat generation
g = g.IsoNode([1,1],t11);
g = g.HeatGen([6 3],q63);



%solve
g = g.Transient(endTime);
g = g.MapGrid;
disp(g.mappedTemps)