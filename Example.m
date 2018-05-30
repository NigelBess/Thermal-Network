clc;
clear;
r = 1;
c = 0.01;
t1 = 400;
t16 = 300;

n = Network;
n = n.Initialize(16);%the network has 16 nodes
n = n.tConstant(1,t1);%node 1 is isothermal with temperature t1
n = n.tConstant(16,300);%node 16 is isothermal with temperature t16

%turn nodes into a grid of nodes connected by resistors
nodeMap = zeros(4);
for i = 1:numel(nodeMap)
    nodeMap(i) = i;
end
nodeMap = nodeMap.';

for i = 1:size(nodeMap,1)
    for j = 1:size(nodeMap,2)
        if i<size(nodeMap,1)
            n=n.Conn(nodeMap(i,j),nodeMap(i+1,j),r);
        end
        if j<size(nodeMap,2)
            n=n.Conn(nodeMap(i,j),nodeMap(i,j+1),r);
        end
    end
end

%connect center superNode
n = n.Conn(6,7);
n = n.Conn(7,11);
n = n.Conn(11,10);
n = n.Conn(10,6);


n = n.Prep;
n = n.Equilibrium

%go back to a matrix
for i = 1:numel(nodeMap)
    nodeMap(i) = n.t(nodeMap(i));
end