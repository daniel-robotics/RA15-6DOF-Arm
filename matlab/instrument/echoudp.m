function echoudp(varargin)
%ECHOUDP start or stop a UDP echo server.
%
%   ECHOUDP('STATE',PORT) starts a UDP server with port number,
%   PORT. STATE can only be 'on'.
%
%   ECHOUDP('STATE') stops the echo server. STATE can only be
%   'off'.
%
%   Example:
%       echoudp('on', 4000);
%       u = udp('localhost', 4000);
%       fopen(u);
%       fprintf(u, 'echo this string.');
%       data = fscanf(u);
%       echoudp('off');
%       fclose(u);
%       delete(u);
%
%   See also ECHOTCPIP, TCPIP, UDP.
%

% Copyright 1999-2016 The MathWorks, Inc.

import com.mathworks.toolbox.instrument.EchoUDP;

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

switch nargin
    case 0
        error(message('instrument:echoudp:invalidSyntaxState'));
    case 1
        if ~ischar(varargin{1})
            error(message('instrument:echoudp:invalidSyntaxBool'));
        end

        % Get the state - on or off.
        state = lower(varargin{1});
        switch (state)
            case 'off'
                echoServer = EchoUDP.getEchoServer;

                % Shut down the echo server.
                if ~isempty(echoServer)
                    echoServer.shutDownServer;
                end
            case 'on'
                error(message('instrument:echoudp:invalidSyntaxPort'));
            otherwise
                error(message('instrument:echoudp:invalidSyntaxBool'));
        end

    case 2
        if ~ischar(varargin{1})
            error(message('instrument:echoudp:invalidSyntaxBool'));
        end

        % Based on the state, turn on or off the echo server.
        switch (lower(varargin{1}))
            case 'on'
                port = varargin{2};
                if (~localIsValidPort(port))
                    error(message('instrument:echoudp:invalidSyntaxPortRange'))
                end

                % Determine if there is already a connection.
                echoServer = EchoUDP.getEchoServer;

                if isempty(echoServer)
                    try
                        com.mathworks.toolbox.instrument.EchoUDP(port);
                    catch AException
                        newExc  = MException('instrument:echoudp:createError',AException.message);
                        throw (newExc );
                    end

                else
                    portNumber = echoServer.getPort;
                    error(message('instrument:echoudp:running', num2str( portNumber )));
                end
            case 'off'
                error(message('instrument:echoudp:invalidSyntax'));
            otherwise
                error(message('instrument:echoudp:invalidSyntaxBool'));
        end
    otherwise
        error(message('instrument:echoudp:invalidSyntaxArgv'))
end

% -------------------------------------------------------------------
% Determine if the specified port is in a valid range.
function out = localIsValidPort(port)

out = true;
if ((numel(port) ~= 1) || ~isnumeric(port) || isempty(port) || (port < 1) || (port > 65535) || (fix(port) ~= port))
    out = false;
    return
end

