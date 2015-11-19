% This function passes back the error, error Ratio, Abaqus 
% Force-Displacement data, and "relevant" indices which were counted.
%
% defined error cases:
%   1: include elastic displacement, total dissipated energy
%   2: include elastic displacement, total energy flux
%   3: exclude elastic displacement, total energy flux
%   4: rainflow type cycles only, total energy flux
%
% This is mainly just copied from Chris' original code, with some comments
% added in. Error case 4 is what is recommended in his paper.
% Some questions that still remain about Chris' code: 
%   (1) The paper states that the plastic displacement history is used 
%       rather than total displacement history, but that is not reflected 
%       in the code for error case 4.
%   (2) The paper states that the integrals are only evalueated for the
%       first two half-cycles which exceed the previous displacement
%       extrema, but the code additionally includes the first 2 full-cycles
%       as well (that part is not mentioned in the paper).

function [err, errRatio, forceDispl, timeStepsToCount] = ...
                calcResidualError(fileID, realdata, errortype, rxNodeSet)

% warn user that the errortype 4 is recommended... as that is what is
% documented in the original paper.
persistent WHANDLE 

if (errortype ~=4) && isempty(WHANDLE)
    %only create msgbox if one has not been created yet
	msgbox_ = sprintf('Warning: Error Type %i Not Recommended',errortype);
    msgbox(msgbox_,'Warning','warn');
    WHANDLE = true;
end
            
% obtain force-displacement data from Abaqus
[frame, RF2, U2] = fetchOdbLoadDispl(fileID, rxNodeSet);

% reshape into storage array for output
forceDispl = [frame, RF2, U2];

% obtain subset of realData which aligns with U2. This only works if the
% real data is more finely discretized than the FEM data
[DisplOut, ForceOut, through] = fdinterp(U2, realdata(:,1), realdata(:,2));

% assign variables for readability
abqForce  = RF2( 1:length(ForceOut) );
abqDispl  = U2( 1:length(DisplOut) );
realForce = ForceOut;

%
% calculate error ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
switch errortype
    case 1
        % include elastic displacement, total dissipated energy
        displ    = DisplOut;
        err      = abs( [0; diff(displ)]' ) * abs( abqForce - realForce );
        errRatio = err/(([0; diff(realdata(:,1))])'*(realdata(:,2)));
        
        timeStepsToCount = 1:length(errRatio);
        
    case 2
        % include elastic displacement, total energy flux
        displ    = DisplOut;
        err      = abs( [0; diff(displ)]' ) * abs( abqForce - realForce );
        errRatio = err/(abs([0; diff(realdata(:,1))])'*abs(realdata(:,2)));
        
        timeStepsToCount = 1:length(errRatio);
        
    case 3
        % exclude elastic displacement, total energy flux
        
        %find elastic region using LSQ polynomial fit to determine modulus
        maxElastic = find(realdata(:,2)>2, 1);
        pfit = polyfit(realdata(1:maxElastic,1),realdata(1:maxElastic,2),1);
        
        %subtract off elastic displacement, calc error
        displ    = DisplOut - ForceOut/pfit(1);
        err      = abs( [0; diff(displ)]' ) * abs( abqForce - realForce );
        errRatio = err/(abs([0; diff(realdata(:,1))])'*abs(realdata(:,2)));
        
        timeStepsToCount = 1:length(errRatio);
        
    case 4
        % rainflow-type cycles only, total energy flux
        
        % determine eligibile history: first two full cycles, then any half
        % cycles which exceed the previous maximum
        
        %initialize
        cycleNum   = 1;         % number of half cycles counted
        cycleStart = 1;         % cycle's starting index
        maxDispl   = 0;         % maximum displacement so far
        minDispl   = 0;         % minimum displacement so far
        timeStepsToCount = [];  % list of indices which we want to include
        
        for i = 1:length(abqForce)
            % for entire length of history
            
            % check for peaks
            if i == 1
                % skip
                isPeak = false;
            elseif i == length(abqDispl)
                % consider the last cycle a peak
                isPeak = true;                
            else
                dl = abqDispl(i)   - abqDispl(i-1);
                dr = abqDispl(i+1) - abqDispl(i);
                isPeak = ( dl*dr <= 0 ) && ( dl ~= 0 );
            end
            
            if isPeak
                % set this cycle's indices
                cycleEnd = i;
                cycleInd = cycleStart:cycleEnd;

                % check if cycle is qualified 
                % (i.e. if first 2 full cycles, or exceeds extrema)
                if (cycleNum <= 4) || ...   %4 since these are half cycles
                       (abqDispl(i) > maxDispl) || (abqDispl(i) < minDispl)
                    % then cycle is qualified
                    
                    % set new extrema criteria
                    maxDispl = max(maxDispl, abqDispl(i));
                    minDispl = min(minDispl, abqDispl(i));
                    
                    timeStepsToCount = [timeStepsToCount cycleInd]; %#ok<AGROW>
                end
                
                % if it is a peak, but not qualified, then timeStepsToCount
                % is not appended and the cycleStart index is moved up to
                % exclude this cycle
                cycleNum   = cycleNum + 1;
                cycleStart = i + 1;
                
            end
        end
        
        
        displ = DisplOut;
        
        errhist    = abs( [0; diff(displ)] ).*abs( abqForce - realForce );
        subErrHist = errhist(timeStepsToCount);
        err        = sum(subErrHist);
        
        totEnergyHist = (abs([0; diff(DisplOut)]).*abs(ForceOut));
        normalizer    = sum(totEnergyHist(timeStepsToCount));
        errRatio      = err / normalizer;

    otherwise
        error('Unknown error-type requested!')
end


if through == 0
    err = 10*err;
    disp(['Not through:' fileID])
end

end





