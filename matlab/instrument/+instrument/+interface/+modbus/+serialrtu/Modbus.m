classdef Modbus < instrument.interface.modbus.Modbus
    %MODBUS Construct a MODBUS Serial RTU communication object.

    %   Copyright 2016-2019 The MathWorks, Inc.
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
            
            narginchk(2,inf);
            
            % call through to the base class            
            obj@instrument.interface.modbus.Modbus(varargin);
            
            % nargin possibilities
            % 2  m = modbus('serialrtu',ITransport)
            % 3+ m = modbus('serialrtu',ITransport,'N','V'...)
            % 2  m = modbus('serialrtu','COM1')
            % 3+ m = modbus('serialrtu','COM1','N','V'...)

            % Check for transport being passed in, not created here
            if isa(varargin{2},'matlabshared.transportlib.internal.ITransport')
                obj.SerialObj = varargin{2};
                obj.TransportInjected = true;
            else
                % validate required Port argument
                validateattributes(varargin{2},{'string','char','cell'},{'nonempty'},mfilename,'Port',2);
                obj.Port = string(varargin{2});
            end
            
            % Create the transport object if it was not passed in, and 
            % connect to it if the connection has not already been
            % established.
            try
                obj.createAndConnect(obj.Port);
            catch ex
                throwAsCaller(ex);
            end
            
            % Initialize properties            
            try
                inputs = varargin(3:end);
                obj.initProperties(inputs);
            catch ex                    
                throwAsCaller(ex);
            end
            
            % Create the Serial RTU specific PacketBuilder
            obj.PacketBuilder = instrument.interface.modbus.serialrtu.PacketBuilder(obj.Converter);
        end
        
        % destructor
        function delete(obj)
            % Clean up
            obj.disconnectAndDelete();
        end                           
    end    
        
    %% Dependent properties
    methods       
        function set.BaudRate(obj,val)
            % handler for BaudRate property set
            if obj.TransportInjected
               error(message('transportlib:transport:cannotSetWhenInjected','BaudRate'));
            end
            try
                validateattributes(val,{'numeric'},{'nonnegative','finite'},'BaudRate','BaudRate');
                obj.SerialObj.BaudRate = val;
            catch ex
                throwAsCaller(ex);
            end                
            
            % update the termination delay based on baud rate setting
            obj.TerminationDelay = obj.ModbusTerminationDelay * (1/obj.BaudRate);
        end
        function val = get.BaudRate(obj)
            % handler for BaudRate property get  
            if obj.TransportInjected
               error(message('transportlib:transport:cannotGetWhenInjected','BaudRate'));
            end
            val = obj.SerialObj.BaudRate;
        end
        function set.DataBits(obj,val)
            % handler for DataBits property set
            if obj.TransportInjected
               error(message('transportlib:transport:cannotSetWhenInjected','DataBits'));
            end            
            try
                validateattributes(val,{'numeric'},{'nonnegative','finite'},'DataBits','DataBits');
                obj.SerialObj.DataBits = val;
            catch ex
                throwAsCaller(ex);
            end                        
        end
        function val = get.DataBits(obj)
            % handler for DataBits property get
            if obj.TransportInjected
               error(message('transportlib:transport:cannotGetWhenInjected','DataBits'));
            end
            val = obj.SerialObj.DataBits;
        end
        function set.StopBits(obj,val)
            % handler for StopBits property set
            if obj.TransportInjected
               error(message('transportlib:transport:cannotSetWhenInjected','StopBits'));
            end
            try
                validateattributes(val,{'numeric'},{'nonnegative','finite'},'StopBits','StopBits');
                obj.SerialObj.StopBits = val;
            catch ex
                throwAsCaller(ex);
            end                            
        end
        function val = get.StopBits(obj)
            % handler for StopBits property get
            if obj.TransportInjected
               error(message('transportlib:transport:cannotGetWhenInjected','StopBits'));
            end
            val = obj.SerialObj.StopBits;
        end
        function set.Parity(obj,val)
            % handler for Parity property set
            if obj.TransportInjected
               error(message('transportlib:transport:cannotSetWhenInjected','Parity'));
            end
            try
                validateattributes(val,{'char', 'string'},{'nonempty'},'Parity','Parity');
                if (isstring(val))
                    val = char(val);
                end                
                obj.SerialObj.Parity = val;
            catch ex
                throwAsCaller(ex);
            end                
        end
        function val = get.Parity(obj)
            % handler for Parity property get
            if obj.TransportInjected
               error(message('transportlib:transport:cannotGetWhenInjected','Parity'));
            end
            val = obj.SerialObj.Parity;
        end   
        function set.Timeout(obj,val)
            % handler for Timeout property set
            try
                obj.setTimeout(obj.SerialObj, val);
            catch ex
                throwAsCaller(ex);
            end                
        end
        function val = get.Timeout(obj)
            % handler for Timeout property get
            val = obj.SerialObj.Timeout;
        end        
    end
    
    %% Private methods
    methods (Access = private)
                
        function createAndConnect(obj, port)
            % helper function to create and connect the serial object
            try        
                if ~obj.TransportInjected
                    obj.SerialObj = matlabshared.transportlib.internal. ...
                        TransportFactory.getTransport('serial', port);
                end
                % connect
                if ~obj.SerialObj.Connected
                    connect(obj.SerialObj);
                end
            catch ex
                throw(MException(message('instrument:modbus:transportUnavailable', ex.message)));
            end        
        end
        
        function disconnectAndDelete(obj)
            % Close and delete the serial obj            
            if ~isempty(obj.SerialObj) && isvalid(obj.SerialObj)
                if obj.SerialObj.Connected && ~obj.TransportInjected
                    disconnect(obj.SerialObj);
                end
                obj.SerialObj = [];
            end
        end
                
        function initProperties(obj, inputs)
            % Partial match contructor N-V pairs and assign to properties
            p = inputParser;
            p.PartialMatching = true;
            addParameter(p, 'BaudRate', 9600, @isscalar);
            addParameter(p, 'DataBits', 8, @isscalar);
            addParameter(p, 'Parity', 'none', @(x) validateattributes(x,{'char','string'},{'nonempty'}));
            addParameter(p, 'StopBits', 1, @isscalar);
            addParameter(p, 'ByteOrder', 'big-endian', @(x) validateattributes(x,{'char','string'},{'nonempty'})); 
            addParameter(p, 'WordOrder', 'big-endian', @(x) validateattributes(x,{'char','string'},{'nonempty'})); 
            addParameter(p, 'Timeout', 10, @isscalar);
            addParameter(p, 'NumRetries', 1, @isscalar);            
            parse(p, inputs{:});
            output = p.Results;
            
            if ~obj.TransportInjected
                obj.BaudRate  = output.BaudRate;
                obj.DataBits  = output.DataBits;
                obj.Parity    = output.Parity;
                obj.StopBits  = output.StopBits;
            end
            obj.ByteOrder = output.ByteOrder;            
            obj.WordOrder = output.WordOrder;            
            obj.Timeout   = output.Timeout;
            obj.NumRetries  = output.NumRetries;            
        end
        
        function timedOut = waitForResponse(obj, bytesNeeded)
            % Wait for the response from the server within
            % TransactionTimeout seconds. If the slave responds within the
            % timeout period return false, otherwise return true.
            try
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

            catch ex
                throw(ex);
            end
        end
        
        function data = readBytes(obj, numBytes)
            % Perform a serial read
            try
                data = read(obj.SerialObj, numBytes);
                data = double(data);
            catch ex
                throw(MException(message('instrument:modbus:commReadError',ex.message)));
            end           
        end
    end    
    
    %% Protected methods
    methods (Access = protected)

        function sendRequest(obj, reqPacket)
            % Send the request frame to the slave
            try
                write(obj.SerialObj, reqPacket, 'uint8');
                pause(obj.TerminationDelay);
            catch ex
                obj.flushIO;
                error(message('instrument:modbus:commWriteError',ex.message));
            end            
        end
        
        function [data, retry] = getReadResponse(obj)
            retry = false;

            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinReadRespLen);
            
            % initialize data output arg to empty
            data = [];            
            if (~timedOut)                
                % Read the response from the slave
                devId = obj.readBytes(1);
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
                            errmsg = message('instrument:modbus:crcCheckFailed').getString();
                            error(message('instrument:modbus:commReadError',errmsg));
                        end
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
            % assume success
            retry = false;
            
            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinWriteRespLen);
            
            if (~timedOut)
                % Read the response from the slave
                devId = obj.readBytes(1);
                fcnCode = obj.readBytes(1);
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8, 'uint8'))
                    % If error, next byte will be error code
                    errCode = obj.readBytes(1);  
                    obj.flushIO;
                    err = obj.translateServerError(errCode,fcnCode);
                    error(err);
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
                            errmsg = message('instrument:modbus:crcCheckFailed').getString();
                            error(message('instrument:modbus:commWriteError',errmsg));
                        end
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
               
        function retry = getMaskWriteResponse(obj)
            % Get the response to the mask write request
            retry = false;

            % wait for server response or timeout
            timedOut = obj.waitForResponse(obj.MinWriteRespLen);
            
            if (~timedOut)
                % Read the response from the slave
                devId = obj.readBytes(1);
                fcnCode = obj.readBytes(1);
                % If MSB in function code is set there is an error
                if (bitget(fcnCode, 8, 'uint8'))
                    % If error, next byte will be error code
                    errCode = obj.readBytes(1);  
                    obj.flushIO;
                    err = obj.translateServerError(errCode,fcnCode);
                    error(err);
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
                            errmsg = message('instrument:modbus:crcCheckFailed').getString();
                            error(message('instrument:modbus:commWriteError',errmsg));
                        end
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
        
        function flushIO(obj)
            % clean IO buffers 
            flushInput(obj.SerialObj);
            flushOutput(obj.SerialObj);
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
                        out = instrument.interface.modbus.serialrtu.Modbus('serialrtu',s.Transport);
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
                    out = instrument.interface.modbus.serialrtu.Modbus('serialrtu',s.Port);
                    out.NumRetries = s.NumRetries;
                    out.Timeout    = s.Timeout;
                    out.ByteOrder  = s.ByteOrder;
                    out.WordOrder  = s.WordOrder;
                    out.BaudRate   = s.BaudRate;
                    out.DataBits   = s.DataBits;
                    out.Parity     = s.Parity;
                    out.StopBits   = s.StopBits;                
                catch ex
                    warning(message('instrument:modbus:loadError', ex.message));
                end
            end
        end
    end

    methods (Hidden)        
        function s = saveobj(obj)
        %SAVEOBJ Returns values to serialize for this object
            s.Port       = obj.Port;            
            s.NumRetries = obj.NumRetries;
            s.Timeout    = obj.Timeout;
            s.ByteOrder  = obj.ByteOrder;
            s.WordOrder  = obj.WordOrder;
            s.BaudRate   = obj.BaudRate;
            s.DataBits   = obj.DataBits;
            s.Parity     = obj.Parity;
            s.StopBits   = obj.StopBits;
            s.TransportInjected = obj.TransportInjected;
            if obj.TransportInjected
                s.Transport = obj.SerialObj;
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
                headerStr = [headerStr ' Serial RTU with properties:'];
                header    = sprintf('%s\n',headerStr);
            end
        end        
        
        function displayScalarObject(obj)
            header = obj.getHeader();
            disp(header);
  
            % Display properties
            if ~obj.TransportInjected
                fprintf('             Port: ''%s''\n',obj.Port);
                fprintf('         BaudRate: %d\n',obj.BaudRate);
                fprintf('         DataBits: %d\n',obj.DataBits);
                fprintf('           Parity: ''%s''\n',obj.Parity);
                fprintf('         StopBits: %d\n',obj.StopBits);
            end
            fprintf('           Status: ''%s''\n',obj.SerialObj.ConnectionStatus);
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
            name = 'instrument.interface.coder.modbus.serialrtu.Modbus';
        end
    end        
end

