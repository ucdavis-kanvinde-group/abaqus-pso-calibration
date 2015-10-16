% this function seems to find which real (measured) force is associated
% with a given U2 displacement (from Abaqus)

% function written by Chris
% comments written by Vince Pericoli (otherwise left mainly untouched)

% update 21 Aug 2015: Vince adapted function to use linear interpolation
% instead of simply assuming acceptably discrete values. Need to
% double-check how this funciton is used in the context of the main
% program. There might be a bug in the for i loop... continue is used
% before setting the target. Also changed output from the non-descript
% DataOut (which is deceptively named in the calling routines, S.T. the
% user thinks this returns realDispl instead of U2), to a more descriptive
% 2 vectors of ForceOut and DisplOut. Really, NEITHER of these outputs are
% "real" ... since the Displ is from ABAQUS and the realForce is an
% interpolated value
function [DisplOut, ForceOut, through] = fdinterp(U2,RealDispl,RealForce)

% preallocate
%DataOut(1,:) = [RealDispl(1), RealForce(1)];
ForceOut = zeros(size(U2));
DisplOut = ForceOut;

% initialize values
j = 1;
ForceOut(1) = RealForce(1);
DisplOut(1) = RealDispl(1);

% set target_U2 for identifying next force in the array
target_U2 = U2(1);

for i = 2:length(U2)
    %for all of U2
    if target_U2 == U2(i)
        % if U2(i) = U2(i-1)
        % then current displ = prev. displ... so, take the same force.
        % this is important to check because otherwise the routine will
        % not associate the correct force with this displacement
        ForceOut(i) = ForceOut(i-1);
        DisplOut(i) = DisplOut(i-1);
        continue
    end
    
    % might be a bug here... if the previous conditional statement is true,
    % then the loop continues without setting the next target. maybe this
    % is okay? above conditional statement actually might just be a hack to
    % get around the first and second values being the same.. i.e.
    % realDispl(1) = realDispl(2) = 0... or maybe it never comes true
    % anyway, so has not presented any issues.
    target_U2 = U2(i);
    
    while j < length(RealDispl)
        %for all of the real data
        if sign( RealDispl(j) - target_U2 ) ~= sign( RealDispl(j+1) - target_U2 )
            % check if target_U2 is between RealDispl(j+1) and RealDispl(j)
            
            % if true, interpolate to find the RealForce associated with 
            % target_U2 displacement
            slope = (RealForce(j+1) - RealForce(j)) / ...
                    (RealDispl(j+1) - RealDispl(j));
            ForceOut(i) = slope*(target_U2 - RealDispl(j)) + RealForce(j);
            DisplOut(i) = U2(i); % = target_U2
            
                        
            % variable "through" seems to be a flag that indicates if this
            % process is completed adequately... used in error calculation
            if j < 0.8*length(RealDispl)
                through=0;
            else
                through=1;
            end
            
            break;
        end
        
        j = j + 1;
    end
    
    if j >= length(RealDispl)
        % if we have searched to the end of RealDispl,
        % break out of for loop and return
        return
    end

end

end



            
    