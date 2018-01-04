% This function keeps track of and submits ABAQUS jobs. It will
% load-balance the jobs so that only nconcur will run simultaneously

% fileNames is a cell array of strings
% nconcur is an integer indicating how many jobs to run simultaneously
function runAbaqusJobs(fileNames, nconcur)

% create cleanup object. when this object is destroyed (on either normal or
% irregular function termination), the cleanup function will execute.
cleanupObj = onCleanup(@() cleanupJobs());

% total number of jobs that need to be run
numFiles = length(fileNames);

% define the error conditions
MAX_RESTART = 5;
MAX_RUNTIME = 1200 * numFiles; % 20 mins per job

% keep track of number of restarted jobs
numRestart  = 0;

% keep track of runtime
tic()

% keep track of number of currently running jobs
numRunning = 0;

% initialize
flags = zeros(numFiles,1);
lastFlags = flags;

while any(flags ~= 2)
    % while any of the jobs are not completed
    
    for i = 1:numFiles
        % for all jobs
        
        switch flags(i)
            % check the status of this job
            case 0
                % this job has not been submitted
                if numRunning < nconcur
                    % if we can submit the job, submit it
                    system(['abaqus job=' fileNames{i}]);
                    pause(4);
                    
                    if exist([fileNames{i} '.lck'], 'file')
                        % if an abaqus lock file exists, the job has
                        % submitted successfully.
                        flags(i)   = 1;
                        numRunning = numRunning + 1;
                    else
                        % otherwise, it did not submit successfully. this
                        % indicates that there are not enough available
                        % licenses to check out currently.
                        disp('No Available License')
                    end
                end
                
            case 1
                % this job has been submitted
                if ~exist([fileNames{i} '.lck'], 'file')
                    % if an abaqus lock file does not exist, the job has
                    % completed (or otherwise exited).
                    numRunning = numRunning - 1;
                    
                    % try to check if the job has completed successfully...
                    % perform two checks: 
                    % (1) check if job has aborted, (2) check ODB filesize
                    
                    % to check if job has aborted, read the log file:
                    % open log file
                    logfile = fopen([fileNames{i} '.log']);
                    % scan to obtain the strings in the log file
                    logstr  = textscan(logfile,'%s');
                    % after scan, close log file
                    fclose(logfile);
                    
                    % to check filesize, read the dir information:
                    d = dir([fileNames{i} '.odb']);
                    
                    % the last string of log file will indicate if Abaqus 
                    % exited/aborted with errors.
                    if( strcmpi(logstr{1}(end),'errors') )
                        % this means that the abaqus job has aborted.
                        % To fix this issue, it would require user
                        % intervention... halt search.
                        error('Job %s aborted with errors!',fileNames{i});
                        
                        % instead of just erroring out, the better thing to
                        % do here is to go back and adjust the initial and
                        % max step size increments to be smaller, and try
                        % again. Keep trying until MAX_RESTART is exceeded.
                        % If decreasing increment size doesn't resolve the 
                        % issue, perhaps these material parameters are 
                        % unsuitable--just return a large error. 
                        
                    elseif( d.bytes < 1000000 ) % < 1MB
                        % something not right, try to resubmit the job.
                        flags(i) = 0;
                        numRestart = numRestart + 1;
                        fprintf(2,['\nError: Job Output less than 1MB ',...
                                   'in size. Trying again.\n']);
                        
                    else
                        % seems okay. continue search.
                        flags(i) = 2;
                    end
                end
                % if .lck file still exists, then the job is still running.
                % in that case, do nothing (i.e. flags(i) remains 1)
                
            otherwise
                % implies flags(i) == 2, so this job has completed.
                % do nothing.
        end
    end
    
    % check each job every 5 seconds
    pause(5)
    
    if( ~isequal(flags,lastFlags) )
        % if any of the flags have changed, display flags to command window
        % along with tic-toc, and update lastFlags
        fprintf(1,'%1.0f.', flags'); toc();
        lastFlags=flags;
    end
    
    %
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % CHECK ERROR CONDITIONS
    %
    
    if( toc() > MAX_RUNTIME )
        % something is probably wrong.
        
        % determine which jobs are still running...
        fileNamesErr = fileNames(flags==1);
        numErr  = length(fileNamesErr);
        % print error message to user
        fprintf(2,['\nError: %i jobs have been executing for ', ...
                   '%f seconds!\n'],numErr,toc());
        
        % try to resubmit
        if( (numRestart < MAX_RESTART) && (numErr > 0) )
            fprintf(2,'Trying to resubmit jobs... \n');
            % try to kill jobs
            cleanupJobs(); pause(10);
            % kill task and restart
            KS = system('python.exe kill_abaqus.py');
            if( KS ~= 0 )
                error('taskkill failed. jobs cannot be resubmitted');
            end
            pause(5)
            % delete the job files (except input file)
            delete_all_except_inp(fileNamesErr)
            % resubmit the jobs
            flags(flags==1) = 0;
            numRestart = numRestart + numErr;
            
            % update MAX_RUNTIME so jobs can complete.
            MAX_RUNTIME = toc() + 600; % 10 minutes
        end
    end 
    
    if( numRestart > MAX_RESTART )
        error('Too many attempts to resubmit jobs. Quitting.');
    end
end

return;
end

function delete_all_except_inp(fileNames)

this_dir  = [pwd,'\'];

% loop thru filenames, deleting files and skipping .inp
for fn = 1:length(fileNames)
    % must update dir_list each time
    dir_list  = dir([this_dir, fileNames{fn}, '.*']);
    % delete all files not containing ".inp"
    del_files = {dir_list.name};
    del_files = del_files(cellfun('isempty',strfind(del_files,'.inp')));
    delete(del_files{:});
end

return;
end

function cleanupJobs()
% kill any running jobs

dir_list = dir();
Ndirs = length(dir_list);

for d = 1:Ndirs
    % skip directories
    if dir_list(d).isdir, continue; end
    
    [~,jobName,ext] = fileparts(dir_list(d).name);
    if strcmp(ext,'.lck')
        % this job is still running. send kill command.
        system(['abaqus terminate job=',jobName]);
        pause(1);
    end
end

return;
end