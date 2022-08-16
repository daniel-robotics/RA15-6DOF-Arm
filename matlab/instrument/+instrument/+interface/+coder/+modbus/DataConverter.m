classdef (Hidden) DataConverter < handle
    %DATACONVERTER - Helper class for converting to/from different data
    %types stored in Modbus server registers.
    
    % Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    properties (Access = public)            
        % ByteOrder - Byte order of data sent to/from Modbus server.
        %             Default is 'big-endian'.        
        ByteOrder
        
        % WordOrder - Word order of data sent to/from the Modbus server
        %             when a value spans multiple 16 bit registers.
        %             Default is 'big-endian'.
        WordOrder
    end 
    
    properties (Access = private)
        % MachineByteOrder - Byte order of host computer
        MachineByteOrder
    end
    
    methods
        function set.ByteOrder(obj,val)
            % handler for ByteOrder property set
            validatestring(val,{'little-endian' 'big-endian'},mfilename);            
            % This is a workaround for g2092194 and partial string matching.
            % Technically we can get the return value from validatestring 
            % (which does partial matching). However, if we do that, the 
            % code being generated for some scenario has compiler warnings
            % about potential uninitialized variables
            if strncmpi(val, 'little-endian', length(val))
                value = 'little-endian';
            else
                value = 'big-endian';
            end
            
            obj.ByteOrder = blanks(coder.ignoreConst(0));
            obj.ByteOrder = value;
        end
        function out = get.ByteOrder(obj)
            % handler for ByteOrder property get
            out = obj.ByteOrder;
        end        
        function set.WordOrder(obj,val)
            % handler for WordOrder property set
            validatestring(val,{'little-endian' 'big-endian'},mfilename);
            % This is a workaround for g2092194 and partial string matching.
            % Technically we can get the return value from validatestring 
            % (which does partial matching). However, if we do that, the 
            % code being generated for some scenario has compiler warnings
            % about potential uninitialized variables
            if strncmpi(val, 'little-endian', length(val))
                value = 'little-endian';
            else
                value = 'big-endian';
            end
            obj.WordOrder = blanks(coder.ignoreConst(0));
            obj.WordOrder = value;           
        end    
        function out = get.WordOrder(obj)   
            % handler for WordOrder property get
            out = obj.WordOrder;
        end
                
        function obj = DataConverter
            % Constructor
            coder.extrinsic('computer');
            obj.ByteOrder = 'big-endian';
            obj.WordOrder = 'big-endian';
            [~,~,b] = coder.const(@computer);
            if strcmpi(b,'l')
                obj.MachineByteOrder = 'little-endian';
            else
                obj.MachineByteOrder = 'big-endian';
            end
        end
        
        function out = convertReadValues(obj, bytes, precision)
           % Convert values from 16 bit register values to the specified
           % precision.
            sz = obj.sizeof(precision);
            numout = numel(bytes)/sz;
            reshapedBytes = reshape(bytes',sz,numout)';
            out = zeros(1,numout);
            for i = 1:numout
                out(i) = obj.bytes2value(uint8(reshapedBytes(i,:)),precision);
            end
        end
        
        function out = convertWriteValues(obj, values, precision)
            % Convert values to 16 bit register values based on the
            % specified precision.
            % Get number of values passed in
            numValues = numel(values);
            sz = obj.sizeof(precision);
            numout = numValues*sz/2;
            
            % Initialize the output
            out = zeros(1,numout,'uint16');
            
            % Calculate size of block to be copied into the output for
            % given number of values and precision
            copySize = numout/numValues;
            
            % Use copySize to calculate the start and end index for the
            % block copy into output
            startIdx = 1;
            for currentVal = 1:numValues
                endIdx = currentVal*copySize;
                out(startIdx:endIdx) = obj.value2words(cast(values(currentVal),precision));
                startIdx = endIdx + 1;
            end
        end            
        
       %% Bit converters
       function bits = unpackBits(~, bytes, count)            
            % Extract 'count' bits from bytes returning an array of 1's and
            % 0's
            
            % Data is lowest address first. For example if count is 16
            % and discrete values are (MSB)0001110001100101(LSB)2 bytes are
            % passed in: 0x65 0x1C
            bitsLeft = count;
            bits = [];
            numbytes = numel(bytes);
            for b = 1:numbytes
                if (bitsLeft > 8)
                    bitsToCopy = 8;
                else
                    bitsToCopy = bitsLeft;
                end
                bits = [bits bitget(bytes(b),1:1:bitsToCopy)]; %#ok<AGROW>
                bitsLeft = bitsLeft - bitsToCopy;
            end
        end
                
        function bytes = packBits(~, bitVals)            
            % Shift bit values into words. Unused bits are set to zero.
            % Caller will be responsible for any byte order adjustments.
            bitCount = length(bitVals);
            extra = 0;
            
            % Calculate how many bytes are required for the number of bits.
            rem = mod(bitCount,8);            
            if ~isequal(rem,0)
                extra = 1;
            end
            numBytes = floor(bitCount/8) + extra;
            bytes = zeros(1,numBytes,'uint8');
            bitIdx = 1;
            byteIdx = 1;
            shiftVal = uint8(0);
            for idx = 1 : bitCount
               % Shift the current bit left into it's position and or with
               % the current byte value.
               bytes(byteIdx) = bitor(bytes(byteIdx), uint8(bitshift(bitVals(bitIdx),shiftVal)));
               bitIdx = bitIdx + 1;
               % If we haven't or'ed in the last bit for the current byte
               % increment the amount to shift, else move to the next byte
               % and reset the shift value.
               if ~isequal(mod(idx,8), 0)
                   shiftVal = shiftVal + uint8(1);                   
               else
                   byteIdx = byteIdx + 1;
                   shiftVal = uint8(0);
               end
            end           
        end
                
        %% Byte swapping
        function bytes = word2bytes(obj,wordval)
            % Convert a word value into 2 correctly ordered bytes
            convertedWordVal = uint16(wordval);
            if obj.needByteSwap
                convertedWordVal = swapbytes(uint16(wordval));
            end
            bytes = typecast(convertedWordVal, 'uint8');
        end
        
        %% Helpers
        function numbytes = sizeof(~,precision)
            precision = validatestring(precision,instrument.interface.coder.modbus.Modbus.Precisions,mfilename,'precision',2);
            switch(precision)
                case {'int16','uint16'}                    
                    numbytes = 2;
                case {'int32','uint32','single'}
                    numbytes = 4;   
                case {'int64','uint64','double'} 
                    numbytes = 8;
                otherwise
                    coder.internal.error('instrument:modbus:invalidPrecision', precision);
            end
        end
    end
    
    %% Private methods
    methods(Access = private)    
        
        function out = value2words(obj,val)
            % Convert an integer value to 16 bit register values to be
            % written to the modbus device
            
            % typecast will return an array of uint16 values, endianness 
            % will match host
            out = typecast(val,'uint16');
            
            % fix the word order if necessary. Byte order is taken care of
            % when the data packet is constructed.
            if strcmpi(obj.WordOrder, 'big-endian')
                out = fliplr(out);
            end
        end
                
        function value = bytes2value(obj,bytes,precision)
            % Convert the byte array read from the modbus device 
            % based on the precision, byte order, and word order.
            
            % get data into word format
            words = obj.bytes2words(bytes);
            
            % first fix word order if necessary. If we read from a device
            % that stores register data big endian we need to reverse the
            % order.
            if strcmpi(obj.WordOrder, 'big-endian')            
                words = fliplr(words);
            end

            % back to bytes
            bytes = typecast(words,'uint8');

            value = double(typecast(bytes,precision));
        end        

        function out = bytes2words(obj,bytes)
            % convert byte array to word array
            out = typecast(bytes,'uint16');
            
            % the typecast just ordered the bytes in the host order. If 
            % that doesn't match the device swap them back.
            if obj.needByteSwap
                out = swapbytes(out);
            end
        end
        
        function out = needByteSwap(obj)
            % if the host machine byte order is different than the Modbus
            % server return true.
            out = ~strcmpi(obj.ByteOrder, obj.MachineByteOrder); 
        end        
    end
end

