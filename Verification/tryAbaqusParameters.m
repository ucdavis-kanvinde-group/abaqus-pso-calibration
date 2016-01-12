% Vincente Pericoli
% UC Davis
% 12 Jan 2016

function [combinedError, errRatio] = tryAbaqusParameters...
                                                (AFparams, tests, testnums)
% Provide some Armstrong-Frederick parameters, and this function will 
% run an ABAQUS job with those parameters, and plot out the results so that
% you may visually inspect them. Furthermore, it will return the error
% ratio of that parameter set.
%
%
% bestpos   = transformed output from PSO algorithm
% bestval   = output from PSO algorithm (for informational purposes only)
% tests     = specifically designed .mat struct file containing test data
%             (see documentation)
% testnums  = subset of tests on which to run analysis, or string 'all'
% need_analysis = boolean indicating whether abaqus runs need to be
%                 submitted (default = True). Otherwise it assumes you
%                 already have run the analyses, and only want some plots.
% save_xls  = boolean indicating whether you want to save the
%             force-displacement information into an excel spreadsheet
%             (default = False)

%
% Add Calibration path to search directory, so those functions can be used.
%
calib_dir = strrep(pwd, 'Verification', 'Calibration');
addpath(calib_dir);

%
% check inputs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

% get all field names of the .mat struct
testnames = fieldnames(tests);

% check the requested inputs...
if (nargin < 3) || strcmpi(testnums,'all')
    % run all tests if not otherwise specified, or if 'all' specified
    testnums = 1:length(testnames);
end


% Run simulations, obtain error, and compare the displacement curves
%

% using AF params, run the abaqus simulations and obtain the errors.
% a warning message should occur.
[combinedError, errRatio] = getABQerrorCombined(AFparams, tests, testnums);
end