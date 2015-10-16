function writeParamsINPfile(basefileID,newfileID,params)
% This function writes a new input file with defined *Plastic keyword
% properties

%new parameter definition
sig0  = params(1);
Qinf  = params(2);
b     = params(3);
C     = params(4:2:end);
gamma = params(5:2:end);

%open base file
basefile = fopen([basefileID '.inp'], 'rt');

%open write file
newfile = fopen([newfileID '.inp'], 'wt', 'n');

tline='';
while ~feof(basefile)
    % loop until we reach the end of the base file
    if strncmp(tline,'*Plastic, hardening=COMBINED, datatype=PARAMETERS,',48)
        % if we reach the *Plastic keyword
        
        % write our own keyword
        fprintf(newfile,['*Plastic, hardening=COMBINED, ', ...
                         'datatype=PARAMETERS, ', ...
                         'number backstresses=%1.0f\n'],length(C));
        
        % read and throw away the current parameters
        trash = fgets(basefile); %#ok<NASGU>
        
        % write our new kinematic backstress parameters
        fprintf(newfile,'  %2.2f',sig0);
        fprintf(newfile,',   %2.2f,   %2.2f',[C;gamma]);
        fprintf(newfile,'\n');
        
        % get and write cyclic hardening line
        tline = fgets(basefile);
        fprintf(newfile,tline);
        
        % read and throw away the current parameters
        trash = fgets(basefile); %#ok<NASGU>
        
        % write our new isotropic hardening params
        fprintf(newfile,'  %2.2f,   %2.2f,   %2.2f\n',sig0,Qinf,b);
    else
        % otherwise, copy base file text into new file
        fprintf(newfile,tline);
    end
    
    % read the next line in file
    tline = fgets(basefile);
end

% print last line into new file
fprintf(newfile,tline);

% close files
fclose(newfile);
fclose(basefile);

end
