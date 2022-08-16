 function varargout = fscanf(obj, varargin)
%FSCANF Read data from instrument and format as text.
%
%   A=FSCANF(OBJ) reads data from the instrument connected to instrument
%   object, OBJ, and formats the data as text and returns to A.
%
%   For serial port, VISA-serial and TCPIP objects, FSCANF blocks
%   until one of the following occurs:
%       1. The terminator is received as specified by the Terminator
%          property.
%       2. A timeout occurs as specified by the Timeout property.
%       3. The input buffer is filled.
%
%   For GPIB, VISA-GPIB, VISA-VXI, VISA-GPIB-VXI, VISA-TCPIP, VISA-USB
%   and VISA-RSIB objects, FSCANF blocks until one of the following occurs:
%       1. The EOI line is asserted.
%       2. The terminator is received as specified by the EOSCharCode
%          property (if defined). This option is not available for
%          VISA-RSIB objects.
%       3. A timeout occurs as specified by the Timeout property.
%       4. The input buffer is filled.
%
%   For UDP objects, FSCANF blocks until one of the following occurs:
%       1. The terminator is received as specified by the terminator
%          property (if DatagramTerminateMode is off).
%       2. A datagram has been received (if DatagramTerminateMode is on).
%       3. A timeout occurs as specified by the Timeout property.
%
%   The interface object must be connected to the instrument with the
%   FOPEN function before any data can be read from the instrument
%   otherwise an error is returned. A connected interface object has
%   a Status property value of open.
%
%   For GPIB, VISA-GPIB, VISA-VXI, VISA-GPIB-VXI, VISA-TCPIP and VISA-USB
%   objects, the terminator is defined by setting OBJ's EOSMode property to
%   read or read&write and setting OBJ's EOSCharCode property to the ASCII
%   code for the character received. For example, if the EOSMode property
%   is set to read and the EOSCharCode property is set to LF, then one of
%   the ways that the read terminates is when the linefeed character
%   is received. A terminator cannot be defined for VISA-RSIB objects.
%
%   A=FSCANF(OBJ,'FORMAT') reads data from the instrument connected to
%   interface object, OBJ, and converts it according to the specified
%   FORMAT string. By default, the %c FORMAT string is used. The SSCANF
%   function is used to format the data read from the instrument.
%
%   FORMAT is a string containing C language conversion specifications.
%   Conversion specifications involve the character % and the conversion
%   characters d, i, o, u, x, X, f, e, E, g, G, c, and s. Refer to the 
%	SSCANF format specification section for more details.
%
%   A=FSCANF(OBJ,'FORMAT',SIZE) reads the specified number of values,
%   SIZE, from the instrument connected to interface object, OBJ.
%
%   For serial port, VISA-serial and TCPIP objects, FSCANF blocks
%   until one of the following occurs:
%       1. The terminator is received as specified by the Terminator
%          property.
%       2. A timeout occurs as specified by the Timeout property.
%       3. SIZE values have been received.
%
%   For GPIB, VISA-GPIB, VISA-VXI, VISA-GPIB-VXI, VISA-TCPIP, VISA-USB
%   and VISA-RSIB objects, FSCANF blocks until one of the following occurs:
%       1. The EOI line is asserted.
%       2. The terminator is received as specified by the EOSCharCode
%          property (if defined). This option is not available for
%          VISA-RSIB objects.
%       3. A timeout occurs as specified by the Timeout property.
%       4. SIZE values have been received.
%
%   For UDP objects, FSCANF blocks until one of the following occurs:
%       1. SIZE values have been received (if DatagramTerminateMode
%          if off).
%       2. The terminator is received as specified by the Terminator
%          property (if DatagramTerminateMode is off).
%       3. A datagram has been received (if DatagramTerminateMode
%          is on).
%       4. A timeout occurs as specified by the Timeout property.
%
%   Available options for SIZE include:
%
%      N      read at most N values into a column vector.
%      [M,N]  read at most M * N values filling an M-by-N
%             matrix, in column order.
%
%   SIZE cannot be set to INF. If SIZE is greater than OBJ's
%   InputBufferSize property value an error will be returned.
%
%   If the matrix A results from using character conversions only and
%   SIZE is not of the form [M,N] then a row vector is returned.
%
%   [A,COUNT]=FSCANF(OBJ,...) returns the number of values read to COUNT.
%
%   [A,COUNT,MSG]=FSCANF(OBJ,...) returns a message, MSG, if FSCANF
%   did not complete successfully. If MSG is not specified a warning is
%   displayed to the command line.
%
%   [A,COUNT,MSG,DATAGRAMADDRESS]=FSCANF(OBJ,...) returns the datagram
%   address to DATAGRAMADDRESS, if OBJ is a UDP object. If more than
%   one datagram is read, DATAGRAMADDRESS is ''.
%
%   [A,COUNT,MSG,DATAGRAMADDRESS,DATAGRAMPORT]=FSCANF(OBJ,...) returns
%   the datagram port to DATAGRAMPORT, if OBJ is a UDP object. If more
%   than one datagram is read, DATAGRAMPORT is [].
%
%   OBJ's ValuesReceived property will be updated by the number of values
%   read from the instrument including the terminator.
%
%   If OBJ's RecordStatus property is configured to on with the RECORD
%   function, the data received will be recorded in the file specified
%   by OBJ's RecordName property value.
%
%   Examples:
%       s = visa('ni', 'ASRL1::INSTR');
%       fopen(s);
%       fprintf(s, '*IDN?');
%       idn = fscanf(s);
%       fclose(s);
%       delete(s);
%
%   See also ICINTERFACE/FOPEN, ICINTERFACE/FGETL, ICINTERFACE/FGETS,
%   ICINTERFACE/FREAD, ICINTERFACE/SCANSTR, ICINTERFACE/RECORD,
%   INSTRUMENT/PROPINFO, INSTRHELP, STRREAD, SSCANF.

%   Copyright 1999-2017 The MathWorks, Inc.

% Error checking.
if nargout > 5
    error(message('instrument:fscanf:invalidSyntaxRet'));
end

if ~isa(obj, 'icinterface')
    error(message('instrument:fscanf:invalidOBJInterface'));
end

if length(obj)>1
    error(message('instrument:fscanf:invalidOBJDim'));
end

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

% Parse the input.
switch nargin
    case 1
        % Ex. fscanf(obj);
        format = '%c';
        size = 0;
    case 2
        % Ex. fscanf(obj, '%d');
        format = varargin{1};
        size = 0;
    case 3
        % Ex. fscanf(obj, '%d', 10);
        [format, size] = deal(varargin{1:2});
        if ~isa(size, 'double')
            error(message('instrument:fscanf:invalidSIZEdouble'));
        elseif size < 1
            error(message('instrument:fscanf:invalidSIZEpos'));
        end
    otherwise
        error(message('instrument:fscanf:invalidSyntaxArgv'));
end

% Error checking.
if ~ischar(format)
    error(message('instrument:fscanf:invalidFORMATstring'));
elseif ~isa(size, 'double')
    error(message('instrument:fscanf:invalidSIZEdouble'));
elseif any(isinf(size))
    error(message('instrument:fscanf:invalidSIZEinf'));
elseif any(isnan(size))
    error(message('instrument:fscanf:invalidSIZEnan'));
end

% Floor the size.
% Note: The call to floor must be done after the error checking
% since floor on a string converts the string to its ascii value.
size = floor(size);

% Determine the total number of elements to read.
switch length(size)
    case 1
        if size ~= 0
            totalSize = size;
        else
            totalSize = inf;
        end
    case 2
        totalSize = size(1)*size(2);
        if totalSize < 1
            error(message('instrument:fscanf:invalidSIZEpos'));
        end
    otherwise
        error(message('instrument:fscanf:invalidSIZE'));
end

% Call the fscanf java method.
try
    if length(size) == 1 && size ~= 0 && strcmp(format, '%c')
        out = fscanf(igetfield(obj, 'jobject'), totalSize);
    else
        out = fscanf(igetfield(obj, 'jobject'), 0);
    end
catch aException
    newExc = MException('instrument:fscanf:opfailed',aException.message);
    throw(newExc);
end

% Parse the output.
fscanfData = out(1);
fscanfCount = out(2);
fscanfErrMsg = out(3);
datagramAddress = out(4);
datagramPort    = out(5);

% Format the result and return.
try
    if ~isinf(totalSize) && totalSize > 0
        [sscanfData, sscanfCount, sscanfErrMsg] = sscanf(fscanfData, format, size);
    else
        [sscanfData, sscanfCount, sscanfErrMsg] = sscanf(fscanfData, format);
    end

    % sscanf errored (as third output argument). If sscanf returned nothing, return
    % the unformatted data, the number of values read and sscanf's third output argument
    % otherwise return the result of sscanf along with the number of values read and
    % the third output argument.

    sscanfSuccessful = isempty(sscanfErrMsg);

    if sscanfSuccessful
        outputData = sscanfData;
        outputCount = sscanfCount;
        outputMessage = fscanfErrMsg;
    else
        sscanfErrMsg = [sscanfErrMsg, ' ' getString(message('instrument:fscanf:invalidFormat', format))];

        % If sscanf returns no data, use the data received from fscanf instead.
        if isempty(sscanfData)
            outputData = fscanfData;
            outputCount = fscanfCount;
        else
            outputData = sscanfData;
            outputCount = sscanfCount;
        end
        outputMessage = sscanfErrMsg;
    end
    
    % If we do have some error Message, show the message
    if ~isempty(outputMessage)
        % Store the warning state.
        warnState = warning('backtrace', 'off');

        % If sscanfSuccessful, that means that fscanf must've given an error
        % as outputMessage is not empty.
        if sscanfSuccessful
            if ~isempty(outputData)
                outputMessage = instrument.internal.warningMessagesHelpers.getReadWarning(outputMessage, obj.class, obj.DocIDSomeData, 'somedata');
            else
                outputMessage = instrument.internal.warningMessagesHelpers.getReadWarning(outputMessage, obj.class, obj.DocIDNoData, 'nodata');
            end

            % Prepare the warning message
            dispWarning = message('instrument:fscanf:unsuccessfulRead', outputMessage);
        else

            % Prepare the warning message
            outputMessage = sscanfErrMsg;
            dispWarning = sscanfErrMsg;
        end

        if nargout < 3
            warning(dispWarning);
        end
        % Restore the warning state.
        warning(warnState);
    end

    varargout = {outputData, outputCount, outputMessage, datagramAddress, datagramPort};
catch aException
    % An error occurred while formatting the data.  Return the
    % unformatted data, the number of values reaad and the error
    % from sscanf (errmsg).
    varargout = {fscanfData, fscanfCount, aException.message, datagramAddress, datagramPort};
end


