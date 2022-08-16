function transportObj = GetTransport(transportType, varargin)
    %GetTransport creates internal transport objects. This function is
    %called by a Modbus trasport constructor - tcpip.Modbus or
    %seriartu.Modbus. Inputs to this function are:
    %   1. transportType - 'tcpip' or 'serialrtu'
    %   2. Required paramters to create the corresponding transport obj
   
    % Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    if strcmp(transportType,'tcpip')
        narginchk(3,3);
        transportObj = matlabshared.network.internal.TCPClient(varargin{1},varargin{2});
    elseif strcmp(transportType,'serial')
        narginchk(2,2);
        transportObj = matlabshared.seriallib.internal.Serial(varargin{1});
        connect(transportObj);
    else
        coder.internal.error('instrument:modbus:invalidTransport','tcpip, serial');
    end
end

