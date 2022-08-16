classdef (Hidden) PacketBuilder < handle
    %PACKETBUILDER Base class for transport specific Modbus packet builders
   
    % Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    properties (Hidden, SetAccess = immutable)
       Converter
    end
    
    properties (Constant, Hidden)
        % Modbus function codes
        ReadCoils           = 1
        ReadInputs          = 2
        ReadHoldingRegs     = 3
        ReadInputRegs       = 4
        WriteSingleCoil     = 5
        WriteSingleReg      = 6
        WriteMultipleCoils  = 15
        WriteMultipleRegs   = 16
        MaskWrite           = 22
        WriteRead           = 23
        
        % Valid targets to read
        ReadTargets  = {'coils', 'inputs', 'holdingregs', 'inputregs'}
        ReadFcnCodes = [1, 2, 3, 4]
        
        % Default Modbus PDU Size
        DefaultMBPDUSize = 6
        
        % Single Modbus PDU frame constant
        SingleMBPDU = 1
    end
    
    properties (Hidden, Access = private)
        ModbusPDUSize
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

            % Calculate bytes to add and expand modbusPDU
            andBytes = obj.Converter.word2bytes(andMask);
            orBytes = obj.Converter.word2bytes(orMask);

            % Add DefaultMBPDUSize to the final size to compensate for initialization.
            % This is used by coder to initialize modbusPDU with the
            % required fixed size.
            obj.ModbusPDUSize = length(orBytes) + obj.DefaultMBPDUSize;

            % Create and return the base MODBUS PDU request frame
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, address, serverId);

            % and mask
            [modbusPDU, index] = obj.addBytes(modbusPDU, index, andBytes);

            % or mask
            modbusPDU = obj.addBytes(modbusPDU, index, orBytes);
        end
        
        function modbusPDU = createWriteReadPDUframe(obj, readAddress, quantity,...
                                    writeAddress, values, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % writeRead operation.
            fcnCode = obj.WriteRead;

            % Calculate bytes to add and expand modbusPDU
            qtyBytes = obj.Converter.word2bytes(quantity);
            % In the PDU coils inputs and registers are addressed starting
            % at zero. eg. coils numbered 1-16 are addressed as 0-15.
            writeAddress = writeAddress - 1;
            addrBytes = obj.Converter.word2bytes(writeAddress);
            regCount = length(values);
            regCountBytes = obj.Converter.word2bytes(regCount);

            % Add the single PDU and DefaultMBPDUSize to the final
            % size to compensate for initialization.
            % This is used by coder to initialize modbusPDU with the
            % required fixed size.
            obj.ModbusPDUSize = length(addrBytes) + length(regCountBytes) +...
                2*regCount + obj.SingleMBPDU + obj.DefaultMBPDUSize;

            % Create and return the base MODBUS PDU request frame
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, readAddress, serverId);

            % Read qty
            [modbusPDU, index] = obj.addBytes(modbusPDU, index, qtyBytes);

            % Write address
            [modbusPDU, index] = obj.addBytes(modbusPDU, index, addrBytes);

            % Add number of registers to write
            [modbusPDU, index] = obj.addBytes(modbusPDU, index, regCountBytes);
            byteCount = regCount * 2;

            % Add byte count and values
            modbusPDU(index) = byteCount;
            index = index + 1;

            for idx = 1 : regCount
                valBytes = obj.Converter.word2bytes(values(idx));
                [modbusPDU, index] = obj.addBytes(modbusPDU, index, valBytes);
            end
        end
        
        function modbusPDU = createReadPDUframe(obj, readTarget, startAddress, quantity, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % read operation.
            % Reset Modbus PDU size and extract function code
            obj.ModbusPDUSize = obj.DefaultMBPDUSize;
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
            % Set Modbus PDU size and extract function code
            obj.ModbusPDUSize = obj.DefaultMBPDUSize;
            fcnCode = obj.getWriteFunctionCode(writeTarget, length(values));

            if (isequal(fcnCode,5) || isequal(fcnCode,6))
                % Write single coil or register
                
                % Create and return the base MODBUS PDU request frame for a
                % read operation.
                [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
                valBytes = obj.Converter.word2bytes(values(1));
                modbusPDU = obj.addBytes(modbusPDU, index, valBytes);
            else
                % Write multiple coils or registers

                % Add count, either number of coils, or number of registers                
                countInputValues = length(values);
                cntBytes = obj.Converter.word2bytes(countInputValues);
                byteCount = countInputValues * 2;

                if (isequal(fcnCode, 15))
                    % If write multiple coils
                    
                    % Calculate bytes to add and expand modbusPDU
                    % Convert coil bits to bytes
                    values = obj.Converter.packBits(values);
                    % Update count
                    count = length(values);
                    
                    % Add the single PDU and DefaultMBPDUSize to the final
                    % size to compensate for initialization.
                    % This is used by coder to initialize modbusPDU with the
                    % required fixed size.
                    obj.ModbusPDUSize = count + obj.SingleMBPDU + obj.DefaultMBPDUSize;
                    [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
                    [modbusPDU, index] = obj.addBytes(modbusPDU, index, cntBytes);

                    % Add byte count and values
                    byteCount = count;
                    modbusPDU(index) = byteCount;
                    index = index + 1;
                    modbusPDU = obj.addBytes(modbusPDU, index, values);
                else
                    % else write multiple registers
                    
                    % Add the single PDU and DefaultMBPDUSize to the final
                    % size to compensate for initialization.
                    % This is used by coder to initialize modbusPDU with the
                    % required fixed size.
                    obj.ModbusPDUSize = 2*countInputValues + obj.SingleMBPDU + obj.DefaultMBPDUSize;
                    [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
                    [modbusPDU, index] = obj.addBytes(modbusPDU, index, cntBytes);
                    
                    % Add byte count and values
                    modbusPDU(index) = byteCount;
                    index = index + 1;

                    for idx = 1:countInputValues
                        valBytes = obj.Converter.word2bytes(values(idx));
                        [modbusPDU, index] = obj.addBytes(modbusPDU, index, valBytes);
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
            % Use the calculated Modbus PDU Size property to create the
            % entire modbusPDU required and initialize first 4 indices.
            modbusPDU = zeros(1, obj.ModbusPDUSize, 'uint8');
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
            code = obj.ReadFcnCodes(strcmp(obj.ReadTargets, target));
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
end