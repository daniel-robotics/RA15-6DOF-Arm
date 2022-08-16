classdef (Hidden) PacketBuilder < instrument.interface.modbus.PacketBuilder
    %PACKETBUILDER Builds Modbus TCP/IP request packets
    
    % Copyright 2019 The MathWorks, Inc.
    %#codegen

    properties (Hidden, SetAccess=private, GetAccess=private)
        % Transaction Id. This will be incremented with each transaction.
        TransactionId
    end
    
    %% Constructor
    methods
        function obj = PacketBuilder(converter)
            % call throught to base class
            obj@instrument.interface.modbus.PacketBuilder(converter);
            obj.TransactionId = 1;
        end
    end
    
    %% Public methods
    methods
        function modbusADU = createReadADUframe(obj, readTarget, startAddress, quantity, serverId)
            % Create and return the MODBUS ADU request frame, which for
            % MODBUS TCP is the MBAP + PDU.
            
            pdu = obj.createReadPDUframe(readTarget, startAddress, quantity, serverId);            
            modbusADU = obj.addMBAPheader(pdu);
        end        
        
        function modbusADU = createWriteADUframe(obj, writeTarget, startAddress, values, serverId)
            % Create and return the MODBUS ADU request frame, which for
            % MODBUS TCP is the MBAP + PDU.
            
            pdu = obj.createWritePDUframe(writeTarget, startAddress, values, serverId);            
            modbusADU = obj.addMBAPheader(pdu);            
        end   
        
        function modbusADU = createWriteReadADUframe(obj, writeAddress, values,...
                                                     readAddress, readCount, serverId)
            % Create and return the MODBUS ADU request frame, which for
            % MODBUS TCP is the MBAP + PDU.
            
            % Create Modbus PDU frame
            pdu = obj.createWriteReadPDUframe(readAddress, readCount,...
                                              writeAddress, values, serverId);
            modbusADU = obj.addMBAPheader(pdu);
        end
        
        function modbusADU = createMaskWriteADUframe(obj, address, andMask, orMask, serverId)        
            % Create and return the MODBUS ADU request frame, which for
            % MODBUS TCP is the MBAP + PDU.     
            
            % Create Modbus PDU frame
            pdu = obj.createMaskWritePDUframe(address, andMask, orMask, serverId);
                                          
            modbusADU = obj.addMBAPheader(pdu);            
        end
    end
    
    %% Private methods
    methods (Access = private)
        
        function modbusADU = addMBAPheader(obj, pdu)
            % Append an MBAP header to the pdu passed in.
            
            len = length(pdu);            
            mbap = obj.createMBAPheader(uint16(obj.TransactionId), uint16(len));            
            obj.TransactionId = obj.TransactionId + 1;
            modbusADU = [mbap, pdu];            
        end
               
        function MBAPheader = createMBAPheader(obj, transactionId, packetLen)
            % Create the standard MODBUS TCP MBAP header
            MBAPheader = zeros(1,6,'uint8');
            index = 1;
            % transactionId
            xactBytes = obj.Converter.word2bytes(transactionId);            
            MBAPheader(index) = xactBytes(1);
            index  = index +1;
            MBAPheader(index) = xactBytes(2);            
            index = index + 3; % skip past protocol id which is 0 for MODBUS            
            lenBytes = obj.Converter.word2bytes(packetLen);            
            MBAPheader(index) = lenBytes(1);
            index  = index +1;
            MBAPheader(index) = lenBytes(2);                      
        end       
                   
    end
end

