classdef (Hidden)InstrumentAdaptorFactory < handle
    %InstrumentAdaptorFactory class for creating instrument objects
    % InstrumentFactory uses chain of responsibility pattern to generate
    % instrument objects based on the instrument type, resource or driver
    % name.
    
    % Copyright 2011 The MathWorks, Inc.
    
    methods(Static)
        
        function [scopeAdaptor, driver] = createAdaptor( varargin)
            %CreateAdaptor method follows the chain of responsbility pattern, it
            %iterates througg each adaper. If an adapter can handle the
            %situation,it will create itself and return. Otherwise it
            %passes the responsibility to the next available adapter.
            %Note: The order of adapters is important and it is specified
            %in the adapters.config file.
            
            scopeAdaptor = [];
            driver = '';
            
            instrumentType = char(varargin{1});
            %get a list of adapters based on given instrument type
            adaptors = instrument.internal.udm.InstrumentUtility.getAdapterList(instrumentType);
            
            narginchk(2,3);
            switch (nargin)
                %create an adapter based on the resource information.
                case 2
                    resource = char(varargin{2});
                    for i = 1: size (adaptors , 2)
                        [scopeAdaptor, driver] = feval(str2func([adaptors{i}.Name '.createByResource']), resource);
                        if ~isempty (scopeAdaptor)
                            break;
                        else
                            continue;
                        end
                    end
                    %create an adapter based on the resource and driver information.
                case 3
                    resource = char(varargin{2});
                    driverName = varargin{3};
                    for i = 1: size (adaptors , 2)
                        [scopeAdaptor, driver] = feval(str2func([adaptors{i}.Name '.createByDriverAndResource']), driverName, resource);
                        if ~isempty (scopeAdaptor)
                            break;
                        else
                            continue;
                        end
                    end
            end
            
        end
        
    end
end