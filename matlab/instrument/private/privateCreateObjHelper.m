function out = privateCreateObjHelper(action, varargin)
%PRIVATECREATEOBJHELPER helper function used by the New Object Dialog.
%
%   PRIVATECREATEOBJHELPER helper function used by the New Object 
%   Dialog to create instrument objects. This dialog is used by
%   INSTRCREATE, MIDTEST and TMTOOL.
%   
%   This function should not be called directly be the user.
%  
%   See also INSTRCREATE, MIDTEST, TMTOOL.
%
 
%   MP 9-08-03
%   Copyright 1999-2019 The MathWorks, Inc.

% Capture the interface or device object that was created for usage data
% logging
logger = instrument.internal.UsageLogger();

switch action
case 'serial'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    % Create the serial port object.
    obj = serial(varargin{1});
    out = createdObject(obj);    
case 'Bluetooth'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    obj = Bluetooth(varargin{1}, str2double(varargin{2}));
    out = createdObject(obj);
case 'i2c'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    vendor =  strtok(varargin{1}, ':');
    if isempty(varargin{3})
        % If remote address is empty, throw an error
        error(message('instrument:i2c:invalidSyntax'));
    else
        if strfind(varargin{3}, '0x')
            hexString = varargin{3};
            remoteAddress = hex2dec(hexString(3:end));
        elseif strfind(varargin{3}, 'h')
            hexString = varargin{3};
            remoteAddress = hex2dec(hexString(1:end-1));
        else
            remoteAddress = str2double(varargin{3});
        end
        
    end
    obj = i2c(vendor, str2double(varargin{2}), remoteAddress);
    out = createdObject(obj);
case 'gpib'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    % Parse the input.
    vendor = varargin{1};
    bid = str2double(varargin{2});
    pad = str2double(varargin{3});
    
    % Create the GPIB object.
    obj = gpib(vendor, bid, pad);
    out = createdObject(obj);
case 'visa'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    % Create the VISA object.
    obj = visa(varargin{1}, varargin{2});
    out = createdObject(obj);
case 'tcpip'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    % Parse the inputs.
    remotehost = varargin{1};
    remoteport = specifyRemotePort(varargin{2});
    
    % Call the TCPIP constructor with the correct arguments based
    % on what the user entered in the dialog.
    if isempty(remoteport)
        obj = tcpip(remotehost);
    else
        obj = tcpip(remotehost, remoteport);
    end
    
    % Get needed output arguments for GUI.
    out = createdObject(obj);
case 'udp'
    logger.logTmToolHardwareUsage('interfaceObj', convertCharsToStrings(action), 'deviceObj', "", 'IviClassDriver', "")
    % Parse the input.
    remotehost = varargin{1};
    remoteport = specifyRemotePort(varargin{2});
    
    % Call the UDP constructor with the correct arguments based
    % on what the user entered in the dialog.
    if isempty(remotehost)
        obj = udp;
    elseif isempty(remoteport)
        obj = udp(remotehost);
    else
        obj = udp(remotehost, remoteport);
    end
    
    % Get needed output arguments for GUI.
    out = createdObject(obj);
case 'device'
    % Parse the input.
    driverName = char(varargin{1});
    interface  = varargin{2};
    
    % Initialize the value of the interface string to be usage logged
    interfaceLogStr = "";
    driverLogStr = convertCharsToStrings(driverName);
    
    if isa(interface, 'com.mathworks.toolbox.instrument.Instrument');
        interface = localGetValidObject(interface);
        
        % get the class name of the object as the interface log string
        interfaceLogStr = convertCharsToStrings(class(interface));
    elseif iscell(interface)
        constructor = interface{1};
        instrfindArgs = interface{2};
        obj = eval(['instrfind' instrfindArgs]);
        if ~isempty(obj)
            fclose(obj);
            interface = obj(1);
        else
            obj = eval(constructor);
        end
    else
        interface = char(interface);
        % interface value is char - get the string from char as the usage
        % log string
        interfaceLogStr = convertCharsToStrings(interface);
    end
    
    % Call the device object constructor with the correct arguments based
    % on what the user entered in the dialog.
    if isempty(interface)
        logger.logTmToolHardwareUsage('interfaceObj', "", 'deviceObj', driverLogStr, 'IviClassDriver', "")
        obj = icdevice(driverName);
    else
        logger.logTmToolHardwareUsage('interfaceObj', interfaceLogStr, 'deviceObj', driverLogStr , 'IviClassDriver', "")
        obj = icdevice(driverName, interface);
    end
    
    % Get needed output arguments for GUI.
    out = createdObject(obj);    
end



% ------------------------------------------------------------------------
% Create the output arguments needed by instrcreate after an object
% has been created.
function out = createdObject(obj)

out = {obj.Type, obj, obj.Name, java(igetfield(obj, 'jobject'))};

% ------------------------------------------------------------------------
% Get the MATLAB OOPs object for the java instrument object.
function out = localGetValidObject(instr)

objs = instrfindall;
for i = 1:length(objs)
    obj = objs(i);
    jobj = java(igetfield(obj, 'jobject'));
    if (jobj == instr)
        out = obj;
        return;
    end
end    

% ------------------------------------------------------------------------
% Parse the input string for the remoteport.  This is to workaround
% the fact that STR2DOUBLE('') is NaN.  This should return [] if the input
% is empty and NaN or a number as appropriate otherwise.
function remoteport = specifyRemotePort(inputString)

if isempty(inputString)
    remoteport = [];
else
    remoteport = str2double(inputString);
end
