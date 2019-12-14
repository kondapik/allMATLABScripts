%{
	First Input: Selecting the model under test. 
	Second Input: To create harness or execute test

	STEPS TO EXECUTE
	1: 

%%
	DECRIPTION:
	Creates harness for an AUTOSAR compliant model with a data dictionary 
	and an excel sheet to fill test case data(Testcase ID, Inputs and Expected Outputs).
	Signal builder contains all test cases and test results will updated in excel.
  
	(Note: Input 'text' for Enums not int value)
%%
	CREATED BY : Kondapi V S Krishna Prasanth
	DATE OF CREATION: 27-May-2019
%%
	VERSION MANAGER
	v1      Treat each row as a test case and create one signal group)
	v2      Treat each test case as its own signal group.
	v3      Created functions to create Excel, Update Harness, MIL and SIL.
            Updated GUI with both MIL and SIL options
            Port selection (based on fill color) to print required signals in report
            Updated harness to handle report generator requirements and float comparision       
            Setting configuration of harness model
            Option to update test cases
            Seperate functions to read and write data to excel
	v3.1	Updated naming convention and seperate harness for MIL and SIL
            CreateHarness and UpdateHarness handles MIL and SIL harnesses
    v3.2    Fix: Removed Excel handles in mat file
            Fix: Changed sample time of Init Function call block
	v3.3    Fix: Results of first timestep are overlooked in updating excel
			Fix: Sometimes SIL is updating model which results in a code generation error
	v4b		Updated GUI to control new features
			Added Non autodar testing support
			Updating model history
			MIL & SIL report generation
			SLDV button disabled(beta)
			Added exception handling
			Map to update status instead of switch-case
			Configuration changes according to MIL or SIL execution
	v4 		Reading and writing data from excel is independent of time step (Sample Time)
			Better error handling
            Option to import SLDV test cases
%}

classdef Testing_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        OpenButton                  matlab.ui.control.Button
        CreateExcel                 matlab.ui.control.CheckBox
        Execute                     matlab.ui.control.Button
        SelectmodeltotestLabel      matlab.ui.control.Label
        UpdateHarness               matlab.ui.control.CheckBox
        UpdateCases                 matlab.ui.control.CheckBox
        AUTOSARButton               matlab.ui.control.StateButton
        TestingPanel                matlab.ui.container.Panel
        RunTests                    matlab.ui.control.CheckBox
        MILReport                   matlab.ui.control.CheckBox
        SILReport                   matlab.ui.control.CheckBox
        Panel                       matlab.ui.container.Panel
        RunSIL                      matlab.ui.control.CheckBox
        SLDVButton           		matlab.ui.control.StateButton
        ModelNameEditFieldLabel     matlab.ui.control.Label
        ModelNameEditField          matlab.ui.control.EditField
        ModelVersionEditFieldLabel  matlab.ui.control.Label
        ModelVersionEditField       matlab.ui.control.EditField
        ThisisanLabel               matlab.ui.control.Label
        modelLabel                  matlab.ui.control.Label
    end

    
    properties (Access = private)
        rootPath
        ModelName
        OnlyModelName
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
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            evalin('base','clear');
            keys = {'00000001','00000000','00000010','00000100','00001000','00001010','00001100','00010000','00010010','00010100','00011000','00011010','00011100','00100000','00100010','00100100','00101000','00101010','00101100','00110000','00110010','00110100','00111000','00111010','00111100','01000000','01001000','01001010','01001100','01010000','01010010','01010100','01011000','01011010','01011100','01100000','01101000','01101010','01101100','01110000','01110010','01110100','01111000','01111010','01111100','10000000','10001000','10001010','10001100','10010000','10010010','10010100','10011000','10011010','10011100','10100000','10101000','10101010','10101100','10110000','10110010','10110100','10111000','10111010','10111100','11000000','11001000','11001010','11001100','11010000','11010010','11010100','11011000','11011010','11011100','11100000','11101000','11101010','11101100','11110000','11110010','11110100','11111000','11111010','11111100','00100001'};
            values = {'Create Excel''^^^''Creates test case Excel and frame harness''^^^''on','Not an option''^^^''Select something, I don''t have much time''^^^''off','Complete harness''^^^''Extract data from excel and updates harness''^^^''on','Update test cases''^^^''Updates signal builder with new test cases from excel''^^^''on','Execute MIL test''^^^''Executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates harness, executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates test cases, executes MIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Executes SIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Updates harness, executes SIL & updates results in Excel''^^^''on','Execute SIL test''^^^''Updates test cases, executes SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Not an option''^^^''Select something, I don''t have much time''^^^''off','Complete harness''^^^''Extract data from excel and updates harness''^^^''on','Update test cases''^^^''Updates signal builder with new test cases from excel''^^^''on','Execute MIL test''^^^''Executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates harness, executes MIL & updates results in Excel''^^^''on','Execute MIL test''^^^''Updates test cases, executes MIL & updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Executes SIL with SLDV& updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates harness, executes SIL with SLDV & updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates test cases, executes SIL with SLDV& updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate MIL report''^^^''Generates MIL report''^^^''on','Execute MIL test & generate report''^^^''Executes MIL, updates results in Excel & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates harness, executes MIL, updates results in Excel  & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates test cases, executes MIL, updates results in Excel  & generates report''^^^''on','Execute SIL test & generate MIL report''^^^''Executes SIL, updates results in Excel & generates MIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates MIL report''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate MIL report''^^^''Generates MIL report''^^^''on','Execute MIL test & generate report''^^^''Executes MIL, updates results in Excel & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates harness, executes MIL, updates results in Excel  & generates report''^^^''on','Execute MIL test & generate report''^^^''Updates test cases, executes MIL, updates results in Excel  & generates report''^^^''on','Execute SIL test & generate MIL report''^^^''Executes SIL, updates results in Excel & generates MIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate SIL Report''^^^''Generates SIL report''^^^''on','Execute MIL test & generate SIL report''^^^''Executes MIL, updates results in Excel & generates SIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate report''^^^''Executes SIL, updates results in Excel & generates report''^^^''on','Execute SIL test & generate report''^^^''Updates harness, executes SIL, updates results in Excel  & generates report''^^^''on','Execute SIL test & generate report''^^^''Updates test cases, executes SIL, updates results in Excel  & generates report''^^^''on','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates SIL report''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate SIL report''^^^''Generates SIL report''^^^''on','Execute MIL test & generate SIL report''^^^''Executes MIL, updates results in Excel & generates SIL report''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL with SLDV''^^^''Executes SIL with SLDV, updates results in Excel & generates SIL report''^^^''on','Execute SIL with SLDV''^^^''Updates harness, executes SIL with SLDV& updates results in Excel''^^^''on','Execute SIL with SLDV''^^^''Updates test cases, executes SIL with SLDV& updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV updates results in Excel  & generates report''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Generate MIL & SIL reports''^^^''Generate MIL & SIL reports''^^^''on','Execute MIL test & generate reports''^^^''Executes MIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate reports''^^^''Executes SIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL''^^^''Executes MIL, SIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Execute MIL & SIL''^^^''Updates harness, executes MIL, SIL & updates results in Excel''^^^''on','Execute MIL & SIL''^^^''Updates test cases, executes MIL, SIL & updates results in Excel''^^^''on','Generate MIL & SIL reports''^^^''Generates MIL & SIL reports''^^^''on','Execute MIL test & generate reports''^^^''Executes MIL, updates results in Excel & generates MIL and SIL reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate SIL report without SIL testing''^^^''off','Execute SIL test & generate reports''^^^''Executes SIL with SLDV, updates results in Excel & generates reports''^^^''on','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Not an option''^^^''Doesn''t work, cannot generate MIL report without MIL testing''^^^''off','Execute MIL & SIL with SLDV''^^^''Executes MIL, SIL with SLDV updates results in Excel  & generates reports''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates harness, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Execute MIL & SIL with SLDV''^^^''Updates test cases, executes MIL, SIL with SLDV & updates results in Excel''^^^''on','Create Excel''^^^''Creates test case Excel and frame harness''^^^''on'};
            app.optionsMap = containers.Map(keys,values);
        end

        % Button pushed function: OpenButton
        function OpenButtonPushed(app, event)
            [app.ModelName,app.rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to test');
            app.SelectmodeltotestLabel.FontColor = [0 0 0];
            %app.UIFigure
            figure(app.UIFigure);
            if isequal(app.ModelName,0)
                app.Execute.Text = 'Select';
                app.SelectmodeltotestLabel.Text = 'Select model to test';
                app.Execute.Enable = 'off';
            else
                app.OnlyModelName = strsplit(app.ModelName,'.');
                app.OnlyModelName = app.OnlyModelName{1,1};
                app.harness_name_MIL = sprintf('MIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.harness_name_SIL = sprintf('SIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.Execute.Text = 'Select';
                app.SelectmodeltotestLabel.Text = 'Select one or more options';
                app.ModelNameEditField.Value = app.ModelName;
                updateStatus(app);
            end
        end

        % 
        function updateStatus(app)
            valid_run = 'off';

            %treating check box values as binary(?)
            % MSB SILReport MILReport SLDVButton RunSIL RunTests UpdateCases UpdateHarness CreateExcel LSB -> followed

            %app.option_value = (app.CreateExcel.Value*(10^0))+(app.UpdateHarness.Value*(10^1))+(app.UpdateCases.Value*(10^2))+(app.RunTests.Value*(10^3))...
            %	+(app.RunSIL.Value*(10^4))+(app.SLDVButton.Value*(10^5))+(app.MILReport.Value*(10^6))+(app.SILReport.Value*(10^7));

            app.option_value = sprintf('%d%d%d%d%d%d%d%d',app.SILReport.Value,app.MILReport.Value,app.SLDVButton.Value,app.RunSIL.Value,...
            	app.RunTests.Value,app.UpdateCases.Value,app.UpdateHarness.Value,app.CreateExcel.Value);

            app.SelectmodeltotestLabel.FontColor = [0 0 0];
            app.Execute.Text = 'Not an option';
            if app.CreateExcel.Value == 1 && (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1) || isequal(app.RunTests.Value,1) || isequal(app.RunSIL.Value,1)...
                    || isequal(app.MILReport.Value,1) || isequal(app.SILReport.Value,1))       	
                app.SelectmodeltotestLabel.Text = 'Combination doesn''t work. I cannot simulate model without TC';
        	elseif isequal(app.UpdateHarness.Value,1) && isequal(app.UpdateCases.Value,1)
                app.SelectmodeltotestLabel.Text = 'Deselect, either ''Complete harness'' or ''Update Test cases''';
        	elseif (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1)) && (isequal(app.RunTests.Value,0) && isequal(app.RunSIL.Value,0))...
        		&& (isequal(app.MILReport.Value,1) || isequal(app.SILReport.Value,1))
                app.SelectmodeltotestLabel.Text = 'Doesn''t work, cannot generate report(s) without testing';
        	end

        	try
	        	dispText = app.optionsMap(app.option_value);
	        	splits = strsplit(dispText,'^^^');
	        	tempText = splits{1,1};
	        	app.Execute.Text = tempText(1:end-1);
	        	tempText = splits{1,2};
	        	app.SelectmodeltotestLabel.Text = tempText(2:end-1);
	        	tempText = splits{1,3};
	        	valid_run = tempText(2:end);
            catch
	        	%fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end

            if isequal(app.ModelName,0) || isempty(app.ModelName)
                app.Execute.Text = 'Select';
                app.SelectmodeltotestLabel.Text = 'Select model to test';
                valid_run = 'off';
            end
            app.Execute.Enable = valid_run;
            drawnow
        end

        % Value changed function: CreateExcel
        function CreateExcelValueChanged(app, event) % enable changing model version
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'on';
        end

        % Value changed function: UpdateHarness
        function UpdateHarnessValueChanged(app, event)
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'off';
        end

        % Value changed function: RunTests
        function RunTestsValueChanged(app, event)
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'off';
        end

        % Value changed function: RunSIL
        function RunSILValueChanged(app, event)
            updateStatus(app); %RunSIL
            app.ModelVersionEditField.Editable = 'off';
        end

        % Value changed function: UpdateCases
        function UpdateCasesValueChanged(app, event)
            %value = app.UpdateCases.Value;
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'off';
        end

        % Value changed function: MILReport
        function MILReportValueChanged(app, event)
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'off';
        end

        % Value changed function: SILReport
        function SILReportValueChanged(app, event)
            updateStatus(app);
            app.ModelVersionEditField.Editable = 'off';
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
                app.RunSIL.Enable = 'off';
                app.SLDVButton.Enable = 'off';
                app.SILReport.Enable = 'off';
            end
            %app.SLDVButton.Enable = 'off'; %remove this after beta release
            drawnow
        end

        % Value changed function: SLDVButton
        function SLDVButtonValueChanged(app, event)
            if app.SLDVButton.Value == 0
                app.SLDVButton.Text = 'Without SLDV';
            else
                app.SLDVButton.Text = 'With SLDV';
            end
            drawnow
        end

        % Create Excel and frame harness
        function CreateExcel_Data(app,DataDictionary,DataDictSec)
        	try
        		errorCode = 1; %Error in creating harness
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','Creating test case Excel',...
                            'Message','Creating test harness','Indeterminate','on');
        		drawnow

	            app.port_data = struct('Name',{},'OutDataType',{},'BaseDataType',{},'Position',{},'Handle',{},'Values',{});
	            %add_block('simulink/Signal Attributes/Data Type Conversion','OutDataTypeStr','AliasType or Enum: <classname>');
	            save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName));
	            app.dataMatfile = matfile(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'Writable',true);
	            
	            inports = find_system(app.OnlyModelName, 'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'Inport');
	            app.SelectmodeltotestLabel.Text = 'Creating harness';
	            drawnow
	            
	            harness_handle = new_system(app.harness_name_MIL);
	            %set_param(harness_handle,'Solver','FixedStepDiscrete','FixedStep','0.01');
	            open_system(harness_handle);
	            figure(app.UIFigure);
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

	            load_system(app.OnlyModelName);

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

	            app.SelectmodeltotestLabel.Text = 'Creating harness - Analyzing model';
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
	            app.no_inports = length(inports);
	            for AllPorts = 1:app.no_inports
	                name = get_param(inports(AllPorts),'Name');
	                app.port_data(AllPorts).Name = name{1,1};
	                app.port_data(AllPorts).Position = all_PortPos(AllPorts);
	                app.port_data(AllPorts).Position = app.port_data(AllPorts).Position{1,1};
	                app.port_data(AllPorts).Handle = inportHandles(AllPorts);
	                if cellfun(@isempty,regexpi(inports(AllPorts),'Rnbl_.*'))
	                    out_data_type = get_param(inports(AllPorts),'OutDataTypeStr');
	                    app.port_data(AllPorts).OutDataType = out_data_type{1,1};
	                    if isempty(regexpi(app.port_data(AllPorts).OutDataType,'Enum: .*'))
	                        if app.AUTOSAR_stat == 1
	                            entryObj = getEntry(DataDictSec,app.port_data(AllPorts).OutDataType);
	                            aliasValue = getValue(entryObj);
	                            app.port_data(AllPorts).BaseDataType = aliasValue.BaseType;
	                        else
	                        	if ~isequal(app.port_data(AllPorts).OutDataType,'Inherit: auto')
	                            	app.port_data(AllPorts).BaseDataType = app.port_data(AllPorts).OutDataType;
	                            else
	                            	error('Data type not assigned to ''%s'' inport',app.port_data(AllPorts).Name);
	                            	errorCode = 33; %Data type not provided for non autosar model. Delete harness
	                            end
	                        end
	                    else
	                        app.port_data(AllPorts).BaseDataType = 'Enum';
	                    end
	                else
	                    app.no_rnbls = app.no_rnbls + 1;
	                end
	            end

	            if app.AUTOSAR_stat == 1
		            AllPorts = AllPorts + 1;
		            app.port_data(AllPorts).Name = 'initialize';
		            app.port_data(AllPorts).Position = all_PortPos(AllPorts);
		            app.port_data(AllPorts).Position = app.port_data(AllPorts).Position{1,1};
		            app.port_data(AllPorts).Handle = inportHandles(AllPorts);
		        end
	            
	            
	            outports = find_system(app.OnlyModelName, 'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'Outport');
	            outportHandles = AllPortHandles.Outport;
	            app.no_outports = length(outports);
	            for AllPorts = (app.no_inports+1+app.AUTOSAR_stat):(app.no_inports+app.AUTOSAR_stat+app.no_outports)
	                name = get_param(outports(AllPorts-app.no_inports-app.AUTOSAR_stat),'Name');
	                app.port_data(AllPorts).Name = name{1,1};
	                out_data_type = get_param(outports(AllPorts-app.no_inports-app.AUTOSAR_stat),'OutDataTypeStr');
	                app.port_data(AllPorts).OutDataType = out_data_type{1,1};
	                app.port_data(AllPorts).Position = all_PortPos(AllPorts);
	                app.port_data(AllPorts).Position = app.port_data(AllPorts).Position{1,1};
	                app.port_data(AllPorts).Handle = outportHandles(AllPorts-app.no_inports-app.AUTOSAR_stat);
	                if isempty(regexpi(app.port_data(AllPorts).OutDataType,'Enum: .*'))
	                    if app.AUTOSAR_stat == 1
		                    entryObj = getEntry(DataDictSec,app.port_data(AllPorts).OutDataType);
		                    aliasValue = getValue(entryObj);
		                    app.port_data(AllPorts).BaseDataType = aliasValue.BaseType;
		                else
		                	if ~isequal(app.port_data(AllPorts).OutDataType,'Inherit: auto')
                            	app.port_data(AllPorts).BaseDataType = app.port_data(AllPorts).OutDataType;
                            else
                            	error('Data type not assigned to ''%s'' outport',app.port_data(AllPorts).Name);
                            	errorCode = 33; %Data type not provided for non autosar model. Delete harness
                            end
		                end
	                else
	                    app.port_data(AllPorts).BaseDataType = 'Enum';
	                end
	            end
	            
	            errorCode = 4; %error in adding function call generator

	            if app.AUTOSAR_stat == 1 
		            add_block('simulink/Ports & Subsystems/Function-Call Generator',...
		                    sprintf('%s/InitFunCallGen',app.harness_name_MIL),'sample_time','11',...
		                    'Position',[app.port_data(app.no_inports+1).Position(1)-85-20 app.port_data(app.no_inports+1).Position(2)-11 app.port_data(app.no_inports+1).Position(1)-85 app.port_data(app.no_inports+1).Position(2)+11]);
		            add_line(app.harness_name_MIL,'InitFunCallGen/1',sprintf('%s/%d',app.OnlyModelName,app.no_inports+1));
		               
		            if app.no_rnbls == 1
		                add_block('simulink/Ports & Subsystems/Function-Call Generator',...
		                    sprintf('%s/FunCallGen',app.harness_name_MIL),'sample_time','0.01',...
		                    'Position',[app.port_data(1).Position(1)-85-20 app.port_data(1).Position(2)-11 app.port_data(1).Position(1)-85 app.port_data(1).Position(2)+11]);
		                add_line(app.harness_name_MIL,'FunCallGen/1',sprintf('%s/1',app.OnlyModelName));  
		            else
		                add_block('simulink/Ports & Subsystems/Function-Call Split',...
		                    sprintf('%s/FunCallSplit',app.harness_name_MIL),'NumOutputPorts',num2str(app.no_rnbls),...
		                    'Position',[app.port_data(1).Position(1)-55 app.port_data(1).Position(2)-25 app.port_data(1).Position(1)-30 app.port_data(1).Position(2)+25+((app.no_rnbls-1)*55)]);
		                
		                outSrc = cell.empty(0,app.no_rnbls);
		                inDest = outSrc;
		                for i = 1:app.no_rnbls
		                    outSrc(i) = {sprintf('FunCallSplit/%d',i)};
		                    inDest(i) = {sprintf('%s/%d',app.OnlyModelName,i)};
		                end
		                add_line(app.harness_name_MIL,outSrc,inDest,'autorouting','on');
		                
		                add_block('simulink/Ports & Subsystems/Function-Call Generator',...
		                    sprintf('%s/FunCallGen',app.harness_name_MIL),'sample_time','0.01',...
		                    'Position',[app.port_data(1).Position(1)-85-20 app.port_data(1).Position(2)-11+((app.no_rnbls-1)*55/2) app.port_data(1).Position(1)-85 app.port_data(1).Position(2)+11+((app.no_rnbls-1)*55/2)]);
		                add_line(app.harness_name_MIL,{'FunCallGen/1'},{'FunCallSplit/1'},'autorouting','on');
		            end
		        end

		        errorCode = 5; %error updating excel. delete harness and retry
		        prog_stat.Message = 'Harness created. Creating Excel workbook';
	            app.SelectmodeltotestLabel.Text = 'Harness created. Creating Excel workbook';
	            drawnow

	            app.no_inports = app.no_inports - app.no_rnbls;
	            Excel = actxserver('Excel.Application');
	            Ex_Workbook = Excel.Workbooks.Add;
	            Ex_Sheets = Excel.ActiveWorkbook.Sheets;
	            Ex_actSheet = Ex_Sheets.get('Item',1);
	            Ex_actSheet.Name = app.OnlyModelName;
	            SaveAs(Ex_Workbook,sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
	            figure(app.UIFigure);
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
	                    Ex_range = Ex_range.get('Offset',-2,-(app.no_outports-1));
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
	            Ex_range = Ex_range.get('Offset',3,-(6+app.no_inports+(2*app.no_outports))); % error with No_inports with non autosar
	            Ex_range.Value = '*Start Here*';
	            Ex_actSheet.Cells.Borders.Item('xlInsideHorizontal').LineStyle = 1;
	            Ex_actSheet.Cells.Borders.Item('xlInsideVertical').LineStyle = 1;
	            Ex_Workbook.Save;
	            
	             
	            app.dataMatfile.port_data = app.port_data;
	            app.dataMatfile.no_inports = app.no_inports;
	            app.dataMatfile.no_outports = app.no_outports;
	            app.dataMatfile.no_rnbls = app.no_rnbls;
	            close(prog_stat);
	            uialert(app.UIFigure,'Populate Excel with test cases and complete harness','Success','icon','success');
	            app.SelectmodeltotestLabel.Text = 'Populate Excel with test cases and complete harness';
	        catch ErrorCaught
                assignin('base','ErrorInfo_CreateExcel',ErrorCaught);
                app.errorFlag = 1;
                close(prog_stat);
                warning('-----------Unable to test harness and Excel. Delete any harness or Excel files generated. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to test harness and Excel. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                if isequal(exist(app.harness_name_MIL),4)
                	close_system(app.harness_name_MIL,0);
                	delete(sprintf('%s.slx',app.harness_name_MIL));
                end
                switch errorCode
                	case 1
                		%Error in creating harness
                		uialert(app.UIFigure,'Unable to create harness. Retry after fixing error. Check command window for error info','Error');
                	case 2
                		%Error in setting configuration of harness
                		uialert(app.UIFigure,'Unable to set harness configuration. Check if configuration is set for model through DD. Retry after fixing error. Check command window for error info','Error');
                		warning('-----------Check if configuration is set for model through data dictionary-----------');
                	case 3
                		%error in reading port information mostly issue with data dictionary
                		uialert(app.UIFigure,'Incorrect port details (mostly, data type issues either in model or DD). Retry after fixing error. Check command window for error info','Error');
                	case 33
                		%Data type not provided for non autosar model. Delete harness
                		uialert(app.UIFigure,'Port data type not provided in non autosar model. Retry after fixing error. Check command window for error info','Error');
                	case 4
                		%error in adding function call generator
                		uialert(app.UIFigure,'Unable to add function call generators. Retry after fixing error. Check command window for error info','Error');
                	case 5
                		%error updating excel. delete harness and retry
                		uialert(app.UIFigure,'Unable to update Excel. Delete generated files and retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end
            
        end

        % CreatingHarness
        function CreateHarness(app)

        	try
        		errorCode = 1; %Error in reading Excel
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		app.SelectmodeltotestLabel.Text = 'Importing test cases from Excel';
        		drawnow
        		figure(app.UIFigure);

	            harness_handle = get_param(app.harness_name_MIL,'Handle');

	            caughtError = ReadingExcel(app);
            	throwError(app,caughtError,'Unable to read excel. Check previous messages for error info');

	            prog_stat = uiprogressdlg(app.UIFigure,'Title','Completing harness',...
                            'Message','Adding signal builder and other required blocks','Indeterminate','on');
	            drawnow
	            errorCode = 2; %Error in adding signal builder and other blocks
	            %replace app.port_data with app.test_data(caseNo).SigData
	            for caseNo = 1:length(app.test_data)
	                %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;

	                if caseNo == 1
	                    %Inputs_ExpectedOutput = Simulink.SimulationData.Dataset;
	                    %Inputs_ExpectedOutput.Name = 'Input&ExpectedOutput';
	                    app.SelectmodeltotestLabel.Text = 'Updating harness';
	                    drawnow
	%{
	                    scope_height = app.no_outports*45+40;
	                    ref_position = get_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'Position');
	                    scope_handle = add_block('simulink/Sinks/Scope',sprintf('%s/Scope',app.harness_name_MIL),...
	                        'Position',[ref_position(3)+420 ref_position(4)-scope_height ref_position(3)+550 ref_position(4)+scope_height]);
	                    scope_config = get_param(scope_handle,'ScopeConfiguration');
	                    scope_config.NumInputPorts = num2str(2*app.no_outports);
	                    scope_ports = get_param(scope_handle,'PortConnectivity');
	%}

	                    port_no = app.no_rnbls+1;
	                    %values = size(timeStamps);
	                    signal_no = 1;
	                    %re_timeStamps = reshape(timeStamps,values(2),1);
	                    %data = reshape(app.port_data(port_no).Values,values(2),1);
	                    %temp_timeseries = timeseries(data,re_timeStamps,'Name',app.port_data(port_no).Name);
	                    block = signalbuilder(sprintf('%s/SignalGen',app.harness_name_MIL),'create',app.test_data(caseNo).SigTime,app.test_data(caseNo).SigData(port_no).Values,app.test_data(caseNo).SigData(port_no).Name,app.test_data(caseNo).TestCaseID);
	                    set_param(block,'Position',[app.test_data(caseNo).SigData(port_no).Position(1)-735 app.test_data(caseNo).SigData(port_no).Position(2)-31 app.test_data(caseNo).SigData(port_no).Position(1)-390 ...
	                        app.test_data(caseNo).SigData(port_no).Position(2)+((app.no_inports+app.no_outports-1)*55)+11]);
	                    gen_handles = get_param(block,'PortHandles');
	                    ref_port_handles = get_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'PortHandles');
	                    convert_handle = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d',app.harness_name_MIL,signal_no),...
	                        'Position',[app.test_data(caseNo).SigData(port_no).Position(1)-265 app.test_data(caseNo).SigData(port_no).Position(2)-10 app.test_data(caseNo).SigData(port_no).Position(1)-190 app.test_data(caseNo).SigData(port_no).Position(2)+10]...
	                        ,'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).OutDataType,'ShowName','off');
	                    convert_port = get_param(convert_handle,'PortHandles');
	                    set_param(convert_port.Outport(1),'DataLogging','on','DataLoggingName',app.test_data(caseNo).SigData(port_no).Name);
	                    if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
	                        old_pos = get_param(convert_handle,'Position');
	                        int_convert = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d_int8',app.harness_name_MIL,signal_no),...
	                            'Position', [old_pos(1)-100 old_pos(2) old_pos(3)-100 old_pos(4)],'OutDataTypeStr','uint8','ShowName','off');
	                        int_convert_port = get_param(int_convert,'PortHandles');
	                        add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),int_convert_port.Inport(1));
	                        add_line(app.harness_name_MIL,int_convert_port.Outport(1),convert_port.Inport(1));
	                    else
	                        add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),convert_port.Inport(1));
	                    end
	                    line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),ref_port_handles.Inport(port_no));
	                    set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name);

	                    add_block('simulink/Sinks/Scope',sprintf('%s/ScopeIn_%d',app.harness_name_MIL,signal_no),'Position',...
	                        [app.test_data(caseNo).SigData(port_no).Position(1)-40 app.test_data(caseNo).SigData(port_no).Position(2)+4 app.test_data(caseNo).SigData(port_no).Position(1)-10 app.test_data(caseNo).SigData(port_no).Position(2)+36]);
	                    add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('ScopeIn_%d/1',signal_no),'autorouting','on');

	                    port_position = app.test_data(caseNo).SigData(port_no).Position;

	                    %ref positions for output scope blocks
	                    scope_ref_height = app.test_data(caseNo).SigData(app.no_rnbls + app.no_inports + 2).Position(2) - 32;
	                    scope_ref_width = app.test_data(caseNo).SigData(app.no_rnbls + app.no_inports + 2).Position(1);

	                    for port_no = app.no_rnbls+2: app.no_rnbls+app.no_inports+app.no_outports+1+app.AUTOSAR_stat
	                        if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
	                            %inports
	                            signal_no = signal_no + 1;
	                            %data = reshape(app.test_data(caseNo).SigData(port_no).Values,values(2),1);
	                            %temp_timeseries = timeseries(data,re_timeStamps,'Name',app.test_data(caseNo).SigData(port_no).Name);
	                            signalbuilder(block,'appendsignal',app.test_data(caseNo).SigTime,app.test_data(caseNo).SigData(port_no).Values,app.test_data(caseNo).SigData(port_no).Name);
	                            gen_handles = get_param(block,'PortHandles');
	                            convert_handle = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d',app.harness_name_MIL,signal_no),...
	                                'Position',[app.test_data(caseNo).SigData(port_no).Position(1)-265 app.test_data(caseNo).SigData(port_no).Position(2)-10 app.test_data(caseNo).SigData(port_no).Position(1)-190 app.test_data(caseNo).SigData(port_no).Position(2)+10]...
	                                ,'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).OutDataType,'ShowName','off');
	                            convert_port = get_param(convert_handle,'PortHandles');
	                            set_param(convert_port.Outport(1),'DataLogging','on','DataLoggingName',app.test_data(caseNo).SigData(port_no).Name);
	                            if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
	                                old_pos = get_param(convert_handle,'Position');
	                                int_convert = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d_int8',app.harness_name_MIL,signal_no),...
	                                    'Position', [old_pos(1)-100 old_pos(2) old_pos(3)-100 old_pos(4)],'OutDataTypeStr','uint8','ShowName','off');
	                                int_convert_port = get_param(int_convert,'PortHandles');
	                                add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),int_convert_port.Inport(1));
	                                add_line(app.harness_name_MIL,int_convert_port.Outport(1),convert_port.Inport(1));
	                            else
	                                add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),convert_port.Inport(1));
	                            end
	                            line_handle = add_line(app.harness_name_MIL,convert_port.Outport(1),ref_port_handles.Inport(port_no));
	                            set_param(line_handle,'Name',app.test_data(caseNo).SigData(port_no).Name);

	                            add_block('simulink/Sinks/Scope',sprintf('%s/ScopeIn_%d',app.harness_name_MIL,signal_no),'Position',...
	                                [app.test_data(caseNo).SigData(port_no).Position(1)-40 app.test_data(caseNo).SigData(port_no).Position(2)+4 app.test_data(caseNo).SigData(port_no).Position(1)-10 app.test_data(caseNo).SigData(port_no).Position(2)+36]);
	                            add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('ScopeIn_%d/1',signal_no),'autorouting','on');

	                            port_position = app.test_data(caseNo).SigData(port_no).Position;
	                        elseif port_no > (app.no_rnbls + app.no_inports + app.AUTOSAR_stat) && port_no < (app.no_rnbls+app.no_inports+app.no_outports+1+app.AUTOSAR_stat)
	                            %outports
	                            port_position(2) = port_position(2) + 55;
	                            signal_no = signal_no + 1;
	                            %data = reshape(app.test_data(caseNo).SigData(port_no).Values,values(2),1);
	                            %temp_timeseries = timeseries(data,re_timeStamps,'Name',app.test_data(caseNo).SigData(port_no).Name);
	                            signalbuilder(block,'appendsignal',app.test_data(caseNo).SigTime,app.test_data(caseNo).SigData(port_no).Values,app.test_data(caseNo).SigData(port_no).Name);
	                            gen_handles = get_param(block,'PortHandles');
	                            convert_handle = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d',app.harness_name_MIL,signal_no),...
	                                'Position',[port_position(1)-265 port_position(2)-10 port_position(1)-190 port_position(2)+10]...
	                                ,'OutDataTypeStr',app.test_data(caseNo).SigData(port_no).OutDataType,'ShowName','off');
	                            convert_port = get_param(convert_handle,'PortHandles');
	                            set_param(convert_port.Outport(1),'DataLogging','on','DataLoggingName',app.test_data(caseNo).SigData(port_no).Name);
	                            if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
	                                old_pos = get_param(convert_handle,'Position');
	                                int_convert = add_block('simulink/Signal Attributes/Data Type Conversion',sprintf('%s/convert_%d_int8',app.harness_name_MIL,signal_no),...
	                                    'Position', [old_pos(1)-100 old_pos(2) old_pos(3)-100 old_pos(4)],'OutDataTypeStr','uint8','ShowName','off');
	                                int_convert_port = get_param(int_convert,'PortHandles');
	                                add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),int_convert_port.Inport(1));
	                                add_line(app.harness_name_MIL,int_convert_port.Outport(1),convert_port.Inport(1));
	                            else
	                                add_line(app.harness_name_MIL,gen_handles.Outport(signal_no),convert_port.Inport(1));
	                            end

	                            outportNo = signal_no-app.no_inports;
	                            set_param(ref_port_handles.Outport(outportNo),'DataLogging','on','DataLoggingName',app.test_data(caseNo).SigData(port_no).Name);
	                            
	                            OutScope = add_block('simulink/Sinks/Scope',sprintf('%s/ScopeOut_%d',app.harness_name_MIL,outportNo),...
	                                'Position', [scope_ref_width+475 scope_ref_height scope_ref_width+475+40 scope_ref_height+64]);
	                            OutScope_param = get_param(OutScope,'ScopeConfiguration');
	                            OutScope_param.NumInputPorts = '3';
	                            OutScope_param.LayoutDimensions = [3,1];

	                            %line_handle = add_line(app.harness_name_MIL,sprintf('%s/%d',app.OnlyModelName,outportNo),sprintf('Scope/%d',outportNo),'autorouting','on');
	                            %set_param(line_handle,'Name',sprintf('%s_Actual',app.test_data(caseNo).SigData(port_no).Name));
	                            if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'single') || isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'double')
	                                relation_handle = add_block('simulink/Logic and Bit Operations/Relational Operator',sprintf('%s/Relational_%d',app.harness_name_MIL,outportNo), 'Operator','<=',...
	                                    'Position', [scope_ref_width+285 scope_ref_height+34 scope_ref_width+285+30 scope_ref_height+34+31],'ShowName','off');
	                                relation_port = get_param(relation_handle,'PortHandles');
	                                set_param(relation_port.Outport(1),'DataLogging','on');

	                                add_block('simulink/Math Operations/Add',sprintf('%s/Difference_%d',app.harness_name_MIL,outportNo),'Inputs','+-',...
	                                    'Position', [scope_ref_width+190 scope_ref_height+9 scope_ref_width+190+30 scope_ref_height+9+31],'ShowName','off');
	                                line_handle = add_line(app.harness_name_MIL,sprintf('%s/%d',app.OnlyModelName,outportNo),sprintf('Difference_%d/1',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Actual',app.test_data(caseNo).SigData(port_no).Name));
	                                line_handle = add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('Difference_%d/2',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Expected',app.test_data(caseNo).SigData(port_no).Name));
	                                add_line(app.harness_name_MIL,sprintf('%s/%d',app.OnlyModelName,outportNo),sprintf('ScopeOut_%d/2',outportNo),'autorouting','on');

	                                add_block('simulink/Sources/Constant',sprintf('%s/Limit_%d',app.harness_name_MIL,outportNo),'Value','0.0001',...
	                                    'Position', [scope_ref_width+230 scope_ref_height+49 scope_ref_width+230+35 scope_ref_height+49+16],'ShowName','off');
	                                add_line(app.harness_name_MIL,sprintf('Limit_%d/1',outportNo),sprintf('Relational_%d/2',outportNo),'autorouting','on');

	                                add_block('simulink/Math Operations/Abs',sprintf('%s/Abs_%d',app.harness_name_MIL,outportNo),...
	                                    'Position', [scope_ref_width+235 scope_ref_height+9 scope_ref_width+235+30 scope_ref_height+9+31],'ShowName','off');
	                                add_line(app.harness_name_MIL,sprintf('Difference_%d/1',outportNo),sprintf('Abs_%d/1',outportNo),'autorouting','on');
	                                add_line(app.harness_name_MIL,sprintf('Abs_%d/1',outportNo),sprintf('Relational_%d/1',outportNo),'autorouting','on');

	                                add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('ScopeOut_%d/1',outportNo),'autorouting','on');

	                                line_handle = add_line(app.harness_name_MIL,sprintf('Relational_%d/1',outportNo),sprintf('ScopeOut_%d/3',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
	                            else
	                                relation_handle = add_block('simulink/Logic and Bit Operations/Relational Operator',sprintf('%s/Relational_%d',app.harness_name_MIL,outportNo), 'Operator','==',...
	                                    'Position', [scope_ref_width+285 scope_ref_height+34 scope_ref_width+285+30 scope_ref_height+34+31]);
	                                relation_port = get_param(relation_handle,'PortHandles');
	                                set_param(relation_port.Outport(1),'DataLogging','on');
	                                line_handle = add_line(app.harness_name_MIL,sprintf('%s/%d',app.OnlyModelName,outportNo),sprintf('ScopeOut_%d/2',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Actual',app.test_data(caseNo).SigData(port_no).Name));
	                                add_line(app.harness_name_MIL,sprintf('%s/%d',app.OnlyModelName,outportNo),sprintf('Relational_%d/1',outportNo),'autorouting','on');
	                                line_handle = add_line(app.harness_name_MIL,sprintf('Relational_%d/1',outportNo),sprintf('ScopeOut_%d/3',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
	                                line_handle = add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('Relational_%d/2',outportNo),'autorouting','on');
	                                set_param(line_handle,'Name',sprintf('%s_Expected',app.test_data(caseNo).SigData(port_no).Name));
	                                add_line(app.harness_name_MIL,sprintf('convert_%d/1',signal_no),sprintf('ScopeOut_%d/1',outportNo),'autorouting','on');
	                            end

	                            scope_ref_height = scope_ref_height + 85;

	                        end
	                        %Inputs_ExpectedOutput = addElement(Inputs_ExpectedOutput,temp_timeseries);
	                    end
	                    %caseNo = 1 condition
	                    errorCode = 3; %Error in adding test cases in Signal builder
	                else
	                	prog_stat.Indeterminate = 'off';
	                	prog_stat.Value = caseNo/length(app.test_data);
	                	prog_stat.Message = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
	                	app.SelectmodeltotestLabel.Text = sprintf('%s: Updating signal builder',app.test_data(caseNo).TestCaseID);
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
	            errorCode = 4; %Error in creating SIL harness
	            prog_stat.Indeterminate = 'on';
	            prog_stat.Message = 'Creating SIL harness';

	            set_param(harness_handle, 'ZoomFactor','FitSystem');
	            save_system(harness_handle);
	            copyfile(sprintf('%s.slx',app.harness_name_MIL),sprintf('%s.slx',app.harness_name_SIL));

	            load_system(app.harness_name_SIL);
	            set_param(app.harness_name_SIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
	            save_system(app.harness_name_SIL);
	            
	            close(prog_stat);
	            uialert(app.UIFigure,'Harnesses are updated according to test cases','Success','icon','success');
	            app.SelectmodeltotestLabel.Text = 'Harnesses are completed according to test cases';
	        catch ErrorCaught
	        	assignin('base','ErrorInfo_CreateHarness',ErrorCaught);
	        	app.errorFlag = 1;
                warning('-----------Unable to complete harness. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to test harness and Excel. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%uialert(app.UIFigure,'Unable read excel. Check command window for error info','Error');
                	case 2
                		%%Error in adding signal builder and other blocks
                		uialert(app.UIFigure,'Unable add required blocks. Delete any blocks added and Retry. Check command window for error info','Error');
                		close(prog_stat);
                	case 3
                		%Error in adding test cases in Signal builder
                		uialert(app.UIFigure,'Error in importing test cases into signal builder. Delete any blocks added and Retry. Check command window for error info','Error');
                		close(prog_stat);
                	case 4
                		%Error in creating SIL harness
                		uialert(app.UIFigure,'Unable to create SIL harness. Duplicate MIL harness and rename it. Check command window for error info','Error');
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
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','Importing test cases Excel',...
                            'Message','Loading Excel','Indeterminate','on'); 
        		drawnow
	            Excel = actxserver('Excel.Application');
	            Ex_Workbook = Excel.Workbooks.Open(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
	            Ex_Sheets = Excel.ActiveWorkbook.Sheets;
	            Ex_actSheet = Ex_Sheets.get('Item',1);
	            Excel.Visible = 1;
	            
	            figure(app.UIFigure);
	            Ex_range = get(Ex_actSheet,'Range','B4');
	            caseNo = 1;

	            app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},...
	                        'SigData',{},'SigTime',{},'Result',{},'DataLog',{},'TimeData',{},'ScopeSelect',{});

	            errorCode = 2; %Error in reading excel
	            while ~isnan(Ex_range.Value)
	                app.test_data(caseNo).TestCaseID = Ex_range.Value;
	                app.SelectmodeltotestLabel.Text = sprintf('Importing %s from Excel',app.test_data(caseNo).TestCaseID);
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
	            %uialert(app.UIFigure,'Harness is completed according to test cases','Success','icon','success');
	        catch ErrorCaught
	        	caughtError = 1;
	        	assignin('base','IntErrorInfo_ReadingExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import test cases from Excel. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to import test cases from Excel. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in loading excel
                		uialert(app.UIFigure,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                	case 2
                		%Error in adding test cases in Signal builder
                		uialert(app.UIFigure,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                		Ex_Workbook.Close;
	            		Excel.Quit;
                	case 3
                		%Error in adding test cases in Signal builder
                		uialert(app.UIFigure,'Unable to update Init function call generator. Retry after fixing error. Check command window for error info','Error');
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
            %     load_system(app.harness_name_MIL);
            %     %Selecting signal builder
            %     sigBuilders = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');
            % elseif isequal(test_mode,'SIL')
            %     load_system(app.harness_name_SIL);
            %     %Selecting signal builder
            %     sigBuilders = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
            % end
            try
            	errorCode = 1; %Error in resetting signal builders
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','Updating test cases',...
                            'Message','Resetting signal builders','Indeterminate','on'); 

        		drawnow

	            load_system(app.harness_name_MIL);
	            sigBuilders_MIL = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');

	            load_system(app.harness_name_SIL);
	            sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');

	            %deleting signals (all but first)
	            [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_MIL{1,1});
	            for grp_no = 2:length(groupnames_t)
	                signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 2, [], []);
	                signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 2, [], []);
	            end

	            close(prog_stat);
	            errorCode = 2; %Error in reading excel
	            caughtError = ReadingExcel(app);
	            throwError(app,caughtError,'Unable to read excel. Check previous messages for error info');

	            errorCode = 3; %Error in adding test cases to signal builder
	            prog_stat = uiprogressdlg(app.UIFigure,'Title','Updating test cases',...
                            'Message','Updating signal builders'); 

	            for caseNo = 1:length(app.test_data)
	                %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
	                
	                app.SelectmodeltotestLabel.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
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
	            end
	            %deleting the first one
	            signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
	            signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
	            
	            save_system(app.harness_name_MIL);
	            save_system(app.harness_name_SIL);

	            errorCode = 4; %Error in copying excel
	            prog_stat.Message = 'Updating SIL test cases Excel';
	            prog_stat.Indeterminate = 'on';

	            delete(sprintf('SIL_Functional_TestReport_%s.xlsx',app.OnlyModelName));
	            copyfile(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName),...
	                    sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
	            
	            close(prog_stat);
	            app.SelectmodeltotestLabel.Text = 'Updated MIL & SIL harnesses';
	            uialert(app.UIFigure,'Harnesses are updated according to new test cases','Success','icon','success');
	        catch ErrorCaught
	        	assignin('base','ErrorInfo_UpdateSignal',ErrorCaught);
	        	app.errorFlag = 1;
                warning('-----------Unable to update signal builder with new test cases. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to update signal builder with new test cases. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in resetting signal builders
                		uialert(app.UIFigure,'Unable to reset signal builders. Retry after fixing error. Check command window for error info','Error');
                	case 2
                		%Error in reading excel
                		%uialert(app.UIFigure,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                	case 3
                		%Error in adding test cases to signal builder
                		uialert(app.UIFigure,'Unable to update signal builders. Retry after fixing error. Check command window for error info','Error');
                		close(prog_stat);
                	case 4
                		%Error in adding test cases in Signal builder
                		uialert(app.UIFigure,sprintf('Unable to copy updated test cases from ''MIL_Functional_TestReport_%s.xlsx'' to ''SIL_Functional_TestReport_%s.xlsx''. Delete ''SIL_Functional_TestReport_%s.xlsx'' and copy the file manually\n',app.OnlyModelName,app.OnlyModelName,app.OnlyModelName),'Error');
                		app.SelectmodeltotestLabel.Text = 'Updated both harnesses. Manually copy test cases from MIL Excel to SIL Excel';
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
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','Updating results in Excel',...
                            'Message','Loading Excel'); 

	            Excel = actxserver('Excel.Application');
	            Ex_Workbook = Excel.Workbooks.Open(sprintf('%s%s_Functional_TestReport_%s.xlsx',app.rootPath,test_mode,app.OnlyModelName));
	            Ex_Sheets = Excel.ActiveWorkbook.Sheets;
	            Ex_actSheet = Ex_Sheets.get('Item',1);
	            Excel.Visible = 1;
	            
	            figure(app.UIFigure);

	            Ex_range = get(Ex_actSheet,'Range','F4');
	            Ex_range = Ex_range.get('Offset',0,app.no_inports+app.no_outports); % offset to Expected Output

	            %fixedTimeStep = 0.01;
	            errorCode = 2; %Error in updating excel
	            for caseNo = 1:length(app.test_data)
	                %simulating current group
	                all_time_values = app.test_data(caseNo).TimeData;
	                logged_data = app.test_data(caseNo).DataLog;

	                %Log results in excel
	                app.SelectmodeltotestLabel.Text = sprintf('Updating %s results of %s',test_mode,app.test_data(caseNo).TestCaseID);
	                prog_stat.Message = sprintf('Updating %s results of %s',test_mode,app.test_data(caseNo).TestCaseID);
	                prog_stat.Value = caseNo/length(app.test_data);
	                drawnow
	                %Ex_range = Ex_range.get('Offset',-(no_rows-1),(app.no_inports+app.no_outports));

	                time_milestone = all_time_values(1);
	                time_index = 1;
	                value_index = 1;
	                result_status = 1; %1-> passed, 0-> failed
	                test_result = 1; %1-> passed, 0-> failed of complete test case
	                for valueIndex = 1:length(app.test_data(caseNo).DataLog{1}.Values.Time)
				        if abs(app.test_data(caseNo).DataLog{1}.Values.Time(valueIndex) - time_milestone) > app.timeOffset
				            for port_no = app.no_rnbls + app.no_inports + 1 + app.AUTOSAR_stat: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                result_log = get(logged_data, sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
				                result_log = result_log.Values.Data;
				                if result_log(valueIndex) == 1
				                    if result_status ~= 0
				                        Ex_range.Interior.ColorIndex = 0;
				                    end
				                else
				                    errIndex = valueIndex;
				                    result_status = 0;
				                    Ex_range.Interior.ColorIndex = 3; %red
				                end
				                Ex_range = Ex_range.get('Offset',0,1);
				            end
				            Ex_range = Ex_range.get('Offset',0,-(app.no_outports));
				        else
				            for port_no = app.no_rnbls + app.no_inports + 1 + app.AUTOSAR_stat: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                actual_log = get(logged_data, sprintf('%s_Actual',app.test_data(caseNo).SigData(port_no).Name));
				                actual_log = actual_log.Values.Data;

				                if result_status == 0
				                    temp_index = valueIndex;
				                    valueIndex = errIndex;
				                end

				                if isequal(app.test_data(caseNo).SigData(port_no).BaseDataType,'Enum')
				                    Ex_range.Value = char(actual_log(valueIndex));
				                else
				                    Ex_range.Value = actual_log(valueIndex);
				                end
				                Ex_range = Ex_range.get('Offset',0,1);

				                if result_status == 0
				                    valueIndex = temp_index;
				                end
				            end
				            if result_status == 1
				                Ex_range.Value = 'Passed';
				                Ex_range.Interior.ColorIndex = 4; %green
				            else
				                Ex_range.Value = 'Failed';
				                Ex_range.Interior.ColorIndex = 3; %red
				                test_result = 0;
				            end
				            Ex_range = Ex_range.get('Offset',1,-(app.no_outports));
				            
				            if abs(app.test_data(caseNo).DataLog{1}.Values.Time(valueIndex) - app.test_data(caseNo).TestTime) > app.timeOffset
				                time_index = time_index + 1;
                                try
                                    time_milestone = time_milestone + all_time_values(time_index);
                                catch
                                    disp(time_index);
                                end
				                
				                result_status = 1;
				                for port_no = app.no_rnbls + app.no_inports + 1 + app.AUTOSAR_stat: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                    result_log = get(logged_data, sprintf('%s_Result',app.test_data(caseNo).SigData(port_no).Name));
				                    result_log = result_log.Values.Data;
				                    if result_log(valueIndex) == 1
				                        if result_status ~= 0
				                            Ex_range.Interior.ColorIndex = 0;
				                        end
				                    else
				                        errIndex = valueIndex;
				                        result_status = 0;
				                        Ex_range.Interior.ColorIndex = 3; %red
				                    end
				                    Ex_range = Ex_range.get('Offset',0,1);
				                end
				                Ex_range = Ex_range.get('Offset',0,-(app.no_outports));
				            end
				        end
				    end
	                app.test_data(caseNo).Result = test_result;
	                %Ex_range = Ex_range.get('Offset',1,-(4+app.no_inports+app.no_outports)); % change offset
	            end

	            errorCode = 3; %Error in saving
	            Ex_Workbook.Save;
	            Ex_Workbook.Close;
	            Excel.Quit;

	        	close(prog_stat);
	            %uialert(app.UIFigure,'Harness is completed according to test cases','Success','icon','success');
	        catch ErrorCaught
	        	caughtError = 1;
	        	assignin('base','IntErrorInfo_UpdateExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to update results in Excel. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to update results in Excel. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in loading excel
                		uialert(app.UIFigure,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                	case 2
                		%Error in updating excel
                		uialert(app.UIFigure,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                		Ex_Workbook.Close;
	            		Excel.Quit;
                	case 3
                		%Error in saving excel
                		uialert(app.UIFigure,'Unable to save Excel after updating results. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end
	        app.errorFlag = caughtError;
        end

        % RunMILTest
        function RunMILTest(app)
        	try
        		errorCode = 1; %Error in simulating model
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','MIL testing',...
                            'Message','MIL testing'); 
        		drawnow
	            set_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'SimulationMode','Normal');
	            sigBuilders = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');

	            for caseNo = 1:length(app.test_data)
	                %simulating current group
	                signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

	                app.SelectmodeltotestLabel.Text = sprintf('MIL testing of %s',app.test_data(caseNo).TestCaseID);
	                prog_stat.Message = sprintf('MIL testing of %s',app.test_data(caseNo).TestCaseID);
	                prog_stat.Value = caseNo/length(app.test_data);
	                drawnow

	                sim_data = sim(app.harness_name_MIL,'SimulationMode','Normal','SignalLogging','on','SignalLoggingName','logsout','StopTime',num2str(app.test_data(caseNo).TestTime));
	                %pause(simulation_time+3)
	                app.test_data(caseNo).DataLog = sim_data.logsout;
	            end
	            errorCode = 2; %Error in updating results
	            close(prog_stat);
	            caughtError = UpdateExcel(app,'MIL');
	            throwError(app,caughtError,'Unable to update results in excel. Check previous messages for error info');

	            uialert(app.UIFigure,'MIL testing completed','Success','icon','success');
	            app.SelectmodeltotestLabel.Text = 'MIL Testing completed';
	        catch ErrorCaught
	        	assignin('base','ErrorInfo_RunMILTest',ErrorCaught);
	        	app.errorFlag = 1;
                warning('-----------Unable to MIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.SelectmodeltotestLabel.Text = sprintf('Unable to MIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in simulating model
                		uialert(app.UIFigure,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                		close(prog_stat);
                	case 2
                		%Error in updating results
                		%uialert(app.UIFigure,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end
        end        

        %RunSILTest
        function RunSILTest(app)
        	try
        		errorCode = 1; %Error in loading excel
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','SIL testing',...
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

	            temp_data = app.test_data;

	            if app.SLDVButton.Value
	            	errorCode = 4; %Error in importing SLDV test cases
	            	caughtError = importSLDV(app);
					throwError(app,caughtError,'Unable to import SLDV test cases. Check previous messages for error info');
	            end

	            errorCode = 2; %Error in simulating model
	            for caseNo = 1:length(app.test_data)
	                %simulating current group
	                signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

	                save_system(app.OnlyModelName);
	                app.SelectmodeltotestLabel.Text = sprintf('SIL testing of %s',app.test_data(caseNo).TestCaseID);
	                prog_stat.Message = sprintf('SIL testing of %s',app.test_data(caseNo).TestCaseID);
	                prog_stat.Value = caseNo/length(app.test_data);
	                drawnow

	                sim_data = sim(app.harness_name_SIL,'SimulationMode','Normal','SignalLogging','on','SignalLoggingName','logsout','StopTime',num2str(app.test_data(caseNo).TestTime));
	                %pause(simulation_time+3)
	                app.test_data(caseNo).DataLog = sim_data.logsout;
	            end

	            errorCode = 3; %Error in updating results in excel
	            close(prog_stat);

	            caughtError = UpdateExcel(app,'SIL');
	            %Excel.Quit;
	            throwError(app,caughtError,'Unable to update results in excel. Check previous messages for error info');
	            app.test_data_SIL = app.test_data;
	            app.test_data = temp_data;

	            uialert(app.UIFigure,'SIL testing completed','Success','icon','success');
	            app.SelectmodeltotestLabel.Text = 'SIL Testing completed';
	        catch ErrorCaught
	        	assignin('base','ErrorInfo_RunSILTest',ErrorCaught);
	        	app.errorFlag = 1;
                warning('-----------Unable to SIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.SelectmodeltotestLabel.Text = sprintf('Unable to SIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in loading Excel
                		uialert(app.UIFigure,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                		close(prog_stat);
                	case 2
                		%Error in simulating model
                		uialert(app.UIFigure,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                		app.test_data_SIL = app.test_data;
	            		app.test_data = temp_data;
	            		close(prog_stat);
                	case 3
                		%Error in updating results
                		%uialert(app.UIFigure,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                		app.test_data_SIL = app.test_data;
	            		app.test_data = temp_data;
	            	case 4
                		%Error in importing SLDV test cases
                		%uialert(app.UIFigure,'Unable to import SLDV test cases. Retry after fixing error. Check command window for error info','Error');
                		app.test_data_SIL = app.test_data;
	            		app.test_data = temp_data;
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end
        end

        %importSLDV
        function caughtError = importSLDV(app)
        	try
	        	sldvAllowed = 0; %Only allowes further sldv actions if data is present
	        	caughtError = 0;
	        	errorCode = 1; %Error in accessing sldv test cases
        		app.SelectmodeltotestLabel.FontColor = [0 0 0];
        		prog_stat = uiprogressdlg(app.UIFigure,'Title','Loading test cases from SLDV',...
                            'Message','Checking files...','Indeterminate','on');
        		app.SelectmodeltotestLabel.Text = 'Checking SLDV files';
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
				            matFileName = dir(sprintf('%s/%s/*_sldvdata.mat',all_files(i).folder,all_files(i).name));
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
					load_system(app.harness_name_SIL);
					app.timeStep = str2num(get_param(app.harness_name_SIL,'FixedStep'));
				    caseID = app.test_data(1).TestCaseID(1:7);
				    caseNo = length(app.test_data);
				    for sldvIndex = 1: length(app.allSLDV)
				        for sldvNo = 1: length(app.allSLDV(sldvIndex).TestCases)
				            caseNo = caseNo + 1;
				            sldvTestCase = app.allSLDV(sldvIndex).TestCases(sldvNo);
				            all_time_values = sldvTestCase.timeValues;

				            %Initializing new entries in test_data structure
				            app.test_data(caseNo).RequirementID = 'NA';
				            app.test_data(caseNo).TestDescription = 'Auto generated by Simulink Design Verifier';
				            app.test_data(caseNo).TestOutput = 'NA';
				            if caseNo <10
				                app.test_data(caseNo).TestCaseID = sprintf('%sB_00%d',caseID,caseNo);
				            elseif caseNo < 100
				                app.test_data(caseNo).TestCaseID = sprintf('%sB_0%d',caseID,caseNo);
				            else
				                app.test_data(caseNo).TestCaseID = sprintf('%sB_%d',caseID,caseNo);
				            end
				            app.test_data(caseNo).ScopeSelect = ones(2,max(app.no_inports,app.no_outports));
				            app.test_data(caseNo).SigData = app.port_data;
				            app.test_data(caseNo).SigTime = zeros(1,2*length(all_time_values));

				            prog_stat.Message = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
				            app.SelectmodeltotestLabel.Text = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
				            drawnow

				            for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                if (port_no == (app.no_rnbls + app.no_inports + 1)) && (app.AUTOSAR_stat == 1)
				                    %initialize port
				                else
				                    %Inports and outports
				                    app.test_data(caseNo).SigData(port_no).Values = zeros(1,2*length(all_time_values));
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
	                                app.test_data(caseNo).TimeData(timeIndex) = app.timeStep;
	                            else
	                                app.test_data(caseNo).TimeData(timeIndex) = all_time_values(timeIndex + 1) - all_time_values(timeIndex);
	                            end
				                app.test_data(caseNo).SigTime(valueIndex) = timeValue;

				                inIndex = 0;
				                outIndex = 0;
				                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                    if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
				                        %initialize port
				                    else
				                        if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
				                            inIndex = inIndex + 1;
				                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.dataValues{inIndex}(timeIndex);
				                        elseif (port_no > (app.no_rnbls + app.no_inports + 1)) && (port_no < (app.no_rnbls+app.no_inports+app.no_outports+2))
				                        	errorCode = 6; %expected output not present
				                            outIndex = outIndex + 1;
				                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(timeIndex);
				                        end
				                        errorCode = 4; %error in adding sldv test cases
				                    end
				                end

				                %updating indexes for second half
				                if timeIndex == 1
				                    timeValue = timeValue - app.timeOffset;
				                end

				                if timeIndex == length(all_time_values)
				                    timeValue = app.timeStep + timeValue;
				                else
				                    timeValue = all_time_values(timeIndex + 1) + timeValue;
				                end

				                valueIndex = valueIndex + 1;

				                app.test_data(caseNo).SigTime(valueIndex) = timeValue;

				                inIndex = 0;
				                outIndex = 0;
				                for port_no = app.no_rnbls+1: app.no_rnbls+app.no_inports+app.no_outports+app.AUTOSAR_stat
				                    if port_no == (app.no_rnbls + app.no_inports + 1) && (app.AUTOSAR_stat == 1)
				                        %initialize port
				                    else
				                        if (port_no > app.no_rnbls) && port_no < (app.no_rnbls + app.no_inports + 1)
				                            inIndex = inIndex + 1;
				                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.dataValues{inIndex}(timeIndex);
				                        elseif (port_no > (app.no_rnbls + app.no_inports + 1)) && (port_no < (app.no_rnbls+app.no_inports+app.no_outports+2))
				                        	errorCode = 6; %expected output not present
				                            outIndex = outIndex + 1;
				                            app.test_data(caseNo).SigData(port_no).Values(valueIndex) = sldvTestCase.expectedOutput{outIndex}(timeIndex);
				                        end
				                        errorCode = 4; %error in adding sldv test cases
				                    end
				                end  
				            end
				            app.test_data(caseNo).TestTime = sum(app.test_data(caseNo).TimeData);
				        end
				    end

				    %Update signal builder
				    errorCode = 5; %error in updating signal builder
		            sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
		            prog_stat.Indeterminate = 'off';
		            %deleting signals (all but first)
		            [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_SIL{1,1});
		            for grp_no = 2:length(groupnames_t)
		                signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 2, [], []);
		            end

		            for caseNo = 1:length(app.test_data)
		                %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
		                
		                app.SelectmodeltotestLabel.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
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
		                signalbuilder(sigBuilders_SIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
		            end
		            %deleting the first one
		            signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
		            
		            save_system(app.harness_name_SIL);
		          	close(prog_stat);
		            app.SelectmodeltotestLabel.Text = 'Imported SLDV test cases';
		            uialert(app.UIFigure,'Imported all SLDV test cases','Success','icon','success');
		            drawnow
				end
			catch ErrorCaught
	        	caughtError = 1;
	        	assignin('base','IntErrorInfo_importSLDV',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import SLDV test cases. Retry after fixing error-----------');
                app.SelectmodeltotestLabel.Text = 'Unable to import SLDV test cases. Retry after fixing error';
                app.SelectmodeltotestLabel.FontColor = [1 0 0];
                switch errorCode
                	case 1
                		%Error in accessing sldv test cases
                		uialert(app.UIFigure,'Unable to access sldv mat files. Retry after generating SLDV test cases. Check command window for error info','Error');
                	case 2
                		%SLDV test cases are not available
                		uialert(app.UIFigure,'Unable to find sldv data files(''*_sldvdata.mat''). Retry after generating SLDV test cases. Check command window for error info','Error');
                	case 3
                		%SLDV folder not available
                		uialert(app.UIFigure,'Unable to find ''sldv_output'' folder. Retry after generating SLDV test cases. Check command window for error info','Error');
                	case 4
                		%error in adding sldv test cases
                		uialert(app.UIFigure,'Unable to add sldv test cases. Retry after fixing error. Check command window for error info','Error');
                	case 5
                		%error in updating signal builder
                		uialert(app.UIFigure,'Unable to update signalbuilder. Retry after fixing error. Check command window for error info','Error');
                	case 6
                		%expected output not present
                		uialert(app.UIFigure,'Unable to find expected outputs. Regenerate test cases after updating model configuration. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        end
	        app.errorFlag = caughtError;
        end

        %reportMIL
        function reportMIL(app)
                	
        	prog_stat = uiprogressdlg(app.UIFigure,'Title','MIL report generation',...
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
        	
        	prog_stat = uiprogressdlg(app.UIFigure,'Title','SIL report generation',...
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
					uialert(app.UIFigure,sprintf('SLDV data is not available. Run ''SIL with SLDV'' and try again'),'Error','Icon','error');
        			fprintf(2,'Error: SLDV data is not available. Run ''SIL with SLDV'' and try again\n');
        			app.SelectmodeltotestLabel.Text = 'SLDV data is not available. Run ''SIL with SLDV'' and try again';
				else
					reportGen(app,'SIL', dataAvail);
				end
			else
				reportGen(app,'SIL', dataAvail);
			end
        end

        %Reportgen
        function reportGen(app, test_mode, dataAvail)

        	prog_stat = uiprogressdlg(app.UIFigure,'Title',sprintf('%s report generation',test_mode),...
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
	        				else
	        					open_system(app.harness_name_SIL);
	        					evalin('base','load(sprintf(''%s_TestHarness_data.mat'',OnlyModelName),''test_data_SIL'',''no_inports'',''no_outports'',''no_rnbls'')');
	        				end

	        				figure(app.UIFigure);
	        				report(sprintf('Eaton_OBC_DCDC_%s_Report.RPT',test_mode));
	        				uialert(app.UIFigure,sprintf('%s report of %s model generated',test_mode,app.OnlyModelName),'Success','Icon','success');
	        				app.SelectmodeltotestLabel.Text = sprintf('%s report of %s model generated',test_mode,app.OnlyModelName);
	        			catch ErrorCaught
	        				close(prog_stat);
	        				app.errorFlag = 1;
	        				assignin('base','ErrorInfo_reportGen',ErrorCaught);
	        				warning('-----------Unable generate %s report-----------',test_mode);
	        				uialert(app.UIFigure,sprintf('Unable to generate %s report. Check command window for more information',test_mode),'Error','Icon','error');
	        				fprintf(2,'Error: %s\n',ErrorCaught.message);
	        			end
	        		else
	        			close(prog_stat);
	        			uialert(app.UIFigure,sprintf('''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again',test_mode),'Error','Icon','error');
	        			fprintf(2,sprintf('Error: ''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again\n',test_mode));
	        			app.SelectmodeltotestLabel.Text = sprintf('''Eaton_OBC_DCDC_%s_Report.RPT'' file is not present. Add it to path and try again',test_mode);
	        		end
	        	else
	        		close(prog_stat);
	        		uialert(app.UIFigure,'''rpt_icon'' folder is not present. Add it to path and try again','Error','Icon','error');
	        		fprintf(2,'Error: ''rpt_icon'' folder is not present. Add it to path and try again\n');
	        		app.SelectmodeltotestLabel.Text = '''rpt_icon'' folder is not present. Add it to path and try again';
	        	end
	        else
	        	close(prog_stat);
	        	uialert(app.UIFigure,sprintf('Simulation results are not available. Re-run %s test and try again',test_mode),'Error','Icon','error');
        		fprintf(2,sprintf('Error: Simulation results are not available. Re-run %s test and try again\n',test_mode));
        		app.SelectmodeltotestLabel.Text = sprintf('Simulation results are not available. Re-run %s test and try again',test_mode);
	        end
    	end

        %configUpdate
        function configUpdate(app,DataDictObj,EnableCov)
        	try
				DataSectConfig = getSection(DataDictObj,'Configurations');

				model_config = getActiveConfigSet(app.OnlyModelName);
				entryObj = getEntry(DataSectConfig,model_config.SourceName);
				ConfigSet = getValue(entryObj);
				set_param(ConfigSet,'CovEnable',EnableCov,'CovMetricStructuralLevel','ConditionDecision','CovHighlightResults','on','CovHtmlReporting','on','CovCumulativeReport','on');
				setValue(entryObj,ConfigSet);

				saveChanges(DataDictObj);
        	catch ErrorCaught
        		assignin('base','ErrorInfo_configUpdate',ErrorCaught);
        		app.errorFlag = 1;
				warning('-----------Unable update configuration parameters-----------');
				uialert(app.UIFigure,'Unable update configuration parameters','Error','Icon','error');
				fprintf(2,'Error: %s\n',ErrorCaught.message);
        	end
        end

        %throwError
        function throwError(app,caughtError,msgError)
        	if caughtError
        		error(msgError);
        	end
        end
        % Button pushed function: Execute
        function ExecuteButtonPushed(app, event)
            app.SelectmodeltotestLabel.Text = sprintf('Loading %s model', app.ModelName);
            drawnow
            load_system(app.ModelName);
            DataDictionary = get_param(app.OnlyModelName,'DataDictionary');
            DataDictObj = Simulink.data.dictionary.open(DataDictionary);
            DataDictSec = getSection(DataDictObj,'Design Data');
            %app.SelectmodeltotestLabel.Text = sprintf('Loading %s model', app.ModelName);
            app.errorFlag = 0;

            %updateStatus(app);
            AUTOSARButtonValueChanged(app, event);

            if app.CreateExcel.Value
            	CreateExcel_Data(app,DataDictionary,DataDictSec);
                drawnow
            end

            if (isequal(app.UpdateHarness.Value,1) || isequal(app.UpdateCases.Value,1) || isequal(app.RunTests.Value,1) || isequal(app.RunSIL.Value,1))
            	try
            		errorCode = 1; %error in reading mat file
	            	app.dataMatfile = matfile(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'Writable',true);
	                app.port_data = app.dataMatfile.port_data;
	                app.no_inports = app.dataMatfile.no_inports;
	                app.no_outports = app.dataMatfile.no_outports;
	                app.no_rnbls = app.dataMatfile.no_rnbls;
	                app.timeOffset = 0.0001; %Updating value slightly before actual time ***should be smaller than sample time***

	                if app.UpdateHarness.Value && app.errorFlag == 0
		            	app.SelectmodeltotestLabel.Text = 'Importing test cases from Excel';
		            	drawnow
		                
		                errorCode = 2; %error in opening MIL harness
		                open_system(app.harness_name_MIL);

		                figure(app.UIFigure);
		                CreateHarness(app);

		                errorCode = 3; %error in writing to mat
		                app.dataMatfile.test_data = app.test_data;
		            end

		            if app.UpdateCases.Value && app.errorFlag == 0

		            	errorCode = 4; %error in reading data in mat
		            	app.test_data = app.dataMatfile.test_data;

		            	errorCode = 2; %error in opening MIL harness
		            	open_system(app.harness_name_MIL);

		            	figure(app.UIFigure);
		            	UpdateSignal(app);

		            	errorCode = 3; %error in writing to mat
		                app.dataMatfile.test_data = app.test_data;

		            end

		            if app.RunTests.Value && app.errorFlag == 0
		            	errorCode = 4; %error in reading data in mat
		            	app.test_data = app.dataMatfile.test_data;
		            	app.SelectmodeltotestLabel.Text = 'Simulating test cases';
		                drawnow

		                errorCode = 2; %error in opening MIL harness
		                open_system(app.harness_name_MIL);

		                %DataDictSec = getSection(DataDictObj,'Design Data');
		                
		                %app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},'SigData',{},'Result',{},'DataLog',{},'TimeData',{});
		                %failed_result: <b style="color:Red;">Failed</b>
		                %passed_result: <b style="color:Green;">Passed</b>
		                
		                figure(app.UIFigure);

		                %Running results
		                configUpdate(app,DataDictObj,'off');
		                RunMILTest(app);

		                errorCode = 3; %error in writing to mat
		                app.dataMatfile.test_data = app.test_data;
		%               Ex_Workbook.Save;
		            end

		            if app.RunSIL.Value && app.errorFlag == 0
		            	app.SelectmodeltotestLabel.Text = 'Simulating test cases';
		                drawnow
		                errorCode = 4; %error in reading data in mat
		                app.test_data = app.dataMatfile.test_data;

		                errorCode = 5; %error in opening SIL harness
		                open_system(app.harness_name_SIL);
		                figure(app.UIFigure);
		                %DataDictSec = getSection(DataDictObj,'Design Data');
		                
		                %app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},'SigData',{},'Result',{},'DataLog',{},'TimeData',{});
		                %failed_result: <b style="color:Red;">Failed</b>
		                %passed_result: <b style="color:Green;">Passed</b>
		                
		                %Running results
		                configUpdate(app,DataDictObj,'on');
		                RunSILTest(app);

		                errorCode = 3; %error in writing to mat
		                app.dataMatfile.test_data_SIL = app.test_data_SIL;
		%               Ex_Workbook.Save;
		            end
	            catch ErrorCaught
	            	app.errorFlag = 1;
	            	assignin('base','ErrorInfo_Execute',ErrorCaught);
					
					switch errorCode
	                	case 1
	                		%error in reading mat file
	                		warning('-----------Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
							uialert(app.UIFigure,sprintf('Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error','Icon','error');
	                	case 2
	                		%error in opening MIL harness
	                		warning('-----------Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option-----------',app.harness_name_MIL);
	                		uialert(app.UIFigure,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option',app.harness_name_MIL),'Error');
	                	case 3
	                		%error in writing to mat
	                		warning('-----------Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
	                		uialert(app.UIFigure,sprintf('Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
	                	case 4
	                		%error in reading to mat
	                		warning('-----------Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
	                		uialert(app.UIFigure,sprintf('Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
	                	case 5
	                		%error in opening MIL harness
	                		warning('-----------Unable to load SIL harness ''%s''. Create harness using ''Complete harness'' Option-----------',app.harness_name_SIL);
	                		uialert(app.UIFigure,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Complete harness'' Option',app.harness_name_MIL),'Error');
	                end
					fprintf(2,'Error: %s\n',ErrorCaught.message);
				end
            end

            if app.errorFlag
	        else
	            if app.MILReport.Value
	            	reportMIL(app);
	            end

	            if app.SILReport.Value
	            	reportSIL(app);
	            end
	        end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 630 343];
            app.UIFigure.Name = 'MIL & SIL testing (v4)';

            % Create OpenButton
            app.OpenButton = uibutton(app.UIFigure, 'push');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenButton.Position = [465 287 99 22];
            app.OpenButton.Text = 'Open';

            % Create CreateExcel
            app.CreateExcel = uicheckbox(app.UIFigure);
            app.CreateExcel.ValueChangedFcn = createCallbackFcn(app, @CreateExcelValueChanged, true);
            app.CreateExcel.Text = ' Export TC Excel';
            app.CreateExcel.Position = [76 204 112 22];

            % Create Execute
            app.Execute = uibutton(app.UIFigure, 'push');
            app.Execute.ButtonPushedFcn = createCallbackFcn(app, @ExecuteButtonPushed, true);
            app.Execute.Enable = 'off';
            app.Execute.Position = [193 64 243 22];
            app.Execute.Text = 'Create Excel';

            % Create SelectmodeltotestLabel
            app.SelectmodeltotestLabel = uilabel(app.UIFigure);
            app.SelectmodeltotestLabel.HorizontalAlignment = 'center';
            app.SelectmodeltotestLabel.FontWeight = 'bold';
            app.SelectmodeltotestLabel.FontAngle = 'italic';
            app.SelectmodeltotestLabel.Position = [83 28 467 22];
            app.SelectmodeltotestLabel.Text = 'Select model to test';

            % Create UpdateHarness
            app.UpdateHarness = uicheckbox(app.UIFigure);
            app.UpdateHarness.ValueChangedFcn = createCallbackFcn(app, @UpdateHarnessValueChanged, true);
            app.UpdateHarness.Text = ' Complete harness';
            app.UpdateHarness.Position = [253 204 123 22];

            % Create UpdateCases
            app.UpdateCases = uicheckbox(app.UIFigure);
            app.UpdateCases.ValueChangedFcn = createCallbackFcn(app, @UpdateCasesValueChanged, true);
            app.UpdateCases.Text = ' Update test cases';
            app.UpdateCases.Position = [441 204 121 22];

            % Create AUTOSARButton
            app.AUTOSARButton = uibutton(app.UIFigure, 'state');
            app.AUTOSARButton.ValueChangedFcn = createCallbackFcn(app, @AUTOSARButtonValueChanged, true);
            app.AUTOSARButton.Text = 'AUTOSAR';
            app.AUTOSARButton.BackgroundColor = [0 0.902 0];
            app.AUTOSARButton.Position = [175 245 100 22];

            % Create TestingPanel
            app.TestingPanel = uipanel(app.UIFigure);
            app.TestingPanel.BorderType = 'none';
            app.TestingPanel.Title = '      ';
            app.TestingPanel.Position = [49 93 531 113];

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
            app.Panel = uipanel(app.TestingPanel);
            app.Panel.ForegroundColor = [1 0.4118 0.1608];
            app.Panel.BorderType = 'none';
            app.Panel.BackgroundColor = [0.8706 0.8706 0.8706];
            app.Panel.Position = [277 15 205 72];

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
            %app.SLDVButton.Enable = 'off'; %remove this after beta release

            % Create SILReport
            app.SILReport = uicheckbox(app.Panel);
            app.SILReport.ValueChangedFcn = createCallbackFcn(app, @SILReportValueChanged, true);
            app.SILReport.Text = ' SIL Report';
            app.SILReport.Position = [9 7 83 22];

            % Create ModelNameEditFieldLabel
            app.ModelNameEditFieldLabel = uilabel(app.UIFigure);
            app.ModelNameEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelNameEditFieldLabel.Position = [45 287 77 22];
            app.ModelNameEditFieldLabel.Text = 'Model Name:';

            % Create ModelNameEditField
            app.ModelNameEditField = uieditfield(app.UIFigure, 'text');
            app.ModelNameEditField.Editable = 'off';
            app.ModelNameEditField.Position = [152 287 290 22];

            % Create ModelVersionEditFieldLabel
            app.ModelVersionEditFieldLabel = uilabel(app.UIFigure);
            app.ModelVersionEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelVersionEditFieldLabel.Position = [356 245 85 22];
            app.ModelVersionEditFieldLabel.Text = 'Model Version:';

            % Create ModelVersionEditField
            app.ModelVersionEditField = uieditfield(app.UIFigure, 'text');
            app.ModelVersionEditField.Editable = 'off';
            app.ModelVersionEditField.HorizontalAlignment = 'center';
            app.ModelVersionEditField.Position = [448 245 38 22];
            app.ModelVersionEditField.Value = '1.0';

            % Create ThisisanLabel
            app.ThisisanLabel = uilabel(app.UIFigure);
            app.ThisisanLabel.Position = [116 245 57 22];
            app.ThisisanLabel.Text = 'This is an';

            % Create modelLabel
            app.modelLabel = uilabel(app.UIFigure);
            app.modelLabel.Position = [283 245 38 22];
            app.modelLabel.Text = 'model';
        end
    end

    methods (Access = public)

        % Construct app
        function app = Testing_GUI

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end