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
                    
                    % rudimentary check on the output database
                    d = dir([fileNames{i} '.odb']);
                    if d.bytes>1000000
                        % seems okay, this job completed successfully.
                        flags(i) = 2;
                    else
                        % something not right, try to resubmit the job.
                        flags(i) = 0;
                        disp('something wrong, trying again')
                    end
                end
                
            otherwise
                % implies flags(i) == 2
                % so, this job has completed successfully.
                % do nothing.
        end
    end
    
    pause(10)
    
    if ~isequal(flags,lastFlags)
        % if any of the flags have changed, display flags to command window
        % along with tic-toc, and update lastFlags
        fprintf(1,'%1.0f.', flags'); toc;
        lastFlags=flags;
    end
    
end