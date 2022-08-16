function varargout = resolvehost(varargin)
%RESOLVEHOST Return the name and address of the host.
%
%   NAME = RESOLVEHOST('HOST') returns the name of host, HOST.
%
%   [NAME, ADDRESS] = RESOLVEHOST('HOST') returns the address of host, HOST,
%   in addition to the HOST'S name. HOST can be either the network name or
%   address of the host. If HOST is not a valid network host, NAME and ADDRESS
%   return as empty strings.
%  
%   For example, 'www.mathworks.com' is a network name and '144.212.100.10' 
%   is a network address.
%
%   OUT = RESOLVEHOST('HOST','RETURNTYPE') returns the host name if RETURNTYPE 
%   is 'name' and returns the host address if RETURNTYPE is 'address'. By default,
%   RETURNTYPE is 'name'.
%
%   Example:
%       [name,address] = resolvehost('144.212.100.10')
%       name = resolvehost('144.212.100.10','name')
%       address = resolvehost('www.mathworks.com','address')
%
%   See also TCPIP, UDP.

%   Copyright 1999-2016 The MathWorks, Inc.

% Error if java is not running.
if ~usejava('jvm')
    error(message('instrument:resolvehost:nojvm'));
end

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

if (nargout > 2)
    error(message('instrument:resolvehost:invalidSyntaxRetv'));
end

switch nargin
case 0
    error(message('instrument:resolvehost:invalidSyntaxHost'));
case 1
    host = lower(varargin{1});
    if (~ischar(host) )
        error(message('instrument:resolvehost:invalidSyntaxHostString'));
    end
    
    list='both';
case 2
    host = lower(varargin{1});
    if (~ischar(host) )
        error(message('instrument:resolvehost:invalidSyntaxHostString'));
    end
    
    list = lower(varargin{2});
    if ( ~ischar(list) || (~ischar(list) && isempty(list)) )
        error(message('instrument:resolvehost:invalidSyntaxFlagString'));
    elseif (~strcmp(list, {'name' 'address'} ))
        error(message('instrument:resolvehost:invalidSyntaxFlag'));
    end
otherwise
    error(message('instrument:resolvehost:invalidSyntaxArgv'));
end

if (~localVerifyIPAddress(host))
    varargout{1}='';
    varargout{2}='';
    return
end

% Create the output structure.
try
    varargout = cell(com.mathworks.toolbox.instrument.TCPIP.resolveHost(host,list));
catch aException
    newExc = MException('instrument:resolvehost:opfailed', aException.message);
    throw (newExc);
end

%--------------------------------------------------------------------------
% Display warning if host is bad IP address. Valid IPs are x.x.x.x where x=0-255
function flag = localVerifyIPAddress(host)

flag = false;

% Return if it's empty string
if isempty(strtrim(host))
    return;
end

% Parse the string x.x.x.x into four numbers.
outCell = regexp(host,'\.','split');
out = cellfun(@(x)str2double(x),outCell);

% Non-numerical IP address
if any(isnan(out))
    flag = true;
    return;
end

if length(out) ~= 4
    return
end
for i=1:4
    if ((out(i) < 0) || (out(i) > 255))
        warnState = warning('backtrace', 'off');
        warning(message('instrument:resolvehost:invalidIPaddress'));
        warning(warnState);
        return
    end
end
flag = true;



