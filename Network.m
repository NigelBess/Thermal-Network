classdef Network
    properties(Access = public)
        n;%number of nodes
        c;%connection matrix
        t;%temperature vector (or voltage or any other potential)
        q;%heat flux matrix
        r;%resistance matrix
        tConst;%isothermal temperature vector
        qGen;%heat generation vector
        cap;%heat capacity vector
        tau;%time constant of each node
        dt = 0.01;%time step
        maxIterations = 1E6;%after how many iterations should it stop while trying to find equilibrium
        precision = 1E-8;
        sets;%matrix of logicals. each row of the 'sets' matrix shows a set of nodes that are connected to eachother with 0 resistance
        setsTau;%time constant associated to each set
        grid = false;%boolean. Is this network a grid?
        nodeMap;%each element of nodemap contains the node number associated with that position in the map (only applicable for grid networks)
        mappedTemps;%used to visualize the grid
        rad = false;%boolean. Is this a radiative network?
    end
    methods(Access = public)
        function this = Initialize(this,numNodes)
            this.n = numNodes;
            this.c = zeros(numNodes);
            this.c = this.c==1;%to logical
            this.t = zeros(1,numNodes);
            this.q = zeros(numNodes);
            this.r = ones(numNodes);
            this.r = this.r./0;%set all resistances to Inf
            this.tConst = zeros(1,numNodes);
            this.tConst = this.tConst == 1;%to logical
            this.qGen = zeros(1,numNodes);
            this.cap = 0.01*ones(1,numNodes);
            this.tau = zeros(1,numNodes);
        end
        
        function this = GridInit(this,x,y)%Initialize as x by y grid
            if nargin == 2
                y = x;
            end
            this = this.Initialize(x*y);
            this.grid = true;
            this.nodeMap = zeros(y,x);
            for i = 1:numel(this.nodeMap)
                this.nodeMap(i) = i;
            end
            this.nodeMap = this.nodeMap.';
        end
        function this = RadInit(this,numNodes)
            this = this.Initialize(numNodes);
            this.rad = true;
        end
        function this = GridConnect(this,r,node1,node2)
            
            if ~this.grid
                error("Network.GridConnect only works for grid networks. To initialize as x by y grid, call 'Network.GridInit(x,y)'");
            end
            if nargin == 2%if nodes not specified then we will connect the entire grid
                node1 = [1,1];
                node2 = size(this.nodeMap);
            end
            xbounds = zeros(1,2);
            ybounds = xbounds;
            xbounds(1) = min([node1(1),node2(1)]);
            xbounds(2) = max([node1(1),node2(1)]);
            ybounds(1) = min([node1(2),node2(2)]);
            ybounds(2) = max([node1(2),node2(2)]);
                
             for i = xbounds(1):xbounds(end)
                for j = ybounds(1):ybounds(end)
                    if i<xbounds(end)
                        this=this.DisConn(this.nodeMap(i,j),this.nodeMap(i+1,j));%remove any pre-existing connection
                        if r<Inf
                        this=this.Conn(this.nodeMap(i,j),this.nodeMap(i+1,j),r);
                        end
                    end
                    if j<ybounds(end)
                        this=this.DisConn(this.nodeMap(i,j),this.nodeMap(i,j+1));%remove any pre-existing connection
                        if r<Inf
                        this=this.Conn(this.nodeMap(i,j),this.nodeMap(i,j+1),r);
                        end
                    end
                end
             end
             this = this.MapGrid;
        end
        function this = GridDisConn(this,node1,node2)
            this = this.GridConnect(Inf,node1,node2);
        end
        function this = MapGrid(this)
            this.mappedTemps = this.nodeMap;%allcate
            for i = 1:this.n
                this.mappedTemps(i) = this.t(this.nodeMap(i));
            end
        end
        
        function this = Conn(this,i,j,r)%connect node i to node j via resistance (r)
            if this.grid && (numel(i)==2)
                i = this.nodeMap(i(1),i(2));            
            end
            if this.grid && (numel(j)==2)
                j = this.nodeMap(j(1),j(2));            
            end
            if nargin == 3
                r = 0;
            end
                this.c(i,j) = true;
                this.c(j,i) = this.c(i,j);
                this.r(i,j) = this.Par([r this.r(i,j)]);
                this.r(j,i) = this.r(i,j);
        end
        
        function this = DisConn(this,i,j,r)%disconnect node i and node j
            if this.grid && (numel(i)==2)
                i = this.nodeMap(i(1),i(2));            
            end
            if this.grid && (numel(j)==2)
                j = this.nodeMap(j(1),j(2));            
            end
            if nargin == 3%left out resistance parameter
                this.r(i,j) = Inf;%set resistance to Inf
                this.c(i,j) = false;%remove connection
                this.c(j,i) = this.c(i,j);
            else
                if r<this.r(i,j)
                    error('This function removes resitors from a set of parralel resistors. r must be greater than this.r(i,j). To disconnect the two nodes entirely, do not include a parameter for r.')
                end
                this.r(i,j) = this.Par([this.r(i,j), -r]);%remove resistor r
            end            
            this.r(j,i) = this.r(i,j);
        end
        
        function this = HeatGen(this,i,qVal)
             if this.grid && (numel(i)==2)
                i = this.nodeMap(i(1),i(2));            
            end
            %sets constant heat flux, qVal through connection i,j
            this.qGen(i) = qVal;
        end
        
        function this = IsoNode(this,i,tVal)
            if this.grid && (numel(i)==2)
                i = this.nodeMap(i(1),i(2));            
            end
            %defines node i as isothermal with temperature tVal
            this.tConst(i) = true;
            this.t(i) = tVal;
        end
        
         function this = Time(this)%find time constant of each node, and determine an appropriate time step (tau_min/2)
             tempR = this.r;
             if this.rad
                 for i = 1:this.n
                    for j = 1:this.n
                        tempR(i,j) = this.r(i,j)/5.67E-8/(this.t(i)^2+this.t(j)^2)/(this.t(i)+this.t(j));
                    end
                 end
             end
             for i = 1:this.n
                res = tempR(i,:);
                nonZeroRes = res(find(res>0));
                this.tau(i) = this.Par(nonZeroRes)*this.cap(i);
             end
             
            this.setsTau = Inf;%in case there are no sets
            if any(any(this.sets))%if there are sets, each set will have its own time constant
                numSets = size(this.sets,1);
                this.setsTau = ones(1,numSets)*Inf;%prep time constant vector
                for i = 1:numSets
                    nodes = find(this.sets(i,:));%nodes in this set
                    res = zeros(this.n);%resistance matrix for all resistances touching this set
                    for k = nodes
                        res(k,:) = tempR(k,:);
                        res(:,k) = tempR(:,k);
                    end
                    nonZeroRes = res(find(res>0));
                    this.setsTau(i) = this.Par(nonZeroRes)*sum(this.cap(nodes));
                end
            end

            
            this.dt = min([min(this.tau),min(this.setsTau)])/2;
         end
        
        function this = Prep(this)%prep should be called before iterating but after creating all connections
            this=this.FindSets;
            this=this.Time;%find appropriate dt
            this = this.IsoSets;
            
        end
        
        function this = Transient(this,t)
            minIterations = 100;%if t is small do at least this many iterations
            this = this.Prep;
            if this.dt > t/minIterations
                this.dt = t/minIterations;
            end
            for i = 0:this.dt:t
                this = this.Iterate;
            end
            if this.grid
                this=this.MapGrid;
            end
        end
        
        function this = Equilibrium(this)
            this = this.Prep;
            tLast = this.t.*0;
            for i = 1:this.maxIterations              
                this = this.Iterate;
                if all(abs(this.t-tLast)<this.precision) %has EVERY temperature changed by less than desired precision?
                    if this.grid
                        this = this.MapGrid;
                    end
                    return;
                end
                tLast = this.t;
            end
            error('System did not equilibriate after %d iterations.\n Change "maxIterations property to increase number of interations (NOT RECOMMENDED)"',this.maxIterations);
        end
        
        function this = Iterate(this) 
            this = CalcHeat(this);
            this = ApplyHeat(this);
            
        end
        function this = CalcHeat(this)
           for i = 1:this.n
            for j = (i+1):this.n %i:n to avoid redundant work (r(i,j) = r(j,i), q(i,j) = -q(j,i), etc)
                    if this.r(i,j)==0
                        this.q(i,j) = 0;
                    else
                        this.q(i,j) = (this.t(i)-this.t(j))/this.r(i,j);
                    end
                    this.q(j,i) = -this.q(i,j);
            end
           end
        end
        function this = ApplyHeat(this)
                 sig = 5.67E-8;
                       newT = this.t.*0;%temporary vector to store new temperatures

                    %apply heat to each node
                    for i = 1:this.n 
                        if ~this.tConst(i)
                            deltaT = ((sum(this.q(:,i))+this.qGen(i))/this.cap(i)*this.dt);
                           if ~this.rad
                                newT(i) = this.t(i)+deltaT ;
                           else
                               newT(i) = ((this.t(i)/sig)^(1/4)+deltaT)^(4)*sig;
                           end
                        else
                            newT(i) =this.t(i); 
                        end
                    end            
            %equalize temperature over each set
            for i = 1:size(this.sets)*[1;0]%iterate through number of sets
                if any(this.sets(i,:))%if there are any nodes in the current set
                    temps = newT.*this.sets(i,:);
                    caps = this.cap.*this.sets(i,:);
                    finalTemp = sum(temps.*caps)/sum(caps);%weighted average by heat capacity
                    for j = 1:this.n%for each node
                        if this.sets(i,j)%if the node is part of the set
                            newT(j) = finalTemp;%set new temperature of that node
                        end
                    end
                end
            end
            
            this.t = newT;
        end
        
        
        function this = FindSets(this)%finds all sets of nodes connected by 0 resistance
            rEdit = this.r;
            indices = this.num2index(rEdit,find(rEdit==0));%indices is an unknown-by-2 matrix where each row is the indices of the resistance matrix where resistance = 0
            affectedNodes = unique(indices)';
            maxSets = floor(numel(affectedNodes)/2);%there can only be an integer number of sets. Each set has at least 2 nodes. 
            this.sets = zeros(maxSets,this.n)==1;%prep the sets matrix
            
            setNumber = 1;
            for i = affectedNodes
                if ~any(this.sets(:,i))
                    [this,indices] = this.addConnected(i,indices,setNumber);
                    setNumber = setNumber+1;
                end
            end 
            for i = 1:maxSets
                if ~any(this.sets(i,:))
                    this.sets(i,:)=[];
                end
            end
        end
        
       function [this,indices] = addConnected(this,node,indices,setNumber)
            if ~this.sets(setNumber,node)%Has this node already been added? This ends the recursion
                this.sets(setNumber,node) = true;%add this node
                
                %find nodes that also connect to this node
                relevantIndices = find(indices(:,1)==node);
                connectedNodes = zeros(1,length(relevantIndices)); 
                for i = 1:length(relevantIndices)
                    connectedNodes(i) = indices(relevantIndices(i),2);
                    %this.sets(setNumber,connectedNodes(i)) = true;%add nodes that connect to this node
                end
                for i = 1:length(relevantIndices)
                    indices(i,:) = [];  
                end
                
                for i = connectedNodes
                    [this,indices] = this.addConnected(i,indices,setNumber);
                end
            end
       end
        
        function this = IsoSets(this)
            numSets = size(this.sets,1);
            for i =1:numSets
                if any(and(this.sets(i,:),this.tConst))%is any member of the set isothermal?
                    temps = this.t(find(this.t.*this.tConst.*this.sets(i,:)));%get all the isothermal temperatures in the set   
                        if ~all(temps==temps(1))%are there any temperature mismatches among isothermal nodes in the set?
                            error("Multiple isothermal temperatures set within a supernode. Only one isothermal temperature can exist in a single node");
                        end
                    for j = 1:this.n
                        if this.sets(i,j)
                            this = this.IsoNode(j,temps(1));
                        end
                    end
                end
            end
        end
        
        
            
        function out = Par(~,rVec)%resistance in parralel
             rVec = 1./rVec;
             out = 1/sum(rVec);
        end
        
        function out = index2num(~,mat,index)%double index to single index conversion for matrix 'mat'
            if numel(index) == 1
                out = index;
                return;
            end
            col = size(mat,2);
            out = (index(1)-1)*col+index(2);
        end
        function out = num2index(~,mat,num)%returns indices of element 'num' in matrix 'mat'
            amount = numel(num);
            out = zeros(amount,2);
            for k = 1:amount
                [out(k,1),out(k,2)] = ind2sub(size(mat),num(k));
            end
        end
        function out = Conv(this)
            if this.rad
                out = (this.t./5.67E-8).^(1/4);
            else
                out = this.t;
            end
        end
    end
    
end