classdef HardwareInfo < dynamicprops & matlab.mixin.CustomDisplay
% HardwareInfo Displays information on available hardware.

% Copyright 2014 The MathWorks, Inc.
    
    properties (Access = private)
        % PropertyList - Stores the properties in the order of creation.
        PropertyList
    end
    
    methods
        % FIELDNAMES returns the properties of the object in in the order
        % of creation for maintaining backward compatibility with
        % INSTRHWINFO display.
        function names = fieldnames(obj)
            names = obj.PropertyList;
        end
    end
    
    methods (Static)
        % STRUCT2OBJ converts a structure to HardwareInfo object. The
        % structure fields are converted to properties.
        function obj = Struct2Obj(structData)
            obj = instrument.HardwareInfo();
            obj.PropertyList = fieldnames(structData);
            for i = 1: numel(obj.PropertyList)
                obj.addprop(obj.PropertyList{i});
                obj.(obj.PropertyList{i}) = structData.(obj.PropertyList{i});
            end
        end
    end
    
    methods (Access = protected)
        % GETFOOTER returns the footer information. 
        function footer = getFooter(~)
            if matlab.internal.display.isHot
                footer = sprintf('Access to your hardware may be provided by a support package. Go to the <a href="matlab:instrument.internal.supportPackageInstaller">Support Package Installer</a> to learn more.\n\n');
            else
                footer = '';
            end
        end
        
        % GETPROPERTYGROUPS returns the properties of the object in in the
        % order of creation for maintaining backward compatibility with
        % INSTRHWINFO display.
        function propgrp = getPropertyGroups(obj)
            if (~isempty(obj.PropertyList))
                propgrp = matlab.mixin.util.PropertyGroup(obj.PropertyList);
            else
                propgrp = [];
            end
        end
    end
end