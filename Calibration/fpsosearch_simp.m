% Simple Particle Swarm Optimization function
% originally written by Chris Smith (2012)
% updated and comments added by Vince Pericoli (2015)

function [bestpos, bestval] = ...
    fpsosearch_simp(ObjFun, lbound, ubound, np, niter, gravity, ...
                    inertia, errTol, plotflag, dumpflag)
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
%   plotflg : optional flag to specify whether to plot the particle search
%             path and optimum history (Default = true)
%   dumpflg : optional flag to specify whether to dump intermediate results 
%             to disk, in case of error (Default = true). This is useful if
%             objective function is expensive. In the future, we can fully
%             implement a restart feature.
%
%OUTPUT--
%   bestpos : the best (optimum) position of the particles located by the
%             routine
%   bestval : the best (optimum) value of the objective function, i.e. the
%             objective function evaluated at bestpos.
%

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Check Input Args, set defaults.
%

if( (nargin == 2) && isstruct(lbound) )
    % then this is a restart file input
    restart_from_prev = true;
    restart_struct = lbound;
    clear('lbound');
    
else
    % then this is a standard input.
    restart_from_prev = false;
    
    % set defaults
    if nargin <  9, plotflag = true; end
    if nargin < 10, dumpflag = true; end

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
end

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Error Handling
%

if( ~restart_from_prev )
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
end

% check objective function
if( ~isa(ObjFun,'function_handle') )
    error('ObjFun is not a valid MATLAB function handle!')
end 

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Initialization
%


if( restart_from_prev )
    % initialize to the previously saved state!
    % see below for descriptions of variables.
    
    % set input vars
    np       = restart_struct.np;
    niter    = restart_struct.niter;
    pgrav    = restart_struct.pgrav;
    ggrav    = restart_struct.ggrav;
    errTol   = restart_struct.errTol;
    plotflag = restart_struct.plotflag;
    dumpflag = restart_struct.dumpflag;
    inertia_init  = restart_struct.inertia_init;
    inertia_final = restart_struct.inertia_final;
    
    % set state vars
    start_iter = 1 + restart_struct.last_good_iter;
    ppos       = restart_struct.ppos;
    pvel       = restart_struct.pvel;
    pbestpos   = restart_struct.pbestpos;
    pbestval   = restart_struct.pbestval;
    pval       = restart_struct.pval;
    gbestval   = restart_struct.gbestval;
    gbestpos   = restart_struct.gbestpos;
    ppos_hist  = restart_struct.ppos_hist;
    gbest_hist = restart_struct.gbest_hist;
    
    % set ndim
    ndim = size(ppos,2);
    
else
    % initialize to fresh state.    
    start_iter = 1;
    
    % initialize storage arrays and values
    ppos     = zeros(np, ndim); %particle position (in the parameter space)
    pvel     = zeros(np, ndim); %particle velocity
    pbestpos = zeros(np, ndim); %particle best position

    pbestval = inf*ones(np,1); %particle best value (begin infinitely large)
    pval     = zeros(np,1);    %particle's current ObjFun value
    gbestval = inf;            %absolute global best ObjFun value
    gbestpos = zeros(1,ndim);  %absolute global best parameter position

    %furthermore, preallocate some "history" arrays for plotting purposes
    ppos_hist  = zeros(np,ndim,niter);
    gbest_hist = zeros(1,niter);

    %initialize the particles to random positions throughout the space
    for i = 1:np
        ppos(i,:) = rand(1,ndim).*(ubound-lbound) + lbound;
    end
    
end

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% particle swarm
%

for iter = start_iter:niter
    %for all iterations
    
    %print iteration number, and send to base-workspace (sometimes the 
    %print is unreadable if the window is full of text)
    fprintf('\n*** Beginning PSO Iteration %i ***\n',iter);
    
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
    
    % save last known best position and restart file, if requested
    if( dumpflag )
        last_good_iter = iter; %#ok<NASGU>
        save('last_known_best_position.mat','gbestpos','last_good_iter')
        save('last_known_best_state.mat', ...
                ... % state vars
                'last_good_iter', 'ppos', 'pvel', 'pbestpos', ...
                'pbestval', 'pval', 'gbestval', 'gbestpos',   ...
                'ppos_hist', 'gbest_hist',                    ...
                ... % input vars
                'np', 'niter', 'pgrav', 'ggrav',    ...
                'inertia_init', 'inertia_final',    ...
                'errTol', 'plotflag', 'dumpflag' )
    end
end


if plotflag
    %if plotting desired, plot search history
    figure;
    hold on;
    plot(gbest_hist)
    plot(gbest_hist,'bo')
    plot([1 iter], [gbestval gbestval],'r')
    
    figure;
    for j=1:ndim
        subplot(3,ceil(ndim/3),j)
        plot(squeeze(ppos_hist(:,j,:))')
    end
end

% save any open figures 
% (this will also save figures generated by the objective function)
h = get(0,'children');
for i = 1:length(h)
    fname = get(h(i),'Name');
    if isempty(fname)
        saveas(h(i),['figure' num2str(get(h(i),'Number'))],'pdf');
    else
        saveas(h(i),fname,'pdf');
    end
end

%set output arguments
bestpos = gbestpos;
bestval = gbestval;

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Save output args to file.
%

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

%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% clean up
%
delete('last_known_best_position.mat')
delete('last_known_best_state.mat')

return;
end