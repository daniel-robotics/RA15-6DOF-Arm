function instrnotify(varargin)
%INSTRNOTIFY Define notification for instrument events.
%
%   INSTRNOTIFY('TYPE', CALLBACK) evaluates the MATLAB expression, CALLBACK,
%   in the MATLAB workspace when an event of type, TYPE, is generated. TYPE
%   can be ObjectCreated, ObjectDeleted or PropertyChangedPostSet. 
%   
%   If TYPE is ObjectCreated, CALLBACK is evaluated each time an instrument
%   object or a device group object is created. If TYPE is ObjectDeleted, 
%   CALLBACK is evaluated each time an instrument object or a device group
%   object is deleted. If TYPE is PropertyChangedPostSet, CALLBACK is 
%   evaluated each time an instrument object or device group object property 
%   is configured with SET. 
%   
%   CALLBACK can be:
%      - a function handle
%      - a string to be evaluated
%      - a cell array containing the function to evaluate in the first cell 
%        (function handle or name of function) and extra arguments to pass to 
%        the function in subsequent cells.
%
%   The CALLBACK function is invoked with:
%           function(obj, event, [arg1, arg2,...])
%
%   where obj is the instrument object or device group object generating 
%   the event. event is a structure containing information on the event
%   generated. If TYPE ObjectCreated or ObjectDeleted, event contains the
%   type of event. If TYPE is PropertyChangedPostSet, event contains the
%   type of event, the property being configured and the new property value.
%
%   INSTRNOTIFY({'Prop1', 'Prop2', ...}, 'TYPE', CALLBACK) evaluates the 
%   MATLAB expression, CALLBACK, in the MATLAB workspace when one of the
%   specified properties, Prop1, Prop2, are configured. TYPE can only be 
%   PropertyChangedPostSet.
%
%   INSTRNOTIFY(OBJ, 'TYPE', CALLBACK) evaluates the MATLAB expression, 
%   CALLBACK, in the MATLAB workspace when an event of type, TYPE, for 
%   object, OBJ, is generated. OBJ can be an array of instrument objects 
%   or an array of device group objects.
%
%   INSTRNOTIFY(OBJ, {'Prop1', 'Prop2', ...}, 'TYPE', CALLBACK) evaluates 
%   the MATLAB expression, CALLBACK, in the MATLAB workspace when one of the
%   specified properties, Prop1, Prop2 are configured on object, OBJ.
%
%   INSTRNOTIFY('TYPE', CALLBACK, '-remove') removes the specified CALLBACK
%   of type, TYPE.
%
%   INSTRNOTIFY(OBJ, 'TYPE', CALLBACK, '-remove') removes the specified 
%   CALLBACK of type, TYPE, for object, OBJ.
%
%   Note: PropertyChangedPostSet events are generated only when the property is 
%   configured to a different value than what the property is currently 
%   configured to. For example, if a GPIB object's Tag property is configured
%   to 'myobject', a PropertyChangedPostSet event will not be generated if the 
%   object's Tag property is set to 'myobject'. A PropertyChangedPostSet event 
%   will be generated if the object's Tag property is set to 'myGPIBObject'.
%
%   Note: If OBJ is specified and the callback TYPE is ObjectCreated, then
%   the callback will not be generated since OBJ has already been created.
%
%   Note, if Type is ObjectDeleted, the invalid object, OBJ, is not passed as
%   the first input argument to the CALLBACK function. An empty matrix is passed 
%   as the first input argument.
%
%   Example:
%       instrnotify('PropertyChangedPostSet', @instrcallback);
%       g = gpib('agilent', 0, 4);
%       set(g, 'Name', 'mygpib');
%       fopen(g);
%       fclose(g);
%       instrnotify('PropertyChangedPostSet', @instrcallback, '-remove');
%

%   Copyright 1999-2018 The MathWorks, Inc.

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

switch nargin
case 0
    error(message('instrument:instrnotify:invalidSyntax'));
case 1
    error(message('instrument:instrnotify:invalidSyntax'));
case 2
    error(message('instrument:instrnotify:invalidSyntax'));
case 3
    % Valid Syntax: instrnotify(obj, 'PropertyChangedPostSet', @instrcallback);
    if isa(varargin{1}, 'instrument')
        % Ex. instrnotify(obj, 'PropertyChangedPostSet', @instrcallback);
        objects  = varargin{1};
        props    = {};
        type     = varargin{2};
        callback = varargin{3};
    else
        error(message('instrument:instrnotify:invalidSyntax'));
    end
case 4
    % Valid Syntax: instrnotify(obj, {'Name', 'Status'}, 'PropertyChangedPostSet', @instrcallback);
    % Valid Syntax: instrnotify(obj, 'PropertyChangedPostSet', @instrcallback, '-remove');
    if ischar(varargin{4}) && strcmp(varargin{4}, '-remove')
        type     = varargin{2};
        callback = varargin{3};
          
        if ~any(strcmpi(type, {'PropertyChangedPostSet', 'ObjectCreated', 'ObjectDeleted'}))
            error(message('instrument:instrnotify:invalidArg'));
        end
        
        localRemoveNotification(varargin{1}, callback, type);  
        return;
    else
        objects  = varargin{1};
        props    = varargin{2};
        type     = varargin{3};
        callback = varargin{4};
        
        % Do a little checking in case the wrong flag was passed. This
        % allows a better error message to be returned.
        if ~ischar(type)
            error(message('instrument:instrnotify:invalidSyntax'));
        end          
    end
otherwise
    error(message('instrument:instrnotify:invalidSyntaxArgv'));
end    

% Error checking.
if ~ischar(type)
    error(message('instrument:instrnotify:invalidArg'));
end        

if ~any(strcmpi(type, {'PropertyChangedPostSet', 'ObjectCreated', 'ObjectDeleted'}))
    error(message('instrument:instrnotify:invalidArg'));
end

% If properties are specified, TYPE must be PropertyChangedPostSet.
if ~isempty(props) && ~strcmpi(type, 'PropertyChangedPostSet')
    error(message('instrument:instrnotify:invalidSyntaxType'));
end

% If objects are specified, they must all be valid.
if ~isempty(objects) && ~all(isvalid(objects))
    error(message('instrument:instrnotify:invalidSyntaxObj'))
end

addForDevice = false;
addForInstrument = false;

% Verify that valid properties were specified.
if ~isempty(props)
    if ischar(props)
        props = {props};
    end    
    if ~iscellstr(props)
        error(message('instrument:instrnotify:invalidSyntaxCell'));
    end

    % Verify properties specified for device objects.
    jobjects = java(igetfield(objects, 'jobject'));
    for j = 1:length(objects)
        if isa(objects(j), 'icdevice')
            addForDevice = true;
            for i = 1:length(props)
                s = com.mathworks.toolbox.instrument.device.util.PropertyHelp.isValidPropertyName(jobjects(j), props{i});
                if isempty(s)
                    error(message('instrument:instrnotify:InvalidProp', props{ i }));
                else
                    props{i} = s;
                end
            end
        end
    end
    
    % The properties must be valid for each object type specified.
    classNames = localGetClassNames(objects);
    for j = 1:length(classNames)
        for i = 1:length(props)
            addForInstrument = true;
            s = com.mathworks.toolbox.instrument.util.PropertyHelp.isValidPropertyName(classNames{j}, props{i});
            if isempty(s)
                error(message('instrument:instrnotify:InvalidProp', props{ i }));
            else
                props{i} = s;
            end
        end
    end
else
    % Determine the type of objects specified.
    for i = 1:length(objects)
        if isa(localObjectIndexer(objects, i), 'icinterface')
            addForInstrument = true;
        elseif isa(localObjectIndexer(objects, i), 'icdevice')
            addForDevice = true;
        end
    end            
end
    
% Verify that the callback is configured to a string, cell array or a function 
% handle.
 localIsValidCallback(callback);
 
% Store the warning state.
lastwarn('');
warnState = warning('backtrace', 'off');

% Add notification.
if (addForInstrument)
    com.mathworks.toolbox.instrument.Instrument.addNotification(type, localObjects2Vector(objects, 'icinterface'), props, callback);
end

if (addForDevice)
    com.mathworks.toolbox.instrument.device.icdevice.ICDevice.addNotification(type, localObjects2Vector(objects, 'icdevice'), props, callback);
end

% Restore the warning state.
warning(warnState);


% ------------------------------------------------------------------------------------
% Get a unique list of classnames.
function out = localGetClassNames(objects)

out = cell(1, length(objects));
for i = 1:length(objects)
    out{i} = class(objects(i));
    if strcmp(out{i}, 'visa')
        out{i} = get(objects(i), 'Type');
    end
end
out = unique(out);
out(find(strcmp(out, 'icdevice'))) = [];

% ------------------------------------------------------------------------------------
% Convert an array of objects to a java vector.
function out = localObjects2Vector(objects, type)

out = java.util.Vector;
for i = 1:length(objects)
    if isa(localObjectIndexer(objects, i), type)
        out.addElement(java(igetfield(localObjectIndexer(objects, i), 'jobject')));
    end
end

% ------------------------------------------------------------------------------------
% NOTE: provide error ID for the exception
function localIsValidCallback(callback)

% If a string, it is a valid callback.
if ischar(callback)
    return;
end

% If a function handle, it is a valid callback.
if isa(callback, 'function_handle')
    return;
end

% If it is not a cell, string or a function handle, error.
if ~iscell(callback)
    newExc =  MException('instrument:instrnotify:invalidCallBack','Invalid CALLBACK. CALLBACK must be a string, a 1-by-n cell array or a function handle.' );
    throwAsCaller(newExc);
end

% Verify cell array has the correct dimensions.
[row, col] = size(callback);
if (row ~= 1)
    newExc =  MException('instrument:instrnotify:invalidCallBack','Invalid CALLBACK. CALLBACK must be a string, a 1-by-n cell array or a function handle.' );
    throwAsCaller(newExc);
end
   
% Verify first element of cell array.   
firstElement = callback{1};
if ~(ischar(firstElement) || isa(firstElement, 'function_handle')) || isempty(firstElement)
    newExc =  MException('instrument:instrnotify:invalidCallBack','Invalid CALLBACK. The first element of the cell array must be either a string or a function handle.' );
    throwAsCaller(newExc);
end

% ------------------------------------------------------------------------------------
function localRemoveNotification(obj, callback, type)

for idx = 1:length(obj)
    if (isa(localObjectIndexer(obj, idx), 'icdevice'))
        % Look at device objects.
        try
            cbs = com.mathworks.toolbox.instrument.device.util.MLNotifier.getNotificationCallbacks(type);
            for i = cbs.size:-1:1
                val = cbs.elementAt(i-1);
                if isa(val, 'com.mathworks.toolbox.instrument.device.PropertyListenerObject') || ...
                        isa(val, 'com.mathworks.toolbox.instrument.device.DeleteListenerObject')
                    val = val.getCallback;
                end

                if isequal(val, callback)
                    com.mathworks.toolbox.instrument.device.util.MLNotifier.removeNotification(type, i-1);
                end
            end
        catch
        end
        continue;
    end

    % Look at instrument objects.
    try
        cbs = com.mathworks.toolbox.instrument.Instrument.getNotificationCallbacks(type);
        for i = cbs.size:-1:1
            val = cbs.elementAt(i-1);
            if isa(val, 'com.mathworks.toolbox.instrument.PropertyListenerObject') || ...
                    isa(val, 'com.mathworks.toolbox.instrument.DeleteListenerObject')
                val = val.getCallback;
            end

            if isequal(val, callback)
                com.mathworks.toolbox.instrument.Instrument.removeNotification(type, i-1);
            end
        end
    catch
    end
end

% Some instrument objects do not overload subsef.  As a result, the built in
% subsef may be called instead of instrument/subsef inside an instrument method.
% This is the intentional behavior of MATLAB OOPs object.  We need to force use
% of instrument/subsref ourselves.
function obj = localObjectIndexer(objs, index)

obj = instrgate('privateObjectIndexer', objs, index);


