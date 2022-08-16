classdef Modbus < instrument.interface.modbus.Modbus
    %MODBUS Construct a MODBUS TCP/IP communication object.

    %   Copyright 2016-2019 The MathWorks, Inc.
    %#codegen

    properties (GetAccess = public, SetAccess = private)
        % Device IP Address or host name
        DeviceAddress  
        % Remote port
        Port           
    end
    
    properties (Hidden)
        % tcpip object used to communicate with server
        TcpIpObj
    end
    
    properties (Constant, Hidden)
        DefaultPort = 502;
        % mbap header (6 bytes) + server id (1 byte) + function code or 
        % error code (1 byte).
        MinWriteRespLen = 8;
        % read adds the 1 byte count
        MinReadRespLen = 9;
    end
    
    properties (Access = public, Dependent)
        % Amount of time to wait for a response from the Modbus
        % server.
        Timeout        
    end
    
    %% Constructor and destructor
    methods (Hidden)
        function obj = Modbus (varargin)
            
            narginchk(2,inf);
            
            % call through to the base class
            obj@instrument.interface.modbus.Modbus(varargin);               
            
            % nargin possibilities
            % 2  m = modbus('tcpip',ITransport)
            % 3+ m = modbus('tcpip',ITransport,'N','V'...)
            % 2  m = modbus('tcpip','192.168.2.177')
            % 3  m = modbus('tcpip','192.168.2.177',502)
            % 4+ m = modbus('tcpip','192.168.2.177',502,'N','V'...)
            %    m = modbus('tcpip','192.168.2.177','N','V'...)
            
            firstProp = 3;
            % Check for transport being passed in, not created here
            if isa(varargin{2},'matlabshared.transportlib.internal.ITransport')
                obj.TcpIpObj = varargin{2};
                obj.TransportInjected = true;
            else
                % validate required DeviceAddress argument
                validateattributes(varargin{2},{'string','char','cell'},{'nonempty'},mfilename,'DeviceAddress',2);
                obj.DeviceAddress = string(varargin{2});
                firstProp = 3;

                switch(nargin)
                case 2
                    obj.Port = obj.DefaultPort;
                case 3 
                    % validate remote port
                    port = varargin{3};
                    if ~obj.localIsValidPort(port)
                        throwAsCaller(MException('instrument:modbus:invalidRemotePort',...
                                message('instrument:modbus:invalidRemotePort').getString()));
                    end
                    obj.Port = port;
                    firstProp = 4;
                otherwise
                    % If remote port is not 3rd arg set to the default
                    port = varargin{3};
                    if obj.localIsValidPort(port)
                        obj.Port = port;                        
                        firstProp = 4;
                    else
                        obj.Port = obj.DefaultPort;
                    end
                end
            end            

            % Create the transport object if it was not passed in, and 
            % connect to it if the connection has not already been
            % established.
            try
                obj.createAndConnect(obj.DeviceAddress, obj.Port);
            catch ex
                throwAsCaller(ex);
            end 
            
            % Try setting the object properties. Some of these may
            % call through to the tcpip object, so this is done
            % after we've established a connection.            
            try
                inputs = varargin(firstProp:end);
                obj.initProperties(inputs);
            catch ex                       
                throwAsCaller(ex);
            end 
            
            % Create the TCP/IP specific PacketBuilder
            obj.PacketBuilder = instrument.interface.modbus.tcpip.PacketBuilder(obj.Converter);            
        end
        
        function delete(obj) 
            % clean up
            obj.disconnectAndDelete();
        end                      
    end
        
    %% Dependent properties
    methods
        function set.Timeout(obj,val)
            % handler for Timeout property set
            try
                obj.setTimeout(obj.TcpIpObj, val);
            catch ex
                throwAsCaller(ex);
            end                       
        end
        
        function val = get.Timeout(obj)
            % handler for Timeout property get
            val = obj.TcpIpObj.Timeout;
        end 
               
    end
    
    %% Private methods
    methods (Access = private)
                
        function createAndConnect(obj, host, port)
            % Helper function to connect the tcpip object
            try
                if ~obj.TransportInjected                    
                    obj.TcpIpObj = matlabshared.transportlib.internal. ...
                        TransportFactory.getTransport('tcpip', host, port);
                end
                % connect
                if ~obj.TcpIpObj.Connected
                    connect(obj.TcpIpObj);
                end
            catch ex                
                throw(MException(message('instrument:modbus:transportUnavailable', ex.message)));
            end           
        end
                
        function disconnectAndDelete(obj)
            % Disconnect the tcpip obj
            if ~isempty(obj.TcpIpObj) && isvalid(obj.TcpIpObj)
                if obj.TcpIpObj.Connected && ~obj.TransportInjected
                    disconnect(obj.TcpIpObj);
                end
                obj.TcpIpObj = [];
            end
        end
        
        function initProperties(obj, inputs)
            % Partial match contructor N-V pairs and assign to properties

            p = inputParser;
            p.PartialMatching = true;
            addParameter(p, 'ByteOrder', 'big-endian', @(x) validateattributes(x,{'char','string'},{'nonempty'}));            
            addParameter(p, 'WordOrder', 'big-endian', @(x) validateattributes(x,{'char','string'},{'nonempty'})); 
            addParameter(p, 'Timeout', 10, @isscalar);
            addParameter(p, 'NumRetries',  1, @isscalar);
            parse(p, inputs{:});
            output = p.Results;
            
            obj.ByteOrder = output.ByteOrder;   
            obj.WordOrder = output.WordOrder;
            obj.NumRetries = output.NumRetries;
            obj.Timeout = output.Timeout;
            
        end    
        
        function timedOut = waitForResponse(obj, bytesNeeded)
            % Wait for the response from the server within
            % TransactionTimeout seconds. If the slave responds within the
            % timeout period return false, otherwise return true.
            try
                timedOut = false;
                startTic = tic;
                
                % Wait for the response to be in the buffer
                while obj.TcpIpObj.NumBytesAvailable < bytesNeeded
                    if toc(startTic) > obj.TransactionTimeout
                        timedOut = true;
                        break;
                    end
                    pause(.001);                     
                end

            catch ex
                throw(ex);
            end
        end
        
        function data = readBytes(obj, numBytes)
            % Perform a tcpip read
            try
                data = read(obj.TcpIpObj, numBytes);
                data = double(data);
            catch ex
                throw(MException(message('instrument:modbus:commReadError',ex.message)));
            end
        end   
        
        function out = localIsValidPort(~,port)
            % Determine if the specified port is in a valid range.
            out = true;
            if (~(isa(port,'numeric') && (port >= 1) && (port <= 65535) && (fix(port) == port)))
                out = false;
            end      
        end                      
    end    
        
    %% Protected methods
    methods (Access = protected)
        
        function sendRequest(obj, reqPacket)
            % Send the request frame to the slave
            try
                write(obj.TcpIpObj, reqPacket, 'uint8');
            catch ex
                obj.flushIO;
                error(message('instrument:modbus:commWriteError',ex.message));
            end            
        end        
        
        function [data,retry] = getReadResponse(obj)
            % Get the response to the read request            
            retry = false;
            
            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinReadRespLen);
            
            % initialize data output arg to empty
            data = [];
            if (~timedOut)
                % Get the response
                
                % First read the 7 byte header
                obj.readBytes(7);                
                % Function code
                fcnCode = obj.readBytes(1);
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8, 'uint8'))
                    % If error, next byte will be error code                    
                    errCode = obj.readBytes(1);                    
                    obj.flushIO;
                    err = obj.translateServerError(errCode,fcnCode);
                    error(err);
                else
                    % Get the number of data bytes to read
                    byteCount = obj.readBytes(1); 
                    if byteCount <= 0
                        throw(MException(message('instrument:modbus:invalidResponse')));    
                    end     
                    
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(byteCount);
                    
                    if (~timedOut)
                        % Read the byte count and return the data                
                        data = obj.readBytes(byteCount);
                    end
                end
            end
            
            if (timedOut)
                % Timeout occurred, call common handler                
                retry = obj.handleTimeout('instrument:modbus:commReadError');
            else
                % there wasn't a timeout, so reset the retry count
                obj.RetryCount = 0;                                
            end            
        end
        
        function retry = getWriteResponse(obj)
            % Get the response to the write request
            retry = false;

            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinWriteRespLen);
            
            if (~timedOut)
                % Read the response

                % First read the 7 byte header
                obj.readBytes(7);
                % Function code
                fcnCode = obj.readBytes(1);
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8, 'uint8'))
                    % If error, next byte will be error code                    
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    err = obj.translateServerError(errCode,fcnCode);
                    error(err);
                else
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(4);
                    if (~timedOut)
                        % Get the output address and count
                        obj.readBytes(4);
                    end
                end
            end
            if (timedOut)
                % Timeout occurred, call common handler
                retry = obj.handleTimeout('instrument:modbus:commWriteError');
            else
                % there wasn't a timeout, so reset the retry count
                obj.RetryCount = 0;                                
            end                            
        end       
        
        function retry = getMaskWriteResponse(obj)
            % Get the response to the mask write request
            retry = false;

            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinWriteRespLen);
            
            if (~timedOut)
                % Read the response
                
                % First read the 7 byte header
                obj.readBytes(7);
                % Function code
                fcnCode = obj.readBytes(1);
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8, 'uint8'))
                    % If error, next byte will be error code
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    err = obj.translateServerError(errCode,fcnCode);
                    error(err);
                else
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(6);
                    if (~timedOut)                    
                        % Get the address and both masks
                        obj.readBytes(6);
                    end
                end
            end
            if (timedOut)
                % Timeout occurred, call common handler
                retry = obj.handleTimeout('instrument:modbus:commWriteError');
            else
                % there wasn't a timeout, so reset the retry count
                obj.RetryCount = 0;                                
            end                            
        end           
        
        function prepareForRetry(obj)
            % Disconnect, then reconnect to the tcpip object before
            % attempting a retry.
            try
                if ~obj.TransportInjected
                    % Disconnect the tcpip object
                    obj.disconnectAndDelete();

                    % Reconnect
                    obj.createAndConnect(char(obj.DeviceAddress),obj.Port);
                else
                    disconnect(obj.TcpIpObj);
                    pause(.002);
                    connect(obj.TcpIpObj);
                end
            catch ex
                throw(MException(message('instrument:modbus:transportUnavailable', ex.message)));
            end           
        end      
        
        function flushIO(obj)
            % Flush IO buffers            
            flushInput(obj.TcpIpObj);
            flushOutput(obj.TcpIpObj);
        end         
    end
    
    %% Object serialization
    methods (Static, Hidden = true)
        function out = loadobj(s)
            %LOADOBJ Creates and returns a new Modbus using the deserialized
            % data passed in. 

            % Initialize return value to empty
            out = [];
            if ~isstruct(s)
                return;
            end
            if isfield(s, 'TransportInjected') && s.TransportInjected
                if ~isempty(s.Transport)
                    try
                        out = instrument.interface.modbus.serialrtu.Modbus('tcpip',s.Transport);
                        out.NumRetries = s.NumRetries;
                        out.Timeout    = s.Timeout;
                        out.ByteOrder  = s.ByteOrder;
                        out.WordOrder  = s.WordOrder;
                    catch ex
                        warning(message('instrument:modbus:loadError', ex.message));
                    end
                end
            else
                try
                    out = modbus('tcpip',s.DeviceAddress,s.Port);
                    out.NumRetries = s.NumRetries;
                    out.Timeout    = s.Timeout;
                    out.ByteOrder  = s.ByteOrder;
                    out.WordOrder  = s.WordOrder;
                catch ex
                    warning(message('instrument:modbus:loadError', ex.message));
                end                
            end
        end
    end    
    
    methods (Hidden)        
        function s = saveobj(obj)
        %SAVEOBJ Returns values to serialize for this object
            s.DeviceAddress = obj.DeviceAddress;
            s.Port       = obj.Port;
            s.NumRetries = obj.NumRetries;
            s.Timeout    = obj.Timeout;
            s.ByteOrder  = obj.ByteOrder;
            s.WordOrder  = obj.WordOrder;
            s.ObjectVersion = obj.ObjectVersion;
            s.TransportInjected = obj.TransportInjected;
            if obj.TransportInjected
                s.Transport = obj.TcpIpObj;
            else
                s.Transport = [];
            end
        end        
    end
    
    %% Custom display overrides
    methods (Access = protected)
        
        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                headerStr = [headerStr ' TCPIP with properties:'];
                header = sprintf('%s\n',headerStr);
            end
        end        
        
        function displayScalarObject(obj)
            header = obj.getHeader();
            disp(header);
  
            % Display properties
            if ~obj.TransportInjected
                fprintf('    DeviceAddress: ''%s''\n',obj.DeviceAddress);
                fprintf('             Port: %d\n',obj.Port);
            end
            fprintf('           Status: ''%s''\n',obj.TcpIpObj.ConnectionStatus);
            fprintf('       NumRetries: %d\n',obj.NumRetries);
            fprintf('          Timeout: %d (seconds)\n',obj.Timeout);
            fprintf('        ByteOrder: ''%s''\n',obj.ByteOrder);
            fprintf('        WordOrder: ''%s''\n',obj.WordOrder);            
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end

    %------------------------------------------------------------------
    % For code generation support
    %------------------------------------------------------------------
    methods(Static)
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'instrument.interface.coder.modbus.tcpip.Modbus';
        end
    end      
end

