function varargout = size(obj,varargin)
%SIZE Size of instrument object array.  
%
%   D = SIZE(OBJ), for M-by-N instrument object, OBJ, returns the 
%   two-element row vector D = [M, N] containing the number of rows
%   and columns in the instrument object array, OBJ.  
%
%   [M,N] = SIZE(OBJ) returns the number of rows and columns in separate
%   output variables.  
%
%   [M1,M2,M3,...,MN] = SIZE(OBJ) returns the length of the first N 
%   dimensions of OBJ.
%
%   M = SIZE(OBJ,DIM) returns the length of the dimension specified by the 
%   scalar DIM. For example, SIZE(OBJ,1) returns the number of rows.
% 
%   See also VISA/LENGTH, INSTRHELP.
%

%   Copyright 1999-2013 The MathWorks, Inc. 

% Error checking.
if (nargin > 1)
    if ~isa(obj, 'instrument')
        error(message('instrument:size:invalidOBJ'));
    elseif ~isnumeric(varargin{1})
        error(message('instrument:size:badopt'));
    end
end

% Determine the number of output arguments.
numOut = nargout;

% Call the builtin size function on the java object.  The jobject field
% of the object indicates the number of objects that are concatenated
% together.
[varargout{1:numOut}] = builtin('size', obj.jobject, varargin{:});
