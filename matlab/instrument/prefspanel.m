function prefspanel
%PREFSPANEL Registers an Instrument Control preferences control panel.
% 
%   PREFSPANEL registers a Preferences Control panel for object's in the Instrument
%   Control Toolbox with the MATLAB IDE.
%

%   Copyright 1999-2012 The MathWorks, Inc.

% Register Object-based context menus items in the Workspace Browser.

%   Methods of MatlabObjectMenuRegistry are unsupported.  Calls to these
%   methods will become errors in future releases.

% Redefine Serial Port Context menu (note that this replaces the one defined
% in matlab\toolbox\matlab\iofun\@serial\prefspanel.m)
contextMenuCallbackCategory = getString(message('instrument:prefspanel:contextMenuCallbackCategory'));
displaySummaryMenuItem = getString(message('instrument:prefspanel:displaySummaryMenuItem'));
propertyInspectorMenuItem = getString(message('instrument:prefspanel:propertyInspectorMenuItem'));
instrumentHelpMenuItem = getString(message('instrument:prefspanel:instrumentHelpMenuItem'));
displayHWInfoMenuItem = getString(message('instrument:prefspanel:displayHWInfoMenuItem'));
com.mathworks.mlwidgets.workspace.MatlabCustomClassRegistry.registerClassCallbacks(...
    {'serial'},...
    contextMenuCallbackCategory,...
    {displaySummaryMenuItem, ...
	propertyInspectorMenuItem,...
	'-',...
	displayHWInfoMenuItem, ...
	'-', ...
	instrumentHelpMenuItem},...
    {'disp($1)', ...
	'inspect($1);', ...
	'',...
	'instrhwinfo($1); disp(ans)',...
	'-',...
	'instrhelp($1)'});

% Define icinterface, device and output objects - same as serial port.
com.mathworks.mlwidgets.workspace.MatlabCustomClassRegistry.registerSimilarClassCallbacks(...
    {'gpib', 'visa', 'tcpip', 'udp', 'icdevice'}, 'serial');

% Define Instrument Context menu
com.mathworks.mlwidgets.workspace.MatlabCustomClassRegistry.registerClassCallbacks(...
    {'instrument'},...
    contextMenuCallbackCategory,...
    {displaySummaryMenuItem, ...
	propertyInspectorMenuItem,...
	'-',...
	instrumentHelpMenuItem},...
    {'display($1)', ...
	'inspect($1);', ...
	'',...
	'help instrument\Contents'});

% Define output object array - same as instrument.
com.mathworks.mlwidgets.workspace.MatlabCustomClassRegistry.registerSimilarClassCallbacks({'icgroup'}, 'instrument');

% If we're on a PC, and IVI shared components are installed, and the [IVI
% INSTALL]/Components/MATLAB directory exists, then add it to the path.
% NOTE:  This must be done WITHOUT using any ICT licensed files, because
% this happens every time MATLAB starts, and we do not want to check out a
% license.
try
    if ispc
        driverpath = winqueryreg('HKEY_LOCAL_MACHINE', 'SOFTWARE\IVI\', 'IVIStandardRootDir');
        if ~isempty(driverpath)
            driverpath = fullfile(driverpath,'Components','MATLAB');
            if exist(driverpath,'dir')
                addpath(driverpath)
            end
        end
    end
catch e %#ok<NASGU>
    % Ignore failures
end
% LocalWords:  iofun IVI ICT