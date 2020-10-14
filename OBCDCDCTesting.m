classdef OBCDCDCTesting < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        OBCTesting               matlab.ui.Figure
        ModelNameEditFieldLabel  matlab.ui.control.Label
        ModelNameEditField       matlab.ui.control.EditField
        Open                     matlab.ui.control.Button
        Panel                    matlab.ui.container.Panel
        ExecuteButton            matlab.ui.control.Button
        Label                    matlab.ui.control.Label
        UpdateHarnessCheckBox    matlab.ui.control.CheckBox
        RunMILCheckBox           matlab.ui.control.CheckBox
        SILPanel                 matlab.ui.container.Panel
        RunSILCheckBox           matlab.ui.control.CheckBox
        WithoutSLDVButton        matlab.ui.control.StateButton
    end

    properties (Access = private)
        %Common properties
        ModelName
        rootPath
        OnlyModelName
        harness_name_MIL
        harness_name_SIL
        report_name_MIL
        report_name_SIL
        
        simDataTypes

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

        % Code that executes after component creation
        function startupFcn(app)
            app.simDataTypes = {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','boolean'};
            app.AUTOSAR_stat = 1;
        end

        function updateStatus(app)
            if ~isempty(app.ModelNameEditField.Value)
                if isequal(app.UpdateHarnessCheckBox.Value, 1) && isequal(app.RunMILCheckBox.Value, 1) && isequal(app.RunSILCheckBox.Value, 1)
                    app.Label.Text = 'Update test cases in Harness and execute MIL and SIL test cases';
                    app.ExecuteButton.Text = 'Execute MIL & SIL';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.UpdateHarnessCheckBox.Value, 1) && isequal(app.RunMILCheckBox.Value, 1)
                    app.Label.Text = 'Update test cases in Harness and execute MIL test cases';
                    app.ExecuteButton.Text = 'Execute MIL test cases';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.UpdateHarnessCheckBox.Value, 1) && isequal(app.RunSILCheckBox.Value, 1)
                    app.Label.Text = 'Update test cases in Harness and execute SIL test cases';
                    app.ExecuteButton.Text = 'Execute SIL test cases';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.RunMILCheckBox.Value, 1) && isequal(app.RunSILCheckBox.Value, 1)
                    app.Label.Text = 'Execute MIL and SIL test cases';
                    app.ExecuteButton.Text = 'Execute MIL & SIL test cases';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.UpdateHarnessCheckBox.Value, 1)
                    app.Label.Text = 'Update test cases in Harness';
                    app.ExecuteButton.Text = 'Update Harness';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.RunMILCheckBox.Value, 1)
                    app.Label.Text = 'Execute MIL test cases and update results in Excel';
                    app.ExecuteButton.Text = 'Execute MIL test cases';
                    app.ExecuteButton.Enable = 'on';
                elseif isequal(app.RunSILCheckBox.Value, 1)
                    app.Label.Text = 'Execute SIL test cases and update results in Excel';
                    app.ExecuteButton.Text = 'Execute SIL test cases';
                    app.ExecuteButton.Enable = 'on';
                else
                    app.ExecuteButton.Text = 'Select an option';
                    app.Label.Text = 'Select one or more options';
                    app.ExecuteButton.Enable = 'off';
                end
            else
                app.ExecuteButton.Text = 'Select model';
                app.Label.Text = 'Select model to test';
                app.ExecuteButton.Enable = 'off';
            end
            drawnow
        end

        % Value changed function: UpdateHarnessCheckBox
        function UpdateHarnessCheckBoxValueChanged(app, event)
            updateStatus(app);
        end

        % Button pushed function: Open
        function OpenButtonPushed(app, event)
            [app.ModelName,app.rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to test');
            app.Label.FontColor = [0 0 0];
            drawnow
            figure(app.OBCTesting);

            if isequal(app.ModelName,0)
                app.ExecuteButton.Text = 'Select model';
                app.Label.Text = 'Select model to test';
                app.ExecuteButton.Enable = 'off';
                app.ModelNameEditField.Value = '';
            elseif contains(app.ModelName,'_TestHarness_')
                app.ExecuteButton.Text = 'Select model';
                app.Label.Text = 'Select model to test';
                app.ExecuteButton.Enable = 'off';
                app.ModelNameEditField.Value = '';
                uialert(app.OBCTesting,'Select model to test not its harness','Error');
            else
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','Loading model',...
                            'Message',sprintf('Loading ''%s'' model',app.ModelName),'Indeterminate','on');
                drawnow
                cd(app.rootPath);
                [~,app.OnlyModelName,~] = fileparts(app.ModelName);
                app.harness_name_MIL = sprintf('MIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.harness_name_SIL = sprintf('SIL_Functional_TestHarness_%s',app.OnlyModelName);
                app.report_name_MIL = sprintf('MIL_Functional_TestReport_%s',app.OnlyModelName);
                app.report_name_SIL = sprintf('SIL_Functional_TestReport_%s',app.OnlyModelName);

                app.ExecuteButton.Text = 'Select an option';
                app.Label.Text = 'Select one or more options';
                app.ModelNameEditField.Value = app.ModelName;
                updateStatus(app);
                close(prog_stat);
            end
        end

        % Value changed function: RunMILCheckBox
        function RunMILCheckBoxValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: RunSILCheckBox
        function RunSILCheckBoxValueChanged(app, event)
            updateStatus(app);
        end

        % Value changed function: WithoutSLDVButton
        function WithoutSLDVButtonValueChanged(app, event)
            if app.WithoutSLDVButton.Value == 0
                app.WithoutSLDVButton.Text = 'Without SLDV';
            else
                app.WithoutSLDVButton.Text = 'With SLDV';
            end
            updateStatus(app);
            drawnow
        end

        % loadModel
        function loadModel(app, modelName)
            if bdIsLoaded(modelName)
            else
                load_system(sprintf('%s.slx',modelName));
            end
        end

        %throwError
        function throwError(app,caughtError,msgError)
            if caughtError
                error(msgError);
            end
        end

        function [caughtError, availExcel] = ReadingExcel(app)
            try
                caughtError = 0;
                errorCode = 1; %Error in loading excel
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','Importing test cases Excel',...
                            'Message','Loading Excel','Indeterminate','on'); 
                drawnow

                if ~isequal(exist([app.report_name_MIL '.xlsx']), 0) && ~isequal(exist([app.report_name_SIL '.xlsx']), 0)
                    availExcel = 'both';
                elseif ~isequal(exist([app.report_name_MIL '.xlsx']), 0)
                    availExcel = 'MIL';
                elseif ~isequal(exist([app.report_name_SIL '.xlsx']), 0)
                    availExcel = 'SIL';
                else
                    availExcel = '';
                    figure(app.OBCTesting);
                    caughtError = 1;
                    uialert(app.OBCTesting,'Excel report files are not found','Error');
                    app.errorFlag = 1;
                end

                if ~isempty(availExcel)
                    Excel = actxserver('Excel.Application');

                    if isequal(availExcel, 'MIL') || isequal(availExcel, 'both')
                        Ex_Workbook = Excel.Workbooks.Open(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                    else
                        Ex_Workbook = Excel.Workbooks.Open(sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                    end

                    Ex_Sheets = Excel.ActiveWorkbook.Sheets;
                    Ex_actSheet = Ex_Sheets.get('Item',1);
                    Excel.Visible = 1;
                    
                    figure(app.OBCTesting);
                    Ex_range = get(Ex_actSheet,'Range','B4');
                    caseNo = 1;

                    app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},...
                                'SigData',{},'SigTime',{},'Result',{},'DataLog',{},'TimeData',{},'ScopeSelect',{},'SLDVExpTime',{});

                    errorCode = 2; %Error in reading excel
                    while ~isnan(Ex_range.Value)
                        app.test_data(caseNo).TestCaseID = Ex_range.Value;
                        app.Label.Text = sprintf('Importing %s from Excel',app.test_data(caseNo).TestCaseID);
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
                        if ~isequal(exist(app.harness_name_MIL), 0)
                            set_param(sprintf('%s/InitFunCallGen',app.harness_name_MIL),'sample_time',num2str(sum([app.test_data.TestTime])+1));
                        end

                        if ~isequal(exist(app.harness_name_SIL), 0)
                            set_param(sprintf('%s/InitFunCallGen',app.harness_name_SIL),'sample_time',num2str(sum([app.test_data.TestTime])+1));
                        end
                    end
                    
                    Ex_Workbook.Close;
                    Excel.Quit;

                    close(prog_stat);
                    %uialert(app.OBCTesting,'Harness is completed according to test cases','Success','icon','success');
                end
            catch ErrorCaught
                figure(app.OBCTesting);
                caughtError = 1;
                assignin('base','IntErrorInfo_ReadingExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import test cases from Excel. Retry after fixing error-----------');
                app.Label.Text = 'Unable to import test cases from Excel. Retry after fixing error';
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading excel
                        uialert(app.OBCTesting,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in adding test cases in Signal builder
                        if isempty(app.test_data(caseNo).TestCaseID)
                            uialert(app.OBCTesting,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                        else
                            uialert(app.OBCTesting,sprintf('Unable to import ''%s'' test case from Excel. Retry after fixing error. Check command window for error info', app.test_data(caseNo).TestCaseID),'Error');
                        end
                        Ex_Workbook.Close;
                        Excel.Quit;
                    case 3
                        %Error in adding test cases in Signal builder
                        uialert(app.OBCTesting,'Unable to update Init function call generator. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;      
        end

        % UpdateSignal
        function availHarness = UpdateSignal(app)
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
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','Updating test cases',...
                            'Message','Resetting signal builders','Indeterminate','on'); 
                drawnow

                exist('SIL_Functional_TestReport_ChgIntf.xlsx')

                if ~isequal(exist(app.harness_name_MIL), 0) && ~isequal(exist(app.harness_name_SIL), 0)
                    availHarness = 'both';
                elseif ~isequal(exist(app.harness_name_MIL), 0)
                    availHarness = 'MIL';
                elseif ~isequal(exist(app.harness_name_SIL), 0)
                    availHarness = 'SIL';
                else
                    availHarness = '';
                    figure(app.OBCTesting);
                    caughtError = 1;
                    uialert(app.OBCTesting,'Test harness files are not found','Error');
                    app.errorFlag = 1;
                end

                if ~isempty(availHarness)
                    if isequal(availHarness, 'both')
                        loadModel(app,app.harness_name_MIL);
                        sigBuilders_MIL = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');

                        loadModel(app,app.harness_name_SIL);
                        sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
                    elseif isequal(availHarness, 'MIL')
                        loadModel(app,app.harness_name_MIL);
                        sigBuilders_MIL = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');
                        sigBuilders_SIL = '';
                    elseif isequal(availHarness, 'SIL')
                        loadModel(app,app.harness_name_SIL);
                        sigBuilders_SIL = find_system(app.harness_name_SIL,'MaskType','Sigbuilder block');
                        sigBuilders_MIL = '';
                    end

                    %deleting signals (all but first)
                    if ~isempty(sigBuilders_MIL)
                        [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_MIL{1,1});
                        for grp_no = 2 : length(groupnames_t)
                            signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                        end
                    end

                    if ~isempty(sigBuilders_SIL)
                        [~, ~, signames_t, groupnames_t] = signalbuilder(sigBuilders_SIL{1,1});
                        for grp_no = 2 : length(groupnames_t)
                            signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                        end
                    end

                    close(prog_stat);
                    errorCode = 2; %Error in reading excel
                    [caughtError, availExcel] = ReadingExcel(app);
                    throwError(app,caughtError,'Unable to read excel. Check previous messages for error info');

                    errorCode = 3; %Error in adding test cases to signal builder
                    prog_stat = uiprogressdlg(app.OBCTesting,'Title','Updating test cases',...
                                'Message','Updating signal builders'); 

                    for caseNo = 1:length(app.test_data)
                        %timeStamps = 0:0.002:app.test_data(caseNo).TestTime;
                        
                        app.Label.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
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

                        if ~isempty(sigBuilders_MIL)
                            signalbuilder(sigBuilders_MIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
                        end

                        if ~isempty(sigBuilders_SIL)
                        signalbuilder(sigBuilders_SIL{1,1},'appendgroup',time_array,signal_data,signal_name,app.test_data(caseNo).TestCaseID);
                        end
                        
                        if caseNo == 1
                            %deleting the first one
                            if ~isempty(sigBuilders_MIL)
                                signalbuilder(sigBuilders_MIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                            end
                            if ~isempty(sigBuilders_SIL)
                                signalbuilder(sigBuilders_SIL{1,1}, 'set', [1:length(signames_t)], 1, [], []);
                            end
                        end 
                    end
                    
                    if ~isempty(sigBuilders_MIL)
                        save_system(app.harness_name_MIL);
                    end
                    
                    if ~isempty(sigBuilders_SIL)
                        save_system(app.harness_name_SIL);
                    end

                    if isequal(availExcel, 'both')
                        errorCode = 4; %Error in copying excel
                        prog_stat.Message = 'Updating SIL test cases Excel';
                        prog_stat.Indeterminate = 'on';

                        delete(sprintf('SIL_Functional_TestReport_%s.xlsx',app.OnlyModelName));
                        copyfile(sprintf('%sMIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName),...
                                sprintf('%sSIL_Functional_TestReport_%s.xlsx',app.rootPath,app.OnlyModelName));
                    end
                    
                    close(prog_stat);
                    
                    if isequal(availExcel, 'both')
                        app.Label.Text = 'Updated MIL & SIL harnesses';
                    elseif isequal(availExcel, 'MIL')
                        app.Label.Text = 'Updated MIL harnesses';
                    elseif isequal(availExcel, 'SIL')
                        app.Label.Text = 'Updated SIL harnesses';
                    end

                    uialert(app.OBCTesting,'Harnesses are updated according to new test cases','Success','icon','success');
                end
            catch ErrorCaught
                figure(app.OBCTesting);
                assignin('base','ErrorInfo_UpdateSignal',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to update signal builder with new test cases. Retry after fixing error-----------');
                app.Label.Text = 'Unable to update signal builder with new test cases. Retry after fixing error';
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in resetting signal builders
                        uialert(app.OBCTesting,'Unable to reset signal builders. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in reading excel
                        %uialert(app.OBCTesting,'Unable to import test cases from Excel. Retry after fixing error. Check command window for error info','Error');
                    case 3
                        %Error in adding test cases to signal builder
                        uialert(app.OBCTesting,'Unable to update signal builders. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 4
                        %Error in adding test cases in Signal builder
                        uialert(app.OBCTesting,sprintf('Unable to copy updated test cases from ''MIL_Functional_TestReport_%s.xlsx'' to ''SIL_Functional_TestReport_%s.xlsx''. Delete ''SIL_Functional_TestReport_%s.xlsx'' and copy the file manually\n',app.OnlyModelName,app.OnlyModelName,app.OnlyModelName),'Error');
                        app.Label.Text = 'Updated both harnesses. Manually copy test cases from MIL Excel to SIL Excel';
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
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','Updating results in Excel',...
                            'Message','Loading Excel'); 
            
                Excel = actxserver('Excel.Application');
                Ex_Workbook = Excel.Workbooks.Open(sprintf('%s%s_Functional_TestReport_%s.xlsx',app.rootPath,test_mode,app.OnlyModelName));
                Ex_Sheets = Excel.ActiveWorkbook.Sheets;
                Ex_actSheet = Ex_Sheets.get('Item',1);
                Excel.Visible = 1;
            
                figure(app.OBCTesting);
            
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
                    app.Label.Text = sprintf('Updating %s results of %s',test_mode,app.test_data(caseNo).TestCaseID);
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
                uialert(app.OBCTesting,'Harness is completed according to test cases','Success','icon','success');
            catch ErrorCaught
                figure(app.OBCTesting);
                caughtError = 1;
                assignin('base','IntErrorInfo_UpdateExcel',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to update results in Excel. Retry after fixing error-----------');
                app.Label.Text = 'Unable to update results in Excel. Retry after fixing error';
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading excel
                        uialert(app.OBCTesting,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                    case 2
                        %Error in updating excel
                        uialert(app.OBCTesting,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                        Ex_Workbook.Close;
                        Excel.Quit;
                    case 3
                        %Error in saving excel
                        uialert(app.OBCTesting,'Unable to save Excel after updating results. Retry after fixing error. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;
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
                figure(app.OBCTesting);
                assignin('base','ErrorInfo_configUpdate',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable update configuration parameters-----------');
                uialert(app.OBCTesting,'Unable update configuration parameters','Error','Icon','error');
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
	                figure(app.OBCTesting);
	                assignin('base','ErrorInfo_updateParam',ErrorCaught);
	                app.errorFlag = 1;
	                caughtError = 1;
	                switch errorCode
	                    case 1
	                        warning('-----------Unable update global configurations in data dictionary-----------');
	                        uialert(app.OBCTesting,'Unable update global configurations in data dictionary','Error','Icon','error');
	                    case 2
	                        warning('-----------Unable to save data dictionary or model-----------');
	                        uialert(app.OBCTesting,'Unable to save data dictionary or model','Error','Icon','error');
	                end
	                fprintf(2,'Error: %s\n',ErrorCaught.message);
	        	end
	        end
        end 
        
        % RunMILTest
        function RunMILTest(app, DataDictObj, DataDictSec)
            try
                errorCode = 1; %Error in simulating model
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','MIL testing',...
                            'Message','MIL testing'); 
                drawnow
                % set_param(app.harness_name_MIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                set_param(sprintf('%s/%s',app.harness_name_MIL,app.OnlyModelName),'SimulationMode','Normal');
                sigBuilders = find_system(app.harness_name_MIL,'MaskType','Sigbuilder block');
                save_system(app.harness_name_MIL);

            	readParam(app);

                set_param(app.harness_name_MIL,'FastRestart','on','SimulationMode','Normal');
                for caseNo = 1:length(app.test_data)
                    %simulating current group
                    signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

                    app.Label.Text = sprintf('MIL testing of %s',app.test_data(caseNo).TestCaseID);
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

                uialert(app.OBCTesting,'MIL testing completed','Success','icon','success');
                app.Label.Text = 'MIL Testing completed';
            catch ErrorCaught
                figure(app.OBCTesting);
                set_param(app.harness_name_MIL,'FastRestart','off');
                assignin('base','ErrorInfo_RunMILTest',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to MIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.Label.Text = sprintf('Unable to MIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in simulating model
                        uialert(app.OBCTesting,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 2
                        %Error in updating results
                        %uialert(app.OBCTesting,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
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
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','SIL testing',...
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
                
                % set_param(app.harness_name_SIL,'Creator','KPIT','ModifiedByFormat','KPIT','ModelVersionFormat',app.ModelVersionEditField.Value);
                save_system(app.harness_name_SIL);
                temp_data = app.test_data;

                if app.WithoutSLDVButton.Value
                    close(prog_stat);
                    errorCode = 4; %Error in importing SLDV test cases
                    caughtError = importSLDV(app);
                    throwError(app,caughtError,'Unable to import SLDV test cases. Check previous messages for error info');
                end

                prog_stat = uiprogressdlg(app.OBCTesting,'Title','SIL testing',...
                            'Message','SIL testing'); 
                drawnow

                readParam(app);

                set_param(app.harness_name_SIL,'FastRestart','on','SimulationMode','Normal');
                for caseNo = 1:length(app.test_data)
                    %simulating current group
                    signalbuilder(sigBuilders{1,1}, 'activegroup', caseNo);

                    save_system(app.OnlyModelName);
                    app.Label.Text = sprintf('SIL testing of %s',app.test_data(caseNo).TestCaseID);
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

                uialert(app.OBCTesting,'SIL testing completed','Success','icon','success');
                app.Label.Text = 'SIL Testing completed';
            catch ErrorCaught
                figure(app.OBCTesting);
                assignin('base','ErrorInfo_RunSILTest',ErrorCaught);
                app.errorFlag = 1;
                warning('-----------Unable to SIL test %s model. Retry after fixing error-----------',app.OnlyModelName);
                app.Label.Text = sprintf('Unable to SIL test %s model. Retry after fixing error',app.OnlyModelName);
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in loading Excel
                        uialert(app.OBCTesting,'Unable to load Excel. Retry after fixing error. Check command window for error info','Error');
                        close(prog_stat);
                    case 2
                        %Error in simulating model
                        uialert(app.OBCTesting,'Unable to simulate model. Retry after fixing error. Check command window for error info','Error');
                        app.test_data_SIL = app.test_data;
                        app.test_data = temp_data;
                        close(prog_stat);
                    case 3
                        %Error in updating results
                        %uialert(app.OBCTesting,'Unable to update results in Excel. Retry after fixing error. Check command window for error info','Error');
                        app.test_data_SIL = app.test_data;
                        app.test_data = temp_data;
                    case 4
                        %Error in importing SLDV test cases
                        %uialert(app.OBCTesting,'Unable to import SLDV test cases. Retry after fixing error. Check command window for error info','Error');
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
                app.Label.FontColor = [0 0 0];
                prog_stat = uiprogressdlg(app.OBCTesting,'Title','Loading test cases from SLDV',...
                            'Message','Checking files...','Indeterminate','on');
                app.Label.Text = 'Checking SLDV files';
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
                            app.test_data(caseNo).TestCaseID = sprintf('%sC_%03d',caseID,caseNo);
                            app.test_data(caseNo).ScopeSelect = ones(2,max(app.no_inports,app.no_outports));
                            app.test_data(caseNo).SigData = app.port_data;
                            app.test_data(caseNo).SigTime = zeros(1,2*(length(all_time_values)));

                            prog_stat.Message = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
                            app.Label.Text = sprintf('Importing test case: %s',app.test_data(caseNo).TestCaseID);
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
                        
                        app.Label.Text = sprintf('Updating signal builder: %s',app.test_data(caseNo).TestCaseID);
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
                    app.Label.Text = 'Imported SLDV test cases';
                    uialert(app.OBCTesting,'Imported all SLDV test cases','Success','icon','success');
                    drawnow
                end
            catch ErrorCaught
                figure(app.OBCTesting);
                caughtError = 1;
                assignin('base','IntErrorInfo_importSLDV',ErrorCaught);
                close(prog_stat);
                warning('-----------Unable to import SLDV test cases. Retry after fixing error-----------');
                app.Label.Text = 'Unable to import SLDV test cases. Retry after fixing error';
                app.Label.FontColor = [1 0 0];
                switch errorCode
                    case 1
                        %Error in accessing sldv test cases
                        uialert(app.OBCTesting,'Unable to access sldv mat files. Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 2
                        %SLDV test cases are not available
                        uialert(app.OBCTesting,'Unable to find sldv data files(''*_sldvdata.mat''). Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 3
                        %SLDV folder not available
                        uialert(app.OBCTesting,'Unable to find ''sldv_output'' folder. Retry after generating SLDV test cases. Check command window for error info','Error');
                    case 4
                        %error in adding sldv test cases
                        uialert(app.OBCTesting,'Unable to add sldv test cases. Retry after fixing error. Check command window for error info','Error');
                    case 5
                        %error in updating signal builder
                        uialert(app.OBCTesting,'Unable to update signalbuilder. Retry after fixing error. Check command window for error info','Error');
                    case 6
                        %expected output not present
                        uialert(app.OBCTesting,'Unable to find expected outputs. Regenerate test cases after updating model configuration. Check command window for error info','Error');
                end
                drawnow
                fprintf(2,'Error: %s\n',ErrorCaught.message);
            end
            app.errorFlag = caughtError;
        end

        % Button pushed function: ExecuteButton
        function ExecuteButtonPushed(app, event)
            app.Label.Text = sprintf('Loading %s model', app.ModelName);
            drawnow
            loadModel(app, app.OnlyModelName);
            DataDictionary = get_param(app.OnlyModelName,'DataDictionary');
            DataDictObj = Simulink.data.dictionary.open(DataDictionary);
            DataDictSec = getSection(DataDictObj,'Design Data');

            app.errorFlag = 0;

            if (isequal(app.UpdateHarnessCheckBox.Value,1) || isequal(app.RunMILCheckBox.Value,1) || isequal(app.RunSILCheckBox.Value,1))
                try
                    errorCode = 1; %error in reading mat file
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

                    if app.UpdateHarnessCheckBox.Value && app.errorFlag == 0
                        errorCode = 4; %error in reading data in mat
                        app.test_data = app.dataMatfile.test_data;

                        % errorCode = 2; %error in opening MIL harness
                        % open_system(app.harness_name_MIL);

                        figure(app.OBCTesting);
                        availHarness = UpdateSignal(app);

                        errorCode = 3; %error in writing to mat
                        if isequal(availHarness,'both') || isequal(availHarness,'MIL')
                            app.dataMatfile.test_data = app.test_data;
                            test_data = app.test_data;
                            save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data', '-append')
                        else
                            app.dataMatfile.test_data_SIL = app.test_data;
                            test_data_SIL = app.test_data;
                            save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data_SIL', '-append')
                        end
                    end

                    if app.RunMILCheckBox.Value && app.errorFlag == 0
                        if ~isequal(exist(app.harness_name_MIL), 0)
                            errorCode = 4; %error in reading data in mat
                            app.test_data = app.dataMatfile.test_data;
                            app.Label.Text = 'Loading files...';
                            app.Label.FontColor = [0 0 0];
                            drawnow

                            errorCode = 2; %error in opening MIL harness
                            open_system(app.harness_name_MIL);

                            %DataDictSec = getSection(DataDictObj,'Design Data');
                            
                            %app.test_data = struct('TestCaseID',{},'RequirementID',{},'TestDescription',{},'TestOutput',{},'TestTime',{},'SigData',{},'Result',{},'DataLog',{},'TimeData',{});
                            %failed_result: <b style="color:Red;">Failed</b>
                            %passed_result: <b style="color:Green;">Passed</b>
                            
                            figure(app.OBCTesting);

                            %Running results
                            %configUpdate(app,DataDictObj,'off','on');
                            configUpdate(app,DataDictObj,'on','off');
                            RunMILTest(app, DataDictObj, DataDictSec);
                            configUpdate(app,DataDictObj,'off','on');

                            errorCode = 3; %error in writing to mat
                            app.dataMatfile.test_data = app.test_data;
                            test_data = app.test_data;
                            save(sprintf('%s_TestHarness_data.mat',app.OnlyModelName),'test_data', '-append')
                        else
                            figure(app.OBCTesting);
                            uialert(app.OBCTesting,'MIL harness not found, Cannot proceed with MIL testing.','Error');
                        end
                    end

                    if app.RunSILCheckBox.Value && app.errorFlag == 0
                        if ~isequal(exist(app.harness_name_SIL), 0)
                            app.Label.Text = 'Loading files...';
                            app.Label.FontColor = [0 0 0];
                            drawnow
                            errorCode = 4; %error in reading data in mat
                            app.test_data = app.dataMatfile.test_data;

                            errorCode = 5; %error in opening SIL harness
                            open_system(app.harness_name_SIL);
                            figure(app.OBCTesting);
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
                        else
                            figure(app.OBCTesting);
                            uialert(app.OBCTesting,'SIL harness not found, Cannot proceed with SIL testing.','Error');
                        end
                    end
                catch ErrorCaught
                    figure(app.OBCTesting);
                    app.errorFlag = 1;
                    assignin('base','ErrorInfo_ExecuteTEST',ErrorCaught);
                    
                    switch errorCode
                        case 1
                            %error in reading mat file
                            warning('-----------Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.OBCTesting,sprintf('Unable read ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error','Icon','error');
                        case 2
                            %error in opening MIL harness
                            warning('-----------Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option-----------',app.harness_name_MIL);
                            uialert(app.OBCTesting,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Export TC Excel'' Option',app.harness_name_MIL),'Error');
                        case 3
                            %error in writing to mat
                            warning('-----------Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.OBCTesting,sprintf('Unable access ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
                        case 4
                            %error in reading to mat
                            warning('-----------Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness-----------',app.OnlyModelName);
                            uialert(app.OBCTesting,sprintf('Unable to read test data in ''%s_TestHarness_data.mat'' file. Retry after fixing error or recreate harness',app.OnlyModelName),'Error');
                        case 5
                            %error in opening MIL harness
                            warning('-----------Unable to load SIL harness ''%s''. Create harness using ''Complete harness'' Option-----------',app.harness_name_SIL);
                            uialert(app.OBCTesting,sprintf('Unable to load MIL harness ''%s''. Create harness using ''Complete harness'' Option',app.harness_name_MIL),'Error');
                    end
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create OBCTesting
            app.OBCTesting = uifigure;
            app.OBCTesting.Position = [100 100 671 187];
            app.OBCTesting.Name = 'OBC DCDC Testing';

            % Create ModelNameEditFieldLabel
            app.ModelNameEditFieldLabel = uilabel(app.OBCTesting);
            app.ModelNameEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelNameEditFieldLabel.Position = [30 144 80 22];
            app.ModelNameEditFieldLabel.Text = 'Model Name: ';

            % Create ModelNameEditField
            app.ModelNameEditField = uieditfield(app.OBCTesting, 'text');
            app.ModelNameEditField.Editable = 'off';
            app.ModelNameEditField.Position = [120 144 401 22];

            % Create Open
            app.Open = uibutton(app.OBCTesting, 'push');
            app.Open.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.Open.Position = [545 144 94 22];
            app.Open.Text = 'Open';

            % Create Panel
            app.Panel = uipanel(app.OBCTesting);
            app.Panel.BorderType = 'none';
            app.Panel.Title = '  ';
            app.Panel.Position = [28 27 618 78];

            % Create ExecuteButton
            app.ExecuteButton = uibutton(app.Panel, 'push');
            app.ExecuteButton.ButtonPushedFcn = createCallbackFcn(app, @ExecuteButtonPushed, true);
            app.ExecuteButton.Enable = 'off';
            app.ExecuteButton.Position = [218 29 183 22];
            app.ExecuteButton.Text = 'Select model';

            % Create Label
            app.Label = uilabel(app.Panel);
            app.Label.HorizontalAlignment = 'center';
            app.Label.FontWeight = 'bold';
            app.Label.FontAngle = 'italic';
            app.Label.Position = [29 -3 562 22];
            app.Label.Text = 'Select model to test';

            % Create UpdateHarnessCheckBox
            app.UpdateHarnessCheckBox = uicheckbox(app.OBCTesting);
            app.UpdateHarnessCheckBox.ValueChangedFcn = createCallbackFcn(app, @UpdateHarnessCheckBoxValueChanged, true);
            app.UpdateHarnessCheckBox.Text = ' Update Harness';
            app.UpdateHarnessCheckBox.Position = [71 99 112 22];

            % Create RunMILCheckBox
            app.RunMILCheckBox = uicheckbox(app.OBCTesting);
            app.RunMILCheckBox.ValueChangedFcn = createCallbackFcn(app, @RunMILCheckBoxValueChanged, true);
            app.RunMILCheckBox.Text = ' Run MIL';
            app.RunMILCheckBox.Position = [267 99 70 22];

            % Create SILPanel
            app.SILPanel = uipanel(app.OBCTesting);
            app.SILPanel.BackgroundColor = [0.902 0.902 0.902];
            app.SILPanel.Position = [407 95 214 30];

            % Create RunSILCheckBox
            app.RunSILCheckBox = uicheckbox(app.SILPanel);
            app.RunSILCheckBox.ValueChangedFcn = createCallbackFcn(app, @RunSILCheckBoxValueChanged, true);
            app.RunSILCheckBox.Text = ' Run SIL';
            app.RunSILCheckBox.Position = [13 4 69 22];

            % Create WithoutSLDVButton
            app.WithoutSLDVButton = uibutton(app.SILPanel, 'state');
            app.WithoutSLDVButton.ValueChangedFcn = createCallbackFcn(app, @WithoutSLDVButtonValueChanged, true);
            app.WithoutSLDVButton.Text = 'Without SLDV';
            app.WithoutSLDVButton.Position = [97 4 103 22];
        end
    end

    methods (Access = public)

        % Construct app
        function app = OBCDCDCTesting

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.OBCTesting)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.OBCTesting)
        end
    end
end