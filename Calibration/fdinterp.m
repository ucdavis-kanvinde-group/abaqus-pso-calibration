% this function seems to find which real (measured) force is associated
% with a given U2 displacement (from Abaqus)

% function written by Chris
% comments written by Vince Pericoli (otherwise left mainly untouched)

% I get a sense that using actual linear interp would not be good for
% cyclic loading, because you would "chop off" the extrema by averaging
% them with an unloading step... this would effect the error calc.
%
% Also, there might be a bug in the for i loop... continue is used
% before setting the target. Also changed output from the non-descript
% DataOut (which is deceptively named in the calling routines, S.T. the
% user thinks this returns realDispl instead of U2), to a more descriptive
% 2 vectors of ForceOut and DisplOut. Really, NEITHER of these outputs are
% "real" ... since the Displ is from ABAQUS and the realForce is assigned
% to a slightly different (nearest) x-location

function [DisplOut, ForceOut, through] = fdinterp(U2, RealDispl, RealForce)

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
        % I assume this is important to check because otherwise the routine
        % will not associate the correct force with this displacement
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
            
            % if true, associate the RealForce with target_U2 displacement
            ForceOut(i) = RealForce(j);
            DisplOut(i) = U2(i); % = target_U2
            
                        
            % variable "through" seems to be a flag that indicates if this
            % process is completed adequately... used in error calculation
            if j < 0.8*length(RealDispl)
                through = 0;
            else
                through = 1;
            end
            
            break;
        end
        
        j = j + 1;
        
        % I'm not entirely sure what the point of the next statement is.
        % What is it's purpose, why is it necessary? I doubt it will ever
        % be activated, but leaving it in because perhaps Chris encountered
        % a situation that required this...
        if j > length(RealDispl)
            ForceOut(i) = RealForce(length(RealDispl));
            DisplOut(i) = U2(length(RealDispl));
            break;
        end
        
    end
    
    if j >= length(RealDispl)
        % if we have searched to the end of RealDispl,
        % break out of for loop and return
        return
    end

end

end



            
    