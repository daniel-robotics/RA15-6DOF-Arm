classdef Modbus < handle
    %MODBUS Base class for transport specific classes which are created
    % using the modbus function on the MATLAB path.
    
    %   Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    properties (Constant, Hidden)
        % Valid transports
        Transports = {'tcpip', 'serialrtu'};
        
        % Valid count ranges as defined in the Modbus protocol
        % specification:
        % http://www.modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf
        DiscreteReadCountRange  = [1,2000];
        RegisterReadCountRange  = [1,125];
        DiscreteWriteCountRange = [1,1968];
        RegisterWriteCountRange = [1,123];
        ServerIdRange           = [0,247];
        
        DefaultServerId = 1; % If optional serverId is not used
        DefaultCount = 1;    % If optional count is not used
        
        Precisions = {'int16','uint16','int32','uint32','single','double',...
            'int64','uint64'};
        
        % Used to manage object serialization versioning
        ObjectVersion = 1;
        
        % Valid targets to read/write
        WriteTargets = {'coils', 'holdingregs'};
        ReadTargets  = {'coils', 'inputs', 'holdingregs', 'inputregs'};
        ReadFcnCodes = [1, 2, 3, 4];
        
        % Modbus defined error bit in response data is 128 (0x80), so mask
        % for this bit is 127 (0x7F).
        ErrorMask = 127;
    end
    
    properties (Access = public)
        % NumRetries - Number of retries to perform if there is no reply
        %              from the server after a timeout. Default is 1.
        NumRetries
    end
    
    properties (Dependent, Access = public)
        % ByteOrder - Byte order of data sent to/from Modbus server.
        %             Default is 'big-endian'.
        ByteOrder
        % WordOrder - Word order of data sent to/from the Modbus server
        %             when a value spans multiple 16 bit registers.
        %             Default is 'big-endian'.
        WordOrder
    end
    
    properties (Hidden, Access = protected)
        % Amount of time to wait for a response from the Modbus
        % server after sending a command. This value will always match the
        % transport Timeout property but is handled separately to account
        % for the transport injection option.
        TransactionTimeout
        
        % Tracks whether this object created and owns the transport, or if
        % it was passed into the constructor.
        TransportInjected = false;
        
        % How many retries have occurred
        RetryCount = 0;
        
        % Creates Modbus request packets for a specific transport
        PacketBuilder
        
        % Provides data conversion support to/from Modbus registers.
        Converter
    end
    
    %% Constructor and destructor
    methods (Hidden)
        
        function obj = Modbus (varargin)
            % Constructor - This is never called directly            
            % Create the data converter
            obj.Converter = instrument.interface.coder.modbus.DataConverter;
        end
        
        function delete(obj)
            % Delete does not empty any objects out due to codegeneration
            % limitations.
        end
    end
    
    %% Dependent properties
    methods
        function set.ByteOrder(obj,val)
            % handler for ByteOrder property set
            validateattributes(val, {'char','string'}, {'nonempty'}, mfilename, 'ByteOrder');           
            obj.Converter.ByteOrder = char(val);
        end
        function out = get.ByteOrder(obj)
            % handler for ByteOrder property get
            out = obj.Converter.ByteOrder;
        end
        function set.WordOrder(obj,val)
            % handler for WordOrder property set
            validateattributes(val, {'char','string'}, {'nonempty'}, mfilename, 'ByteOrder'); 
            obj.Converter.WordOrder = char(val);
        end
        function out = get.WordOrder(obj)
            % handler for v property get
            out = obj.Converter.WordOrder;
        end
    end
    
    %% Non-dependent properties
    methods
        function set.NumRetries(obj,val)
            % handler for NumRetries property set
            validateattributes(val,{'numeric'},{'nonempty','finite','positive','scalar','integer'},mfilename,'NumRetries');
            obj.NumRetries = val;
        end
        
        function out = get.NumRetries(obj)
            % handler for NumRetries property get
            out = obj.NumRetries;
        end
    end
    
    %% Public methods
    methods
        function data = read(varargin)
            % READ Perform a read operation on the connected Modbus server.
            %
            % Syntax:
            % data = read(obj,target,address)
            % data = read(obj,target,address,count)
            % data = read(obj,target,address,count,serverId)
            % data = read(obj,target,address,count,'precision')
            % data = read(obj,target,address,count,serverId,'precision')
            %
            % Description:
            % This function will perform a read operation from one of four
            % target addressable areas: Coils, Inputs, Holding Registers, or
            % Input Registers. Each of the four areas corresponds to a unique
            % Modbus function code, which may or may not be supported by the
            % connected Modbus server.
            %
            % Input Arguments:
            % obj         modbus object
            % 'target'	  Specifies the area to read. The valid choices are
            %             'coils', 'inputs', 'inputregs' and 'holdingregs'.
            % address 	  The starting address to read from.
            % count       The number of values to read. Optional, default is 1.
            %             Count is a scalar when doing reads of the same data type.
            %             Count is a vector of integers for reading multiple
            %             contiguous registers containing different data types.
            %             The number of values for count must match the
            %             number of values for precision.
            % serverId	  The address of the server to send this command to.
            %             Valid values are 0-247, with 0 being the broadcast
            %             address. Optional, default is 1.
            % 'precision' Specifies the data format of the register being read
            %             from on the Modbus server. Valid values are 'uint16',
            %             'int16', 'uint32', 'int32', 'uint64', 'int64',
            %             'single', and 'double'. Optional, default is ‘uint16’.
            %
            %             'single' and 'double' conversions conform to the IEEE
            %             754 floating point standard. For signed integers a
            %             two's complement conversion is performed. Note that
            %             'precision' does not refer to the return type (always
            %             'double'), it only specifies how to interpret the
            %             register data.
            %
            %             Precision is a string or char array when doing
            %             reads of the same data type.
            %             For reading multiple contiguous registers containing
            %             different data types, precision must be a cell
            %             array of strings or character vectors,
            %             or a string array of precisions. The number
            %             of precision values must match the number of
            %             count values.
            %             Only for tagets: inputregs and holdingregs.
            %
            % Examples:
            %
            % m = modbus('serialrtu', 'COM6');
            %
            % % Read 8 coil values starting at address 101 from server id 1
            % address = 101;
            % data = read(m,'coils',address,8,1)
            %
            % % Read 1 holding register at address 9 whose data format is
            % % unsigned 16 bit integer
            % address = 9;
            % read(m,'holdingregs',address)
            %
            % % Read 4 input registers starting at address 601 whose data
            % % format is signed 16 bit integer
            % address = 601;
            % read(m,'inputregs',address,4,'int16');
            %
            % % Read 2 holding registers whose data format is unsigned 16
            % % bit integer and 4 holding registers whose data format is
            % % double, in one read, at address 500.
            % address = 500;
            % precision = {'uint16', 'double'};
            % count = [2, 4];
            % read(m, 'holdingregs', address, count, precision);
            % clear m
            %
            %   See also WRITE
            narginchk(3,6);
                        
            obj = varargin{1};
            if length(obj) > 1
                coder.internal.error('instrument:modbus:invalidOBJDim');
            end
            
            % Extract Target and Address from passed params
            target  = obj.validateTarget(varargin{2}, 'read', 2, instrument.interface.coder.modbus.Modbus.ReadTargets);
            coder.internal.assert(eml_is_const(target), 'instrument:modbus:compileConstInputArgs');
            address = obj.validateAddress(varargin{3}, 3, 'address');
            
            % If target is coils or inputs max allowed input args are 5
            coder.internal.assert(~((strcmpi(target,'coils') || strcmpi(target,'inputs')) && nargin > 5), 'instrument:modbus:invalidNarginForTarget', char(target));
            
            % assign default serverId
            serverId = obj.DefaultServerId;
            
            if strcmpi(target,'coils') || strcmpi(target,'inputs')
                countLow = instrument.interface.coder.modbus.Modbus.DiscreteReadCountRange(1);
                countHi  = instrument.interface.coder.modbus.Modbus.DiscreteReadCountRange(2);
            else
                countLow = instrument.interface.coder.modbus.Modbus.RegisterReadCountRange(1);
                countHi  = instrument.interface.coder.modbus.Modbus.RegisterReadCountRange(2);
            end
            
            % Given the number of input arguments passed and target being
            % read from, assign the serverId and precion to be used by
            % read.
            switch nargin
                case 5
                    if strcmpi(target,'coils') || strcmpi(target,'inputs')
                        serverId = obj.validateServerId(varargin{5}, 5);
                        precision = 'uint16';
                    else
                        if isnumeric(varargin{5})
                            serverId = obj.validateServerId(varargin{5}, 5);
                            precision = 'uint16';
                        else
                            precision = obj.validateAllPrecision(varargin{5}, 5);
                        end
                    end
                case 6
                    if strcmpi(target,'coils') || strcmpi(target,'inputs')
                        coder.internal.error('instrument:modbus:incorrectTarget');
                    end
                    serverId = obj.validateServerId(varargin{5}, 5);
                    precision = obj.validateAllPrecision(varargin{6}, 6);
                otherwise
                    precision = 'uint16';
            end

            % Check the inputs count and precision when passed
            if nargin > 3
                count = varargin{4};
                % Column Cell array of precision converted to row cell
                % arrays.
                if size(precision, 1) ~= 1
                    precision = precision';
                end
                
                % Column Cell array of counts converted to row cell
                % arrays.
                if size(count, 1) ~= 1
                    count = count';
                end
                
                % Count validation
                count = obj.validateCount(count, precision,...
                    countLow, countHi,4, 'count');
            else
                count = obj.DefaultCount;
            end
            
            % Create readFn based on precision-count flag
            if iscell(precision)
                readFn = ['read' target 'contiguous'];
            else
                readFn = ['read' target];
            end
            
            % Call the corresponding read method to read data
            data = obj.(readFn)(address, count, serverId, precision);
        end
        
        function write(varargin)
            % WRITE Perform a write operation to the connected Modbus server.
            %
            % Syntax:
            % write(obj,target,address,values)
            % write(obj,target,address,values,serverId)
            % write(obj,target,address,values,'precision')
            % write(obj,target,address,values,serverId,'precision')
            %
            % Description:
            % This function will perform a write operation to one of two
            % writable target addressable areas: Coils or Holding Registers.
            % Each of the two areas can accept a write request to a single
            % address, or a contiguous address range. Each possibility
            % (single coil, multiple coils, single register, multiple registers)
            % corresponds to a unique Modbus function code which may or may
            % not be supported by the connected Modbus server.
            %
            % Input Arguments:
            % obj         modbus object
            % 'target'	  Specifies the area to write. The valid choices are
            %             'coils' and 'holdingregs'.
            % address 	  The starting address to write to.
            % values 	  Array of values to write. For target 'coils' valid
            %             values are 0 and 1. For target 'holdingregs' valid
            %             values must be in the range of the specified
            %             'precision'.
            % serverId	  The address of the server to send this command to.
            %             Valid values are 0-247, with 0 being the broadcast
            %             address. Optional, default is 1.
            % 'precision' Specifies the data format of the register being
            %             written to on the Modbus server. Valid values are
            %             'uint16', 'int16', 'uint32', 'int32', 'uint64',
            %             'int64', 'single', and 'double'. Optional, default
            %             is ‘uint16’
            %
            %             The values passed in to be written will be converted
            %             to register values based on the specified precision.
            %             'single' and 'double' conversions conform to the IEEE
            %             754 floating point standard. For signed integers a
            %             2's complement conversion is performed.
            %
            % Examples:
            % m = modbus('tcpip','192.168.2.15',502);
            %
            % % set the holding register at address 49153 to the value 2000
            % write(m,'holdingregs',49153,2000)
            %
            % % write 3 values starting at address 29473 as single precision
            % write(m,'holdingregs',29473,[928.1 50.3 24.4],'single')
            %
            % % write values to 4 coils starting at address 8289
            % write(m,'coils',8289,[1 1 0 1])
            %
            % clear m
            %
            % See also READ            
            narginchk(4,7);
            
            obj = varargin{1};
            if length(obj) > 1
                coder.internal.error('instrument:modbus:invalidOBJDim');
            end
            
            % Extract Target, address and values from passed args
            target  = obj.validateTarget(varargin{2}, 'write', 2, instrument.interface.coder.modbus.Modbus.WriteTargets);
            coder.internal.assert(eml_is_const(target), 'instrument:modbus:compileConstInputArgs');
            address = obj.validateAddress(varargin{3}, 3, 'address');
            values  = obj.validateValues(varargin{4}, 4, 'values');
            
            if strcmpi(target,'coils')
                countLow = instrument.interface.coder.modbus.Modbus.DiscreteWriteCountRange(1);
                countHi  = instrument.interface.coder.modbus.Modbus.DiscreteWriteCountRange(2);
            else
                countLow = instrument.interface.coder.modbus.Modbus.RegisterWriteCountRange(1);
                countHi  = instrument.interface.coder.modbus.Modbus.RegisterWriteCountRange(2);
            end
            
            % If target is coils there cannot be greater than 5 input args
            coder.internal.assert(~(strcmpi(target,'coils') && nargin > 5), 'instrument:modbus:invalidNarginForTarget', char(target));
            
            % assign default serverId
            serverId = obj.DefaultServerId;
            
            % Given the number of input arguments passed and target being
            % written to, assign the serverId and precion to be used to
            % write.
            switch (nargin)
                case 5
                    if strcmpi(target,'coils')
                        serverId = obj.validateServerId(varargin{5}, 5);
                        precision = 'uint16';
                    else
                        if ischar(varargin{5})
                            precision = obj.validatePrecision(varargin{5}, 5, 'precision');
                        else
                            serverId = obj.validateServerId(varargin{5}, 5);
                            precision = 'uint16';
                        end
                    end
                case 6
                    serverId = obj.validateServerId(varargin{5}, 5);
                    precision = obj.validatePrecision(varargin{6}, 6, 'precision');
                otherwise
                    precision = 'uint16';
            end
            
            % validate number of values
            obj.validateCount(length(values), precision, countLow, countHi,4, 'values');
            
            % call the write function for the requested target
            writeFn = ['write' target];
            obj.(writeFn)(address, values, serverId, precision);
        end
        
        function data = writeRead(varargin)
            % WRITEREAD Perform a write then read operation on the connected
            % Modbus server in a single Modbus transaction.
            %
            % Syntax:
            % data = writeRead(obj,writeAddress,values,readAddress,readCount)
            % data = writeRead(obj,writeAddress,values,readAddress,...
            %                    readCount,serverId)
            % data = writeRead(obj,writeAddress,values,'writePrecision',...
            %                    readAddress,readCount,'readPrecision')
            % data = writeRead(obj,writeAddress,values,'writePrecision',...
            %                    readAddress,readCount,'readPrecision',serverId)
            %
            % Description:
            % This function is used to perform a combination of one write.
            % operation and one read operation on groups of holding registers
            % in a single Modbus transaction. The write operation is always
            % performed before the read. The range of addresses to read must be
            % contiguous, and the range of addresses to write must be
            % contiguous, but each are specified independently and may or may
            % not overlap.
            %
            % Input Arguments:
            % obj               modbus object
            % writeAddress      The starting address of the registers to write
            % writeData         Array of values to write where the first value
            %                   in the array is written to writeAddress.
            % 'writePrecision' 	Specifies the data format of the register being
            %                   written to on the Modbus server. Valid values
            %                   are 'uint16','int16','uint32','int32','uint64',
            %                   'int64','single', and 'double'.  Optional,
            %                   default is 'uint16'.
            % readAddress       The starting address of the registers to read.
            % readCount         The number of registers to read.
            % serverId          The address of the server to send this command
            %                   to. Valid values are 0-247, with 0 being the
            %                   broadcast address. Optional, default is 1.
            % 'readPrecision' 	Specifies the data format of the register being
            %                   read from on the Modbus server. Valid values
            %                   are 'uint16','int16','uint32','int32','uint64',
            %                   'int64','single', and 'double'. Optional,
            %                   default is 'uint16'.
            %
            %                   'single' and 'double' conversions conform to
            %                   the IEEE 754 floating point standard. For
            %                   signed integers a 2's complement conversion is
            %                   performed. Note that 'precision' does not refer
            %                   to the return type (always 'double'), it only
            %                   specifies how to interpret the register data.
            %
            % Examples:
            %
            % m = modbus('serialrtu','COM6','BaudRate',256000,'Timeout',3)
            %
            % % read 4 holding registers starting at address 19250, and write 2
            % % holding registers starting at address 601
            %
            % writeData = [1024 512];
            % writeAddress = 601;
            % readAddress = 19250
            % writeRead(m,writeAddress,writeData,readAddress,4)
            %
            % % read 2 holding registers starting at address 919, and write 3
            % % holding registers starting at address 719 formatting read and
            % % write for single precision data registers.
            %
            % writeData = [1.14 5.9 11.27];
            % writeAddress = 719;
            % readAddress = 919;
            % writeRead(m,writeAddress,writeData,’single’,readAddress,2,’single’)
            %
            % clear m
            
            narginchk(5,8);
            
            obj = varargin{1};
            if length(obj) > 1
                coder.internal.error('instrument:modbus:invalidOBJDim');
            end
            
            % Extract write address and values from passed params
            writeAddress = obj.validateAddress(varargin{2}, 2, 'writeAddress');
            values = obj.validateValues(varargin{3}, 3, 'values');
            
            % Assign default values
            serverId = obj.DefaultServerId;
            
            usingWritePrecision = ischar(varargin{4});
            
            % Extract the write precision, read address and read count.
            % Determine positions by data type of arg 4.
            if (usingWritePrecision)
                narginchk(7,8);
                writePrecision = obj.validatePrecision(varargin{4}, 4, 'writePrecision');
                readAddress = obj.validateAddress(varargin{5}, 5, 'readAddress');
            else
                % No write precision is specified, default to uint16
                writePrecision = 'uint16';
                readAddress = obj.validateAddress(varargin{4}, 4, 'readAddress');
                readCountPosition = 5;
            end
            
            % Given the number of input arguments passed assign required
            % variables to be used in the writeread operation.
            switch (nargin)
                case 6
                    if (usingWritePrecision)
                        readCountPosition = 6;
                    else
                        serverId = obj.validateServerId(varargin{6}, 6);
                    end
                    % No read precision is specified, default to uint16
                    readPrecision = 'uint16';
                case {7,8}
                    readCountPosition = 6;
                    readPrecision = obj.validatePrecision(varargin{7}, 7, 'readPrecision');
                    if isequal(nargin,8)
                        serverId = obj.validateServerId(varargin{8}, 8);
                    end
                otherwise
                    % No read precision is specified, default to uint16
                    readPrecision = 'uint16';
            end
            
            readCount = varargin{readCountPosition};
            % validate number of values to read
            obj.validateCount(readCount, readPrecision,...
                instrument.interface.coder.modbus.Modbus.RegisterReadCountRange(1), ...
                instrument.interface.coder.modbus.Modbus.RegisterReadCountRange(2), readCountPosition, 'readCount');
            
            % validate number of values to write
            obj.validateCount(length(values), writePrecision,...
                instrument.interface.coder.modbus.Modbus.RegisterWriteCountRange(1),...
                instrument.interface.coder.modbus.Modbus.RegisterWriteCountRange(2), 3, 'values');
            
            % Call the writeread method with the write address and its
            % corresponding fields and read address and its corresponding
            % fields.
            data = obj.writeReadRegs(writeAddress, values, writePrecision,...
                readAddress, readCount, readPrecision, serverId);
        end
        
        function maskWrite(varargin)
            % MASKWRITE Modify the contents of a holding register using a
            % combination of an AND mask, an OR mask, and the register's
            % current contents.
            %
            % Syntax:
            % maskWrite(obj, address, andMask, orMask)
            % maskWrite(obj, address, andMask, orMask, serverId)
            %
            % Description:
            % This function is used to set or clear individual bits in a
            % specific holding register; a read/modify/write operation. This is
            % done by using a combination of an AND mask, an OR mask, and the
            % register's current contents.
            %
            % The function’s algorithm is:
            % Result = (register value AND andMask) OR (orMask AND (NOT andMask))
            %
            % For example:
            %                   Hex 	Binary
            % Current Contents 	12 	0001 0010
            % And_Mask          F2 	1111 0010
            % Or_Mask           25 	0010 0101
            % (NOT And_Mask) 	0D 	0000 1101
            % Result            17 	0001 0111
            %
            % Notes
            %
            % 1. If the orMask value is zero, the result is simply the logical
            % AND of the current contents and andMask. If the andMask value
            % is zero, the result is equal to the orMask value.
            %
            % 2. The contents of the register can be read by calling read with
            % 'target' set to 'holdingregs'. They could, however,
            % be changed subsequently as the controller scans its user logic
            % program.
            %
            % Input Arguments:
            % obj       modbus object
            % address   Register address to perform mask write on.
            % andMask   AND value to use in mask write operation described
            %           above. Valid range is 0-65535.
            % orMask    OR value to use in mask write operation described above.
            %           Valid range is 0-65535.
            % serverId  The address of the server to send this command to. Valid
            %           values are 0-247, with 0 being the broadcast address.
            %           Optional, default is 1.
            
            % Example:
            % m = modbus('serialrtu','COM6','BaudRate',256000,'Timeout',3)
            % % Set bit 0 of the register at address 20 while preserving the
            % % state of bits 4 and 5
            % andMask = 48 % 0x30
            % orMask = 1
            % % perform the mask write
            % maskWrite(m, 20, andMask, orMask)
            %
            % clear m
            
            narginchk(4,5);
            
            obj = varargin{1};
            if length(obj) > 1
                coder.internal.error('instrument:modbus:invalidOBJDim');
            end
            
            % Extract write address and mask values from passed params
            address = obj.validateAddress(varargin{2}, 2, 'address');
            andMask = obj.validateMask(varargin{3}, 3, 'And mask');
            orMask  = obj.validateMask(varargin{4}, 4, 'Or mask');
            
            if isequal(nargin, 5)
                serverId = obj.validateServerId(varargin{5}, 5);
            else
                serverId = obj.DefaultServerId;
            end
            
            % Call the maskwrite method with corresponding address and mask
            % parameters.
            obj.maskWriteRegs(address, andMask, orMask, serverId);
        end
    end
    
    %% Private methods
    methods(Access = private)
        
        function maskWriteRegs(obj, address, andMask, orMask, serverId)
            % perform Modbus register maskWrite
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createMaskWriteADUframe(address, andMask, orMask, serverId);
            
            % Execute the mask write request
            obj.executeMaskWrite(reqPacket);
        end
        
        function data = writeReadRegs(obj,writeAddress, values, writePrecision,...
                readAddress, readCount, readPrecision, serverId)
            % Perform Modbus register writeRead
            
            % validate the values to write based on requested precision
            obj.validateWriteValues(values,writePrecision);
            
            % Convert values to requested precision
            values = obj.Converter.convertWriteValues(values,writePrecision);
            
            % Get the bytes for precision and divide by 2 to convert to words.
            countMultiplier = obj.Converter.sizeof(readPrecision)/2;
            readCount = readCount * countMultiplier;
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createWriteReadADUframe(writeAddress,...
                values, readAddress, readCount, serverId);
            
            % Execute the read request
            bytes = obj.executeRead(reqPacket);
            
            % Convert byte array to requested type
            data = obj.Converter.convertReadValues(bytes, readPrecision);
        end
        
        function writecoils(obj, address, values, serverId, ~)
            % MODBUS function code 0x05 (single value write) or 0x0F (multiple
            % value write. Write values to 1 to 2000 contiguous coils
            % in the remote server starting at the specified address.
            
            % Convert the values. A Modbus 1 is represented by 0xFF00 for writing
            % a single coil. Multiple coils will be represented by word vals.
            if isequal(length(values),1)
                values(values == 1) = hex2dec('FF00');
                valid = [0,hex2dec('FF00')];
            else
                valid = [0, 1];
            end
            
            % Validate values
            if any(~ismember(values,valid))
                coder.internal.error('instrument:modbus:invalidValue','0,1');
            end
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createWriteADUframe('coils', address, values, serverId);
            
            % Execute the write request
            obj.executeWrite(reqPacket);
        end
        
        function writeholdingregs(obj, address, values, serverId, precision)
            % MODBUS function code 0x06 (single value write) or 0x10 (multiple
            % value write. Write values to 1 to 125 contiguous coils
            % in the remote server starting at the specified address.
            
            % validate the values to write based on requested precision
            obj.validateWriteValues(values,precision);
            
            % Convert values to requested precision
            values = obj.Converter.convertWriteValues(values,precision);
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createWriteADUframe('holdingregs', address, values, serverId);
            
            % Execute the write request
            obj.executeWrite(reqPacket);
        end
        
        function data = readcoils(obj, address, count, serverId, ~)
            % MODBUS function code 0x01. Read the values from 1 to 2000
            % contiguous coils in the remote server starting at the specified address.
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createReadADUframe('coils', address, count, serverId);

            % Execute the read request
            bytes = obj.executeRead(reqPacket);
            
            % Convert to array of bits
            data = obj.Converter.unpackBits(bytes, count);
        end
        
        function data = readinputs(obj, address, count, serverId,~)
            % MODBUS function code 0x02. Read the values from 1 to 2000
            % contiguous inputs in the remote server starting at the specified address.
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createReadADUframe('inputs', address, count, serverId);
            
            % Execute the read request
            bytes = obj.executeRead(reqPacket);
            
            % Convert to array of bits
            data = obj.Converter.unpackBits(bytes, count);
        end
        
        function data = readholdingregs(obj, address, count, serverId, precision)
            % MODBUS function code 0x03. Read the values from 1 to 125
            % contiguous holding registers in the remote server starting at the specified address.
            
            data = obj.readregs('holdingregs', address, count, serverId, precision);
        end
        
        function data = readinputregs(obj, address, count, serverId, precision)
            % MODBUS function code 0x04. Read the values from 1 to 125
            % contiguous input registers in the remote server starting at the specified address.
            
            data = obj.readregs('inputregs', address, count, serverId, precision);
        end
        
        function data = readregs(obj, target, address, count, serverId, precision)
            % Perform Modbus register read
            
            % Get the bytes for precision and divide by 2 to convert to
            % words.            
            countMultiplier = obj.Converter.sizeof(precision)/2;
            count = count * countMultiplier;
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createReadADUframe(target, address, count, serverId);
            
            % Execute the read request
            bytes = obj.executeRead(reqPacket);
            
            % Convert byte array to requested type
            data = obj.Converter.convertReadValues(bytes, precision);
        end
        
        function data = readholdingregscontiguous(obj, address, count, serverId, precision)
            % Read the values from 1 to 125 contiguous holding registers
            % in the remote server starting at the specified address using
            % precision-count, using holdingregs.
            
            data = obj.readRegsContiguous('holdingregs', address, count, serverId, precision);
        end
        
        function data = readinputregscontiguous(obj, address, count, serverId, precision)
            % Read the values from 1 to 125 contiguous input registers
            % in the remote server starting at the specified address using
            % precision-count, using inputregs.
            
            data = obj.readRegsContiguous('inputregs', address, count, serverId, precision);
        end
        
        function data = readRegsContiguous(obj, target, address, count, serverId, precision)
            % Perform Modbus register read across contiguous registers and
            % varying precision types
            
            % Parse the precision passed and create a wrodsize vector.
            wordSize = zeros(1, numel(precision));
            for numPrecision = 1:numel(precision)
                wordSize(numPrecision) = obj.Converter.sizeof(precision{numPrecision})/2;
            end
            totalWordSizeForEachPrecisionType = wordSize.*count;
            countTotal = sum(totalWordSizeForEachPrecisionType);
            
            % Create the request packet
            reqPacket = obj.PacketBuilder.createReadADUframe(target, address, countTotal, serverId);
            bytes = obj.executeRead(reqPacket);
            
            % Format the Raw bytes into given precision types.
            % Output data is always of type double.
            data = [];
            for i = 1 : size(precision, 2)
                sizeOfPrecision = obj.Converter.sizeof(precision{i})*count(i);
                bytesToSend = bytes(1: sizeOfPrecision);
                bytes = bytes((sizeOfPrecision+1):end);
                data =[data obj.Converter.convertReadValues(bytesToSend, precision{i})]; %#ok<AGROW>
            end
        end
        
        function serverId = validateServerId(obj, value, position)            
            % Validate server ID attributes and range
            validateattributes(value,{'numeric'},{'nonnegative','nonempty','scalar'},mfilename,'serverId',position);
            if (value < obj.ServerIdRange(1) || value > obj.ServerIdRange(2))
                coder.internal.error('instrument:modbus:invalidServerId', obj.ServerIdRange(1), obj.ServerIdRange(2));
            end
            serverId = value;
        end
        
        function values = validateCount(obj, values, precision, minCount, maxCount, position, argname)            
            % Set the flag for read count validation
            % isRead = true for read count validation
            % isRead = false for write count validation
            isRead = contains(lower(argname),'count');
            if isRead && iscell(precision)
                % for reads of mixed data types
                values = obj.validateMultipleCount(values, precision, minCount, maxCount, position, argname);
            else
                % for read or write of the same data type
                values = obj.validateSingleCount(values, precision, minCount, maxCount, position, isRead, argname);
            end
        end
        
        function value = validateSingleCount(obj, value, precision, minCount, maxCount, position, isRead, argname)            
            % Validate count if there is a single value for count
            validateattributes(value,{'numeric'},{'nonnegative', 'nonempty', 'scalar',...
                'integer'},mfilename, argname, position);
            
            valueSizeInWords = obj.Converter.sizeof(precision)/2;
            maxCount = floor(maxCount/valueSizeInWords);
            
            if value < minCount || value > maxCount
                if isRead
                    coder.internal.error('instrument:modbus:invalidCount', minCount, maxCount);
                else
                    coder.internal.error('instrument:modbus:invalidValuesCount', minCount, maxCount);
                end
            end
        end
        
        function values = validateMultipleCount(obj, values, precision, minCount, maxCount, position, argname)            
            % Validate count for vector of counts and precisions.
            
            % Size of precision vector and count vector must be the same
            if size(precision, 2) ~= size(values, 2)
                coder.internal.error('instrument:modbus:precisionCountDimensionMismatch');
            end
            
            % Validate every count value
            validateattributes(values,{'numeric'},{'nonnegative', 'nonempty', ...
                'integer'},mfilename, argname, position);
            
            % Find total number of 16-bit registers to read in one read.
            valueSizeInWords = zeros(1, numel(precision));
            for numPrecision = 1:numel(precision)
                valueSizeInWords(numPrecision) = obj.Converter.sizeof(precision{numPrecision})/2;
            end
            totalWordSizeForEachPrecisionType = valueSizeInWords.*values;
            
            % Total Number of registers to read in 1 read.
            numRegsToRead = sum(totalWordSizeForEachPrecisionType);
            
            if numRegsToRead < minCount || numRegsToRead > maxCount
                coder.internal.error('instrument:modbus:outOfBoundsReadRange',...
                    num2str(obj.RegisterReadCountRange(1)), num2str(obj.RegisterReadCountRange(2)));
            end
        end
        
        function precision = validatePrecision(~, value, position, argname)
            % Validate precision argument
            validateattributes(value,{'char','string'},{'nonempty'},mfilename,argname,position);
            precision = validatestring(value,instrument.interface.modbus.Modbus.Precisions,mfilename,argname,position);
        end
        
        function validatedPrecision = validateAllPrecision(obj, precision, position)
            % Validate scalar and cell array of precisions
            if iscell(precision)
                validatedPrecision = cell(1, numel(precision));
                for numPrecision = 1:numel(precision)
                    validatedPrecision{numPrecision} = obj.validatePrecision(precision{numPrecision}, position, 'precision');
                end
            else
                validatedPrecision = obj.validatePrecision(precision, position, 'precision');
            end
        end
        
        function address = validateAddress(~, value, position, argname)
            % Validate precision argument
            validateattributes(value,{'numeric'},{'nonnegative','nonzero','nonempty','size',[1,1]},mfilename,argname,position)
            address = value;
        end
        
        function mask = validateMask(~, value, position, argname)
            % Validate mask value
            validateattributes(value,{'numeric'},{'nonnegative','nonempty'},mfilename,argname,position);
            if (value > intmax('uint16'))
                coder.internal.error('instrument:modbus:invalidMask', argname, 0, intmax('uint16'));
            end
            mask = value;
        end
        
        function values = validateValues(~, values, position, argname)
            % Validate values to be written
            validateattributes(values,{'double'},{'nonempty'},mfilename,argname,position);
            validateattributes(values,{'cell','numeric'},{'nonempty','finite'},mfilename,argname,position);
            
            if size(values) > 1
                coder.internal.error('instrument:modbus:invalidValuesDim');
            end
        end
        
        function target = validateTarget(~, value, funcName, position, validValues)
            % validate target
            target = validatestring(value,validValues, funcName,'target',position);
        end
        
        function validateWriteValues(obj,values, precision)
            % Validate the range and type of the values passed in based on
            % requested precision
            
            if contains(precision,'int')
                % check for non-integer
                for val = 1:numel(values)
                    if ~isequal(rem(values(val), 1), 0)
                        coder.internal.error('instrument:modbus:invalidValueFractional', obj.quoteString(precision));
                    end
                end
                
                % check range wrt intmin and intmax on the precision
                if any(values < intmin(precision)) || any(values > intmax(precision))
                    coder.internal.error('instrument:modbus:valueOutOfRange',...
                        num2str(intmin(precision)), num2str(intmax(precision)));
                end
            else
                % check range wrt realmin and realmax on the precision
                if any(values < -realmax(precision)) || any(values > realmax(precision))
                    coder.internal.error('instrument:modbus:valueOutOfRange',...
                        num2str(-realmax(precision)), num2str(realmax(precision)));
                end
            end
        end
        
        function [bytes, retry] = executeRead(obj,reqPacket)
            % Send read request and wait for response. Handle retry if
            % failure.
            
            retry = true;
            % Initialize data to empty - double - as readbytes always
            % returns a double
            bytes = [];
            while retry
                % Perform the transaction. If successful retry will be
                % false. If there is a timeout and NumRetries is less
                % than the number of retry attempts retry will be
                % true, else a timeout exception will be thrown.
                obj.sendRequest(reqPacket);
                [bytes, retry] = obj.getReadResponse();
            end
        end
        
        function executeWrite(obj,reqPacket)
            % Send write request and wait for response. Handle retry if
            % failure.
            
            retry = true;
            while retry
                % Perform the transaction. If successful retry will be
                % false. If there is a timeout and NumRetries is less
                % than the number of retry attempts retry will be
                % true, else a timeout exception will be thrown.
                obj.sendRequest(reqPacket);
                retry = obj.getWriteResponse();
            end
        end
        
        function executeMaskWrite(obj,reqPacket)
            % Send mask write request and wait for response. Handle retry if
            % failure.
            
            retry = true;
            while retry
                % Perform the transaction. If successful retry will be
                % false. If there is a timeout and NumRetries is less
                % than the number of retry attempts retry will be
                % true, else a timeout exception will be thrown.
                obj.sendRequest(reqPacket);
                retry = obj.getMaskWriteResponse();
            end
        end
    end
    
    methods (Hidden, Access = protected)
        
        function translateandGenerateServerError(obj, errCode, fcnCode)
            % Error out for the server error code passed in. These error 
            % codes are defined in the Modbus specification.
            
            switch errCode
                case 1
                    fcnCode = bitand(fcnCode,obj.ErrorMask);
                    coder.internal.error('instrument:modbus:functionNotSupported', fcnCode);
                case 2
                    if (obj.isReadFunction(fcnCode))
                        coder.internal.error('instrument:modbus:invalidReadAddressRange');
                    else
                        coder.internal.error('instrument:modbus:invalidWriteAddressRange');
                    end
                case 3
                    coder.internal.error('instrument:modbus:invalidDataValue');
                case 4
                    if (obj.isReadFunction(fcnCode))
                        coder.internal.error('instrument:modbus:serverReadFailed');
                    else
                        coder.internal.error('instrument:modbus:serverWriteFailed');
                    end
                case 6
                    coder.internal.error('instrument:modbus:serverDeviceBusy');
                otherwise
                    coder.internal.error('instrument:modbus:unknownServerError', fcnCode);
            end
        end
        
        function val = isReadFunction(obj,fcnCode)
            % Get the function code by masking out the error bit then determine
            % if it is one of the supported read functions.
            fcnCode = bitand(fcnCode,obj.ErrorMask);
            val = any(fcnCode == obj.ReadFcnCodes);
        end
        
        function setTimeout(obj, transportObj, val)
            % Set the timeout on the transport object and the transaction
            % timer.
            validateattributes(val,{'numeric'},{'nonnegative','finite','scalar'},'Timeout','Timeout');
            if (val < .002)
                coder.internal.error('instrument:modbus:invalidTimeoutValue');
            end
            if ~obj.TransportInjected
                transportObj.Timeout = val;
            end
            obj.TransactionTimeout = val;
            obj.RetryCount = 0;
        end
        
        function retry = handleTimeout(obj)
            % Handle the timeout based on where we're at with retries
            
            % Flush IO before retrying
            obj.flushIO;
            
            % Do any transport specific work before the retry
            obj.prepareForRetry();
            
            obj.RetryCount = obj.RetryCount + 1;
            retry = true;
        end
        
        function prepareForRetry(~)
            % Default implementation does nothing. May be overridden by
            % derived classes.            
        end
        
        function str = quoteString(~, str)
            % Return str with in single quotes
            str = char(char(39) + string(str) + char(39));
        end
    end
    
    % Abstract methods transport specific derived classes must implement
    methods (Abstract, Access = protected, Hidden)
        sendRequest(obj, reqPacket);
        [bytes,retry] = getReadResponse(obj);
        retry = getWriteResponse(obj);
        retry = getMaskWriteResponse(obj);
        flushIO(obj);
    end
end

