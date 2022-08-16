classdef  IviSwtch < instrument.ivic.IviSwtchSpecification
    %IVISWTCH IviSwtch MATLAB wrapper provides programming support
    %for the IVI-C Swtch Class.  The driver contains all the functionalities
    %required in the IviSwtch specification defined by the IVI Foundation.
    %This wrapper requires VISA ,IVI Compliance Package and an IVI instrument
    %specific driver that is compliant with the IviSwtch class. The
    %IviSwtch class wrapper accesses the specific driver using the logical
    %name in the configuration store.
    
    %   OBJ = instrument.ivic.IviSwtch() constructs an IVI-C Swtch object.
    %
    %   In order to communicate with the instrument, the device object must be
    %   connected to the instrument with the init() or InitWithOption() function.
    %
    %   Example using a MATLAB IVI-C Swtch class complaint instrument wrapper:
    %
    %       % Construct an IVI-C Swtch object
    %       swtchObj = instrument.ivic.IviSwtch();
    %
    %       % Connect to the instrument via logical name 'mySwtch'
    %       swtchObj.init('mySwtch', false, false);
    %
    %       % Connect to the instrument via logical name 'mySwtch' in
    %       simulation mode
    %       swtchObj.InitWithOption('mySwtch', false, false, 'simulate=true');
    %
    %       % Disconnect from the instrument and clean up.
    %       swtchObj.close();
    %       delete(swtchObj);
    
    % Copyright 2010 The MathWorks, Inc.
    
    %% Construction
    methods
        function obj = IviSwtch()
            narginchk(0,0)
            instrgate ('privateCheckNICPVersion');
            % construct superclass
            obj@instrument.ivic.IviSwtchSpecification();
            
        end
        
    end
    
    %% Public Read Only Properties
    properties (SetAccess = private)
        
    end
    
    %% methods
    methods
        %override base class's init() method
        function init(obj, LogicalName,IDQuery,ResetDevice)
            obj.init@instrument.ivic.IviSwtchSpecification(LogicalName,IDQuery,ResetDevice);
            obj.updateLibraryAndSession();
        end
        
        
        %override base class's InitWithOptions() method
        function  InitWithOptions(obj,LogicalName,IDQuery,ResetDevice,OptionString)
            obj.InitWithOptions@instrument.ivic.IviSwtchSpecification(LogicalName,IDQuery,ResetDevice,OptionString );
            obj.updateLibraryAndSession();
        end
        
        %override base class's close() method
        function close(obj)
            obj.close@instrument.ivic.IviSwtchSpecification();
            obj.session=[];
            obj.updateLibraryAndSession();
         
        end
        
        %helper function to update driver's session
        function updateLibraryAndSession(obj)

            obj.MatrixConfiguration.setLibraryAndSession(obj.libName, obj.session);
            obj.ScanningConfiguration.setLibraryAndSession(obj.libName, obj.session);
            obj.ModuleCharacteristics.setLibraryAndSession(obj.libName, obj.session);
            obj.ChannelConfiguration.setLibraryAndSession(obj.libName, obj.session);
            obj.InherentIVIAttributes.setLibraryAndSession(obj.libName, obj.session);
            obj.Utility.setLibraryAndSession(obj.libName, obj.session);
            obj.Scan.setLibraryAndSession(obj.libName, obj.session);
            obj.Route.setLibraryAndSession(obj.libName, obj.session);
            obj.Configuration.setLibraryAndSession(obj.libName, obj.session);
        end
        
    end
end


 