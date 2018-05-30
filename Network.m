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
            this.sets = zeros(numNodes,numNodes);
            
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
                this.tau(i) = par(this.r(i,:))*this.cap(i);
            end
            this.dt = min(this.tau)/2;
         end
        
        function this = Prep(this)%prep should be called before iterating but after creating all connections
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
                        this.q(i,j) = (this.t(i)-this.t(j))/this.r(i,j);
                        this.q(j,i) = -this.q(i,j);
                    end
                end
            end
            
            for i = 1:this.n
                if ~this.tConst(i)
                    newT(i) = this.t(i)+sum(this.q(:,i))/this.cap(i)*this.dt;
                else
                    newT(i) =this.t(i); 
                end
            end
            this.t = newT;
        end
        
        
        function this = FindSets(this)%finds all sets of nodes connected by 0 resistance
            rEdit = this.r;
            while any(rEdit==0)
                indices = find(rEdit==0);
                
            end
        end
       
        function out = Par(~,rVec)%resistance in parralel
             rVec = 1./rVec;
             out = 1/sum(rVec);
        end
    end
    
end