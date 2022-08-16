classdef (Hidden)InstrumentUtility < handle
    %InstrumentUtility class provides useful helper functions.
    % InstrumentUtility offers support functions such as available
    % instrument resources and drivers. It also retrieves available
    % adapters information from adapters.config file.
    
    %    Copyright 2011-2013 The MathWorks, Inc.
    
    methods(Static)
        
        function resources = getResources(instrumentType)
            %GetResources method follows the chain of responsibility pattern, it
            %iterates through each adapter and query the resource information.
            
            adaptors = instrument.internal.udm.InstrumentUtility.getAdapterList(instrumentType);
            
            resourcesArray ={};
            for i = 1: size (adaptors , 2)
                % for each resource discovery technique
                for j =  1 : size ( adaptors{i}.ResourceDiscovery, 2)
                    try
                        specificTarget = feval(str2func([adaptors{i}.Name '.getResource']),adaptors{i}.ResourceDiscovery{j} );
                        resourcesArray  =  horzcat (resourcesArray , specificTarget ); %#ok<*AGROW>
                    catch e  %#ok<*NASGU>
                    end
                end
            end
            
            %eliminate dups
            resources = unique(resourcesArray);
            
        end
        
        
        function visaResources = getVisaResources() %#ok<*STOUT>
            %GetVisaResources returns a list of VISA resources installed in
            %the system.
            
            visaResources ={};
            visaInfo =  instrhwinfo('visa');
            visaAdaptors = visaInfo.InstalledAdaptors;
            if isempty (visaAdaptors)
                return;
            end
            
            for i = 1 : size (visaAdaptors, 2)
                try
                    % report all VISA resources
                    visa = instrhwinfo ('visa', visaAdaptors{i}, 'generic');
                    for idx = 1: size (visa.ObjectConstructorName, 1)
                        constructorName =  visa.ObjectConstructorName{idx};
                        resourceName = textscan (constructorName,'%s','delimiter', ',');
                        % get resource portion of constructor
                        visaResources{end+1} =   resourceName{1}{2}(2: length(resourceName{1}{2}) - 3);
                    end
                catch e
                end
            end
        end
            
        
        function drivers = getDrivers(instrumentType)
            %GetDrivers method follows the chain of responsibility pattern, it
            %iterates through each adapter and query the supported driver information.
            
            adaptors = instrument.internal.udm.InstrumentUtility.getAdapterList(instrumentType);
            drivers = {};
            %follows chain of responsibility pattern
            for i = 1: size (adaptors , 2)
                try
                    specificDrivers = feval(str2func([adaptors{i}.Name '.getDriver']));
                    drivers  =  horzcat (drivers , specificDrivers );
                catch e
                end
            end
            
        end
        
        
        function adaptors =  getAdapterList(instrumentType)
            %GetAdapterList reads adapters.config file and get a list of available
            %adapters for each OS and the instrument type.
            
            ictroot = toolboxdir('instrument');
            adaptersFileName = fullfile(ictroot, 'instrument', '+instrument','+internal', '+udm' ,'adapters.config' );
            [xpa, doc ,  XPathConst ] = initializeXPath(adaptersFileName);
            % Parse the config file and retrieve adapter info.
            adaptors = getAdapters(xpa , doc, XPathConst, instrumentType);
                            
            function [xpa, doc, Constant] = initializeXPath(configFileName)
                % initialize the XPath
                import javax.xml.xpath.*
                import javax.xml.parsers.*
                import javax.xml.validation.*
                import java.io.File
                import javax.xml.transform.stream.StreamSource;
                
                factory = DocumentBuilderFactory.newInstance();
                factory.setNamespaceAware(true);
                builder = factory.newDocumentBuilder();
                
                try
                    doc = builder.parse(configFileName);
                    xpf = XPathFactory.newInstance();
                    xpa = xpf.newXPath();
                catch e
                    error(message('instrument:oscilloscope:failedToParseConfigFile'));
                    
                end
                
                Constant = XPathConstants.NODESET;
                
            end
            
            
            function adapters = getAdapters(xpa, doc, XPathConstants , instrumentType)
                %GetAdapters method returns a array of available adapters based on
                %instrument type and OS.
                
                adapters ={};
                %locates xpath for the right OS and instrument type
                instrumentAdaptersPath = sprintf('adptersConfig/OS/%s/%s/adapter',computer, instrumentType);
                try
                    instrumentAdapters = xpa.evaluate(instrumentAdaptersPath, doc,XPathConstants);
                    %get each adapter's info
                    for idx = 1: instrumentAdapters.getLength()
                        
                        adapterPath = sprintf('%s[%d]/',instrumentAdaptersPath, idx );
                        adapterName = xpa.evaluate([adapterPath '/name'] ,doc,XPathConstants);
                        adapter.Name = char(adapterName.item(0).getTextContent);
                        resourcePath = sprintf('%s/resourceIdentification',adapterPath );
                        adapterResources = xpa.evaluate(resourcePath, doc,XPathConstants);
                        resources ={};
                        
                        %find out resource identification options for each
                        %adapter
                        for resourceIdx = 1: adapterResources.getLength()
                            resourceIDPath = sprintf('%s[%d]/name',resourcePath, resourceIdx );
                            adapterResource = xpa.evaluate(resourceIDPath ,doc,XPathConstants);
                            resources{end+1}  = char(adapterResource.item(0).getTextContent);
                        end
                        
                        adapter.ResourceDiscovery = resources;
                        adapters{end+1}= adapter;
                    end
                    
                catch e
                end
            end
        end
        
        
        function instrumentInfo = queryInstrument( resource)
            %QueryInstrument creates a VISA object and send '*IDN' to the
            %instrument, then it queries resource string from the
            %instrument.
            visaInfo =  instrhwinfo('visa');
            visaAdaptors = visaInfo.InstalledAdaptors;
            if isempty (visaAdaptors)
                error (message('instrument:oscilloscope:noVisaInstalled')) ;
            end
            
            v = [];
            for i = 1 : size (visaAdaptors, 2)
                try
                    v = visa(visaAdaptors{i}, resource); %#ok<TNMLP>
                    break;
                catch e
                end
            end
            
            if isempty (v)
                error (message('instrument:oscilloscope:notValidResource')) ;
            end
            
            try
                fopen ( v );
                instrumentInfo = query(v, '*IDN?');
                fclose(v);
                delete (v);
            catch e
                fclose(v);
                delete (v);
                if strcmpi(e.identifier, 'instrument:fopen:opfailed' )
                    error(message('instrument:oscilloscope:notValidResource' ));
                end
            end
            
        end
        
    end
end