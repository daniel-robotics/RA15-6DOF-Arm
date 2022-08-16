function p = privateGetVXIPNPPath
%PRIVATEGETVXIPNPPATH Find the VXI plug&play installation directory.
%
%   PRIVATEGETVXIPNPPATH finds the VXI plug&play installation directory
%   to allow access to the drivers and function panels.
%
%   This is a helper function used by functions in the Instrument
%   Control Toolbox. This function should not be called directly
%   by users.

%   PE 06-23-03
%   Copyright 1999-2012 The MathWorks, Inc.


vxipnppath=[];
if isempty(vxipnppath)
    rootPath = localFindPath;
    
    if (~isempty(rootPath))
        vxipnppath = fullfile(rootPath, localFindFramework);
    else
        vxipnppath = '';
    end
end

p = vxipnppath;

% -------------------------------------------------------------------
% Find the root installation path.
function p = localFindPath

% See the VPP-6 VXI plug-n-play spec for the logic below.
if (ispc)
    p = getenv('VPNPPATH');

    if (isempty(p))
        try
            p = winqueryreg('HKEY_LOCAL_MACHINE', 'SOFTWARE\VXIPNP_Alliance\VXIPNP\CurrentVersion', 'VXIPNPPATH');
        catch %#ok<CTCH>
            if (exist('C:\VXIPNP','dir'))
                p = 'C:\VXIPNP';
            else
                p = '';
            end
        end
    end
else
    p = getenv('VXIPNPPATH');
    if (isempty(p))
        p = '';
    end
end

% -------------------------------------------------------------------
% Find the framework name for this os type.
function p = localFindFramework

import java.lang.System;

p = '';
os = System.getProperty('os.name');

if (os.startsWith('Window'))
    if strcmpi(computer, 'PCWIN64') %  64 bit
        p = 'Win64';
    elseif strcmpi(computer, 'PCWIN') % 32 bit
        p = 'WINNT';
    end
end


 