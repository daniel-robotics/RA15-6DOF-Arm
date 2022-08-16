function obj = isetfield(obj, field, value)
%ISETFIELD Set instrument object internal fields.
%
%   OBJ = ISETFIELD(OBJ, FIELD, VAL) sets the value of OBJ's FIELD 
%   to VAL.
%
%   This function is a helper function for the concatenation and
%   manipulation of instrument object arrays. This function should
%   not be used directly by users.
%

%   MP 7-13-99
%   Copyright 1999-2011 The MathWorks, Inc. 

% Assign the specified field information.
try
    obj.(field) = value;
catch
   error(message('instrument:isetfield:invalidFIELD', field));
end
