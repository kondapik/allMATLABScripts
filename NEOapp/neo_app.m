%{
%
    DECRIPTION:
    Creates harness for an AUTOSAR compliant model with a data dictionary 
    and an excel sheet to fill test case data(Testcase ID, Inputs and Expected Outputs).
    Signal builder contains all test cases and test results will updated in excel.
  
    (Note: Input 'text' for Enums not integer value)
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 19-Aug-2019
    LAST MODIFIED: 19-Jul-2020
%
    VERSION MANAGER 
    v1      Frame model generation [arxml_frame_GUI.m(v4)] and testing [Testing_GUI.m(v4)] features are included
    v1.1	Testcase ID and description of SLDV test cases updated
    		Fix: Error in importing SLDV expected outputs
            Fix: First row of outputs are not updated in Excel
            Class name changed to neo_app
            Disables code generation report when SIL testing
            Patch: Error handling in report generation
            Fix: SLDV single input issue fixed
    v1.2	Extra variables are not saved in MAT file(eliminates Data dictionary and app warnings)
    		Handling of global configurations via .m file
            Patch: Updated status and button text for 'Generating files'
            Patch: Model name is not removed when model is not selected
            Patch: Updated progress bat messages while resetting signal builder
            Patch: Model name is visible when Update model option is disabled
            Fix: Updating caughtError to 0 before checking of enableGC in updateParam
    v1.3    Testing using 'Fast Restart' to avoid model compiling for every test case
            Updating results using vectorization to improve efficiency
            Aligning signal builder with model reference and other blocks
            Enabled coverage report for MIL testing
    v1.3.1  Model version will be displayed when a model is opened
            Model version of source model will be updated when text box is updated
            Model version of harnesses will be updated when running tests or generating reports
            Model version will can be edited when test operations are not running
    v1.4    Added a function generator per runnable with its sampleTime
            Added simulink functions and 'virtual ports' to create client-server interface
    v1.4.1  Fix: Importing signal time and expected outputs of SLDV test cases
    v1.4.2  Fix: Updated function caller inport and outport names to include function name
    v1.4.3  Fix: Removed an artifact of 'Update Test cases' in signal builders
            Patch: Updated report generation mechanism to generate it twice in order to remove blank input plot
            Patch: Checking if input and output specification of function caller is an enum
    v1.5    Update: Included mechanism to test bus signals
            Update: Resampling simulink logs to fit longest time series(incase of runnables with different sample times)
            Update: checking the version of the data saved before testing
            Patch: Replaced '_Expected','_Result' and '_Actual' with '_Exp','_Res' and '_Act' to reduce signal length
    v1.5.1  Patch: Replaced use of matfile function with load and save functions to avoid data corruption
    v1.5.2  Update: Adding support for simulink datatypes for error ports without application datatypes 
%}

classdef neo_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NEO                           matlab.ui.Figure
        Features                      matlab.ui.container.TabGroup
        Testing                       matlab.ui.container.Tab
        OpenTESTButton                matlab.ui.control.Button
        CreateExcel                   matlab.ui.control.CheckBox
        ExecuteTEST                   matlab.ui.control.Button
        StatusTESTLabel               matlab.ui.control.Label
        UpdateHarness                 matlab.ui.control.CheckBox
        UpdateCases                   matlab.ui.control.CheckBox
        ModelNameEditFieldLabel       matlab.ui.control.Label
        ModelNameEditField            matlab.ui.control.EditField
        TestingPanel                  matlab.ui.container.Panel
        RunTests                      matlab.ui.control.CheckBox
        MILReport                     matlab.ui.control.CheckBox
        Panel                         matlab.ui.container.Panel
        ModelVersionEditFieldLabel    matlab.ui.control.Label
        ModelVersionEditField         matlab.ui.control.EditField
        AUTOSARButton                 matlab.ui.control.StateButton
        ThisisanLabel                 matlab.ui.control.Label
        modelLabel                    matlab.ui.control.Label
        RunSIL                        matlab.ui.control.CheckBox
        SLDVButton                    matlab.ui.control.StateButton
        SILReport                     matlab.ui.control.CheckBox
        ARXML                         matlab.ui.container.Tab
        OpenARXMLButton               matlab.ui.control.Button
        ExecuteARXML                  matlab.ui.control.Button
        StatusARXMLLabel              matlab.ui.control.Label
        UpdateModel                   matlab.ui.control.CheckBox
        ButtonGroup                   matlab.ui.container.ButtonGroup
        ApplicationButton             matlab.ui.control.ToggleButton
        SensorActuatorButton          matlab.ui.control.ToggleButton
        CompositionsButton            matlab.ui.control.ToggleButton
        ComponentsLabel               matlab.ui.control.Label
        SelectModelButton             matlab.ui.control.Button
        SelectcomponentDropDownLabel  matlab.ui.control.Label
        SelectcomponentDropDown       matlab.ui.control.DropDown
        NameofarxmlLabel              matlab.ui.control.Label
        NameofarxmlField              matlab.ui.control.EditField
        NameofmodelLabel              matlab.ui.control.Label
        Nameofmodel                   matlab.ui.control.EditField
    end

    
    properties (Access = private)
        %Common properties
        ModelName
        OnlyModelName
        
        %Frame generation properties
        arxml_name % Description
        arxml_path
        ModelPath
        comp_name % Description
        arObj
        sel_cmpt
        AppCompts
        SACompts
        Comps
        AllNames
        simDataTypes
        
        %testing properties
        rootPath
        harness_name_MIL
        harness_name_SIL
        Create_excel
        dataMatfile
        port_data
        no_inports
        no_rnbls
        no_outports
        test_data
        test_data_SIL
        option_value
        AUTOSAR_stat
        errorFlag
        optionsMap
        timeOffset
        allSLDV
        timeStep
        enableGC
        gConf
        funcData
        no_func
        no_funcInp
        no_funcOut
        neoVersion = '1.5';
        enableTest;
    end
    

    methods (Access = private)

        % Code that Executes after component creation
        function startupFcn(app)
            evalin('base','clear');
            keys = {'00000001','00000000','00000010','00000100','00001000','00001010','00001100','00010000','00010010','00010100','00011000','00011010','00011100','00100000','00100010','00100100','00101000','00101010','00101100','00110000','00110010','00110100','00111000','00111010','00111100','01000000','01001000','01001010','01001100','01010000','01010010','01010100','01011000','01011010','01011100','01100000','01101000','01101010','01101100','01110000','01110010','01110100','01111000','01111010','01111100','10000000','10001000','10001010','10001100','10010000','10010010','10010100','10011000','10011010','10011100','10100000','10101000','10101010','10101100','10110000','10110010','10110100','10111000','10111010','10111100','11000000','11001000','11001010','11001100','11010000','11010010','11010100','11011000','11011010','11011100','11100000','11101000','11101010','11101100','11110000','11110010','11110100','11111000','11111010','11111100','00100001'};
            values = {'Generate test files''^^^''Creates test case Excel, frame harness and global config file''^^^''on','Not an option''^^^''Select something, I have to get back to work.''^^^''off','Complete harness''^^^''Extract data from excel and updates harness''^^^''on','Update test cases''^^^''Updates signal builder with new test cases from excel''^^^''on','Execute MIL test''^^^''Executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates harness, executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates test cases, executes MIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Executes SIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Updates harness, executes SIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Updates test cases, executes SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Not an option''^^^''Select something, I don''t have much time''^^^''off','Complete harness''^^^''Extract data from excel and updates harness''^^^''on','Update test cases''^^^''Updates signal builder with new test cases from excel''^^^''on','Execute MIL test''^^^''Executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates harness, executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates test cases, executes MIL & updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Executes SIL with SLDV & updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates harness, executes SIL with SLDV & updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates test cases, executes SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate MIL report''^^^''Generates MIL report''^^^''on','Execute MIL test & generate report''^^^''Executes MIL, updates results in Excel & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates harness, executes MIL, updates results in Excel  & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates test cases, executes MIL, updates results in Excel  & generates report''^^^''on','Execute SIL test & generate MIL report''^^^''Executes SIL, updates results in Excel & generates MIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates MIL report''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate MIL report''^^^''Generates MIL report''^^^''on','Execute MIL test & generate report''^^^''Executes MIL, updates results in Excel & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates harness, executes MIL, updates results in Excel  & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates test cases, executes MIL, updates results in Excel & generates report''^^^''on','Execute SIL test & generate MIL report''^^^''Executes SIL, updates results in Excel & generates MIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate SIL Report''^^^''Generates SIL report''^^^''on','Execute MIL test & generate SIL report''^^^''Executes MIL, updates results in Excel & generates SIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate report''^^^''Executes SIL, updates results in Excel & generates report''^^^''on','Execute SIL test & generate report''^^^''Updates harness, executes SIL, updates results in Excel  & generates report''^^^''on','Execute SIL test & generate report''^^^''Updates test cases, executes SIL, updates results in Excel  & generates report''^^^''on','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates SIL report''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate SIL report''^^^''Generates SIL report''^^^''on','Execute MIL test & generate SIL report''^^^''Executes MIL, updates results in Excel & generates SIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL with SLDV''^^^''Executes SIL with SLDV, updates results in Excel & generates SIL report''^^^''on','Execute SIL with SLDV''^^^''Updates harness, executes SIL with SLDV& updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates test cases, executes SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV updates results in Excel & generates report''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate MIL & SIL reports''^^^''Generate MIL & SIL reports''^^^''on','Execute MIL test & generate reports''^^^''Executes MIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate reports''^^^''Executes SIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate MIL & SIL reports''^^^''Generates MIL & SIL reports''^^^''on','Execute MIL test & generate reports''^^^''Executes MIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate reports''^^^''Executes SIL with SLDV, updates results in Excel & generates reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV updates results in Excel & generates reports''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Create Excel''^^^''Creates test case Excel and frame harness''^^^''on'};
            app.optionsMap = containers.Map(keys,values);
            app.simDataTypes = {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','boolean'};
        end

        %
        % Testing functions

        % Button pushed function: OpenTESTButton
        function OpenTESTButtonPushed(app, event)
            [app.ModelName,app.rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to test');
            app.StatusTESTLabel.FontColor = [0 0 0];
            %app.NEO
            figure(app.NEO);
            if isequal(app.ModelName,0)
                app.ExecuteTEST.Text = 'Select';
                app.StatusTESTLabel.Text = 'Select model to test';
                app.ExecuteTEST.Enable = 'off';
                app.ModelNameEditField.Value = '';
                app.ModelVersionEditField.Editable = 'off';
                app.ModelVersionEditField.Value = '';
            else
                prog_stat = uiprogressdlg(app.NEO,'Title','Loading model',...
                            'Message',sprintf('Loading ''%s'' model',app.ModelName),'Indeterminate','on');
                drawnow
                cd(app.rootPath);
                [~,app.OnlyModelName,~] = fileparts(app.ModelName);
                app.harness_name_MIL = sprintf('MIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.harness_name_SIL = sprintf('SIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.ExecuteTEST.Text = 'Select';
                app.StatusTESTLabel.Text = 'Select one or more options';
                app.ModelNameEditField.Value = app.ModelName;
                updateStatus(app);
                app.ModelVersionEditField.Editable = 'on';
                
                %finding model version
                loadModel(app, app.OnlyModelName);
                app.ModelVersionEditField.Value = get_param(app.OnlyModelName,'ModelVersionFormat');
                close(prog_stat);

                if exist(sprintf('%s_TestHarness_data.mat',app.OnlyModelName))
                    matNames = who('-file', sprintf('%s_TestHarness_data.mat',app.OnlyModelName));
                    matVariables = load(sprintf('%s_TestHarness_data.mat',app.OnlyModelName));
                    if ~ismember('neoVersion', matNames) || ~isequal(matVariables.neoVersion, app.neoVersion)
                        uialert(app.NEO,'Testing files are outdated. Regenerate all testing files.','Error');
                        app.StatusTESTLabel.Text = 'Testing files are outdated. Regenerate all testing files.';
                        app.enableTest = false;
                    else
                        app.enableTest = true;
                    end
                end
            end
        end

        % updateStatus
        function updateStatus(app)
            valid_run = 'off';

            % treating check box values as binary
            % MSB SILReport MILReport SLDVButton RunSIL RunTests UpdateCases UpdateHarness CreateExcel LSB -> followed

            %app.option_value = (app.CreateExcel.Value*(10^0))+(app.UpdateHarness.Value*(10^1))+(app.UpdateCases.Value*(10^2))+(app.RunTests.Value*(10^3))...
            %   +(app.RunSIL.Value*(10^4))+(app.SLDVButton.Value*(10^5))+(app.MILReport.Value*(10^6))+(app.SILReport.Value*(10^7));

            app.option_value = sprintf('%d%d%d%d%d%d%d%d',app.SILReport.Value,app.MILReport.Value,app.SLDVButton.Value,app.RunSIL.Value,...
                app.RunTests.Value,app.UpdateCases.Value,app.UpdateHarness.Value,app.CreateExcel.Value);

            app.StatusTESTLabel.FontColor = [0 0 0];
            app.ExecuteTEST.Text = 'Not an option';
            if app.CreateExcel.Value == 1 && (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1) || isequal(app.RunTests.Value,1) || isequal(app.RunSIL.Value,1)...
                    || isequal(app.MILReport.Value,1) || isequal(app.SILReport.Value,1))        
                app.StatusTESTLabel.Text = 'Combination doesn''t work. I cannot simulate model without TC';
            elseif isequal(app.UpdateHarness.Value,1) && isequal(app.UpdateCases.Value,1)
                app.StatusTESTLabel.Text = 'Deselect, either ''Complete harness'' or ''Update Test cases''';
            elseif (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1)) && (isequal(app.RunTests.Value,0) && isequal(app.RunSIL.Value,0))...
                && (isequal(app.MILReport.Value,1) || isequal(app.SILReport.Value,1))
                app.StatusTESTLabel.Text = 'Doesn''t work, cannot generate report(s) without testing';
            end

            try
                dispText = app.optionsMap(app.option_value);
                splits = strsplit(dispText,'^^^');
                tempText = splits{1,1};
                app.ExecuteTEST.Text = tempText(1:end-1);
                tempText = splits{1,2};
                app.StatusTESTLabel.Text = tempText(2:end-1);
                tempText = splits{1,3};
                valid_run = tempText(2:end);
            catch
                %fprintf(2,'Error: %s\n',ErrorCaught.message);
            end

            if isequal(app.ModelName,0) || isempty(app.ModelName)
                app.ExecuteTEST.Text = 'Select';
                app.StatusTESTLabel.Text = 'Select model to test';
                valid_run = 'off';
            end
            app.ExecuteTEST.Enable = valid_run;
            drawnow
        end

        % Value changed function: CreateExcel
        function CreateExcelValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: UpdateHarness
        function UpdateHarnessValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: UpdateCases
        function UpdateCasesValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: RunTests
        function RunTestsValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: MILReport
        function MILReportValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: RunSIL
        function RunSILValueChanged(app, event)
            updateStatus(app); %RunSIL
        end

        % Value changed function: SILReport
        function SILReportValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: AUTOSARButton
        function AUTOSARButtonValueChanged(app, event)
            if app.AUTOSARButton.Value == 0
                app.AUTOSARButton.Text = 'AUTOSAR';
                app.ThisisanLabel.Text = 'This is an';
                app.AUTOSARButton.BackgroundColor = [0 .9 0];
                app.AUTOSAR_stat = 1;
                app.RunSIL.Enable = 'on';
                app.SLDVButton.Enable = 'on';
                app.SILReport.Enable = 'on';
            else
                app.AUTOSARButton.Text = 'Non AUTOSAR';
                app.ThisisanLabel.Text = 'This is a';
                app.AUTOSARButton.BackgroundColor = [1 1 0];
                app.AUTOSAR_stat = 0;
                app.SILReport.Value = 0;
                app.RunSIL.Value = 0;
                app.RunSIL.Enable = 'off';
                app.SLDVButton.Enable = 'off';
                app.SILReport.Enable = 'off';
            end
            drawnow
        end

        % Value changed function: SLDVButton
        function SLDVButtonValueChanged(app, event)
            if app.SLDVButton.Value == 0
                app.SLDVButton.Text = 'Without SLDV';
            else
                app.SLDVButton.Text = 'With SLDV';
            end
            updateStatus(app);
            drawnow
        end

        % Value changed function: ModelVersionEditField
        function ModelVersionEditFieldValueChanged(app, event)
            prog_stat = uiprogressdlg(app.NEO,'Title','Loading model',...
                            'Message',sprintf('Loading ''%s'' model',app.ModelName),'Indeterminate','on');
            drawnow
            loadModel(app, app.OnlyModelName);
            set_param(app.OnlyModelName,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
            save_system(app.OnlyModelName);
            close(prog_stat);
            drawnow
        end

        % Create Excel and frame harness
        function CreateExcel_Data(app,DataDictionary,DataDictSec)
            try
                errorCode = 1; %Error in creating harness
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','Creating test case Excel',...
                            'Message','Creating test harness','Indeterminate','on');
                drawnow

                app.port_data = struct('Name',{},'OutDataType',{},'BaseDataType',{},'Position',{},'Handle',{},'Values',{},'FunctionName',{},'BusName',{},'BusDataType',{},'NoBusElm',{},'defValue',{});
                %add_block('simulink/Signal Attributes/Data Type Conversion','OutDataTypeStr','AliasType or Enum: <classname>');
                save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'errorCode');
                app.dataMatfile = matfile(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'Writable',true);
                
                inports = find_system(app.OnlyModelName, 'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'Inport');
                app.StatusTESTLabel.Text = 'Creating harness';
                drawnow
                
                harness_handle = new_system(app.harness_name_MIL);
                %set_param(harness_handle,'Solver','FixedStepDiscrete','FixedStep','0.01');
                open_system(harness_handle);
                figure(app.NEO);
                if app.AUTOSAR_stat == 1
                    ref_handle = add_block('simulink/Ports & Subsystems/Model',...
                        sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'ModelFile',app.ModelName,...
                        'ShowModelInitializePort','on','ShowModelPeriodicEventPorts','on');
                else
                    ref_handle = add_block('simulink/Ports & Subsystems/Model',...
                        sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'ModelFile',app.ModelName);
                end
                set_param(harness_handle, 'ZoomFactor','100'); % fit to screen
                max_ports = max(get_param(ref_handle, 'Ports'));
                ref_position = get_param(ref_handle,'Position');
                ref_position(4) = ref_position(2) + 55*max_ports;
                ref_position(3) = ref_position(1) + 520;
                set_param(ref_handle,'Position',ref_position);
                set_param(harness_handle, 'ZoomFactor','FitSystem'); % fit to screen
                set_param(harness_handle,'DataDictionary',DataDictionary);
                
                errorCode = 2; %Error in setting configuration of harness
                prog_stat.Message = 'Changing harness configuration';
                drawnow

                loadModel(app,app.OnlyModelName);

                set_param(app.OnlyModelName,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                set_param(app.harness_name_MIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                save_system(app.OnlyModelName);
                save_system(app.harness_name_MIL);

                model_config = getActiveConfigSet(app.OnlyModelName);
                
                cref = Simulink.ConfigSetRef;
                cref.Name = 'ModelRefConfig';
                cref.SourceName = model_config.SourceName;
                attachConfigSet(harness_handle,cref,true);
                setActiveConfigSet(harness_handle,'ModelRefConfig');
                save_system(harness_handle);

                app.StatusTESTLabel.Text = 'Creating harness - Analyzing model';
                drawnow

                errorCode = 3; %error in reading port information mostly issue with data dictionary
                prog_stat.Message = 'Collecting inport and outport details';
                drawnow

                %
                AllPortHandles = get_param(ref_handle,'PortHandles');
                inportHandles = AllPortHandles.Inport;
                all_PortConnectivity = get_param(ref_handle,'PortConnectivity');
                all_PortPos = {all_PortConnectivity.Position};
                app.no_rnbls = 0;
                rnbl_data = struct('Name',{},'PortNo',{},'SampleTime',{});
                app.no_inports = 0;
                inportNo = length(inports);
                for AllPorts = 1 : inportNo
                    name = get_param(inports(AllPorts),'Name');
                    % app.port_data(AllPorts).Name = name{1,1};
                    % app.port_data(AllPorts).Position = all_PortPos(AllPorts);
                    % app.port_data(AllPorts).Position = app.port_data(AllPorts).Position{1,1};
                    % app.port_data(AllPorts).Handle = inportHandles(AllPorts);
                    if cellfun(@isempty,regexpi(inports(AllPorts),'Rnbl_.*'))
                        out_data_type = get_param(inports(AllPorts),'OutDataTypeStr');
                        [app.no_inports, errorCode] = updatePortData(app, DataDictSec, app.no_inports, name{1,1}, out_data_type{1,1}, all_PortPos(AllPorts), inportHandles(AllPorts));
                    else
                        app.no_rnbls = app.no_rnbls + 1;
                        rnbl_data(app.no_rnbls).Name = name{1};
                        sampleTime = get_param(inports(AllPorts),'SampleTime');
                        rnbl_data(app.no_rnbls).SampleTime = sampleTime{1};
                        portNum = get_param(inports(AllPorts),'Port');
                        rnbl_data(app.no_rnbls).PortNo = portNum{1};

                        app.no_inports = app.no_inports + 1;
                        app.port_data(app.no_inports).Name = name{1,1};
                        app.port_data(app.no_inports).Position = all_PortPos(AllPorts);
                        app.port_data(app.no_inports).Position = app.port_data(app.no_inports).Position{1,1};
                        app.port_data(app.no_inports).Handle = inportHandles(AllPorts);
                    end
                end

                app.funcData = struct('functionProto',{},'funcName',{},'inArg',{},'outArg',{},'inArgSpc',{},'inBase',{},'outArgSpc',{},'outBase',{},'dstBlocks',{},'srcBlocks',{});
                allCaller = find_system(app.OnlyModelName, 'BlockType', 'FunctionCaller');
                app.no_func = 0;
                app.no_funcInp = 0;
                app.no_funcOut = 0;
                for calNo = 1:length(allCaller)
                    dstNo = 0;
                    srcNo = 0;
                    dstBlk = cell.empty(1,0);
                    srcBlk = cell.empty(1,0);
                    app.no_func = app.no_func + 1;
                    app.funcData(app.no_func).functionProto = get_param(allCaller(calNo),'FunctionPrototype');
                    
                    if ~isequal(get_param(allCaller(calNo),'InputArgumentSpecifications'),{'<Enter example>'})
                        app.funcData(app.no_func).inArgSpc = get_param(allCaller(calNo),'InputArgumentSpecifications');
                    end
                    if ~isequal(get_param(allCaller(calNo),'OutputArgumentSpecifications'),{'<Enter example>'})
                        app.funcData(app.no_func).outArgSpc = get_param(allCaller(calNo),'OutputArgumentSpecifications');
                    end
                    
                    %( = )*(?<funName>\w*(?=\()) -> gives function name under 'funName' token
                    %\[*(?<ouArg>,*\w*)*\]*(?=( = )) -> gives output arguments: Comma delimited under 'ouArg' token
                    %\((?<inArg>,*\w*)*\) -> gives input arguments: Comma delimited under 'inArg' token
                    outArg = regexp(app.funcData(app.no_func).functionProto,'\[*(?<ouArg>,*\w*)*\]*(?=( = ))','names');
                    outArg = outArg{1};
                    if ~isempty(outArg)
                        outputArg = outArg.ouArg;
                        app.funcData(app.no_func).outArg = strsplit(outputArg,',');
                        app.funcData(app.no_func).outArgSpc = strsplit(app.funcData(app.no_func).outArgSpc{1},',');
                        %funcParts(funcNo).inputArg = inputArg;
                        for outNo = 1:length(app.funcData(app.no_func).outArg)
                            dataType = strtrim(app.funcData(app.no_func).outArgSpc{outNo});
                            enumType = regexp(dataType,'(?<enumName>\w*)\(\d*\)','names');
                            %enumType = enumType{1};
                            if ~isempty(enumType)
                                app.funcData(app.no_func).outArgSpc{outNo} = sprintf('Enum: %s',enumType.enumName);
                                app.funcData(app.no_func).outBase{outNo} = 'Enum';
                            else
                                entryObj = getEntry(DataDictSec,dataType);
                                paramValue = getValue(entryObj);
                                app.funcData(app.no_func).outArgSpc{outNo} = paramValue.DataType;
                                if isempty(regexpi(paramValue.DataType,'Enum: .*'))
                                    entryObj = getEntry(DataDictSec,paramValue.DataType);
                                    aliasValue = getValue(entryObj);
                                    app.funcData(app.no_func).outBase{outNo} = aliasValue.BaseType;
                                else
                                    app.funcData(app.no_func).outBase{outNo} = 'Enum';
                                end
                            end

                        end
                    else
                        app.funcData(app.no_func).outArg = outArg;
                    end
                    %dataType = strtrim(inData{inpNo});
                    
                    funcName = regexp(app.funcData(app.no_func).functionProto,'( = )*(?<funName>\w*(?=\())','names');
                    funcName = funcName{1};
                    app.funcData(app.no_func).funcName = funcName.funName;
                    
                    inpArg = regexp(app.funcData(app.no_func).functionProto,'\((?<inArg>,*\w*)*\)','names');
                    inpArg = inpArg{1};
                    if ~isequal(inpArg.inArg,'')
                        inputArg = inpArg.inArg;
                        app.funcData(app.no_func).inArg = strsplit(inputArg,',');
                        app.funcData(app.no_func).inArgSpc = strsplit(app.funcData(app.no_func).inArgSpc{1},',');
                        %funcParts(funcNo).outputArg = outputArg;
                        for inpNo = 1:length(app.funcData(app.no_func).inArg)
                            dataType = strtrim(app.funcData(app.no_func).inArgSpc{inpNo});
                            enumType = regexp(dataType,'(?<enumName>\w*)\(\d*\)','names');
                            %enumType = enumType{1};
                            if ~isempty(enumType)
                                app.funcData(app.no_func).inArgSpc{inpNo} = sprintf('Enum: %s',enumType.enumName);
                                app.funcData(app.no_func).inBase{inpNo} = 'Enum';
                            else
                                entryObj = getEntry(DataDictSec,dataType);
                                paramValue = getValue(entryObj);
                                app.funcData(app.no_func).inArgSpc{inpNo} = paramValue.DataType;
                                if isempty(regexpi(paramValue.DataType,'Enum: .*'))
                                    entryObj = getEntry(DataDictSec,paramValue.DataType);
                                    aliasValue = getValue(entryObj);
                                    app.funcData(app.no_func).inBase{inpNo} = aliasValue.BaseType;
                                else
                                    app.funcData(app.no_func).inBase{inpNo} = 'Enum';
                                end
                            end
                        end
                    else
                        app.funcData(app.no_func).inArg = [];
                    end

                    portCon = get_param(allCaller(calNo),'PortConnectivity');
                    portCon = portCon{1};
                    for portNo = 1:length(portCon)
                        if ~isempty(portCon(portNo).SrcBlock)
                            srcNo = srcNo + 1;
                            srcBlk{srcNo} = get_param(portCon(portNo).SrcBlock,'BlockType');
                            if ~isequal(srcBlk{srcNo},'Ground')
                                app.no_funcInp = app.no_funcInp + 1;
                            end
                        end
                        if ~isempty(portCon(portNo).DstBlock)
                            dstNo = dstNo + 1;
                            dstBlk{dstNo} = get_param(portCon(portNo).DstBlock,'BlockType'); 
                            if ~isequal(dstBlk{dstNo},'Terminator')
                                app.no_funcOut = app.no_funcOut + 1;
                            end
                        end
                    end

                    app.funcData(app.no_func).dstBlocks = dstBlk;
                    app.funcData(app.no_func).srcBlocks = srcBlk;
                end

                for funNo = 1:app.no_func
                    if ~isempty(app.funcData(funNo).outArg)
                        for outNo = 1:length(app.funcData(funNo).outArg)
                            if ~isequal(app.funcData(funNo).dstBlocks{outNo},'Terminator')
                                app.no_inports = app.no_inports + 1;
                                funcPart = strsplit(app.funcData(funNo).funcName,'_');
                                app.port_data(app.no_inports).Name = sprintf('InProc_%s_%s_Read',funcPart{2},app.funcData(funNo).outArg{outNo});
                                app.port_data(app.no_inports).OutDataType = app.funcData(funNo).outArgSpc{outNo};
                                app.port_data(app.no_inports).BaseDataType = app.funcData(funNo).outBase{outNo};
                                app.port_data(app.no_inports).FunctionName = app.funcData(funNo).funcName;
                            end
                        end
                    end
                end

                if app.AUTOSAR_stat == 1
                    AllPorts = AllPorts + 1;
                    app.port_data(app.no_inports + 1).Name = 'initialize';
                    app.port_data(app.no_inports + 1).Position = all_PortPos(AllPorts);
                    app.port_data(app.no_inports + 1).Position = app.port_data(app.no_inports + 1).Position{1,1};
                    app.port_data(app.no_inports + 1).Handle = inportHandles(AllPorts);
                end

                outports = find_system(app.OnlyModelName, 'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'Outport');
                outportHandles = AllPortHandles.Outport;
                app.no_outports = 0;
                for AllPorts = (inportNo + 1 + app.AUTOSAR_stat) : (inportNo + app.AUTOSAR_stat + length(outports))
                    name = get_param(outports(AllPorts - inportNo - app.AUTOSAR_stat),'Name');
                    out_data_type = get_param(outports(AllPorts - inportNo - app.AUTOSAR_stat),'OutDataTypeStr');

                    outPortNo = app.no_outports + app.no_inports + app.AUTOSAR_stat;
                    [outPortNo, errorCode] = updatePortData(app, DataDictSec, outPortNo, name{1,1}, out_data_type{1,1}, all_PortPos(AllPorts), outportHandles(AllPorts - inportNo - app.AUTOSAR_stat));
                    app.no_outports = outPortNo - app.no_inports - app.AUTOSAR_stat;
                end

                portLength = length(app.port_data);
                for funNo = 1:app.no_func
                    if ~isempty(app.funcData(funNo).inArg)
                        for inpNo = 1:length(app.funcData(funNo).inArg)
                            if ~isequal(app.funcData(funNo).srcBlocks{inpNo},'Ground')
                                app.no_outports = app.no_outports + 1;
                                portLength = portLength + 1;
                                funcPart = strsplit(app.funcData(funNo).funcName,'_');
                                app.port_data(portLength).Name = sprintf('OutProc_%s_%s_Write',funcPart{2},app.funcData(funNo).inArg{inpNo});
                                app.port_data(portLength).OutDataType = app.funcData(funNo).inArgSpc{inpNo};
                                app.port_data(portLength).BaseDataType = app.funcData(funNo).inBase{inpNo};
                                app.port_data(portLength).FunctionName = app.funcData(funNo).funcName;
                            end
                        end
                    end
                end

                errorCode = 4; %error in adding function call generator

                if app.AUTOSAR_stat == 1 
                    add_block('simulink/Ports & Subsystems/Function-Call Generator',...
                            sprintf('%s/InitFunCallGen',app.harness_name_MIL),'sample_time','11',...
                            'Position',[app.port_data(app.no_inports + 1).Position(1) - 85 - 20 app.port_data(app.no_inports + 1).Position(2) - 11 app.port_data(app.no_inports + 1).Position(1) - 85 app.port_data(app.no_inports + 1).Position(2) + 11]);
                    add_line(app.harness_name_MIL,'InitFunCallGen/1',sprintf('%s/%d',app.OnlyModelName,inportNo + 1));
                    
                    for rnblNo = 1:app.no_rnbls
                        findIndex = find(contains(string({rnbl_data.PortNo}),num2str(rnblNo)));
                        add_block('simulink/Ports & Subsystems/Function-Call Generator',...
                            sprintf('%s/FunCallGen_%d',app.harness_name_MIL,rnblNo),'sample_time',rnbl_data(findIndex).SampleTime,...
                            'Position',[app.port_data(rnblNo).Position(1)-85-20 app.port_data(rnblNo).Position(2)-11 app.port_data(rnblNo).Position(1)-85 app.port_data(rnblNo).Position(2)+11]);
                        add_line(app.harness_name_MIL,sprintf('FunCallGen_%d/1',rnblNo),sprintf('%s/%d',app.OnlyModelName,rnblNo));
                    end
                end

                errorCode = 5; %error updating excel. delete harness and retry
                prog_stat.Message = 'Harness created. Creating Excel workbook';
                app.StatusTESTLabel.Text = 'Harness created. Creating Excel workbook';
                drawnow

                app.no_inports = app.no_inports - app.no_rnbls;
                Excel = actxserver('Excel.Application');
                Ex_Workbook = Excel.Workbooks.Add;
                Ex_Sheets = Excel.ActiveWorkbook.Sheets;
                Ex_actSheet = Ex_Sheets.get('Item',1);
                Ex_actSheet.Name = app.OnlyModelName;
                SaveAs(Ex_Workbook,sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                figure(app.NEO);
                Excel.Visible = 1;
                Ex_actSheet.Cells.HorizontalAlignment = -4108;
                Ex_actSheet.Cells.VerticalAlignment = -4108;
                
                Ex_range = get(Ex_actSheet,'Range','A1');
                Ex_range.Value = 'Requirement ID';
                Ex_range.ColumnWidth = 44;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = 'Test Case ID';
                Ex_range.ColumnWidth = 33;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = 'Test Description';
                Ex_range.ColumnWidth = 58;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = 'Test Case Output';
                Ex_range.ColumnWidth = 33;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = 'Time';
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',1,0);
                Ex_range.Value = '(in Sec)';
                Ex_range.ColumnWidth = 11;
                Ex_range = Ex_range.get('Offset',-1,1);
                %Ex_range.Interior.ColorIndex = 20->liteTorquoise, 43-> Lime,6-> yellow, 44-> Gold, -4142 -> No_Fill  
                %Ex_range.EntireRow.Interior.ColorIndex = 20
                %Ex_range.EntireColumn.AutoFit
                
                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+1+app.AUTOSAR_stat
                    if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                        %inports
                        Ex_range.Value = 'Source: Input';
                        Ex_range.Interior.ColorIndex = 43;
                        Ex_range = Ex_range.get('Offset',1,0);
                        Ex_range.Value = app.port_data(port_no).Name;
                        Ex_range.Interior.ColorIndex = 43;
                        Ex_range = Ex_range.get('Offset',1,0);
                        if isequal(app.port_data(port_no).BaseDataType,'Enum')
                            Ex_range.Value = app.port_data(port_no).OutDataType;
                        else
                            Ex_range.Value = sprintf('Type: %s',app.port_data(port_no).BaseDataType);
                        end
                        Ex_range.Interior.ColorIndex = 43;
                        Ex_range.EntireColumn.AutoFit;
                        Ex_range = Ex_range.get('Offset',-2,1);
                    elseif port_no > (app.no_rnbls + app.no_inports + app.AUTOSAR_stat) && port_no < (app.no_rnbls+app.no_inports+app.no_outports+1+app.AUTOSAR_stat)
                        %outports
                        Ex_range.Value = 'Expected Output';
                        Ex_range.Interior.ColorIndex = 6;
                        Ex_range = Ex_range.get('Offset',1,0);
                        Ex_range.Value = app.port_data(port_no).Name;
                        Ex_range.Interior.ColorIndex = 6;
                        Ex_range = Ex_range.get('Offset',1,0);
                        if isequal(app.port_data(port_no).BaseDataType,'Enum')
                            Ex_range.Value = app.port_data(port_no).OutDataType;
                        else
                            Ex_range.Value = sprintf('Type: %s',app.port_data(port_no).BaseDataType);
                        end
                        Ex_range.Interior.ColorIndex = 6;
                        Ex_range.EntireColumn.AutoFit;
                        Ex_range = Ex_range.get('Offset',-2,app.no_outports);
                        
                        Ex_range.Value = 'Source: Output';
                        Ex_range.Interior.ColorIndex = 44;
                        Ex_range = Ex_range.get('Offset',1,0);
                        Ex_range.Value = app.port_data(port_no).Name;
                        Ex_range.Interior.ColorIndex = 44;
                        Ex_range = Ex_range.get('Offset',1,0);
                        if isequal(app.port_data(port_no).BaseDataType,'Enum')
                            Ex_range.Value = app.port_data(port_no).OutDataType;
                        else
                            Ex_range.Value = sprintf('Type: %s',app.port_data(port_no).BaseDataType);
                        end
                        Ex_range.Interior.ColorIndex = 44;
                        Ex_range.EntireColumn.AutoFit;
                        Ex_range = Ex_range.get('Offset',-2,-(app.no_outports - 1));
                    end
                end

                
                Ex_range = Ex_range.get('Offset',0,app.no_outports);
                Ex_range.Value = 'Result';
                Ex_range.ColumnWidth = 19;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = 'Remarks';
                Ex_range.ColumnWidth = 40;
                Ex_range.Interior.ColorIndex = 20;
                Ex_range = Ex_range.get('Offset',3,-(6 + app.no_inports + (2*(app.no_outports)))); % error with No_inports with non autosar
                Ex_range.Value = '*Start Here*';
                Ex_actSheet.Cells.Borders.Item('xlInsideHorizontal').LineStyle = 1;
                Ex_actSheet.Cells.Borders.Item('xlInsideVertical').LineStyle = 1;
                Ex_Workbook.Save;
                
                errorCode = 6; %Unable to create .m file with global configurations
                caughtError = createParam(app,DataDictSec);
                throwError(app,caughtError,'Unable to create .m file with global configurations. Check previous messages for error info');
                
                app.dataMatfile.port_data = app.port_data;
                app.dataMatfile.no_inports = app.no_inports;
                app.dataMatfile.no_outports = app.no_outports;
                app.dataMatfile.no_rnbls = app.no_rnbls;
                app.dataMatfile.enableGC = app.enableGC;
                app.dataMatfile.funcData = app.funcData;
                app.dataMatfile.no_func = app.no_func;
                app.dataMatfile.no_funcInp = app.no_funcInp;
                app.dataMatfile.no_funcOut = app.no_funcOut;
                app.dataMatfile.neoVersion = app.neoVersion;
                app.enableTest = true;
                
                close(prog_stat);
                uialert(app.NEO,'Populate Excel with test cases and complete harness','Success','icon','success');
                app.StatusTESTLabel.Text = 'Populate Excel with test cases and complete harness';
            catch ErrorCaught
                figure(app.NEO);
                assignin('base','ErrorInfo_CreateExcel',ErrorCaught);
                app.errorFlag = 1;
                close(prog_stat);
                warning('-----------Unable to test harness and Excel. Delete any harness or Excel files generated. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to test harness and Excel. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                if isequal(exist(app.harness_name_MIL),4)
                    close_system(app.harness_name_MIL,0);
                    delete(sprintf('%s.slx',app.harness_name_MIL));
                end
                switch errorCode
                    case 1
                        %Error in creating harness
                        uialert(app.NEO,'Unable to create harness. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in setting configuration of harness
                        uialert(app.NEO,'Unable to set harness configuration. Check if configuration is set for model through DD. Retry after fixing error. Check command window for error info','Error');
                        warning('-----------Check if configuration is set for model through data dictionary-----------');
                    case 3
                        %error in reading port information mostly issue with data dictionary
                        uialert(app.NEO,'Incorrect port details (mostly, data type issues either in model or DD). Retry after fixing error. Check command window for error info','Error');
                    case 33
                        %Data type not provided for non autosar model. Delete harness
                        uialert(app.NEO,'Port data type not provided in non autosar model. Retry after fixing error. Check command window for error info','Error');
                    case 4
                        %error in adding function call generator
                        uialert(app.NEO,'Unable to add function call generators. Retry after fixing error. Check command window for error info','Error');
                    case 5
                        %error updating excel. delete harness and retry
                        uialert(app.NEO,'Unable to update Excel. Delete generated files and retry after fixing error. Check command window for error info','Error');
                    case 6
                        %error updating excel. delete harness and retry
                        %uialert(app.NEO,'Unable to update Excel. Delete generated files and retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            
        end

        function [signalNo, errorCode] = updatePortData(app, DataDictSec, signalNo, portName, portType, portPos, portHandle)
            errorCode = 0;
            if isequal(portType(1:4),'Enum')
                %An Enum signal
                signalNo = signalNo + 1;
                app.port_data(signalNo).Name = portName;
                app.port_data(signalNo).Position = portPos;
                app.port_data(signalNo).Position = app.port_data(signalNo).Position{1,1};
                app.port_data(signalNo).Handle = portHandle;
                app.port_data(signalNo).OutDataType = portType;
                app.port_data(signalNo).BaseDataType = 'Enum';
                gcEntries = find(DataDictSec,'Name',app.port_data(signalNo).OutDataType(7:length(app.port_data(signalNo).OutDataType)));
                enumValue = getValue(gcEntries(1));
                app.port_data(signalNo).defValue = [app.port_data(signalNo).OutDataType(7:length(app.port_data(signalNo).OutDataType)) '.' enumValue.DefaultValue];
            elseif isequal(portType(1:3),'Bus')
                %A bus signal
                entryObj = getEntry(DataDictSec, portType(6:length(portType)));
                aliasValue = getValue(entryObj);
                busElements = aliasValue.Elements;
                for busNo = 1 : length(busElements)
                    signalNo = signalNo + 1;
                    app.port_data(signalNo).Name = sprintf('%s.%s', portName, busElements(busNo).Name);
                    app.port_data(signalNo).Position = portPos;
                    app.port_data(signalNo).Position = app.port_data(signalNo).Position{1,1};
                    app.port_data(signalNo).Handle = portHandle;
                    app.port_data(signalNo).OutDataType = busElements(busNo).DataType;
                    app.port_data(signalNo).BusName = portName;
                    app.port_data(signalNo).BusDataType = portType;
                    if busNo == 1
                        app.port_data(signalNo).NoBusElm = length(busElements);
                    end
                    if isequal(busElements(busNo).DataType(1:4),'Enum')
                        app.port_data(signalNo).BaseDataType = 'Enum';
                        gcEntries = find(DataDictSec,'-regexp','Name',app.port_data(signalNo).OutDataType(7:length(app.port_data(signalNo).OutDataType)));
                        enumValue = getValue(gcEntries(1));
                        app.port_data(signalNo).defValue = [app.port_data(signalNo).OutDataType(7:length(app.port_data(signalNo).OutDataType)) '.' enumValue.DefaultValue];
                    else
                        app.port_data(signalNo).defValue = '0';
                        if app.AUTOSAR_stat == 1
                            if isempty(find(ismember(app.simDataTypes,app.port_data(signalNo).OutDataType)))
                                entryObj = getEntry(DataDictSec,app.port_data(signalNo).OutDataType);
                                aliasValue = getValue(entryObj);
                                app.port_data(signalNo).BaseDataType = aliasValue.BaseType;
                            else
                                app.port_data(signalNo).BaseDataType = app.port_data(signalNo).OutDataType;
                            end
                        else
                            if ~isequal(app.port_data(signalNo).OutDataType,'Inherit: auto')
                                app.port_data(signalNo).BaseDataType = app.port_data(signalNo).OutDataType;
                            else
                                errorCode = 33; %Data type not provided for non autosar model. Delete harness
                                error('Data type not assigned to ''%s'' inport',app.port_data(signalNo).Name);
                            end
                        end
                    end
                end
            else
                %non enum or bus signal
                signalNo = signalNo + 1;
                app.port_data(signalNo).Name = portName;
                app.port_data(signalNo).Position = portPos;
                app.port_data(signalNo).Position = app.port_data(signalNo).Position{1,1};
                app.port_data(signalNo).Handle = portHandle;
                app.port_data(signalNo).OutDataType = portType;
                app.port_data(signalNo).defValue = '0';
                if app.AUTOSAR_stat == 1
                    if isempty(find(ismember(app.simDataTypes,app.port_data(signalNo).OutDataType)))
                        entryObj = getEntry(DataDictSec,app.port_data(signalNo).OutDataType);
                        aliasValue = getValue(entryObj);
                        app.port_data(signalNo).BaseDataType = aliasValue.BaseType;
                    else
                        app.port_data(signalNo).BaseDataType = app.port_data(signalNo).OutDataType;
                    end
                else
                    if ~isequal(app.port_data(signalNo).OutDataType,'Inherit: auto')
                        app.port_data(signalNo).BaseDataType = app.port_data(signalNo).OutDataType;
                    else
                        errorCode = 33; %Data type not provided for non autosar model. Delete harness
                        error('Data type not assigned to ''%s'' inport',app.port_data(signalNo).Name);
                    end
                end
            end
        end

        % CreatingHarness
        function CreateHarness(app)
            try
                errorCode = 1; %Error in reading Excel
                app.StatusTESTLabel.FontColor = [0 0 0];
                app.StatusTESTLabel.Text = 'Importing test cases from Excel';
                drawnow
                figure(app.NEO);

                harness_handle = get_param(app.harness_name_MIL,'Handle');

                caughtError = ReadingExcel(app);
                throwError(app,caughtError,'Unable to read excel. Check previous messages for error info');

                prog_stat = uiprogressdlg(app.NEO,'Title','Completing harness',...
                            'Message','Adding signal builder and other required blocks','Indeterminate','on');
                drawnow
                errorCode = 2; %Error in adding signal builder and other blocks
                %replace app.port_data with app.test_data(caseNo).SigData
                for caseNo = 1:length(app.test_data)
                    %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
                    if caseNo == 1
                        %Inputs_ExpOutput = Simulink.SimulationData.Dataset;
                        %Inputs_ExpOutput.Name = 'Input&ExpectedOutput';
                        app.StatusTESTLabel.Text = 'Updating harness';
                        drawnow

                        %values = size(timeStamps);
                        %re_timeStamps = reshape(timeStamps,values(2),1);
                        %data = reshape(app.port_data(port_no).Values,values(2),1);
                        %temp_timeseries = timeseries(data,re_timeStamps,'Name',app.port_data(port_no).Name);
                        
                        time_array = cell(app.no_inports+app.no_outports,0);
                        signal_data = cell(app.no_inports+app.no_outports,0);
                        signal_name = cell(app.no_inports+app.no_outports,0);
                        sig_no = 0;
                        for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                            if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                                %initialize port
                            else
                                %Inports and outports
                                sig_no = sig_no +1;
                                time_array(sig_no) = {app.test_data(caseNo).SigTime};
                                signal_data(sig_no) = {app.test_data(caseNo).SigData(port_no).Values};
                                signal_name(sig_no) = {app.test_data(caseNo).SigData(port_no).Name};
                            end
                            signal_data = reshape(signal_data,sig_no,1);
                            time_array = reshape(time_array,sig_no,1);
                        end
                        %port_no = app.no_rnbls+1;

                        ref_port_handles = get_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'PortHandles');
                        modelPos = get_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'Position');
                        block = signalbuilder(sprintf('%s/SignalGen',app.harness_name_MIL),'create',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);

                        if ~isempty(ref_port_handles.Inport)
                            refPos = get_param(ref_port_handles.Inport(1),'Position');
                        else
                            refPos(1) = modelPos(1);
                            refPos(2) = (modelPos(2) + modelPos(4))/2; 
                        end

                        set_param(block,'Position',[(refPos(1) - 1300) (refPos(2) - 31) (refPos(1) - 950) (refPos(2) + ((app.no_inports + app.no_outports - app.no_rnbls) * 55) + 11)]);
                        sigPort = get_param(block,'PortConnectivity');
                        portGap = sigPort(2).Position(2) - sigPort(1).Position(2);
                        gen_handles = get_param(block,'PortHandles');
                        % Aligning signal builder
                        % if isempty(app.test_data(caseNo).SigData(port_no).FunctionName)
                        %     posDiff = app.test_data(1).SigData(port_no).Position(2) - sigPort(1).Position(2);
                        %     sigPos = get_param(block,'Position');
                        %     set_param(block,'Position',[sigPos(1) sigPos(2)+posDiff sigPos(3) sigPos(4)+posDiff]);
                        % end
                        
                        if ~isempty(ref_port_handles.Outport)
                            %ref positions for output scope blocks
                            tempPos = get_param(ref_port_handles.Outport(1),'Position');
                            scope_ref_height = tempPos(2) - 32;
                            scope_ref_width = tempPos(1) + 350;
                        else
                            scope_ref_height = (modelPos(2) + modelPos(4))/2;
                            scope_ref_width = modelPos(3);
                        end

                        signalNo = app.no_rnbls;
                        portOutNo = 0;
                        for port_no = app.no_rnbls + 1: app.no_rnbls + app.no_inports + app.no_outports + 1 + app.AUTOSAR_stat
                            if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                                %For all Inports
                                %create convert signal builder output to required
                                convert_handle = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),...
                                    'Position',[(sigPort(port_no - app.no_rnbls).Position(1) + 120) (sigPort(port_no - app.no_rnbls).Position(2)-10) (sigPort(port_no - app.no_rnbls).Position(1) + 195) (sigPort(port_no - app.no_rnbls).Position(2)+10)]...
                                    ,'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).OutDataType,'ShowName','off');
                                convert_port = get_param(convert_handle,'PortHandles');
                                set_param(convert_port.Outport(1),'DataLogging','on','DataLoggingName',app.test_data(caseNo).SigData(port_no).Name,'DataLoggingNameMode','Custom');
                                
                                %if signal is am enum, convert double to uint8 
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    old_pos = get_param(convert_handle,'Position');
                                    int_convert = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d_int8',app.harness_name_MIL,(port_no - app.no_rnbls)),...
                                        'Position', [old_pos(1)-100 old_pos(2) old_pos(3)-100 old_pos(4)],'OutDataTypeStr','uint8','ShowName','off');
                                    int_convert_port = get_param(int_convert,'PortHandles');
                                    add_line(app.harness_name_MIL,gen_handles.Outport((port_no - app.no_rnbls)),int_convert_port.Inport(1));
                                    add_line(app.harness_name_MIL,int_convert_port.Outport(1),convert_port.Inport(1));
                                else
                                    add_line(app.harness_name_MIL,gen_handles.Outport((port_no - app.no_rnbls)),convert_port.Inport(1));
                                end

                                if ~isempty(app.test_data(caseNo).SigData(port_no).BusDataType) && ~isempty(app.test_data(caseNo).SigData(port_no).NoBusElm)
                                    %if signal is part of a bus then create bus
                                    old_pos = get_param(convert_handle,'Position');

                                    bus_handle = add_block('simulink/Signal Routing/Bus Creator',sprintf('%s/bus_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),...
                                                            'Position',[(old_pos(3) + 80) old_pos(2) (old_pos(3) + 85) (old_pos(2) + ((app.test_data(caseNo).SigData(port_no).NoBusElm - 1) * portGap) + 48)],...
                                                            'Inputs',num2str(app.test_data(caseNo).SigData(port_no).NoBusElm),'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).BusDataType);

                                    % Aligning bus creator with convert blocks
                                    busPort = get_param(bus_handle,'PortConnectivity');
                                    old_pos = get_param(convert_port.Outport(1),'Position');
                                    posDiff = old_pos(2) - busPort(1).Position(2);
                                    busPos = get_param(bus_handle,'Position');
                                    set_param(bus_handle,'Position',[busPos(1) busPos(2)+posDiff busPos(3) busPos(4)+posDiff]);

                                    busSigNo = 1;
                                    % Connect convert block to bus
                                    busPort = get_param(bus_handle,'PortHandles');
                                    line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),busPort.Inport(busSigNo));
                                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name(length(app.test_data(caseNo).SigData(port_no).BusName) + 2 : length(app.test_data(caseNo).SigData(port_no).Name)));

                                    % Connect bus to goto
                                    busPos = get_param(busPort.Outport(1),'Position');
                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),'MakeNameUnique','on',...
                                        'Position',[(busPos(1) + 120) (busPos(2)-10) (busPos(1) + 225) (busPos(2)+10)]...
                                        ,'GotoTag',strrep(app.test_data(caseNo).SigData(port_no).BusName,'.','_'),'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    line_handle = add_line(app.harness_name_MIL,busPort.Outport(1),goto_port.Inport(1));
                                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).BusName);

                                    % Create a from block and connect it to runnable
                                    signalNo = signalNo + 1;
                                    portPos = get_param(ref_port_handles.Inport(signalNo),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),'MakeNameUnique','on',...
                                        'Position',[(portPos(1) - 125) (portPos(2) - 10) (portPos(1) - 20) (portPos(2) + 10)]...
                                        ,'GotoTag',strrep(app.test_data(caseNo).SigData(port_no).BusName,'.','_'),'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),ref_port_handles.Inport(signalNo));
                                elseif ~isempty(app.test_data(caseNo).SigData(port_no).BusDataType) && isempty(app.test_data(caseNo).SigData(port_no).NoBusElm)
                                    %if signal is part of a bus and bus is created then just add signal
                                    % Connect convert block to bus
                                    busSigNo = busSigNo + 1;
                                    line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),busPort.Inport(busSigNo));
                                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name(length(app.test_data(caseNo).SigData(port_no).BusName) + 2 : length(app.test_data(caseNo).SigData(port_no).Name)));
                                elseif isempty(app.test_data(caseNo).SigData(port_no).FunctionName)
                                    % Adding goto block to convert
                                    old_pos = get_param(convert_port.Outport(1),'Position');
                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),'MakeNameUnique','on',...
                                        'Position',[(old_pos(1) + 20) (old_pos(2)-10) (old_pos(1) + 125) (old_pos(2)+10)]...
                                        ,'GotoTag',strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_'),'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),goto_port.Inport(1));
                                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name);

                                    % Adding a from block 
                                    signalNo = signalNo + 1;
                                    portPos = get_param(ref_port_handles.Inport(signalNo),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),'MakeNameUnique','on',...
                                        'Position',[(portPos(1) - 125) (portPos(2) - 10) (portPos(1) - 20) (portPos(2) + 10)]...
                                        ,'GotoTag',strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_'),'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),ref_port_handles.Inport(signalNo));
                                else
                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no - app.no_rnbls)),'MakeNameUnique','on',...
                                        'Position',[(sigPort(port_no - app.no_rnbls).Position(1) + 250) (sigPort(port_no - app.no_rnbls).Position(2)-10) (sigPort(port_no - app.no_rnbls).Position(1) + 355) (sigPort(port_no - app.no_rnbls).Position(2)+10)]...
                                        ,'GotoTag',strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_'),'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),goto_port.Inport(1));
                                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name);
                                end
                            elseif port_no > (app.no_rnbls + app.no_inports + app.AUTOSAR_stat) && port_no < (app.no_rnbls + app.no_inports + app.no_outports + 1 + app.AUTOSAR_stat)
                                convert_handle = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d',app.harness_name_MIL,(port_no - app.no_rnbls - app.AUTOSAR_stat)),...
                                    'Position',[(sigPort(port_no - app.no_rnbls - app.AUTOSAR_stat).Position(1) + 120) (sigPort(port_no - app.no_rnbls - app.AUTOSAR_stat).Position(2)-10) (sigPort(port_no - app.no_rnbls - app.AUTOSAR_stat).Position(1) + 195) (sigPort(port_no - app.no_rnbls - app.AUTOSAR_stat).Position(2)+10)]...
                                    ,'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).OutDataType,'ShowName','off');
                                convert_port = get_param(convert_handle,'PortHandles');
                                % set_param(convert_port.Outport(1),'DataLogging','on');
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    old_pos = get_param(convert_handle,'Position');
                                    int_convert = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d_int8',app.harness_name_MIL,(port_no - app.no_rnbls - app.AUTOSAR_stat)),...
                                        'Position', [old_pos(1)-100 old_pos(2) old_pos(3)-100 old_pos(4)],'OutDataTypeStr','uint8','ShowName','off');
                                    int_convert_port = get_param(int_convert,'PortHandles');
                                    add_line(app.harness_name_MIL,gen_handles.Outport((port_no - app.no_rnbls - app.AUTOSAR_stat)),int_convert_port.Inport(1));
                                    add_line(app.harness_name_MIL,int_convert_port.Outport(1),convert_port.Inport(1));
                                else
                                    add_line(app.harness_name_MIL,gen_handles.Outport((port_no - app.no_rnbls - app.AUTOSAR_stat)),convert_port.Inport(1));
                                end

                                % Add goto block
                                old_pos = get_param(convert_port.Outport(1),'Position');
                                goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no - app.no_rnbls - app.AUTOSAR_stat)),'MakeNameUnique','on',...
                                    'Position',[(old_pos(1) + 20) (old_pos(2)-10) (old_pos(1) + 125) (old_pos(2)+10)]...
                                    ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Exp'],'ShowName','off');
                                goto_port = get_param(goto_handle,'PortHandles');
                                line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),goto_port.Inport(1));
                                set_param(line_handle,'Name',[app.test_data(caseNo).SigData(port_no).Name '_Exp']);

                                if ~isempty(app.test_data(caseNo).SigData(port_no).BusDataType) && ~isempty(app.test_data(caseNo).SigData(port_no).NoBusElm)
                                    %add a bus selector block
                                    portOutNo = portOutNo + 1;
                                    old_pos = get_param(ref_port_handles.Outport(portOutNo),'Position');
                                    bus_handle = add_block('simulink/Signal Routing/Bus Selector',sprintf('%s/bus_%d',app.harness_name_MIL,port_no),...
                                                            'Position',[old_pos(1) + 150 old_pos(2) - 20 old_pos(1) + 155 old_pos(2) + 20]);
                                    busPort = get_param(bus_handle,'PortHandles');
                                    add_line(app.harness_name_MIL,ref_port_handles.Outport(portOutNo),busPort.Inport(1));
                                    busSignals = get_param(bus_handle, 'InputSignals');
                                    busHeight = ((length(busSignals) - 1) * portGap) + 48;
                                    busSignals = join(busSignals,',');
                                    set_param(bus_handle, 'OutputSignals',busSignals{1},'Position', [old_pos(1) + 150 old_pos(2) - (busHeight / 2) old_pos(1) + 155 old_pos(2) + (busHeight / 2)]);

                                    busSigNo = 1;
                                    %add goto block
                                    busPort = get_param(bus_handle,'PortHandles');
                                    old_pos = get_param(busPort.Outport(busSigNo),'Position');
                                    % rate_handle = add_block('simulink/Signal Attributes/Rate Transition',sprintf('%s/rate_%d',app.harness_name_MIL,(port_no)),...
                                    %                         'Position',[(old_pos(1) + 20) (old_pos(2) - 20) (old_pos(1) + 60) (old_pos(2) + 20)],...
                                    %                         'InitialCondition',app.test_data(caseNo).SigData(port_no).defValue,'ShowName','off');
                                    % ratePort = get_param(rate_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,busPort.Outport(busSigNo),ratePort.Inport(1));

                                    % old_pos = get_param(ratePort.Outport(1),'Position');

                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no)),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) + 20) (old_pos(2) - 10) (old_pos(1) + 125) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Act'],'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,ratePort.Outport(1),goto_port.Inport(1));
                                    add_line(app.harness_name_MIL,busPort.Outport(busSigNo),goto_port.Inport(1));
                                    %set_param(line_handle,'Name',[app.test_data(caseNo).SigData(port_no).Name '_Actual']);
                                elseif ~isempty(app.test_data(caseNo).SigData(port_no).BusDataType) && isempty(app.test_data(caseNo).SigData(port_no).NoBusElm)
                                    busSigNo = busSigNo + 1;
                                    %add goto block
                                    busPort = get_param(bus_handle,'PortHandles');
                                    old_pos = get_param(busPort.Outport(busSigNo),'Position');
                                    % rate_handle = add_block('simulink/Signal Attributes/Rate Transition',sprintf('%s/rate_%d',app.harness_name_MIL,(port_no)),...
                                    %                         'InitialCondition',app.test_data(caseNo).SigData(port_no).defValue,...
                                    %                         'Position',[(old_pos(1) + 20) (old_pos(2) - 20) (old_pos(1) + 60) (old_pos(2) + 20)],'ShowName','off');
                                    % ratePort = get_param(rate_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,busPort.Outport(busSigNo),ratePort.Inport(1));

                                    % old_pos = get_param(ratePort.Outport(1),'Position');
                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no)),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) + 20) (old_pos(2) - 10) (old_pos(1) + 125) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Act'],'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,ratePort.Outport(1),goto_port.Inport(1));
                                    add_line(app.harness_name_MIL,busPort.Outport(busSigNo),goto_port.Inport(1));
                                    %set_param(line_handle,'Name',[app.test_data(caseNo).SigData(port_no).Name '_Actual']);
                                elseif isempty(app.test_data(caseNo).SigData(port_no).FunctionName)
                                    % add goto block at reference model
                                    portOutNo = portOutNo + 1;
                                    old_pos = get_param(ref_port_handles.Outport(portOutNo),'Position');
                                    % rate_handle = add_block('simulink/Signal Attributes/Rate Transition',sprintf('%s/rate_%d',app.harness_name_MIL,(port_no)),...
                                    %                         'InitialCondition',app.test_data(caseNo).SigData(port_no).defValue,...
                                    %                         'Position',[(old_pos(1) + 20) (old_pos(2)-20) (old_pos(1) + 60) (old_pos(2)+20)],'ShowName','off');
                                    % ratePort = get_param(rate_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,ref_port_handles.Outport(portOutNo),ratePort.Inport(1));

                                    % old_pos = get_param(ratePort.Outport(1),'Position');
                                    goto_handle = add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%d',app.harness_name_MIL,(port_no)),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) + 20) (old_pos(2)-10) (old_pos(1) + 125) (old_pos(2)+10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Act'],'ShowName','off');
                                    goto_port = get_param(goto_handle,'PortHandles');
                                    % add_line(app.harness_name_MIL,ratePort.Outport(1),goto_port.Inport(1));
                                    add_line(app.harness_name_MIL,ref_port_handles.Outport(portOutNo),goto_port.Inport(1));
                                    %set_param(line_handle,'Name',[app.test_data(caseNo).SigData(port_no).Name '_Actual']);
                                end

                                outportNo = port_no - app.no_rnbls - app.AUTOSAR_stat - app.no_inports;
                                
                                OutScope = add_block('simulink/Sinks/Scope',sprintf('%s/ScopeOut_%d',app.harness_name_MIL,outportNo),...
                                    'Position', [scope_ref_width + 475 scope_ref_height scope_ref_width + 475 + 40 scope_ref_height + 64]);
                                OutScope_param = get_param(OutScope,'ScopeConfiguration');
                                OutScope_param.NumInputPorts = '3';
                                OutScope_param.LayoutDimensions = [3,1];
                                scope_port = get_param(OutScope,'PortHandles');

                                % if ~isempty(app.test_data(caseNo).SigData(port_no).FunctionName)
                                %     from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_%d',app.harness_name_MIL,outportNo),...
                                %         'Position',[scope_ref_width + 20 scope_ref_height + 32 - 10 scope_ref_width + 20 + 105 scope_ref_height + 32 + 10]...
                                %         ,'GotoTag',app.test_data(caseNo).SigData(port_no).Name,'ShowName','off');
                                %     from_port = get_param(from_handle,'PortHandles');
                                %     set_param(from_port.Outport(1),'DataLogging','on');
                                %     outSource = sprintf('from_%d/1',outportNo);
                                % else
                                %     outSource = sprintf('%s/%d',app.OnlyModelName,outportNo);
                                %     set_param(ref_port_handles.Outport(outportNo),'DataLogging','on');
                                % end

                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'single') || isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'double')
                                    old_pos = get_param(scope_port.Inport(3),'Position');
                                    relation_handle = add_block('simulink/Logic and Bit Operations/Relational Operator',sprintf('%s/Relational_%d',app.harness_name_MIL,outportNo), 'Operator','<=',...
                                        'Position', [old_pos(1) - 155 old_pos(2) - 31 old_pos(1) - 135 old_pos(2) + 31],'ShowName','off');
                                    relation_port = get_param(relation_handle,'PortHandles');
                                    set_param(relation_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Res'],'DataLoggingNameMode','Custom');

                                    old_pos = get_param(relation_port.Inport(1),'Position');
                                    add_block('simulink/Math Operations/Abs',sprintf('%s/Abs_%d',app.harness_name_MIL,outportNo),...
                                        'Position', [old_pos(1) - 55 old_pos(2) - 16 old_pos(1) - 25 old_pos(2) + 16],'ShowName','off');
                                    
                                    diff_handle = add_block('simulink/Math Operations/Add',sprintf('%s/Difference_%d',app.harness_name_MIL,outportNo),'Inputs','+-',...
                                        'Position', [old_pos(1) - 100 old_pos(2) - 31 old_pos(1) - 80 old_pos(2) + 31],'ShowName','off');
                                    diff_port = get_param(diff_handle,'PortHandles');

                                    
                                    old_pos = get_param(relation_port.Inport(2),'Position');
                                    add_block('simulink/Sources/Constant',sprintf('%s/Limit_%d',app.harness_name_MIL,outportNo),'Value','0.0001',...
                                    'Position', [old_pos(1) - 60 old_pos(2) - 8 old_pos(1) - 25 old_pos(2) + 8],'ShowName','off');
                                        
                                    add_line(app.harness_name_MIL,sprintf('Limit_%d/1',outportNo),sprintf('Relational_%d/2',outportNo),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,sprintf('Difference_%d/1',outportNo),sprintf('Abs_%d/1',outportNo),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,sprintf('Abs_%d/1',outportNo),sprintf('Relational_%d/1',outportNo),'autorouting','Smart');
                                    
                                    old_pos = get_param(diff_port.Inport(1),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_Exp_%d',app.harness_name_MIL,outportNo),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) - 155) (old_pos(2) - 10) (old_pos(1) - 50) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Exp'],'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    set_param(from_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Exp'],'DataLoggingNameMode','Custom');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),diff_port.Inport(1),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),scope_port.Inport(1),'autorouting','Smart');

                                    old_pos = get_param(diff_port.Inport(2),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_Act_%d',app.harness_name_MIL,outportNo),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) - 155) (old_pos(2) - 10) (old_pos(1) - 50) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Act'],'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    set_param(from_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Act'],'DataLoggingNameMode','Custom');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),diff_port.Inport(2),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),scope_port.Inport(2),'autorouting','Smart');

                                    line_handle = add_line(app.harness_name_MIL,sprintf('Relational_%d/1',outportNo),sprintf('ScopeOut_%d/3',outportNo),'autorouting','Smart');
                                    set_param(line_handle,'Name',sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
                                else
                                    old_pos = get_param(scope_port.Inport(3),'Position');
                                    relation_handle = add_block('simulink/Logic and Bit Operations/Relational Operator',sprintf('%s/Relational_%d',app.harness_name_MIL,outportNo), 'Operator','==',...
                                                        'Position', [old_pos(1) - 155 old_pos(2) - 31 old_pos(1) - 135 old_pos(2) + 31], 'ShowName','off');
                                    relation_port = get_param(relation_handle,'PortHandles');
                                    set_param(relation_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Res'],'DataLoggingNameMode','Custom');

                                    old_pos = get_param(scope_port.Inport(1),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_Exp_%d',app.harness_name_MIL,outportNo),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) - 320) (old_pos(2) - 10) (old_pos(1) - 225) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Exp'],'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    set_param(from_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Exp'],'DataLoggingNameMode','Custom');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),relation_port.Inport(1),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),scope_port.Inport(1),'autorouting','Smart');

                                    old_pos = get_param(relation_port.Inport(2),'Position');
                                    from_handle = add_block('simulink/Signal Routing/From',sprintf('%s/from_Act_%d',app.harness_name_MIL,outportNo),'MakeNameUnique','on',...
                                                            'Position',[(old_pos(1) - 155) (old_pos(2) - 10) (old_pos(1) - 50) (old_pos(2) + 10)]...
                                                            ,'GotoTag',[strrep(app.test_data(caseNo).SigData(port_no).Name,'.','_') '_Act'],'ShowName','off');
                                    from_port = get_param(from_handle,'PortHandles');
                                    set_param(from_port.Outport(1),'DataLogging','on','DataLoggingName',[app.test_data(caseNo).SigData(port_no).Name '_Act'],'DataLoggingNameMode','Custom');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),relation_port.Inport(2),'autorouting','Smart');
                                    add_line(app.harness_name_MIL,from_port.Outport(1),scope_port.Inport(2),'autorouting','Smart');

                                    line_handle = add_line(app.harness_name_MIL,sprintf('Relational_%d/1',outportNo),sprintf('ScopeOut_%d/3',outportNo),'autorouting','Smart');
                                    set_param(line_handle,'Name',sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
                                end
                                scope_ref_height = scope_ref_height + 120;
                            end
                        end
                        %caseNo = 1 condition
                        errorCode = 3; %Error in adding test cases in Signal builder
                    else
                        prog_stat.Indeterminate = 'off';
                        prog_stat.Value = caseNo/length(app.test_data);
                        prog_stat.Message = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
                        app.StatusTESTLabel.Text = sprintf('%s: Updating signal builder',app.test_data(caseNo).TestCaseID);
                        drawnow

                        time_array = cell(app.no_inports+app.no_outports,0);
                        signal_data = cell(app.no_inports+app.no_outports,0);
                        signal_name = cell(app.no_inports+app.no_outports,0);
                        sig_no = 0;
                        for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                            if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                                %initialize port
                            else
                                %Inports and outports
                                sig_no = sig_no +1;
                                time_array(sig_no) = {app.test_data(caseNo).SigTime};
                                signal_data(sig_no) = {app.test_data(caseNo).SigData(port_no).Values};
                                signal_name(sig_no) = {app.test_data(caseNo).SigData(port_no).Name};
                            end
                            signal_data = reshape(signal_data,sig_no,1);
                            time_array = reshape(time_array,sig_no,1);
                        end
                        signalbuilder(block,'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
                    end
                end
                
                errorCode = 4; %Error in creating Stub functions

                %Adding stub functions
                refPos(1) = modelPos(1);
                refPos(2) = modelPos(2);
                for funcNo = 1 : length(app.funcData)

                    prog_stat.Value = funcNo/length(app.funcData);
                    prog_stat.Message = sprintf('Creating client for ''%s'' function caller',app.funcData(funcNo).funcName);
                    maxPorts = max(length(app.funcData(funcNo).inArg),length(app.funcData(funcNo).outArg));
                    funcHandle = add_block('simulink/User-Defined Functions/Simulink Function',sprintf('%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName),...
                    'Position',[(refPos(1) - 1695) refPos(2) (refPos(1) - 1535) (refPos(2) + 50 * maxPorts)]);

                    tempLine = find_system(funcHandle,'FindAll','on','type','line');
                    delete_line(tempLine);

                    funcBlock = find_system(funcHandle,'BlockType','TriggerPort');
                    funcPosition = get_param(funcBlock,'Position');
                    %funcPosition = funcPosition{1};
                    set_param(funcBlock(1),'Name',app.funcData(funcNo).funcName,'FunctionName',app.funcData(funcNo).funcName,'FunctionVisibility','global','FunctionPrototype',app.funcData(funcNo).functionProto{1});
                    
                    %Adding or deleting ArgIn ports and corresponding terminator or outport
                    if isempty(app.funcData(funcNo).inArg)
                        tempBlock = find_system(funcHandle,'BlockType','ArgIn');
                        delete_block(tempBlock);
                    else
                        allArgIn = find_system(funcHandle,'BlockType','ArgIn');
                        for inpNo = 1:length(app.funcData(funcNo).inArg)
                            set_param(allArgIn(inpNo),'Name',app.funcData(funcNo).inArg{inpNo},'ArgumentName',app.funcData(funcNo).inArg{inpNo},'OutDataTypeStr',app.funcData(funcNo).inArgSpc{inpNo},...
                                            'Position', [funcPosition(3)+10 funcPosition(4)+inpNo*60 funcPosition(3)+110 funcPosition(4)+inpNo*60+30]);
                            
                            %sprintf('OutProc_%s_Write',app.funcData(funcNo).inArg{inpNo})
                            funcPart = strsplit(app.funcData(funcNo).funcName,'_');
                            portName = sprintf('OutProc_%s_%s_Write',funcPart{2},app.funcData(funcNo).inArg{inpNo});

                            if isequal(app.funcData(funcNo).srcBlocks{inpNo},'Ground')
                                add_block('simulink/Sinks/Terminator',sprintf('%s/%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName,portName),...
                                            'Position',[funcPosition(3)+250 funcPosition(4)+inpNo*60+5 funcPosition(3)+270 funcPosition(4)+inpNo*60+25]);
                            else
                                add_block('simulink/Sinks/Out1',sprintf('%s/%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName,portName),...
                                            'Position',[funcPosition(3)+250 funcPosition(4)+inpNo*60+8 funcPosition(3)+280 funcPosition(4)+inpNo*60+22],...
                                            'OutDataTypeStr',app.funcData(funcNo).inArgSpc{inpNo});
                            end
                            lineHandle = add_line(sprintf('%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName),...
                                            sprintf('%s/1',app.funcData(funcNo).inArg{inpNo}),sprintf('%s/1',portName));
                            set_param(lineHandle,'Name',portName);
                        end
                    end

                    allOuts = find_system(funcHandle,'BlockType','Outport');
                    portHan = get_param(funcHandle,'PortHandles');
                    portHan = portHan.Outport;
                    if ~isempty(allOuts)
                        for outNo = 1 : length(allOuts)
                            portPos = get_param(portHan(outNo),'Position');
                            add_block('simulink/Signal Routing/Goto',sprintf('%s/goto_%s',app.harness_name_MIL,get_param(allOuts(outNo),'Name')),...
                                        'Position',[portPos(1) + 100 portPos(2) - 10 portPos(1) + 180 portPos(2) + 10],'GotoTag',[get_param(allOuts(outNo),'Name') '_Act'],'ShowName','off');
                            add_line(app.harness_name_MIL,sprintf('%s/%d',app.funcData(funcNo).funcName,outNo),sprintf('goto_%s/1',get_param(allOuts(outNo),'Name')),'autorouting','on');
                        end
                    end

                    %Adding or deleting ArgOut ports and corresponding terminator or inport
                    if isempty(app.funcData(funcNo).outArg)
                        tempBlock = find_system(funcHandle,'BlockType','ArgOut');
                        delete_block(tempBlock);
                    else
                        allArgOut = find_system(funcHandle,'BlockType','ArgOut');
                        for outNo = 1:length(app.funcData(funcNo).outArg)
                            funcPart = strsplit(app.funcData(funcNo).funcName,'_');
                            portName = sprintf('InProc_%s_%s_Read',funcPart{2},app.funcData(funcNo).outArg{outNo});
                            set_param(allArgOut(outNo),'Name',app.funcData(funcNo).outArg{outNo},'ArgumentName',app.funcData(funcNo).outArg{outNo},'OutDataTypeStr',app.funcData(funcNo).outArgSpc{outNo},...
                                        'Position', [funcPosition(3)-110 funcPosition(4)+outNo*60 funcPosition(3)-10 funcPosition(4)+outNo*60+30]);
                            if isequal(app.funcData(funcNo).dstBlocks{outNo},'Terminator')
                                add_block('simulink/Sources/Ground',sprintf('%s/%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName,portName),...
                                            'Position',[funcPosition(3)-270 funcPosition(4)+outNo*60+5 funcPosition(3)-250 funcPosition(4)+outNo*60+25]);
                            else
                                add_block('simulink/Sources/In1',sprintf('%s/%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName,portName),...
                                            'Position',[funcPosition(3)-280 funcPosition(4)+outNo*60+8 funcPosition(3)-250 funcPosition(4)+outNo*60+22],...
                                            'OutDataTypeStr',app.funcData(funcNo).outArgSpc{outNo});
                            end
                            lineHandle = add_line(sprintf('%s/%s',app.harness_name_MIL,app.funcData(funcNo).funcName),...
                                            sprintf('%s/1',portName),sprintf('%s/1',app.funcData(funcNo).outArg{outNo}));
                            %set_param(lineHandle,'Name',portName);
                            set(lineHandle,'signalPropagation','on');
                        end
                    end

                    allInps = find_system(funcHandle,'BlockType','Inport');
                    portHan = get_param(funcHandle,'PortHandles');
                    portHan = portHan.Inport;
                    if ~isempty(allInps)
                        for inpNo = 1 : length(allInps)
                            portPos = get_param(portHan(inpNo),'Position');
                            add_block('simulink/Signal Routing/From',sprintf('%s/from_%s',app.harness_name_MIL,get_param(allInps(inpNo),'Name')),...
                                        'Position',[portPos(1) - 180 portPos(2) - 10 portPos(1) - 100 portPos(2) + 10],'GotoTag',get_param(allInps(inpNo),'Name'),'ShowName','off');
                            add_line(app.harness_name_MIL,sprintf('from_%s/1',get_param(allInps(inpNo),'Name')),sprintf('%s/%d',app.funcData(funcNo).funcName,inpNo),'autorouting','on');
                        end
                    end
                    refPos(2) = refPos(2) + 60 + 50 * maxPorts;
                end

                %Adding goto and from tags
                
                %sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName)

                errorCode = 5; %Error in creating SIL harness
                prog_stat.Indeterminate = 'on';
                prog_stat.Message = 'Creating SIL harness';

                set_param(harness_handle, 'ZoomFactor','FitSystem');
                save_system(harness_handle);
                copyfile(sprintf('%s.slx',app.harness_name_MIL),sprintf('%s.slx',app.harness_name_SIL));

                loadModel(app,app.harness_name_SIL);
                set_param(app.harness_name_SIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                save_system(app.harness_name_SIL);
                
                close(prog_stat);
                uialert(app.NEO,'Harnesses are updated according to test cases','Success','icon','success');
                app.StatusTESTLabel.Text = 'Harnesses are completed according to test cases';
            catch ErrorCaught
                figure(app.NEO);
                assignin('base','ErrorInfo_CreateHarness',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to complete harness. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to test harness and Excel. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %uialert(app.NEO,'Unable read excel. Check command window for error info','Error');
                    case 2
                        %Error in adding signal builder and other blocks
                        uialert(app.NEO,'Unable add required blocks. Delete any blocks added and Retry. Check command window for error info','Error');
                        close(prog_stat);
                    case 3
                        %Error in adding test cases in Signal builder
                        uialert(app.NEO,'Error in importing test cases into signal builder. Delete any blocks added and Retry. Check command window for error info','Error');
                        close(prog_stat);
                    case 4
                        %Error in creating SIL harness
                        uialert(app.NEO,'Unable to add simulink functions for function callers. Delete any blocks added and Retry. Check command window for error info','Error');
                        close(prog_stat);
                    case 5
                        %Error in creating SIL harness
                        uialert(app.NEO,'Unable to create SIL harness. Duplicate MIL harness and rename it. Check command window for error info','Error');
                        close(prog_stat);
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
        end

        %UpdateTestCases
        function caughtError = ReadingExcel(app)

            try
                caughtError = 0;
                errorCode = 1; %Error in loading excel
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','Importing test cases Excel',...
                            'Message','Loading Excel','Indeterminate','on'); 
                drawnow
                Excel = actxserver('Excel.Application');
                Ex_Workbook = Excel.Workbooks.Open(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                Ex_Sheets = Excel.ActiveWorkbook.Sheets;
                Ex_actSheet = Ex_Sheets.get('Item',1);
                Excel.Visible = 1;
                
                figure(app.NEO);
                Ex_range = get(Ex_actSheet,'Range','B4');
                caseNo = 1;

                app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},...
                            'SigData',{},'SigTime',{},'Result',{},'DataLog',{},'TimeData',{},'ScopeSelect',{},'SLDVExpTime',{});

                errorCode = 2; %Error in reading excel
                while ~isnan(Ex_range.Value)
                    app.test_data(caseNo).TestCaseID = Ex_range.Value;
                    app.StatusTESTLabel.Text = sprintf('Importing %s from Excel',app.test_data(caseNo).TestCaseID);
                    prog_stat.Message = sprintf('Importing %s from Excel',app.test_data(caseNo).TestCaseID);
                    drawnow

                    Ex_range = Ex_range.get('Offset',0,-1);
                    app.test_data(caseNo).RequirementID = Ex_range.Value;
                    Ex_range = Ex_range.get('Offset',0,2);
                    app.test_data(caseNo).TestDescription = Ex_range.Value;
                    Ex_range = Ex_range.get('Offset',0,1);
                    app.test_data(caseNo).TestOutput = Ex_range.Value;
                    Ex_range = Ex_range.get('Offset',0,-2);
                    app.test_data(caseNo).ScopeSelect = zeros(2,max(app.no_inports,app.no_outports));

                    app.test_data(caseNo).SigData = app.port_data;

                    all_time_values = 0;
                    simulation_time = 0;
                    no_rows = 0;
                    while isequal(Ex_range.Value,app.test_data(caseNo).TestCaseID)
                        no_rows = no_rows + 1;
                        Ex_range = Ex_range.get('Offset',0,3);
                        all_time_values(no_rows) = Ex_range.Value;
                        simulation_time = simulation_time + Ex_range.Value;
                        Ex_range = Ex_range.get('Offset',1,-3);
                    end
                    app.test_data(caseNo).TestTime = simulation_time;
                    app.test_data(caseNo).TimeData = all_time_values;
                
                    %Ex_range = get(Ex_actSheet,'Range','E4');
                    Ex_range = Ex_range.get('Offset',-no_rows,4);
                    
                    %Initilizing signal time and value variables
                    app.test_data(caseNo).SigTime = zeros(1,2*no_rows);
                    for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                        if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                            %initialize port
                        else
                            %Inports and outports
                            app.test_data(caseNo).SigData(port_no).Values = zeros(1,2*no_rows);
                        end
                    end

                    %Ex_range = Ex_range.get('Offset',-1,0);% moving up bcz at time

                    for rowIndex = 1:no_rows
                        if rowIndex == 1
                            timeValue = 0;
                            valueIndex = 1;
                        else
                            valueIndex = valueIndex + 1;
                        end
                        
                        %Updating time and value(also scope select) for first half
                        app.test_data(caseNo).SigTime(valueIndex) = timeValue;
                        
                        for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                            if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
                                %initialize port
                            else
                                %Inports and outports
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    app.test_data(caseNo).SigData(port_no).Values(valueIndex) = ...
                                        eval(sprintf('%s.%s',app.test_data(caseNo).SigData(port_no).OutDataType(7:end),Ex_range.Value));
                           
                                else
                                    app.test_data(caseNo).SigData(port_no).Values(valueIndex) = Ex_range.Value;
                                end
                                %Scope Selection
                                if ~isequal(Ex_range.Interior.ColorIndex,-4142)
                                    if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                                        app.test_data(caseNo).ScopeSelect(1,(port_no-(app.no_rnbls))) = 1;
                                    elseif (port_no > (app.no_rnbls + app.no_inports + 1)) && (port_no < (app.no_rnbls+app.no_inports+app.no_outports+2))
                                        app.test_data(caseNo).ScopeSelect(2,(port_no-(app.no_rnbls + app.no_inports + 1))) = 1;
                                    end
                                end

                                Ex_range = Ex_range.get('Offset',0,1);
                            end
                        end
                        
                        Ex_range = Ex_range.get('Offset',0,-(app.no_inports+app.no_outports));
                        
                        %updating indexes for second half
                        if rowIndex == 1
                            timeValue = timeValue - app.timeOffset;
                        end
                        timeValue = all_time_values(rowIndex) + timeValue;
                        valueIndex = valueIndex + 1;
                        
                        %Updating time and value for second half
                        app.test_data(caseNo).SigTime(valueIndex) = timeValue;
                        for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                            if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
                                %initialize port
                            else
                                %Inports and outports
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    app.test_data(caseNo).SigData(port_no).Values(valueIndex) = ...
                                        eval(sprintf('%s.%s',app.test_data(caseNo).SigData(port_no).OutDataType(7:end),Ex_range.Value));
                                else
                                    app.test_data(caseNo).SigData(port_no).Values(valueIndex) = Ex_range.Value;
                                end
                                Ex_range = Ex_range.get('Offset',0,1);
                            end
                        end   
                        Ex_range = Ex_range.get('Offset',1,-(app.no_inports+app.no_outports));
                    end

                    Ex_range = Ex_range.get('Offset',0,-4); % offset to TestCaseID from First input
                    caseNo = caseNo + 1;
                    %timeStamps = 0:0.002:simulation_time;
                end
                
                errorCode = 3; %Error in updating Init function call generator 
                if app.AUTOSAR_stat == 1
                    set_param(sprintf('%s/InitFunCallGen',app.harness_name_MIL),'sample_time',num2str(sum([app.test_data.TestTime])+1));
                end
                
                Ex_Workbook.Close;
                Excel.Quit;

                close(prog_stat);
                %uialert(app.NEO,'Harness is completed according to test cases','Success','icon','success');
            catch ErrorCaught
                figure(app.NEO);
                caughtError = 1;
                assignin('base','IntErrorInfo_ReadingExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import test cases from Excel. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to import test cases from Excel. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading excel
                        uialert(app.NEO,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in adding test cases in Signal builder
                        if isempty(app.test_data(caseNo).TestCaseID)
                            uialert(app.NEO,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                        else
                            uialert(app.NEO,sprintf('Unable to import ''%s'' test case from Excel. Retry after fixing error. Check command window for error info', app.test_data(caseNo).TestCaseID),'Error');
                        end
                        Ex_Workbook.Close;
                        Excel.Quit;
                    case 3
                        %Error in adding test cases in Signal builder
                        uialert(app.NEO,'Unable to update Init function call generator. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;      
        end

        % UpdateSignal
        function UpdateSignal(app)
            %DataDictObj = Simulink.data.dictionary.open(DataDictionary)

            % if isequal(test_mode, 'MIL')
            %     loadModel(app,app.harness_name_MIL);
            %     %Selecting signal builder
            %     sigBuilders = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');
            % elseif isequal(test_mode,'SIL')
            %     loadModel(app,app.harness_name_SIL);
            %     %Selecting signal builder
            %     sigBuilders = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
            % end
            try
                errorCode = 1; %Error in resetting signal builders
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','Updating test cases',...
                            'Message','Resetting signal builders','Indeterminate','on'); 

                drawnow

                loadModel(app,app.harness_name_MIL);
                sigBuilders_MIL = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');

                loadModel(app,app.harness_name_SIL);
                sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');

                %deleting signals (all but first)
                [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_MIL{1,1});
                for grp_no = 2 : length(groupnames_t)
                    signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                    signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                end

                close(prog_stat);
                errorCode = 2; %Error in reading excel
                caughtError = ReadingExcel(app);
                throwError(app,caughtError,'Unable to read excel. Check previous messages for error info');

                errorCode = 3; %Error in adding test cases to signal builder
                prog_stat = uiprogressdlg(app.NEO,'Title','Updating test cases',...
                            'Message','Updating signal builders'); 

                for caseNo = 1:length(app.test_data)
                    %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
                    
                    app.StatusTESTLabel.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Message = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Value = caseNo/length(app.test_data);
                    drawnow

                    time_array = cell(app.no_inports+app.no_outports,0);
                    signal_data = cell(app.no_inports+app.no_outports,0);
                    signal_name = cell(app.no_inports+app.no_outports,0);
                    sig_no = 0;
                    for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                        if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                            %initialize port
                        else
                            %Inports and outports
                            sig_no = sig_no +1;
                            time_array(sig_no) = {app.test_data(caseNo).SigTime};
                            signal_data(sig_no) = {app.test_data(caseNo).SigData(port_no).Values};
                            signal_name(sig_no) = {app.test_data(caseNo).SigData(port_no).Name};
                        end
                        signal_data = reshape(signal_data,sig_no,1);
                        time_array = reshape(time_array,sig_no,1);
                    end
                    signalbuilder(sigBuilders_MIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
                    signalbuilder(sigBuilders_SIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
                    
                    if caseNo == 1
                        %deleting the first one
                        signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                        signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                    end  
                end
                
                save_system(app.harness_name_MIL);
                save_system(app.harness_name_SIL);

                errorCode = 4; %Error in copying excel
                prog_stat.Message = 'Updating SIL test cases Excel';
                prog_stat.Indeterminate = 'on';

                delete(sprintf('SIL_Functional_TestReport_%s.xlsx',app.OnlyModelName));
                copyfile(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName),...
                        sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                
                close(prog_stat);
                app.StatusTESTLabel.Text = 'Updated MIL & SIL harnesses';
                uialert(app.NEO,'Harnesses are updated according to new test cases','Success','icon','success');
            catch ErrorCaught
                figure(app.NEO);
                assignin('base','ErrorInfo_UpdateSignal',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to update signal builder with new test cases. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to update signal builder with new test cases. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in resetting signal builders
                        uialert(app.NEO,'Unable to reset signal builders. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in reading excel
                        %uialert(app.NEO,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                    case 3
                        %Error in adding test cases to signal builder
                        uialert(app.NEO,'Unable to update signal builders. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 4
                        %Error in adding test cases in Signal builder
                        uialert(app.NEO,sprintf('Unable to copy updated test cases from ''MIL_Functional_TestReport_%s.xlsx'' to ''SIL_Functional_TestReport_%s.xlsx''. Delete ''SIL_Functional_TestReport_%s.xlsx'' and copy the file manually\n',app.OnlyModelName,app.OnlyModelName,app.OnlyModelName),'Error');
                        app.StatusTESTLabel.Text = 'Updated both harnesses. Manually copy test cases from MIL Excel to SIL Excel';
                        close(prog_stat);
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
        end

        % Function to write results to excel 
        function caughtError = UpdateExcel(app,test_mode)
            try
                caughtError = 0;
                errorCode = 1; %Error in loading excel
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','Updating results in Excel',...
                            'Message','Loading Excel'); 
            
                Excel = actxserver('Excel.Application');
                Ex_Workbook = Excel.Workbooks.Open(sprintf('%s%s_Functional_TestReport_%s.xlsx',app.rootPath,test_mode,app.OnlyModelName));
                Ex_Sheets = Excel.ActiveWorkbook.Sheets;
                Ex_actSheet = Ex_Sheets.get('Item',1);
                Excel.Visible = 1;
            
                figure(app.NEO);
            
                Ex_range = get(Ex_actSheet,'Range','F4');
                Ex_range = Ex_range.get('Offset',0,app.no_inports+app.no_outports); % offset to Expected Output
            
                %fixedTimeStep = 0.01;
                errorCode = 2; %Error in updating excel

                for caseNo = 1:length(app.test_data)

                    % find the time series with max length
                    maxLen = zeros(1,numElements(app.test_data(caseNo).DataLog));
                    for sigNo = 1:numElements(app.test_data(caseNo).DataLog)
                        maxLen(sigNo) = length(app.test_data(caseNo).DataLog{sigNo}.Values.Time);
                    end
                    [maxValue,maxIdx] = max(maxLen);
                    maxTimeSeries = app.test_data(caseNo).DataLog{maxIdx}.Values.Time;
                    
                    % resampling timeseries to fit longest timeseries
                    for sigNo = 1:numElements(app.test_data(caseNo).DataLog)
                        if length(app.test_data(caseNo).DataLog{sigNo}.Values.Time) < maxValue
                            app.test_data(caseNo).DataLog{sigNo}.Values = resample(app.test_data(caseNo).DataLog{sigNo}.Values,maxTimeSeries);
                        end
                        app.test_data(caseNo).DataLog{sigNo}.Values.Name = app.test_data(caseNo).DataLog{sigNo}.Name;
                        app.test_data(caseNo).DataLog{sigNo}.Values.Data = reshape(app.test_data(caseNo).DataLog{sigNo}.Values.Data, size(app.test_data(caseNo).DataLog{maxIdx}.Values.Time));
                    end

                    %simulating current group
                    all_time_values = app.test_data(caseNo).TimeData;
                    logged_data = app.test_data(caseNo).DataLog;
            
                    %Log results in excel
                    app.StatusTESTLabel.Text = sprintf('Updating %s results of %s',test_mode,app.test_data(caseNo).TestCaseID);
                    %disp(app.test_data(caseNo).TestCaseID);
                    prog_stat.Message = sprintf('Updating %s results of %s',test_mode,app.test_data(caseNo).TestCaseID);
                    prog_stat.Value = caseNo/length(app.test_data);
                    drawnow
                    %Ex_range = Ex_range.get('Offset',-(no_rows-1),(no_inports+no_outports));
            
                    time_milestone = all_time_values(1);
                    test_result = 1; %1-> passed, 0-> failed of complete test case
                    time_index = 0;
                    indexValues = 0;
                    for valueIndex = 1:length(app.test_data(caseNo).DataLog{1}.Values.Time)
                        if abs(app.test_data(caseNo).DataLog{1}.Values.Time(valueIndex) - time_milestone) < app.timeOffset
                            time_index = time_index + 1;
                            indexValues(time_index) = valueIndex;
                            if time_index < length(all_time_values)
                                time_milestone = time_milestone + all_time_values(time_index+1);
                            end
                        end
                    end
            
                    result_status = ones(1,length(indexValues)); %array for results of all rows
                    for port_no = app.no_rnbls + app.no_inports + 1 + app.AUTOSAR_stat: app.no_rnbls + app.no_inports + app.no_outports + app.AUTOSAR_stat
                        resultLog = get(logged_data, sprintf('%s_Res',app.test_data(caseNo).SigData(port_no).Name));
                        resultLog = resultLog.Values.Data;
            
                        actualLog = get(logged_data, sprintf('%s_Act',app.test_data(caseNo).SigData(port_no).Name));
                        actualLog = actualLog.Values.Data;
                        
                        for rowNo = 1:length(indexValues)
                            if rowNo == 1
                                oldIndex = 1;
                            end
                            if rowNo == length(indexValues)
                                newIndex = indexValues(rowNo);
                            else
                                newIndex = indexValues(rowNo)-1;
                            end
                            resultSec = resultLog(oldIndex:newIndex);
                            actualSec = actualLog(oldIndex:newIndex);
                            oldIndex = newIndex+1;
                            rowResult = find(resultSec-1);
                            if isempty(rowResult)
                                Ex_range.Interior.ColorIndex = 0; 
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    Ex_range.Value = char(actualSec(1));
                                else
                                    Ex_range.Value = actualSec(1);
                                end
                            else
                                test_result = 0;
                                result_status(rowNo) = 0;
                                Ex_range.Interior.ColorIndex = 3; %red 
                                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
                                    Ex_range.Value = char(actualSec(rowResult(1)));
                                else
                                    Ex_range.Value = actualSec(rowResult(1));
                                end
                            end
                            Ex_range = Ex_range.get('Offset',1,0); %moving to the row below
                        end
                        Ex_range = Ex_range.get('Offset',-rowNo,1); %moving to first row of next output
                    end
            
                    for rowNo = 1:length(indexValues)
                        if result_status(rowNo) == 1
                            Ex_range.Interior.ColorIndex = 4; %green
                            Ex_range.Value = 'Passed';
                        else
                            Ex_range.Value = 'Failed';
                            Ex_range.Interior.ColorIndex = 3; %red
                        end
                        Ex_range = Ex_range.get('Offset',1,0); %moving to the row below
                    end
                    Ex_range = Ex_range.get('Offset',0,-(app.no_outports)); %moving to nest test case
                    app.test_data(caseNo).Result = test_result;
                end
            
                errorCode = 3; %Error in saving
                Ex_Workbook.Save;
                Ex_Workbook.Close;
                Excel.Quit;
            
                close(prog_stat);
                uialert(app.NEO,'Harness is completed according to test cases','Success','icon','success');
            catch ErrorCaught
                figure(app.NEO);
                caughtError = 1;
                assignin('base','IntErrorInfo_UpdateExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to update results in Excel. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to update results in Excel. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading excel
                        uialert(app.NEO,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in updating excel
                        uialert(app.NEO,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                        Ex_Workbook.Close;
                        Excel.Quit;
                    case 3
                        %Error in saving excel
                        uialert(app.NEO,'Unable to save Excel after updating results. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;
        end

        % RunMILTest
        function RunMILTest(app, DataDictObj, DataDictSec)
            try
                errorCode = 1; %Error in simulating model
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','MIL testing',...
                            'Message','MIL testing'); 
                drawnow
                set_param(app.harness_name_MIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                set_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'SimulationMode','Normal');
                sigBuilders = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');
                save_system(app.harness_name_MIL);

            	readParam(app);

                set_param(app.harness_name_MIL,'FastRestart','on','SimulationMode','Normal');
                for caseNo = 1:length(app.test_data)
                    %simulating current group
                    signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

                    app.StatusTESTLabel.Text = sprintf('MIL testing of %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Message = sprintf('MIL testing of %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Value = caseNo/length(app.test_data);
                    drawnow
                    
                    errorCode = 3; %Unable to update global configurations
	                caughtError = updateParam(app, DataDictObj, DataDictSec, caseNo);
	                throwError(app,caughtError,'Unable to update global configurations. Check previous messages for error info');

                    errorCode = 1; %Error in simulating model
                    %sim_data = sim(app.harness_name_MIL,'SimulationMode','Normal','SignalLogging','on','SignalLoggingName','logsout','StopTime',num2str(app.test_data(caseNo).TestTime));
                    sim_data = sim(app.harness_name_MIL,'StopTime',num2str(app.test_data(caseNo).TestTime));
                    %pause(simulation_time+3)
                    app.test_data(caseNo).DataLog = sim_data.logsout;
                end
                set_param(app.harness_name_MIL,'FastRestart','off');

                errorCode = 2; %Error in updating results
                close(prog_stat);
                caughtError = UpdateExcel(app,'MIL');
                throwError(app,caughtError,'Unable to update results in excel. Check previous messages for error info');

                uialert(app.NEO,'MIL testing completed','Success','icon','success');
                app.StatusTESTLabel.Text = 'MIL Testing completed';
            catch ErrorCaught
                figure(app.NEO);
                assignin('base','ErrorInfo_RunMILTest',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to MIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.StatusTESTLabel.Text = sprintf('Unable to MIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in simulating model
                        uialert(app.NEO,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 2
                        %Error in updating results
                        %uialert(app.NEO,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                    case 3
                    	%Error in updating global config
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
        end        

        %RunSILTest
        function RunSILTest(app, DataDictObj, DataDictSec)
            try
                errorCode = 1; %Error in loading excel
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','SIL testing',...
                            'Message','SIL testing'); 
                drawnow

                Excel = actxserver('Excel.Application');
                try 
                    Excel.Workbooks.Open(sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                catch
                    copyfile(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName),...
                        sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                end
                Excel.Quit;
                
                errorCode = 2; %Error in simulating model
                set_param(sprintf('%s/%s',app.harness_name_SIL,app.OnlyModelName),'SimulationMode','Software-in-the-loop (SIL)','CodeInterface','Top model');
                sigBuilders = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
                
                set_param(app.harness_name_SIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                save_system(app.harness_name_SIL);
                temp_data = app.test_data;

                if app.SLDVButton.Value
                    close(prog_stat);
                    errorCode = 4; %Error in importing SLDV test cases
                    caughtError = importSLDV(app);
                    throwError(app,caughtError,'Unable to import SLDV test cases. Check previous messages for error info');
                end

                prog_stat = uiprogressdlg(app.NEO,'Title','SIL testing',...
                            'Message','SIL testing'); 
                drawnow

                readParam(app);

                set_param(app.harness_name_SIL,'FastRestart','on','SimulationMode','Normal');
                for caseNo = 1:length(app.test_data)
                    %simulating current group
                    signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

                    save_system(app.OnlyModelName);
                    app.StatusTESTLabel.Text = sprintf('SIL testing of %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Message = sprintf('SIL testing of %s',app.test_data(caseNo).TestCaseID);
                    prog_stat.Value = caseNo/length(app.test_data);
                    drawnow

                    errorCode = 5; %Unable to update global configurations
	                caughtError = updateParam(app, DataDictObj, DataDictSec, caseNo);
	                throwError(app,caughtError,'Unable to update global configurations. Check previous messages for error info');

	                errorCode = 2; %Error in simulating model
                    %sim_data = sim(app.harness_name_SIL,'SimulationMode','Normal','SignalLogging','on','SignalLoggingName','logsout','StopTime',num2str(app.test_data(caseNo).TestTime));
                    sim_data = sim(app.harness_name_SIL,'StopTime',num2str(app.test_data(caseNo).TestTime));
                    %pause(simulation_time+3)
                    app.test_data(caseNo).DataLog = sim_data.logsout;
                end
                set_param(app.harness_name_SIL,'FastRestart','off');

                errorCode = 3; %Error in updating results in excel
                close(prog_stat);

                caughtError = UpdateExcel(app,'SIL');
                %Excel.Quit;
                throwError(app,caughtError,'Unable to update results in excel. Check previous messages for error info');
                app.test_data_SIL = app.test_data;
                app.test_data = temp_data;

                uialert(app.NEO,'SIL testing completed','Success','icon','success');
                app.StatusTESTLabel.Text = 'SIL Testing completed';
            catch ErrorCaught
                figure(app.NEO);
                assignin('base','ErrorInfo_RunSILTest',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to SIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.StatusTESTLabel.Text = sprintf('Unable to SIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading Excel
                        uialert(app.NEO,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 2
                        %Error in simulating model
                        uialert(app.NEO,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                        app.test_data_SIL = app.test_data;
                        app.test_data = temp_data;
                        close(prog_stat);
                    case 3
                        %Error in updating results
                        %uialert(app.NEO,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                        app.test_data_SIL = app.test_data;
                        app.test_data = temp_data;
                    case 4
                        %Error in importing SLDV test cases
                        %uialert(app.NEO,'Unable to import SLDV test cases. Retry after fixing error. Check command window for error info','Error');
                        app.test_data_SIL = app.test_data;
                        app.test_data = temp_data;
                    case 5
                    	%Unable to update global config
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
        end

        %importSLDV
        function caughtError = importSLDV(app)
            try
                sldvAllowed = 0; %Only allows further sldv actions if data is present
                caughtError = 0;
                errorCode = 1; %Error in accessing sldv test cases
                app.StatusTESTLabel.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.NEO,'Title','Loading test cases from SLDV',...
                            'Message','Checking files...','Indeterminate','on');
                app.StatusTESTLabel.Text = 'Checking SLDV files';
                drawnow

                if isequal(exist('sldv_output','dir'),7)
                    addpath('sldv_output');
                    all_files = dir('sldv_output');
                    fileCount = 0;
                    app.allSLDV = struct('ModelInformation',{},'AnalysisInformation',{},'ModelObjects',{},'Constraints',{},'Objectives',{},...
                                'TestCases',{},'Version',{});
                    for i = 1: length(all_files)
                        if all_files(i).isdir == 1 && ~isequal(all_files(i).name,'.') && ~isequal(all_files(i).name,'..')
                            addpath(sprintf('sldv_output/%s',all_files(i).name));
                            matFileName = dir(sprintf('%s/%s/*_sldvdata.mat',all_files(i).folder,all_files(i).name)); %Update to handle '*_sldvdata1.mat' file names 
                            if isempty(matFileName)
                            else
                                fileCount = fileCount + 1;
                                matFile = matfile(sprintf('%s/%s',matFileName.folder,matFileName.name));
                                app.allSLDV(fileCount) = matFile.sldvData;
                                sldvAllowed = 1;
                            end
                        end
                    end
                    if fileCount == 0
                        errorCode = 2; %SLDV test cases are not available
                        error('SLDV testcases(''*_sldvdata.mat'') are not available');
                    end
                else
                    errorCode = 3; %SLDV folder not available
                    error('SLDV folder(''sldv_output'') is not available');
                end

                
                %adding sldv test cases to test_data (if sldv data is available) 
                if sldvAllowed
                    errorCode = 4; %error in adding sldv test cases
                    loadModel(app,app.harness_name_SIL);
                    app.timeStep = str2double(get_param(app.harness_name_SIL,'FixedStep'));
                    caseID = app.test_data(1).TestCaseID(1:7);
                    caseNo = length(app.test_data);
                    for sldvIndex = 1: length(app.allSLDV)
                        for sldvNo = 1: length(app.allSLDV(sldvIndex).TestCases)
                            caseNo = caseNo + 1;
                            sldvTestCase = app.allSLDV(sldvIndex).TestCases(sldvNo);
                            all_time_values = sldvTestCase.timeValues;

                            %Initializing new entries in test_data structure
                            app.test_data(caseNo).RequirementID = 'NA';
                            app.test_data(caseNo).TestDescription = 'Auto generated by Simulink Design Verifier to achieve maximum condition coverage';
                            app.test_data(caseNo).TestOutput = 'Code output is same as model output';
                            if caseNo < 10
                                app.test_data(caseNo).TestCaseID = sprintf('%sC_00%d',caseID,caseNo);
                            elseif caseNo < 100
                                app.test_data(caseNo).TestCaseID = sprintf('%sC_0%d',caseID,caseNo);
                            else
                                app.test_data(caseNo).TestCaseID = sprintf('%sC_%d',caseID,caseNo);
                            end
                            app.test_data(caseNo).ScopeSelect = ones(2,max(app.no_inports,app.no_outports));
                            app.test_data(caseNo).SigData = app.port_data;
                            app.test_data(caseNo).SigTime = zeros(1,2*(length(all_time_values)));

                            prog_stat.Message = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
                            app.StatusTESTLabel.Text = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
                            drawnow

                            for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                                if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                                    %initialize port
                                else
                                    %Inports and outports
                                    if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                                        app.test_data(caseNo).SigData(port_no).Values = zeros(1,2*length(all_time_values));
                                    end
                                end
                            end

                            for timeIndex = 1:length(all_time_values)
                                if timeIndex == 1
                                    timeValue = 0;
                                    valueIndex = 1;
                                    if timeIndex ~= length(all_time_values)
                                        app.test_data(caseNo).TimeData(timeIndex) = all_time_values(2) - all_time_values(1);
                                    end
                                else
                                    valueIndex = valueIndex + 1;
                                end
                                if timeIndex == length(all_time_values)
                                    app.test_data(caseNo).TimeData(timeIndex) = 0; %changed it from app.timeStep
                                else
                                    app.test_data(caseNo).TimeData(timeIndex) = all_time_values(timeIndex + 1) - all_time_values(timeIndex);
                                end
                                app.test_data(caseNo).SigTime(valueIndex) = timeValue;

                                inIndex = 0;
                                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                                    if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
                                        %initialize port
                                    else
                                        if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                                            inIndex = inIndex + 1;
                                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.dataValues{inIndex}(timeIndex);
                                        end
                                    end
                                end

                                %updating indexes for second half
                                if timeIndex == 1
                                    timeValue = timeValue - app.timeOffset;
                                end

                                if timeIndex == length(all_time_values)
                                    timeValue = app.timeStep + timeValue;
                                else
                                    timeValue = app.test_data(caseNo).TimeData(timeIndex) + timeValue;
                                end

                                valueIndex = valueIndex + 1;

                                app.test_data(caseNo).SigTime(valueIndex) = timeValue;

                                inIndex = 0;
                                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                                    if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
                                        %initialize port
                                    else
                                        if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
                                            inIndex = inIndex + 1;
                                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.dataValues{inIndex}(timeIndex);
                                        end
                                    end
                                end  
                            end
                            app.test_data(caseNo).TestTime = sum(app.test_data(caseNo).TimeData);
                            
                            %Updating expected outputs
                            outTime = zeros(1 , 2*length(sldvTestCase.expectedOutput(1)));
                            %Updating expected outputs
                            valueIndex = 0;
                            expIndex = 0;
                            for timeValue = 0:app.timeStep:app.test_data(caseNo).TestTime
                                outIndex = 0;
                                expIndex = expIndex + 1;
                                valueIndex = valueIndex + 2;
                                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                                    if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
                                        %initialize port
                                    else
                                        if (port_no > (app.no_rnbls + app.no_inports + 1)) && (port_no < (app.no_rnbls+app.no_inports+app.no_outports+2))
                                            errorCode = 6; %expected output not present
                                            outIndex = outIndex + 1;
                                            if timeValue < app.timeOffset
                                                outTime(valueIndex) = timeValue;
                                                app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(expIndex);
                                                valueIndex = valueIndex + 1;
                                                outTime(valueIndex) = timeValue + app.timeOffset;
                                                app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(expIndex);
                                                valueIndex = valueIndex - 1;
                                            elseif abs(timeValue - app.test_data(caseNo).TestTime) < app.timeOffset
                                                outTime(valueIndex) = timeValue - app.timeOffset;
                                                app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(expIndex);
                                            else
                                                outTime(valueIndex) = timeValue - app.timeOffset;
                                                app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(expIndex);
                                                valueIndex = valueIndex + 1;
                                                outTime(valueIndex) = timeValue + app.timeOffset;
                                                app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(expIndex);
                                                valueIndex = valueIndex - 1;
                                            end
                                        end
                                    end
                                end
                            end
                            app.test_data(caseNo).SLDVExpTime = outTime;
                        end
                    end

                    %Update signal builder
                    errorCode = 5; %error in updating signal builder
                    sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
                    
                    prog_stat.Message = 'Resetting signal builder';
                    %deleting signals (all but first)
                    [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_SIL{1,1});
                    for grp_no = 2:length(groupnames_t)
                        signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                    end
                    prog_stat.Indeterminate = 'off';
                    for caseNo = 1:length(app.test_data)
                        %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
                        
                        app.StatusTESTLabel.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
                        prog_stat.Message = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
                        prog_stat.Value = caseNo/length(app.test_data);
                        drawnow

                        time_array = cell(app.no_inports+app.no_outports,0);
                        signal_data = cell(app.no_inports+app.no_outports,0);
                        signal_name = cell(app.no_inports+app.no_outports,0);
                        sig_no = 0;
                        for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
                            if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
                                %initialize port
                            else
                                %Inports and outports
                                sig_no = sig_no +1;
                                if isequal(app.test_data(caseNo).TestCaseID(8),'C') && ((port_no > (app.no_rnbls + app.no_inports + 1)) && (port_no < (app.no_rnbls+app.no_inports+app.no_outports+2)))
                                    time_array(sig_no) = {app.test_data(caseNo).SLDVExpTime};
                                else
                                    time_array(sig_no) = {app.test_data(caseNo).SigTime};
                                end
                                signal_data(sig_no) = {app.test_data(caseNo).SigData(port_no).Values};
                                signal_name(sig_no) = {app.test_data(caseNo).SigData(port_no).Name};
                            end
                            signal_data = reshape(signal_data,sig_no,1);
                            time_array = reshape(time_array,sig_no,1);
                        end
                        signalbuilder(sigBuilders_SIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);

                        if caseNo == 1
                            %deleting the first one
                            signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                        end
                    end
                    
                    
                    save_system(app.harness_name_SIL);
                    close(prog_stat);
                    app.StatusTESTLabel.Text = 'Imported SLDV test cases';
                    uialert(app.NEO,'Imported all SLDV test cases','Success','icon','success');
                    drawnow
                end
            catch ErrorCaught
                figure(app.NEO);
                caughtError = 1;
                assignin('base','IntErrorInfo_importSLDV',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import SLDV test cases. Retry after fixing error-----------');
                app.StatusTESTLabel.Text = 'Unable to import SLDV test cases. Retry after fixing error';
                app.StatusTESTLabel.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in accessing sldv test cases
                        uialert(app.NEO,'Unable to access sldv mat files. Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 2
                        %SLDV test cases are not available
                        uialert(app.NEO,'Unable to find sldv data files(''*_sldvdata.mat''). Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 3
                        %SLDV folder not available
                        uialert(app.NEO,'Unable to find ''sldv_output'' folder. Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 4
                        %error in adding sldv test cases
                        uialert(app.NEO,'Unable to add sldv test cases. Retry after fixing error. Check command window for error info','Error');
                    case 5
                        %error in updating signal builder
                        uialert(app.NEO,'Unable to update signalbuilder. Retry after fixing error. Check command window for error info','Error');
                    case 6
                        %expected output not present
                        uialert(app.NEO,'Unable to find expected outputs. Regenerate test cases after updating model configuration. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;
        end

        %reportMIL
        function reportMIL(app)
                    
            prog_stat = uiprogressdlg(app.NEO,'Title','MIL report generation',...
                            'Message','Checking files...','Indeterminate','on');

            dataAvail = 1;
            for caseNo = 1:length(app.test_data)
                if isempty(app.test_data(caseNo).DataLog)
                    dataAvail = 0;
                end
            end
            close(prog_stat);
            reportGen(app,'MIL', dataAvail);
        end

        %reportSIL
        function reportSIL(app)
            
            prog_stat = uiprogressdlg(app.NEO,'Title','SIL report generation',...
                            'Message','Checking files...','Indeterminate','on');

            dataAvail = 1;
            for caseNo = 1:length(app.test_data_SIL)
                if isempty(app.test_data_SIL(caseNo).DataLog)
                    dataAvail = 0;
                end
            end

            close(prog_stat);
            if isequal(app.SLDVButton.Value,1)
                if isequal(length(app.test_data),length(app.test_data_SIL)) 
                    uialert(app.NEO,sprintf('SLDV data is not available. Run ''SIL with SLDV'' and try again'),'Error','Icon','error');
                    fprintf(2,'Error: SLDV data is not available. Run ''SIL with SLDV'' and try again\n');
                    app.StatusTESTLabel.Text = 'SLDV data is not available. Run ''SIL with SLDV'' and try again';
                else
                    reportGen(app,'SIL', dataAvail);
                end
            else
                reportGen(app,'SIL', dataAvail);
            end
        end

        %Reportgen
        function reportGen(app, test_mode, dataAvail)

            prog_stat = uiprogressdlg(app.NEO,'Title',sprintf('%s report generation',test_mode),...
                            'Message','Checking files...','Indeterminate','on');

            if dataAvail
                if isequal(exist('rpt_icon','dir'),7)
                    if isequal(exist(sprintf('Eaton_OBC_DCDC_%s_Report.RPT',test_mode),'file'),2)
                        try
                            prog_stat.Message = sprintf('Generating %s report', test_mode);

                            assignin('base','OnlyModelName',app.OnlyModelName);
                            if isequal(test_mode,'MIL')
                                open_system(app.harness_name_MIL);
                                evalin('base','load(sprintf(''%s_TestHarness_data.mat'',OnlyModelName),''test_data'',''no_inports'',''no_outports'',''no_rnbls'')');
                                set_param(app.harness_name_MIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                                save_system(app.harness_name_MIL);
                            else
                                open_system(app.harness_name_SIL);
                                evalin('base','load(sprintf(''%s_TestHarness_data.mat'',OnlyModelName),''test_data_SIL'',''no_inports'',''no_outports'',''no_rnbls'')');
                                set_param(app.harness_name_SIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                                save_system(app.harness_name_SIL);
                            end
                            
                            figure(app.NEO);
                            evalin('base','genReport = 0');
                            report(sprintf('Eaton_OBC_DCDC_%s_Report.RPT',test_mode));

                            evalin('base','genReport = 1');
                            [rptGenSt] = report(sprintf('Eaton_OBC_DCDC_%s_Report.RPT',test_mode));
                            
                            if isempty(rptGenSt)
                                app.errorFlag = 1;
                                figure(app.NEO);
                                close(prog_stat);
                                warning('-----------Unable generate %s report. Try again after deleting all generated report files-----------',test_mode);
                                uialert(app.NEO,sprintf('Unable to generate %s report of %s model. Try again after deleting all generated report files',test_mode,app.OnlyModelName),'Error','Icon','error');
                                app.StatusTESTLabel.Text = sprintf('Unable to generate %s report of %s model',test_mode,app.OnlyModelName);
                                error('Unable to generate %s report of %s model. Try again after deleting all generated report files',test_mode,app.OnlyModelName);
                            else
                                uialert(app.NEO,sprintf('%s report of %s model generated',test_mode,app.OnlyModelName),'Success','Icon','success');
                                app.StatusTESTLabel.Text = sprintf('%s report of %s model generated',test_mode,app.OnlyModelName);
                            end
                        catch ErrorCaught
                            figure(app.NEO);
                            close(prog_stat);
                            app.errorFlag = 1;
                            assignin('base','ErrorInfo_reportGen',ErrorCaught);
                            warning('-----------Unable generate %s report-----------',test_mode);
                            uialert(app.NEO,sprintf('Unable to generate %s report. Check command window for more information',test_mode),'Error','Icon','error');
                            fprintf(2,'Error: %s\n',ErrorCaught.message);
                        end
                    else
                        close(prog_stat);
                        uialert(app.NEO,sprintf('''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again',test_mode),'Error','Icon','error');
                        fprintf(2,sprintf('Error: ''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again\n',test_mode));
                        app.StatusTESTLabel.Text = sprintf('''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again',test_mode);
                    end
                else
                    close(prog_stat);
                    uialert(app.NEO,'''rpt_icon'' folder is not present. Add it to path and try again','Error','Icon','error');
                    fprintf(2,'Error: ''rpt_icon'' folder is not present. Add it to path and try again\n');
                    app.StatusTESTLabel.Text = '''rpt_icon'' folder is not present. Add it to path and try again';
                end
            else
                close(prog_stat);
                uialert(app.NEO,sprintf('Simulation results are not available. Re-run %s test and try again',test_mode),'Error','Icon','error');
                fprintf(2,sprintf('Error: Simulation results are not available. Re-run %s test and try again\n',test_mode));
                app.StatusTESTLabel.Text = sprintf('Simulation results are not available. Re-run %s test and try again',test_mode);
            end
        end

        %configUpdate
        function caughtError = configUpdate(app,DataDictObj,EnableCov,EnableGenRep)
            try
            	caughtError = 0;
                DataSectConfig = getSection(DataDictObj,'Configurations');

                model_config = getActiveConfigSet(app.OnlyModelName);
                entryObj = getEntry(DataSectConfig,model_config.SourceName);
                ConfigSet = getValue(entryObj);
                set_param(ConfigSet,'CovEnable',EnableCov,'CovScope','ReferencedModels','CovMetricStructuralLevel','ConditionDecision','CovHighlightResults','on','CovHtmlReporting','on','CovCumulativeReport','on');
                set_param(ConfigSet,'GenerateReport',EnableGenRep); %Enabling or disabling code generation report (faster SIL) 
                setValue(entryObj,ConfigSet);

                saveChanges(DataDictObj);
            catch ErrorCaught
            	caughtError = 1;
                figure(app.NEO);
                assignin('base','ErrorInfo_configUpdate',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable update configuration parameters-----------');
                uialert(app.NEO,'Unable update configuration parameters','Error','Icon','error');
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
        end

        %throwError
        function throwError(app,caughtError,msgError)
            if caughtError
                error(msgError);
            end
        end

        %createParam
        function caughtError = createParam(app,DataDictSec)
        	try
        		errorCode = 1;
        		caughtError = 0;
        		app.StatusTESTLabel.Text = 'Reading Global Configurations';
        		gcEntries = find(DataDictSec,'-regexp','Name','GC_+'); %All global configuration parameters start with 'GC_'

        		if isempty(gcEntries)
        			app.enableGC = 0;
        		else
        			errorCode = 2;
        			app.enableGC = 1;
	        		paramFile = fullfile(app.rootPath,sprintf('GlobalConfigurations_%s.m',app.OnlyModelName));
	        		fid = fopen(paramFile,'w');

					fprintf(fid,'%%Initial values of global parameters\n');
					for i = 1:length(gcEntries)
					    param = getValue(gcEntries(i));
					    if isenum(param.Value)
					        fprintf(fid,'GlobalConfigs(1).%s = %s.%s;\n',gcEntries(i).Name,param.DataType(7:end),param.Value);
					    else
					        fprintf(fid,'GlobalConfigs(1).%s = %d;\n',gcEntries(i).Name,param.Value);
					    end
					end
					fprintf(fid,'%%End of Initial values of all global parameters\n');
					fprintf(fid,'%%*********Do not edit text above this line***********\n');

					fprintf(fid,'\n%%Update GlobalConfigs according to test cases\n');
					fprintf(fid,'%%Eg., GlobalConfigs(TestCaseID).parameterName = parameterValue;\n');
					fclose(fid);
				end
        	catch ErrorCaught
                figure(app.NEO);
                caughtError = 1;
                assignin('base','ErrorInfo_createParam',ErrorCaught);
                app.errorFlag = 1;
                switch errorCode
                    case 1
                        warning('-----------Unable read global configurations in data dictionary-----------');
                        uialert(app.NEO,'Unable read global configurations in data dictionary','Error','Icon','error');
                    case 2
                        warning('-----------Unable write global configurations to .m file-----------');
                        uialert(app.NEO,'Unable write global configurations to .m file','Error','Icon','error');
                end
                fprintf(2,'Error: %s\n',ErrorCaught.message);
        	end
        end

        %readParam
        function readParam(app)
        	if app.enableGC == 1
	        	run(fullfile(app.rootPath,sprintf('GlobalConfigurations_%s.m',app.OnlyModelName)));
			    app.gConf = GlobalConfigs;
			    entryNames = fieldnames(app.gConf);

			    for i = 1:length(app.gConf)
			        for j = 1:length(entryNames)
			            if isempty(eval(sprintf('app.gConf(%d).%s',i,entryNames{j})))
			                eval(sprintf('app.gConf(%d).%s = app.gConf(%d).%s',i,entryNames{j},i-1,entryNames{j}));
			            end
			        end
			    end
			end
        end

        %updateParam
		function caughtError = updateParam(app, DataDictObj, DataDictSec, caseNo)
            caughtError = 0;
			if app.enableGC == 1
				try
					errorCode = 1;
					caughtError = 0;
					if caseNo <= length(app.gConf)
						entryNames = fieldnames(app.gConf);
						for entryNo = 1:length(entryNames)
							ConfigObj = getEntry(DataDictSec,entryNames{entryNo});
							ConfigParam = getValue(ConfigObj);
							ConfigParam.Value = eval(sprintf('app.gConf(%d).%s',caseNo,entryNames{entryNo}));
							setValue(ConfigObj,ConfigParam);
						end
						errorCode = 2;
						saveChanges(DataDictObj);
						save_system(app.OnlyModelName);
					end
				catch ErrorCaught
	                figure(app.NEO);
	                assignin('base','ErrorInfo_updateParam',ErrorCaught);
	                app.errorFlag = 1;
	                caughtError = 1;
	                switch errorCode
	                    case 1
	                        warning('-----------Unable update global configurations in data dictionary-----------');
	                        uialert(app.NEO,'Unable update global configurations in data dictionary','Error','Icon','error');
	                    case 2
	                        warning('-----------Unable to save data dictionary or model-----------');
	                        uialert(app.NEO,'Unable to save data dictionary or model','Error','Icon','error');
	                end
	                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        	end
	        end
		end 

        % loadModel
        function loadModel(app, modelName)
            if bdIsLoaded(modelName)
            else
                load_system(sprintf('%s.slx',modelName));
            end
        end

        % Button pushed function: ExecuteTEST
        function ExecuteTESTButtonPushed(app, event)
            app.ModelVersionEditField.Editable = 'off';
            app.StatusTESTLabel.Text = sprintf('Loading %s model', app.ModelName);
            drawnow
            %Simulink.data.dictionary.closeAll;
            loadModel(app, app.OnlyModelName);
            DataDictionary = get_param(app.OnlyModelName,'DataDictionary');
            DataDictObj = Simulink.data.dictionary.open(DataDictionary);
            DataDictSec = getSection(DataDictObj,'Design Data');
            %app.StatusTESTLabel.Text = sprintf('Loading %s model', app.ModelName);
            app.errorFlag = 0;

            %updateStatus(app);
            AUTOSARButtonValueChanged(app, event);

            if app.CreateExcel.Value
                CreateExcel_Data(app,DataDictionary,DataDictSec);
                drawnow
            end

            if (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1) || isequal(app.RunTests.Value,1) ||...
                    isequal(app.RunSIL.Value,1) || isequal(app.MILReport.Value,1) || isequal(app.SILReport.Value,1)) && app.enableTest == true
                try
                    errorCode = 1; %error in reading mat file
                    % app.dataMatfile = matfile(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'Writable',true);
                    app.dataMatfile = load(sprintf('%s_TestHarness_data.mat',app.OnlyModelName));
                    app.port_data = app.dataMatfile.port_data;
                    app.no_inports = app.dataMatfile.no_inports;
                    app.no_outports = app.dataMatfile.no_outports;
                    app.no_rnbls = app.dataMatfile.no_rnbls;
                    app.funcData = app.dataMatfile.funcData;
                    app.no_func = app.dataMatfile.no_func;
                    app.no_funcInp = app.dataMatfile.no_funcInp;
                    app.no_funcOut = app.dataMatfile.no_funcOut;
                    app.enableGC = app.dataMatfile.enableGC;
                    app.timeOffset = 0.0001; %Updating value slightly before actual time ***should be smaller than sample time***

                    if app.UpdateHarness.Value && app.errorFlag == 0
                        app.StatusTESTLabel.Text = 'Importing test cases from Excel';
                        app.StatusTESTLabel.FontColor = [0 0 0];
                        drawnow
                        
                        errorCode = 2; %error in opening MIL harness
                        open_system(app.harness_name_MIL);

                        figure(app.NEO);
                        CreateHarness(app);

                        errorCode = 3; %error in writing to mat
                        app.dataMatfile.test_data = app.test_data;
                        test_data = app.test_data;
                        save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data', '-append')
                    end

                    if app.UpdateCases.Value && app.errorFlag == 0

                        errorCode = 4; %error in reading data in mat
                        app.test_data = app.dataMatfile.test_data;

                        errorCode = 2; %error in opening MIL harness
                        open_system(app.harness_name_MIL);

                        figure(app.NEO);
                        UpdateSignal(app);

                        errorCode = 3; %error in writing to mat
                        app.dataMatfile.test_data = app.test_data;
                        test_data = app.test_data;
                        save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data', '-append')
                    end

                    if app.RunTests.Value && app.errorFlag == 0
                        errorCode = 4; %error in reading data in mat
                        app.test_data = app.dataMatfile.test_data;
                        app.StatusTESTLabel.Text = 'Loading files...';
                        app.StatusTESTLabel.FontColor = [0 0 0];
                        drawnow

                        errorCode = 2; %error in opening MIL harness
                        open_system(app.harness_name_MIL);

                        %DataDictSec = getSection(DataDictObj,'Design Data');
                        
                        %app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},'SigData',{},'Result',{},'DataLog',{},'TimeData',{});
                        %failed_result: <b style="color:Red;">Failed</b>
                        %passed_result: <b style="color:Green;">Passed</b>
                        
                        figure(app.NEO);

                        %Running results
                        %configUpdate(app,DataDictObj,'off','on');
                        configUpdate(app,DataDictObj,'on','off');
                        RunMILTest(app, DataDictObj, DataDictSec);
                        configUpdate(app,DataDictObj,'off','on');

                        errorCode = 3; %error in writing to mat
                        app.dataMatfile.test_data = app.test_data;
                        test_data = app.test_data;
                        save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data', '-append')
        %               Ex_Workbook.Save;
                    end

                    if app.RunSIL.Value && app.errorFlag == 0
                        app.StatusTESTLabel.Text = 'Loading files...';
                        app.StatusTESTLabel.FontColor = [0 0 0];
                        drawnow
                        errorCode = 4; %error in reading data in mat
                        app.test_data = app.dataMatfile.test_data;

                        errorCode = 5; %error in opening SIL harness
                        open_system(app.harness_name_SIL);
                        figure(app.NEO);
                        %DataDictSec = getSection(DataDictObj,'Design Data');
                        
                        %app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},'SigData',{},'Result',{},'DataLog',{},'TimeData',{});
                        %failed_result: <b style="color:Red;">Failed</b>
                        %passed_result: <b style="color:Green;">Passed</b>
                        
                        %Running results
                        configUpdate(app,DataDictObj,'on','off');
                        RunSILTest(app, DataDictObj, DataDictSec);
                        configUpdate(app,DataDictObj,'off','on');

                        errorCode = 3; %error in writing to mat
                        app.dataMatfile.test_data_SIL = app.test_data_SIL;
                        test_data_SIL = app.test_data_SIL;
                        save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data_SIL', '-append')
        %               Ex_Workbook.Save;
                    end
                    
                    if app.MILReport.Value && app.errorFlag == 0
                        errorCode = 4; %error in reading data in mat
                        app.test_data = app.dataMatfile.test_data;
                        
                        figure(app.NEO);
                        errorCode = 6; %Error in report generation
                        reportMIL(app);
                    end

                    if app.SILReport.Value && app.errorFlag == 0
                        errorCode = 4; %error in reading data in mat
                        app.test_data_SIL = app.dataMatfile.test_data_SIL;
                        
                        figure(app.NEO);
                        errorCode = 6; %Error in report generation
                        reportSIL(app);
                    end
                catch ErrorCaught
                    figure(app.NEO);
                    app.errorFlag = 1;
                    assignin('base','ErrorInfo_ExecuteTEST',ErrorCaught);
                    
                    switch errorCode
                        case 1
                            %error in reading mat file
                            warning('-----------Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.NEO,sprintf('Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error','Icon','error');
                        case 2
                            %error in opening MIL harness
                            warning('-----------Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option-----------',app.harness_name_MIL);
                            uialert(app.NEO,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option',app.harness_name_MIL),'Error');
                        case 3
                            %error in writing to mat
                            warning('-----------Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.NEO,sprintf('Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
                        case 4
                            %error in reading to mat
                            warning('-----------Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.NEO,sprintf('Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
                        case 5
                            %error in opening MIL harness
                            warning('-----------Unable to load SIL harness ''%s''. Create harness using ''Complete harness'' Option-----------',app.harness_name_SIL);
                            uialert(app.NEO,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Complete harness'' Option',app.harness_name_MIL),'Error');
                    end
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            elseif app.enableTest == false
                uialert(app.NEO,'Testing files are outdated. Regenerate all testing files.','Error');
                app.StatusTESTLabel.Text = 'Testing files are outdated. Regenerate all testing files.';
            end
            figure(app.NEO);
            app.ModelVersionEditField.Editable = 'on';
            drawnow
        end

        
        %
        %Frame model generation functions

        % Button pushed function: OpenARXMLButton
        function OpenARXMLButtonPushed(app, event)
            app.StatusARXMLLabel.Text = 'Select .arxml file';
            app.StatusARXMLLabel.FontColor = [0 0 0];
            drawnow
            
            [app.arxml_name,app.arxml_path] = uigetfile('*.arxml','Select ARXML file');
            figure(app.NEO);
            
            if app.arxml_name == 0
                app.StatusARXMLLabel.Text = 'Select .arxml file';
                app.ExecuteARXML.Enable = 'off';
                app.NameofarxmlField.Value = '';
                app.Nameofmodel.Value = '';
                drawnow
            else
                addpath(app.arxml_path);
                %app.comp_name = strsplit(app.arxml_name,'.'); %update comp name based on selection
                try
                    prog_stat = uiprogressdlg(app.NEO,'Title','Importing ARXML',...
                            'Message','','Indeterminate','on');
                    app.arObj = arxml.importer(app.arxml_name);
                    app.ExecuteARXML.Enable = 'on';
                    app.NameofarxmlField.Value = app.arxml_name;
                    app.Nameofmodel.Value = '';
                    app.StatusARXMLLabel.Text = 'ARXML imported';
                    drawnow

                    app.AppCompts = CompNames(app,'Application');
                    app.SACompts = CompNames(app,'SensorActuator');
                    app.Comps = CompNames(app,'Composition');
                    app.AllNames = [app.AppCompts;app.SACompts;app.Comps];

                    UpdateDropDown(app);
                    app.StatusARXMLLabel.Text = 'Select component or composition';
                    close(prog_stat);
                catch ErrorCaught
                    figure(app.NEO);
                    assignin('base','ErrorInfo_OpenARXML',ErrorCaught);
                    close(prog_stat);
                    warning('-----------Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support-----------');
                    app.StatusARXMLLabel.Text = 'Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support';
                    app.StatusARXMLLabel.FontColor = [1 0 0];
                    app.ExecuteARXML.Enable = 'off';
                    uialert(app.NEO,'Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support','Error');
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            end
        end

        % Value changed function: UpdateModel
        function UpdateModelValueChanged(app, event)
            %value = app.UpdateModel.Value;
            app.StatusARXMLLabel.FontColor = [0 0 0];
            drawnow
            
            if app.UpdateModel.Value == 1 && app.CompositionsButton.Value == 1
                app.ExecuteARXML.Enable = 'off';
                app.SelectModelButton.Enable = 'off';
                app.Nameofmodel.Enable = 'off';
                app.NameofmodelLabel.Enable = 'off';
                app.StatusARXMLLabel.Text = 'Select component not composition';
                app.ExecuteARXML.Text = 'Update model according to new ARXML';
                app.Nameofmodel.Value = '';
                drawnow
            elseif app.UpdateModel.Value
                app.SelectModelButton.Enable = 'on';
                app.Nameofmodel.Enable = 'on';
                app.NameofmodelLabel.Enable = 'on';
                app.StatusARXMLLabel.Text = 'Select model to update';
                app.ExecuteARXML.Text = 'Update model according to new ARXML';
                app.ExecuteARXML.Enable = 'off';
                drawnow
            else
                if isempty(app.SelectcomponentDropDown.Items)
                    app.ExecuteARXML.Enable = 'off';
                else
                    app.ExecuteARXML.Enable = 'on';
                end
                app.SelectModelButton.Enable = 'off';
                app.Nameofmodel.Enable = 'off';
                app.NameofmodelLabel.Enable = 'off';
                app.StatusARXMLLabel.Text = 'Select component or composition';
                app.ExecuteARXML.Text = 'Create frame model & data type scripts';
                app.Nameofmodel.Value = '';
                drawnow
            end
        end

        function CompMap = CompNames(app,optionSelect)
            All_Names = getComponentNames(app.arObj,optionSelect);
            CompMap = containers.Map('KeyType','char','ValueType','char');
            for i = 1:length(All_Names)
                temp = char(All_Names(i));
                split = strsplit(temp,'/');
                split = split(length(split));
                CompMap(split{1,1}) = temp;
            end
        end

        function UpdateDropDown(app)
            app.StatusARXMLLabel.FontColor = [0 0 0];
            drawnow
            
            try
                if app.ApplicationButton.Value
                    app.SelectcomponentDropDown.Items = app.AppCompts.keys;
                    app.SelectcomponentDropDownLabel.Text = 'Select component:';
                elseif app.SensorActuatorButton.Value
                    app.SelectcomponentDropDown.Items = app.SACompts.keys;
                    app.SelectcomponentDropDownLabel.Text = 'Select component:';
                elseif app.CompositionsButton.Value
                    app.SelectcomponentDropDown.Items = app.Comps.keys;
                    app.SelectcomponentDropDownLabel.Text = 'Select composition:';
                end
                
                if isempty(app.SelectcomponentDropDown.Items) || app.UpdateModel.Value == 1
                    app.ExecuteARXML.Enable = 'off';
                else
                    app.ExecuteARXML.Enable = 'on';
                end
                app.Nameofmodel.Value = '';
                drawnow
            catch
                figure(app.NEO);
                if isempty(app.arxml_name) || app.arxml_name == 0
                    app.StatusARXMLLabel.Text = 'Select .arxml file';
                end
            end
        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            %selectedButton = app.ButtonGroup.SelectedObject;
            UpdateDropDown(app);
        end

        % Value changed function: SelectcomponentDropDown
        function SelectcomponentDropDownValueChanged(app, event)
            %value = app.SelectcomponentDropDown.Value;
        end

        % Button pushed function: SelectModelButton
        function SelectModelButtonPushed(app, event)
            app.StatusARXMLLabel.FontColor = [0 0 0];
            drawnow
            [app.ModelName,app.ModelPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to test');
            figure(app.NEO);
            if app.ModelName == 0
                app.StatusARXMLLabel.Text = 'Select model to update';
                app.ExecuteARXML.Enable = 'off';
                app.Nameofmodel.Value = '';
                drawnow
            else
                prog_stat = uiprogressdlg(app.NEO,'Title','Loading model',...
                            'Message','','Indeterminate','on');
                app.OnlyModelName = strsplit(app.ModelName,'.');
                app.OnlyModelName = app.OnlyModelName{1,1};
                app.Nameofmodel.Value = app.OnlyModelName;
                if isequal(app.OnlyModelName,app.SelectcomponentDropDown.Value)
                    app.ExecuteARXML.Enable = 'on';
                    app.StatusARXMLLabel.Text = 'Select model to update';
                    app.StatusARXMLLabel.FontColor = [0 0 0];
                    if ~isequal(app.ModelPath, app.arxml_path)
                        addpath(app.ModelPath);
                    end
                    loadModel(app,app.OnlyModelName);
                    close(prog_stat);
                else
                    close(prog_stat);
                    uialert(app.NEO,'Different model and component names. Reselect component model','Error');
                    app.StatusARXMLLabel.Text = 'Different model and component names';
                    app.StatusARXMLLabel.FontColor = [1 0 0];
                    app.ExecuteARXML.Enable = 'off';
                end
            end
        end

        % Button pushed function: ExecuteARXML
        function ExecuteARXMLButtonPushed(app, event)
            app.StatusARXMLLabel.FontColor = [0 0 0];
            drawnow
            if app.UpdateModel.Value == 1
                app.StatusARXMLLabel.Text = 'Updating model according to ARXML';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.NEO,'Title','Updating model',...
                            'Message','','Indeterminate','on');
                    loadModel(app,app.OnlyModelName);
                    updateModel(app.arObj,app.OnlyModelName);
                    app.StatusARXMLLabel.Text = 'Model udpated according to ARXML';
                    drawnow

                    close(prog_stat);
                    
                    uialert(app.NEO,'Model udpated according to ARXML. Complete manual model changes mentioned in update report','Success','Icon','success');
                catch ErrorCaught
                    figure(app.NEO);
                    close(prog_stat);
                    assignin('base','ErrorInfo_ExecuteARXML',ErrorCaught);
                    warning('-----------Unable to update model. Retry after restarting matlab-----------');
                    app.StatusARXMLLabel.Text = 'Unable to update model.';
                    app.StatusARXMLLabel.FontColor = [1 0 0];
                    uialert(app.NEO,'Unable to update model. Check command window for error info','Error');
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            elseif app.CompositionsButton.Value == 0
                app.StatusARXMLLabel.Text = 'Creating scripts with data types';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.NEO,'Title','Creating frame model',...
                            'Message','','Indeterminate','on');
                    createComponentAsModel(app.arObj,app.AllNames(char(app.SelectcomponentDropDown.Value)),'ModelPeriodicRunnablesAs','FunctionCallSubsystem');
                    Model_name = get_param(gcs,'Name');
                    close_system(sprintf('%s.slx',Model_name),0);
                    %Simulink.data.dictionary.closeAll('-discard');
                    %delete *.slx;
                    %delete *.slxc;
                    %delete *.sldd;
                    %delete(sprintf('%s.slx',Model_name));
                    %delete (sprintf('%s.sldd',app.comp_name{1,1}));
                    
                    app.StatusARXMLLabel.Text = 'Creating component frame model';
                    prog_stat.Message = app.StatusARXMLLabel.Text;
                    drawnow

                    createComponentAsModel(app.arObj,app.AllNames(app.SelectcomponentDropDown.Value),'ModelPeriodicRunnablesAs','FunctionCallSubsystem',...
                            'DataDictionary',sprintf('%s.sldd',app.SelectcomponentDropDown.Value));

                    Model_name = get_param(gcs,'Name');
                    DataDictionaryObj = Simulink.data.dictionary.open(sprintf('%s.sldd',app.SelectcomponentDropDown.Value));
                    dDataSectObj = getSection(DataDictionaryObj,'Design Data');
                    exportToFile(dDataSectObj,sprintf('%s_DerivedDatatypes.m',Model_name));
                    
                    save_system;
                    
                    app.StatusARXMLLabel.Text = 'Component frame model created';
                    close(prog_stat);
                    uialert(app.NEO,'Component frame model created','Success','Icon','success');
                catch ErrorCaught
                    close(prog_stat);
                    assignin('base','ErrorInfo_ExecuteARXML',ErrorCaught);
                    warning('-----------Unable to create frame model. Retry after restarting matlab-----------');
                    app.StatusARXMLLabel.Text = 'Unable to create frame model.';
                    uialert(app.NEO,'Unable to create frame model. Check command window for error info','Error');
                    app.StatusARXMLLabel.FontColor = [1 0 0];
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
                
            elseif app.CompositionsButton.Value == 1
                app.StatusARXMLLabel.Text = 'Creating scripts with data types';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.NEO,'Title','Creating frame models',...
                            'Message','','Indeterminate','on');

                    createCompositionAsModel(app.arObj,app.AllNames(app.SelectcomponentDropDown.Value),'DataDictionary',sprintf('%s.sldd',app.SelectcomponentDropDown.Value));
                    app.StatusARXMLLabel.Text = 'Creating composition frame model';
                    drawnow

                    Model_name = get_param(gcs,'Name');
                    DataDictionaryObj = Simulink.data.dictionary.open(sprintf('%s.sldd',app.SelectcomponentDropDown.Value));
                    dDataSectObj = getSection(DataDictionaryObj,'Design Data');
                    exportToFile(dDataSectObj,sprintf('%s_DerivedDatatypes.m',Model_name));
                    
                    %close_system(sprintf('%s.slx',Model_name),0);
                    %Simulink.data.dictionary.closeAll('-discard');
                    
                    %delete *.slx;
                    %delete *.slxc;
                    %delete *.sldd;
                    %delete(sprintf('%s.slx',Model_name));
                    
                    %delete (sprintf('%s.sldd',app.comp_name{1,1}));
                    
                    %createCompositionAsModel(app.arObj,char(all_comsts(1)),'ModelPeriodicRunnablesAs','FunctionCallSubsystem');
                    save_system;
                    close(prog_stat);
                    app.StatusARXMLLabel.Text = 'Composition frame model created';
                    uialert(app.NEO,'Composition frame model created','Success','Icon','success');
                catch ErrorCaught
                    close(prog_stat);
                    assignin('base','ErrorInfo_ExecuteARXML',ErrorCaught);
                    warning('-----------Unable to create frame model. Retry after restarting matlab-----------');
                    app.StatusARXMLLabel.Text = 'Unable to create frame model. Retry after restarting matlab';
                    uialert(app.NEO,'Unable to create frame model. Check command window for error info','Error');
                    app.StatusARXMLLabel.FontColor = [1 0 0];
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            end
            figure(app.NEO);
        end

        % Selection change function: Features
        function FeaturesSelectionChanged(app, event)
            %selectedTab = app.Features.SelectedTab;
            app.ModelName = 0;
            app.ModelNameEditField.Value = '';
            updateStatus(app);
        end

    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create NEO
            app.NEO = uifigure;
            app.NEO.AutoResizeChildren = 'off';
            app.NEO.Position = [100 100 618 351];
            app.NEO.Name = 'Testing and frame generation app (NEO 1.5.2)';
            app.NEO.Resize = 'off';

            % Create Features
            app.Features = uitabgroup(app.NEO);
            app.Features.AutoResizeChildren = 'off';
            app.Features.Position = [1 1 620 351];

            % Create Testing
            app.Testing = uitab(app.Features);
            app.Testing.AutoResizeChildren = 'off';
            app.Features.SelectionChangedFcn = createCallbackFcn(app, @FeaturesSelectionChanged, true);
            app.Testing.Title = 'Testing';

            % Create OpenTESTButton
            app.OpenTESTButton = uibutton(app.Testing, 'push');
            app.OpenTESTButton.ButtonPushedFcn = createCallbackFcn(app, @OpenTESTButtonPushed, true);
            app.OpenTESTButton.Position = [460 278 99 22];
            app.OpenTESTButton.Text = 'Open';

            % Create CreateExcel
            app.CreateExcel = uicheckbox(app.Testing);
            app.CreateExcel.ValueChangedFcn = createCallbackFcn(app, @CreateExcelValueChanged, true);
            app.CreateExcel.Text = ' Generate test files';
            app.CreateExcel.Position = [71 195 123 22];

            % Create ExecuteTEST
            app.ExecuteTEST = uibutton(app.Testing, 'push');
            app.ExecuteTEST.ButtonPushedFcn = createCallbackFcn(app, @ExecuteTESTButtonPushed, true);
            app.ExecuteTEST.Enable = 'off';
            app.ExecuteTEST.Position = [188 55 243 22];
            app.ExecuteTEST.Text = 'Select something';

            % Create StatusTESTLabel
            app.StatusTESTLabel = uilabel(app.Testing);
            app.StatusTESTLabel.HorizontalAlignment = 'center';
            app.StatusTESTLabel.FontWeight = 'bold';
            app.StatusTESTLabel.FontAngle = 'italic';
            app.StatusTESTLabel.Position = [76 21 467 22];
            app.StatusTESTLabel.Text = 'Select model to test';

            % Create UpdateHarness
            app.UpdateHarness = uicheckbox(app.Testing);
            app.UpdateHarness.ValueChangedFcn = createCallbackFcn(app, @UpdateHarnessValueChanged, true);
            app.UpdateHarness.Text = ' Complete harness';
            app.UpdateHarness.Position = [248 195 123 22];

            % Create UpdateCases
            app.UpdateCases = uicheckbox(app.Testing);
            app.UpdateCases.ValueChangedFcn = createCallbackFcn(app, @UpdateCasesValueChanged, true);
            app.UpdateCases.Text = ' Update test cases';
            app.UpdateCases.Position = [436 195 121 22];

            % Create ModelNameEditFieldLabel
            app.ModelNameEditFieldLabel = uilabel(app.Testing);
            app.ModelNameEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelNameEditFieldLabel.Position = [40 278 77 22];
            app.ModelNameEditFieldLabel.Text = 'Model Name:';

            % Create ModelNameEditField
            app.ModelNameEditField = uieditfield(app.Testing, 'text');
            app.ModelNameEditField.Editable = 'off';
            app.ModelNameEditField.Position = [147 278 290 22];

            % Create TestingPanel
            app.TestingPanel = uipanel(app.Testing);
            app.TestingPanel.AutoResizeChildren = 'off';
            app.TestingPanel.BorderType = 'none';
            app.TestingPanel.Title = '      ';
            app.TestingPanel.Position = [44 84 531 113];

            % Create RunTests
            app.RunTests = uicheckbox(app.TestingPanel);
            app.RunTests.ValueChangedFcn = createCallbackFcn(app, @RunTestsValueChanged, true);
            app.RunTests.Text = ' Run MIL';
            app.RunTests.Position = [131 59 71 22];

            % Create MILReport
            app.MILReport = uicheckbox(app.TestingPanel);
            app.MILReport.ValueChangedFcn = createCallbackFcn(app, @MILReportValueChanged, true);
            app.MILReport.Text = ' MIL Report';
            app.MILReport.Position = [131 21 85 22];

            % Create Panel
            app.Panel = uipanel(app.Testing);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.ForegroundColor = [1 0.4118 0.1608];
            app.Panel.BorderType = 'none';
            app.Panel.BackgroundColor = [0.8706 0.8706 0.8706];
            app.Panel.Position = [321 98 205 72];

            % Create RunSIL
            app.RunSIL = uicheckbox(app.Panel);
            app.RunSIL.ValueChangedFcn = createCallbackFcn(app, @RunSILValueChanged, true);
            app.RunSIL.Text = ' Run SIL';
            app.RunSIL.Position = [9 45 69 22];

            % Create SLDVButton
            app.SLDVButton = uibutton(app.Panel, 'state');
            app.SLDVButton.ValueChangedFcn = createCallbackFcn(app, @SLDVButtonValueChanged, true);
            app.SLDVButton.Text = 'Without SLDV';
            app.SLDVButton.Position = [98 27 100 22];

            % Create SILReport
            app.SILReport = uicheckbox(app.Panel);
            app.SILReport.ValueChangedFcn = createCallbackFcn(app, @SILReportValueChanged, true);
            app.SILReport.Text = ' SIL Report';
            app.SILReport.Position = [9 7 83 22];

            % Create ModelVersionEditFieldLabel
            app.ModelVersionEditFieldLabel = uilabel(app.Testing);
            app.ModelVersionEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelVersionEditFieldLabel.Position = [348 236 85 22];
            app.ModelVersionEditFieldLabel.Text = 'Model Version:';

            % Create ModelVersionEditField
            app.ModelVersionEditField = uieditfield(app.Testing, 'text');
            app.ModelVersionEditField.ValueChangedFcn = createCallbackFcn(app, @ModelVersionEditFieldValueChanged, true);
            app.ModelVersionEditField.Editable = 'off';
            app.ModelVersionEditField.Value = '';
            app.ModelVersionEditField.HorizontalAlignment = 'center';
            app.ModelVersionEditField.Position = [440 236 38 22];
            

            % Create AUTOSARButton
            app.AUTOSARButton = uibutton(app.Testing, 'state');
            app.AUTOSARButton.ValueChangedFcn = createCallbackFcn(app, @AUTOSARButtonValueChanged, true);
            app.AUTOSARButton.Text = 'AUTOSAR';
            app.AUTOSARButton.BackgroundColor = [0 0.902 0];
            app.AUTOSARButton.Position = [167 236 100 22];

            % Create ThisisanLabel
            app.ThisisanLabel = uilabel(app.Testing);
            app.ThisisanLabel.Position = [108 236 57 22];
            app.ThisisanLabel.Text = 'This is an';

            % Create modelLabel
            app.modelLabel = uilabel(app.Testing);
            app.modelLabel.Position = [275 236 38 22];
            app.modelLabel.Text = 'model';

            % Create ARXML
            app.ARXML = uitab(app.Features);
            app.ARXML.AutoResizeChildren = 'off';
            app.ARXML.Title = 'Frame Generation';

            % Create OpenARXMLButton
            app.OpenARXMLButton = uibutton(app.ARXML, 'push');
            app.OpenARXMLButton.ButtonPushedFcn = createCallbackFcn(app, @OpenARXMLButtonPushed, true);
            app.OpenARXMLButton.Position = [461 278 105 22];
            app.OpenARXMLButton.Text = 'Open';

            % Create ExecuteARXML
            app.ExecuteARXML = uibutton(app.ARXML, 'push');
            app.ExecuteARXML.ButtonPushedFcn = createCallbackFcn(app, @ExecuteARXMLButtonPushed, true);
            app.ExecuteARXML.Enable = 'off';
            app.ExecuteARXML.Position = [190 67 226 22];
            app.ExecuteARXML.Text = 'Create frame model & data type scripts';

            % Create StatusARXMLLabel
            app.StatusARXMLLabel = uilabel(app.ARXML);
            app.StatusARXMLLabel.HorizontalAlignment = 'center';
            app.StatusARXMLLabel.FontWeight = 'bold';
            app.StatusARXMLLabel.FontAngle = 'italic';
            app.StatusARXMLLabel.Position = [46 35 522 23];
            app.StatusARXMLLabel.Text = 'Select .arxml file';

            % Create UpdateModel
            app.UpdateModel = uicheckbox(app.ARXML);
            app.UpdateModel.ValueChangedFcn = createCallbackFcn(app, @UpdateModelValueChanged, true);
            app.UpdateModel.Text = ' Update Model';
            app.UpdateModel.Position = [466 176 100 22];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.ARXML);
            app.ButtonGroup.AutoResizeChildren = 'off';
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.BorderType = 'none';
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.Position = [45 209 463 50];

            % Create ApplicationButton
            app.ApplicationButton = uitogglebutton(app.ButtonGroup);
            app.ApplicationButton.Text = 'Application';
            app.ApplicationButton.Position = [111 18 100 22];
            app.ApplicationButton.Value = true;

            % Create SensorActuatorButton
            app.SensorActuatorButton = uitogglebutton(app.ButtonGroup);
            app.SensorActuatorButton.Text = 'Sensor-Actuator';
            app.SensorActuatorButton.Position = [221 18 100 22];

            % Create CompositionsButton
            app.CompositionsButton = uitogglebutton(app.ButtonGroup);
            app.CompositionsButton.Text = 'Compositions';
            app.CompositionsButton.Position = [333 18 100 22];

            % Create ComponentsLabel
            app.ComponentsLabel = uilabel(app.ButtonGroup);
            app.ComponentsLabel.Position = [1 18 77 22];
            app.ComponentsLabel.Text = 'Components:';

            % Create SelectModelButton
            app.SelectModelButton = uibutton(app.ARXML, 'push');
            app.SelectModelButton.ButtonPushedFcn = createCallbackFcn(app, @SelectModelButtonPushed, true);
            app.SelectModelButton.Enable = 'off';
            app.SelectModelButton.Position = [462 124 104 22];
            app.SelectModelButton.Text = 'Select Model';

            % Create SelectcomponentDropDownLabel
            app.SelectcomponentDropDownLabel = uilabel(app.ARXML);
            app.SelectcomponentDropDownLabel.Position = [45 176 105 22];
            app.SelectcomponentDropDownLabel.Text = 'Select component:';

            % Create SelectcomponentDropDown
            app.SelectcomponentDropDown = uidropdown(app.ARXML);
            app.SelectcomponentDropDown.Items = {'Component'};
            app.SelectcomponentDropDown.ValueChangedFcn = createCallbackFcn(app, @SelectcomponentDropDownValueChanged, true);
            app.SelectcomponentDropDown.Position = [154 176 282 22];
            app.SelectcomponentDropDown.Value = 'Component';

            % Create NameofarxmlLabel
            app.NameofarxmlLabel = uilabel(app.ARXML);
            app.NameofarxmlLabel.Position = [45 278 87 22];
            app.NameofarxmlLabel.Text = 'Name of arxml:';

            % Create NameofarxmlField
            app.NameofarxmlField = uieditfield(app.ARXML, 'text');
            app.NameofarxmlField.Editable = 'off';
            app.NameofarxmlField.Position = [155 278 285 22];

            % Create NameofmodelLabel
            app.NameofmodelLabel = uilabel(app.ARXML);
            app.NameofmodelLabel.Enable = 'off';
            app.NameofmodelLabel.Position = [45 124 90 22];
            app.NameofmodelLabel.Text = 'Name of model:';

            % Create Nameofmodel
            app.Nameofmodel = uieditfield(app.ARXML, 'text');
            app.Nameofmodel.Editable = 'off';
            app.Nameofmodel.Enable = 'off';
            app.Nameofmodel.Position = [154 124 282 22];

        end
    end

    methods (Access = public)

        % Construct app
        function app = neo_app

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NEO)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NEO)
        end
    end
end