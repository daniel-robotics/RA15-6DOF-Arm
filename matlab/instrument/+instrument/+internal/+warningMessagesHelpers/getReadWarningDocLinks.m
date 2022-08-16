function [docIDNoDataRef, docIDSomeDataRef] = getReadWarningDocLinks(objectClass, visaType)

%GETREADWARNINGDOCLINKS handles the warning messages that may arise when communication with a device using ICT.

% A=GETREADWARNINGDOCLINKS(OBJECTCLASS, VISATYPE) Takes in the object class 
% (serial, serialport, gpib, tcpip, visa, udp) char
% array OBJECTCLASS.
% VISATYPE is a char array that holds the visa type (like visa-serial, visa-usb, etc).
% Calling this helper function returns the appropriate document links corresponding to the
% warnings.

%   Copyright 2017-2019 The MathWorks, Inc.

docIDNoData = '';
docIDSomeData = '';
docIDNoDataRef = '';
docIDSomeDataRef = '';
isVisa = false;
if strcmpi(objectClass, 'visa')
    isVisa = true;
    linkTag = 'VISA Read Warnings';
    switch visaType

        % We treat visa-serial similar to serial
        case 'visa-serial'
            objectClass = 'serial';

            % We treat visa-gpib, tcpip and usb similar to gpib
        case {'visa-gpib', 'visa-tcpip', 'visa-usb'}
            objectClass = 'gpib';

        case 'visa-generic'
            docIDNoData = 'tcpsocket_nodata';
            docIDSomeData = 'tcpsocket_somedata';
            objectClass = 'visa';

        otherwise
            objectClass = 'visa';
    end
end
switch lower(objectClass)
    case 'serialport'
        linkTag = 'serialport Read Warnings';
        % Binary/ASCII/BinBlock
        docIDNoData = 'serialport_nodata';
        % Only Binary
        docIDSomeData = 'serialport_somedata';
    case 'serial'
        if ~isVisa
            linkTag = 'Serial Read Warnings';
        end
        % Binary/ASCII/BinBlock
            docIDNoData = 'serial_nodata';
            docIDSomeData = 'serial_somedata';

    case 'bluetooth'
        if ~isVisa
            linkTag = 'Bluetooth Read Warnings';
        end

        % Binary/ASCII/BinBlock
            docIDNoData = 'bt_nodata';
            docIDSomeData = 'bt_somedata';

    case 'udp'
        if ~isVisa
            linkTag = 'UDP Read Warnings';
        end

        % Binary/ASCII/BinBlock
            docIDNoData = 'udp_nodata';
            docIDSomeData = 'udp_somedata';

    case 'tcpip'
        if ~isVisa
            linkTag = 'TCPIP Read Warnings';
        end
        % Binary/ASCII/BinBlock
            docIDNoData = 'tcpip_nodata';
            docIDSomeData = 'tcpip_somedata';

    case 'gpib'
        if ~isVisa
            linkTag = 'GPIB Read Warnings';
        end
        % Binary/ASCII/BinBlock
            docIDNoData = 'gpib_nodata';
            docIDSomeData = 'gpib_somedata';

end

if ~isempty(docIDNoData) && ~isempty(docIDSomeData)
    docIDMapLoc = 'matlab: helpview(fullfile(docroot,''instrument'',''instrument.map''), ';
    noDataHV = [docIDMapLoc '''' docIDNoData '''' ')'];
    someDataHV = [docIDMapLoc '''' docIDSomeData '''' ')'];
    docIDNoDataRef = ['<a href=' '"' noDataHV '"' '>' linkTag '</a>'];
    docIDSomeDataRef = ['<a href=' '"' someDataHV '"''>' linkTag '</a>'];
end
end