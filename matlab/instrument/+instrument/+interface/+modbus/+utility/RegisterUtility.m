classdef RegisterUtility < handle
% REGISTERUTILITY takes modbus register data to give the minimum number of
% reads that would take to read all of the modbus addresses.
% The input 'RegisterStruct' needs to be a struct with the following
% fields - 'Address', 'RegisterType', 'Precision', 'Index'.
% E.g.
% registerUtility = instrument.interface.modbus.utility.RegisterUtility(registerStruct)
% where,
% registerStruct =
%
%   struct with fields:
%
%          Address: {7×1 cell}
%     RegisterType: {7×1 cell}
%        Precision: {7×1 cell}
%            Index: {7×1 cell}
% registerStruct.Address = {40006; 40004; 40002; 40010; 39999; 40050; 40052}
% registerStruct.RegisterType = {'Holding Register'; 'Holding Register'; 'Coil'; 'Holding Register'; ...
%                                'Holding Register'; 'Coil'; 'Coil'}
% registerStruct.Precision = {'double'; 'int32'; 'bit'; 'uint32'; 'uint16'; 'bit'; 'bit'}
% registerStruct.Index = { 1; 2; 3; 4; 5; 6; 7}

%   Copyright 2018 The MathWorks, Inc.

    properties
        % This is the struct containing the register data fields -
        % 'Address', 'RegisterType', 'Precision', and 'Index'.
        RegisterStruct
    end

    properties(Access = private, Constant)
        % The header Index for the modbus register data. It helps in aligning
        % the register fields - Index, RegisterType, Address and Precision
        % when forming the cell array of the register fields from a struct.
        ColumnName = struct('Index', 1, 'RegisterType', 2, 'Address',  3, ...
            'Precision', 4)
    end

    methods
        function obj = RegisterUtility(registerStruct)
            % MODBUSUTILITY constructor. Assign the valid register Struct.
            try
                narginchk(1, 1);
                obj.RegisterStruct = registerStruct;
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.RegisterStruct(obj, registerStruct)
            % Setter for the Class Property - RegisterStruct. Before assigning
            % obj.RegisterStruct, validate the value to be set.
            try
                registerStruct = ...
                    obj.validateAndAlignRegisterStruct(registerStruct);
                obj.RegisterStruct = registerStruct;
            catch ex
                throwAsCaller(ex);
            end
        end

        function readArguments = getReadArguments(obj)

            % getReadArguments returns the struct which contains minimum number of read
            % statements required for each register type.
            %
            % Syntax: readArguments = getReadArguments(obj)
            %
            % Output: Struct with fields - Coils, Inputs, Holdingregs, Inputregs
            %         readArgument.(fields) is a struct of Index, Count,
            %         Precision and Starting Address.
            %
            % E.g:
            % registerStruct.Address = {40006; 40004; 40002; 40010; 39999; 40050; 40052}
            % registerStruct.RegisterType = {'Holding Register'; 'Holding Register'; 'Coil'; 'Holding Register'; ...
            %                                'Holding Register'; 'Coil'; 'Coil'}
            % registerStruct.Precision = {'double'; 'int32'; 'bit'; 'uint32'; 'uint16'; 'bit'; 'bit'}
            % registerStruct.Index = { 1; 2; 3; 4; 5; 6; 7}
            %
            % registerUtility = instrument.interface.modbus.utility.RegisterUtility(registerStruct)
            % readArguments = getReadArguments(registerUtility)
            %
            % readArguments =
            %
            %             struct with fields:
            %
            %             Coils: [1×1 struct]
            %             Holdingregs: [1×1 struct]
            %             Inputs: []
            %             Inputregs: []
            %
            % readArguments.Holdingregs
            %
            %   struct with fields:
            %
            %               Index: {[5]  [2 1 4]}
            %           Precision: {["uint16"]  ["int32"    "double"    "uint32"]}
            %               Count: {[1]  [1 1 1]}
            %     StartingAddress: {[39999]  [40004]}
            %
            % Starting at address '39999', do a read for register type 'Holdingregs'
            % which contains "uint16" data and '1' contiguous register can be
            % read. This address corresponds to the Index '5' of the
            % registerStruct.address array.
            % We need to have an Index list for the data coming in so that we can
            % map the registers to their respective rows in the table.
            try
                indexList = obj.RegisterStruct.Index;
                address = obj.RegisterStruct.Address;
                precision = obj.RegisterStruct.Precision;
                regType = obj.RegisterStruct.RegisterType;

                % Create a cell array of Index, address, regtypes and
                % Precision.
                cellarr = horzcat(indexList, regType, address, precision);

                % Sort the table contents
                cellarr = sortrows(cellarr, obj.ColumnName.Address);

                % Get the minimum number of reads
                readArguments = obj.returnReadParams(cellarr);
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    methods(Access = private)

        function readArgs = returnReadParams(obj, cellarr)
            try
                readArgs = [];
                if ~isempty(cellarr)

                    % Initialize the readArgs struct
                    readArgs.Coils = [];
                    readArgs.Holdingregs = [];
                    readArgs.Inputs = [];
                    readArgs.Inputregs = [];

                    % The register type is in a user readable format, like 'Holding
                    % Register', 'Coil', 'Input Register' and 'Input'. This function
                    % will give us the corresponding name for the output struct
                    % 'readArgs' like readArgs.Coils and readArgs.Holdingregs, etc.
                    currentRegisterName = obj.getRegisterName ...
                        (cellarr{1, obj.ColumnName.RegisterType});

                    % We need to keep different Index pointer for different register
                    % type.
                    % registerCount.(currentRegisterName) will give the corresponding
                    % Index pointer value for currentRegisterName.
                    % E.g. When currentRegisterName is 'Coils', registerCount.Coils
                    % will give 1, meaning, we are now pointing to the 1st position of
                    % the register type 'Coils'.
                    registerIndexPointer = struct('Coils', 1, 'Inputs', 1, 'Holdingregs', 1, ...
                        'Inputregs', 1);

                    % Extract the first row details.
                    % Start creating the outputStruct readArgs

                    % The table is sorted by address now.
                    % Put the Index of the first table row into
                    % readArgs.<registerType>. Because this is the first Index value
                    % being added, it is added to the first Count position for
                    % <registerType>, denoted by registerCount.(currentRegisterName).
                    % registerCount.(currentRegisterName) is the Index pointer in the readArgs
                    % for the particular <'registerType'>
                    readArgs.(currentRegisterName).Index{registerIndexPointer.(currentRegisterName)} = ...
                        cellarr{1, obj.ColumnName.Index};

                    % Similarly, add the top most Precision value into its correspoding
                    % readArgs.<registerType> and add it to the
                    % registerCount.(currentRegisterName) position.
                    readArgs.(currentRegisterName).Precision{registerIndexPointer.(currentRegisterName)} = ...
                        string(cellarr{1, obj.ColumnName.Precision});

                    % Add the Count for the particular register type to be 1.
                    readArgs.(currentRegisterName).Count{registerIndexPointer.(currentRegisterName)} = 1;

                    % Add the first address
                    address = cell2mat(cellarr(:, obj.ColumnName.Address));
                    readArgs.(currentRegisterName).StartingAddress{registerIndexPointer.(currentRegisterName)} = ...
                        address(1);

                    % Keeps Count of the consecutive registers for the same register type
                    countNum = 1;

                    % Iterate through every address value, to calculate the minimum number of
                    % reads required to read all the table register data.
                    for currentTableRowNumber = 1 : size(cellarr, 1) - 1

                        % Get the register type of the current row.
                        currentRegisterName = obj.getRegisterName(cellarr{currentTableRowNumber, obj.ColumnName.RegisterType});

                        % Get the register type of the next row in the table
                        nextRegisterName = obj.getRegisterName(cellarr{currentTableRowNumber+1, obj.ColumnName.RegisterType});

                        % Get the number of registers needed to store the 'Precision of
                        % data' for the current row
                        unit = obj.getPrecisionSize(cellarr{currentTableRowNumber, obj.ColumnName.Precision});

                        % If the current address, added to the number of registers it
                        % needs to store its data type (like double, uint16, etc)
                        % exceeeds the address of the next row, it means that there is
                        % an overlapping of register addresses. This is an error.
                        if address(currentTableRowNumber) + unit > address(currentTableRowNumber+1)
                            throwAsCaller(MException(message('instrument:modbusutility:overlappingRegisters')));
                        end

                        % If the current address, added to the number of registers it
                        % needs to store its data type (like double, uint16, etc), is
                        % equal to the address of the next row, the next address can be
                        % read with the current address (i.e. contiguous register
                        % values), provided the register type of the current row and
                        % the next row are the same. i.e. both the current row and same
                        % row should be 'Coils' or 'Holdingregs' etc.

                        % Compare the current row register type and the next row
                        % register type.
                        if strcmpi(currentRegisterName, nextRegisterName)

                            % If register types are same and:
                            % current address + data type = next address, meaning,
                            % next address can be read as part of the contiguous read.
                            if address(currentTableRowNumber) + unit == address(currentTableRowNumber+1)

                                % Add the table Index to the current table Index. All
                                % contiguous read table indexes are grouped together.
                                readArgs.(currentRegisterName).Index{registerIndexPointer.(currentRegisterName)} = ...
                                    [readArgs.(currentRegisterName).Index{registerIndexPointer.(currentRegisterName)}, cellarr{currentTableRowNumber+1, obj.ColumnName.Index}];

                                % Get the next row's Precision value
                                nextRowPrecision = string(cellarr{currentTableRowNumber+1, obj.ColumnName.Precision});

                                % If the next row's Precision matches with the current
                                % Precision, increase the Count value of the register
                                % type by 1 and update the Count value for the register
                                % type.
                                if nextRowPrecision == ...
                                        readArgs.(currentRegisterName). ...
                                        Precision{registerIndexPointer.(currentRegisterName)}(end)

                                    countNum = countNum + 1;
                                    readArgs.(currentRegisterName).Count{registerIndexPointer. ...
                                        (currentRegisterName)}(end) = countNum;
                                else

                                    % If the next row's Precision does not match with the current
                                    % Precision, this means ending the previous Count value
                                    % for the Precision type. Make a new Count value of 1 for the
                                    % next Precision value for the same register type.
                                    % (Note: We are still in the condition where the
                                    % current Precision is the same as the next Precision.)
                                    % Get a new Count value 1 for the new Precision
                                    % for the same register type and append the new Precision type.
                                    countNum = 1;
                                    readArgs.(currentRegisterName).Count{registerIndexPointer.(currentRegisterName)} = ...
                                        [readArgs.(currentRegisterName). ...
                                        Count{registerIndexPointer.(currentRegisterName)}, countNum];

                                    readArgs.(currentRegisterName).Precision{registerIndexPointer.(currentRegisterName)} = ...
                                        [readArgs.(currentRegisterName).Precision{registerIndexPointer.(currentRegisterName)}, ...
                                        string(cellarr{currentTableRowNumber+1, obj.ColumnName.Precision})];
                                end
                            else
                                % If register types are same and:
                                % current address + data type < next address, meaning,
                                % next address cannot be read as part of the contiguous
                                % read, increment the registerIndexPointer for the
                                % register type. Assign new Count value for the new
                                % registerIndexPointer to be 1, set the Precision for the
                                % same register type to the Precision of the next row.
                                % Similarly, add a new Index and add a new starting
                                % address.
                                registerIndexPointer.(currentRegisterName) = registerIndexPointer.(currentRegisterName) + 1;
                                countNum = 1;
                                % Update RowIndexPointer
                                readArgs = obj.updateReadArgPointer(readArgs, cellarr, currentRegisterName, address, ...
                                    registerIndexPointer, currentTableRowNumber);
                            end
                        else
                            % If the next register type is not the same as the current
                            % register type, change the Index pointer now to the Index
                            % pointer for the next register type.
                            % Assign new Count value for the new registerIndexPointer to be 1,
                            % set the Precision for the same register type to the Precision
                            % of the next row. Similarly, add a new Index and add a new starting
                            % address.
                            countNum = 1;
                            if ~isempty(readArgs.(nextRegisterName))
                                registerIndexPointer.(nextRegisterName) = registerIndexPointer.(nextRegisterName) + 1;
                            end
                            % Update RowIndexPointer
                            readArgs = obj.updateReadArgPointer(readArgs, cellarr, nextRegisterName, address, ...
                                registerIndexPointer, currentTableRowNumber);
                        end
                    end
                end
            catch ex
                throw(ex);
            end
            
        end

        function readArgs = updateReadArgPointer(obj, readArgs, cellarr, registerName, ...
                address, registerIndexPointer, currentTableRowNumber)
            % Update the readArgs based on the rowIndexPointer,
            % registerName (current or next) and update the fields.
            readArgs.(registerName).Index{registerIndexPointer.(registerName)} = ...
                cellarr{currentTableRowNumber+1, obj.ColumnName.Index};

            % Update Count
            readArgs.(registerName).Count{registerIndexPointer.(registerName)} = 1;

            % Update Precision
            readArgs.(registerName).Precision{registerIndexPointer.(registerName)} = ...
                string(cellarr{currentTableRowNumber+1, obj.ColumnName.Precision});

            % Update StartingAddress
            readArgs.(registerName).StartingAddress{registerIndexPointer.(registerName)} = ...
                address(currentTableRowNumber+1);
        end

        function registerStruct = validateAndAlignRegisterStruct(obj, registerStruct)
            % validateAndAlignRegisterStruct validates the list of modbus register data. It
            % checks that the table input from the Modbus Explorer app and the Simulink
            % blocks are valid, before further operations can be done on them.

            try
                if ~isstruct(registerStruct)
                    throwAsCaller(MException(message('instrument:modbusutility:noStructInput')));
                end
                fieldsTocheck = {'Address', 'RegisterType', 'Precision', 'Index'};

                if sum(isfield(registerStruct, fieldsTocheck)) < length(fieldsTocheck)
                    throwAsCaller(MException(message('instrument:modbusutility:incorrectStructFields')));
                end
                registerStruct = instrument.internal.stringConversionHelpers.str2char(registerStruct);

                % Check that all struct fields are cell arrays
                if ~iscell(registerStruct.Address) || ~iscell(registerStruct.Precision) || ...
                        ~iscell(registerStruct.RegisterType) || ~iscell(registerStruct.Index)
                    throwAsCaller(MException(message('instrument:modbusutility:typeNotCell')));
                end

                try
                    % Try to convert address from cell array to double
                    registerStruct.Address = cell2mat(registerStruct.Address);
                catch ex
                    throwAsCaller(MException(message('instrument:modbusutility:nonNumericAddress')));
                end

                try
                    % Try to convert index from cell array to double
                    registerStruct.Index = cell2mat(registerStruct.Index);
                catch ex
                    throwAsCaller(MException(message('instrument:modbusutility:nonNumericIndex')));
                end

                for i = 1 : length(fieldsTocheck)
                    % If row-order type of cell array, convert it to column-array
                    % format.

                    % If the fields are not 1xn or nx1 vectors, the struct is invalid
                    if ~isscalar(registerStruct.(fieldsTocheck{i}))
                        if size(registerStruct.(fieldsTocheck{i}), 1) ~= 1 && ...
                                size(registerStruct.(fieldsTocheck{i}), 2) ~= 1
                            throwAsCaller(MException(message('instrument:modbusutility:invalidStructSize', string(size(registerStruct.(fieldsTocheck{i}), 1)), ...
                                string(size(registerStruct.(fieldsTocheck{i}), 2)) )));

                        elseif size(registerStruct.(fieldsTocheck{i}), 1) == 1
                            registerStruct.(fieldsTocheck{i}) = [registerStruct.(fieldsTocheck{i})]';
                        end
                    end
                end

                % Validate the size of the struct fields. All fields should have the
                % same number of elements.
                obj.validatesize(registerStruct);

                % Validate the datatype of address.
                validateattributes(registerStruct.Address,{'numeric'}, ...
                    {'finite', 'nonnegative', 'nonempty', 'nonzero', 'nonnan', 'integer'}, ...
                    '', 'Register Address');

                % Validate the table indices.
                validateattributes(registerStruct.Index,{'numeric'}, ...
                    {'finite', 'nonnegative', 'nonempty', 'nonzero', 'nonnan', 'integer'}, ...
                    '', 'Index');

                % Validate RegisterType and Precision
                obj.validateAllRegisterTypeAndPrecision(registerStruct.RegisterType, ...
                    registerStruct.Precision);

                registerStruct.Address = num2cell(registerStruct.Address);
                registerStruct.Index = num2cell(registerStruct.Index);
            catch ex
                throw(ex);
            end
        end

        function validatesize(~, registerStruct)
            % Validate the size of the struct fields. All fields should have the
            % same number of elements.
            if length(registerStruct.Address) ~= length(registerStruct.RegisterType) || ...
                    length(registerStruct.Address) ~= length(registerStruct.Precision) || ...
                    length(registerStruct.Address) ~= length(registerStruct.Index)
                throw(MException(message('instrument:modbusutility:fieldDimensionsMismatch')));
            end
        end

        function validateAllRegisterTypeAndPrecision(obj, regTypes, precision)
            % Validate scalar and cell array of Precision

            try
                validateattributes(regTypes, {'cell'}, {'nonempty'}, '', 'Register Type');
                validateattributes(precision, {'cell'}, {'nonempty'}, '', 'Precision');
                cellfun(@(x) obj.validateRegTypeAndPrecision(regTypes{x}, precision{x}), ...
                    num2cell(1:length(precision)), 'UniformOutput', false);
            catch ex
                throw(ex);
            end
        end

        function validateRegTypeAndPrecision(~, regType, precisionName)
            % Validate Precision argument
            validateattributes(regType,{'char','string'},{'nonempty'}, '', 'Register Type');
            validateattributes(precisionName,{'char','string'},{'nonempty'}, '', 'Precision');
            validRegTypes = {'Coil', 'Input', 'Holding Register', 'Input Register'};
            validatestring(regType, validRegTypes, '', 'Register Type');
            switch regType
                case {'Coil', 'Input'}
                    validatestring(precisionName, {'bit'}, '', 'Precision');
                case {'Holding Register', 'Input Register'}
                    validatestring(precisionName, instrument.interface.modbus.Modbus.Precisions, '', 'Precision');
                otherwise
                    throw(MException(message('instrument:modbusutility:invalidRegisterType', regType)));
            end
        end

        function val = getPrecisionSize(~, precision)
            % Return the register size for each Precision type.
            switch precision
                case {'uint16', 'int16', 'bit'}
                    val = 1;
                case {'uint32', 'int32', 'single'}
                    val = 2;
                case {'double', 'uint64', 'int64'}
                    val = 4;
                otherwise
                    throw(MException(message('instrument:modbusutility:invalidPrecision', precision)));
            end
        end

        function name = getRegisterName(~, name)
            %Get the register type struct field name for a given type of Modbus Register.
            % E.g. for 'Holding Register', the corresponding struct field name is 'Holdingregs'.
            switch name
                case 'Holding Register'
                    name = 'Holdingregs';
                case 'Input Register'
                    name = 'Inputregs';
                case 'Coil'
                    name = 'Coils';
                case 'Input'
                    name = 'Inputs';
                otherwise
                    throw(MException(message('instrument:modbusutility:invalidRegisterType', name)));
            end
        end
    end
end