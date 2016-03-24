function writeHistINPfile(template, target, testdata)
% This function replicates an input file, and inserts it's own *Static and
% *Amplitude keywords (based on test displacement history).
% template = input file to replicate
% target   = output filename
% testdata = MATLAB struct. See documentation

%
% set the total time and step sizes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
if testdata.cyclic
    % set each peak to be 0.1 of total time
    peak_inc  = 0.1;
    totaltime = ( length(testdata.history)-1 ) * peak_inc;
    % this was set to mimic Chris' initial settings... since the
    % initial step is set to 0.001, it seems that there would be 100
    % steps per cycle (or more, if required for convergence)
    init_step = 0.005;
    max_step  = 0.005;
else
    % set step sizes so that there are 1000 total steps for the pull
    peak_inc  = 1.0;
    totaltime = 1.0;
    init_step = 0.001;
    max_step  = 0.001;
    % these settings were chosen in accordance with convergence and
    % stability observations from Vince's unnotched axisymmetric
    % models.
end

%
% set the displacement history (peaks) data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
if testdata.symmetric
    % if the abaqus simulation is symmetric (in addition to axisymmetric)
    % only half the displacement should be applied
    hist = testdata.history/2;
else
    hist = testdata.history;
end

%
% read from template and write to target ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

% open template file
templfid=fopen(template, 'rt');

% open target file
targfid=fopen(target, 'wt', 'n');

%initialize
tmpline='';

while ~feof(templfid)
    % loop until we reach the end of the template file
    
    if strncmpi(tmpline, '*Step, name=', 12)
        % if we encounter the Step keyword
        
        % write our desired step information
        fprintf(targfid, '*Step, name=Pull, nlgeom=YES, inc=10000\n');
        
        %get the line '*Static', and write to target
        tmpline = fgets(templfid);
        fprintf(targfid, tmpline);
        
        %get the line with the static info... throw this away
        trash = fgets(templfid); %#ok<NASGU>
        
        % write our own static info
        fprintf(targfid,'%5.4g',   init_step);   % initial step
        fprintf(targfid,', %.1f',  totaltime);   % total time
        fprintf(targfid,', %1.1e', 2.0e-7);      % min step
        fprintf(targfid,', %5.4g', max_step);    % max step
        
        fprintf(targfid,'\n');          %end line
        
        
    elseif strncmpi(tmpline, '*Amplitude, name=', 17)
        % if we encounter the Amplitude keyword
        
        % figure out what the name of that amplitude keyword is
        C = strsplit(tmpline, ', ');
        ampName = C{2}(6:end);
        ampName = strrep(ampName,sprintf('\n'),''); % strip any newlines
        
        % write our desired Amplitude information (preserve ampName)
        fprintf(targfid, ['*Amplitude, name=', ampName, '\n']);
        
        % read past any amplitude info which is defined in the template
        while ~strncmpi(tmpline,'**',2)
            tmpline = fgets(templfid);
        end
        
        % force starting displacement to be zero
        hist(1) = 0;
        
        for i = 2:length(hist)
            % for the rest of the displacements
            if hist(i-1) > hist(i)
                % round up, keeping 4 decimal places
                hist(i) = ceil(hist(i)*10000)/10000;
            else
                % round down, keeping 4 decimal places
                hist(i) = floor(hist(i)*10000)/10000;
            end
        end
        
        % write these displacement peaks to the amplitude keyword
        for i = 1:length(hist)
            % for all displacement histories

            if (mod(i,2) == 1) && (i ~= 1)
                % if i is odd and not 1, print newline.
                % this lets you extend tabular list so multiple rows can be
                % written to one line in the input file. Abaqus can
                % seemingly fit 4 amplitude pairs on one row.
                fprintf(targfid,'\n');
            end
            
            % write two history pairs... so peaks are "maintained" for one
            % max step size (e.g. max_step)
            fprintf(targfid,' %#3.3f, %#12.9f, %#3.3f, %#12.9f', ...
                    (i-1)*peak_inc, hist(i), (i-1)*peak_inc+max_step, hist(i));
            
            if i < length(hist)
                % if we haven't printed the full history, print a comma
                % (the last entry does not get a comma)
                fprintf(targfid,',');
            end
        end
        
        % print newline
        fprintf(targfid,'\n');
        % print template line into target file (this is '**' currently)
        fprintf(targfid,tmpline);

    else
        % otherwise, copy template into target
        fprintf(targfid,tmpline);
        
    end
    
    % get next line in template
    tmpline=fgets(templfid);
end

% print last line of template into target
fprintf(targfid,tmpline);

% close files
fclose(templfid);
fclose(targfid);

end

