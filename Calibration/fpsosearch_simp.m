% Simple Particle Swarm Optimization function
% originally written by Chris Smith (2012)
% updated, optimized, and comments added by Vince Pericoli (2015)


% Particle Swarm "Multi-Input Single-Output" (MISO) optimization
%ObjFun - function handle to objective function (like matlab opt routines)
%lbound, ubound - vectors describing the size and bounds of param space
%np - number of particles. Try 3-6 * the param space dimension
%niter - number of iterations
%gravity  - particle attractive force. Try 1.5
%inertia - particle inertia. Try 0.55
%errTol - stopping criteria. use -inf unless you know otherwise; this
%         implies that the search will run until for niter iterations.
%plotflag - plot results during? 1 or 0
% startpos, plotflag, saveextra, errTol, refresh, startconstraint


function [bestpos, bestval] = ...
    fpsosearch_simp(ObjFun, lbound, ubound, np, niter, gravity, ...
                    inertia, errTol, plotflag)

%% Error Handling
%perform a rudimentary check on lbound and ubound
if length(ubound) ~= length(lbound)
    %check sizes
    error('lbound and ubound are different sizes!');
else
    for i = 1:length(ubound)
        %make sure lbound <= ubound
        if lbound(i) > ubound(i)
            error('lbound(%i) > ubound(%i)',i,i);
        end
    end
end
    
              
%% INPUTS

%set the personal and global "gravity" or acceleration constants
%   in some literature, this is referred to as social (global) 
%   and cognitive (personal) learning rates
if length(gravity) == 1
    ggrav = gravity;
    pgrav = gravity;
elseif length(gravity) == 2
    ggrav = gravity(1);
    pgrav = gravity(2);
else
    error('Error in gravity definition');
end

%set the inertia weight
%can be specified as constant or linearly decreasing
if length(inertia) == 1
    inertia_init  = inertia;
    inertia_final = inertia;
elseif length(inertia) == 2
    inertia_init  = inertia(1);
    inertia_final = inertia(2);
else
    error('Error in inertia definition');
end

%determine the number of dimensions of the problem
ndim = length(ubound);

%% INITIALIZATION

%initialize storage arrays and values
ppos     = zeros(np, ndim); %particle position (in the parameter space)
pvel     = zeros(np, ndim); %particle velocity
pbestpos = ppos;            %particle best position

pbestval = inf*ones(np,1); %particle best value (begin infinitely large)
pval     = zeros(np,1);    %particle's current ObjFun value
gbestval = inf;            %absolute global best ObjFun value

%furthermore, preallocate some "history" arrays for plotting purposes
ppos_hist  = zeros(np,ndim,niter);
gbest_hist = zeros(1,niter);

%initialize the particles to random positions throughout the space
for i = 1:np
    ppos(i,:) = rand(1,ndim).*(ubound-lbound) + lbound;
end

%% PSO
for iter = 1:niter
    %for all iterations
    
    %if desired, set inertia to linearly decrease
    inertia = inertia_init + (inertia_final - inertia_init)*(iter/niter);
    
    for i = 1:np
        %for all particles
        
        %get the ObjFun value at current particle position
        pval(i) = feval(ObjFun, ppos(i,:));

        %check the particle's value
        if pval(i) < pbestval(i)
            %if the particle value is less than the current particle best,
            %save this value as the particle best, and update the particle
            %best position.
            pbestval(i)   = pval(i);
            pbestpos(i,:) = ppos(i,:);
        end
        
        if pbestval(i) < gbestval
            %furthermore, if it's less than the current global best, save
            %this value as the new global best, and update the global best
            %position.
            gbestval = pbestval(i);
            gbestpos = pbestpos(i,:);
        end
        

        %using the PSO algorithm, update the particle position:
        %new particle velocity
        pvel(i,:) = inertia*pvel(i,:) + ...
                    pgrav*rand(1).*( pbestpos(i,:) - ppos(i,:) ) + ...
                    ggrav*rand(1).*( gbestpos - ppos(i,:) );
        
        %new particle position
        ppos(i,:) = ppos(i,:) + pvel(i,:);
        ppos_hist(i,:,iter) = ppos(i,:); %keep history of all positions
    end
    
    gbest_hist(iter) = gbestval; %keep history of all gbestval for plotting
    
    if gbestval < errTol
        %if the global best is lower than user-defined tolerance,
        %terminate search.
        break;
    end
end


if plotflag
    %if plotting desired, plot search history
    figure(100)
    hold on;
    plot(gbest_hist)
    plot(gbest_hist,'bo')
    plot([1 iter], [gbestval gbestval],'r')
    
    for j=1:ndim
        figure(102)
        subplot(3,ceil(ndim/3),j)
        plot(squeeze(ppos_hist(:,j,:))')
    end
    
    % save figures to file
    saveas(figure(100),'figure100');
    saveas(figure(102),'figure102');
end

%set output arguments
bestpos = gbestpos;
bestval = gbestval;

%save output arguments
save('pso_results.mat','bestpos','bestval');

end
