classdef MatFileUtility < handle
    %% MATFILEUTILITY is the Utility class for Exporting and Importing
    %Data to and from a MAT file. This is used by the MODBUS Explorer App,
    %MODBUS Simulink Read and Write Blocks.
    %
    % Source: This is the name from where the MAT file utility is called,
    % i.e. 'App', 'ReadBlock', 'WriteBlock'.
    % Default: 'App'
    %
    % AppServerId: This is an optional parameter that is passed when the
    % Source is 'App'. It is the server ID for the current App session. For
    % all other Sources, the AppServerId is not required.
    % Default: 1
    %
    % E.g. 
    % Register Table Data from the Modbus Explorer App
    %
    %     tableData =
    %   4×6 cell array
    % 
    %     {[0]}    {'Volume'  }    {[40006]}    {'Holding Register'}    {'single'}    {'12.12'}
    %     {[0]}    {'pos'     }    {[40050]}    {'Coil'            }    {'bit'   }    {'1'    }
    %     {[0]}    {'pos0'    }    {[40052]}    {'Coil'            }    {'bit'   }    {'0'    }
    %     {[0]}    {'Humidity'}    {[40004]}    {'Holding Register'}    {'uint16'}    {'23'   }
    %
    %   Convert this data as a MAT file
    %
    %   >> serverId = 1;
    %   matFileUtility = instrument.interface.modbus.utility.MatFileUtility ...
    %                 ('App', serverId);
    %   matFileData = matFileUtility.convertToMatFileFormat(registerTableData);
    %
    %   matFileData = 
    % 
    %   Table
    % 
    %     Name        Address       RegisterType       Precision    ServerId
    %     ________    _______    __________________    _________    ________
    %     
    %     "Volume"     40006     "Holding Register"      "uint16"        1
    %     "pos"        40050     "Coil"                  "bit"        1
    %     "pos0"       45099     "Coil"                  "bit"        1
    %     "Humidity"   40052     "Holding Register"      "uint16"        1
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    properties
        Source {mustBeMember(Source,{'App','ReadBlock','WriteBlock'})} = 'App'
    end
    
    properties (Hidden)
        % The definition of mustBeInRange is at the bottom of this file
        AppServerId {mustBeNumeric, mustBeInRange(AppServerId)} = 1
    end

    properties (Constant, Hidden)
        ServerIdRange = instrument.interface.modbus.Modbus.ServerIdRange
        NameColumn = 1
        AddressColumn = 2
        RegisterTypeColumn = 3
        PrecisionColumn = 4
        ServerIdColumn = 5
        DefaultSelectValue = {false}
        DefaultReadValue = {''}
        
        %% Read Blocks Only
        DefaultCount = {1}
        CountColumn = 4
        ReadBlockPrecisionColumn = 5
        ReadBlockServerIdColumn = 6
        NameIdentifier = '_MWMAT'
        TableName = 'ModbusRegisterTable'
        ExpectedColumns = message('instrument:modbusmatutility:expectedColumns').getString
    end

    methods
        function obj = MatFileUtility(source, serverId)
            %MATFILEUTILITY Construct an instance of this class. Assign the
            % Class parameters.
            narginchk(1, 2);
            obj.Source = source;
            if nargin == 2
                obj.AppServerId = serverId;
            end
        end


        function data = convertToMatFileFormat(obj, data)
            % Converts the Table Data to MAT File format.
            % Output: MAT File data as a struct with the fields - Name,
            % Address, Precision, RegisterType, ServerId.
            % data: This is the Register Table Data from the App or the Blocks. 
            % Data is a cell array of N x M for Table Data,
            % The validation for Data coming in from the Table only involves
            % checking for empty cells and rows in the table (it is assumed that
            % the table is always in a valid state when the data is to be
            % exported).

            if ~iscell(data)
                throw(MException(message('instrument:modbusmatutility:wrongTableDataInputType')));
            end
            functionName = ['convert', obj.Source, 'TableData'];
            data = obj.(functionName)(data);
            
            % If the data was empty, do not convert to table.
            if ~isempty(data)
                data = struct2table(data);
            end
        end

        function [data, serverIdWarning] = convertToTableFormat(obj, data, format)
            % Converts the Table Data to MAT File format.
            % Output: 
            % data: Register Table Data converted from the MAT file. The
            % Table Data is a cell array for the App. It is a struct array
            % with the respective fields for the Blocks
            %
            % serverIdWarning: A warning message that means that the Server Id
            % of none of the registers in the MAT file matched with the MODBUS
            % Explorer App's Server Id, or that multiple Server Ids were detected
            % in the MAT File being imported and only loading Registers whose
            % Server Ids match the Server Id of the current app session.
            % Default = []
            %
            % Input:
            % data: This is the MAT File data. Data is a table 'ModbusRegisterTable'
            % with 'Name', 'Address', 'RegisterType', 'Precision', and 'ServerId'.
            % The validation for Data coming in from the MAT file involves Register
            % Utility checks in the MatFileUtility
            %
            % format: This boolean flag tells whether the Table Data needs to be
            % formatted, only when importing a MAT file created by a Read Block
            % containing multiple count rows back into a Read Block. For other
            % scenarios, the value of Format is not important is not checked.
            % Default: false

            narginchk(2, 3);
            formattedDataMap = obj.validateMatFileInput(data);
            functionName = ['convert', obj.Source, 'MATData'];

            if strcmpi(obj.Source, 'ReadBlock')
                % Format is not specified, Make the format false by
                % default.
                if nargin == 2
                   format = false;
                else
                    if ~islogical(format)
                        throw(MException(message('instrument:modbusmatutility:wrongFormatType')));
                    end
                end
                [data, serverIdWarning] = obj.(functionName)(formattedDataMap, format);
            else
                [data, serverIdWarning] = obj.(functionName)(formattedDataMap);
            end
        end
    end

    methods (Access = private)

        function formattedDataMap = validateMatFileInput(obj, data)
            % Validate the input of the MAT file data being imported

            formattedDataMap = containers.Map;
            try
                % Check to see if the MAT file contains the Table
                fieldToCheck = obj.TableName;
                if ~isfield(data, fieldToCheck)
                    throw(MException(message('instrument:modbusmatutility:wrongMATFile', obj.TableName, ...
                        obj.ExpectedColumns)));
                end

                data = data.(obj.TableName);
                data = obj.convertToStruct(data);

                % Check that all field lengths are same in trhe struct
                if length(data.Address) ~= length(data.Name) && ...
                        length(data.Address) ~= length(data.Precision) && ...
                        length(data.Address) ~= length(data.ServerId) && ...
                        length(data.Address) ~= length(data.RegisterType)
                    throw(MException(message('instrument:modbusmatutility:inconsistentDataLength')));
                end

                % Validate Name
                % Check that every name value is a valid variable name
                obj.validateAllNames(data.Name);

                % Check that all names are unique
                if length(data.Name) ~= length(unique(data.Name))
                    throw(MException(message('instrument:modbusmatutility:nonUniqueVariableNames')));
                end

                % Validate ServerId
                validateattributes(data.ServerId, ...
                    {'numeric'}, {'nonempty', 'integer'}, '', 'ServerId');

                % Separate out the different Server Ids and group Rows of
                % Register Input Data from the MAT file that have the same
                % serverIds, i.e. All ServerID = 1 are grouped together, all
                % ServerID = 2 are grouped together, and so on.
                serverIdGroups = unique(data.ServerId);
                for i = 1 : length(serverIdGroups)
                    serverId = serverIdGroups(i);

                    % Check if Server ID lies in the valid range of values
                    % for Server Ids.
                    if serverId < (obj.ServerIdRange(1) + 1) || serverId > obj.ServerIdRange(2)
                        throw(MException(message('instrument:modbusmatutility:invalidServerId', num2str(serverId), ...
                            num2str(obj.ServerIdRange(1) + 1), num2str(obj.ServerIdRange(2)))));
                    end
                    
                    % Find the indices of thhe MAT file that match the current server ID 
                    indices = find(ismember(data.ServerId, serverId));

                    % Create the Register Utility Fields
                    registerFields = [];
                    registerFields.Index = num2cell(1:length(indices));

                    try
                        registerFields.Address = num2cell(data.Address(indices));
                    catch
                        throw(MException(message('instrument:modbusmatutility:nonNumericAddress')));
                    end

                    registerFields.Precision = data.Precision(indices);
                    registerFields.RegisterType = data.RegisterType(indices);

                    % Create Regiser Util instance. This verifies the Address
                    % fields, Register Types and Precision Fields
                    registerUtility = instrument.interface.modbus.utility.RegisterUtility(registerFields);
                    registerUtility.getReadArguments();

                    registerFields.Name = data.Name(indices);
                    formattedDataMap(num2str(serverId)) = registerFields;
                end
            catch ex
                throw(ex);
            end
        end

        function validateAllNames(~, names)
            % Check that every name value is a valid variable name
            
            for i = 1 : length(names)
                if ~isvarname(names{i})
                    throw(MException(message('instrument:modbusmatutility:invalidVariableName', names{i})));
                end
            end
        end

        function data = convertAppTableData(obj, tableData)
            % Convert the App table data to MAT file format.
            try
                data = [];
                if ~isempty(tableData)

                    % Remove the Select Column and Read Column
                    tableData(:, 1) = [];
                    tableData(:, end) = [];

                    % Convert to Mat File format.
                    data = obj.createMatFileData(tableData);
                end
            catch ex
                throw(ex);
            end
        end

        function data = convertWriteBlockTableData(obj, tableData)
            % Convert the Write Block table data to MAT file format.
            try
                data = [];
                if ~isempty(tableData)

                    % Convert to Mat File format.
                    data = obj.createMatFileData(tableData);
                end
            catch ex
                throw(ex);
            end
        end
        
        function data = convertReadBlockTableData(obj, tableData)
            % Convert the Read Block table data to MAT file format.
            try
                data = [];
                if ~isempty(tableData)
                    tableLength = size(tableData, 1);

                    % Check for empty cells.
                    obj.checkEmptyCells(tableData);
                    
                    % Iterate over the table
                    for i = 1 : tableLength
                        count = cell2mat(tableData(i, obj.CountColumn));
                        registerType = string(tableData{i, obj.RegisterTypeColumn});
                        precision = string(tableData{i, obj.ReadBlockPrecisionColumn});
                        startingAddress = tableData{i, obj.AddressColumn};
                        name = string(tableData{i, obj.NameColumn});
                        serverId = tableData{i, obj.ReadBlockServerIdColumn};
                        
                        % Do further processing to the data if count > 1
                        if count > 1
                            
                            % Get the precision size in Bytes
                            sizeOfPrecision = obj.getPrecisionSize(precision);
                            
                            % Get all addresses, given the starting address,
                            % count and precision type.
                            allAddresses = obj.getReadBlockAddressesMultipleCount(startingAddress, count, sizeOfPrecision);
                            
                            % Get the name for each row of the MAT file,
                            % appending the address and identifier
                            % '_<address>_MWMAT' to the current Register Name
                            allNames = obj.getReadBlockNamesMultipleCount(name, allAddresses);
                            
                            % Append the data to the already existing data.
                            data = obj.appendReadTableData(data, allNames, allAddresses, registerType, precision, serverId);
                        else
                            % Append the data to the already existing data.
                            data = obj.appendReadTableData(data, name, startingAddress, registerType, precision, serverId);
                        end
                    end
                    
                    allFields = fieldnames(data);
                    for i = 1 : length(allFields)
                        data.(allFields{i}) = data.(allFields{i})';
                    end
                end
            catch ex
                throw(ex);
            end
        end
        
        function [data, serverIdWarning] = convertAppMATData(obj, formattedDataMap)
            try
                % Convert the MAT file data to the App Register Table format
                serverId = num2str(obj.AppServerId);
                data = [];
                serverIdWarning = [];
                if formattedDataMap.Count > 1
                    serverIdWarning = message('instrument:modbusmatutility:multipleServerIds');
                end

                % If the server ID matches with the app's server Id, else return empty data
                if isKey(formattedDataMap, serverId)
                    registerData = formattedDataMap(serverId);
                    tableLength = length(registerData.Index);
                    selectColumn = repmat(obj.DefaultSelectValue, tableLength, 1);
                    readColumn = repmat(obj.DefaultReadValue, tableLength, 1);
                    data = horzcat(selectColumn, registerData.Name, ...
                        registerData.Address, registerData.RegisterType, registerData.Precision, ...
                        readColumn);
                else
                    serverIdWarning = message('instrument:modbusmatutility:noMatchingServerIds');
                end
            catch ex
                throw(ex);
            end
        end

        function [data, serverIdWarning] = convertWriteBlockMATData(obj, formattedDataMap)
            % Convert the MAT file data to the Write Block Register Table format
            try
                serverIdWarning = [];
                data = [];
                keyset = formattedDataMap.keys;
                structIndex = 1;
                for i = 1 : length(keyset)
                    registerData = formattedDataMap(keyset{i});
                    serverId = str2double(keyset{i});
                    [data, structIndex] = obj.fillUnformmatedBlock(data, registerData, serverId, structIndex, 'write');
                end
            catch ex
                throw(ex);
            end
        end

        function [data, serverIdWarning] = convertReadBlockMATData(obj, formattedDataMap, format)
            % Convert the MAT file data to the Read Block Register Table format
            try
                serverIdWarning = [];
                data = [];
                keyset = formattedDataMap.keys;
                structIndex = 1;
                for i = 1 : length(keyset)
                    registerData = formattedDataMap(keyset{i});
                    
                    % The data does not need to be formatted, i.e. keep
                    % Name_<Address>_MWMATs as is, if it exists in the MAT
                    % file.
                    if ~format
                        serverId = str2double(keyset{i});
                        [data, structIndex] = obj.fillUnformmatedBlock(data, registerData, serverId, structIndex, 'read');
                    else
                        % The data needs to be formatted, i.e.
                        % Name_<Address>_MWMATs need to be formatted and
                        % clubbed together to get the appropriate Name,
                        % Address, and Count.
                        dataValues = obj.prepareFormattedReadTableDataFromMAT(registerData, str2double(keyset{i}));
                        
                        % Prepare the output 'data'
                        if isempty(data)
                            data = dataValues;
                            structIndex = structIndex + size(dataValues, 2);
                        else
                            for index = 1 : size(dataValues, 2)
                                data(structIndex) = dataValues(index);
                                structIndex = structIndex + 1;
                            end
                        end
                    end
                end
            catch ex
                throw(ex);
            end
        end

        function checkEmptyCells(obj, tableData)
            % Check if any table cells are empty. Throw an error if empty
            % cells exist in the table.
            emptyCellsIndices = cellfun(@isempty, tableData);

            if find(emptyCellsIndices)
                messageString = ['instrument:modbusmatutility:emptyCells', obj.Source];
                throw(MException(message(messageString)));
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
                    throw(MException(message('instrument:modbusmatutility:invalidPrecision', precision)));
            end
        end
        
        function addresses = getReadBlockAddressesMultipleCount(~, startingAddress, count, sizeOfPrecision)
            % Returns the Array of addresses, given a starting address,
            % precision type, and count.
            % E.g. Register Address = 4000, precision: uint32, count = 4
            % addresses = [4000 4002 4004 4006]

            addresses = startingAddress;
            for i = 2 : count
               addresses(end+1) = addresses(end) + sizeOfPrecision; %#ok<*AGROW>
            end
        end
        
        function names = getReadBlockNamesMultipleCount(obj, name, addresses)
            % Returns the String array of names, for a given starting
            % address, count value and the Name
            % E.g. name = 'Humidity', addresses = [4000 4002 4004 4006]
            % names : "Humidity_4000_MWMAT", "Humidity_4002_MWMAT" "Humidity_4004_MWMAT"
            % "Humidity_4006_MWMAT"
            for i = 1 : length(addresses)
                names(i) = name + "_" + num2str(addresses(i)) + obj.NameIdentifier;
            end
        end
        
        function data = appendReadTableData(~, data, names, addresses, registerType, precision, serverId)
            % Append the data to the already existing data for a Read Block
            % Register Table Data conversion to MAT file Format
            fieldLength = length(names);
            if isempty(data)
                data.Name = names;
                data.Address = addresses;
                data.RegisterType = repmat(registerType, 1, fieldLength);
                data.Precision = repmat(precision, 1, fieldLength);
                data.ServerId = repmat(serverId, 1, fieldLength);
            else
                data.Name = [data.Name, names];
                data.Address = [data.Address, addresses];
                data.RegisterType = [data.RegisterType, repmat(registerType, 1, fieldLength)];
                data.Precision = [data.Precision, repmat(precision, 1, fieldLength)];
                data.ServerId = [data.ServerId, repmat(serverId, 1, fieldLength)];
            end
        end
        
        function data = createMatFileData(obj, tableData)
            % Create the MAT file data to be stored for the Write Block and
            % the App.

            % Check for empty cells.
            obj.checkEmptyCells(tableData);
            
            data.Name = string(tableData(:, obj.NameColumn));
            data.Address = cell2mat(tableData(:, obj.AddressColumn));
            data.RegisterType = string(tableData(:, obj.RegisterTypeColumn));
            data.Precision = string(tableData(:, obj.PrecisionColumn));
            
            if strcmpi(obj.Source, 'App')
                tableLength = size(tableData, 1);
                data.ServerId = repmat(obj.AppServerId, tableLength, 1);
            elseif strcmpi(obj.Source, 'WriteBlock')
                data.ServerId = cell2mat(tableData(:, obj.ServerIdColumn));
            end
        end
        
        function data = prepareFormattedReadTableDataFromMAT(obj, registerData, serverId)
            % Format the MAT file data to a Read Block Register Table Data,
            % which involves stripping away of the "_<Address>_MWMAT"
            data = [];
            fieldLength = length(registerData.Name);
            structIndex = 1;
            
            % Names and Indices of all register rows have "_<Address>_MWMAT"
            multipleCountNames = struct('Index', [], 'Name', {''});

            % Indices of all other register rows
            singleCountNamesIndex = {};
            % Group all names that have the unique name identifiers 
            for i = 1 : fieldLength
                name = string(registerData.Name(i));
                
                % Find if the string "_MWMAT" exists in the Register Name
                identifierIndex = strfind(name, obj.NameIdentifier);
                if ~isempty(identifierIndex)
                    
                    % Get its corresponding address
                    correspondingAddress = cell2mat(registerData.Address(i));
                    
                    % Extract the string between the start of the Name and
                    % "_MWMAT". E.g. if name = "Humidity_4000_MWMAT",
                    % namePart will be "Humidity_4000_"
                    namePart = extractBetween(name, 1, identifierIndex);
                    
                    % Find all instances of '_' in namePart
                    underscoreIndices = strfind(namePart, '_');
                    
                    % For it to be a possible formatted register name,
                    % there should be atleast 2 '_' and the last '_' in the
                    % namePart should be at the very end of namePart
                    if length(underscoreIndices) > 1 && ...
                            underscoreIndices(end) == strlength(namePart)
                        
                        % E.g. Get the address value "4000" from
                        % "Humidity_4000_" and convert that to double.
                        address = str2double ...
                            (extractBetween(namePart, underscoreIndices(end-1)+1,underscoreIndices(end)-1));
                        
                        % If the address in the name matches the
                        % corresponding Address, this is a possibel name
                        % that needs to be formatted. Store this away.
                        if address ==  correspondingAddress
                            multipleCountNames.Name{end+1} = extractBetween(name, 1, underscoreIndices(end-1));
                            multipleCountNames.Index(end+1) = i;
                        else
                            % If any of the above conditions did not match,
                            % this name is not a name that requires
                            % formatting. Save its index.
                            singleCountNamesIndex{end+1} = i;
                        end
                    else
                        singleCountNamesIndex{end+1} = i;
                    end
                else
                    singleCountNamesIndex{end+1} = i;
                end
            end
            
            % Get all unique names in the multipleCountNames. E.g.
            % "Humuidity_", "Pressure_"
            uniqueNames = unique(string(multipleCountNames.Name));
            if uniqueNames == ""
                uniqueNames = [];
            end
            
            % Map of these unique names.
            nameMap = containers.Map;
            for i = 1 : length(uniqueNames)
                
                % Find all indexes of each Uniqie Names
                indexes = find(contains(string(multipleCountNames.Name), uniqueNames(i)));
                nameMap(uniqueNames(i)) = indexes;
            end

            keyset = nameMap.keys;

            % Iterate over the unique names
            for i = 1 : length(keyset)
                
                % Indexes in the MAT file where these unique names were
                % present.
                indexes = nameMap(keyset{i});
                
                if length(indexes) == 1
                    singleCountNamesIndex{end+1} = indexes;
                else
                    addresses = cell2mat(registerData.Address(indexes));
                    precisions = string(registerData.Precision(indexes));
                    registerTypes = string(registerData.RegisterType(indexes));
                    
                    % Check if all precision values for all unique name rows are
                    % the same. i.e. for a possible formatted name, the
                    % precision type for every row has to be the same.
                    uniquePrecision = unique(precisions);
                    
                    % Similarly, the Register Type for each unique name
                    % instance has to be the same
                    uniqueRegisterType = unique(registerTypes);
                    
                    % If the precision and register types for these instances
                    % are not the same for each instance, this name cannot be
                    % formatted and index of these names needs to be added to
                    % the list of the unformatted names.
                    if length(uniquePrecision) ~= 1 || length(uniqueRegisterType) ~= 1
                        singleCountNamesIndex{end+1} = indexes;
                    else
                        % Check that the addresses and precision type of these
                        % possible formatted instances are valid.
                        sizeOfPrecision = obj.getPrecisionSize(uniquePrecision);
                        addresses = sort(addresses);
                        
                        % Check that the addresses and precision type are
                        % proper. If not, add the index to the list of
                        % unformatted names.
                        if ~obj.checkValidAddress(addresses, sizeOfPrecision)
                            singleCountNamesIndex{end+1} = indexes;
                        else
                            % This is finally a formatted name. Format the rows
                            % accordingly.
                            name = keyset{i};
                            if length(name) > 1
                                name = name(1:end-1);
                            end
                            data(structIndex).Name = string(name);
                            data(structIndex).Precision = uniquePrecision;
                            data(structIndex).Count = length(indexes);
                            data(structIndex).Address = addresses(1);
                            data(structIndex).RegisterType = uniqueRegisterType;
                            data(structIndex).ServerId = serverId;
                            structIndex = structIndex + 1;
                        end
                    end
                end
            end
            
            singleCountNamesIndex = cell2mat(singleCountNamesIndex);
            
            % Add the remaining list of unformatted rows
            for i = 1 : length(singleCountNamesIndex)
                data(structIndex).Name = string(registerData.Name(singleCountNamesIndex(i)));
                data(structIndex).Precision = string(registerData.Precision(singleCountNamesIndex(i)));
                data(structIndex).Count = 1;
                data(structIndex).Address = registerData.Address{singleCountNamesIndex(i)};
                data(structIndex).RegisterType =  string(registerData.RegisterType(singleCountNamesIndex(i)));
                data(structIndex).ServerId = serverId;
                structIndex = structIndex + 1;
            end
        end

        function flag = checkValidAddress(~, addresses, sizeOfPrecision)
            % Checks that the register addresses and precision types are in
            % sync, i.e. for addresses 4000 4002 and 4004, the precision
            % type is a 2-byte precision type like uint32, int32, or
            % single.
            flag = true;
            for i = 1 : length(addresses) - 1
                nextAddress = addresses(i) + sizeOfPrecision;
                if nextAddress ~= addresses(i+1) 
                    flag = false;
                    break
                end
            end
        end
        
        function [data, structIndex] = fillUnformmatedBlock(~, data, registerData, serverId, structIndex, type)
            % Format the Register Table Data to the MAT file format and
            % append it to the existing MAT fle data.
            
            % For Read Block - There is a field called Count. Its value is
            % always 1. Count > 1 for read blocks are handled elsewhere.
            if strcmpi(type, 'read')
                for i = 1 : length(registerData.Index)
                    if isempty(data)
                        data = struct('Name', string(registerData.Name(i)), ...
                            'Address', registerData.Address(i), ...
                            'Precision', string(registerData.Precision(i)), ...
                            'Count', 1, ...
                            'RegisterType', string(registerData.RegisterType(i)), ...
                            'ServerId', serverId);
                    else
                        data(structIndex) = struct('Name', string(registerData.Name(i)), ...
                            'Address', registerData.Address(i), ...
                            'Precision', string(registerData.Precision(i)), ...
                            'Count', 1, ...
                            'RegisterType', string(registerData.RegisterType(i)), ...
                            'ServerId', serverId);
                    end
                    structIndex = structIndex + 1;
                end
            else
                % For Write Block - No Count field
                for i = 1 : length(registerData.Index)
                    if isempty(data)
                        data = struct('Name', string(registerData.Name(i)), ...
                            'Address', registerData.Address(i), ...
                            'Precision', string(registerData.Precision(i)), ...
                            'RegisterType', string(registerData.RegisterType(i)), ...
                            'ServerId', serverId);
                    else
                        data(structIndex) = struct('Name', string(registerData.Name(i)), ...
                            'Address', registerData.Address(i), ...
                            'Precision', string(registerData.Precision(i)), ...
                            'RegisterType', string(registerData.RegisterType(i)), ...
                            'ServerId', serverId);
                    end
                    structIndex = structIndex + 1;
                end
            end
        end
        
        function structData = convertToStruct(obj, data)
            % Convert the MAT file content from the Table format to struct
            % format.

            if ~istable(data)
                throw(MException(message('instrument:modbusmatutility:wrongMATFile', obj.TableName, ...
                        obj.ExpectedColumns)));
            end

            data = table2struct(data);
            % Validate that the required fields are present - 'Address',
            % 'RegisterType', 'Precision', 'Name', 'ServerId'
            fieldsTocheck = {'Address', 'RegisterType', 'Precision', 'Name', 'ServerId'};
            if sum(isfield(data, fieldsTocheck)) ~= length(fieldsTocheck)
                throw(MException(message('instrument:modbusmatutility:incorrectTableColumns', ...
                    obj.ExpectedColumns)));
            end
            structData = [];
            for i = 1 : size(data, 1)
                for j = 1 : length(fieldsTocheck)
                    if i == 1
                        structData.(fieldsTocheck{j}) = data(i).(fieldsTocheck{j});
                    else
                        structData.(fieldsTocheck{j})(end+1) = data(i).(fieldsTocheck{j});
                    end
                end
            end

            structData = instrument.internal.stringConversionHelpers.str2char(structData);
            
            for i = 1 : length(fieldsTocheck)
                % If row-order type of cell array, convert it to column-array
                % format.
                
                if ischar(structData.(fieldsTocheck{i}))
                    structData.(fieldsTocheck{i}) = cellstr(structData.(fieldsTocheck{i}));
                end
                
                % If the fields are not 1xn or nx1 vectors, the struct is invalid
                if ~isscalar(structData.(fieldsTocheck{i}))
                    if size(structData.(fieldsTocheck{i}), 1) ~= 1 && ...
                            size(structData.(fieldsTocheck{i}), 2) ~= 1
                        throw(MException(message('instrument:modbusmatutility:invalidStructSize', string(size(structData.(fieldsTocheck{i}), 1)), ...
                            string(size(structData.(fieldsTocheck{i}), 2)) )));
                        
                    elseif size(structData.(fieldsTocheck{i}), 1) == 1
                        structData.(fieldsTocheck{i}) = [structData.(fieldsTocheck{i})]';
                    end
                end
            end
        end
    end
end
function mustBeInRange(appServerId)
% Validate that the serverID entered in the constructor is valid.
serverIdRange = instrument.interface.modbus.utility.MatFileUtility.ServerIdRange;

if appServerId < serverIdRange(1) || appServerId > serverIdRange(2)
    throw(MException(message('instrument:modbusmatutility:invalidServerId', num2str(appServerId), ...
        num2str(serverIdRange(1)), num2str(serverIdRange(2)))));
end
end