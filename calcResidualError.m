% This function passes back the error, error Ratio, field output data, and
% "relevant" indices.

% defined error cases:
%1: include elastic displacement, total dissipated energy
%2: include elastic displacement, total energy flux
%3: exclude elastic displacement, total energy flux
%4: rainflow type cycles only, total energy flux

% one issue is that "exclude elastic displacement" uses matlab LSQ polyfit
% to determine the elastic modulus... however, it is doing the best least
% squares fit to a straight line, without forcing the y-intercept to be
% zero. Furthermore, it only subtracts the initial elastic part, not the
% elastic unloading/reloading parts... perhaps that is okay.

% Note: NONE of the defined error cases were double-checked for accurracy,
% except for case 3 (the important one). The others were simply copied
% directly from Chris' code.

function [err, errRatio, forceDispl, varargout] = ...
                calcResidualError(fileID, realdata, errortype, rxNodeSet)

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
        
        
    case 2
        % include elastic displacement, total energy flux
        displ    = DisplOut;
        err      = abs( [0; diff(displ)]' ) * abs( abqForce - realForce );
        errRatio = err/(abs([0; diff(realdata(:,1))])'*abs(realdata(:,2)));
        
    case 3
        % exclude elastic displacement, total energy flux
        
        %find elastic region using LSQ polynomial fit to determine modulus
        maxElastic = find(realdata(:,2)>2, 1);
        pfit = polyfit(realdata(1:maxElastic,1),realdata(1:maxElastic,2),1);
        
        %subtract off elastic displacement, calc error
        displ    = DisplOut - ForceOut/pfit(1);
        err      = abs( [0; diff(displ)]' ) * abs( abqForce - realForce );
        errRatio = err/(abs([0; diff(realdata(:,1))])'*abs(realdata(:,2)));
        
    case 4
        % rainflow type cycles only, total energy flux (written by Chris)
        
        % determine eligibile history: first two full cycles, plus any half
        % cycles which exceed the previous maximum
        cycleNum   = 1;
        cycleStart = 1;
        maxDispl   = 0;
        minDispl   = 0;
        timeStepsToCount = [];
        
        for i = 1:length(abqForce)
            % for entire length of history
            
            %check for peaks
            if i == 1
                isPeak = false;
            elseif i == length(abqDispl)
                isPeak = true;                
            else
                dl = abqDispl(i)   - abqDispl(i-1);
                dr = abqDispl(i+1) - abqDispl(i);
                isPeak = ( dl*dr <= 0 ) & ( dl ~= 0 );
            end
            
            if isPeak
                cycleEnd = i;
                cycleInd = cycleStart:cycleEnd;

                %check if cycle is qualified
                if (cycleNum <= 4) || ...   %these are half cycles
                       (abqDispl(i) > maxDispl) || (abqDispl(i) < minDispl)

                    maxDispl = max(maxDispl, abqDispl(i));
                    minDispl = min(minDispl, abqDispl(i));
                    
                    timeStepsToCount = [timeStepsToCount cycleInd]; %#ok<AGROW>
                end
                
                cycleNum   = cycleNum + 1;
                cycleStart = i + 1;
                
            end
        end
        
        
        displ = DisplOut;
        
        errhist    = abs( [0; diff(displ)] ).*abs( abqForce - realForce );
        suberrhist = errhist(timeStepsToCount);
        err        = sum(suberrhist);
        
        totEnergyHist = (abs([0; diff(DisplOut)]).*abs(ForceOut));
        normalizer    = sum(totEnergyHist(timeStepsToCount));
        errRatio      = err / normalizer;
        
        varargout{1} = timeStepsToCount;
        
    otherwise
        error('Unknown error-type requested!')
end


if through == 0
    err = 10*err;
    disp(['Not through:' fileID])
end

end





