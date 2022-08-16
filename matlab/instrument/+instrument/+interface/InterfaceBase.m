classdef InterfaceBase < instrument.internal.InterfaceBaseClass
    %INTERFACEBASE The base class for all the interface objects
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties (GetAccess = 'public', SetAccess = 'protected')
        % BoardIndex - The vendor device index
        BoardIndex
        % VendorName - The name of the Vendor
        VendorName
        % BoardSerial - The device serial number
        BoardSerial
        % ConnectionStatus - The connection status of the interface object
        ConnectionStatus
        % TransferStatus - The transfer status of the interface object
        TransferStatus
    end
    
    properties (Hidden, SetAccess = 'protected')
        % InterfaceType - The interface type
        InterfaceType
    end
    
    properties (Abstract)
        %BitRate - The speed of communication
        BitRate
        % Port - Specifies the physical port associated with the object and
        % the device.
        Port
    end
    
    
    % Getters/Setters
    methods
        function value = get.ConnectionStatus(obj)
            value = char(obj.ConnectionStatus);
        end
        
        function value = get.TransferStatus(obj)
            value = char(obj.TransferStatus);
        end
    end
    
    % Methods
    
    methods(Abstract)
        % CONNECT(obj) connects the interface object to the device
        connect(obj)
        % DISCONNECT(obj) disconnects the interface object from the device
        disconnect(obj)
    end
    
    methods (Hidden)
        
        function obj = InterfaceBase()
        end
        
        function disp(obj)
            %disp Display method for interface objects.
            
            if (~isvalid(obj))
                disp(getString(message ('instrument:Interface:deletedObject')));
                return;
            end
            
            if (isscalar(obj))                
                fprintf('%s Object : \n\n', obj.InterfaceType);
                fprintf('\tAdapter Settings\n');
                fprintf('%s', obj.displayAdapterSettings);
                fprintf('\tCommunication Settings\n');
                fprintf('%s', obj.displayCommunicationSettings);
                fprintf('\tCommunication State\n');
                fprintf('%s', obj.displayCommunicationState);
                fprintf('\tRead/Write State\n');
                fprintf('%s', obj.displayReadWriteState);
            else
                obj.localArrayDisplay();
            end
        end
        
        function dispString = displayAdapterSettings(obj)
            % displayAdapterSettings Displays the adapter settings for the
            % device
            dispString = sprintf('\t\tBoardIndex:            %d\n', obj.BoardIndex);
            dispString = sprintf('%s\t\tBoardSerial:           %s\n', dispString, num2str(obj.BoardSerial));
            dispString = sprintf('%s\t\tVendorName:            %s\n\n',dispString, obj.VendorName);
        end
        
        function dispString = displayCommunicationSettings(obj)
            % displayCommunicationSettings Displays the communication settings
            % for the device
            dispString = sprintf('\t\tBitRate:            %d\n\n',obj.BitRate);
            dispString = sprintf('%s\t\tPort:                 %d\n',dispString, obj.Port);
        end
        
        function dispString = displayCommunicationState(obj)
            % displayCommunicationSettings Displays the communication state the
            % device
            dispString = sprintf('\t\tConnectionStatus:      %s\n\n', char(obj.ConnectionStatus));
        end
        
        function dispString = displayReadWriteState(obj)
            % displayCommunicationSettings Displays the transfer state for the
            % device
            dispString = sprintf('\t\tTransferStatus:        %s\n\n', char(obj.TransferStatus));
            
        end
        
        function fopen(~)
            error(message('instrument:Interface:methodNotSupported', 'FOPEN', 'Please use CONNECT method.'))
        end
        
        function fclose(~)
            error(message('instrument:Interface:methodNotSupported', 'FCLOSE', 'Please use DISCONNECT method.'))
        end
        
        function A = fread(~) %#ok<STOUT>
            error(message('instrument:Interface:methodNotSupported', 'FREAD', 'Please use READ or WRITEANDREAD method.'))
        end
        
        function fwrite(~, ~)
            error(message('instrument:Interface:methodNotSupported', 'FWRITE', 'Please use WRITE or WRITEANDREAD method.'))
        end
        
        function get(varargin)
            error(message('instrument:Interface:methodNotSupported', 'GET', ''))
        end
        
        function set(varargin)
            error(message('instrument:Interface:methodNotSupported', 'SET', ''))
        end
        
        function localArrayDisplay(obj)
            %LOCALARRAYDISPLAY creates the display for an array of objects.
            
            % Create the index.
            dispLength = length(obj);
            index = num2cell(1:dispLength);
            
            % Initialize variables.
            typeValues   = cell(dispLength,1);
            statusValues = cell(dispLength,1);
            nameValues   = cell(dispLength,1);
            
            % Get all the values for the display.
            for i = 1:dispLength
                if isvalid(obj(i))
                    typeValues{i}   = obj(i).InterfaceType;
                    statusValues{i} = obj(i).ConnectionStatus;
                    nameValues{i}   = [obj(i).InterfaceType '-' num2str(obj(i).BoardIndex) '-' num2str(obj(i).Port)];
                else
                    typeValues{i}   = 'Invalid';
                    statusValues{i} = 'Invalid';
                    nameValues{i}   = 'Invalid';
                end
            end
            
            % Calculate spacing information.
            typeLength   = max(cellfun('length', typeValues));
            statusLength = max(cellfun('length', statusValues));
            maxSpacing   = 4;
            
            % Write out the header.
            fprintf('\n');
            fprintf([blanks(3) 'Instrument Object Array\n\n']);
            fprintf([blanks(3) 'Index:' blanks(maxSpacing) 'Type:' blanks(maxSpacing + typeLength-5)...
                'Status:' blanks(maxSpacing+statusLength-7) 'Name:  \n']);
            
            % Write out the property values.
            for i = 1:dispLength
                fprintf([blanks(3) num2str(index{i})...
                    blanks(6 + maxSpacing - length(num2str(index{i}))) typeValues{i}...
                    blanks(typeLength + maxSpacing - length(typeValues{i})) statusValues{i}...
                    blanks(statusLength + maxSpacing - length(statusValues{i})) num2str(nameValues{i})...
                    '\n']);
            end
            
            fprintf('\n');
            
        end
    end
end
