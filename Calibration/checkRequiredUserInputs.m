% Vincente Pericoli
% UC Davis
% 11/30/15


function checkRequiredUserInputs(tests, testnames)
% Checks that the tests you want to run have all of the required fields.
% Also checks to see if your python path to abaqus-odb-tools is defined
% properly and can execute.

%
% define the required fields
%
required_fields = {'force', 'displ', 'cyclic', 'template', 'history', ...
                   'symmetric', 'rxNodeSet'};

%
% for each testname, check for all required fields
%
missing_fields = struct();

for i = 1:length(testnames)
    % for all testnames
    for r = 1:length(required_fields)
        % for all required fields
        if ~isfield(tests.(testnames{i}),required_fields{r})
            % then this field is missing, alert the user
            fprintf('%s: missing required field %s!\n', testnames{i}, ...
                                                        required_fields{r})
            % save to a variable
            if isfield(missing_fields, testnames{i})
                % then this testname is missing multiple fields, append.
                missing_fields.(testnames{i}){end+1} = required_fields{r};
            else
                % this is the first missing field of this testname.
                missing_fields.(testnames{i}) = required_fields(r);
            end
        end
    end
end

if ~isempty(fieldnames(missing_fields))
    % then one or more testnames are missing some fields.
    
    % save the missing_fields struct to the base workspace
    assignin('base', 'missing_fields', missing_fields)
    
    % alert the user and error-out
    error(['The input struct is missing some required fields--', ...
           'see missing_fields for more info.']);
end

%
% Now, check to see if the defined template input files exist
%

% obtain directory listing of input files (output is awkward structure)
inpFiles = dir('*.inp');
% convert this awkward structure into a cell
inpFileCell = cell(size(inpFiles));
for i = 1:length(inpFiles)
    inpFileCell{i} = inpFiles(i).name;
end

% for each testname, check the validity of the input file template
missing_files = {};

for i = 1:length(testnames)
    % for all testnames
    
    if all( strcmp(inpFileCell, tests.(testnames{i}).template) == 0)
        % then the defined template does not exist!
        missing_files{end+1} = tests.(testnames{i}).template; %#ok<AGROW>
    end 
end

if ~isempty(missing_files)
    % then one or more input files are missing or ill-defined
    
    % save the missing_files cell to the base workspace
    assignin('base', 'missing_files', missing_files)
    
    % alert the user and error-out
    error(['Some of the defined template input files do not exist ', ...
           'in the current directory!']);
end


%
% Now, try to execute the python function file, to see if it works.
%
status = system('abaqus python odbFetchFieldOutput.py');
if status ~= 0
    % then something went wrong.
    error(['Error in odbFetchFieldOutput.py.\n', ...
           'Check to see if your abaqus-odb-tools directory is'...
           ' correctly degined.']);
end

end