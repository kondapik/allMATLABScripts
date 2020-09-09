%{

%
    DECRIPTION:
	Does something interesting
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 19-Sep-2019
    LAST MODIFIED: 13-Dec-2019
%
    VERSION MANAGER
    v1      Panel with input and output table
            Buttons to reset, wait standby, prepare charge and charge modes
            Feedback loop for switch S2 and plug lock commands
    v1.1    Added drop down to select configuration and a button to select NvM or non NvM models
    v1.2    Updated inProc and outProc signal names according to 'autoIntegration.m'
            Moved feedback loop from GUI to model 
            GUI gets updated sensor input for feedback loops when it detects a change in command
    v1.3    Updated to work with mat file to store and load inputs and results
            Handling enums as inputs 
    v1.4    NvM support and presets updated to work with HLC
            Replaced NvM button with phase selection button
    v1.5    Added feature to open mat file to load log results without loading root model
            Moved delete option to pop up when log or input set is selected
            Added progress bar while setting preset
%}

classdef integrationPanel < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        simPanel                        matlab.ui.Figure
        OpenButton                      matlab.ui.control.Button
        ModelNameEditFieldLabel         matlab.ui.control.Label
        ModelNameEditField              matlab.ui.control.EditField
        Status                          matlab.ui.control.Label
        StartButton                     matlab.ui.control.StateButton
        StopButton                      matlab.ui.control.Button
        SimTimeLabel                    matlab.ui.control.Label
        InputPresetsPanel               matlab.ui.container.Panel
        ResetButton                     matlab.ui.control.Button
        InputTable                      matlab.ui.control.Table
        SearchField                     matlab.ui.control.EditField
        OutputTable                     matlab.ui.control.Table
        OutputTable_2                   matlab.ui.control.Table
        MatchLabel                      matlab.ui.control.Label
        Button_2                        matlab.ui.control.Button
        Button_3                        matlab.ui.control.Button
        Button_4                        matlab.ui.control.Button
        Button_5                        matlab.ui.control.Button
        Button_6                        matlab.ui.control.StateButton
        Button_7                        matlab.ui.control.StateButton
        Button_8                        matlab.ui.control.StateButton
        Button_9                        matlab.ui.control.StateButton
        ConfigurationDropDownLabel      matlab.ui.control.Label
        ConfigurationDropDown           matlab.ui.control.DropDown
        PhaseButton                     matlab.ui.control.StateButton
        LoggedRunsDropDownLabel         matlab.ui.control.Label
        LoggedRunsDropDown              matlab.ui.control.DropDown
        RecordedInputsDropDownLabel     matlab.ui.control.Label
        RecordedInputsDropDown          matlab.ui.control.DropDown
        SaveInputsButton                matlab.ui.control.Button
    end

    
    properties (Access = private)
        ModelName
        rootPath
        OnlyModelName
        slddName
        constNames
        inTableData
        outTableData
        refSystems
        inBackground
        outBackground
        dataMatFile
        nvmFlg

        allInputValues
        allOutputValues
        loggedInputs
        loggedRuns

        DataDictObj
        DataSectObj
        ConstDictObj
        ConstDictSec
        updateTimer

        prevSwS2Cmd
        prevPlgLckCmd
    end
    
    
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            evalin('base','clear');
        end

        % Close request function: simPanel
        function simPanelCloseRequest(app, event)
            if ~isequal(app.ModelName,0) && ~isempty(app.ModelName)
                prog_stat = uiprogressdlg(app.simPanel,'Title','Closing panel',...
                            'Message','Updating inports with sldd parameters ','Indeterminate','on');
	            allConsts = find_system(app.OnlyModelName,'SearchDepth',1,'BlockType','Constant');
	            for constNo = 1:length(allConsts)
	            	if ~isempty(regexpi(get_param(allConsts{constNo},'Name'),'.*_Constant'))
		            	constName = get_param(allConsts{constNo},'Name');
		            	set_param(allConsts{constNo},'Value',constName(1:end-9));
		            end
	            end
	            save_system(app.OnlyModelName);
                close_system(app.OnlyModelName);
                close(prog_stat);
        	end
            delete(app);
        end

        % Button pushed function: OpenButton
        function OpenButtonPushed(app, event)
            [app.ModelName,app.rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)';'*.mat','MAT-files (*.mat)'},'Select model to test');
            app.Status.FontColor = [0 0 0];
            figure(app.simPanel);
            if isequal(app.ModelName,0)
                app.Status.Text = 'Select model to test';
                app.ModelNameEditField.Value = '';
                app.StartButton.Enable = 'off';
                app.InputTable.Data = [];
                app.OutputTable.Data = [];
                app.OutputTable_2.Data = [];
                app.inTableData = [];
                app.outTableData = [];
                app.ResetButton.Enable = 'off';
                app.Button_2.Enable = 'off';
                app.Button_3.Enable = 'off';
                app.Button_4.Enable = 'off';
                app.ConfigurationDropDown.Enable = 'off';
                app.PhaseButton.Enable = 'off';
                app.LoggedRunsDropDown.Enable = 'off';
                app.LoggedRunsDropDownLabel.Enable = 'off';
                app.RecordedInputsDropDownLabel.Enable = 'off';
                app.RecordedInputsDropDown.Enable = 'off';
                app.SaveInputsButton.Enable = 'off';
                app.ConfigurationDropDownLabel.Text = '';
            else
                [~,app.OnlyModelName,ext] = fileparts(app.ModelName);
                app.ModelNameEditField.Value = app.ModelName;
                if isequal(ext,'.slx')
                    prog_stat = uiprogressdlg(app.simPanel,'Title','Updating panel',...
                                'Message','Loading model...','Indeterminate','on');
                    app.slddName = sprintf('%s_InConst.sldd',app.OnlyModelName);
                    app.Status.Text = 'Start simulation and go to town on it';
                    if bdIsLoaded(app.OnlyModelName)
                    else
                        load_system(sprintf('%s.slx',app.OnlyModelName));
                    end

                    app.dataMatFile = matfile(sprintf('%s_IntegrationData.mat',app.OnlyModelName),'Writable',true);
                    app.allInputValues = app.dataMatFile.allInputValues;
                    app.allOutputValues = app.dataMatFile.allOutputValues;
                    app.loggedInputs = app.dataMatFile.loggedInputs;
                    app.loggedRuns = app.dataMatFile.loggedRuns;
                    app.nvmFlg = app.dataMatFile.nvmFlg;
                    %run(fullfile(app.rootPath,sprintf('%s_InputConsts.m',app.OnlyModelName)));
                    %app.constNames = fieldnames(InpConsts);
                    app.constNames = {app.allInputValues.Name};

                    if isempty(app.loggedInputs)
                        app.RecordedInputsDropDownLabel.Enable = 'off';
                        app.RecordedInputsDropDown.Enable = 'off';
                    else
                        app.RecordedInputsDropDownLabel.Enable = 'on';
                        app.RecordedInputsDropDown.Enable = 'on';
                        app.RecordedInputsDropDown.Items = horzcat({'Select input set'},{app.loggedInputs.Name});
                    end

                    if isempty(app.loggedRuns)
                        app.LoggedRunsDropDown.Enable = 'off';
                        app.LoggedRunsDropDownLabel.Enable = 'off';
                    else
                        app.LoggedRunsDropDown.Enable = 'on';
                        app.LoggedRunsDropDownLabel.Enable = 'on';
                        app.LoggedRunsDropDown.Items = horzcat({'Select result log'},{app.loggedRuns.Name});
                    end

                    prog_stat.Message = 'Reading inputs';
                    updateInputTable(app);
                    prog_stat.Message = 'Reading outputs';
                    createOutputTable(app);
                    prog_stat.Message = 'Updating Constants';
                    allConsts = find_system(app.OnlyModelName,'SearchDepth',1,'BlockType','Constant');
                    for constNo = 1:length(allConsts)
                        if ~isempty(regexpi(get_param(allConsts{constNo},'Name'),'.*_Constant'))
                            %set_param(allConsts{constNo},'Value','0');
                            dataType = get_param(allConsts{constNo},'OutDataTypeStr');
                            if isempty(regexpi(dataType,'Enum: .*'))
                                set_param(allConsts{constNo},'Value','0');
                            else
                                entryObj = getEntry(app.DataSectObj,dataType(7:end));
                                aliasValue = getValue(entryObj);
                                set_param(allConsts{constNo},'Value',sprintf('%s.%s',dataType(7:end),aliasValue.DefaultValue));
                            end
                        end
                    end

                    if app.nvmFlg == 0
                        app.ConfigurationDropDownLabel.Text = 'without NvM';
                        %confEntry = find(app.DataSectObj,'Name','ADTS_EVSEComProto');
                    else
                        app.ConfigurationDropDownLabel.Text = 'with NvM';
                        %confEntry = find(app.DataSectObj,'Name','ADTS_EVSEComProtoE');
                    end
                    confEntry = find(app.DataSectObj,'Name','ADTS_EVSEComProto');
                    confEnum = getValue(confEntry);
                    confValues = confEnum.Enumerals;
                    app.ConfigurationDropDown.Items = {confValues.Name};
                    
                    app.StartButton.Enable = 'on';
                    app.updateTimer = timer('ExecutionMode','fixedSpacing','Name','updateOutputs','Period',.5,'TimerFcn',@(~,~)app.updateOutputTable);
                    close(prog_stat);
                    
                    app.SaveInputsButton.Enable = 'on';
                    app.ResetButton.Enable = 'on';
                    app.Button_2.Enable = 'on';
                    app.Button_3.Enable = 'on';
                    app.Button_4.Enable = 'on';
                    app.ConfigurationDropDown.Enable = 'on';
                    app.PhaseButton.Enable = 'on';
                elseif isequal(ext,'.mat')
                    app.Status.Text = 'Select model to test';
                    app.ModelNameEditField.Value = '';
                    app.StartButton.Enable = 'off';
                    app.InputTable.Data = [];
                    app.OutputTable.Data = [];
                    app.OutputTable_2.Data = [];
                    app.inTableData = [];
                    app.outTableData = [];
                    app.ResetButton.Enable = 'off';
                    app.Button_2.Enable = 'off';
                    app.Button_3.Enable = 'off';
                    app.Button_4.Enable = 'off';
                    app.ConfigurationDropDown.Enable = 'off';
                    app.PhaseButton.Enable = 'off';
                    app.RecordedInputsDropDownLabel.Enable = 'off';
                    app.RecordedInputsDropDown.Enable = 'off';
                    app.SaveInputsButton.Enable = 'off';
                    app.ConfigurationDropDownLabel.Text = '';
                    app.ModelName = 0; % for skipping replacing constants when closing panel

                    prog_stat = uiprogressdlg(app.simPanel,'Title','Updating panel',...
                                'Message','Loading data...','Indeterminate','on');
                    uiopen('RootSWComposition.sldd',1); %Opening data dictionary
                    app.dataMatFile = matfile('RootSWComposition_IntegrationData.mat','Writable',true);
                    app.loggedRuns = app.dataMatFile.loggedRuns;
                    %run(fullfile(app.rootPath,sprintf('%s_InputConsts.m',app.OnlyModelName)));
                    %app.constNames = fieldnames(InpConsts);
                    if isempty(app.loggedRuns)
                        app.LoggedRunsDropDown.Enable = 'off';
                        app.LoggedRunsDropDownLabel.Enable = 'off';
                    else
                        app.LoggedRunsDropDown.Enable = 'on';
                        app.LoggedRunsDropDownLabel.Enable = 'on';
                        app.LoggedRunsDropDown.Items = horzcat({'Select result log'},{app.loggedRuns.Name});
                    end
                    close(prog_stat);
                end
            end
            app.StopButton.Enable = 'off';
            app.SimTimeLabel.Enable = 'off';
        end

        %updateInputTable
        function updateInputTable(app)
            if bdIsLoaded(app.OnlyModelName)
            else
                load_system(sprintf('%s.slx',app.OnlyModelName));
            end
			
			app.DataDictObj = Simulink.data.dictionary.open(get_param(app.OnlyModelName,'DataDictionary'));
			app.DataSectObj = getSection(app.DataDictObj,'Design Data');

			app.ConstDictObj = Simulink.data.dictionary.open(app.slddName);
    		app.ConstDictSec = getSection(app.ConstDictObj,'Design Data');

			for inpNo = 1 : length(app.constNames)
				app.inTableData{inpNo,1} = app.constNames{inpNo};
				% entryFound = find(app.ConstDictSec,'Name',app.constNames{inpNo});
		        % entryParam = getValue(entryFound);
				% OutDataType = entryParam.DataType;
				% app.inTableData{inpNo,2} = entryParam.Value;

				% if isempty(regexpi(OutDataType,'Enum: .*'))
		        %     entryObj = getEntry(app.DataSectObj,OutDataType);
		        %     aliasValue = getValue(entryObj);
		        %     OutDataType = aliasValue.BaseType;
		        % end
		        % app.inTableData{inpNo,3} = OutDataType;
                app.inTableData{inpNo,2} = app.allInputValues(inpNo).Value;
                app.inTableData{inpNo,3} = app.allInputValues(inpNo).BaseDataType;

                if mod(inpNo,2)
                    app.inBackground(inpNo,:) = [1 1 1];
                else
                    app.inBackground(inpNo,:) = [.94 .94 .94];
                end
			end
			app.InputTable.Data = app.inTableData;
			app.InputTable.BackgroundColor = app.inBackground;
        end

        %createOutputTable
        function createOutputTable(app)
            % set_param(app.OnlyModelName,'SimulationCommand','update');
        	% app.refSystems = find_system(app.OnlyModelName,'SearchDepth',1,'BlockType','ModelReference');
            % dioOutputs = find_system('RootSWComposition/OutProc_Stub_Functions','SearchDepth',1,'BlockType','SubSystem');
            % dioOutputs = dioOutputs(2:end);
            % app.refSystems = vertcat(app.refSystems,dioOutputs);
        	% tableIndex = 0;
        	% for refNo = 1:length(app.refSystems)
        	% 	allOutputs = get_param(app.refSystems{refNo},'OutputSignalNames');
        	% 	%runTimeObj = get_param(app.refSystems{refNo},'RunTimeObject');
        	% 	for outNo = 1:length(allOutputs)
        	% 		tableIndex = tableIndex + 1;
        	% 		app.outTableData{tableIndex,1} = allOutputs{outNo};
        	% 		app.outTableData{tableIndex,2} = 0;
        	% 		%app.outTableData{tableIndex,3} = 0;
            %         if mod(tableIndex,2)
            %             app.outBackground(tableIndex,:) = [1 1 1];
            %         else
            %             app.outBackground(tableIndex,:) = [.94 .94 .94];
            %         end
        	% 	end
            % end

            app.refSystems = find_system(app.OnlyModelName,'SearchDepth',1,'BlockType','ModelReference');
            dioOutputs = find_system('RootSWComposition/OutProc_Stub_Functions','SearchDepth',1,'BlockType','SubSystem');
            dioOutputs = dioOutputs(2:end);
            app.refSystems = vertcat(app.refSystems,dioOutputs);

            for outNo = 1 : length(app.allOutputValues)
				app.outTableData{outNo,1} = app.allOutputValues(outNo).Name;
                app.outTableData{outNo,2} = app.allOutputValues(outNo).Value;

                if mod(outNo,2)
                    app.outBackground(outNo,:) = [1 1 1];
                else
                    app.outBackground(outNo,:) = [.94 .94 .94];
                end
			end
        	app.OutputTable.Data = app.outTableData(1:round(length(app.outTableData)/2),:);
        	app.OutputTable_2.Data = app.outTableData(round(length(app.outTableData)/2)+1:end,:);
            app.OutputTable.BackgroundColor = app.outBackground(1:round(length(app.outBackground)/2),:,:);
            app.OutputTable_2.BackgroundColor = app.outBackground(round(length(app.outBackground)/2)+1:end,:,:);

            app.prevSwS2Cmd = 0;
            app.prevPlgLckCmd = 0;
        end

        %updateOutputTable
        function updateOutputTable(app)
        	app.SimTimeLabel.Text = sprintf('Sim Time: %.2f',get_param(app.OnlyModelName,'SimulationTime'));
            drawnow
        	%app.outTableData = app.OutputTable.Data;
        	tableIndex = 0;
			app.inTableData = app.InputTable.Data;
        	for refNo = 1:length(app.refSystems)
        		allOutputs = get_param(app.refSystems{refNo},'OutputSignalNames');
        		runTimeObj = get_param(app.refSystems{refNo},'RunTimeObject');
        		for outNo = 1:length(allOutputs)
        			tableIndex = tableIndex + 1;
        			if isenum(runTimeObj.OutputPort(outNo).Data)
        				app.outTableData{tableIndex,2} = char(runTimeObj.OutputPort(outNo).Data);
        			else
        				app.outTableData{tableIndex,2} = runTimeObj.OutputPort(outNo).Data;
        			end

                    % Updating Switch S2 voltage based on command
                    if isequal(allOutputs(outNo), {'OutProc_Arg_SwtS2CtrlCmd_write'})
                        if app.prevSwS2Cmd ~= app.outTableData{tableIndex,2}
                            findIndex = find(contains(string({app.inTableData{:,1}}),'InProc_Arg_CPVtgPhy_read'));
                            app.inTableData{findIndex,2} = get_param(sprintf('%s/InProc_Arg_CPVtgPhy_read_Constant',app.OnlyModelName),'Value');
                            % if app.outTableData{tableIndex,2} == 0
                            %     app.inTableData{findIndex,2} = 9;
                            %     set_param(sprintf('%s/InProc_Arg_CPVtgPhy_read_Constant',app.OnlyModelName),'Value','9');
                            % else
                            %     app.inTableData{findIndex,2} = 6;
                            %     set_param(sprintf('%s/InProc_Arg_CPVtgPhy_read_Constant',app.OnlyModelName),'Value','6');
                            % end    
                        end 
                        app.prevSwS2Cmd = app.outTableData{tableIndex,2};
                    end
                    %

                    % Updating Plug lock sensor voltage based on Lock control 1
                    if isequal(allOutputs(outNo), {'OutProc_Arg_DIOPlgLkCtrl1_write'})
                        if app.prevPlgLckCmd ~= app.outTableData{tableIndex,2}
                            findIndex = find(contains(string({app.inTableData{:,1}}),'InProc_Arg_PlgLkPsSnVtgPhy_read'));
                            app.inTableData{findIndex,2} = get_param(sprintf('%s/InProc_Arg_PlgLkPsSnVtgPhy_read_Constant',app.OnlyModelName),'Value');
                            % if app.outTableData{tableIndex,2} == 0
                            %     app.inTableData{findIndex,2} = 0;
                            %     set_param(sprintf('%s/InProc_Arg_PlgLkPsSnVtgPhy_read_Constant',app.OnlyModelName),'Value','0');
                            % else
                            %     app.inTableData{findIndex,2} = 7;
                            %     set_param(sprintf('%s/InProc_Arg_PlgLkPsSnVtgPhy_read_Constant',app.OnlyModelName),'Value','7');
                            % end    
                        end 
                        app.prevPlgLckCmd = app.outTableData{tableIndex,2};
                    end
                    %
        		end
            end

            app.InputTable.Data = app.inTableData;
        	app.OutputTable.Data = app.outTableData(1:round(length(app.outTableData)/2),:);
        	app.OutputTable_2.Data = app.outTableData(round(length(app.outTableData)/2)+1:end,:);
            app.SimTimeLabel.Text = sprintf('Sim Time: %.2f',get_param(app.OnlyModelName,'SimulationTime'));
        	drawnow
        end

        % Value changing function: SearchField
        function SearchFieldValueChanging(app, event)
            changingValue = event.Value;
            inHits = find(contains(string({app.inTableData{:,1}}),changingValue,'IgnoreCase',true));
            outHits = find(contains(string({app.outTableData{:,1}}),changingValue,'IgnoreCase',true));
            newInBack = app.inBackground;
            newOutBack = app.outBackground;
            
            if length({app.inTableData{:,1}}) ~= length(inHits)
                for inNo = 1:length(inHits)
                    newInBack(inHits(inNo),:) = [1 1 0];
                end
            end
            app.InputTable.BackgroundColor = newInBack;
            
            if length({app.outTableData{:,1}}) ~= length(outHits)
                for outNo = 1:length(outHits)
                    newOutBack(outHits(outNo),:) = [1 1 0];
                end
            end

            if ((length(inHits) == 0) && (length(outHits) == 0)) ||...
            	(length({app.inTableData{:,1}}) == length(inHits) && length({app.outTableData{:,1}}) == length(outHits))
            	app.MatchLabel.Visible = 'off';
	            app.MatchLabel.Text = 'Matches found: 0';
            else
            	app.MatchLabel.Visible = 'on';
	            app.MatchLabel.Text = sprintf('Matches found:- in:%d out:%d',length(inHits),length(outHits));
            end
            app.OutputTable.BackgroundColor = newOutBack(1:round(length(newOutBack)/2),:,:);
            app.OutputTable_2.BackgroundColor = newOutBack(round(length(newOutBack)/2)+1:end,:,:);
        end
        
        % Value changed function: SearchField
        function SearchFieldValueChanged(app, event)
            if isequal(app.SearchField.Value,'')
                app.OutputTable.BackgroundColor = app.outBackground;
                app.InputTable.BackgroundColor = app.inBackground;
                app.MatchLabel.Visible = 'off';
	            app.MatchLabel.Text = 'Matches found: 0';
            end
        end
        
        % Cell edit callback: InputTable
        function InputTableCellEdit(app, event)
			indices = event.Indices;
			newData = event.NewData;
			% entryFound = find(app.ConstDictSec,'Name',app.constNames{indices(1)});
			% entryParam = getValue(entryFound);
			% entryParam.Value = newData;
			% setValue(entryFound,entryParam);
            % saveChanges(app.ConstDictObj);
            dataType = app.allInputValues(indices(1)).BaseDataType;
            if isempty(regexpi(dataType,'Enum: .*'))
                set_param(sprintf('%s/%s_Constant',app.OnlyModelName,app.constNames{indices(1)}),'Value',num2str(newData));
            else
                entryObj = getEntry(app.DataSectObj,dataType(7:end));
                aliasValue = getValue(entryObj);
                enumValues = aliasValue.Enumerals;
                findIndex = find(contains(string({enumValues.Value}),newData));
                if isempty(findIndex)
                    uialert(app.simPanel,sprintf('%s does not contain ''%s'' value',dataType(7:end),num2str(newData)),'Error');
                else
                    set_param(sprintf('%s/%s_Constant',app.OnlyModelName,app.constNames{indices(1)}),'Value',sprintf('%s.%s',dataType(7:end),enumValues(findIndex).Name));
                    app.InputTable.Data(indices(1),2) = {enumValues(findIndex).Name};
                end
            end
            updatePreset(app);
            app.inTableData = app.InputTable.Data;
        end

        % Value changed function: StartButton
        function StartButtonValueChanged(app, event)
            if app.StartButton.Value
                if isequal(get_param(app.OnlyModelName,'SimulationStatus'),'stopped')
            		app.Status.Text = 'Starting simulation';
                    drawnow
                    %set_param(app.OnlyModelName,'SimulationCommand','update');
            		set_param(app.OnlyModelName,'SimulationCommand','start');
            		app.Status.Text = 'Simulating...';
            		drawnow
            	else
            		app.Status.Text = 'Resuming simulation';
            		drawnow
            		set_param(app.OnlyModelName,'SimulationCommand','continue');
            		app.Status.Text = 'Simulating...';
            		drawnow
            	end
            	app.StartButton.Text = 'Pause';
            	app.StartButton.BackgroundColor = [1 1 0];
            	app.StopButton.Enable = 'on';
                app.SimTimeLabel.Enable = 'on';
                app.ConfigurationDropDown.Enable = 'off';
                app.PhaseButton.Enable = 'off';
            	start(app.updateTimer);
            else
            	%app.StopButton.Enable = 'off';
            	set_param(app.OnlyModelName,'SimulationCommand','pause');
				app.StartButton.Text = 'Resume';
            	app.StartButton.BackgroundColor = [0 0.9 0];
            	app.Status.Text = 'Simulation paused';
            	drawnow
            	stop(app.updateTimer);
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
        	app.Status.Text = 'Stopping simulation';
            drawnow

            stop(app.updateTimer);
        	app.StartButton.Value = 0;
        	app.StartButton.Text = 'Start';
            app.StartButton.BackgroundColor = [0 0.9 0];
            app.StopButton.Enable = 'off';
            app.SimTimeLabel.Enable = 'off';
            app.ConfigurationDropDown.Enable = 'on';
            app.PhaseButton.Enable = 'on';
            app.SimTimeLabel.Text = 'Sim Time: 0000.00';
            app.Status.Text = 'Start simulation and go to town on it';
            set_param(app.OnlyModelName,'SimulationCommand','stop');

            runName = inputdlg('Log name:','Save log',[1 35]);
            if ~isempty(runName)
                prog_stat = uiprogressdlg(app.simPanel,'Title','Saving Log',...
                                'Message',sprintf('Saving log as ''%s''...',runName{1}),'Indeterminate','on');
                setNo = length(app.loggedRuns);
                app.loggedRuns(setNo+1).Name = runName{1};
                app.loggedRuns(setNo+1).DataLog = evalin('base', 'logsout');

                app.LoggedRunsDropDown.Items = horzcat({'Select result log'},{app.loggedRuns.Name});
                app.LoggedRunsDropDown.Enable = 'on';
                app.LoggedRunsDropDownLabel.Enable = 'on';
                app.dataMatFile.loggedRuns = app.loggedRuns;
                close(prog_stat);
            end
        end
        
        % Value changed function: Button_2 :- Wait standby
        function Button_2ValueChanged(app, event)
            prog_stat = uiprogressdlg(app.simPanel,'Title','Updating Inputs',...
                                'Message','Applying ''Wait Standby'' preset...','Indeterminate','on');
            set_param(app.OnlyModelName,'SimulationCommand','pause');

            updateSignalValue(app,'VCAN_EVReady_R_VCANEVR',0);

            updateSignalValue(app,'VCAN_BatStatOfChg_R_VCANSOC',100);
            
            updateSignalValue(app,'VCAN_MainWkUp_R_VCANVCUMWU',1);

            % findIndex = find(contains(string({app.inTableData{:,1}}),'InProc_APCRCDWkUp_P_APCRCDWU'));
            % set_param(sprintf('%s/InProc_APCRCDWkUp_P_APCRCDWU_Constant',app.OnlyModelName),'Value','1');
            % app.inTableData{findIndex,2} = 1;

            updateSignalValue(app,'InProc_Arg_CPVtgPhy_read',9);

            updateSignalValue(app,'VCAN_FlpSt_R_VCANFS',1);
            
            if isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851E') || isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851')
                updateSignalValue(app,'V2G_ComStat_R_CS','ComStat_In_CableCheckLoop');
                updateSignalValue(app,'V2G_DLINKSt_R_DLINKSt','DLINKSt_NoLink');
            end
            app.InputTable.Data = app.inTableData;
            set_param(app.OnlyModelName,'SimulationCommand','continue');   
            close(prog_stat);
        end

        % Value changed function: Button_3 :- Prepare charge
        function Button_3ValueChanged(app, event)
            %value = app.Button_3.Value;
            prog_stat = uiprogressdlg(app.simPanel,'Title','Updating Inputs',...
                                'Message','Applying ''Prepare Charge'' preset...','Indeterminate','on');
            set_param(app.OnlyModelName,'SimulationCommand','pause');

            updateSignalValue(app,'VCAN_EVReady_R_VCANEVR',1);

            updateSignalValue(app,'VCAN_BatStatOfChg_R_VCANSOC',50);
            
            updateSignalValue(app,'VCAN_MainWkUp_R_VCANVCUMWU',1);

            % findIndex = find(contains(string({app.inTableData{:,1}}),'InProc_APCRCDWkUp_P_APCRCDWU'));
            % set_param(sprintf('%s/InProc_APCRCDWkUp_P_APCRCDWU_Constant',app.OnlyModelName),'Value','1');
            % app.inTableData{findIndex,2} = 1;

            updateSignalValue(app,'InProc_Arg_CPVtgPhy_read',9);

            updateSignalValue(app,'VCAN_FlpSt_R_VCANFS',1);

            updateSignalValue(app,'InProc_Arg_PrxmtyVtgPhy_read',1.42);

            updateSignalValue(app,'InProc_Arg_CPPWMFreq_read',1000);

            updateSignalValue(app,'InProc_Arg_CPPWMDtyCcl_read',50);
            
            updateSignalValue(app,'InProc_Arg_PlgUnlkBtnSt_read',0);

            obcAdd = {'00','01','10','11'};
            for obcNo = 1:4                
                for phNo = 1:3
                    %update OBC Vin
                    updateSignalValue(app,sprintf('ICAN_OBCVinPh%d_R_ICANOBC%sVi%d',phNo,obcAdd{obcNo},phNo),2000);

                    %update OBC Iin
                    updateSignalValue(app,sprintf('ICAN_OBCIinPh%d_R_ICANOBC%sIi%d',phNo,obcAdd{obcNo},phNo),0);
                end
                %update OBC status
                updateSignalValue(app,sprintf('ICAN_OBCSt_R_ICANOBC%sS',obcAdd{obcNo}),0);

                %update OBC Vout
                updateSignalValue(app,sprintf('ICAN_OBCVout_R_ICANOBC%sVo',obcAdd{obcNo}),2000);
            end

            if isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851E') || isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851')
                updateSignalValue(app,'V2G_ComStat_R_CS','ComStat_In_PrechargeLoop');
                updateSignalValue(app,'V2G_DLINKSt_R_DLINKSt','DLINKSt_LinkEstablished');
                updateSignalValue(app,'V2G_EVSEMxI_R_EVSEMxI',0);
            end

            app.InputTable.Data = app.inTableData;
            set_param(app.OnlyModelName,'SimulationCommand','continue');
            close(prog_stat);
        end

        % Value changed function: Button_4 :- Charge
        function Button_4ValueChanged(app, event)
            %value = app.Button_4.Value;
            prog_stat = uiprogressdlg(app.simPanel,'Title','Updating Inputs',...
                                'Message','Applying ''Charge'' preset...','Indeterminate','on');
            set_param(app.OnlyModelName,'SimulationCommand','pause');

            updateSignalValue(app,'VCAN_EVReady_R_VCANEVR',1);

            updateSignalValue(app,'VCAN_BatStatOfChg_R_VCANSOC',50);
            
            updateSignalValue(app,'VCAN_MainWkUp_R_VCANVCUMWU',1);

            % findIndex = find(contains(string({app.inTableData{:,1}}),'InProc_APCRCDWkUp_P_APCRCDWU'));
            % set_param(sprintf('%s/InProc_APCRCDWkUp_P_APCRCDWU_Constant',app.OnlyModelName),'Value','1');
            % app.inTableData{findIndex,2} = 1;

            updateSignalValue(app,'InProc_Arg_CPVtgPhy_read',6);

            updateSignalValue(app,'VCAN_FlpSt_R_VCANFS',1);

            updateSignalValue(app,'InProc_Arg_PrxmtyVtgPhy_read',1.42);

            updateSignalValue(app,'InProc_Arg_CPPWMFreq_read',1000);

            updateSignalValue(app,'InProc_Arg_CPPWMDtyCcl_read',50);
            
            updateSignalValue(app,'InProc_Arg_PlgUnlkBtnSt_read',0);

            updateSignalValue(app,'VCAN_WOBCSetPtI_R_VCANWOBCSPI',200);

            updateSignalValue(app,'VCAN_WOBCSetPtV_R_VCANWOBCSPV',2000);

            obcAdd = {'00','01','10','11'};
            for obcNo = 1:4
                for phNo = 1:3
                    %update OBC Vin
                    updateSignalValue(app,sprintf('ICAN_OBCVinPh%d_R_ICANOBC%sVi%d',phNo,obcAdd{obcNo},phNo),2000);

                    %update OBC Iin
                    updateSignalValue(app,sprintf('ICAN_OBCIinPh%d_R_ICANOBC%sIi%d',phNo,obcAdd{obcNo},phNo),30); %Change it to 300 ->50% DC=> 30A MLC
                end
                
                %update OBC status
                updateSignalValue(app,sprintf('ICAN_OBCSt_R_ICANOBC%sS',obcAdd{obcNo}),1);

                %update OBC Vout
                updateSignalValue(app,sprintf('ICAN_OBCVout_R_ICANOBC%sVo',obcAdd{obcNo}),2000);
            end

            if isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851E') || isequal(app.ConfigurationDropDown.Value,'ISO15118ANDIEC61851')
                updateSignalValue(app,'V2G_ComStat_R_CS','ComStat_In_ChargeLoop');
                updateSignalValue(app,'V2G_DLINKSt_R_DLINKSt','DLINKSt_LinkEstablished');
                updateSignalValue(app,'V2G_EVSEMxI_R_EVSEMxI',30);
            end

            app.InputTable.Data = app.inTableData;
            set_param(app.OnlyModelName,'SimulationCommand','continue');
            close(prog_stat);
        end

        % Value changed function: Button_5
        function Button_5ValueChanged(app, event)
            value = app.Button_5.Value;
            
        end

        % Value changed function: Button_6
        function Button_6ValueChanged(app, event)
            value = app.Button_6.Value;
            
        end

        % Value changed function: Button_7
        function Button_7ValueChanged(app, event)
            value = app.Button_7.Value;
            
        end

        % Value changed function: Button_8
        function Button_8ValueChanged(app, event)
            value = app.Button_8.Value;
            
        end

        % Value changed function: Button_9
        function Button_9ValueChanged(app, event)
            value = app.Button_9.Value;
            
        end
        
        % Value changed function: ResetButton
        function ResetButtonValueChanged(app, event)
            for inpNo = 1:length(app.inTableData)
                dataType = app.allInputValues(inpNo).BaseDataType;
                if isempty(regexpi(dataType,'Enum: .*'))
                    app.inTableData{inpNo,2} = 0;
                    set_param(sprintf('%s/%s_Constant',app.OnlyModelName,app.constNames{inpNo}),'Value','0');
                else
                    entryObj = getEntry(app.DataSectObj,dataType(7:end));
                    aliasValue = getValue(entryObj);
                    set_param(sprintf('%s/%s_Constant',app.OnlyModelName,app.constNames{inpNo}),'Value',sprintf('%s.%s',dataType(7:end),aliasValue.DefaultValue));
                    app.inTableData{inpNo,2} = aliasValue.DefaultValue;
                    if app.nvmFlg == 1 && isequal(app.constNames{inpNo},'IM_EVSEComProto_R_EVSEComProto_NvData')
                        app.ConfigurationDropDown.Value = aliasValue.DefaultValue;
                    end
                end
            end
            % if app.nvmFlg == 0
            %     app.PhaseButton.Text = 'SinglePhase';
            % else
            %     app.PhaseButton.Text = 'SinglePhaseE';
            % end
            app.PhaseButton.Text = 'SinglePhase';
            app.PhaseButton.Value = 0;
            app.InputTable.Data = app.inTableData;
        end

        function updatePreset(app)

        end

        % Value changed function: PhaseButton
        function PhaseButtonValueChanged(app, event)
            prog_stat = uiprogressdlg(app.simPanel,'Title','Updating Configuration',...
                                'Message','Updating charging phase...','Indeterminate','on');
            if app.PhaseButton.Value == 0
                % if app.nvmFlg == 0
                %     app.PhaseButton.Text = 'SinglePhase';
                % else
                %     app.PhaseButton.Text = 'SinglePhaseE';
                % end
                app.PhaseButton.Text = 'SinglePhase';
            else
                % if app.nvmFlg == 0
                %     app.PhaseButton.Text = 'ThreePhase';
                % else
                %     app.PhaseButton.Text = 'ThreePhaseE';
                % end
                app.PhaseButton.Text = 'ThreePhase';
            end

            if app.nvmFlg == 0
                confEntry = find(app.DataSectObj,'Name','GC_SChgPhConfg_R_SCPC');
                confParam = getValue(confEntry);
                confParam.Value = eval(sprintf('ADTS_GCSChgPhConfg.%s',app.PhaseButton.Text));
                setValue(confEntry,confParam);
                saveChanges(app.DataDictObj);
            else
                updateSignalValue(app,'IM_SChgPhConfg_R_SCPC_NvData',app.PhaseButton.Text);
            end
            drawnow
            close(prog_stat);
        end

        % Value changed function: ConfigurationDropDown
        function ConfigurationDropDownValueChanged(app, event)
            %value = app.ConfigurationDropDown.Value;
            prog_stat = uiprogressdlg(app.simPanel,'Title','Updating Configuration',...
                                'Message',sprintf('Updating EVSE ComProto to %s...',app.ConfigurationDropDown.Value),'Indeterminate','on');
            if app.nvmFlg == 0
                confEntry = find(app.DataSectObj,'Name','GC_EVSEComProto_R_EVSECP');
                confParam = getValue(confEntry);
                confParam.Value = eval(sprintf('ADTS_EVSEComProto.%s',app.ConfigurationDropDown.Value));
                setValue(confEntry,confParam);
                saveChanges(app.DataDictObj);  
            else
                updateSignalValue(app,'IM_EVSEComProto_R_EVSEComProto_NvData',app.ConfigurationDropDown.Value);
            end
            save_system(app.OnlyModelName);
            close(prog_stat);
        end

        % Button pushed function: SaveInputsButton
        function SaveInputsButtonPushed(app, event)
            tempInports = app.allInputValues;
            inputName = inputdlg('Input set Name:','Record input set',[1 35]);
            if ~isempty(inputName)
                prog_stat = uiprogressdlg(app.simPanel,'Title','Saving inputs',...
                                'Message',sprintf('Saving current Input set as %s...',inputName{1}),'Indeterminate','on');
                for inpNo = 1:length(app.allInputValues)
                    tempInports(inpNo).Value = app.inTableData{inpNo,2};
                end
                setNo = length(app.loggedInputs);
                app.loggedInputs(setNo+1).Name = inputName{1};
                app.loggedInputs(setNo+1).InputSet = tempInports;

                app.RecordedInputsDropDown.Items = horzcat({'Select input set'},{app.loggedInputs.Name});
                app.RecordedInputsDropDownLabel.Enable = 'on';
                app.RecordedInputsDropDown.Enable = 'on';
                app.dataMatFile.loggedInputs = app.loggedInputs;
                close(prog_stat);
            end
        end

        % Value changed function: RecordedInputsDropDown
        function RecordedInputsDropDownValueChanged(app, event)
            if ~isequal(app.RecordedInputsDropDown.Value,'Select input set')
                selection = uiconfirm(app.simPanel,sprintf('Load input set %s?',app.RecordedInputsDropDown.Value),'Confirm load inputs',...
                                        'Options',{'OK','Delete','Cancel'},'DefaultOption',1,'CancelOption',3);
                if isequal(selection,'OK') 
                    findIndex = find(contains(string({app.loggedInputs.Name}),app.RecordedInputsDropDown.Value));
                    prog_stat = uiprogressdlg(app.simPanel,'Title','Loading inputs',...
                                    'Message',sprintf('Loading %s input set...',app.loggedInputs(findIndex).Name),'Indeterminate','on');
                    newInputSet = app.loggedInputs(findIndex).InputSet;
                    for inpNo = 1 : length(app.constNames)
                        app.inTableData{inpNo,2} = newInputSet(inpNo).Value;
                        %set_param(sprintf('%s/%s_Constant',app.OnlyModelName,newInputSet(inpNo).Name),'Value',num2str(newInputSet(inpNo).Value));
                        dataType = newInputSet(inpNo).BaseDataType;
                        if isempty(regexpi(dataType,'Enum: .*'))
                            set_param(sprintf('%s/%s_Constant',app.OnlyModelName,newInputSet(inpNo).Name),'Value',num2str(newInputSet(inpNo).Value));
                        else
                            set_param(sprintf('%s/%s_Constant',app.OnlyModelName,newInputSet(inpNo).Name),'Value',sprintf('%s.%s',dataType(7:end),newInputSet(inpNo).Value));
                        end
                    end
                    app.InputTable.Data = app.inTableData;
                    close(prog_stat);
                elseif isequal(selection,'Delete')
                    prog_stat = uiprogressdlg(app.simPanel,'Title','Deleting input set',...
                                'Message',sprintf('Deleting ''%s'' input set...',app.RecordedInputsDropDown.Value),'Indeterminate','on');
                    findIndex = find(contains(string({app.loggedInputs.Name}),app.RecordedInputsDropDown.Value));
                    if findIndex == 1
                        app.loggedInputs = app.loggedInputs(2:end);
                    else
                        app.loggedInputs = horzcat(app.loggedInputs(1:findIndex-1),app.loggedInputs(findIndex+1:end));
                    end
                    if isempty(app.loggedInputs)
                        app.RecordedInputsDropDownLabel.Enable = 'off';
                        app.RecordedInputsDropDown.Enable = 'off';
                    else
                        app.RecordedInputsDropDownLabel.Enable = 'on';
                        app.RecordedInputsDropDown.Enable = 'on';
                        app.RecordedInputsDropDown.Items = horzcat({'Select input set'},{app.loggedInputs.Name});
                    end
                    app.dataMatFile.loggedInputs = app.loggedInputs;
                    close(prog_stat);
                end
                app.RecordedInputsDropDown.Value = 'Select input set';
            end
        end

        % Value changed function: LoggedRunsDropDown
        function LoggedRunsDropDownValueChanged(app, event)
            if ~isequal(app.LoggedRunsDropDown.Value,'Select result log')
                selection = uiconfirm(app.simPanel,sprintf('Display logged run %s?',app.LoggedRunsDropDown.Value),'Confirm display log',...
                                        'Options',{'OK','Delete','Cancel'},'DefaultOption',1,'CancelOption',3);
                if isequal(selection,'OK')
                    findIndex = find(contains(string({app.loggedRuns.Name}),app.LoggedRunsDropDown.Value));
                    runObj = Simulink.sdi.Run.create;
                    runObj.Name = app.loggedRuns(findIndex).Name;
                    prog_stat = uiprogressdlg(app.simPanel,'Title','Loading logged run',...
                                    'Message',sprintf('Loading logged signals of %s...',app.loggedRuns(findIndex).Name),'Indeterminate','on');
                    %disp(plotData(caseNo).TestCaseID);
                    for sigNo = 1:numElements(app.loggedRuns(findIndex).DataLog)
                        %adding signals to (Input, Results, Expected and Actual outputs) to runs
                        runObj.add('vars',app.loggedRuns(findIndex).DataLog{sigNo}.Values);
                        % allSig = allSig+1;
                        % waitbar(allSig/(length(plotData)*numElements(plotData(caseNo).DataLog)),...
                        %     progBar,regexprep(sprintf('Inporting %s',plotData(caseNo).TestCaseID),'_','\\_'));
                    end
                    Simulink.sdi.view; %opening simulink data inspector
                    close(prog_stat);
                elseif isequal(selection,'Delete')
                    prog_stat = uiprogressdlg(app.simPanel,'Title','Deleting Log',...
                                'Message',sprintf('Deleting ''%s'' log...',app.LoggedRunsDropDown.Value),'Indeterminate','on');
                    findIndex = find(contains(string({app.loggedRuns.Name}),app.LoggedRunsDropDown.Value));
                    if findIndex == 1
                        app.loggedRuns = app.loggedRuns(2:end);
                    else
                        app.loggedRuns = horzcat(app.loggedRuns(1:findIndex-1),app.loggedRuns(findIndex+1:end));
                    end
                    if isempty(app.loggedRuns)
                        app.LoggedRunsDropDown.Enable = 'off';
                        app.LoggedRunsDropDownLabel.Enable = 'off';
                    else
                        app.LoggedRunsDropDown.Enable = 'on';
                        app.LoggedRunsDropDownLabel.Enable = 'on';
                        app.RecordedInputsDropDown.Items = horzcat({'Select result log'},{app.loggedRuns.Name});
                    end
                    app.dataMatFile.loggedRuns = app.loggedRuns;
                    close(prog_stat);
                end
                app.LoggedRunsDropDown.Value = 'Select result log';
            end
        end
        
        function updateSignalValue(app,signalName,signalValue)
            findIndex = find(contains(string({app.inTableData{:,1}}),signalName));
            dataType = app.allInputValues(findIndex).BaseDataType;
            if isempty(regexpi(dataType,'Enum: .*'))
                set_param(sprintf('%s/%s_Constant',app.OnlyModelName,signalName),'Value',num2str(signalValue));
                app.inTableData{findIndex,2} = signalValue;
            else
                set_param(sprintf('%s/%s_Constant',app.OnlyModelName,signalName),'Value',sprintf('%s.%s',dataType(7:end),signalValue));
                app.InputTable.Data(findIndex,2) = {signalValue};
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create simPanel
            app.simPanel = uifigure;
            app.simPanel.Position = [100 100 1207 653];
            app.simPanel.Name = 'ASW Integrated Environment (v1.4)';
            app.simPanel.CloseRequestFcn = createCallbackFcn(app, @simPanelCloseRequest, true);
            app.simPanel.Scrollable = 'on';

            % Create OpenButton
            app.OpenButton = uibutton(app.simPanel, 'push');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenButton.Position = [414 611 80 22];
            app.OpenButton.Text = 'Open';

            % Create ModelNameEditFieldLabel
            app.ModelNameEditFieldLabel = uilabel(app.simPanel);
            app.ModelNameEditFieldLabel.HorizontalAlignment = 'right';
            app.ModelNameEditFieldLabel.Position = [26 611 77 22];
            app.ModelNameEditFieldLabel.Text = 'Model Name:';

            % Create ModelNameEditField
            app.ModelNameEditField = uieditfield(app.simPanel, 'text');
            app.ModelNameEditField.Editable = 'off';
            app.ModelNameEditField.Position = [117 611 285 22];

            % Create Status
            app.Status = uilabel(app.simPanel);
            app.Status.HorizontalAlignment = 'center';
            app.Status.FontWeight = 'bold';
            app.Status.FontAngle = 'italic';
            app.Status.Position = [281 576 625 22];
            app.Status.Text = 'Select ''Root Software Composition'' model';

            % Create StartButton
            app.StartButton = uibutton(app.simPanel, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonValueChanged, true);
            app.StartButton.Enable = 'off';
            app.StartButton.Text = 'Start';
            app.StartButton.BackgroundColor = [0 0.902 0];
            app.StartButton.Position = [544 611 70 22];

            % Create StopButton
            app.StopButton = uibutton(app.simPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [1 0 0];
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Enable = 'off';
            app.StopButton.Position = [628 611 70 22];
            app.StopButton.Text = 'Stop';

            % Create SimTimeLabel
            app.SimTimeLabel = uilabel(app.simPanel);
            app.SimTimeLabel.Enable = 'off';
            app.SimTimeLabel.Position = [717 611 140 22];
            app.SimTimeLabel.Text = 'Sim Time: 000000';

            % Create InputPresetsPanel
            app.InputPresetsPanel = uipanel(app.simPanel);
            app.InputPresetsPanel.AutoResizeChildren = 'off';
            app.InputPresetsPanel.BorderType = 'none';
            app.InputPresetsPanel.Title = 'Input Presets';
            app.InputPresetsPanel.Scrollable = 'on';
            app.InputPresetsPanel.Position = [28 478 1153 63];

            % Create ResetButton
            app.ResetButton = uibutton(app.InputPresetsPanel, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonValueChanged, true);
            app.ResetButton.Enable = 'off';
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Position = [21 13 100 22];

            % Create InputTable
            app.InputTable = uitable(app.simPanel);
            app.InputTable.ColumnName = {'Input Name'; 'Value'; 'DataType'};
            app.InputTable.ColumnWidth = {'auto', 75, 75};
            app.InputTable.RowName = {};
            app.InputTable.ColumnEditable = [false true false];
            app.InputTable.CellEditCallback = createCallbackFcn(app, @InputTableCellEdit, true);
            app.InputTable.Position = [28 22 438 422];

            % Create SearchField
            app.SearchField = uieditfield(app.simPanel, 'text');
            app.SearchField.ValueChangedFcn = createCallbackFcn(app, @SearchFieldValueChanged, true);
            app.SearchField.ValueChangingFcn = createCallbackFcn(app, @SearchFieldValueChanging, true);
            app.SearchField.Tooltip = {'Search Inputs or Outputs'};
            app.SearchField.Position = [28 453 270 22];

            % Create MatchLabel
            app.MatchLabel = uilabel(app.simPanel);
            app.MatchLabel.Visible = 'off';
            app.MatchLabel.Position = [315 451 260 22];
            app.MatchLabel.Text = 'Matches found: 0';

            % Create OutputTable
            app.OutputTable = uitable(app.simPanel);
            app.OutputTable.ColumnName = {'Output Name'; 'Value'};
            app.OutputTable.ColumnWidth = {'auto'};
            app.OutputTable.RowName = {};
            app.OutputTable.ColumnEditable = false;
            app.OutputTable.Position = [478 22 346 422];

            % Create OutputTable_2
            app.OutputTable_2 = uitable(app.simPanel);
            app.OutputTable_2.ColumnName = {'Output Name'; 'Value'};
            app.OutputTable_2.ColumnWidth = {'auto'};
            app.OutputTable_2.RowName = {};
            app.OutputTable_2.ColumnEditable = false;
            app.OutputTable_2.Position = [835 22 346 422];
            
            % Create Button_2
            app.Button_2 = uibutton(app.InputPresetsPanel, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2ValueChanged, true);
            app.Button_2.Enable = 'off';
            app.Button_2.Visible = 'on';
            app.Button_2.Text = 'wait Standby';
            app.Button_2.Position = [138 13 100 22];

            % Create Button_3
            app.Button_3 = uibutton(app.InputPresetsPanel, 'push');
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @Button_3ValueChanged, true);
            app.Button_3.Enable = 'off';
            app.Button_3.Visible = 'on';
            app.Button_3.Text = 'prep Charge';
            app.Button_3.Position = [255 13 100 22];

            % Create Button_4
            app.Button_4 = uibutton(app.InputPresetsPanel, 'push');
            app.Button_4.ButtonPushedFcn = createCallbackFcn(app, @Button_4ValueChanged, true);
            app.Button_4.Enable = 'off';
            app.Button_4.Visible = 'on';
            app.Button_4.Text = 'Charge';
            app.Button_4.Position = [371 13 100 22];

            % Create Button_5
            app.Button_5 = uibutton(app.InputPresetsPanel, 'push');
            app.Button_5.ButtonPushedFcn = createCallbackFcn(app, @Button_5ValueChanged, true);
            app.Button_5.Enable = 'off';
            app.Button_5.Visible = 'off';
            app.Button_5.Text = 'Reset';
            app.Button_5.Position = [487 13 100 22];

            % Create Button_6
            app.Button_6 = uibutton(app.InputPresetsPanel, 'state');
            app.Button_6.ValueChangedFcn = createCallbackFcn(app, @Button_6ValueChanged, true);
            app.Button_6.Enable = 'off';
            app.Button_6.Visible = 'off';
            app.Button_6.Text = 'Reset';
            app.Button_6.Position = [603 13 100 22];

            % Create Button_7
            app.Button_7 = uibutton(app.InputPresetsPanel, 'state');
            app.Button_7.ValueChangedFcn = createCallbackFcn(app, @Button_7ValueChanged, true);
            app.Button_7.Enable = 'off';
            app.Button_7.Visible = 'off';
            app.Button_7.Text = 'Reset';
            app.Button_7.Position = [719 13 100 22];

            % Create Button_8
            app.Button_8 = uibutton(app.InputPresetsPanel, 'state');
            app.Button_8.ValueChangedFcn = createCallbackFcn(app, @Button_8ValueChanged, true);
            app.Button_8.Enable = 'off';
            app.Button_8.Visible = 'off';
            app.Button_8.Text = 'Reset';
            app.Button_8.Position = [835 13 100 22];

            % Create Button_9
            app.Button_9 = uibutton(app.InputPresetsPanel, 'state');
            app.Button_9.ValueChangedFcn = createCallbackFcn(app, @Button_9ValueChanged, true);
            app.Button_9.Enable = 'off';
            app.Button_9.Visible = 'off';
            app.Button_9.Text = 'Reset';
            app.Button_9.Position = [951 13 100 22];

            % Create ConfigurationDropDownLabel
            app.ConfigurationDropDownLabel = uilabel(app.simPanel);
            app.ConfigurationDropDownLabel.HorizontalAlignment = 'right';
            app.ConfigurationDropDownLabel.Position = [868 611 80 22];
            app.ConfigurationDropDownLabel.Text = '';

            % Create ConfigurationDropDown
            app.ConfigurationDropDown = uidropdown(app.simPanel);
            app.ConfigurationDropDown.Items = {'No_Com'};
            app.ConfigurationDropDown.ValueChangedFcn = createCallbackFcn(app, @ConfigurationDropDownValueChanged, true);
            app.ConfigurationDropDown.Position = [963 611 100 22];
            app.ConfigurationDropDown.Value = 'No_Com';
            app.ConfigurationDropDown.Enable = 'off';

            % Create PhaseButton
            app.PhaseButton = uibutton(app.simPanel, 'state');
            app.PhaseButton.ValueChangedFcn = createCallbackFcn(app, @PhaseButtonValueChanged, true);
            app.PhaseButton.Text = 'SinglePhase';
            app.PhaseButton.Position = [1081 611 100 22];
            app.PhaseButton.Enable = 'off';

            % Create LoggedRunsDropDownLabel
            app.LoggedRunsDropDownLabel = uilabel(app.simPanel);
            app.LoggedRunsDropDownLabel.HorizontalAlignment = 'right';
            app.LoggedRunsDropDownLabel.Enable = 'off';
            app.LoggedRunsDropDownLabel.Position = [824 546 80 22];
            app.LoggedRunsDropDownLabel.Text = 'Logged Runs:';

            % Create LoggedRunsDropDown
            app.LoggedRunsDropDown = uidropdown(app.simPanel);
            app.LoggedRunsDropDown.Items = {'Select'};
            app.LoggedRunsDropDown.ValueChangedFcn = createCallbackFcn(app, @LoggedRunsDropDownValueChanged, true);
            app.LoggedRunsDropDown.Enable = 'off';
            app.LoggedRunsDropDown.Position = [919 546 262 22];
            app.LoggedRunsDropDown.Value = 'Select';

            % Create RecordedInputsDropDownLabel
            app.RecordedInputsDropDownLabel = uilabel(app.simPanel);
            app.RecordedInputsDropDownLabel.HorizontalAlignment = 'right';
            app.RecordedInputsDropDownLabel.Enable = 'off';
            app.RecordedInputsDropDownLabel.Position = [25 546 94 22];
            app.RecordedInputsDropDownLabel.Text = 'Recorded Inputs';

            % Create RecordedInputsDropDown
            app.RecordedInputsDropDown = uidropdown(app.simPanel);
            app.RecordedInputsDropDown.Items = {'Select'};
            app.RecordedInputsDropDown.ValueChangedFcn = createCallbackFcn(app, @RecordedInputsDropDownValueChanged, true);
            app.RecordedInputsDropDown.Enable = 'off';
            app.RecordedInputsDropDown.Position = [134 546 262 22];
            app.RecordedInputsDropDown.Value = 'Select';

            % Create SaveInputsButton
            app.SaveInputsButton = uibutton(app.simPanel, 'push');
            app.SaveInputsButton.ButtonPushedFcn = createCallbackFcn(app, @SaveInputsButtonPushed, true);
            app.SaveInputsButton.Enable = 'off';
            app.SaveInputsButton.Position = [413 546 100 22];
            app.SaveInputsButton.Text = 'Save Inputs';
        end
    end

    methods (Access = public)

        % Construct app
        function app = integrationPanel

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.simPanel)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.simPanel)
        end
    end
end