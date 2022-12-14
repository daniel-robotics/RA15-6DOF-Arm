function out = instrid(cmd)
%INSTRID Define and retrieve commands used to identify instruments.
%
%   INSTRID('CMD') defines instrument command, CMD, to be used when
%   identifying instruments. CMD can be a cell array of commands.
%
%   The Instrument Control Toolbox INSTRHWINFO and TMTOOL functions use
%   the instrument identification commands as defined by INSTRID when
%   locating and identifying instruments.
%
%   By default, the command *IDN? is used to identify instruments.
%   Most instruments are identified with *IDN?. However, some instruments
%   respond to different identification commands such as *ID? or *IDEN?. 
%
%   If INSTRHWINFO and TMTOOL are not finding a known instrument, INSTRID
%   should be used to specify the identification commands that the known
%   instrument responds to.
%
%   Note, if INSTRID returns no commands, an instrument cannot be identified.
%
%   OUT = INSTRID returns the instrument commands used for identification
%   to OUT.
%
%   Example:
%       instrid('*ID?');
%       instrid({'*IDN?', '*ID?', '*IDEN?'});
%       cmd = instrid;
%

%   Copyright 1999-2016 The MathWorks, Inc. 

import java.util.Vector;

if (nargin == 0)
    % Syntax: instrid.
    % Return the instrument identification commands.
    out = {};
    commands = com.mathworks.toolbox.instrument.Instrument.getScanCommands;
    
    % Convert vector to string array.
    for i = 1:commands.size
        out{i} = char(commands.elementAt(i-1));
    end
    
    % If only one argument, don't pass back as a cell.
    if length(out) == 1
        out = out{:};
    end
    return;
end

% convert to char in order to accept string datatype
cmd = instrument.internal.stringConversionHelpers.str2char(cmd);

% Error checking.
if ~(ischar(cmd) || iscellstr(cmd))
    error(message('instrument:instrid:invalidArgs'));
end

% Syntax: instrid(cmd);
if ~iscell(cmd)
    cmd = {cmd};
end

% Convert string array ot vector;
commands = Vector;
for i = 1:length(cmd)
    commands.addElement(cmd{i});
end

% Configure commands.
com.mathworks.toolbox.instrument.Instrument.setScanCommands(commands);

% Assign output if neeeded.
if (nargout == 1)
    out = cmd;
end