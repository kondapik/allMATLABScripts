%{
%
    DECRIPTION:
    Displays audio

%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 13-June-2020
    LAST MODIFIED: 13-June-2020
%
    VERSION MANAGER
    v1      Initial implementation
%}

classdef chromaticArduino < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        audioControl                   matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        TabGroup                       matlab.ui.container.TabGroup
        ControlTab                     matlab.ui.container.Tab
        Panel                          matlab.ui.container.Panel
        ModeGroup                      matlab.ui.container.ButtonGroup
        AudioButton                    matlab.ui.control.ToggleButton
        RainbowButton                  matlab.ui.control.ToggleButton
        SingleButton                   matlab.ui.control.ToggleButton
        FreqSlider                     matlab.ui.control.Slider
        FreqPlot                       matlab.ui.control.UIAxes
        LEDColor                       matlab.ui.control.Lamp
        ColorOrderDropDownLabel        matlab.ui.control.Label
        ColorOrder                     matlab.ui.control.DropDown
        LEDBrightnessSliderLabel       matlab.ui.control.Label
        LEDSlider                      matlab.ui.control.Slider
        FPSCheckBox                    matlab.ui.control.CheckBox
        minFreq                        matlab.ui.control.Label
        leftFreq                       matlab.ui.control.Label
        rightFreq                      matlab.ui.control.Label
        maxFreq                        matlab.ui.control.Label
        FreqLabel                      matlab.ui.control.Label
        ColorControl                   matlab.ui.container.Panel
        RedSliderLabel                 matlab.ui.control.Label
        RedSlider                      matlab.ui.control.Slider
        GreenSliderLabel               matlab.ui.control.Label
        GreenSlider                    matlab.ui.control.Slider
        BlueSliderLabel                matlab.ui.control.Label
        BlueSlider                     matlab.ui.control.Slider
        SpeedSliderLabel               matlab.ui.control.Label
        SpeedSlider                    matlab.ui.control.Slider
        RedDropDownLabel               matlab.ui.control.Label
        RedPin                         matlab.ui.control.DropDown
        GreenDropDownLabel             matlab.ui.control.Label
        GreenPin                       matlab.ui.control.DropDown
        BlueDropDownLabel              matlab.ui.control.Label
        BluePin                        matlab.ui.control.DropDown
        AudioSourceLabel               matlab.ui.control.Label
        AudioDevice                    matlab.ui.control.DropDown
        StartButton                    matlab.ui.control.StateButton
        PreferencesTab                 matlab.ui.container.Tab
        AudioFPSEditFieldLabel         matlab.ui.control.Label
        AudioFPS                       matlab.ui.control.NumericEditField
        NoofFFTbandsEditFieldLabel     matlab.ui.control.Label
        NoofFFTbands                   matlab.ui.control.NumericEditField
        GainLimitEditFieldLabel        matlab.ui.control.Label
        GainLimit                      matlab.ui.control.NumericEditField
        VolToleranceEditFieldLabel     matlab.ui.control.Label
        VolTolerance                   matlab.ui.control.NumericEditField
        AplhaDecayAudioEditFieldLabel  matlab.ui.control.Label
        AplhaDecayAudio                matlab.ui.control.NumericEditField
        AplhaDecayGainEditFieldLabel   matlab.ui.control.Label
        AplhaDecayGain                 matlab.ui.control.NumericEditField
        AplhaDecayLEDEditFieldLabel    matlab.ui.control.Label
        AplhaDecayLED                  matlab.ui.control.NumericEditField
        MinFrequencyEditFieldLabel     matlab.ui.control.Label
        MinFrequency                   matlab.ui.control.NumericEditField
        LeftFrequencyEditFieldLabel    matlab.ui.control.Label
        LeftFrequency                  matlab.ui.control.NumericEditField
        RightFrequencyEditFieldLabel   matlab.ui.control.Label
        RightFrequency                 matlab.ui.control.NumericEditField
        MaxFrequencyEditFieldLabel     matlab.ui.control.Label
        MaxFrequency                   matlab.ui.control.NumericEditField
        AplhaRiseAudioEditFieldLabel   matlab.ui.control.Label
        AplhaRiseAudio                 matlab.ui.control.NumericEditField
        AplhaRiseGainEditFieldLabel    matlab.ui.control.Label
        AplhaRiseGain                  matlab.ui.control.NumericEditField
        AplhaRiseLEDEditFieldLabel     matlab.ui.control.Label
        AplhaRiseLED                   matlab.ui.control.NumericEditField
        AboutTab                       matlab.ui.container.Tab
        Image                          matlab.ui.control.Image
        PreferenceMenu                 matlab.ui.container.ContextMenu
        SavePreferences                matlab.ui.container.Menu
        SettingsMenu                   matlab.ui.container.ContextMenu
        SaveSettings                   matlab.ui.container.Menu
        PlotMenu                       matlab.ui.container.ContextMenu
        EnablePlot                     matlab.ui.container.Menu
    end

    properties (Access = private)
        freqAxis;
        lineLow;
        lineMid;
        lineHigh;
        ledAxis;
        lineBright;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
        end

        % Close request function: audioControl
        function audioControlCloseRequest(app, event)
            SavePreferencesMenuSelected(app, event);
            delete(app)
        end

        % Menu selected function: SavePreferences, SaveSettings
        function SavePreferencesMenuSelected(app, event)
%             jsonStr = jsonencode(app);
%             fid = fopen('testingJson.json', 'w');
%             if fid == -1, error('Cannot create JSON file'); end
%             fwrite(fid, jsonStr, 'char');
%             fclose(fid);
        end

        % Menu selected function: EnablePlot
        function EnablePlotMenuSelected(app, event)
            
        end

        % Value changed function: StartButton
        function StartButtonValueChanged(app, event)
            value = app.StartButton.Value;
            
        end

        % Value changed function: ColorOrder
        function ColorOrderValueChanged(app, event)
            app.lineLow.Color = app.ColorOrder.Value(1);
            app.lineMid.Color = app.ColorOrder.Value(2);
            app.lineHigh.Color = app.ColorOrder.Value(3);
        end

        function lineLowMoving(app,source)
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;

            app.lineMid.Position(1,1) = source.Position(2,1);
            app.minFreq.Position(1) = app.getPosition(source.Position(1,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.minFreq.Position(3));
            app.minFreq.Text = num2str(round(source.Position(1,1)));
            app.MinFrequency.Value = round(source.Position(1,1));
            
            app.leftFreq.Position(1) = app.getPosition(source.Position(2,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.leftFreq.Position(3));
            app.leftFreq.Text = num2str(round(source.Position(2,1)));
            app.LeftFrequency.Value = round(source.Position(2,1));
        end
        
        function lineMidMoving(app,source)
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;

            app.lineLow.Position(2,1) = source.Position(1,1);

            app.leftFreq.Position(1) = app.getPosition(source.Position(1,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.leftFreq.Position(3));
            app.leftFreq.Text = num2str(round(source.Position(1,1)));
            app.LeftFrequency.Value = round(source.Position(1,1));
            
            app.lineHigh.Position(1,1) = source.Position(2,1);
            app.rightFreq.Position(1) = app.getPosition(source.Position(2,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.rightFreq.Position(3));
            app.rightFreq.Text = num2str(round(source.Position(2,1)));
            app.RightFrequency.Value = round(source.Position(2,1));
        end
        
        function lineHighMoving(app,source)
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;

            app.rightFreq.Position(1) = app.getPosition(source.Position(1,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.rightFreq.Position(3));
            app.rightFreq.Text = num2str(round(source.Position(1,1)));
            app.RightFrequency.Value = round(source.Position(1,1));

            app.lineMid.Position(2,1) = source.Position(1,1);
            app.maxFreq.Position(1) = app.getPosition(source.Position(2,1),app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.maxFreq.Position(3));
            app.maxFreq.Text = num2str(round(source.Position(2,1)));
            app.MaxFrequency.Value = round(source.Position(2,1));
        end

        function lineBrightMoving(~,source)
            source.Position(1,1) = 0;
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;
        end
    end

    methods (Static)

        function mappedValue = mapValue(value, fromLow, fromHigh, toLow, toHigh)
            % map 'value' from 'from range' to 'to range'
            mappedValue = (value - fromLow) * (toHigh - toLow) / (fromHigh - fromLow) + toLow;
        end

        function xPos = getPosition(freq, sliderPos, sliderWidth, blockWidth)
            %get x_position of the label based on slider width and position 
            xPos = (((freq - 20)/(20000 - 20))*sliderWidth) + sliderPos - (blockWidth/2);
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create audioControl and hide until all components are created
            app.audioControl = uifigure('Visible', 'off');
            app.audioControl.Position = [100 100 891 562];
            app.audioControl.Name = 'chromaticArduino';
            app.audioControl.Resize = 'off';
            app.audioControl.CloseRequestFcn = createCallbackFcn(app, @audioControlCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.audioControl);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [2 13];
            app.TabGroup.Layout.Column = [2 12];

            % Create ControlTab
            app.ControlTab = uitab(app.TabGroup);
            app.ControlTab.Title = 'Control';
            app.ControlTab.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create Panel
            app.Panel = uipanel(app.ControlTab);
            app.Panel.BorderType = 'none';
            app.Panel.Title = ' ';
            app.Panel.Position = [8 5 783 430];

            % Create ModeGroup
            app.ModeGroup = uibuttongroup(app.Panel);
            app.ModeGroup.Tooltip = {'Select display mode'};
            app.ModeGroup.BorderType = 'none';
            app.ModeGroup.FontName = 'Microsoft JhengHei UI';
            app.ModeGroup.Position = [20 240 124 139];

            % Create AudioButton
            app.AudioButton = uitogglebutton(app.ModeGroup);
            app.AudioButton.Text = 'Audio';
            app.AudioButton.FontName = 'Microsoft JhengHei UI';
            app.AudioButton.Position = [7 103 113 23];
            app.AudioButton.Value = true;

            % Create RainbowButton
            app.RainbowButton = uitogglebutton(app.ModeGroup);
            app.RainbowButton.Text = 'Rainbow';
            app.RainbowButton.FontName = 'Microsoft JhengHei UI';
            app.RainbowButton.Position = [7 59 113 23];

            % Create SingleButton
            app.SingleButton = uitogglebutton(app.ModeGroup);
            app.SingleButton.Text = 'Single';
            app.SingleButton.FontName = 'Microsoft JhengHei UI';
            app.SingleButton.Position = [7 16 113 23];

            % Create FreqSlider
            app.FreqSlider = uislider(app.Panel);
            app.FreqSlider.Visible = 'off';
            app.FreqSlider.Enable = 'off';
            app.FreqSlider.Tooltip = {'Select Frequency Ranges for Audio Analysis'};
            app.FreqSlider.Position = [33 54 714 3];

            % Create FreqPlot
            app.FreqPlot = uiaxes(app.Panel);
            title(app.FreqPlot, 'Frequency Bank Output')
            xlabel(app.FreqPlot, '')
            ylabel(app.FreqPlot, '')
            app.FreqPlot.FontName = 'Microsoft JhengHei UI';
            app.FreqPlot.XMinorTick = 'on';
            app.FreqPlot.XScale = 'log';
            app.FreqPlot.Position = [158 217 608 185];

            % Create LEDColor
            app.LEDColor = uilamp(app.Panel);
            app.LEDColor.Tooltip = {'LED Color'};
            app.LEDColor.Position = [50 148 64 64];
            app.LEDColor.Color = [0.9412 0.9412 0.9412];

            % Create ColorOrderDropDownLabel
            app.ColorOrderDropDownLabel = uilabel(app.Panel);
            app.ColorOrderDropDownLabel.HorizontalAlignment = 'right';
            app.ColorOrderDropDownLabel.VerticalAlignment = 'top';
            app.ColorOrderDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.ColorOrderDropDownLabel.Position = [165 169 75 22];
            app.ColorOrderDropDownLabel.Text = 'Color Order:';

            % Create ColorOrder
            app.ColorOrder = uidropdown(app.Panel);
            app.ColorOrder.Items = {'RRR', 'RRG', 'RRB', 'RGR', 'RGG', 'RGB', 'RBR', 'RBG','RBB',...
                                    'GRR', 'GRG', 'GRB', 'GGR', 'GGG', 'GGB', 'GBR','GBG', 'GBB',...
                                     'BRR', 'BRG', 'BRB', 'BGR', 'BGG', 'BGB', 'BBR', 'BBG', 'BBB'};
            app.ColorOrder.ValueChangedFcn = createCallbackFcn(app, @ColorOrderValueChanged, true);
            app.ColorOrder.FontName = 'Microsoft JhengHei UI';
            app.ColorOrder.Position = [246 170 63 22];
            app.ColorOrder.Value = 'BGR';

            % Create LEDBrightnessSliderLabel
            app.LEDBrightnessSliderLabel = uilabel(app.Panel);
            app.LEDBrightnessSliderLabel.HorizontalAlignment = 'right';
            app.LEDBrightnessSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.LEDBrightnessSliderLabel.Position = [332 171 92 22];
            app.LEDBrightnessSliderLabel.Text = 'LED Brightness:';

            % Create LEDSlider
            app.LEDSlider = uislider(app.Panel);
            app.LEDSlider.MajorTicks = [0 20 40 60 80 100];
            app.LEDSlider.MajorTickLabels = {'0', '20', '40', '60', '80', '100'};
            app.LEDSlider.Visible = 'off';
            app.LEDSlider.Enable = 'off';
            app.LEDSlider.Tooltip = {'LED Brightness'};
            app.LEDSlider.FontName = 'Microsoft JhengHei UI';
            app.LEDSlider.Position = [441 180 181 3];

            % Create FPSCheckBox
            app.FPSCheckBox = uicheckbox(app.Panel);
            app.FPSCheckBox.Tooltip = {'Display FPS'};
            app.FPSCheckBox.Text = '  FPS:';
            app.FPSCheckBox.FontName = 'Microsoft JhengHei UI';
            app.FPSCheckBox.Position = [653 169 96 22];

            % Create minFreq
            app.minFreq = uilabel(app.Panel);
            app.minFreq.HorizontalAlignment = 'center';
            app.minFreq.FontName = 'Microsoft JhengHei UI';
            app.minFreq.Position = [-3 67 72 22];
            app.minFreq.Text = '20';

            % Create leftFreq
            app.leftFreq = uilabel(app.Panel);
            app.leftFreq.HorizontalAlignment = 'center';
            app.leftFreq.FontName = 'Microsoft JhengHei UI';
            app.leftFreq.Position = [91 67 72 22];
            app.leftFreq.Text = '1500';

            % Create rightFreq
            app.rightFreq = uilabel(app.Panel);
            app.rightFreq.HorizontalAlignment = 'center';
            app.rightFreq.FontName = 'Microsoft JhengHei UI';
            app.rightFreq.Position = [236 67 72 22];
            app.rightFreq.Text = '6000';

            % Create maxFreq
            app.maxFreq = uilabel(app.Panel);
            app.maxFreq.HorizontalAlignment = 'center';
            app.maxFreq.FontName = 'Microsoft JhengHei UI';
            app.maxFreq.Position = [399 67 72 22];
            app.maxFreq.Text = '16000';

            % Create FreqLabel
            app.FreqLabel = uilabel(app.Panel);
            app.FreqLabel.FontName = 'Microsoft JhengHei UI';
            app.FreqLabel.Position = [216 96 354 22];
            app.FreqLabel.Text = '--------- Select Frequency Ranges for Audio Analysis ---------';

            % Create ColorControl
            app.ColorControl = uipanel(app.Panel);
            app.ColorControl.BorderType = 'none';
            app.ColorControl.Visible = 'off';
            app.ColorControl.Position = [162 220 599 175];

            % Create RedSliderLabel
            app.RedSliderLabel = uilabel(app.ColorControl);
            app.RedSliderLabel.HorizontalAlignment = 'right';
            app.RedSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.RedSliderLabel.Position = [33 137 33 22];
            app.RedSliderLabel.Text = 'Red: ';

            % Create RedSlider
            app.RedSlider = uislider(app.ColorControl);
            app.RedSlider.Visible = 'off';
            app.RedSlider.FontName = 'Microsoft JhengHei UI';
            app.RedSlider.Position = [87 146 422 3];

            % Create GreenSliderLabel
            app.GreenSliderLabel = uilabel(app.ColorControl);
            app.GreenSliderLabel.HorizontalAlignment = 'right';
            app.GreenSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.GreenSliderLabel.Position = [21 100 45 22];
            app.GreenSliderLabel.Text = 'Green: ';

            % Create GreenSlider
            app.GreenSlider = uislider(app.ColorControl);
            app.GreenSlider.Visible = 'off';
            app.GreenSlider.FontName = 'Microsoft JhengHei UI';
            app.GreenSlider.Position = [87 109 422 3];

            % Create BlueSliderLabel
            app.BlueSliderLabel = uilabel(app.ColorControl);
            app.BlueSliderLabel.HorizontalAlignment = 'right';
            app.BlueSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.BlueSliderLabel.Position = [30 62 36 22];
            app.BlueSliderLabel.Text = 'Blue: ';

            % Create BlueSlider
            app.BlueSlider = uislider(app.ColorControl);
            app.BlueSlider.Visible = 'off';
            app.BlueSlider.FontName = 'Microsoft JhengHei UI';
            app.BlueSlider.Position = [87 71 422 3];

            % Create SpeedSliderLabel
            app.SpeedSliderLabel = uilabel(app.ColorControl);
            app.SpeedSliderLabel.HorizontalAlignment = 'right';
            app.SpeedSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.SpeedSliderLabel.Position = [79 25 44 22];
            app.SpeedSliderLabel.Text = 'Speed:';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.ColorControl);
            app.SpeedSlider.Visible = 'off';
            app.SpeedSlider.FontName = 'Microsoft JhengHei UI';
            app.SpeedSlider.Position = [144 34 320 3];

            % Create RedDropDownLabel
            app.RedDropDownLabel = uilabel(app.ControlTab);
            app.RedDropDownLabel.HorizontalAlignment = 'right';
            app.RedDropDownLabel.VerticalAlignment = 'top';
            app.RedDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.RedDropDownLabel.Tooltip = {'Select PWM pins for colors'};
            app.RedDropDownLabel.Position = [448 434 30 22];
            app.RedDropDownLabel.Text = 'Red:';

            % Create RedPin
            app.RedPin = uidropdown(app.ControlTab);
            app.RedPin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.RedPin.Tooltip = {'Select PWM pins for colors'};
            app.RedPin.FontName = 'Microsoft JhengHei UI';
            app.RedPin.Position = [486 435 55 22];
            app.RedPin.Value = 'D9';

            % Create GreenDropDownLabel
            app.GreenDropDownLabel = uilabel(app.ControlTab);
            app.GreenDropDownLabel.HorizontalAlignment = 'right';
            app.GreenDropDownLabel.VerticalAlignment = 'top';
            app.GreenDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.GreenDropDownLabel.Tooltip = {'Select PWM pins for colors'};
            app.GreenDropDownLabel.Position = [554 434 42 22];
            app.GreenDropDownLabel.Text = 'Green:';

            % Create GreenPin
            app.GreenPin = uidropdown(app.ControlTab);
            app.GreenPin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.GreenPin.Tooltip = {'Select PWM pins for colors'};
            app.GreenPin.FontName = 'Microsoft JhengHei UI';
            app.GreenPin.Position = [604 435 55 22];
            app.GreenPin.Value = 'D10';

            % Create BlueDropDownLabel
            app.BlueDropDownLabel = uilabel(app.ControlTab);
            app.BlueDropDownLabel.HorizontalAlignment = 'right';
            app.BlueDropDownLabel.VerticalAlignment = 'top';
            app.BlueDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.BlueDropDownLabel.Tooltip = {'Select PWM pins for colors'};
            app.BlueDropDownLabel.Position = [671 434 33 22];
            app.BlueDropDownLabel.Text = 'Blue:';

            % Create BluePin
            app.BluePin = uidropdown(app.ControlTab);
            app.BluePin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.BluePin.Tooltip = {'Select PWM pins for colors'};
            app.BluePin.FontName = 'Microsoft JhengHei UI';
            app.BluePin.Position = [712 435 55 22];
            app.BluePin.Value = 'D11';

            % Create AudioSourceLabel
            app.AudioSourceLabel = uilabel(app.ControlTab);
            app.AudioSourceLabel.HorizontalAlignment = 'right';
            app.AudioSourceLabel.VerticalAlignment = 'top';
            app.AudioSourceLabel.FontName = 'Microsoft JhengHei UI';
            app.AudioSourceLabel.Position = [170 433 84 22];
            app.AudioSourceLabel.Text = 'Audio Source:';

            % Create AudioDevice
            app.AudioDevice = uidropdown(app.ControlTab);
            app.AudioDevice.Items = {'Default'};
            app.AudioDevice.FontName = 'Microsoft JhengHei UI';
            app.AudioDevice.Position = [262 434 153 22];
            app.AudioDevice.Value = 'Default';

            % Create StartButton
            app.StartButton = uibutton(app.ControlTab, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonValueChanged, true);
            app.StartButton.IconAlignment = 'center';
            app.StartButton.Text = 'Start';
            app.StartButton.BackgroundColor = [0 0.902 0];
            app.StartButton.FontName = 'Microsoft JhengHei UI';
            app.StartButton.Position = [40 435 100 23];

            % Create PreferencesTab
            app.PreferencesTab = uitab(app.TabGroup);
            app.PreferencesTab.Title = 'Preferences';

            % Create AudioFPSEditFieldLabel
            app.AudioFPSEditFieldLabel = uilabel(app.PreferencesTab);
            app.AudioFPSEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AudioFPSEditFieldLabel.Position = [101 394 106 22];
            app.AudioFPSEditFieldLabel.Text = 'Audio FPS:';

            % Create AudioFPS
            app.AudioFPS = uieditfield(app.PreferencesTab, 'numeric');
            app.AudioFPS.Limits = [0 Inf];
            app.AudioFPS.RoundFractionalValues = 'on';
            app.AudioFPS.ValueDisplayFormat = '%.0f';
            app.AudioFPS.HorizontalAlignment = 'center';
            app.AudioFPS.FontName = 'Microsoft JhengHei UI';
            app.AudioFPS.Position = [223 392 114 22];
            app.AudioFPS.Value = 60;

            % Create NoofFFTbandsEditFieldLabel
            app.NoofFFTbandsEditFieldLabel = uilabel(app.PreferencesTab);
            app.NoofFFTbandsEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.NoofFFTbandsEditFieldLabel.Position = [101 338 123 22];
            app.NoofFFTbandsEditFieldLabel.Text = 'No of FFT bands:';

            % Create NoofFFTbands
            app.NoofFFTbands = uieditfield(app.PreferencesTab, 'numeric');
            app.NoofFFTbands.Limits = [0 Inf];
            app.NoofFFTbands.RoundFractionalValues = 'on';
            app.NoofFFTbands.ValueDisplayFormat = '%.0f';
            app.NoofFFTbands.HorizontalAlignment = 'center';
            app.NoofFFTbands.FontName = 'Microsoft JhengHei UI';
            app.NoofFFTbands.Position = [223 336 114 22];
            app.NoofFFTbands.Value = 24;

            % Create GainLimitEditFieldLabel
            app.GainLimitEditFieldLabel = uilabel(app.PreferencesTab);
            app.GainLimitEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.GainLimitEditFieldLabel.Position = [101 282 106 22];
            app.GainLimitEditFieldLabel.Text = 'Gain Limit:';

            % Create GainLimit
            app.GainLimit = uieditfield(app.PreferencesTab, 'numeric');
            app.GainLimit.Limits = [0 Inf];
            app.GainLimit.ValueDisplayFormat = '%.7f';
            app.GainLimit.HorizontalAlignment = 'center';
            app.GainLimit.FontName = 'Microsoft JhengHei UI';
            app.GainLimit.Position = [223 280 114 22];
            app.GainLimit.Value = 5e-06;

            % Create VolToleranceEditFieldLabel
            app.VolToleranceEditFieldLabel = uilabel(app.PreferencesTab);
            app.VolToleranceEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.VolToleranceEditFieldLabel.Position = [101 227 106 22];
            app.VolToleranceEditFieldLabel.Text = 'Vol Tolerance:';

            % Create VolTolerance
            app.VolTolerance = uieditfield(app.PreferencesTab, 'numeric');
            app.VolTolerance.Limits = [0 Inf];
            app.VolTolerance.ValueDisplayFormat = '%.13f';
            app.VolTolerance.HorizontalAlignment = 'center';
            app.VolTolerance.FontName = 'Microsoft JhengHei UI';
            app.VolTolerance.Position = [223 225 114 22];
            app.VolTolerance.Value = 1e-12;

            % Create AplhaDecayAudioEditFieldLabel
            app.AplhaDecayAudioEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaDecayAudioEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayAudioEditFieldLabel.Position = [101 172 116 22];
            app.AplhaDecayAudioEditFieldLabel.Text = 'Aplha Decay Audio:';

            % Create AplhaDecayAudio
            app.AplhaDecayAudio = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaDecayAudio.Limits = [0 Inf];
            app.AplhaDecayAudio.ValueDisplayFormat = '%.3f';
            app.AplhaDecayAudio.HorizontalAlignment = 'center';
            app.AplhaDecayAudio.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayAudio.Position = [223 170 114 22];
            app.AplhaDecayAudio.Value = 0.1;

            % Create AplhaDecayGainEditFieldLabel
            app.AplhaDecayGainEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaDecayGainEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayGainEditFieldLabel.Position = [101 117 108 22];
            app.AplhaDecayGainEditFieldLabel.Text = 'Aplha Decay Gain:';

            % Create AplhaDecayGain
            app.AplhaDecayGain = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaDecayGain.Limits = [0 Inf];
            app.AplhaDecayGain.ValueDisplayFormat = '%.3f';
            app.AplhaDecayGain.HorizontalAlignment = 'center';
            app.AplhaDecayGain.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayGain.Position = [223 115 114 22];
            app.AplhaDecayGain.Value = 0.1;

            % Create AplhaDecayLEDEditFieldLabel
            app.AplhaDecayLEDEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaDecayLEDEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayLEDEditFieldLabel.Position = [101 62 103 22];
            app.AplhaDecayLEDEditFieldLabel.Text = 'Aplha Decay LED:';

            % Create AplhaDecayLED
            app.AplhaDecayLED = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaDecayLED.Limits = [0 Inf];
            app.AplhaDecayLED.ValueDisplayFormat = '%.3f';
            app.AplhaDecayLED.HorizontalAlignment = 'center';
            app.AplhaDecayLED.FontName = 'Microsoft JhengHei UI';
            app.AplhaDecayLED.Position = [223 60 114 22];
            app.AplhaDecayLED.Value = 0.5;

            % Create MinFrequencyEditFieldLabel
            app.MinFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.MinFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.MinFrequencyEditFieldLabel.Position = [454 393 92 22];
            app.MinFrequencyEditFieldLabel.Text = 'Min Frequency:';

            % Create MinFrequency
            app.MinFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.MinFrequency.Limits = [0 Inf];
            app.MinFrequency.RoundFractionalValues = 'on';
            app.MinFrequency.ValueDisplayFormat = '%.0f';
            app.MinFrequency.HorizontalAlignment = 'center';
            app.MinFrequency.FontName = 'Microsoft JhengHei UI';
            app.MinFrequency.Position = [576 391 114 22];
            app.MinFrequency.Value = 50;

            % Create LeftFrequencyEditFieldLabel
            app.LeftFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.LeftFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.LeftFrequencyEditFieldLabel.Position = [454 337 123 22];
            app.LeftFrequencyEditFieldLabel.Text = 'Left Frequency:';

            % Create LeftFrequency
            app.LeftFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.LeftFrequency.Limits = [0 Inf];
            app.LeftFrequency.RoundFractionalValues = 'on';
            app.LeftFrequency.ValueDisplayFormat = '%.0f';
            app.LeftFrequency.HorizontalAlignment = 'center';
            app.LeftFrequency.FontName = 'Microsoft JhengHei UI';
            app.LeftFrequency.Position = [576 335 114 22];
            app.LeftFrequency.Value = 1500;

            % Create RightFrequencyEditFieldLabel
            app.RightFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.RightFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.RightFrequencyEditFieldLabel.Position = [454 281 106 22];
            app.RightFrequencyEditFieldLabel.Text = 'Right Frequency:';

            % Create RightFrequency
            app.RightFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.RightFrequency.Limits = [0 Inf];
            app.RightFrequency.RoundFractionalValues = 'on';
            app.RightFrequency.ValueDisplayFormat = '%.0f';
            app.RightFrequency.HorizontalAlignment = 'center';
            app.RightFrequency.FontName = 'Microsoft JhengHei UI';
            app.RightFrequency.Position = [576 279 114 22];
            app.RightFrequency.Value = 6000;

            % Create MaxFrequencyEditFieldLabel
            app.MaxFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.MaxFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.MaxFrequencyEditFieldLabel.Position = [454 226 106 22];
            app.MaxFrequencyEditFieldLabel.Text = 'Max Frequency:';

            % Create MaxFrequency
            app.MaxFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.MaxFrequency.Limits = [0 Inf];
            app.MaxFrequency.RoundFractionalValues = 'on';
            app.MaxFrequency.ValueDisplayFormat = '%.0f';
            app.MaxFrequency.HorizontalAlignment = 'center';
            app.MaxFrequency.FontName = 'Microsoft JhengHei UI';
            app.MaxFrequency.Position = [576 224 114 22];
            app.MaxFrequency.Value = 16000;

            % Create AplhaRiseAudioEditFieldLabel
            app.AplhaRiseAudioEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaRiseAudioEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseAudioEditFieldLabel.Position = [454 171 104 22];
            app.AplhaRiseAudioEditFieldLabel.Text = 'Aplha Rise Audio:';

            % Create AplhaRiseAudio
            app.AplhaRiseAudio = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaRiseAudio.Limits = [0 Inf];
            app.AplhaRiseAudio.ValueDisplayFormat = '%.3f';
            app.AplhaRiseAudio.HorizontalAlignment = 'center';
            app.AplhaRiseAudio.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseAudio.Position = [576 169 114 22];
            app.AplhaRiseAudio.Value = 0.92;

            % Create AplhaRiseGainEditFieldLabel
            app.AplhaRiseGainEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaRiseGainEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseGainEditFieldLabel.Position = [454 116 96 22];
            app.AplhaRiseGainEditFieldLabel.Text = 'Aplha Rise Gain:';

            % Create AplhaRiseGain
            app.AplhaRiseGain = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaRiseGain.Limits = [0 Inf];
            app.AplhaRiseGain.ValueDisplayFormat = '%.3f';
            app.AplhaRiseGain.HorizontalAlignment = 'center';
            app.AplhaRiseGain.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseGain.Position = [576 114 114 22];
            app.AplhaRiseGain.Value = 0.95;

            % Create AplhaRiseLEDEditFieldLabel
            app.AplhaRiseLEDEditFieldLabel = uilabel(app.PreferencesTab);
            app.AplhaRiseLEDEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseLEDEditFieldLabel.Position = [454 61 92 22];
            app.AplhaRiseLEDEditFieldLabel.Text = 'Aplha Rise LED:';

            % Create AplhaRiseLED
            app.AplhaRiseLED = uieditfield(app.PreferencesTab, 'numeric');
            app.AplhaRiseLED.Limits = [0 Inf];
            app.AplhaRiseLED.ValueDisplayFormat = '%.3f';
            app.AplhaRiseLED.HorizontalAlignment = 'center';
            app.AplhaRiseLED.FontName = 'Microsoft JhengHei UI';
            app.AplhaRiseLED.Position = [576 59 114 22];
            app.AplhaRiseLED.Value = 0.9;

            % Create AboutTab
            app.AboutTab = uitab(app.TabGroup);
            app.AboutTab.Title = 'About';

            % Create Image
            app.Image = uiimage(app.AboutTab);
            app.Image.Position = [272 24 227 100];
            app.Image.ImageSource = 'kp_black.png';

            % Create PreferenceMenu
            app.PreferenceMenu = uicontextmenu(app.audioControl);
            
            % Assign app.PreferenceMenu
            app.PreferencesTab.ContextMenu = app.PreferenceMenu;

            % Create SavePreferences
            app.SavePreferences = uimenu(app.PreferenceMenu);
            app.SavePreferences.MenuSelectedFcn = createCallbackFcn(app, @SavePreferencesMenuSelected, true);
            app.SavePreferences.Text = 'Save Preferences';

            % Create SettingsMenu
            app.SettingsMenu = uicontextmenu(app.audioControl);
            
            % Assign app.SettingsMenu
            app.ControlTab.ContextMenu = app.SettingsMenu;
            app.Panel.ContextMenu = app.SettingsMenu;

            % Create SaveSettings
            app.SaveSettings = uimenu(app.SettingsMenu);
            app.SaveSettings.MenuSelectedFcn = createCallbackFcn(app, @SavePreferencesMenuSelected, true);
            app.SaveSettings.Text = 'Save Settings';

            % Create PlotMenu
            app.PlotMenu = uicontextmenu(app.audioControl);
            
            % Assign app.PlotMenu
            app.FreqPlot.ContextMenu = app.PlotMenu;

            % Create EnablePlot
            app.EnablePlot = uimenu(app.PlotMenu);
            app.EnablePlot.MenuSelectedFcn = createCallbackFcn(app, @EnablePlotMenuSelected, true);
            app.EnablePlot.Text = 'Enable Plot';

            % Creating axis for frequency selection 
            app.freqAxis = axes(app.Panel,'Color','none','YColor','none','XLim',[20,20000],'YTick',[], ...
                    'XTick',0:1000:20000,'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.FreqSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.freqAxis);
            app.freqAxis.Toolbar.Visible = 'off';

            % Add the line for low frequency band
            app.lineLow = images.roi.Line(app.freqAxis,'Position',[app.MinFrequency.Value,0;app.LeftFrequency.Value,0],'Color',app.ColorOrder.Value(1));
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));

            % Add the line for mid frequency band
            app.lineMid = images.roi.Line(app.freqAxis,'Position',[app.LeftFrequency.Value,0;app.RightFrequency.Value,0],'Color',app.ColorOrder.Value(2));
            % Add a listener that will trigger a callback function titled "lineMidMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            addlistener(app.lineMid,'MovingROI',@(varargin)lineMidMoving(app,app.lineMid));

            % Add the line for high frequency band
            app.lineHigh = images.roi.Line(app.freqAxis,'Position',[app.RightFrequency.Value,0;app.MaxFrequency.Value,0],'Color',app.ColorOrder.Value(3));
            % Add a listener that will trigger a callback function titled "lMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            addlistener(app.lineHigh,'MovingROI',@(varargin)lineHighMoving(app,app.lineHigh));

            %SetPosition and value of labels
            app.minFreq.Position(1) = app.getPosition(app.MinFrequency.Value,app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.minFreq.Position(3));
            app.minFreq.Text = num2str(app.MinFrequency.Value);

            app.leftFreq.Position(1) = app.getPosition(app.LeftFrequency.Value,app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.leftFreq.Position(3));
            app.leftFreq.Text = num2str(app.LeftFrequency.Value);

            app.rightFreq.Position(1) = app.getPosition(app.RightFrequency.Value,app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.rightFreq.Position(3));
            app.rightFreq.Text = num2str(app.RightFrequency.Value);

            app.maxFreq.Position(1) = app.getPosition(app.MaxFrequency.Value,app.FreqSlider.Position(1),...
                                                        app.FreqSlider.Position(3),app.maxFreq.Position(3));
            app.maxFreq.Text = num2str(app.MaxFrequency.Value);

            % Creating axis for frequency selection 
            app.ledAxis = axes(app.Panel,'Color','none','YColor','none','XLim',[0,100],'YTick',[], ...
                    'XTick',0:20:100,'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.LEDSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.ledAxis);
            app.ledAxis.Toolbar.Visible = 'off';

            % Add the line for LED Brightness
            app.lineBright = images.roi.Line(app.ledAxis,'Position',[0,0; 100,0],'Color','C');
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.lineBright,'MovingROI',@(varargin)lineBrightMoving(app,app.lineBright));
            % Show the figure after all components are created

            app.audioControl.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = chromaticArduino

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.audioControl)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.audioControl)
        end
    end
end