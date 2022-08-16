classdef Modbus < instrument.interface.modbus.Modbus
    %MODBUS Construct a MODBUS TCP/IP communication object.
    
    %   Copyright 2019 The MathWorks, Inc.
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
            
            % Check for minimum number of arguments
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

            hasNVPairs = false;
            % Check if the transport has being passed in. If passed in,
            % extract and set required object properties.
            if strcmpi(class(varargin{2}),'matlabshared.network.internal.coder.TCPClient')
                obj.TcpIpObj = varargin{2};
                obj.TransportInjected = true;
            else
                % validate required DeviceAddress argument
                validateattributes(varargin{2},{'string','char','cell'},{'nonempty'},mfilename,'DeviceAddress',2);
                obj.DeviceAddress = string(varargin{2});
                
                switch(nargin)
                    case 2
                        obj.Port = obj.DefaultPort;
                    case 3
                        % validate remote port
                        port = varargin{3};
                        coder.internal.errorIf(~obj.localIsValidPort(port), 'instrument:modbus:invalidRemotePort');
                        obj.Port = port;
                    otherwise
                        % If remote port is not 3rd arg set to the default
                        port = varargin{3};
                        if isnumeric(port)
                            coder.internal.errorIf(~obj.localIsValidPort(port), 'instrument:modbus:invalidRemotePort');
                            obj.Port = port;
                        else
                            obj.Port = obj.DefaultPort;
                        end
                        hasNVPairs = true;
                end
                obj.createTransport();
            end
            
            % Connect the transport object the connection has not already been
            % established.
            obj.connectTransport();
            
            % Parse N-V pairs and initialize the object properties. Some 
            % of these may call through to the tcpip object, so this is done
            % after we've established a connection.
            if ~hasNVPairs
                % No extra N-V pair input
                obj.initProperties(cell(1,0), -1);
            else
                if isnumeric(varargin{3})
                    % When the 3rd input argument is port setting.
                    % Check if N-V pairs are passed as a set.
                    if mod(nargin - 3, 2) ~= 0
                        coder.internal.error('instrument:modbus:unmatchedPVPairs');
                    end
                    % The N-V pair starts at 4th input argument
                    obj.initProperties(varargin, 4);
                else
                    % When the 3rd input argument is NOT port setting.
                    % Check if N-V pairs are passed as a set.
                    if mod(nargin - 2, 2) ~= 0
                        coder.internal.error('instrument:modbus:unmatchedPVPairs');
                    end
                    % The N-V pair starts at 3rd input argument
                    obj.initProperties(varargin, 3);
                end
            end
            
            % Create the TCP/IP specific PacketBuilder
            obj.PacketBuilder = instrument.interface.modbus.tcpip.PacketBuilder(obj.Converter);
        end
        
        function delete(obj)
            % clean up
            obj.disconnectTransport();
        end
    end
    
    %% Dependent properties
    methods
        function set.Timeout(obj,val)
            % handler for Timeout property set
            obj.setTimeout(obj.TcpIpObj, val);
        end
        
        function val = get.Timeout(obj)
            % handler for Timeout property get
            val = obj.TcpIpObj.Timeout;
        end
        
    end
    
    %% Private methods
    methods (Access = private)
        
        function createTransport(obj)
            % Create a transport object (TCP/IP)
            obj.TcpIpObj = instrument.interface.coder.modbus.GetTransport('tcpip', obj.DeviceAddress, obj.Port);
        end        
        
        function connectTransport(obj)           
            % Connect the serial object if it is not already connected
            if ~obj.TcpIpObj.Connected && ~obj.TransportInjected
                connect(obj.TcpIpObj);
            end
        end
        
        function disconnectTransport(obj)
            % Disconnect the tcpip obj
            if ~isempty(obj.TcpIpObj)
                if obj.TcpIpObj.Connected && ~obj.TransportInjected
                    disconnect(obj.TcpIpObj);
                end
            end
        end
        
        function initProperties(obj, inputs, startIndex)
            % Partial match contructor N-V pairs and assign to properties
            % Set the parsing structs required for coder input parser            
            coder.inline('always');
            coder.internal.prefer_const(inputs);
            params = struct('ByteOrder', uint32(0),...
                'WordOrder', uint32(0),...
                'Timeout', uint32(0),...
                'NumRetries',  uint32(0));
            popts = struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', 'unique',...
                'IgnoreNulls',true);
            if isempty(inputs)
                % If there is no N-V pair input, just assign the properties
                % with default values
                obj.ByteOrder  = 'big-endian';
                obj.WordOrder  = 'big-endian';
                obj.NumRetries = 1;
                obj.Timeout    = 10;
            else
                % If there is N-V pair input, parse the input parameters.
                % For parameters that are not specifies, the parser just                  
                % assigns the properties with default values.
                optarg = coder.internal.parseParameterInputs(params, popts, inputs{startIndex:end});
                obj.ByteOrder  = coder.internal.getParameterValue(optarg.ByteOrder, 'big-endian', inputs{startIndex:end});
                obj.WordOrder  = coder.internal.getParameterValue(optarg.WordOrder, 'big-endian', inputs{startIndex:end});
                obj.NumRetries = coder.internal.getParameterValue(optarg.NumRetries, 1, inputs{startIndex:end});
                obj.Timeout    = coder.internal.getParameterValue(optarg.Timeout, 10, inputs{startIndex:end});
            end
        end
        
        function timedOut = waitForResponse(obj, bytesNeeded)
            % Wait for the response from the server within
            % TransactionTimeout seconds. If the slave responds within the
            % timeout period return false, otherwise return true.
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
        end
        
        function data = readBytes(obj, numBytes)
            % Perform a tcpip read. Explicitly extract all the numBytes
            % requested for read.
            dataRaw = read(obj.TcpIpObj, numBytes);
            data = double(dataRaw(1:numBytes));
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
            write(obj.TcpIpObj, reqPacket, 'uint8');
        end
        
        function [data,retry] = getReadResponse(obj)
            % Get the response to the read request
            retry = false;
            
            data = [];
            
            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinReadRespLen);
            
            % initialize data output arg to empty
            if (~timedOut)
                % Get the response
                % First read the 7 byte header
                obj.readBytes(7);
                % Function code
                fcnCode = uint8(obj.readBytes(1));
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8))
                    % If error, next byte will be error code. In this case,
                    % flush the IO and error out.
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    obj.translateandGenerateServerError(errCode,fcnCode);
                else
                    % Get the number of data bytes to read
                    byteCount = obj.readBytes(1);
                    if byteCount <= 0
                        coder.internal.error('instrument:modbus:invalidResponse');
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
                % Timeout occurred, call common timeout handler
                if isequal(obj.RetryCount,obj.NumRetries)
                    % out of retries
                    obj.flushIO;
                    obj.RetryCount = 0;
                    coder.internal.error('instrument:modbus:commReadError', "Timeout occurred waiting for a response.");
                else
                    retry = obj.handleTimeout;                    
                end
            else
                % Reset the retry count as no timeout occurred.
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
                fcnCode = uint8(obj.readBytes(1));
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8))
                    % If error, next byte will be error code. In this case,
                    % flush the IO and error out.
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    obj.translateandGenerateServerError(errCode,fcnCode);
                else
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(4);
                    if (~timedOut)
                        % Get the output address and count
                        obj.readBytes(4);
                    end
                end
            end
            
            if (~timedOut)
                % Reset the retry count as no timeout occurred.
                obj.RetryCount = 0;
            else
                % Timeout occurred, call common timeout handler
                if isequal(obj.RetryCount,obj.NumRetries)
                    % out of retries
                    obj.flushIO;
                    obj.RetryCount = 0;
                    coder.internal.error('instrument:modbus:commReadError', "Timeout occurred waiting for a response.");
                else
                    retry = obj.handleTimeout;                    
                end
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
                fcnCode = uint8(obj.readBytes(1));
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8))
                    % If error, next byte will be error code. In this case,
                    % flush the IO and error out.
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    obj.translateandGenerateServerError(errCode,fcnCode);
                else
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(6);
                    if (~timedOut)
                        % Get the address and both masks
                        obj.readBytes(6);
                    end
                end
            end
            
            if (~timedOut)
                % Reset the retry count as no timeout occurred.
                obj.RetryCount = 0;
            else
                % Timeout occurred, call common timeout handler
                if isequal(obj.RetryCount,obj.NumRetries)
                    % out of retries
                    obj.flushIO;
                    obj.RetryCount = 0;
                    coder.internal.error('instrument:modbus:commReadError', "Timeout occurred waiting for a response.");
                else
                    retry = obj.handleTimeout;                    
                end
            end
        end
        
        function prepareForRetry(obj)
            % Disconnect, then reconnect to the tcpip object before
            % attempting a retry.
            disconnect(obj.TcpIpObj);
            pause(.002);
            connect(obj.TcpIpObj);
        end
        
        function flushIO(obj)
            % Flush IO buffers
            flushInput(obj.TcpIpObj);
            flushOutput(obj.TcpIpObj);
        end
    end
end

