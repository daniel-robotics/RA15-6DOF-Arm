classdef Modbus < instrument.interface.modbus.Modbus
    %MODBUS Construct a MODBUS Serial RTU communication object.
    
    %   Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    properties (GetAccess = public, SetAccess = private)
        % Serial port identifier
        Port
    end
    
    properties (Constant, Hidden)
        ModbusTerminationDelay = 3.5;
        % server id (1 byte) + function code or
        % error code (1 byte).
        MinWriteRespLen = 2;
        % read adds the 1 byte count
        MinReadRespLen = 3;
    end
    
    properties (Access = public, Dependent)
        % BaudRate - Serial port baud rate. Default is 9600.
        BaudRate
        % DataBits - Number of serial data bits. Default is 8.
        DataBits
        % Parity - Serial port parity. Default is 'none'.
        Parity
        % StopBits - Number of serial stop bits. Default is 1.
        StopBits
        % Timeout - Amount of time to wait for a response from the Modbus
        % server.
        Timeout
    end
    
    properties (Hidden)
        % The serial interface used to communicate with the server
        SerialObj
        % The Serial RTU specific 3.5 character time delay at end
        % of packet tranmission to signify end of transmission.
        TerminationDelay
    end
    
    %% Constructor and destructor
    methods (Hidden)
        function obj = Modbus (varargin)
            
            % Check for minimum number of arguments
            narginchk(2,inf);
            
            % call through to the base class
            obj@instrument.interface.modbus.Modbus(varargin);
            
            % nargin possibilities
            % 2  m = modbus('serialrtu',ITransport)
            % 3+ m = modbus('serialrtu',ITransport,'N','V'...)
            % 2  m = modbus('serialrtu','COM1')
            % 3+ m = modbus('serialrtu','COM1','N','V'...)
            
            % Check if the transport has being passed in. If passed in,
            % extract and set required object properties.
            if strcmpi(class(varargin{2}),'matlabshared.seriallib.internal.coder.Serial')
                obj.SerialObj = varargin{2};
                obj.TransportInjected = true;
            else
                % Validate required Port argument
                validateattributes(varargin{2},{'string','char','cell'},{'nonempty'},mfilename,'Port',2);
                obj.Port = string(varargin{2});
                obj.createTransport();
            end
            
            % Extract the N-V pairs
            if nargin > 2
                % Initialize the varargin input parsing container
                inputs = cell(1, nargin - 2);
                start = 1;
                for count = 3:nargin
                    inputs{start} = varargin{count};
                    start = start + 1;
                end
                
                % Check if N-V pairs are passed as a set.
                if mod(numel(inputs), 2)
                    coder.internal.error('instrument:modbus:unmatchedPVPairs');
                end
            else
                inputs = cell(1,0);
            end

            % Connect the transport object the connection has not already been
            % established.
            obj.connectTransport();
            
            % Parse N-V pairs and initialize the object properties.
            obj.initProperties(inputs);
            
            % Create the Serial RTU specific PacketBuilder
            obj.PacketBuilder = instrument.interface.modbus.serialrtu.PacketBuilder(obj.Converter);
        end
        
        % destructor
        function delete(obj)
            % Clean up
            obj.disconnectTransport();
        end
    end
    
    %% Dependent properties
    methods
        function set.BaudRate(obj,val)
            % handler for BaudRate property set
            if obj.TransportInjected
                coder.internal.error('transportlib:transport:cannotSetWhenInjected','BaudRate');
            end
            validateattributes(val,{'numeric'},{'nonempty','scalar','nonnegative','finite'},mfilename,'BaudRate');
            obj.SerialObj.BaudRate = val;
        end
        function val = get.BaudRate(obj)
            % handler for BaudRate property get
            % TODO: g1974179 Update the getter and setters.
            % if obj.TransportInjected
            %     coder.internal.error('transportlib:transport:cannotGetWhenInjected','BaudRate');
            % end
            val = obj.SerialObj.BaudRate;
        end
        function set.DataBits(obj,val)
            % handler for DataBits property set
            if obj.TransportInjected
                coder.internal.error('transportlib:transport:cannotSetWhenInjected','DataBits');
            end
            validateattributes(val,{'numeric'},{'nonempty','scalar','nonnegative','finite'},mfilename,'DataBits');
            obj.SerialObj.DataBits = val;
        end
        function val = get.DataBits(obj)
            % handler for DataBits property get
            % TODO: g1974179 Update the getter and setters.
            % if obj.TransportInjected
            %     coder.internal.error('transportlib:transport:cannotGetWhenInjected','DataBits');
            % end
            val = obj.SerialObj.DataBits;
        end
        function set.StopBits(obj,val)
            % handler for StopBits property set
            if obj.TransportInjected
                coder.internal.error('transportlib:transport:cannotSetWhenInjected','StopBits');
            end
            validateattributes(val,{'numeric'},{'nonempty','scalar','nonnegative','finite'},mfilename,'StopBits');
            obj.SerialObj.StopBits = val;
        end
        function val = get.StopBits(obj)
            % handler for StopBits property get
            % TODO: g1974179 Update the getter and setters.
            % if obj.TransportInjected
            %     coder.internal.error('transportlib:transport:cannotGetWhenInjected','StopBits');
            % end
            val = obj.SerialObj.StopBits;
        end
        function set.Parity(obj,val)
            % handler for Parity property set
            if obj.TransportInjected
                coder.internal.error('transportlib:transport:cannotSetWhenInjected','Parity');
            end
            validateattributes(val,{'char', 'string'},{'nonempty'},mfilename,'Parity');
            obj.SerialObj.Parity = char(val);
        end
        function val = get.Parity(obj)
            % handler for Parity property get
            % TODO: g1974179 Update the getter and setters.
            % if obj.TransportInjected
            %     coder.internal.error('transportlib:transport:cannotGetWhenInjected','Parity');
            % end
            val = obj.SerialObj.Parity;
        end
        function set.Timeout(obj,val)
            % handler for Timeout property set
            obj.setTimeout(obj.SerialObj, val);
        end
        function val = get.Timeout(obj)
            % handler for Timeout property get
            val = obj.SerialObj.Timeout;
        end
        function val = get.TerminationDelay(obj)
            % handler for TerminationDelay property get
            val = obj.ModbusTerminationDelay * (1/obj.BaudRate);
            
            % TerminationDelay is used by pause when sending write request.
            % The generate code uses "windows.h" and the sleep method it
            % provides which has a minimum threshold of 1 millisec. Here we
            % check for the TerminationDelay value and update it to the 1
            % millisec if required.
            if val<0.001
                val = 0.001;
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        
        function createTransport(obj)
            % Create a transport object (Serial)
            obj.SerialObj = instrument.interface.coder.modbus.GetTransport('serial', obj.Port);
        end
        
        function connectTransport(obj)           
            % Connect the serial object if it is not already connected
            if ~obj.SerialObj.Connected && ~obj.TransportInjected
                connect(obj.SerialObj);
            end
        end
        
        function disconnectTransport(obj)
            % Disconnect the serial obj
            if ~isempty(obj.SerialObj)
                if obj.SerialObj.Connected && ~obj.TransportInjected
                    disconnect(obj.SerialObj);
                end
            end
        end
        
        function initProperties(obj, inputs)
            % Partial match contructor N-V pairs and assign to properties
            % Set the parsing structs required for coder input parser
            coder.inline('always')
            coder.internal.prefer_const(inputs);
            params = struct('BaudRate', uint32(0),...
                'DataBits', uint32(0),...
                'Parity', uint32(0),...
                'StopBits', uint32(0),...
                'ByteOrder', uint32(0),...
                'WordOrder', uint32(0),...
                'Timeout', uint32(0),...
                'NumRetries',  uint32(0));
            popts = struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', 'unique',...
                'IgnoreNulls',true);
            
            optarg = coder.internal.parseParameterInputs(params, popts, inputs{:});
            
            if ~obj.TransportInjected
                obj.BaudRate = coder.internal.getParameterValue(optarg.BaudRate, 9600, inputs{:});
                obj.DataBits = coder.internal.getParameterValue(optarg.DataBits, 8, inputs{:});
                obj.Parity   = coder.internal.getParameterValue(optarg.Parity, 'none', inputs{:});
                obj.StopBits = coder.internal.getParameterValue(optarg.StopBits, 1, inputs{:});                
            end
            obj.ByteOrder  = coder.internal.getParameterValue(optarg.ByteOrder, 'big-endian', inputs{:});
            obj.WordOrder  = coder.internal.getParameterValue(optarg.WordOrder, 'big-endian', inputs{:});
            obj.Timeout    = coder.internal.getParameterValue(optarg.Timeout, 10, inputs{:});
            obj.NumRetries = coder.internal.getParameterValue(optarg.NumRetries, 1, inputs{:});
        end
        
        function timedOut = waitForResponse(obj, bytesNeeded)
            % Wait for the response from the server within
            % TransactionTimeout seconds. If the slave responds within the
            % timeout period return false, otherwise return true.
            timedOut = false;
            startTic = tic;
            
            % Wait for the response to be in the buffer
            while obj.SerialObj.NumBytesAvailable < bytesNeeded
                if toc(startTic) > obj.TransactionTimeout
                    timedOut = true;
                    break;
                end
                pause(.001);
            end
        end
        
        function data = readBytes(obj, numBytes)
            % Perform a serial read. Explicitly extract all the numBytes
            % requested for read.
            dataRaw = read(obj.SerialObj, numBytes);
            data = double(dataRaw(1:numBytes));
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        
        function sendRequest(obj, reqPacket)
            % Send the request frame to the slave and wait for time decided
            % based on the baudrate.
            write(obj.SerialObj, reqPacket, 'uint8');
            pause(obj.TerminationDelay);
        end
        
        function [data, retry] = getReadResponse(obj)
            retry = false;
            data = [];
            
            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinReadRespLen);
            
            % Process ReadResponse if there is no timeout
            if (~timedOut)
                % Read the response from the slave
                devId = obj.readBytes(1);
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
                    % Make sure the data is available to be read. Number of
                    % data bytes plus two bytes for the CRC.
                    timedOut = obj.waitForResponse(byteCount + 2);
                    if (~timedOut)
                        % Read the byte count and return the data
                        data = obj.readBytes(byteCount);
                        % Validate the CRC
                        crcLow = uint16(obj.readBytes(1));
                        crcHigh = uint16(obj.readBytes(1));
                        crc = bitshift(crcHigh,8) + crcLow;
                        msg = [uint8(devId) uint8(fcnCode) uint8(byteCount) data];
                        if (~obj.PacketBuilder.verifyCRC(msg,crc))
                            coder.internal.error('instrument:modbus:commReadError',...
                                "The Modbus server returned a incorrect CRC value.");
                        end
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
        
        function retry = getWriteResponse(obj)
            % assume success
            retry = false;
            
            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinWriteRespLen);
            
            if (~timedOut)
                % Read the response from the slave
                devId = obj.readBytes(1);
                fcnCode = uint8(obj.readBytes(1));
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8))
                    % If error, next byte will be error code. In this case,
                    % flush the IO and error out.
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    obj.translateandGenerateServerError(errCode,fcnCode);
                else
                    % Address + count + CRC
                    byteCount = 6;
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(byteCount);
                    
                    if (~timedOut)
                        % Get the output address
                        addrHi  = obj.readBytes(1);
                        addrLow = obj.readBytes(1);
                        % Get the write count
                        dataHi  = obj.readBytes(1);
                        dataLow = obj.readBytes(1);
                        
                        % Validate the CRC
                        crcLow = uint16(obj.readBytes(1));
                        crcHigh = uint16(obj.readBytes(1));
                        crc = bitshift(crcHigh,8) + crcLow;
                        msg = [uint8(devId) uint8(fcnCode) uint8(addrHi) uint8(addrLow)...
                            uint8(dataHi) uint8(dataLow)];
                        if (~obj.PacketBuilder.verifyCRC(msg,crc))
                            coder.internal.error('instrument:modbus:commWriteError',...
                                "The Modbus server returned a incorrect CRC value.");
                        end
                    end
                end
            end
            
            if (~timedOut)
                % Reset the retry count as no timeout occurred.
                obj.RetryCount = 0;
            else
                % Timeout occurred, call the common timeout handler
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
                % Read the response from the slave
                devId = obj.readBytes(1);
                fcnCode = uint8(obj.readBytes(1));
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8))
                    % If error, next byte will be error code. In this case,
                    % flush the IO and error out.
                    errCode = obj.readBytes(1);
                    obj.flushIO;
                    obj.translateandGenerateServerError(errCode,fcnCode);
                else
                    % Address + masks + CRC
                    byteCount = 8;
                    % Make sure the data is available to be read
                    timedOut = obj.waitForResponse(byteCount);
                    
                    if (~timedOut)
                        % Get the address and masks
                        addrHi  = obj.readBytes(1);
                        addrLow = obj.readBytes(1);
                        andHi   = obj.readBytes(1);
                        andLow  = obj.readBytes(1);
                        orHi    = obj.readBytes(1);
                        orLow   = obj.readBytes(1);
                        
                        % Validate the CRC
                        crcLow = uint16(obj.readBytes(1));
                        crcHigh = uint16(obj.readBytes(1));
                        crc = bitshift(crcHigh,8) + crcLow;
                        msg = [uint8(devId) uint8(fcnCode) uint8(addrHi) uint8(addrLow)...
                            uint8(andHi) uint8(andLow) uint8(orHi) uint8(orLow)];
                        if (~obj.PacketBuilder.verifyCRC(msg,crc))
                            coder.internal.error('instrument:modbus:commWriteError',...
                                "The Modbus server returned a incorrect CRC value.");
                        end
                    end
                end
            end
            
            if (~timedOut)
                % Reset the retry count as no timeout occurred.
                obj.RetryCount = 0;
            else
                % Timeout occurred, call the common timeout handler
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
        
        function flushIO(obj)
            % Flush IO buffers
            flushInput(obj.SerialObj);
            flushOutput(obj.SerialObj);
        end
    end
end

