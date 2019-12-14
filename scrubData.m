%{

%
    DESCRIPTION:
	Scrubs failed results
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 19-Sep-2019
    LAST MODIFIED: 11-Nov-2019
%
    VERSION MANAGER
    v1      Panel with input and output table
            Buttons to reset, wait standby, prepare charge and charge modes
            Feedback loop for switch S2 and plug lock commands
%}

[DataName,rootPath] = uigetfile({'*.mat','MAT file (*.mat)'},'Select test data file');
