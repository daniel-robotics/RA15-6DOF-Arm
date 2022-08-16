classdef (Hidden) DriverUtility < handle
    % DRIVERUTILITY class provides utility functions to search through
    % IEEE488.2 driver database and create an interface based on
    % instrument's resource
    
    %   Copyright 2012-2018 The MathWorks, Inc.
    
    
    methods (Static)
        function interface = createInterface(resource)
            % CREATEINTERFACE Create a visa object.
            interface = [];
            delimiter = '::';
            
            % Try to create a VSIA interface first
            visaInfo =  instrhwinfo('visa');
            visaAdaptors = visaInfo.InstalledAdaptors;
            if isempty (visaAdaptors)
                error (message('instrument:ieee4882Driver:noVisaInstalled')) ;
            end
            
            for i = 1 : size (visaAdaptors, 2)
                try
                    interface = visa(visaAdaptors{i}, resource);
                    if ~isempty (interface )
                        return;
                    end
                catch
                end
            end
            
            % Raw interface resource
          
            % GPIB interface
            if  contains ( resource , 'GPIB')
                position =  length ('gpib') + length(delimiter);
                [vendor , ~]  =  strtok (resource(position: length(resource)), delimiter);
                position =  position + length (vendor) + length(delimiter);
                [boardIndex , ~ ]  = strtok (resource(position: length(resource)), delimiter);
                position =  position + length (boardIndex) + length(delimiter);
                [primaryAddress , ~ ]  =  strtok (resource(position: length(resource)), delimiter);
                interface = gpib(vendor, str2double (boardIndex), str2double(primaryAddress));
                position  =  position + length (primaryAddress) + length(delimiter);
                interface.ByteOrder = 'littleEndian';
            end
            
            % Serial Interface
            if  contains ( resource , 'ASRL')
                position =  length ('ASRL') + length(delimiter);
                [port , ~]  =  strtok (resource(position: length(resource)), delimiter);
                position =  position + length (port) + length(delimiter);
                interface = serial (port);
                interface.ByteOrder = 'littleEndian';
            end
            
            % TCPIP Interface
            if      contains ( resource , 'TCPIP::SOCKET')
                position =  length ('TCPIP::SOCKET') + length(delimiter);
                [host , ~]  =  strtok (resource(position: length(resource)), delimiter);
                position =  position + length (host) + length(delimiter);
                [port , ~ ]  = strtok (resource(position: length(resource)), delimiter);
                position =  position + length (port) + length(delimiter);
                interface = tcpip(host, str2double (port) );
                interface.ByteOrder = 'littleEndian';
            end
            
            % Interface's property PV pair
            while (true )
                [pvPair , ~ ]  =  strtok (resource(position: length(resource)), delimiter);
                
                if isempty (pvPair )
                    break;
                end
                [propertyName , value ]  =   strtok (pvPair, ',');
                
                % Remove the coma
                value  = value(2: length(value));
                try
                    
                    prop = get (interface , propertyName );
                    if ischar ( prop )
                        set (interface , propertyName, value) ;
                    elseif strcmpi ( class (prop) , 'double')
                        set (interface , propertyName, str2double (value)) ;
                    end
                catch e
                    error (message('instrument:ieee4882Driver:invalidPVPairInResource')) ;
                end
                
                % Update position
                position = position + length (pvPair) + length(delimiter);
            end
            
        end
        
        
        function instrumentInfo = queryInstrument(interface)
            % QUERYINSTRUMENT Based on resource info, create an interface and query the
            % Instrument with *IDN? and find out the matching interface driver
            instrumentInfo ='';
            try
                fopen ( interface );
                instrumentInfo = query(interface, '*IDN?');
                fclose(interface);
                
            catch e
                fclose(interface);
                if strcmpi(e.identifier, 'instrument:fopen:opfailed' )
                    error (message('instrument:ieee4882Driver:invalidResource')) ;
                    
                end
            end
        end
        
        
        function resource = getResources()
            % GETRESOURCES Provides a list of interface resources, in tcpip case, provide a link
            % to helper function for user to create a resource string.
            resource = {};
            resource {end +1} =   instrument.ieee4882.DriverUtility.getResourceByType('serial');
            resource {end +1} =   instrument.ieee4882.DriverUtility.getResourceByType('gpib');
            
            % Appends the user created interface resources
            TcpipsocketResource = instrument.ieee4882.DriverUtility.createTcpipsocketResource('');
            if ~isempty (TcpipsocketResource)
                for i = 1: size ( TcpipsocketResource, 2)
                    resource{end + 1 }= TcpipsocketResource{i}; %#ok<*AGROW>
                end
            end
            
            % Add this as the last one
            % resource{end + 1 } =   instrument.ieee4882.DriverUtility.getResourceByType('tcpip');
            
        end
        
        
        
        function resources = getResourceByType (interfaceType)
            resources = {};
            
            % GETRESOURCEBYTYPE Appends the user created interface resources
            TcpipsocketResource = instrument.ieee4882.DriverUtility.createResource('');
            if ~isempty (TcpipsocketResource)
                for i = 1: size ( TcpipsocketResource, 2)
                    resources{end + 1 }= TcpipsocketResource{i};
                end
            end
            
            if  strcmpi ( interfaceType, 'serial')
                s = instrhwinfo ('serial');
                ports = s.SerialPorts;
                for i= 1: size (ports, 1)
                    resources{end + 1 } = sprintf ('ASRL::%s', ports{i} );
                end
                
            elseif  strcmpi ( interfaceType, 'gpib')
                g = instrhwinfo ('gpib');
                for i = 1:  size ( g.InstalledAdaptors , 2)
                    gpibAdaptor = instrhwinfo ('gpib', g.InstalledAdaptors{i}) ;
                    for j = 1 : size (gpibAdaptor.ObjectConstructorName, 2)
                        gpibInfo = char (gpibAdaptor.ObjectConstructorName{j});
                        gpibInfo = gpibInfo (length ('gpib' ) + 2 : length ( gpibInfo ) -2 );
                        [vendor , address ]  = strtok ( gpibInfo , ',');
                        vendor = vendor (2: end-1 ); % remove quotation marks
                        [boardIndex , primaryAddress] = strtok ( address(2:end) , ',');
                        boardIndex = strtrim (boardIndex );
                        primaryAddress = strtrim (primaryAddress (2:end));
                        resources{end + 1 } =  sprintf ('GPIB::%s::%s::%s', vendor , boardIndex , primaryAddress) ;
                    end
                    
                end
            end
            
        end
        
        
        
        function out = createResource (resource )
            % CREATERESOURCE Use InterfaceResources to track user created interface
            % resources. If input resource is empty, it behave as a query
            % just return the content in InterfaceResources.
            
            persistent InterfaceResources ;
            if isempty (InterfaceResources)
                InterfaceResources = {};
            end
            if ~isempty (resource)
                InterfaceResources{end+1 }= resource;
            end
            
            out = InterfaceResources;
        end
        
        
        function [driverName, firmWareVersion] = getDriver (resource,  instrumentType)
            % GETDRIVER Based on resource info, create an interface object and query the
            % instrument with *IDN? and find out the matching interface driver
            driverName = '';
            
            try
                interface = instrument.ieee4882.DriverUtility.createInterface(resource);
                instrumentInfo =  instrument.ieee4882.DriverUtility.queryInstrument(interface);
                if isempty (instrumentInfo)
                    error (message('instrument:ieee4882Driver:cannotLocateDriver'));
                end
            catch e
               if ~isempty(interface)
                   delete(interface);
               end
               rethrow(e);
            end
            delete (interface);
            interface = []; %#ok<NASGU>
            
            try
                [driverName, firmWareVersion] = feval (str2func('getIEEE4882DriverName'), instrumentInfo, instrumentType);
            catch
            end
            
        end
        
        
        
        function  validateDriverName (driverName, instrumentType)
            % VALIDATEDRIVERNAME validate if driver name is in a list of valid drivers.
            validDrivers = instrument.ieee4882.DriverUtility.getDrivers(instrumentType);
            if ~ismember ( driverName, validDrivers)
                error (message('instrument:ieee4882Driver:invalidDriver')) ;
            end
        end
        
        
        function Drivers =  getDrivers(instrumentType)
            % GETDRIVERS Provide a list available
            % IEEE488.2 drivers for the instrument type.
            % It will be replaced by other driver discovery technique in the future.
            Drivers = {};
            if strcmpi (instrumentType , 'scope')
                driverInfo.Name = 'tektronix';
                driverInfo.SupportedInstrumentModels = 'TDS200, TDS1000, TDS2000, TDS1000B, TDS2000B, TPS2000, TDS3000, TDS3000B, MSO4000, DPO4000, DPO7000, DPO70000B, DSA70000B';
                Drivers{end+1} = driverInfo;
            elseif strcmpi(instrumentType, 'fgen')
                driverInfo.Name = 'Agilent332x0_SCPI';
                driverInfo.SupportedInstrumentModels = '33210A, 33220A, 33250A';
                Drivers{end+1} = driverInfo;
            elseif strcmpi(instrumentType, 'rfsiggen')
                driverInfo.Name = 'AgRfSigGen_SCPI';
                driverInfo.SupportedInstrumentModels = 'E4428C, E4438C';
                Drivers{end+1} = driverInfo;
                driverInfo.Name = 'RsRfSigGen_SCPI';
                driverInfo.SupportedInstrumentModels = 'SMW200A, SMBV100A, SMU200A, SMJ100A, AMU200A, SMATE200A';
                Drivers{end+1} = driverInfo;
            end
        end
    end
    
end




