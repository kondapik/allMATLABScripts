%{
%
    DECRIPTION:
    Displays audio

%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 13-June-2020
    LAST MODIFIED: 15-June-2020
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
        TargetFPSLabel                 matlab.ui.control.Label
        AudioFPS                       matlab.ui.control.NumericEditField
        NoofFFTbandsEditFieldLabel     matlab.ui.control.Label
        NoofFFTbands                   matlab.ui.control.NumericEditField
        GainLimitEditFieldLabel        matlab.ui.control.Label
        GainLimit                      matlab.ui.control.NumericEditField
        VolToleranceEditFieldLabel     matlab.ui.control.Label
        VolTolerance                   matlab.ui.control.NumericEditField
        AlphaDecayAudioEditFieldLabel  matlab.ui.control.Label
        AlphaDecayAudio                matlab.ui.control.NumericEditField
        AlphaDecayGainEditFieldLabel   matlab.ui.control.Label
        AlphaDecayGain                 matlab.ui.control.NumericEditField
        AlphaDecayLEDEditFieldLabel    matlab.ui.control.Label
        AlphaDecayLED                  matlab.ui.control.NumericEditField
        MinFrequencyEditFieldLabel     matlab.ui.control.Label
        MinFrequency                   matlab.ui.control.NumericEditField
        LowFrequencyLabel              matlab.ui.control.Label
        LeftFrequency                  matlab.ui.control.NumericEditField
        HighFrequencyLabel             matlab.ui.control.Label
        RightFrequency                 matlab.ui.control.NumericEditField
        MaxFrequencyEditFieldLabel     matlab.ui.control.Label
        MaxFrequency                   matlab.ui.control.NumericEditField
        AlphaRiseAudioEditFieldLabel   matlab.ui.control.Label
        AlphaRiseAudio                 matlab.ui.control.NumericEditField
        AlphaRiseGainEditFieldLabel    matlab.ui.control.Label
        AlphaRiseGain                  matlab.ui.control.NumericEditField
        AlphaRiseLEDEditFieldLabel     matlab.ui.control.Label
        AlphaRiseLED                   matlab.ui.control.NumericEditField
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
        redCtrlAxis;
        redCtrl;
        blueCtrlAxis;
        blueCtrl;
        greenCtrlAxis;
        greenCtrl;
        speedCtrlAxis;
        speedCtrl;

        audioReader;
        arduinoBoard;
        displayPlot;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.audioReader = audioDeviceReader();
            app.AudioDevice.Items = getAudioDevices(app.audioReader);

            app.arduinoBoard = arduino();
            app.RedPin.Items = app.arduinoBoard.AvailablePWMPins;
            app.BluePin.Items = app.arduinoBoard.AvailablePWMPins;
            app.GreenPin.Items = app.arduinoBoard.AvailablePWMPins;

            if exist(fullfile(getenv('APPDATA'), 'chromaticArduino','preferences.json')) ~= 0
                dataValues = jsondecode(fileread(fullfile(getenv('APPDATA'), 'chromaticArduino','preferences.json')));
                app.RedPin.Value = dataValues.RedPin;
                app.GreenPin.Value = dataValues.GreenPin;
                app.BluePin.Value = dataValues.BluePin;
                app.ColorOrder.Value = dataValues.ColorOrder;
                app.speedCtrl.Position(2,1) = dataValues.LEDSpeed;
                app.lineBright.Position(2,1) = dataValues.LEDBrightness;
                app.AudioFPS.Value = dataValues.TargetFPS;
                app.NoofFFTbands.Value = dataValues.NoOfFFTBands; 
                app.GainLimit.Value = dataValues.GainLimit;
                app.VolTolerance.Value = dataValues.VolumeTolerance;
                app.AlphaDecayLED.Value = dataValues.AlphaDecayLED;
                app.AlphaRiseLED.Value = dataValues.AlphaRiseLED;
                app.MinFrequency.Value = dataValues.MinimumFrequency;
                app.LeftFrequency.Value = dataValues.LowFrequency;
                app.RightFrequency.Value = dataValues.HighFrequency;
                app.MaxFrequency.Value = dataValues.MaximumFrequency;
                app.AlphaDecayAudio.Value = dataValues.AlphaDecayAudio;
                app.AlphaRiseAudio.Value = dataValues.AlphaRiseAudio;
                app.AlphaDecayGain.Value = dataValues.AlphaDecayGain;
                app.AlphaRiseGain.Value = dataValues.AlphaRiseGain;

                app.lineLow.Position(1,1) = app.MinFrequency.Value;
                app.lineLow.Position(2,1) = app.LeftFrequency.Value;
                lineLowMoving(app,app.lineLow);

                app.lineMid.Position(1,1) = app.LeftFrequency.Value;
                app.lineMid.Position(2,1) = app.RightFrequency.Value;
                lineMidMoving(app,app.lineMid);

                app.lineHigh.Position(1,1) = app.RightFrequency.Value;
                app.lineHigh.Position(2,1) = app.MaxFrequency.Value;
                lineHighMoving(app,app.lineHigh);
            else
                mkdir(fullfile(getenv('APPDATA'), 'chromaticArduino'));
                SavePreferencesMenuSelected(app);
            end
        end

        % Close request function: audioControl
        function audioControlCloseRequest(app, event)
            SavePreferencesMenuSelected(app, event);
            delete(app)
        end

        % Menu selected function: SavePreferences, SaveSettings
        function SavePreferencesMenuSelected(app, ~)
            %disp('Saving Preference')
            dataValues = struct('RedPin', app.RedPin.Value, 'GreenPin', app.GreenPin.Value, 'BluePin', app.BluePin.Value, 'ColorOrder', app.ColorOrder.Value,'LEDSpeed', app.speedCtrl.Position(2,1),...
                                'LEDBrightness', app.lineBright.Position(2,1), 'TargetFPS', app.AudioFPS.Value, 'NoOfFFTBands', app.NoofFFTbands.Value, 'GainLimit', app.GainLimit.Value,...
                                'VolumeTolerance', app.VolTolerance.Value, 'AlphaDecayLED', app.AlphaDecayLED.Value,'AlphaRiseLED', app.AlphaRiseLED.Value,...
                                'MinimumFrequency', app.MinFrequency.Value, 'LowFrequency', app.LeftFrequency.Value, 'HighFrequency', app.RightFrequency.Value, 'MaximumFrequency', app.MaxFrequency.Value,...
                                'AlphaDecayAudio', app.AlphaDecayAudio.Value,'AlphaRiseAudio', app.AlphaRiseAudio.Value,'AlphaDecayGain', app.AlphaDecayGain.Value,'AlphaRiseGain', app.AlphaRiseGain.Value);
            jsonStr = jsonencode(dataValues);
            fid = fopen(fullfile(getenv('APPDATA'), 'chromaticArduino','preferences.json'), 'w');
            if fid == -1, error('Cannot create JSON file'); end
            fwrite(fid, jsonStr, 'char');
            fclose(fid);
            %fullfile(getenv('APPDATA'), 'New')
        end

        % Menu selected function: EnablePlot
        function EnablePlotMenuSelected(app, ~)
            if isequal(app.EnablePlot.Text, 'Enable Plot')
                app.EnablePlot.Text = 'Disable Plot';
                app.displayPlot = true;
            else
                app.EnablePlot.Text = 'Enable Plot';
                app.displayPlot = false;
            end
        end

        % Value changed function: StartButton
        function StartButtonValueChanged(app, ~)
            lowValue = 0.1;
            midValue = 0.1;
            highValue = 0.1;
            gainValue = app.GainLimit.Value;
            micRate = 44100;
            numOfFrames = round(micRate/app.AudioFPS.Value);
            app.audioReader = audioDeviceReader('Device',app.AudioDevice.Value,'SamplesPerFrame',numOfFrames);
            audioData = zeros(numOfFrames,1);

            sineTime = 0;
            elapsedTime = 0;
            fpsCounterTime = 0;
            fpsCount = 0;

            if app.StartButton.Value
                app.StartButton.Text = 'Stop';
                app.StartButton.BackgroundColor = [1 0 0];
                app.StartButton.Tooltip = {'Stop controlling arduino'};
                app.StartButton.FontColor = [1 1 1];
            else
                app.StartButton.Text = 'Start';
                app.StartButton.BackgroundColor = [0 0.902 0];
                app.StartButton.Tooltip = {'Start controlling arduino'};
                app.StartButton.FontColor = [0 0 0];
            end
            
            fpsTimer = tic;

            while app.StartButton.Value
                
                if app.FPSCheckBox.Value
                    fpsTimer = tic;
                else
                    app.FPSCheckBox.Text = '  FPS:';
                end

                if app.AudioButton.Value
                    audioData = app.expGain(app.audioReader(), audioData, app.AlphaDecayAudio.Value, app.AlphaRiseAudio.Value);
                    hammedAudio = hamming(numOfFrames).*audioData;
                    [melValues,cntFreq,~] = melSpectrogram(hammedAudio,44100,'WindowLength',numOfFrames,...
                                                    'OverlapLength',round(numOfFrames/2),'NumBands',app.NoofFFTbands.Value,...
                                                    'FrequencyRange',[app.MinFrequency.Value app.MaxFrequency.Value]);
                    
                    if max(melValues) > app.VolTolerance.Value

                        if max(melValues) > app.GainLimit.Value 
                            gainValue = app.expGain(max(melValues),gainValue,app.AlphaDecayGain.Value,app.AlphaRiseGain.Value);
                        else
                            gainValue = app.expGain(app.GainLimit.Value,gainValue,app.AlphaDecayGain.Value,app.AlphaRiseGain.Value);
                        end

                        melValues = melValues / gainValue;

                        leftIndex = round(app.mapValue(app.LeftFrequency.Value, app.MinFrequency.Value, app.MaxFrequency.Value, 1, app.NoofFFTbands.Value));
                        rightIndex = round(app.mapValue(app.RightFrequency.Value, app.MinFrequency.Value, app.MaxFrequency.Value, 1, app.NoofFFTbands.Value));
                        
                        lowBand = max(melValues(1 : leftIndex));
                        midBand = max(melValues(leftIndex : rightIndex));
                        highBand = max(melValues(rightIndex : app.NoofFFTbands.Value));

                        lowValue = app.expGain(lowBand, lowValue, app.AlphaDecayLED.Value, app.AlphaRiseLED.Value);
                        midValue = app.expGain(midBand, midValue, app.AlphaDecayLED.Value, app.AlphaRiseLED.Value);
                        highValue = app.expGain(highBand, highValue, app.AlphaDecayLED.Value, app.AlphaRiseLED.Value);

                        orderMap = containers.Map({app.ColorOrder.Value(1), app.ColorOrder.Value(2), app.ColorOrder.Value(3)},...
                                            {lowValue, midValue, highValue});
                        
                        writePWMDutyCycle(app.arduinoBoard, app.RedPin.Value, app.setMax(orderMap('R'),1) * app.lineBright.Position(2,1) / 100);
                        writePWMDutyCycle(app.arduinoBoard, app.GreenPin.Value, app.setMax(orderMap('G'),1) * app.lineBright.Position(2,1) / 100);
                        writePWMDutyCycle(app.arduinoBoard, app.BluePin.Value, app.setMax(orderMap('B'),1) * app.lineBright.Position(2,1) / 100);

                        if app.displayPlot
                            plot(app.FreqPlot, cntFreq(1 : leftIndex), melValues(1 : leftIndex), app.ColorOrder.Value(1),...
                                        cntFreq(leftIndex : rightIndex), melValues(leftIndex : rightIndex), app.ColorOrder.Value(2),...
                                        cntFreq(rightIndex : app.NoofFFTbands.Value), melValues(rightIndex : app.NoofFFTbands.Value), app.ColorOrder.Value(3));
                        end
                    else
                        writePWMDutyCycle(app.arduinoBoard, app.RedPin.Value, 0);
                        writePWMDutyCycle(app.arduinoBoard, app.GreenPin.Value, 0);
                        writePWMDutyCycle(app.arduinoBoard, app.BluePin.Value, 0);
                    end
                elseif app.RainbowButton.Value
                    dispTimer = tic;
                    pause(1 / app.AudioFPS.Value)
                    sineValue = (2 * pi * sineTime * 2) / ((101 - app.speedCtrl.Position(2,1)) * app.AudioFPS.Value);
                    writePWMDutyCycle(app.arduinoBoard,app.RedPin.Value,abs(sin(sineValue) * app.lineBright.Position(2,1) / 100));
                    writePWMDutyCycle(app.arduinoBoard,app.GreenPin.Value,abs(sin(sineValue + (pi / 3)) * app.lineBright.Position(2,1) / 100));
                    writePWMDutyCycle(app.arduinoBoard,app.BluePin.Value,abs(sin(sineValue + (2 * pi / 3)) * app.lineBright.Position(2,1) / 100));

                    elapsedTime = elapsedTime + toc(dispTimer);
                    if elapsedTime > 0.1 
                        app.redCtrl.Position(2,1) = abs(sin(sineValue)) * 255;
                        app.greenCtrl.Position(2,1) = abs(sin(sineValue + (pi / 3))) * 255;
                        app.blueCtrl.Position(2,1) = abs(sin(sineValue + (2 * pi / 3))) * 255;
                        elapsedTime = 0;
                    end
                    
                    sineTime = sineTime + 1;
                else
                    pause(1)
                    writePWMDutyCycle(app.arduinoBoard, app.RedPin.Value, (app.redCtrl.Position(2,1) / 255) * (app.lineBright.Position(2,1) / 100));
                    writePWMDutyCycle(app.arduinoBoard, app.GreenPin.Value, (app.greenCtrl.Position(2,1) / 255) * (app.lineBright.Position(2,1) / 100));
                    writePWMDutyCycle(app.arduinoBoard, app.BluePin.Value, (app.blueCtrl.Position(2,1) / 255) * (app.lineBright.Position(2,1) / 100));
                end

                if app.FPSCheckBox.Value
                    fpsCounterTime = fpsCounterTime + toc(fpsTimer);
                    if fpsCounterTime < 1
                        fpsCount = fpsCount + 1;
                    else
                        app.FPSCheckBox.Text = sprintf('  FPS: %d/%d',fpsCount, app.AudioFPS.Value);
                        fpsCount = 0;
                        fpsCounterTime = 0;
                    end
                end
            end
        end

        % Value changed function: ColorOrder
        function ColorOrderValueChanged(app, ~)
            app.lineLow.Color = app.ColorOrder.Value(1);
            app.lineMid.Color = app.ColorOrder.Value(2);
            app.lineHigh.Color = app.ColorOrder.Value(3);
            drawnow;
        end

        % Value changed function: LeftFrequency, MaxFrequency, 
        % MinFrequency, RightFrequency
        function FrequencyValueChanged(app, event)
            if isequal(event.Source.Tag, 'minFreq') && (app.MinFrequency.Value >= app.LeftFrequency.Value - 200)
                app.MinFrequency.Value = event.PreviousValue;
            elseif isequal(event.Source.Tag, 'leftFreq') && ((app.MinFrequency.Value >= app.LeftFrequency.Value - 200) || (app.LeftFrequency.Value >= app.RightFrequency.Value - 200))
                app.LeftFrequency.Value = event.PreviousValue;
            elseif isequal(event.Source.Tag, 'rightFreq') && ((app.LeftFrequency.Value >= app.RightFrequency.Value - 200) || (app.RightFrequency.Value >= app.MaxFrequency.Value - 200))
                app.RightFrequency.Value = event.PreviousValue;
            elseif isequal(event.Source.Tag, 'maxFreq') && (app.RightFrequency.Value >= app.MaxFrequency.Value - 200)
                app.MaxFrequency.Value = event.PreviousValue;
            end

            app.lineLow.Position(1,1) = app.MinFrequency.Value;
            app.lineLow.Position(2,1) = app.LeftFrequency.Value;
            lineLowMoving(app,app.lineLow);

            app.lineMid.Position(1,1) = app.LeftFrequency.Value;
            app.lineMid.Position(2,1) = app.RightFrequency.Value;
            lineMidMoving(app,app.lineMid);

            app.lineHigh.Position(1,1) = app.RightFrequency.Value;
            app.lineHigh.Position(2,1) = app.MaxFrequency.Value;
            lineHighMoving(app,app.lineHigh);
        end

        % Value changed function: BluePin, GreenPin, RedPin
        function LEDPinValueChanged(app, event)
            if isequal(event.Source.Tag, 'redPin') && (isequal(event.Value,app.GreenPin.Value) || isequal(event.Value,app.BluePin.Value))
                app.RedPin.Value = event.PreviousValue;
            elseif isequal(event.Source.Tag, 'greenPin') && (isequal(event.Value,app.RedPin.Value) || isequal(event.Value,app.BluePin.Value))
                app.GreenPin.Value = event.PreviousValue;
            elseif isequal(event.Source.Tag, 'bluePin') && (isequal(event.Value,app.GreenPin.Value) || isequal(event.Value,app.RedPin.Value))
                app.BluePin.Value = event.PreviousValue;
            end
        end

        % Selection changed function: ModeGroup
        function ModeSelectionChanged(app, ~)
            selectedButton = app.ModeGroup.SelectedObject;
            if isequal(selectedButton.Text, 'Audio')
                app.FreqPlot.Visible = 'on';
                app.ColorControl.Visible = 'off';
                app.lineLow.InteractionsAllowed = 'all';
                app.lineMid.InteractionsAllowed = 'all';
                app.lineHigh.InteractionsAllowed = 'all';
            elseif isequal(selectedButton.Text, 'Rainbow')
                app.FreqPlot.Visible = 'off';
                app.ColorControl.Visible = 'on';
                app.lineLow.InteractionsAllowed = 'none';
                app.lineMid.InteractionsAllowed = 'none';
                app.lineHigh.InteractionsAllowed = 'none';
            else
                app.FreqPlot.Visible = 'off';
                app.ColorControl.Visible = 'on';
                app.lineLow.InteractionsAllowed = 'none';
                app.lineMid.InteractionsAllowed = 'none';
                app.lineHigh.InteractionsAllowed = 'none';
            end
            drawnow;
        end

        % Value changed function: AudioDevice
        function AudioDeviceValueChanged(app, ~)
            app.audioReader = audioDeviceReader('Device',app.AudioDevice.Value,'SamplesPerFrame',round(44100 / app.AudioFPS.Value));
        end

        function lineLowMoving(app,source)
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;

            % Stopping before minFreq is crossed
            if source.Position(1,1) > source.Position(2,1)
                source.Position(1,1) = source.Position(2,1) - 200;  
            end

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

            % Stopping before leftFreq is higher than rightFreq
            if source.Position(1,1) > source.Position(2,1)
                source.Position(1,1) = source.Position(2,1) - 200;  
            end

            % Stopping before minFreq is crossed 
            if app.lineLow.Position(1,1) > source.Position(1,1)
                source.Position(1,1) = app.lineLow.Position(1,1) + 200;  
            end

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

            % Stopping before maxFreq or rightFreq are crossed 
            if (source.Position(1,1) > source.Position(2,1)) && (source.Position(1,1) > app.lineMid.Position(2,1))
                source.Position(1,1) = source.Position(2,1) - 200;
            elseif source.Position(2,1) < source.Position(1,1)
                source.Position(2,1) = source.Position(1,1) + 200;   
            end

            % Stopping before rightFreq is crossed 
            if app.lineMid.Position(1,1) > source.Position(1,1)
                source.Position(1,1) = app.lineMid.Position(1,1) + 200;  
            end

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

        function lineRedMoving(~,source)
            source.Position(1,1) = 0;
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;
        end

        function lineGreenMoving(~,source)
            source.Position(1,1) = 0;
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;
        end

        function lineBlueMoving(~,source)
            source.Position(1,1) = 0;
            source.Position(1,2) = 0;
            source.Position(2,2) = 0;
        end

        function lineSpeedMoving(~,source)
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

        function newValue = expGain(value, oldValue, alphaDecay, alphaRise)
            %exponential decay function
            if value > oldValue
                alphaValue = alphaRise;
            else
                alphaValue = alphaDecay;
            end
            newValue = alphaValue .* value + (1 - alphaValue) .* oldValue;
        end

        function newValue = setMax(value,maxValue)
            %Set upper limit to the value
            if value > maxValue
                newValue = maxValue;
            else
                newValue = value;
            end
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
            app.ModeGroup.SelectionChangedFcn = createCallbackFcn(app, @ModeSelectionChanged, true);
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
            app.FreqSlider.Enable = 'off';
            app.FreqSlider.Visible = 'off';
            app.FreqSlider.Tooltip = {'Select Frequency Ranges for Audio Analysis'};
            app.FreqSlider.Position = [33 59 714 3];

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
            app.ColorOrder.Items = {'RRR', 'RRG', 'RRB', 'RGR', 'RGG', 'RGB', 'RBR', 'RBG', 'RBB',...
                                    'GRR', 'GRG', 'GRB', 'GGR', 'GGG', 'GGB', 'GBR', 'GBG', 'GBB',...
                                    'BRR', 'BRG', 'BRB', 'BGR', 'BGG', 'BGB', 'BBR', 'BBG', 'BBB'};
            app.ColorOrder.ValueChangedFcn = createCallbackFcn(app, @ColorOrderValueChanged, true);
            app.ColorOrder.Tooltip = {'Select the color order for low, mid and high frequency ranges'};
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
            app.LEDSlider.Enable = 'off';
            app.LEDSlider.Visible = 'off';
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
            app.minFreq.Position = [-3 72 72 22];
            app.minFreq.Text = '20';

            % Create leftFreq
            app.leftFreq = uilabel(app.Panel);
            app.leftFreq.HorizontalAlignment = 'center';
            app.leftFreq.FontName = 'Microsoft JhengHei UI';
            app.leftFreq.Position = [91 72 72 22];
            app.leftFreq.Text = '1500';

            % Create rightFreq
            app.rightFreq = uilabel(app.Panel);
            app.rightFreq.HorizontalAlignment = 'center';
            app.rightFreq.FontName = 'Microsoft JhengHei UI';
            app.rightFreq.Position = [236 72 72 22];
            app.rightFreq.Text = '6000';

            % Create maxFreq
            app.maxFreq = uilabel(app.Panel);
            app.maxFreq.HorizontalAlignment = 'center';
            app.maxFreq.FontName = 'Microsoft JhengHei UI';
            app.maxFreq.Position = [399 72 72 22];
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
            app.RedSlider.Position = [87 147 422 3];

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
            app.GreenSlider.Position = [87 110 422 3];

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
            app.BlueSlider.Position = [87 72 422 3];

            % Create SpeedSliderLabel
            app.SpeedSliderLabel = uilabel(app.ColorControl);
            app.SpeedSliderLabel.HorizontalAlignment = 'right';
            app.SpeedSliderLabel.FontName = 'Microsoft JhengHei UI';
            app.SpeedSliderLabel.Position = [79 25 44 22];
            app.SpeedSliderLabel.Text = 'Speed:';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.ColorControl);
            app.SpeedSlider.Visible = 'off';
            app.SpeedSlider.Tooltip = {'Color cycle speed'};
            app.SpeedSlider.FontName = 'Microsoft JhengHei UI';
            app.SpeedSlider.Position = [144 35 320 3];

            % Create RedDropDownLabel
            app.RedDropDownLabel = uilabel(app.ControlTab);
            app.RedDropDownLabel.HorizontalAlignment = 'right';
            app.RedDropDownLabel.VerticalAlignment = 'top';
            app.RedDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.RedDropDownLabel.Tooltip = {''};
            app.RedDropDownLabel.Position = [448 434 30 22];
            app.RedDropDownLabel.Text = 'Red:';

            % Create RedDropDownLabel
            app.RedDropDownLabel = uilabel(app.ControlTab);
            app.RedDropDownLabel.HorizontalAlignment = 'right';
            app.RedDropDownLabel.VerticalAlignment = 'top';
            app.RedDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.RedDropDownLabel.Tooltip = {''};
            app.RedDropDownLabel.Position = [448 434 30 22];
            app.RedDropDownLabel.Text = 'Red:';

            % Create RedPin
            app.RedPin = uidropdown(app.ControlTab);
            app.RedPin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.RedPin.ValueChangedFcn = createCallbackFcn(app, @LEDPinValueChanged, true);
            app.RedPin.Tag = 'redPin';
            app.RedPin.Tooltip = {'Select PWM pin of red LED'};
            app.RedPin.FontName = 'Microsoft JhengHei UI';
            app.RedPin.Position = [486 435 55 22];
            app.RedPin.Value = 'D9';

            % Create GreenDropDownLabel
            app.GreenDropDownLabel = uilabel(app.ControlTab);
            app.GreenDropDownLabel.HorizontalAlignment = 'right';
            app.GreenDropDownLabel.VerticalAlignment = 'top';
            app.GreenDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.GreenDropDownLabel.Tooltip = {''};
            app.GreenDropDownLabel.Position = [554 434 42 22];
            app.GreenDropDownLabel.Text = 'Green:';

            % Create GreenPin
            app.GreenPin = uidropdown(app.ControlTab);
            app.GreenPin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.GreenPin.ValueChangedFcn = createCallbackFcn(app, @LEDPinValueChanged, true);
            app.GreenPin.Tag = 'greenPin';
            app.GreenPin.Tooltip = {'Select PWM pin of green LED'};
            app.GreenPin.FontName = 'Microsoft JhengHei UI';
            app.GreenPin.Position = [604 435 55 22];
            app.GreenPin.Value = 'D10';

            % Create BlueDropDownLabel
            app.BlueDropDownLabel = uilabel(app.ControlTab);
            app.BlueDropDownLabel.HorizontalAlignment = 'right';
            app.BlueDropDownLabel.VerticalAlignment = 'top';
            app.BlueDropDownLabel.FontName = 'Microsoft JhengHei UI';
            app.BlueDropDownLabel.Tooltip = {''};
            app.BlueDropDownLabel.Position = [671 434 33 22];
            app.BlueDropDownLabel.Text = 'Blue:';

            % Create BluePin
            app.BluePin = uidropdown(app.ControlTab);
            app.BluePin.Items = {'D3', 'D5', 'D6', 'D9', 'D10', 'D11'};
            app.BluePin.ValueChangedFcn = createCallbackFcn(app, @LEDPinValueChanged, true);
            app.BluePin.Tag = 'bluePin';
            app.BluePin.Tooltip = {'Select PWM pin of blue LED'};
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
            app.AudioDevice.ValueChangedFcn = createCallbackFcn(app, @AudioDeviceValueChanged, true);
            app.AudioDevice.Tooltip = {'Audio source for analysis'};
            app.AudioDevice.FontName = 'Microsoft JhengHei UI';
            app.AudioDevice.Position = [262 434 153 22];
            app.AudioDevice.Value = 'Default';

            % Create StartButton
            app.StartButton = uibutton(app.ControlTab, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonValueChanged, true);
            app.StartButton.Tooltip = {'Start controlling arduino'};
            app.StartButton.IconAlignment = 'center';
            app.StartButton.Text = 'Start';
            app.StartButton.BackgroundColor = [0 0.902 0];
            app.StartButton.FontName = 'Microsoft JhengHei UI';
            app.StartButton.Position = [40 435 100 23];

            % Create PreferencesTab
            app.PreferencesTab = uitab(app.TabGroup);
            app.PreferencesTab.Title = 'Preferences';

            % Create TargetFPSLabel
            app.TargetFPSLabel = uilabel(app.PreferencesTab);
            app.TargetFPSLabel.FontName = 'Microsoft JhengHei UI';
            app.TargetFPSLabel.Position = [101 394 106 22];
            app.TargetFPSLabel.Text = 'Target FPS:';

            % Create AudioFPS
            app.AudioFPS = uieditfield(app.PreferencesTab, 'numeric');
            app.AudioFPS.Limits = [0 Inf];
            app.AudioFPS.RoundFractionalValues = 'on';
            app.AudioFPS.ValueDisplayFormat = '%.0f';
            app.AudioFPS.HorizontalAlignment = 'center';
            app.AudioFPS.FontName = 'Microsoft JhengHei UI';
            app.AudioFPS.Tooltip = {'Target FPS to drive LEDs in audio mode.'};
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
            app.NoofFFTbands.Tooltip = {'Number of frequency bins to use when transforming audio to frequency domain'};
            app.NoofFFTbands.Position = [223 336 114 22];
            app.NoofFFTbands.Value = 24;

            % Create GainLimitEditFieldLabel
            app.GainLimitEditFieldLabel = uilabel(app.PreferencesTab);
            app.GainLimitEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.GainLimitEditFieldLabel.Position = [101 282 106 22];
            app.GainLimitEditFieldLabel.Text = 'Gain Limit:';

            % Create GainLimit
            app.GainLimit = uieditfield(app.PreferencesTab, 'numeric');
            app.GainLimit.Limits = [0 1];
            app.GainLimit.ValueDisplayFormat = '%.7f';
            app.GainLimit.HorizontalAlignment = 'center';
            app.GainLimit.FontName = 'Microsoft JhengHei UI';
            app.GainLimit.Tooltip = {'A lower limit to filter bank output gain. Better let it alone.'};
            app.GainLimit.Position = [223 280 114 22];
            app.GainLimit.Value = 5e-06;

            % Create VolToleranceEditFieldLabel
            app.VolToleranceEditFieldLabel = uilabel(app.PreferencesTab);
            app.VolToleranceEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.VolToleranceEditFieldLabel.Position = [101 227 106 22];
            app.VolToleranceEditFieldLabel.Text = 'Vol Tolerance:';

            % Create VolTolerance
            app.VolTolerance = uieditfield(app.PreferencesTab, 'numeric');
            app.VolTolerance.Limits = [0 1];
            app.VolTolerance.ValueDisplayFormat = '%.13f';
            app.VolTolerance.HorizontalAlignment = 'center';
            app.VolTolerance.FontName = 'Microsoft JhengHei UI';
            app.VolTolerance.Tooltip = {'No music visualization displayed if recorded audio volume below threshold'};
            app.VolTolerance.Position = [223 225 114 22];
            app.VolTolerance.Value = 1e-12;

            % Create AlphaDecayAudioEditFieldLabel
            app.AlphaDecayAudioEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaDecayAudioEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayAudioEditFieldLabel.Position = [101 172 116 22];
            app.AlphaDecayAudioEditFieldLabel.Text = 'Alpha Decay Audio:';

            % Create AlphaDecayAudio
            app.AlphaDecayAudio = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaDecayAudio.Limits = [0 1];
            app.AlphaDecayAudio.ValueDisplayFormat = '%.3f';
            app.AlphaDecayAudio.HorizontalAlignment = 'center';
            app.AlphaDecayAudio.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayAudio.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaDecayAudio.Position = [223 170 114 22];
            app.AlphaDecayAudio.Value = 0.8;

            % Create AlphaDecayGainEditFieldLabel
            app.AlphaDecayGainEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaDecayGainEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayGainEditFieldLabel.Position = [101 117 108 22];
            app.AlphaDecayGainEditFieldLabel.Text = 'Alpha Decay Gain:';

            % Create AlphaDecayGain
            app.AlphaDecayGain = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaDecayGain.Limits = [0 1];
            app.AlphaDecayGain.ValueDisplayFormat = '%.3f';
            app.AlphaDecayGain.HorizontalAlignment = 'center';
            app.AlphaDecayGain.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayGain.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaDecayGain.Position = [223 115 114 22];
            app.AlphaDecayGain.Value = 0.1;

            % Create AlphaDecayLEDEditFieldLabel
            app.AlphaDecayLEDEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaDecayLEDEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayLEDEditFieldLabel.Position = [101 62 103 22];
            app.AlphaDecayLEDEditFieldLabel.Text = 'Alpha Decay LED:';

            % Create AlphaDecayLED
            app.AlphaDecayLED = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaDecayLED.Limits = [0 1];
            app.AlphaDecayLED.ValueDisplayFormat = '%.3f';
            app.AlphaDecayLED.HorizontalAlignment = 'center';
            app.AlphaDecayLED.FontName = 'Microsoft JhengHei UI';
            app.AlphaDecayLED.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaDecayLED.Position = [223 60 114 22];
            app.AlphaDecayLED.Value = 0.5;

            % Create MinFrequencyEditFieldLabel
            app.MinFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.MinFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.MinFrequencyEditFieldLabel.Position = [454 393 92 22];
            app.MinFrequencyEditFieldLabel.Text = 'Min Frequency:';

            % Create MinFrequency
            app.MinFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.MinFrequency.Limits = [20 20000];
            app.MinFrequency.RoundFractionalValues = 'on';
            app.MinFrequency.ValueDisplayFormat = '%.0f';
            app.MinFrequency.ValueChangedFcn = createCallbackFcn(app, @FrequencyValueChanged, true);
            app.MinFrequency.Tag = 'minFreq';
            app.MinFrequency.HorizontalAlignment = 'center';
            app.MinFrequency.FontName = 'Microsoft JhengHei UI';
            app.MinFrequency.Tooltip = {'Frequencies below this value will be removed during audio processing'};
            app.MinFrequency.Position = [576 391 114 22];
            app.MinFrequency.Value = 50;

            % Create LowFrequencyLabel
            app.LowFrequencyLabel = uilabel(app.PreferencesTab);
            app.LowFrequencyLabel.FontName = 'Microsoft JhengHei UI';
            app.LowFrequencyLabel.Position = [454 337 123 22];
            app.LowFrequencyLabel.Text = 'Low Frequency:';

            % Create LeftFrequency
            app.LeftFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.LeftFrequency.Limits = [20 20000];
            app.LeftFrequency.RoundFractionalValues = 'on';
            app.LeftFrequency.ValueDisplayFormat = '%.0f';
            app.LeftFrequency.ValueChangedFcn = createCallbackFcn(app, @FrequencyValueChanged, true);
            app.LeftFrequency.Tag = 'leftFreq';
            app.LeftFrequency.HorizontalAlignment = 'center';
            app.LeftFrequency.FontName = 'Microsoft JhengHei UI';
            app.LeftFrequency.Tooltip = {'Upper limit for low frequency range'};
            app.LeftFrequency.Position = [576 335 114 22];
            app.LeftFrequency.Value = 1500;

            % Create HighFrequencyLabel
            app.HighFrequencyLabel = uilabel(app.PreferencesTab);
            app.HighFrequencyLabel.FontName = 'Microsoft JhengHei UI';
            app.HighFrequencyLabel.Position = [454 281 106 22];
            app.HighFrequencyLabel.Text = 'High Frequency:';

            % Create RightFrequency
            app.RightFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.RightFrequency.Limits = [20 20000];
            app.RightFrequency.RoundFractionalValues = 'on';
            app.RightFrequency.ValueDisplayFormat = '%.0f';
            app.RightFrequency.ValueChangedFcn = createCallbackFcn(app, @FrequencyValueChanged, true);
            app.RightFrequency.Tag = 'rightFreq';
            app.RightFrequency.HorizontalAlignment = 'center';
            app.RightFrequency.FontName = 'Microsoft JhengHei UI';
            app.RightFrequency.Tooltip = {'Lower limit for high frequncy range'};
            app.RightFrequency.Position = [576 279 114 22];
            app.RightFrequency.Value = 6000;

            % Create MaxFrequencyEditFieldLabel
            app.MaxFrequencyEditFieldLabel = uilabel(app.PreferencesTab);
            app.MaxFrequencyEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.MaxFrequencyEditFieldLabel.Position = [454 226 106 22];
            app.MaxFrequencyEditFieldLabel.Text = 'Max Frequency:';

            % Create MaxFrequency
            app.MaxFrequency = uieditfield(app.PreferencesTab, 'numeric');
            app.MaxFrequency.Limits = [20 20000];
            app.MaxFrequency.RoundFractionalValues = 'on';
            app.MaxFrequency.ValueDisplayFormat = '%.0f';
            app.MaxFrequency.ValueChangedFcn = createCallbackFcn(app, @FrequencyValueChanged, true);
            app.MaxFrequency.Tag = 'maxFreq';
            app.MaxFrequency.HorizontalAlignment = 'center';
            app.MaxFrequency.FontName = 'Microsoft JhengHei UI';
            app.MaxFrequency.Tooltip = {'Frequencies above this value will be removed during audio processing'};
            app.MaxFrequency.Position = [576 224 114 22];
            app.MaxFrequency.Value = 16000;

            % Create AlphaRiseAudioEditFieldLabel
            app.AlphaRiseAudioEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaRiseAudioEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseAudioEditFieldLabel.Position = [454 171 104 22];
            app.AlphaRiseAudioEditFieldLabel.Text = 'Alpha Rise Audio:';

            % Create AlphaRiseAudio
            app.AlphaRiseAudio = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaRiseAudio.Limits = [0 1];
            app.AlphaRiseAudio.ValueDisplayFormat = '%.3f';
            app.AlphaRiseAudio.HorizontalAlignment = 'center';
            app.AlphaRiseAudio.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseAudio.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaRiseAudio.Position = [576 169 114 22];
            app.AlphaRiseAudio.Value = 0.92;

            % Create AlphaRiseGainEditFieldLabel
            app.AlphaRiseGainEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaRiseGainEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseGainEditFieldLabel.Position = [454 116 96 22];
            app.AlphaRiseGainEditFieldLabel.Text = 'Alpha Rise Gain:';

            % Create AlphaRiseGain
            app.AlphaRiseGain = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaRiseGain.Limits = [0 1];
            app.AlphaRiseGain.ValueDisplayFormat = '%.3f';
            app.AlphaRiseGain.HorizontalAlignment = 'center';
            app.AlphaRiseGain.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseGain.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaRiseGain.Position = [576 114 114 22];
            app.AlphaRiseGain.Value = 0.95;

            % Create AlphaRiseLEDEditFieldLabel
            app.AlphaRiseLEDEditFieldLabel = uilabel(app.PreferencesTab);
            app.AlphaRiseLEDEditFieldLabel.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseLEDEditFieldLabel.Position = [454 61 92 22];
            app.AlphaRiseLEDEditFieldLabel.Text = 'Alpha Rise LED:';

            % Create AlphaRiseLED
            app.AlphaRiseLED = uieditfield(app.PreferencesTab, 'numeric');
            app.AlphaRiseLED.Limits = [0 1];
            app.AlphaRiseLED.ValueDisplayFormat = '%.3f';
            app.AlphaRiseLED.HorizontalAlignment = 'center';
            app.AlphaRiseLED.FontName = 'Microsoft JhengHei UI';
            app.AlphaRiseLED.Tooltip = {'Small rise / decay factors = more smoothing'};
            app.AlphaRiseLED.Position = [576 59 114 22];
            app.AlphaRiseLED.Value = 0.9;

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
            app.lineLow = images.roi.Line(app.freqAxis,'Position',[app.MinFrequency.Value,0;app.LeftFrequency.Value,0],'Color',app.ColorOrder.Value(1),'Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));

            % Add the line for mid frequency band
            app.lineMid = images.roi.Line(app.freqAxis,'Position',[app.LeftFrequency.Value,0;app.RightFrequency.Value,0],'Color',app.ColorOrder.Value(2),'Deletable',false);
            % Add a listener that will trigger a callback function titled "lineMidMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            addlistener(app.lineMid,'MovingROI',@(varargin)lineMidMoving(app,app.lineMid));

            % Add the line for high frequency band
            app.lineHigh = images.roi.Line(app.freqAxis,'Position',[app.RightFrequency.Value,0;app.MaxFrequency.Value,0],'Color',app.ColorOrder.Value(3),'Deletable',false);
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
            app.lineBright = images.roi.Line(app.ledAxis,'Position',[0,0; 100,0],'Color','C','Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.lineBright,'MovingROI',@(varargin)lineBrightMoving(app,app.lineBright));
            % Show the figure after all components are created

            % Creating axis for red slider control 
            app.redCtrlAxis = axes(app.ColorControl,'Color','none','YColor','none','XLim',[0,255],'YTick',[], ...
                    'XTick',[0:16:255 255],'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.RedSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.redCtrlAxis);
            app.redCtrlAxis.Toolbar.Visible = 'off';

            % Add the line for red control
            app.redCtrl = images.roi.Line(app.redCtrlAxis,'Position',[0,0; 255,0],'Color','R','Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.redCtrl,'MovingROI',@(varargin)lineRedMoving(app,app.redCtrl));
            % Show the figure after all components are created

            % Creating axis for blue slider control 
            app.blueCtrlAxis = axes(app.ColorControl,'Color','none','YColor','none','XLim',[0,255],'YTick',[], ...
                    'XTick',[0:16:255 255],'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.BlueSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.blueCtrlAxis);
            app.blueCtrlAxis.Toolbar.Visible = 'off';

            % Add the line for blue control
            app.blueCtrl = images.roi.Line(app.blueCtrlAxis,'Position',[0,0; 255,0],'Color','B','Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.blueCtrl,'MovingROI',@(varargin)lineBlueMoving(app,app.blueCtrl));
            % Show the figure after all components are created

            % Creating axis for green slider control 
            app.greenCtrlAxis = axes(app.ColorControl,'Color','none','YColor','none','XLim',[0,255],'YTick',[], ...
                    'XTick',[0:16:255 255],'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.GreenSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.greenCtrlAxis);
            app.greenCtrlAxis.Toolbar.Visible = 'off';

            % Add the line for green control
            app.greenCtrl = images.roi.Line(app.greenCtrlAxis,'Position',[0,0; 255,0],'Color','G','Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.greenCtrl,'MovingROI',@(varargin)lineGreenMoving(app,app.greenCtrl));
            % Show the figure after all components are created

            % Creating axis for speed slider control 
            app.speedCtrlAxis = axes(app.ColorControl,'Color','none','YColor','none','XLim',[0,100],'YTick',[], ...
                    'XTick',0:10:100,'TickDir','both','XMinorTick', ...
                    'off','Units','pixels','Position',app.SpeedSlider.Position);
             
            % Disable the interactivity & toolbar visibility
            disableDefaultInteractivity(app.speedCtrlAxis);
            app.speedCtrlAxis.Toolbar.Visible = 'off';

            % Add the line for speed control
            app.speedCtrl = images.roi.Line(app.speedCtrlAxis,'Position',[0,0; 50,0],'Color','M','Deletable',false);
            % Add a listener that will trigger a callback function titled "lineLowMoving" when user
            % moves the ROI endpoints or the line ROI as a whole
            %addlistener(app.lineLow,'MovingROI',@(varargin)lineLowMoving(app,app.lineLow));
            addlistener(app.speedCtrl,'MovingROI',@(varargin)lineSpeedMoving(app,app.speedCtrl));
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