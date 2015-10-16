
function [frame, PEEQ, Mises, Press, Inv3] ...
              = fetchOdbIntPtData(fileID, IntPtNodeSet)
% this function executes a Python script and reads a CSV file to obtain
% field output data. Will return the abaqus frame values (pseudo-time), and
% integration point data (PEEQ, Mises, Pressure, Inv3) from IntPtNodeSet

%set the name of the ODB file
odbName = [fileID, '.odb'];

%
% write python file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

% define python file
pyfile = fopen(strcat(fileID,'.py'),'w','n');
fprintf(pyfile,'#automatically written by fetchODBdata.m\n\n');

%must import the custom odbFetchFieldOutput functions
fprintf(pyfile,'from odbFetchFieldOutput import * \n\n');


%for convenience, define string input variables
fprintf(pyfile,'odbName = ''%s''\n',odbName);
fprintf(pyfile,'IntPtNodeSet = ''%s''\n',IntPtNodeSet);

% integration point data is requested
fprintf(pyfile,'getNodalPEEQ(odbName, IntPtNodeSet, False)\n');
fprintf(pyfile,'getNodalMises(odbName, IntPtNodeSet, False)\n');
fprintf(pyfile,'getNodalPressure(odbName, IntPtNodeSet, False)\n');
fprintf(pyfile,'getNodalInv3(odbName, IntPtNodeSet, False)\n');

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

PEEQ  = csvread([fileID,'_',IntPtNodeSet,'_PEEQ.csv'],2,1);
Mises = csvread([fileID,'_',IntPtNodeSet,'_MISES.csv'],2,1);
Press = csvread([fileID,'_',IntPtNodeSet,'_PRESS.csv'],2,1);
Inv3  = csvread([fileID,'_',IntPtNodeSet,'_INV3.csv'],2,0);
Inv3  = Inv3(:,2);
frame = Inv3(:,1); %Abaqus frame value (i.e. pseudo-time)

%
% clean up files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

delete(strcat(fileID,'.py'));
delete([fileID,'_',IntPtNodeSet,'_*.csv']);

end