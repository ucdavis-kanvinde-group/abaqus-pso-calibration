% Vincente Pericoli
% UC Davis
% 11/30/15


function checkRequiredFields(tests, testnames)
% Checks that the tests you want to run have all of the required fields

%
% define the required fields
%
required_fields = {'force', 'displ', 'cyclic', 'template', 'history', ...
                   'symmetric', 'rxNodeSet'};

%
% for each testname, check for all required fields
%

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

if exist('missing_fields','var')
    % if the missing_fields variable exists, then one or more testnames are
    % missing some fields.
    
    % save the missing_fields struct to the base workspace
    assignin('base', 'missing_fields', missing_fields)
    
    % alert the user and error-out
    error(['The input struct is missing some required fields--', ...
           'see missing_fields for more info.'])
end

end