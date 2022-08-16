classdef (Hidden) PacketBuilder < instrument.interface.modbus.PacketBuilder
    %PACKETBUILDER Builds Modbus Serial RTU request packets
    
    % Copyright 2019 The MathWorks, Inc.
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
        function outADU = appendCRC(obj, modbusADU)
            % Create and append a CRC to the ADU frame passed in.
            
            % Get the Modbus ADU length
            MBADULength = length(modbusADU);
            
            % Initialize the output ADU size based for coder.
            % Initialize the output ADU with uint8 as the incoming
            % modbusADU (modbbus pdu essentially) will always be of type
            % uint8.
            outADU = zeros(1, MBADULength + 2, 'uint8');
            outADU(1:MBADULength) = modbusADU;
            index = MBADULength + 1;
            
            % compute the crc and add it to the request
            crc = obj.computeCRC(modbusADU);
            outADU(index) = bitand(crc,hex2dec('ff')); 
            index  = index + 1;
            outADU(index) = bitshift(bitand(crc,hex2dec('ff00')),-8);
        end
        
        function crc = computeCRC(~,message)
        % Compute the MODBUS RTU CRC for the passed in message frame
            crc = uint16(hex2dec('FFFF'));
            polynomial = hex2dec('a001');
            
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
end

