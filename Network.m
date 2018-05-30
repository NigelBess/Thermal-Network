classdef Network
    properties(Access = public)
        n;%number of nodes
        c;%connection matrix
        t;%temperature vector (or voltage or any other potential)
        q;%heat flux matrix
        r;%resistance matrix
        tConst;%isothermal temperature vector
        qConst;%constant heat flux matrix
        cap;%heat capacity vector
        tau;%time constant of each node
        dt = 0.01;%time step
        maxIterations = 1E6;%after how many iterations should it stop while trying to find equilibrium
        precision = 1E-8;
        sets;%matrix of logicals. each row of the 'sets' matrix shows a set of nodes that are connected to eachother with 0 resistance
        setsTau;%time constant associated to each set
        grid;%boolean. Is this network a grid?
        nodeMap;%nodes aligned in grid form. Only useful if the network is a grid
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
            this.qConst = zeros(numNodes);
            this.qConst = this.qConst == 1;%to logical
            this.cap = 0.01*ones(1,numNodes);
            this.tau = zeros(1,numNodes);
            
        end
        function this = Conn(this,i,j,r)%connect node i to node j via resistance (r)
            if nargin == 3
                r = 0;
            end
            this.c(i,j) = true;
            this.c(j,i) = this.c(i,j);
            this.r(i,j) = this.Par([r this.r(i,j)]);
            this.r(j,i) = this.r(i,j);
        end
        
        function this = DisConn(this,i,j,r)%disconnect node i and node j
            if ~this.c(i,j)%are the nodes not connexted
                error('These nodes are not connected')
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
        
        function this = qConstant(this,i,j,qVal)
            %sets constant heat flux, qVal through connection i,j
            this.qConst(i,j) = true;
            this.qConst(j,i) = this.qConst(j,i);
            this.q(i,j) = qVal;
            this.q(j,i) = -this.q(j,i);
        end
        
        function this = tConstant(this,i,tVal)
            %defines node i as isothermal with temperature tVal
            this.tConst(i) = true;
            this.t(i) = tVal;
        end
        
         function this = Time(this)%find time constant of each node, and determine an appropriate time step (tau_min/2)
             for i = 1:this.n
                res = this.r(i,:);
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
                        res(k,:) = this.r(k,:);
                        res(:,k) = this.r(:,k);
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
        end
        
        function this = Equilibrium(this)
            this = this.Prep;
            tLast = this.t.*0;
            for i = 1:this.maxIterations              
                this = this.Iterate;
                if all(abs(this.t-tLast)<this.precision) %has EVERY temperature changed by less than desired precision?
                    return;
                end
                tLast = this.t;
            end
            error('System did not equilibriate after %d iterations',this.maxIterations);
        end
        
        function this = Iterate(this) 
            newT = this.t.*0;%temporary vector to store new temperatures
            for i = 1:this.n
                for j = i:this.n %i:n to avoid redundant work (r(i,j) = r(j,i), q(i,j) = -q(j,i), etc)
                    if ~this.qConst(i,j)
                        if this.r(i,j)==0
                            this.q(i,j) = 0;
                        else
                            this.q(i,j) = (this.t(i)-this.t(j))/this.r(i,j);
                        end
                        this.q(j,i) = -this.q(i,j);
                    end
                end
            end
            
            %apply heat to each node
            for i = 1:this.n 
                if ~this.tConst(i)
                    newT(i) = this.t(i)+sum(this.q(:,i))/this.cap(i)*this.dt;
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
            indices = this.num2index(rEdit,find(rEdit==0));
            affectedNodes = unique(indices);
            maxSets = floor(numel(affectedNodes)/2);%there can only be an integer number of sets. Each set has at least 2 nodes. 
            this.sets = zeros(maxSets,this.n)==1;%prep the sets matrix
            

            for i = 1:maxSets
                this = this.addConnected(affectedNodes(i),indices,i);
            end      
        end
        
        function this = addConnected(this,node,indices,setNumber)
            if ~this.sets(setNumber,node)
                this.sets(setNumber,node) = true;
                %find nodes that connect from t1
                relevantIndices = find(indices(:,1)==node);
                connectedNodes = zeros(1,length(relevantIndices));
                for i = 1:length(relevantIndices)
                    connectedNodes(i) = indices(relevantIndices(i),2);
                end
                
                for i = connectedNodes
                    this = this.addConnected(i,indices,setNumber);
                end
            end
        end
        
            
        function out = Par(~,rVec)%resistance in parralel
             rVec = 1./rVec;
             out = 1/sum(rVec);
        end
        function out = num2index(~,mat,num)%returns indices of element 'num' in matrix 'mat'
            amount = numel(num);
            out = zeros(amount,2);
            for k = 1:amount
                [out(k,1),out(k,2)] = ind2sub(size(mat),num(k));
            end
        end
    end
    
end