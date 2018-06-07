clc;
clear;
r = 1;


n = Network;
n = n.GridInit(8,8);%initialize a 4x4 grid network

n = n.IsoNode([1 1],400);%node 1,1 is isothermal with temperature 400
n = n.IsoNode([7 7],300);%node 7,7 is isothermal with temperature 300
n = n.IsoNode([7 2],200);
n = n.HeatGen([2 7],100);%node 2,7 generates 100 heat units per time
n = n.GridConnect(r);%connect entire grid with resistors of resistance r
n = n.GridConnect(Inf,[1 8],[3 5]);% split the grid into two halves. this can be useful for analyzing two grid networks simultaneously (Note: this is not efficient)

n = n.Equilibrium;% calculate equilibrium temperature
n.mappedTemps%temperatures on the grid 
