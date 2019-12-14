%{
    First Input: Selecting .arxml file. 
    Second Input: Select compoenent and create model 

    STEPS TO EXECUTE
    1: 

%%
    DECRIPTION:
    Creates frame model of component or compostion from ARXML. 
    Requires embedded coder with autosar support package  
%%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 4-May-2019
%%
    VERSION MANAGER
    v1  Creates component frame model from ARXML
    v2  Added composition frame model generation option
    v3  Option to choose which compositions to display
    v4  Included update model option, exception handling and progress bar
%}

classdef arxml_frame_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        arxml_GUI                     matlab.ui.Figure
        OpenButton                    matlab.ui.control.Button
        NameofarxmlLabel              matlab.ui.control.Label
        NameofarxmlField              matlab.ui.control.EditField
        SelectcomponentDropDownLabel  matlab.ui.control.Label
        SelectcomponentDropDown       matlab.ui.control.DropDown
        Execute                       matlab.ui.control.Button
        ButtonGroup                   matlab.ui.container.ButtonGroup
        ApplicationButton             matlab.ui.control.ToggleButton
        ComponentsLabel               matlab.ui.control.Label
        SensorActuatorButton          matlab.ui.control.ToggleButton
        CompositionsButton            matlab.ui.control.ToggleButton
        SelectModelButton             matlab.ui.control.Button
        NameofmodelLabel              matlab.ui.control.Label
        Nameofmodel                   matlab.ui.control.EditField
        StatusLabel                   matlab.ui.control.Label
        UpdateModel                   matlab.ui.control.CheckBox
    end

    
    properties (Access = private)
        arxml_name % Description
        arxml_path
        ModelName
        OnlyModelName
        ModelPath
        comp_name % Description
        arObj
        sel_cmpt
        AppCompts
        SACompts
        Comps
        AllNames

    end
    

    methods (Access = private)
        function CompMap = CompNames(app,optionSelect)
            AllNames = getComponentNames(app.arObj,optionSelect);
            CompMap = containers.Map('KeyType','char','ValueType','char');
            for i = 1:length(AllNames)
                temp = char(AllNames(i));
                split = strsplit(temp,'/');
                split = split(length(split));
                CompMap(split{1,1}) = temp;
            end
        end

        function UpdateDropDown(app)
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
                
                if isempty(app.SelectcomponentDropDown.Items)
                    app.Execute.Enable = 'off';
                else
                    app.Execute.Enable = 'on';
                end
            catch
                if isempty(app.arxml_name) || app.arxml_name == 0
                    app.StatusLabel.Text = 'Select .arxml file';
                end
            end
        end

        % function SelCompName(app)
        %     if app.ApplicationButton.Value
        %         app.SelectcomponentDropDown.Items = app.AppCompts.keys;
        %     elseif app.SensorActuatorButton.Value
        %         app.SelectcomponentDropDown.Items = app.SACompts.keys;
        %     elseif app.CompositionsButton.Value
        %         app.SelectcomponentDropDown.Items = app.Comps.keys;
        %     end
        % end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            %app.StatusLabel.Text = char(app.DispOptions.SelectedObject);
            UpdateDropDown(app);
        end

        % Button pushed function: OpenButton
        function OpenButtonPushed(app, event)

            app.StatusLabel.Text = 'Select .arxml file';
            app.StatusLabel.FontColor = [0 0 0];
            
            [app.arxml_name,app.arxml_path] = uigetfile('*.arxml','Select ARXML file');
            
            if app.arxml_name == 0
                app.StatusLabel.Text = 'Select .arxml file';
                app.Execute.Enable = 'off';
                app.NameofarxmlField.Value = '';
                drawnow
            else
                addpath(app.arxml_path);
                %app.comp_name = strsplit(app.arxml_name,'.'); %update comp name based on selection
                try
                    prog_stat = uiprogressdlg(app.arxml_GUI,'Title','Importing ARXML',...
                            'Message','','Indeterminate','on');
                    app.arObj = arxml.importer(app.arxml_name);
                    app.Execute.Enable = 'on';
                    app.NameofarxmlField.Value = app.arxml_name;
                    app.StatusLabel.Text = 'ARXML imported';
                    drawnow

                    app.AppCompts = CompNames(app,'Application');
                    app.SACompts = CompNames(app,'SensorActuator');
                    app.Comps = CompNames(app,'Composition');
                    app.AllNames = [app.AppCompts;app.SACompts;app.Comps];

                    UpdateDropDown(app);
                    app.StatusLabel.Text = 'Select component or composition';
                    close(prog_stat);
                catch ErrorCaught
                    close(prog_stat);
                    warning('-----------Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support-----------');
                    app.StatusLabel.Text = 'Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support';
                    app.StatusLabel.FontColor = [1 0 0];
                    app.Execute.Enable = 'off';
                    uialert(app.arxml_GUI,'Unable to load ARXML. Talk to Sushant or get MATLAB with ARXML support','Error');
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end

            end
        end

        % Button pushed function: SelectModelButton
        function SelectModelButtonPushed(app, event)
            [app.ModelName,app.ModelPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to test');
            if app.ModelName == 0
                app.StatusLabel.Text = 'Select model to update';
                app.Execute.Enable = 'off';
                app.Nameofmodel.Value = '';
                drawnow
            else
                prog_stat = uiprogressdlg(app.arxml_GUI,'Title','Loading model',...
                            'Message','','Indeterminate','on');
                app.OnlyModelName = strsplit(app.ModelName,'.');
                app.OnlyModelName = app.OnlyModelName{1,1};
                app.Nameofmodel.Value = app.OnlyModelName;
                if isequal(app.OnlyModelName,app.SelectcomponentDropDown.Value)
                    app.Execute.Enable = 'on';
                    app.StatusLabel.Text = 'Select model to update';
                    app.StatusLabel.FontColor = [0 0 0];
                else
                    app.StatusLabel.Text = 'Different model and component names';
                    app.StatusLabel.FontColor = [1 0 0];
                    app.Execute.Enable = 'off';
                end
                if ~isequal(app.ModelPath, app.arxml_path)
                    addpath(app.ModelPath);
                end
                load_system(app.OnlyModelName);
                close(prog_stat);
            end  
        end

        % Value changed function: UpdateModel
        function UpdateModelValueChanged(app, event)
            %value = app.UpdateModel.Value;
            if app.UpdateModel.Value == 1 && app.CompositionsButton.Value == 1
                app.Execute.Enable = 'off';
                app.SelectModelButton.Enable = 'off';
                app.Nameofmodel.Enable = 'off';
                app.NameofmodelLabel.Enable = 'off';
                app.StatusLabel.Text = 'Select component or composition';
                app.Execute.Text = 'Create frame model & data type scripts';
                drawnow
            elseif app.UpdateModel.Value
                app.SelectModelButton.Enable = 'on';
                app.Nameofmodel.Enable = 'on';
                app.NameofmodelLabel.Enable = 'on';
                app.StatusLabel.Text = 'Select model to update';
                app.Execute.Text = 'Update model according to new ARXML';
                
                drawnow
            else
                %app.Execute.Enable = 'off';
                app.SelectModelButton.Enable = 'off';
                app.Nameofmodel.Enable = 'off';
                app.NameofmodelLabel.Enable = 'off';
                app.StatusLabel.Text = 'Select component or composition';
                app.Execute.Text = 'Create frame model & data type scripts';
                drawnow
            end

        end

        % Button pushed function: Execute
        function ExecutePushed(app, event)

            app.StatusLabel.FontColor = [0 0 0];
            if app.UpdateModel.Value == 1
                app.StatusLabel.Text = 'Updating model according to ARXML';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.arxml_GUI,'Title','Updating model',...
                            'Message','','Indeterminate','on');
                    load_system(app.OnlyModelName);
                    updateModel(app.arObj,app.OnlyModelName);
                    app.StatusLabel.Text = 'Model udpated according to ARXML';
                    drawnow

                    close(prog_stat);
                    
                    uialert(app.arxml_GUI,'Model udpated according to ARXML. Complete manual model changes mentioned in update report','Success','Icon','success');
                catch ErrorCaught
                    close(prog_stat);
                    warning('-----------Unable to update model. Retry after restarting matlab-----------');
                    app.StatusLabel.Text = 'Unable to update model.';
                    app.StatusLabel.FontColor = [1 0 0];
                    uialert(app.arxml_GUI,'Unable to update model. Check command window for more info','Error');
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            elseif app.CompositionsButton.Value == 0
                app.StatusLabel.Text = 'Creating scripts with data types';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.arxml_GUI,'Title','Creating frame model',...
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
                    
                    app.StatusLabel.Text = 'Creating component frame model';
                    prog_stat.Message = app.StatusLabel.Text;
                    drawnow

                    createComponentAsModel(app.arObj,app.AllNames(app.SelectcomponentDropDown.Value),'ModelPeriodicRunnablesAs','FunctionCallSubsystem',...
                            'DataDictionary',sprintf('%s.sldd',app.SelectcomponentDropDown.Value));

                    Model_name = get_param(gcs,'Name');
                    DataDictionaryObj = Simulink.data.dictionary.open(sprintf('%s.sldd',app.SelectcomponentDropDown.Value));
                    dDataSectObj = getSection(DataDictionaryObj,'Design Data');
                    exportToFile(dDataSectObj,sprintf('%s_DerivedDatatypes.m',Model_name));
                    
                    save_system;
                    
                    app.StatusLabel.Text = 'Component frame model created';
                    close(prog_stat);
                    uialert(app.arxml_GUI,'Component frame model created','Success','Icon','success');
                catch ErrorCaught
                    close(prog_stat);
                    warning('-----------Unable to create frame model. Retry after restarting matlab-----------');
                    app.StatusLabel.Text = 'Unable to create frame model.';
                    uialert(app.arxml_GUI,'Unable to create frame model. Check command window for more info','Error');
                    app.StatusLabel.FontColor = [1 0 0];
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
                
            elseif app.CompositionsButton.Value == 1
                app.StatusLabel.Text = 'Creating scripts with data types';
                drawnow

                try
                    prog_stat = uiprogressdlg(app.arxml_GUI,'Title','Creating frame model',...
                            'Message','','Indeterminate','on');

                    createCompositionAsModel(app.arObj,app.AllNames(app.SelectcomponentDropDown.Value),'DataDictionary',sprintf('%s.sldd',app.SelectcomponentDropDown.Value));
                    app.StatusLabel.Text = 'Creating composition frame model';
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
                    app.StatusLabel.Text = 'Composition frame model created';
                    uialert(app.arxml_GUI,'Component frame model created','Success','Icon','success');
                catch ErrorCaught
                    close(prog_stat);
                    warning('-----------Unable to create frame model. Retry after restarting matlab-----------');
                    app.StatusLabel.Text = 'Unable to create frame model. Retry after restarting matlab';
                    uialert(app.arxml_GUI,'Unable to create frame model. Check command window for more info','Error');
                    app.StatusLabel.FontColor = [1 0 0];
                    fprintf(2,'Error: %s\n',ErrorCaught.message);
                end
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create arxml_GUI
            app.arxml_GUI = uifigure;
            app.arxml_GUI.Position = [100 100 646 293];
            app.arxml_GUI.Name = 'ARXML to frame model (v4)';

            % Create OpenButton
            app.OpenButton = uibutton(app.arxml_GUI, 'push');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenButton.Position = [477 236 104 22];
            app.OpenButton.Text = 'Open';

            % Create NameofarxmlLabel
            app.NameofarxmlLabel = uilabel(app.arxml_GUI);
            app.NameofarxmlLabel.Position = [60 236 87 22];
            app.NameofarxmlLabel.Text = 'Name of arxml:';

            % Create NameofarxmlField
            app.NameofarxmlField = uieditfield(app.arxml_GUI, 'text');
            app.NameofarxmlField.Editable = 'off';
            app.NameofarxmlField.Position = [169 236 282 22];

            % Create SelectcomponentDropDownLabel
            app.SelectcomponentDropDownLabel = uilabel(app.arxml_GUI);
            app.SelectcomponentDropDownLabel.Position = [60 142 105 22];
            app.SelectcomponentDropDownLabel.Text = 'Select component:';

            % Create SelectcomponentDropDown
            app.SelectcomponentDropDown = uidropdown(app.arxml_GUI);
            app.SelectcomponentDropDown.Items = {'Component'};
            app.SelectcomponentDropDown.Position = [169 142 282 22];
            app.SelectcomponentDropDown.Value = 'Component';

            % Create Execute
            app.Execute = uibutton(app.arxml_GUI, 'push');
            app.Execute.ButtonPushedFcn = createCallbackFcn(app, @ExecutePushed, true);
            app.Execute.Enable = 'off';
            app.Execute.Position = [205 50 226 22];
            app.Execute.Text = 'Create frame model & data type scripts';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.arxml_GUI);
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontWeight = 'bold';
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.Position = [61 20 522 22];
            app.StatusLabel.Text = 'Select .arxml file';

            % Create UpdateModel
            app.UpdateModel = uicheckbox(app.arxml_GUI);
            app.UpdateModel.ValueChangedFcn = createCallbackFcn(app, @UpdateModelValueChanged, true);
            app.UpdateModel.Text = ' Update Model';
            app.UpdateModel.Position = [481 142 100 22];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.arxml_GUI);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.BorderType = 'none';
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.Position = [60 167 463 50];

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
            app.SelectModelButton = uibutton(app.arxml_GUI, 'push');
            app.SelectModelButton.ButtonPushedFcn = createCallbackFcn(app, @SelectModelButtonPushed, true);
            app.SelectModelButton.Enable = 'off';
            app.SelectModelButton.Position = [477 100 104 22];
            app.SelectModelButton.Text = 'Select Model';

            % Create NameofmodelLabel
            app.NameofmodelLabel = uilabel(app.arxml_GUI);
            app.NameofmodelLabel.Enable = 'off';
            app.NameofmodelLabel.Position = [60 100 90 22];
            app.NameofmodelLabel.Text = 'Name of model:';

            % Create Nameofmodel
            app.Nameofmodel = uieditfield(app.arxml_GUI, 'text');
            app.Nameofmodel.Editable = 'off';
            app.Nameofmodel.Enable = 'off';
            app.Nameofmodel.Position = [169 100 282 22];
        end
    end

    methods (Access = public)

        % Construct app
        function app = arxml_frame_GUI

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.arxml_GUI)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.arxml_GUI)
        end
    end
end