% Simple Particle Swarm Optimization function
% originally written by Chris Smith (2012)
% updated and comments added by Vince Pericoli (2015)

function [bestpos, bestval] = ...
    fpsosearch_simp(ObjFun, lbound, ubound, np, niter, gravity, ...
                    inertia, errTol, plotflag)
%Particle Swarm "Multi-Input Single-Output" (MISO) optimization
%INPUTS--
%   ObjFun  : function handle to objective function (similar to other 
%             MATLAB optimization routines)
%   lbound  : vector describing the size and lower bound of parameter space
%   ubound  : vector describing the size and upper bound of parameter space
%   np      : number of particles. Try 3-6 * the param space dimension
%   niter   : number of iterations
%   gravity : particle attractive force (try 1.5). You can use a vector to
%             specify a different value for global and local (sometimes
%             referred to as "social" and "cognitive" learning rates in the
%             literature).
%   inertia : particle inertia (try [0.55, 0.275]). You can use a vector to
%             specify a different value for the initial inertia and end
%             inertia (treated as a linear variation over the steps)
%   errTol  : stopping criteria. use -inf unless you know otherwise; this
%             implies that the search will run until for niter iterations.
%   plotflg : optional flag to specify whether to plot results or print 
%             iteration number during the solution search. 0 = no plot or
%             iteration print, 1 = plot, but do not print iteration, 2 =
%             plot and print iteration number (Default).
%OUTPUT--
%   bestpos : the best (optimum) position of the particles located by the
%             routine
%   bestval : the best (optimum) value of the objective function, i.e. the
%             objective function evaluated at bestpos.
%

%% Error Handling
% perform a rudimentary check on lbound and ubound
if length(ubound) ~= length(lbound)
    % check sizes
    error('lbound and ubound are different sizes!');
elseif any(lbound > ubound)
    % make sure lbound <= ubound
    for i = 1:length(ubound)
        %make sure lbound <= ubound
        if lbound(i) > ubound(i)
            error('lbound(%i) > ubound(%i)',i,i);
        end
    end
end
    
              
%% INPUTS

if nargin < 9
    % plotflag default = 2
    plotflag = 2;
end

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
    
    %print iteration number, if requested
    if plotflag > 1
        fprintf('\n*** Beginning PSO Iteration %i ***\n',iter);
    end
    
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

%% save output arguments
% we don't want to overwrite previous results

%figure out how many existing pso_results there are
dir_list = dir('pso_results*.mat');
[save_num, ~] = size(dir_list);

%based on this, set the save file name
if save_num == 0
    save_name = 'pso_results.mat';
else
    save_name = sprintf('pso_results (%i).mat',save_num);
end

%save to binary .mat using the above name
save(save_name,'bestpos','bestval');

end
