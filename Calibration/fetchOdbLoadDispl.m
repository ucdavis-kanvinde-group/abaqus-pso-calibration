
function [frame, RF2, U2] = fetchOdbLoadDispl(fileID, rxNodeSet)
% this function executes a Python script and reads a CSV file to obtain
% field output data. Will return the abaqus frame values (pseudo-time), 
% RF2 and U2 from rxNodeSet.

% This will work whether your rxNodeSet is enforced as a kinematic coupling
% constraint or not.

% set the name of the ODB file
odbName = [fileID, '.odb'];

% force rxNodeSet to uppercase per ABAQUS convention
rxNodeSet = upper(rxNodeSet);

%
% write python file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

% create python file
pyfile = fopen(strcat(fileID,'.py'),'w','n');
fprintf(pyfile,'#automatically written by fetchODBdata.m\n\n');

%must import the custom odbFetchFieldOutput functions
fprintf(pyfile,'from odbFetchFieldOutput import * \n\n');

%for convenience, define string input variables
fprintf(pyfile,'odbName = ''%s''\n',odbName);
fprintf(pyfile,'rxNodeSet = ''%s''\n',rxNodeSet);

% retrieve the reaction sum (force) and displacement
fprintf(pyfile,'getNodalReactionSum(odbName, rxNodeSet, False)\n');
fprintf(pyfile,'getNodalDispl(odbName, rxNodeSet, False)\n');

%close file handle
fclose(pyfile);

%
% execute python file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

system(['abaqus python ', fileID, '.py']);
pause(2);

%
% load data from CSV files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

U2  = csvread([fileID,'_',rxNodeSet,'_U2.csv'],2,1);
RF2 = csvread([fileID,'_',rxNodeSet,'_summedRF2.csv'],2,0);
U2  = U2(:,1);
RF2 = RF2(:,2);
frame = RF2(:,1); %Abaqus frame value (i.e. pseudo-time)

%
% clean up files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

delete(strcat(fileID,'.py'));
delete([fileID,'_',rxNodeSet,'_*.csv']);

end