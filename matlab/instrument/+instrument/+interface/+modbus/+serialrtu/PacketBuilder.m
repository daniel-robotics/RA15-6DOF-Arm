classdef (Hidden) PacketBuilder < instrument.interface.modbus.PacketBuilder
    %PACKETBUILDER Builds Modbus Serial RTU request packets
    
    % Copyright 2016-2019 The MathWorks, Inc.
    %#codegen
    
    %% Constructor
    methods
        function obj = PacketBuilder(converter)
            % call throught to base class
            obj@instrument.interface.modbus.PacketBuilder(converter);
        end
    end
    
    %% Public methods
    methods
        function modbusADU = createReadADUframe(obj, readTarget, startAddress, quantity, deviceId)
            % Create and return the MODBUS ADU request frame which for
            % SerialRTU is the PDU + crc.

            % Create Modbus PDU frame
            pdu = obj.createReadPDUframe(readTarget, startAddress, quantity, deviceId);            
            
            % Add the CRC to the frame
            modbusADU = obj.appendCRC(pdu);                                     
        end

        function modbusADU = createWriteADUframe(obj, writeTarget, startAddress, values, deviceId)
            % Create and return the MODBUS ADU request frame which for
            % SerialRTU is the PDU + crc.

            % Create Modbus PDU frame
            pdu = obj.createWritePDUframe(writeTarget, startAddress, values, deviceId);            

            % Add the CRC to the frame
            modbusADU = obj.appendCRC(pdu);                                    
        end 

        function modbusADU = createWriteReadADUframe(obj, writeAddress, values,...
                                                     readAddress, readCount, deviceId)
            % Create and return the MODBUS ADU request frame, which for
            % SerialRTU is the PDU + crc.
            
            % Create Modbus PDU frame
            pdu = obj.createWriteReadPDUframe(readAddress, readCount,...
                                                    writeAddress, values, deviceId);
            % Add the CRC to the frame
            modbusADU = obj.appendCRC(pdu);            
        end
        
        function modbusADU = createMaskWriteADUframe(obj, address, andMask, orMask, serverId)        
            % Create and return the MODBUS ADU request frame, which for
            % SerialRTU is the PDU + crc.     
            
            % Create Modbus PDU frame
            pdu = obj.createMaskWritePDUframe(address, andMask, orMask, serverId);
            
            % Add the CRC to the frame
            modbusADU = obj.appendCRC(pdu);            
        end      
        
        function valid = verifyCRC(obj,message, crc)
            % Verify that the crc passed in is correct
            expectedCrc = obj.computeCRC(message);
            valid = isequal(expectedCrc, crc);
        end         
    end
    
    methods (Access = private)
        function out = appendCRC(obj, modbusADU)
            % Create and append a CRC to the ADU frame passed in.
            
            index = length(modbusADU) + 1;
            % compute the crc and add it to the request
            crc = obj.computeCRC(modbusADU);
            modbusADU(index) = bitand(crc, 0xffu16);
            index  = index + 1;
            modbusADU(index) = bitshift(bitand(crc,0xff00u16),-8);
            out = modbusADU;
        end
    end
    
    %% Hidden method with unit test access
    methods (Access = {?internal.accessor.UnitTest} )
            
        function crc = computeCRC(~,message)
            % Compute the MODBUS RTU CRC for the passed in message frame
            crc = 0xFFFFu16;
            polynomial = 0xa001;
            
            % loop over each byte in the message frame
            for pos = 1:length(message)
                % XOR current byte into lsb of crc
                crc = bitxor(crc,uint16(message(pos))); 
                % loop over each bit
                for j = 1:8
                    % if the bit is set
                    if bitand(crc,1)
                        % shift right and xor in 0xa001
                        crc = bitshift(crc,-1);
                        crc = bitxor(crc,polynomial);
                    else
                        % shift right one
                        crc = bitshift(crc,-1);
                    end
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
            name = 'instrument.interface.coder.modbus.serialrtu.PacketBuilder';
        end
    end
end

