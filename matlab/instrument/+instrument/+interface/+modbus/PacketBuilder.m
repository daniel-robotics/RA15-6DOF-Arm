classdef (Hidden) PacketBuilder < handle
    %PACKETBUILDER Base class for transport specific Modbus packet builders
    %
   
    % Copyright 2016-2019 The MathWorks, Inc.
    %#codegen
    
    properties (Hidden, SetAccess = immutable)
       Converter 
    end
    
    properties (Constant, Hidden)
        % Modbus function codes
        ReadCoils           = 1;
        ReadInputs          = 2;
        ReadHoldingRegs     = 3;
        ReadInputRegs       = 4;
        WriteSingleCoil     = 5;
        WriteSingleReg      = 6;
        WriteMultipleCoils  = 15;
        WriteMultipleRegs   = 16;
        MaskWrite           = 22;
        WriteRead           = 23;
        
        % Valid targets to read
        ReadTargets  = ["coils", "inputs",...
                        "holdingregs","inputregs"];
        ReadFcnCodes = [1, 2, 3, 4];        
    end
    
    methods
        function obj = PacketBuilder(converter)
            % Constructor
            obj.Converter = converter;           
        end
    end
    
    %% Abstract methods that must be implemented by transport specific subclasses
    methods (Abstract, Access=public)
        modbusADU = createReadADUframe(obj, readTarget, startAddress, quantity, deviceId);
        modbusADU = createWriteADUframe(obj, writeTarget, startAddress, values, deviceId);
        modbusADU = createWriteReadADUframe(obj, writeAddress, values,...
                                            readAddress, readCount, deviceId);
        modbusADU = createMaskWriteADUframe(obj, address, andMask, orMask, serverId);
    end
    
    %% Protected methods
    methods (Hidden, Access = protected)
        
        function modbusPDU = createMaskWritePDUframe(obj, address, andMask, orMask, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % maskWrite operation.
            fcnCode = obj.MaskWrite;
            
            % Create and return the base MODBUS PDU request frame
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, address, serverId);
            
            % and mask
            andBytes = obj.Converter.word2bytes(andMask);            
            [modbusPDU,index] = obj.addBytes(modbusPDU, index, andBytes);
            
            % or mask
            orBytes = obj.Converter.word2bytes(orMask);            
            modbusPDU = obj.addBytes(modbusPDU, index, orBytes);            
        end
        
        function modbusPDU = createWriteReadPDUframe(obj, readAddress, quantity,...
                                    writeAddress, values, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % writeRead operation.            
            fcnCode = obj.WriteRead;
            
            % Create and return the base MODBUS PDU request frame
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, readAddress, serverId);
            
            % Read qty
            qtyBytes = obj.Converter.word2bytes(quantity);            
            [modbusPDU,index] = obj.addBytes(modbusPDU, index, qtyBytes);
            
            % In the PDU coils inputs and registers are addressed starting
            % at zero. eg. coils numbered 1-16 are addressed as 0-15.
            writeAddress = writeAddress - 1;
            
            % Write address            
            addrBytes = obj.Converter.word2bytes(writeAddress);            
            [modbusPDU,index] = obj.addBytes(modbusPDU, index, addrBytes);
            
            % Add number of registers to write
            regCount = length(values);
            regCountBytes = obj.Converter.word2bytes(regCount);            
            [modbusPDU,index] = obj.addBytes(modbusPDU, index, regCountBytes);
            
            byteCount = regCount * 2;   
            
            % Add byte count and values                
            modbusPDU(index) = byteCount;   
            index = index + 1;                    

            for idx = 1 : regCount
                valBytes = obj.Converter.word2bytes(values(idx));            
                [modbusPDU,index] = obj.addBytes(modbusPDU, index, valBytes);
            end          
        end
        
        function modbusPDU = createReadPDUframe(obj, readTarget, startAddress, quantity, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % read operation.            
            fcnCode = obj.getReadFunctionCode(readTarget);
            
            % Create and return the base MODBUS PDU request frame for a
            % read operation.
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
            
            qtyBytes = obj.Converter.word2bytes(quantity); 
            modbusPDU = obj.addBytes(modbusPDU, index, qtyBytes);            
        end
        
        function modbusPDU = createWritePDUframe(obj, writeTarget, startAddress, values, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % write operation.            
            fcnCode = obj.getWriteFunctionCode(writeTarget, length(values));         
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
            
            if (isequal(fcnCode,5) || isequal(fcnCode,6))
                % Write single coil or register
                valBytes = obj.Converter.word2bytes(values(1)); 
                modbusPDU = obj.addBytes(modbusPDU, index, valBytes);
            else                          
                % Write multiple coils or registers

                % Add count, either number of coils, or number of registers
                count = length(values);
                cntBytes = obj.Converter.word2bytes(count); 
                [modbusPDU,index] = obj.addBytes(modbusPDU, index, cntBytes);
                byteCount = count * 2;
                
                % If write multiple coils
                if (isequal(fcnCode, 15)) 
                    % Convert coil bits to bytes
                    values = obj.Converter.packBits(values);
                    % Update count
                    count = length(values);
                    byteCount = count;
                    % Add byte count and values                
                    modbusPDU(index) = byteCount;   
                    index = index + 1;
                    modbusPDU = obj.addBytes(modbusPDU, index, values);
                else
                    % else write multiple registers
                    % Add byte count and values                
                    modbusPDU(index) = byteCount;   
                    index = index + 1;                    

                    for idx = 1:count
                        valBytes = obj.Converter.word2bytes(values(idx)); 
                        [modbusPDU,index] = obj.addBytes(modbusPDU, index, valBytes);
                    end
                end
            end
        end      
    end
    
    methods (Access = protected)
       
        function [modbusPDU, index] = addBytes(~, modbusPDU, index, bytes)
            % Add bytes to the PDU, return PDU and updated index
            for b = bytes
                modbusPDU(index) = b;
                index  = index +1;          
            end
        end
    end
    
    methods (Access = private)
    
        function [modbusPDU, index] = createBasePDUframe(obj, fcnCode, startAddress, serverId)
            % Create and return the base MODBUS PDU request frame                        
            
            % In the PDU coils inputs and registers are addressed starting
            % at zero. eg. coils numbered 1-16 are addressed as 0-15.
            startAddress = startAddress - 1;
            
            index = 1;
            modbusPDU = zeros(1,6,'uint8');
            modbusPDU(index) = serverId;
            index = index + 1;
            modbusPDU(index) = fcnCode;
            index = index + 1;
            % Start address
            addrBytes = obj.Converter.word2bytes(startAddress);            
            modbusPDU(index) = addrBytes(1);
            index  = index +1;
            modbusPDU(index) = addrBytes(2);
            index  = index +1;                                        
        end
       
        function code = getReadFunctionCode(obj, target)
            % Returns the MODBUS function code for the
            % specified target.
            idx = strcmp(obj.ReadTargets, target);
            code = obj.ReadFcnCodes(idx);            
        end
        
        function code = getWriteFunctionCode(obj, target, count)
            % Return the MODBUS function code based on target and qty                        
            if (isequal(target, 'coils'))
                if (count > 1) 
                    code = obj.WriteMultipleCoils;
                else
                    code = obj.WriteSingleCoil;
                end
            end
            
            if (isequal(target, 'holdingregs'))
                if (count > 1) 
                    code = obj.WriteMultipleRegs;
                else
                    code = obj.WriteSingleReg;
                end
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
            name = 'instrument.interface.coder.modbus.PacketBuilder';
        end
    end
end

