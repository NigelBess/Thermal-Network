clc;
clear;
r = 1;
c = 0.01;
t1 = 400;
t28 = 300;

n = Network;
n = n.GridInit(8,8);%initialize a 4x4 grid network
n = n.IsoNode(34,t1);%node 1 is isothermal with temperature t1
n = n.IsoNode(28,t28);%node 16 is isothermal with temperature t16

n = n.GridConnect(r);%connect grid with resistors of resistance r
n = n.GridConnect(0,[2 3],[2 3]);%connect center nodes with 0 resistance
n = n.Conn(19,28);%
n = n.GridConnect(0,[6 7],7);
n = n.Prep;
n = n.Equilibrium;
n.mappedTemps
