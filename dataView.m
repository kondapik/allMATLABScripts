%{
    DESCRIPTION:
    Imports logged test data from '<modelName>_TestHarness_data.mat' file 
    along with the data dictionary to load data type definitions  
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 22-Nov-2019
    LAST MODIFIED: 23-Nov-2019
%
    VERSION MANAGER
    v1      Imports test logs as runs in simulink data inspector 
%}

clear;

[slddName,rootPath] = uigetfile({'*.sldd','Data Dictionary (*.sldd)'},'Select model data dictionary');

if ~isequal(slddName,0)
    cd(rootPath);
    progBar = waitbar(0,regexprep(sprintf('Loading %s',slddName),'_','\\_'),'Name','View logged data to SDI');
    uiopen(slddName,1); %Opening data dictionary
    [~,OnlyModelName,~] = fileparts(slddName);
    waitbar(0.1,progBar,regexprep(sprintf('Loading %s_TestHarness_data.mat',OnlyModelName),'_','\\_'));
    load(sprintf('%s_TestHarness_data.mat',OnlyModelName)); %Loading test data 

    if exist('test_data','var') && exist('test_data_SIL','var') %Checking if both MIL and SIL data are available
        dataOption = questdlg('Select MIL Data or SIL data', ...
            'Select data to plot', ...
            'MIL','SIL','MIL');
        if isequal(dataOption,'MIL')
            plotData = test_data;
        else
            plotData = test_data_SIL;
        end
    elseif exist('test_data','var')
        dataOption = questdlg('Only MIL testing data found', ...
            'Select data to plot', ...
            'Proceed','I''ll be back','Proceed');
        if isequal(dataOption,'Proceed')
            plotData = test_data;
        end
    elseif exist('test_data_SIL','var')
        dataOption = questdlg('Only SIL testing data found', ...
            'Select data to plot', ...
            'Proceed','I''ll be back','Proceed');
        if isequal(dataOption,'Proceed')
            plotData = test_data;
        end
    end

    allSig = 0; %setting it to zero for progress bar
    if exist('plotData','var')
        Simulink.sdi.clear; %clearing all previous runs
        for caseNo = 1:length(plotData)
            %creating runs with test case ID and description
            runObj = Simulink.sdi.Run.create;
            runObj.Name = plotData(caseNo).TestCaseID;
            runObj.Description = plotData(caseNo).TestDescription;
            %disp(plotData(caseNo).TestCaseID);
            for sigNo = 1:numElements(plotData(caseNo).DataLog)
                %adding signals to (Input, Results, Expected and Actual outputs) to runs
                runObj.add('vars',plotData(caseNo).DataLog{sigNo}.Values);
                allSig = allSig+1;
                waitbar(allSig/(length(plotData)*numElements(plotData(caseNo).DataLog)),...
                    progBar,regexprep(sprintf('Inporting %s',plotData(caseNo).TestCaseID),'_','\\_'));
            end
        end
        close(progBar);
        Simulink.sdi.view; %opening simulink data inspector
    end
else
    error('WHY??????');
    %!File is not selected
end