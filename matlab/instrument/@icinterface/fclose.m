function fclose(obj)
%FCLOSE Disconnect interface object from instrument.
%
%   FCLOSE(OBJ) disconnects the interface object, OBJ, from the
%   instrument. OBJ can be an array of interface objects.
%
%   If OBJ was successfully disconnected from the instrument, OBJ's
%   Status property is configured to closed and the RecordStatus
%   property is configured to off. OBJ can be reconnected to the
%   instrument with the FOPEN function.
%
%   You cannot disconnect an object while data is being written
%   asynchronously to the instrument. The STOPASYNC function can be
%   used to stop an asynchronous write.
%
%   If OBJ is an array of interface objects and one of the objects
%   cannot be disconnected from the instrument, the remaining objects
%   in the array will be disconnected from the instrument and a warning
%   will be displayed.
%
%   Example:
%       g = gpib('ni', 0, 2);
%       fopen(g)
%       fprintf(g, '*IDN?');
%       idn = fscanf(g);
%       fclose(g);
%
%   See also ICINTERFACE/FOPEN, ICINTERFACE/STOPASYNC, INSTRUMENT/PROPINFO,
%   INSTRHELP.
%

%   MP 7-13-99
%   Copyright 1999-2011 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2011/05/13 18:05:41 $

% Initialize variables.
errorOccurred = false;
jobject = igetfield(obj, 'jobject');

% Call fclose on each java object.  Keep looping even
% if one of the objects could not be closed.
for i=1:length(jobject),
    try
        fclose(jobject(i));
    catch aException
        errorOccurred = true;
        errmsg = aException.message;
    end
end

% Report error if one occurred.
if errorOccurred
    if length(jobject) == 1
        error(message('instrument:fclose:opfailed', errmsg));
    else
        warnState = warning('backtrace', 'off');
        warning(message('instrument:fclose:invalid'));
        warning(warnState);
    end
end

