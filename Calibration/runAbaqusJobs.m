% This function keeps track of and submits ABAQUS jobs. It will
% load-balance the jobs so that only nconcur will run simultaneously

% fileNames is a cell array of strings
% nconcur is an integer indicating how many jobs to run simultaneously
function runAbaqusJobs(fileNames, nconcur)

%keep track of runtime
tic

% keep track of number of currently running jobs
numRunning = 0;

% total number of jobs that need to be run
numFiles = length(fileNames);

%initialize
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
                    % completed.
                    numRunning = numRunning - 1;
                    
                    % try to check if the job has completed successfully
                    d = dir([fileNames{i} '.odb']);
                    if d.bytes>1000000
                        % seems okay based on size
                        flags(i) = 2;
                        
                        % now, check to see if the job has aborted.
                        % open log file
                        logfile = fopen([fileNames{i} '.log']);
                        
                        % scan to obtain the strings in the log file
                        logstr  = textscan(logfile,'%s');
                        
                        % after scan, close log file
                        fclose(logfile);
                        
                        % the last string will indicate if Abaqus exited
                        % with errors.
                        if strcmpi(logstr{1}(end),'errors')
                            % this means that the abaqus job has aborted.
                            % To fix this issue, it would require user
                            % intervention, so keep flags(i) = 2 (so search
                            % can continue), but warn the user.
                            warning( 'Job %s aborted with errors!', ...
                                                             fileNames{i} )
                        end
                        
                    else
                        % something not right, try to resubmit the job.
                        flags(i) = 0;
                        disp('something wrong, trying again')
                    end
                end
                
            otherwise
                % implies flags(i) == 2, so this job has completed.
                % do nothing.
        end
    end
    
    % check each job every 10 seconds
    pause(10)
    
    if ~isequal(flags,lastFlags)
        % if any of the flags have changed, display flags to command window
        % along with tic-toc, and update lastFlags
        fprintf(1,'%1.0f.', flags'); toc;
        lastFlags=flags;
    end
    
end