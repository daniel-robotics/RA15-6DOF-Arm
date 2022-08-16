classdef (Hidden) DataConverter < handle
    %DATACONVERTER - Helper class for converting to/from different data
    %types stored in Modbus server registers.
    
    % Copyright 2016-2019 The MathWorks, Inc.
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
        MachineByteOrder = 'little-endian';
    end
    
    methods
        function set.ByteOrder(obj,val)
            % handler for ByteOrder property set
            val = validatestring(val,{'little-endian' 'big-endian'}); 
            obj.ByteOrder = val;
        end
        function out = get.ByteOrder(obj)
            % handler for ByteOrder property get
            out = obj.ByteOrder;
        end        
        function set.WordOrder(obj,val)
            % handler for WordOrder property set
            val = validatestring(val,{'little-endian' 'big-endian'});         
            obj.WordOrder = val;           
        end    
        function out = get.WordOrder(obj)   
            % handler for WordOrder property get
            out = obj.WordOrder;
        end    
    end    
    
    methods (Access = public)
                
        function obj = DataConverter
            % Constructor
            obj.ByteOrder = 'big-endian';
            obj.WordOrder = 'big-endian';
            [~,~,b] = computer;
            if strcmpi(b,'l')
                obj.MachineByteOrder = 'little-endian';
            else
                obj.MachineByteOrder = 'big-endian';
            end
        end
        
        function out = convertReadValues(obj, bytes, precision)
           % Convert values from 16 bit register values to the specified type
            sz = obj.sizeof(precision);
            numout = numel(bytes)/sz;
            bytes = reshape(bytes',sz,numout)';
            out = arrayfun(@(i) obj.bytes2value(uint8(bytes(i,:)),precision),1:numout);
        end
        
        function out = convertWriteValues(obj, values, precision)
            % Convert values to 16 bit register values based on the
            % specified precision.
            words = arrayfun(@(x) obj.value2words(cast(x,precision)),values,'UniformOutput',false);
            out = cell2mat(words);
        end            
        
       %% Bit converters
       function bits = unpackBits(~, bytes,count)            
            % Extract 'count' bits from bytes returning an array of 1's and
            % 0's
            
            % Data is lowest address first. For example if count is 16
            % and discrete values are (MSB)0001110001100101(LSB)2 bytes are
            % passed in: 0x65 0x1C
            bitsLeft = count;
            bits = [];
            for b = bytes
                if (bitsLeft > 8)
                    bitsToCopy = 8;
                else
                    bitsToCopy = bitsLeft;
                end
                bits = [bits bitget(b,1:1:bitsToCopy)]; %#ok<AGROW>
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
                   shiftVal = shiftVal + 1;                   
               else
                   byteIdx = byteIdx + 1;
                   shiftVal = 0;
               end
            end           
        end
                
        %% Byte swapping
        function bytes = word2bytes(obj,wordval)
            % Convert a word value into 2 correctly ordered bytes
            if obj.needByteSwap
               wordval = swapbytes(uint16(wordval));
            end
            bytes = typecast(uint16(wordval),'uint8');
        end
        
        %% Helpers
        function numbytes = sizeof(~,precision)
            precision = validatestring(precision,instrument.interface.modbus.Modbus.Precisions,mfilename,'precision',2);
            switch(precision)
                case {'int16','uint16'}                    
                    numbytes = 2;
                case {'int32','uint32','single'}
                    numbytes = 4;   
                case {'int64','uint64','double'} 
                    numbytes = 8;
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

    %------------------------------------------------------------------
    % For code generation support
    %------------------------------------------------------------------
    methods(Static)
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'instrument.interface.coder.modbus.DataConverter';
        end
    end
end

