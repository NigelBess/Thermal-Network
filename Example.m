clc;
clear;
n = Network;
n = n.Initialize(4);%the network has 3 nodes
n = n.tConstant(1,400);%node 1 is isothermal with temperature 400
n = n.tConstant(4,300);%node 3 is isothermal with temperature 300
n = n.Conn(1,2,1);%connect node 1 and 2 with resistance 1
n = n.Conn(2,3);%join node 2 and 3
n = n.Conn(3,4,1);
n = n.Equilibrium