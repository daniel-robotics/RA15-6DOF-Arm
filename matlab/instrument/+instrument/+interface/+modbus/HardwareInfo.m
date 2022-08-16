classdef(Hidden) HardwareInfo
    % HARDWAREINFO Retrieve information about the modbus interface.
    %
    % The supported protocols and their available transports will be
    % displayed.

    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods (Hidden, Static)        
        function out = GetHardwareInfo()
            % GETHARDWAREINFO Construct an object containing modbus
            % interface information.
            % Protocols
            out.SupportedProtocols = ["serialrtu","tcpip"];
            % Transports
            % Get localhost information
            t = com.mathworks.toolbox.instrument.TCPIP('temp',80);
            tcpInfo = hardwareInfo(t);
            dispose(t);                    
            tcpInfo = cell(tcpInfo);   
            % Convert to string array
            out.LocalHost = string(tcpInfo{1}');
            % Get available serial ports
            out.AvailableSerialPorts = serialportlist("available");
        end
    end
end



