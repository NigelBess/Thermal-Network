clc;
clear;
r = 1;
c = 0.01;
t1 = 400;
t28 = 300;

n = Network;
n = n.GridInit(8,8);%initialize a 4x4 grid network
n = n.IsoNode([1 1],t1);%node 1 is isothermal with temperature t1
n = n.IsoNode([7 7],t28);%node 16 is isothermal with temperature t16
n = n.IsoNode([7 2],200);
n = n.HeatGen([2 7],100);

n = n.GridConnect(r);%connect grid with resistors of resistance r
n = n.GridConnect(Inf,[1 8],[3 5]);%connect center nodes with 0 resistance
n = n.Prep;
n = n.MapGrid;
n = n.Equilibrium;
n.mappedTemps
