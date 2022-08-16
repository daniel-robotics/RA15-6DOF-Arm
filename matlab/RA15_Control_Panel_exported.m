classdef RA15_Control_Panel_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        RightPanel              matlab.ui.container.Panel
        RobotControlPanel       matlab.ui.container.Panel
        GridLayout              matlab.ui.container.GridLayout
        JointPanel              matlab.ui.container.Panel
        PTSpinner               matlab.ui.control.Spinner
        VTSpinner               matlab.ui.control.Spinner
        Power0GaugeLabel        matlab.ui.control.Label
        PowerGauge              matlab.ui.control.LinearGauge
        VTMaxCheckBox           matlab.ui.control.CheckBox
        PTEnableCheckBox        matlab.ui.control.CheckBox
        PTSlider                matlab.ui.control.Slider
        VTSlider                matlab.ui.control.Slider
        HomeLampLabel           matlab.ui.control.Label
        HomeLamp                matlab.ui.control.Lamp
        PVPlot                  matlab.ui.control.UIAxes
        JointPanel_2            matlab.ui.container.Panel
        PTSpinner_2             matlab.ui.control.Spinner
        VTSpinner_2             matlab.ui.control.Spinner
        Power0GaugeLabel_2      matlab.ui.control.Label
        PowerGauge_2            matlab.ui.control.LinearGauge
        VTMaxCheckBox_2         matlab.ui.control.CheckBox
        PTEnableCheckBox_2      matlab.ui.control.CheckBox
        PTSlider_2              matlab.ui.control.Slider
        VTSlider_2              matlab.ui.control.Slider
        HomeLamp_2Label         matlab.ui.control.Label
        HomeLamp_2              matlab.ui.control.Lamp
        PVPlot_2                matlab.ui.control.UIAxes
        JointPanel_3            matlab.ui.container.Panel
        PTSpinner_3             matlab.ui.control.Spinner
        VTSpinner_3             matlab.ui.control.Spinner
        Power0GaugeLabel_3      matlab.ui.control.Label
        PowerGauge_3            matlab.ui.control.LinearGauge
        VTMaxCheckBox_3         matlab.ui.control.CheckBox
        PTEnableCheckBox_3      matlab.ui.control.CheckBox
        PTSlider_3              matlab.ui.control.Slider
        VTSlider_3              matlab.ui.control.Slider
        HomeLamp_3Label         matlab.ui.control.Label
        HomeLamp_3              matlab.ui.control.Lamp
        PVPlot_3                matlab.ui.control.UIAxes
        JointPanel_4            matlab.ui.container.Panel
        PTSpinner_4             matlab.ui.control.Spinner
        VTSpinner_4             matlab.ui.control.Spinner
        Power0GaugeLabel_4      matlab.ui.control.Label
        PowerGauge_4            matlab.ui.control.LinearGauge
        VTMaxCheckBox_4         matlab.ui.control.CheckBox
        PTEnableCheckBox_4      matlab.ui.control.CheckBox
        PTSlider_4              matlab.ui.control.Slider
        VTSlider_4              matlab.ui.control.Slider
        HomeLamp_4Label         matlab.ui.control.Label
        HomeLamp_4              matlab.ui.control.Lamp
        PVPlot_4                matlab.ui.control.UIAxes
        JointPanel_5            matlab.ui.container.Panel
        PTSpinner_5             matlab.ui.control.Spinner
        VTSpinner_5             matlab.ui.control.Spinner
        Power0GaugeLabel_5      matlab.ui.control.Label
        PowerGauge_5            matlab.ui.control.LinearGauge
        VTMaxCheckBox_5         matlab.ui.control.CheckBox
        PTEnableCheckBox_5      matlab.ui.control.CheckBox
        PTSlider_5              matlab.ui.control.Slider
        VTSlider_5              matlab.ui.control.Slider
        HomeLamp_5Label         matlab.ui.control.Label
        HomeLamp_5              matlab.ui.control.Lamp
        PVPlot_5                matlab.ui.control.UIAxes
        JointPanel_6            matlab.ui.container.Panel
        PTSpinner_6             matlab.ui.control.Spinner
        VTSpinner_6             matlab.ui.control.Spinner
        Power0GaugeLabel_6      matlab.ui.control.Label
        PowerGauge_6            matlab.ui.control.LinearGauge
        VTMaxCheckBox_6         matlab.ui.control.CheckBox
        PTEnableCheckBox_6      matlab.ui.control.CheckBox
        PTSlider_6              matlab.ui.control.Slider
        VTSlider_6              matlab.ui.control.Slider
        HomeLamp_6Label         matlab.ui.control.Label
        HomeLamp_6              matlab.ui.control.Lamp
        PVPlot_6                matlab.ui.control.UIAxes
        LeftPanel               matlab.ui.container.Panel
        ConnectionPanel         matlab.ui.container.Panel
        BluetoothNameLabel      matlab.ui.control.Label
        BluetoothNameEditField  matlab.ui.control.EditField
        ConnectToNXTButton      matlab.ui.control.Button
        ConnectionStatusLabel   matlab.ui.control.Label
    end

        
    properties (Access = private)
        JointPanels             matlab.ui.container.Panel
        PTSpinners              matlab.ui.control.Spinner
        VTSpinners              matlab.ui.control.Spinner
        PowerGaugeLabels        matlab.ui.control.Label
        PowerGauges             matlab.ui.control.LinearGauge
        VTMaxCheckBoxes         matlab.ui.control.CheckBox
        PTEnableCheckBoxes      matlab.ui.control.CheckBox
        PTSliders               matlab.ui.control.Slider
        VTSliders               matlab.ui.control.Slider
        HomeLamps               matlab.ui.control.Lamp
        PVPlots                 matlab.ui.control.UIAxes
        
        joint                   RobotJoint
        rcx                     = 0;
        ea1                     = 0;
        ea2                     = 0;
        ea3                     = 0;
        
        nxt                     NXTConnection
        bluetoothName           char
        bluetoothChannel        = 1;
        nxtTransmitInterval     = 100;
        
        pcTransmitInterval      = 150;
        pcTransmitTimer         timer
        
        uiUpdateInterval        = 100;
        uiUpdateTimer           timer
        
        plotUpdateInterval      = 500;
        plotUpdateTimer         timer
    end
       
    methods (Access = private)
        
        function initRobotJoints(app)
            for ji=1:6
                app.joint(ji) = RobotJoint(ji);
            end
        end

        function initJointPanels(app)
            app.JointPanels(1) = app.JointPanel;
            app.JointPanels(2) = app.JointPanel_2;
            app.JointPanels(3) = app.JointPanel_3;
            app.JointPanels(4) = app.JointPanel_4;
            app.JointPanels(5) = app.JointPanel_5;
            app.JointPanels(6) = app.JointPanel_6;
            
            for i=1:6
                app.JointPanels(i).UserData = i;
                app.setJointPanelTitle(i, app.joint(i).p, app.joint(i).v);
            end
        end
                
        function initPVPlots(app)
            app.PVPlots(1) = app.PVPlot;
            app.PVPlots(2) = app.PVPlot_2;
            app.PVPlots(3) = app.PVPlot_3;
            app.PVPlots(4) = app.PVPlot_4;
            app.PVPlots(5) = app.PVPlot_5;
            app.PVPlots(6) = app.PVPlot_6;
            
            for i=1:6
                pmin = jpmtr(i).pmin;
                pmax = jpmtr(i).pmax;
                vmax = jpmtr(i).vmax;
                
                yyaxis(app.PVPlots(i),'left');
                app.PVPlots(i).YLabel.String='Position (deg)';
                app.PVPlots(i).YLim = [pmin, pmax];
                app.PVPlots(i).YColor = [0 0 1];
                app.PVPlots(i).YMinorTick = 'on';
                app.PVPlots(i).YGrid = 'on';
                
                
                yyaxis(app.PVPlots(i),'right');
                app.PVPlots(i).YLabel.String='Velocity (deg/s)';
                app.PVPlots(i).YLim = [-vmax, vmax];
                app.PVPlots(i).YColor = [1 0 0];
                app.PVPlots(i).YMinorTick = 'on';
                
                disableDefaultInteractivity(app.PVPlots(i));
            end
        
%             yyaxis(app.PVPlot,'left')
%             plot(app.PVPlot,xdata,ydata);
%             yyaxis(app.PVPlot,'right')
%             plot(app.PVPlot,xdata,y2data);
        end
        
        function initPTSpinnersAndSliders(app)
            app.PTSpinners(1) = app.PTSpinner;
            app.PTSpinners(2) = app.PTSpinner_2;
            app.PTSpinners(3) = app.PTSpinner_3;
            app.PTSpinners(4) = app.PTSpinner_4;
            app.PTSpinners(5) = app.PTSpinner_5;
            app.PTSpinners(6) = app.PTSpinner_6;
            
            app.PTSliders(1) = app.PTSlider;
            app.PTSliders(2) = app.PTSlider_2;
            app.PTSliders(3) = app.PTSlider_3;
            app.PTSliders(4) = app.PTSlider_4;
            app.PTSliders(5) = app.PTSlider_5;
            app.PTSliders(6) = app.PTSlider_6;
            
            for i=1:6
                app.PTSpinners(i).UserData = i;
                app.PTSliders(i).UserData = i;
                
                app.PTSpinners(i).ValueChangedFcn = createCallbackFcn(app, @PTSpinnerValueChange, true);
                app.PTSpinners(i).ValueChangingFcn = createCallbackFcn(app, @PTSpinnerValueChange, true);
                app.PTSliders(i).ValueChangingFcn = createCallbackFcn(app, @PTSliderValueChanging, true);
                
                pmax = jpmtr(i).pmax;
                pmin = jpmtr(i).pmin;
                prest = jpmtr(i).prest;
                app.PTSpinners(i).Limits = [pmin, pmax];
                app.PTSliders(i).Limits = [pmin, pmax];
                yyaxis(app.PVPlots(i),'left');
                app.PTSliders(i).MajorTicks = app.PVPlots(i).YTick;
                app.setPTSpinnerSliderValue(i, prest);
            end
        end
        
        function initVTSpinnersAndSliders(app)
            app.VTSpinners(1) = app.VTSpinner;
            app.VTSpinners(2) = app.VTSpinner_2;
            app.VTSpinners(3) = app.VTSpinner_3;
            app.VTSpinners(4) = app.VTSpinner_4;
            app.VTSpinners(5) = app.VTSpinner_5;
            app.VTSpinners(6) = app.VTSpinner_6;
            
            app.VTSliders(1) = app.VTSlider;
            app.VTSliders(2) = app.VTSlider_2;
            app.VTSliders(3) = app.VTSlider_3;
            app.VTSliders(4) = app.VTSlider_4;
            app.VTSliders(5) = app.VTSlider_5;
            app.VTSliders(6) = app.VTSlider_6;
            
            for i=1:6
                app.VTSpinners(i).UserData = i;
                app.VTSliders(i).UserData = i;
                
                app.VTSpinners(i).ValueChangedFcn = createCallbackFcn(app, @VTSpinnerValueChange, true);
                app.VTSpinners(i).ValueChangingFcn = createCallbackFcn(app, @VTSpinnerValueChange, true);
                app.VTSliders(i).ValueChangingFcn = createCallbackFcn(app, @VTSliderValueChanging, true);
                app.VTSliders(i).ValueChangedFcn = createCallbackFcn(app, @VTSliderValueChanged, true);
                
                vmax = jpmtr(i).vmax;
                app.VTSpinners(i).Limits = [-vmax, vmax];
                app.VTSliders(i).Limits = [-vmax, vmax];
                yyaxis(app.PVPlots(i),'right');
                app.VTSliders(i).MajorTicks = app.PVPlots(i).YTick;
                app.setVTSpinnerSliderValue(i, 0);
            end
        end
                
        function initPowerGaugesAndLabels(app)
            app.PowerGaugeLabels(1) = app.Power0GaugeLabel;
            app.PowerGaugeLabels(2) = app.Power0GaugeLabel_2;
            app.PowerGaugeLabels(3) = app.Power0GaugeLabel_3;
            app.PowerGaugeLabels(4) = app.Power0GaugeLabel_4;
            app.PowerGaugeLabels(5) = app.Power0GaugeLabel_5;
            app.PowerGaugeLabels(6) = app.Power0GaugeLabel_6;
            
            app.PowerGauges(1) = app.PowerGauge;
            app.PowerGauges(2) = app.PowerGauge_2;
            app.PowerGauges(3) = app.PowerGauge_3;
            app.PowerGauges(4) = app.PowerGauge_4;
            app.PowerGauges(5) = app.PowerGauge_5;
            app.PowerGauges(6) = app.PowerGauge_6;
            
            for i=1:6
                app.PowerGauges(i).UserData = i;
                app.PowerGaugeLabels(i).UserData = i;
                app.setPowerGaugeValue(i, 0);
            end
        end
                        
        function initPTEnableCheckBoxes(app)           
            app.PTEnableCheckBoxes(1) = app.PTEnableCheckBox;
            app.PTEnableCheckBoxes(2) = app.PTEnableCheckBox_2;
            app.PTEnableCheckBoxes(3) = app.PTEnableCheckBox_3;
            app.PTEnableCheckBoxes(4) = app.PTEnableCheckBox_4;
            app.PTEnableCheckBoxes(5) = app.PTEnableCheckBox_5;
            app.PTEnableCheckBoxes(6) = app.PTEnableCheckBox_6;
            
            for i=1:6
                app.PTEnableCheckBoxes(i).UserData = i;
                app.PTEnableCheckBoxes(i).ValueChangedFcn = createCallbackFcn(app, @PTCheckboxValueChanged, true);
            end
        end
        
        function initVTMaxCheckBoxes(app)
            app.VTMaxCheckBoxes(1) = app.VTMaxCheckBox;
            app.VTMaxCheckBoxes(2) = app.VTMaxCheckBox_2;
            app.VTMaxCheckBoxes(3) = app.VTMaxCheckBox_3;
            app.VTMaxCheckBoxes(4) = app.VTMaxCheckBox_4;
            app.VTMaxCheckBoxes(5) = app.VTMaxCheckBox_5;
            app.VTMaxCheckBoxes(6) = app.VTMaxCheckBox_6;
            
            for i=1:6
                app.VTMaxCheckBoxes(i).UserData = i;
                app.VTMaxCheckBoxes(i).ValueChangedFcn = createCallbackFcn(app, @VTCheckboxValueChanged, true);
            end
        end
                                
        function initHomeLamps(app)
            app.HomeLamps(1) = app.HomeLamp;
            app.HomeLamps(2) = app.HomeLamp_2;
            app.HomeLamps(3) = app.HomeLamp_3;
            app.HomeLamps(4) = app.HomeLamp_4;
            app.HomeLamps(5) = app.HomeLamp_5;
            app.HomeLamps(6) = app.HomeLamp_6;
            
            for i=1:6
                app.HomeLamps(i).UserData = i;
            end
        end
        
        function initTimers(app)
            app.pcTransmitTimer = timer('Name', 'pcTransmit',   ...
                'TimerFcn', @app.sendPCPacketFromJoints,        ...
                'Period', app.pcTransmitInterval/1000,          ...
                'ExecutionMode', 'fixedRate',                   ...
                'BusyMode', 'drop',                             ...
                'StartDelay', 5);
            
            app.uiUpdateTimer = timer('Name', 'uiUpdate',       ...
                'TimerFcn', @app.updateUI,                      ...
                'Period', app.uiUpdateInterval/1000,            ...
                'ExecutionMode', 'fixedRate',                   ...
                'BusyMode', 'drop',                             ...
                'StartDelay', 5);
            
            app.plotUpdateTimer = timer('Name', 'plotUpdate',   ...
                'TimerFcn', @app.updatePlots,                   ...
                'Period', app.plotUpdateInterval/1000,          ...
                'ExecutionMode', 'fixedRate',                   ...
                'BusyMode', 'drop',                             ...
                'StartDelay', 5);
        end
        
        function startTimers(app)
            start(app.pcTransmitTimer);
            start(app.uiUpdateTimer);
            start(app.plotUpdateTimer);
        end
        
        function setJointPanelTitle(app, joint_index, pos, vel)
            app.JointPanels(joint_index).Title = ...
                sprintf('J%d:  %0.2f deg,   %0.2f deg/s', joint_index, pos, vel);  
        end
        
        function setPTSpinnerSliderValue(app, joint_index, pos_tgt)
            if pos_tgt == RobotJoint.DISABLE_PT
                app.PTSpinners(joint_index).Value = jpmtr(joint_index).prest;
                app.PTSliders(joint_index).Value = jpmtr(joint_index).prest;
                app.PTSpinners(joint_index).Enable = 'off';
                app.PTSliders(joint_index).Enable = 'off';
            else
                app.PTSpinners(joint_index).Value = pos_tgt;
                app.PTSliders(joint_index).Value = pos_tgt;
                app.PTSpinners(joint_index).Enable = 'on';
                app.PTSliders(joint_index).Enable = 'on';
            end
        end
        
        function setVTSpinnerSliderValue(app, joint_index, vel_tgt)
            if vel_tgt == RobotJoint.DISABLE_VT
                app.VTSpinners(joint_index).Value = 0;
                app.VTSliders(joint_index).Value = 0;
                app.VTSpinners(joint_index).Enable = 'off';
                app.VTSliders(joint_index).Enable = 'off';
            else
                app.VTSpinners(joint_index).Value = vel_tgt;
                app.VTSliders(joint_index).Value = vel_tgt;
                app.VTSpinners(joint_index).Enable = 'on';
                app.VTSliders(joint_index).Enable = 'on';
            end
        end
        
        function setPowerGaugeValue(app, joint_index, pwm)
            app.PowerGauges(joint_index).Value = pwm;
            app.PowerGaugeLabels(joint_index).Text{2,1} = sprintf('%d%%', pwm);
        end
        
        function setConnectionPanelValue(app, connected)
            if connected == true
                app.ConnectToNXTButton.Text = 'Disconnect from NXT';
                app.ConnectionStatusLabel.Text = 'Streaming from NXT';
                app.ConnectToNXTButton.Enable = 'on';
            else
                app.ConnectToNXTButton.Text = 'Connect to NXT';
                app.ConnectionStatusLabel.Text = 'Not Connected';
                app.ConnectToNXTButton.Enable = 'on';
            end
        end
        
        
        % Updates UI from RobotJoint state variables
        function updateUI(app, timer, event)
            for ji=1:6
                j = app.joint(ji);
                
                % Setting interactive UI components here causes too much lag
                app.setJointPanelTitle(ji, app.joint(ji).p, app.joint(ji).v);
                %app.setPTSpinnerSliderValue(ji, app.joint(ji).pt);
                %app.setVTSpinnerSliderValue(ji, app.joint(ji).vt);
                app.setPowerGaugeValue(ji, app.joint(ji).pwm);
                %app.PTEnableCheckBoxes(ji).Value = ~(app.joint(ji).pt == RobotJoint.DISABLE_PT);
                %app.VTMaxCheckBoxes(ji).Value = (app.joint(ji).vt == RobotJoint.DISABLE_VT);
                app.HomeLamps(ji).Color = (app.joint(ji).home == true).*[0, 1, 0];
            end
        end
        
        
        % Updates plots from nxt.history table
        function updatePlots(app, timer, event)
            
        end
        
        
        % Sets RobotJoint state variables from newly-received packet
        function setJointsFromNXTPacket(app, packet)
            persistent colStart;
            if isempty(colStart)
                colStart = strfind(strcmp('j1p', NXTConnection.NXT_BT_EMPTY_PACKET.Properties.VariableNames), 1);
            end
            
            col = colStart;
            for ji=1:6
                app.joint(ji).p = packet.(col);       col = col+1;
                app.joint(ji).v = packet.(col);       col = col+1;
                app.joint(ji).pwm = packet.(col);     col = col+1;
                app.joint(ji).home = (bitand(packet.tmux, app.joint(ji).tmux_mask) == 0);
            end
            app.ea1 = packet.ea1;
            app.ea2 = packet.ea2;
            app.ea3 = packet.ea3;
        end
        
        
        % Creates a packet from RobotJoint state variables, then sends it over bluetooth
        function packet = sendPCPacketFromJoints(app, timer, event)
            persistent colStart;
            if isempty(colStart)
                colStart = strfind(strcmp('j1pt', NXTConnection.PC_BT_EMPTY_PACKET.Properties.VariableNames), 1);
            end
            
            if app.nxt.connected == true
                % Start with empty packet, fill in fields from state variables
                packet = NXTConnection.PC_BT_EMPTY_PACKET;
                
                col = colStart;
                for ji=1:6
                    packet.(col) = app.joint(ji).pt;    col = col+1;
                    packet.(col) = app.joint(ji).vt;    col = col+1;
                end
                packet.rcx = uint8(app.rcx);
                packet.nxtTransmitInterval = uint16(app.nxtTransmitInterval);
                
                % Send over bluetooth
                app.nxt.bluetoothSend(packet);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath('instrument');
            
            app.initRobotJoints();
            app.initJointPanels();
            app.initPVPlots();
            app.initPTSpinnersAndSliders();
            app.initVTSpinnersAndSliders();
            app.initPowerGaugesAndLabels()
            app.initPTEnableCheckBoxes();
            app.initVTMaxCheckBoxes();
            app.initHomeLamps();
            app.initTimers();
            
            app.nxt = NXTConnection(@app.setJointsFromNXTPacket);

            app.startTimers();
        end

        % Close request function: UIFigure
        function shutdownFcn(app, event)
            stop(app.pcTransmitTimer);
            stop(app.uiUpdateTimer);
            stop(app.plotUpdateTimer);
            app.nxt.bluetoothDisconnect();
            
            delete(timerfindall);
            delete(gcp('nocreate'));
            delete(app);
            
        end

        % Value changed function: PTEnableCheckBox
        function PTCheckboxValueChanged(app, event)
            joint_index = event.Source.UserData;
            if event.Value == true
                val = app.PTSpinners(joint_index).Value;
            else
                val = RobotJoint.DISABLE_PT;
            end
            app.joint(joint_index).pt = val;
            app.setPTSpinnerSliderValue(joint_index, val);
        end

        % Value changed function: VTMaxCheckBox
        function VTCheckboxValueChanged(app, event)
            joint_index = event.Source.UserData;
            if event.Value == false
                val = app.VTSpinners(joint_index).Value;
            else
                val = RobotJoint.DISABLE_VT;
            end
            app.joint(joint_index).vt = val;
            app.setVTSpinnerSliderValue(joint_index, val);
        end

        % Value changed function: BluetoothNameEditField
        function BluetoothNameValueChanged(app, event)
            app.bluetoothName = app.BluetoothNameEditField.Value;
        end

        % Button pushed function: ConnectToNXTButton
        function ConnectToNXTButtonPushed(app, event)
            app.bluetoothName = app.BluetoothNameEditField.Value;
            if app.nxt.connected == false
                app.ConnectToNXTButton.Enable = 'off';
                app.ConnectionStatusLabel.Text = 'Connecting....';
                drawnow
                app.nxt.bluetoothConnect(app.bluetoothName, app.bluetoothChannel);
            else
                app.nxt.bluetoothDisconnect();
            end
            app.setConnectionPanelValue(app.nxt.connected);
        end

        % Value changing function: PTSlider
        function PTSliderValueChanging(app, event)
            joint_index = event.Source.UserData;
            pos_tgt = event.Value;
            app.joint(joint_index).pt = pos_tgt;
            app.PTSpinners(joint_index).Value = pos_tgt;
        end

        % Callback function: PTSpinner, PTSpinner
        function PTSpinnerValueChange(app, event)
            joint_index = event.Source.UserData;
            pos_tgt = event.Value;
            app.joint(joint_index).pt = pos_tgt;
            app.PTSliders(joint_index).Value = pos_tgt;
        end

        % Value changing function: VTSlider
        function VTSliderValueChanging(app, event)
            joint_index = event.Source.UserData;
            vel_tgt = event.Value;
            app.joint(joint_index).vt = vel_tgt;
            app.VTSpinners(joint_index).Value = vel_tgt;
        end

        % Callback function: VTSpinner, VTSpinner
        function VTSpinnerValueChange(app, event)
            joint_index = event.Source.UserData;
            vel_tgt = event.Value;
            app.joint(joint_index).vt = vel_tgt;
            app.VTSliders(joint_index).Value = vel_tgt; 
        end

        % Value changed function: VTSlider
        function VTSliderValueChanged(app, event)
            joint_index = event.Source.UserData;
            vel_tgt = 0;                            % Reset to 0 when handle is released
            app.joint(joint_index).vt = vel_tgt;
            app.VTSpinners(joint_index).Value = vel_tgt;
            app.VTSliders(joint_index).Value = vel_tgt; 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1600 900];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @shutdownFcn, true);

            % Create RightPanel
            app.RightPanel = uipanel(app.UIFigure);
            app.RightPanel.AutoResizeChildren = 'off';
            app.RightPanel.Position = [249 1 1352 900];

            % Create RobotControlPanel
            app.RobotControlPanel = uipanel(app.RightPanel);
            app.RobotControlPanel.AutoResizeChildren = 'off';
            app.RobotControlPanel.Position = [1 0 1351 900];

            % Create GridLayout
            app.GridLayout = uigridlayout(app.RobotControlPanel);
            app.GridLayout.RowHeight = {'1x', '1x', '1x'};

            % Create JointPanel
            app.JointPanel = uipanel(app.GridLayout);
            app.JointPanel.AutoResizeChildren = 'off';
            app.JointPanel.TitlePosition = 'centertop';
            app.JointPanel.Title = 'J1:  0 deg,   0 deg/s';
            app.JointPanel.Layout.Row = 1;
            app.JointPanel.Layout.Column = 1;
            app.JointPanel.FontWeight = 'bold';
            app.JointPanel.FontSize = 16;

            % Create PTSpinner
            app.PTSpinner = uispinner(app.JointPanel);
            app.PTSpinner.ValueChangingFcn = createCallbackFcn(app, @PTSpinnerValueChange, true);
            app.PTSpinner.Limits = [-100 100];
            app.PTSpinner.RoundFractionalValues = 'on';
            app.PTSpinner.ValueChangedFcn = createCallbackFcn(app, @PTSpinnerValueChange, true);
            app.PTSpinner.Position = [81 4 62 22];

            % Create VTSpinner
            app.VTSpinner = uispinner(app.JointPanel);
            app.VTSpinner.ValueChangingFcn = createCallbackFcn(app, @VTSpinnerValueChange, true);
            app.VTSpinner.Limits = [-100 100];
            app.VTSpinner.RoundFractionalValues = 'on';
            app.VTSpinner.ValueChangedFcn = createCallbackFcn(app, @VTSpinnerValueChange, true);
            app.VTSpinner.Position = [556 4 62 22];

            % Create Power0GaugeLabel
            app.Power0GaugeLabel = uilabel(app.JointPanel);
            app.Power0GaugeLabel.HorizontalAlignment = 'center';
            app.Power0GaugeLabel.FontWeight = 'bold';
            app.Power0GaugeLabel.Position = [9 4 49 33];
            app.Power0GaugeLabel.Text = {'Power:'; '0%'};

            % Create PowerGauge
            app.PowerGauge = uigauge(app.JointPanel, 'linear');
            app.PowerGauge.Limits = [-100 100];
            app.PowerGauge.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge.Orientation = 'vertical';
            app.PowerGauge.MinorTicks = [];
            app.PowerGauge.Position = [9 35 48 224];

            % Create VTMaxCheckBox
            app.VTMaxCheckBox = uicheckbox(app.JointPanel);
            app.VTMaxCheckBox.ValueChangedFcn = createCallbackFcn(app, @VTCheckboxValueChanged, true);
            app.VTMaxCheckBox.Text = 'Max V Only';
            app.VTMaxCheckBox.WordWrap = 'on';
            app.VTMaxCheckBox.FontSize = 10;
            app.VTMaxCheckBox.Position = [472 4 74 22];

            % Create PTEnableCheckBox
            app.PTEnableCheckBox = uicheckbox(app.JointPanel);
            app.PTEnableCheckBox.ValueChangedFcn = createCallbackFcn(app, @PTCheckboxValueChanged, true);
            app.PTEnableCheckBox.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox.WordWrap = 'on';
            app.PTEnableCheckBox.FontSize = 10;
            app.PTEnableCheckBox.Position = [150 4 124 22];
            app.PTEnableCheckBox.Value = true;

            % Create PTSlider
            app.PTSlider = uislider(app.JointPanel);
            app.PTSlider.Limits = [-100 100];
            app.PTSlider.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider.MajorTickLabels = {''};
            app.PTSlider.Orientation = 'vertical';
            app.PTSlider.ValueChangingFcn = createCallbackFcn(app, @PTSliderValueChanging, true);
            app.PTSlider.MinorTicks = [];
            app.PTSlider.Position = [110 35 3 224];

            % Create VTSlider
            app.VTSlider = uislider(app.JointPanel);
            app.VTSlider.Limits = [-100 100];
            app.VTSlider.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider.MajorTickLabels = {''};
            app.VTSlider.Orientation = 'vertical';
            app.VTSlider.ValueChangedFcn = createCallbackFcn(app, @VTSliderValueChanged, true);
            app.VTSlider.ValueChangingFcn = createCallbackFcn(app, @VTSliderValueChanging, true);
            app.VTSlider.MinorTicks = [];
            app.VTSlider.Position = [585 35 3 224];

            % Create HomeLampLabel
            app.HomeLampLabel = uilabel(app.JointPanel);
            app.HomeLampLabel.HorizontalAlignment = 'right';
            app.HomeLampLabel.Position = [305 4 38 22];
            app.HomeLampLabel.Text = 'Home';

            % Create HomeLamp
            app.HomeLamp = uilamp(app.JointPanel);
            app.HomeLamp.Position = [358 4 20 20];
            app.HomeLamp.Color = [0 0 0];

            % Create PVPlot
            app.PVPlot = uiaxes(app.JointPanel);
            app.PVPlot.Toolbar.Visible = 'off';
            app.PVPlot.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot.XLim = [0 10000];
            app.PVPlot.YLim = [-100 100];
            app.PVPlot.XTickLabel = '';
            app.PVPlot.XGrid = 'on';
            app.PVPlot.Position = [132 28 422 239];

            % Create JointPanel_2
            app.JointPanel_2 = uipanel(app.GridLayout);
            app.JointPanel_2.AutoResizeChildren = 'off';
            app.JointPanel_2.TitlePosition = 'centertop';
            app.JointPanel_2.Title = 'J2:  0 deg,   0 deg/s';
            app.JointPanel_2.Layout.Row = 1;
            app.JointPanel_2.Layout.Column = 2;
            app.JointPanel_2.FontWeight = 'bold';
            app.JointPanel_2.FontSize = 16;

            % Create PTSpinner_2
            app.PTSpinner_2 = uispinner(app.JointPanel_2);
            app.PTSpinner_2.Limits = [-100 100];
            app.PTSpinner_2.RoundFractionalValues = 'on';
            app.PTSpinner_2.Position = [81 4 62 22];

            % Create VTSpinner_2
            app.VTSpinner_2 = uispinner(app.JointPanel_2);
            app.VTSpinner_2.Limits = [-100 100];
            app.VTSpinner_2.RoundFractionalValues = 'on';
            app.VTSpinner_2.Position = [556 4 62 22];

            % Create Power0GaugeLabel_2
            app.Power0GaugeLabel_2 = uilabel(app.JointPanel_2);
            app.Power0GaugeLabel_2.HorizontalAlignment = 'center';
            app.Power0GaugeLabel_2.FontWeight = 'bold';
            app.Power0GaugeLabel_2.Position = [9 4 49 33];
            app.Power0GaugeLabel_2.Text = {'Power:'; '0%'};

            % Create PowerGauge_2
            app.PowerGauge_2 = uigauge(app.JointPanel_2, 'linear');
            app.PowerGauge_2.Limits = [-100 100];
            app.PowerGauge_2.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge_2.Orientation = 'vertical';
            app.PowerGauge_2.MinorTicks = [];
            app.PowerGauge_2.Position = [9 35 48 224];

            % Create VTMaxCheckBox_2
            app.VTMaxCheckBox_2 = uicheckbox(app.JointPanel_2);
            app.VTMaxCheckBox_2.Text = 'Max V Only';
            app.VTMaxCheckBox_2.WordWrap = 'on';
            app.VTMaxCheckBox_2.FontSize = 10;
            app.VTMaxCheckBox_2.Position = [472 4 74 22];

            % Create PTEnableCheckBox_2
            app.PTEnableCheckBox_2 = uicheckbox(app.JointPanel_2);
            app.PTEnableCheckBox_2.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox_2.WordWrap = 'on';
            app.PTEnableCheckBox_2.FontSize = 10;
            app.PTEnableCheckBox_2.Position = [150 4 124 22];
            app.PTEnableCheckBox_2.Value = true;

            % Create PTSlider_2
            app.PTSlider_2 = uislider(app.JointPanel_2);
            app.PTSlider_2.Limits = [-100 100];
            app.PTSlider_2.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider_2.MajorTickLabels = {''};
            app.PTSlider_2.Orientation = 'vertical';
            app.PTSlider_2.MinorTicks = [];
            app.PTSlider_2.Position = [110 35 3 224];

            % Create VTSlider_2
            app.VTSlider_2 = uislider(app.JointPanel_2);
            app.VTSlider_2.Limits = [-100 100];
            app.VTSlider_2.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider_2.MajorTickLabels = {''};
            app.VTSlider_2.Orientation = 'vertical';
            app.VTSlider_2.MinorTicks = [];
            app.VTSlider_2.Position = [585 35 3 224];

            % Create HomeLamp_2Label
            app.HomeLamp_2Label = uilabel(app.JointPanel_2);
            app.HomeLamp_2Label.HorizontalAlignment = 'right';
            app.HomeLamp_2Label.Position = [305 4 38 22];
            app.HomeLamp_2Label.Text = 'Home';

            % Create HomeLamp_2
            app.HomeLamp_2 = uilamp(app.JointPanel_2);
            app.HomeLamp_2.Position = [358 4 20 20];
            app.HomeLamp_2.Color = [0 0 0];

            % Create PVPlot_2
            app.PVPlot_2 = uiaxes(app.JointPanel_2);
            app.PVPlot_2.Toolbar.Visible = 'off';
            app.PVPlot_2.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot_2.XLim = [0 10000];
            app.PVPlot_2.YLim = [-100 100];
            app.PVPlot_2.XTickLabel = '';
            app.PVPlot_2.XGrid = 'on';
            app.PVPlot_2.Position = [132 28 422 239];

            % Create JointPanel_3
            app.JointPanel_3 = uipanel(app.GridLayout);
            app.JointPanel_3.AutoResizeChildren = 'off';
            app.JointPanel_3.TitlePosition = 'centertop';
            app.JointPanel_3.Title = 'J3:  0 deg,   0 deg/s';
            app.JointPanel_3.Layout.Row = 2;
            app.JointPanel_3.Layout.Column = 1;
            app.JointPanel_3.FontWeight = 'bold';
            app.JointPanel_3.FontSize = 16;

            % Create PTSpinner_3
            app.PTSpinner_3 = uispinner(app.JointPanel_3);
            app.PTSpinner_3.Limits = [-100 100];
            app.PTSpinner_3.RoundFractionalValues = 'on';
            app.PTSpinner_3.Position = [81 4 62 22];

            % Create VTSpinner_3
            app.VTSpinner_3 = uispinner(app.JointPanel_3);
            app.VTSpinner_3.Limits = [-100 100];
            app.VTSpinner_3.RoundFractionalValues = 'on';
            app.VTSpinner_3.Position = [556 4 62 22];

            % Create Power0GaugeLabel_3
            app.Power0GaugeLabel_3 = uilabel(app.JointPanel_3);
            app.Power0GaugeLabel_3.HorizontalAlignment = 'center';
            app.Power0GaugeLabel_3.FontWeight = 'bold';
            app.Power0GaugeLabel_3.Position = [9 4 49 33];
            app.Power0GaugeLabel_3.Text = {'Power:'; '0%'};

            % Create PowerGauge_3
            app.PowerGauge_3 = uigauge(app.JointPanel_3, 'linear');
            app.PowerGauge_3.Limits = [-100 100];
            app.PowerGauge_3.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge_3.Orientation = 'vertical';
            app.PowerGauge_3.MinorTicks = [];
            app.PowerGauge_3.Position = [9 35 48 224];

            % Create VTMaxCheckBox_3
            app.VTMaxCheckBox_3 = uicheckbox(app.JointPanel_3);
            app.VTMaxCheckBox_3.Text = 'Max V Only';
            app.VTMaxCheckBox_3.WordWrap = 'on';
            app.VTMaxCheckBox_3.FontSize = 10;
            app.VTMaxCheckBox_3.Position = [472 4 74 22];

            % Create PTEnableCheckBox_3
            app.PTEnableCheckBox_3 = uicheckbox(app.JointPanel_3);
            app.PTEnableCheckBox_3.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox_3.WordWrap = 'on';
            app.PTEnableCheckBox_3.FontSize = 10;
            app.PTEnableCheckBox_3.Position = [150 4 124 22];
            app.PTEnableCheckBox_3.Value = true;

            % Create PTSlider_3
            app.PTSlider_3 = uislider(app.JointPanel_3);
            app.PTSlider_3.Limits = [-100 100];
            app.PTSlider_3.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider_3.MajorTickLabels = {''};
            app.PTSlider_3.Orientation = 'vertical';
            app.PTSlider_3.MinorTicks = [];
            app.PTSlider_3.Position = [110 35 3 224];

            % Create VTSlider_3
            app.VTSlider_3 = uislider(app.JointPanel_3);
            app.VTSlider_3.Limits = [-100 100];
            app.VTSlider_3.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider_3.MajorTickLabels = {''};
            app.VTSlider_3.Orientation = 'vertical';
            app.VTSlider_3.MinorTicks = [];
            app.VTSlider_3.Position = [585 35 3 224];

            % Create HomeLamp_3Label
            app.HomeLamp_3Label = uilabel(app.JointPanel_3);
            app.HomeLamp_3Label.HorizontalAlignment = 'right';
            app.HomeLamp_3Label.Position = [305 4 38 22];
            app.HomeLamp_3Label.Text = 'Home';

            % Create HomeLamp_3
            app.HomeLamp_3 = uilamp(app.JointPanel_3);
            app.HomeLamp_3.Position = [358 4 20 20];
            app.HomeLamp_3.Color = [0 0 0];

            % Create PVPlot_3
            app.PVPlot_3 = uiaxes(app.JointPanel_3);
            app.PVPlot_3.Toolbar.Visible = 'off';
            app.PVPlot_3.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot_3.XLim = [0 10000];
            app.PVPlot_3.YLim = [-100 100];
            app.PVPlot_3.XTickLabel = '';
            app.PVPlot_3.XGrid = 'on';
            app.PVPlot_3.Position = [132 28 422 239];

            % Create JointPanel_4
            app.JointPanel_4 = uipanel(app.GridLayout);
            app.JointPanel_4.AutoResizeChildren = 'off';
            app.JointPanel_4.TitlePosition = 'centertop';
            app.JointPanel_4.Title = 'J4:  0 deg,   0 deg/s';
            app.JointPanel_4.Layout.Row = 2;
            app.JointPanel_4.Layout.Column = 2;
            app.JointPanel_4.FontWeight = 'bold';
            app.JointPanel_4.FontSize = 16;

            % Create PTSpinner_4
            app.PTSpinner_4 = uispinner(app.JointPanel_4);
            app.PTSpinner_4.Limits = [-100 100];
            app.PTSpinner_4.RoundFractionalValues = 'on';
            app.PTSpinner_4.Position = [81 4 62 22];

            % Create VTSpinner_4
            app.VTSpinner_4 = uispinner(app.JointPanel_4);
            app.VTSpinner_4.Limits = [-100 100];
            app.VTSpinner_4.RoundFractionalValues = 'on';
            app.VTSpinner_4.Position = [556 4 62 22];

            % Create Power0GaugeLabel_4
            app.Power0GaugeLabel_4 = uilabel(app.JointPanel_4);
            app.Power0GaugeLabel_4.HorizontalAlignment = 'center';
            app.Power0GaugeLabel_4.FontWeight = 'bold';
            app.Power0GaugeLabel_4.Position = [9 4 49 33];
            app.Power0GaugeLabel_4.Text = {'Power:'; '0%'};

            % Create PowerGauge_4
            app.PowerGauge_4 = uigauge(app.JointPanel_4, 'linear');
            app.PowerGauge_4.Limits = [-100 100];
            app.PowerGauge_4.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge_4.Orientation = 'vertical';
            app.PowerGauge_4.MinorTicks = [];
            app.PowerGauge_4.Position = [9 35 48 224];

            % Create VTMaxCheckBox_4
            app.VTMaxCheckBox_4 = uicheckbox(app.JointPanel_4);
            app.VTMaxCheckBox_4.Text = 'Max V Only';
            app.VTMaxCheckBox_4.WordWrap = 'on';
            app.VTMaxCheckBox_4.FontSize = 10;
            app.VTMaxCheckBox_4.Position = [472 4 74 22];

            % Create PTEnableCheckBox_4
            app.PTEnableCheckBox_4 = uicheckbox(app.JointPanel_4);
            app.PTEnableCheckBox_4.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox_4.WordWrap = 'on';
            app.PTEnableCheckBox_4.FontSize = 10;
            app.PTEnableCheckBox_4.Position = [150 4 124 22];
            app.PTEnableCheckBox_4.Value = true;

            % Create PTSlider_4
            app.PTSlider_4 = uislider(app.JointPanel_4);
            app.PTSlider_4.Limits = [-100 100];
            app.PTSlider_4.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider_4.MajorTickLabels = {''};
            app.PTSlider_4.Orientation = 'vertical';
            app.PTSlider_4.MinorTicks = [];
            app.PTSlider_4.Position = [110 35 3 224];

            % Create VTSlider_4
            app.VTSlider_4 = uislider(app.JointPanel_4);
            app.VTSlider_4.Limits = [-100 100];
            app.VTSlider_4.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider_4.MajorTickLabels = {''};
            app.VTSlider_4.Orientation = 'vertical';
            app.VTSlider_4.MinorTicks = [];
            app.VTSlider_4.Position = [585 35 3 224];

            % Create HomeLamp_4Label
            app.HomeLamp_4Label = uilabel(app.JointPanel_4);
            app.HomeLamp_4Label.HorizontalAlignment = 'right';
            app.HomeLamp_4Label.Position = [305 4 38 22];
            app.HomeLamp_4Label.Text = 'Home';

            % Create HomeLamp_4
            app.HomeLamp_4 = uilamp(app.JointPanel_4);
            app.HomeLamp_4.Position = [358 4 20 20];
            app.HomeLamp_4.Color = [0 0 0];

            % Create PVPlot_4
            app.PVPlot_4 = uiaxes(app.JointPanel_4);
            app.PVPlot_4.Toolbar.Visible = 'off';
            app.PVPlot_4.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot_4.XLim = [0 10000];
            app.PVPlot_4.YLim = [-100 100];
            app.PVPlot_4.XTickLabel = '';
            app.PVPlot_4.XGrid = 'on';
            app.PVPlot_4.Position = [132 28 422 239];

            % Create JointPanel_5
            app.JointPanel_5 = uipanel(app.GridLayout);
            app.JointPanel_5.AutoResizeChildren = 'off';
            app.JointPanel_5.TitlePosition = 'centertop';
            app.JointPanel_5.Title = 'J5:  0 deg,   0 deg/s';
            app.JointPanel_5.Layout.Row = 3;
            app.JointPanel_5.Layout.Column = 1;
            app.JointPanel_5.FontWeight = 'bold';
            app.JointPanel_5.FontSize = 16;

            % Create PTSpinner_5
            app.PTSpinner_5 = uispinner(app.JointPanel_5);
            app.PTSpinner_5.Limits = [-100 100];
            app.PTSpinner_5.RoundFractionalValues = 'on';
            app.PTSpinner_5.Position = [81 4 62 22];

            % Create VTSpinner_5
            app.VTSpinner_5 = uispinner(app.JointPanel_5);
            app.VTSpinner_5.Limits = [-100 100];
            app.VTSpinner_5.RoundFractionalValues = 'on';
            app.VTSpinner_5.Position = [556 4 62 22];

            % Create Power0GaugeLabel_5
            app.Power0GaugeLabel_5 = uilabel(app.JointPanel_5);
            app.Power0GaugeLabel_5.HorizontalAlignment = 'center';
            app.Power0GaugeLabel_5.FontWeight = 'bold';
            app.Power0GaugeLabel_5.Position = [9 4 49 33];
            app.Power0GaugeLabel_5.Text = {'Power:'; '0%'};

            % Create PowerGauge_5
            app.PowerGauge_5 = uigauge(app.JointPanel_5, 'linear');
            app.PowerGauge_5.Limits = [-100 100];
            app.PowerGauge_5.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge_5.Orientation = 'vertical';
            app.PowerGauge_5.MinorTicks = [];
            app.PowerGauge_5.Position = [9 35 48 224];

            % Create VTMaxCheckBox_5
            app.VTMaxCheckBox_5 = uicheckbox(app.JointPanel_5);
            app.VTMaxCheckBox_5.Text = 'Max V Only';
            app.VTMaxCheckBox_5.WordWrap = 'on';
            app.VTMaxCheckBox_5.FontSize = 10;
            app.VTMaxCheckBox_5.Position = [472 4 74 22];

            % Create PTEnableCheckBox_5
            app.PTEnableCheckBox_5 = uicheckbox(app.JointPanel_5);
            app.PTEnableCheckBox_5.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox_5.WordWrap = 'on';
            app.PTEnableCheckBox_5.FontSize = 10;
            app.PTEnableCheckBox_5.Position = [150 4 124 22];
            app.PTEnableCheckBox_5.Value = true;

            % Create PTSlider_5
            app.PTSlider_5 = uislider(app.JointPanel_5);
            app.PTSlider_5.Limits = [-100 100];
            app.PTSlider_5.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider_5.MajorTickLabels = {''};
            app.PTSlider_5.Orientation = 'vertical';
            app.PTSlider_5.MinorTicks = [];
            app.PTSlider_5.Position = [110 35 3 224];

            % Create VTSlider_5
            app.VTSlider_5 = uislider(app.JointPanel_5);
            app.VTSlider_5.Limits = [-100 100];
            app.VTSlider_5.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider_5.MajorTickLabels = {''};
            app.VTSlider_5.Orientation = 'vertical';
            app.VTSlider_5.MinorTicks = [];
            app.VTSlider_5.Position = [585 35 3 224];

            % Create HomeLamp_5Label
            app.HomeLamp_5Label = uilabel(app.JointPanel_5);
            app.HomeLamp_5Label.HorizontalAlignment = 'right';
            app.HomeLamp_5Label.Position = [305 4 38 22];
            app.HomeLamp_5Label.Text = 'Home';

            % Create HomeLamp_5
            app.HomeLamp_5 = uilamp(app.JointPanel_5);
            app.HomeLamp_5.Position = [358 4 20 20];
            app.HomeLamp_5.Color = [0 0 0];

            % Create PVPlot_5
            app.PVPlot_5 = uiaxes(app.JointPanel_5);
            app.PVPlot_5.Toolbar.Visible = 'off';
            app.PVPlot_5.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot_5.XLim = [0 10000];
            app.PVPlot_5.YLim = [-100 100];
            app.PVPlot_5.XTickLabel = '';
            app.PVPlot_5.XGrid = 'on';
            app.PVPlot_5.Position = [132 28 422 239];

            % Create JointPanel_6
            app.JointPanel_6 = uipanel(app.GridLayout);
            app.JointPanel_6.AutoResizeChildren = 'off';
            app.JointPanel_6.TitlePosition = 'centertop';
            app.JointPanel_6.Title = 'J6:  0 deg,   0 deg/s';
            app.JointPanel_6.Layout.Row = 3;
            app.JointPanel_6.Layout.Column = 2;
            app.JointPanel_6.FontWeight = 'bold';
            app.JointPanel_6.FontSize = 16;

            % Create PTSpinner_6
            app.PTSpinner_6 = uispinner(app.JointPanel_6);
            app.PTSpinner_6.Limits = [-100 100];
            app.PTSpinner_6.RoundFractionalValues = 'on';
            app.PTSpinner_6.Position = [81 4 62 22];

            % Create VTSpinner_6
            app.VTSpinner_6 = uispinner(app.JointPanel_6);
            app.VTSpinner_6.Limits = [-100 100];
            app.VTSpinner_6.RoundFractionalValues = 'on';
            app.VTSpinner_6.Position = [556 4 62 22];

            % Create Power0GaugeLabel_6
            app.Power0GaugeLabel_6 = uilabel(app.JointPanel_6);
            app.Power0GaugeLabel_6.HorizontalAlignment = 'center';
            app.Power0GaugeLabel_6.FontWeight = 'bold';
            app.Power0GaugeLabel_6.Position = [9 4 49 33];
            app.Power0GaugeLabel_6.Text = {'Power:'; '0%'};

            % Create PowerGauge_6
            app.PowerGauge_6 = uigauge(app.JointPanel_6, 'linear');
            app.PowerGauge_6.Limits = [-100 100];
            app.PowerGauge_6.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PowerGauge_6.Orientation = 'vertical';
            app.PowerGauge_6.MinorTicks = [];
            app.PowerGauge_6.Position = [9 35 48 224];

            % Create VTMaxCheckBox_6
            app.VTMaxCheckBox_6 = uicheckbox(app.JointPanel_6);
            app.VTMaxCheckBox_6.Text = 'Max V Only';
            app.VTMaxCheckBox_6.WordWrap = 'on';
            app.VTMaxCheckBox_6.FontSize = 10;
            app.VTMaxCheckBox_6.Position = [472 4 74 22];

            % Create PTEnableCheckBox_6
            app.PTEnableCheckBox_6 = uicheckbox(app.JointPanel_6);
            app.PTEnableCheckBox_6.Text = 'Enable P-Tracking';
            app.PTEnableCheckBox_6.WordWrap = 'on';
            app.PTEnableCheckBox_6.FontSize = 10;
            app.PTEnableCheckBox_6.Position = [150 4 124 22];
            app.PTEnableCheckBox_6.Value = true;

            % Create PTSlider_6
            app.PTSlider_6 = uislider(app.JointPanel_6);
            app.PTSlider_6.Limits = [-100 100];
            app.PTSlider_6.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.PTSlider_6.MajorTickLabels = {''};
            app.PTSlider_6.Orientation = 'vertical';
            app.PTSlider_6.MinorTicks = [];
            app.PTSlider_6.Position = [110 35 3 224];

            % Create VTSlider_6
            app.VTSlider_6 = uislider(app.JointPanel_6);
            app.VTSlider_6.Limits = [-100 100];
            app.VTSlider_6.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.VTSlider_6.MajorTickLabels = {''};
            app.VTSlider_6.Orientation = 'vertical';
            app.VTSlider_6.MinorTicks = [];
            app.VTSlider_6.Position = [585 35 3 224];

            % Create HomeLamp_6Label
            app.HomeLamp_6Label = uilabel(app.JointPanel_6);
            app.HomeLamp_6Label.HorizontalAlignment = 'right';
            app.HomeLamp_6Label.Position = [305 4 38 22];
            app.HomeLamp_6Label.Text = 'Home';

            % Create HomeLamp_6
            app.HomeLamp_6 = uilamp(app.JointPanel_6);
            app.HomeLamp_6.Position = [358 4 20 20];
            app.HomeLamp_6.Color = [0 0 0];

            % Create PVPlot_6
            app.PVPlot_6 = uiaxes(app.JointPanel_6);
            app.PVPlot_6.Toolbar.Visible = 'off';
            app.PVPlot_6.PlotBoxAspectRatio = [1.85 1 1];
            app.PVPlot_6.XLim = [0 10000];
            app.PVPlot_6.YLim = [-100 100];
            app.PVPlot_6.XTickLabel = '';
            app.PVPlot_6.XGrid = 'on';
            app.PVPlot_6.Position = [132 28 422 239];

            % Create LeftPanel
            app.LeftPanel = uipanel(app.UIFigure);
            app.LeftPanel.AutoResizeChildren = 'off';
            app.LeftPanel.Position = [0 0 250 900];

            % Create ConnectionPanel
            app.ConnectionPanel = uipanel(app.LeftPanel);
            app.ConnectionPanel.AutoResizeChildren = 'off';
            app.ConnectionPanel.Title = 'NXT Connection';
            app.ConnectionPanel.FontWeight = 'bold';
            app.ConnectionPanel.FontSize = 16;
            app.ConnectionPanel.Position = [1 779 249 121];

            % Create BluetoothNameLabel
            app.BluetoothNameLabel = uilabel(app.ConnectionPanel);
            app.BluetoothNameLabel.HorizontalAlignment = 'right';
            app.BluetoothNameLabel.Position = [41 70 91 22];
            app.BluetoothNameLabel.Text = 'Bluetooth Name:';

            % Create BluetoothNameEditField
            app.BluetoothNameEditField = uieditfield(app.ConnectionPanel, 'text');
            app.BluetoothNameEditField.ValueChangedFcn = createCallbackFcn(app, @BluetoothNameValueChanged, true);
            app.BluetoothNameEditField.Position = [136 70 73 22];
            app.BluetoothNameEditField.Value = 'NXT1';

            % Create ConnectToNXTButton
            app.ConnectToNXTButton = uibutton(app.ConnectionPanel, 'push');
            app.ConnectToNXTButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectToNXTButtonPushed, true);
            app.ConnectToNXTButton.Position = [41 10 168 22];
            app.ConnectToNXTButton.Text = 'Connect to NXT';

            % Create ConnectionStatusLabel
            app.ConnectionStatusLabel = uilabel(app.ConnectionPanel);
            app.ConnectionStatusLabel.HorizontalAlignment = 'center';
            app.ConnectionStatusLabel.Position = [40 41 168 20];
            app.ConnectionStatusLabel.Text = 'Not Connected';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RA15_Control_Panel_exported

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

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