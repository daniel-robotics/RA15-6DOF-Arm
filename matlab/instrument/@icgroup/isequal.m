function out = isequal(varargin)
%ISEQUAL True if device group object arrays are equal.
%
%   ISEQUAL(A,B) is 1 if the two device group object arrays are the
%   same size and are equal, and 0 otherwise.
%
%   ISEQUAL(A,B,C,...) is 1 if all the device group object arrays are
%   the same size and are equal, and 0 otherwise.
% 

%   MP 6-25-02
%   Copyright 1999-2011 The MathWorks, Inc. 

% Error checking.
if nargin == 1
    error(message('instrument:icgroup:isequal:minrhs'));
end

% Loop through all the input arguments and compare to each other.
for i=1:nargin-1
    obj1 = varargin{i};
    obj2 = varargin{i+1};
    
    % Return 0 if either arguments are empty.
    if isempty(obj1) || isempty(obj2)
        out = logical(0);
        return;
    end
    
    % Inputs must be the same size.
    if ~(all(size(obj1) == size(obj2))) 
        out = logical(0);
        return;
    end
    
    % Call @instrument\eq.
    out = eq(obj1, obj2);
    
    % If not equal, return 0 otherwise loop and compare obj2 with 
    % the next object in the list.
    if (all(out) == 0)
        out = logical(0);
        return;
    end
end

% Return just a 1 or 0.  
% Ex. isequal(obj, obj)  where obj = [s s s]
% eq returns [1 1 1] isequal returns 1.
out = all(out);
