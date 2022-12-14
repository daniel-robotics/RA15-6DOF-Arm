function instrcallback(obj, event)
%INSTRCALLBACK Display event information for the event.
%
%   INSTRCALLBACK(OBJ, EVENT) displays a message which contains the 
%   type of the event, the time of the event and the name of the
%   object which caused the event to occur.  
%
%   If an error event occurs, the error message is also displayed.  
%   If a pin event occurs, the pin that changed value and the pin value
%   is also displayed. If a trigger event occurs, the trigger line
%   is also displayed. If a datagram is received the datagram host 
%   address, port and length are also displayed. If a confirmation
%   event occurs, the property configured and the actual property value
%   are also displayed.
%
%   INSTRCALLBACK is an example callback function. Use this callback 
%   function as a template for writing your own callback function.
%
%   Example:
%       s = serial('COM1');
%       set(s, 'OutputEmptyFcn', {'instrcallback'});
%       fopen(s);
%       fprintf(s, '*IDN?', 'async');
%       idn = fscanf(s);
%       fclose(s);
%       delete(s);
%
%   See also INSTRHELP.
%

%   MP 11-20-00
%   Copyright 1999-2011 The MathWorks, Inc. 


% Define error message.

switch nargin
case 0
   error(message('instrument:instrcallback:invalidSyntaxArgv'));
case 1
   error(message('instrument:instrcallback:invalidSyntax'));
case 2
   if ~isa(obj, 'icgroup') || ~isa(event, 'struct')
      error(message('instrument:instrcallback:invalidSyntax'));
   end   
   if ~(isfield(event, 'Type') && isfield(event, 'Data'))
      error(message('instrument:instrcallback:invalidSyntax'));
   end
end  

% Determine the type of event.
EventType = event.Type;

% Determine the time of the error event.
EventData = event.Data;
EventDataTime = EventData.AbsTime;
   
% Create a display indicating the type of event, the time of the event and
% the name of the object.
name = get(obj, 'Name');
fprintf([EventType ' event occurred at ' datestr(EventDataTime,13),...
	' for the object: ' name '.\n']);

% Display the configured value information.
if strcmp(lower(EventType), 'confirmation')
    fprintf([EventData.PropertyName ' was configured to ' num2str(EventData.ConfiguredValue) '.\n']);
end
