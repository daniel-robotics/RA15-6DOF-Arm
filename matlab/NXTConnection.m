classdef NXTConnection < handle
    
    properties                 
        connected               = false;
        bluetoothName           char
        bluetoothChannel        = 1;
  
        thread                  parallel.FevalFuture
        txQueue                 parallel.pool.DataQueue
        rxQueue                 parallel.pool.DataQueue
        conQueue                parallel.pool.DataQueue
        packetsReceived         = 0;
        packetsSent             = 0;
        
        packetReceivedCallbackFcn function_handle
        packetProcessingFcn     function_handle
        
        
        history                 struct
        lastPCPacket            struct
        lastRow                 = 0;
        tableSize               = 0;
               
    end
    
    properties (Constant)      
        
        DISABLE_PT = fix16_to_dbl(typecast(0x7FFFFFFF, 'int32'));
        DISABLE_VT = fix16_to_dbl(typecast(0x7FFFFFFF, 'int32'));
        
        HISTORY_INITIAL_ROWS    = 10000;
        HISTORY_SIZE_INCREMENT  = 10000;
        
        BLUETOOTH_CODE_PATH     = 'instrument';
        
        BLUETOOTH_CONNECT_TIMEOUT = 60;     % seconds - sometimes takes >30 seconds to form the bluetooth object and fopen
        
        ECROBOT_HEADER_BYTES    = 2;
        
        NXT_BT_PACKET_BYTES     = 62;
        NXT_BT_PACKET_VALS      = 23;
        NXT_BT_HEADER           = [uint8(NXTConnection.NXT_BT_PACKET_BYTES), zeros(1, NXTConnection.ECROBOT_HEADER_BYTES-1, 'uint8')];
        NXT_BT_EMPTY_PACKET     = struct(   'systick',      uint32(0),  ...
                                            'j1p',          double(0),  ...
                                            'j1v',          double(0),  ...
                                            'j1pwm',        int8(0),    ...
                                            'j2p',          double(0),  ...
                                            'j2v',          double(0),  ...
                                            'j2pwm',        int8(0),    ...
                                            'j3p',          double(0),  ...
                                            'j3v',          double(0),  ...
                                            'j3pwm',        int8(0),    ...
                                            'j4p',          double(0),  ...
                                            'j4v',          double(0),  ...
                                            'j4pwm',        int8(0),    ...
                                            'j5p',          double(0),  ...
                                            'j5v',          double(0),  ...
                                            'j5pwm',        int8(0),    ...
                                            'j6p',          double(0),  ...
                                            'j6v',          double(0),  ...
                                            'j6pwm',        int8(0),    ...
                                            'tmux',         uint8(0),   ...
                                            'ea1',          double(0),  ...
                                            'ea2',          double(0),  ...
                                            'ea3',          double(0)   );
        NXT_PACKET_VARS         = fields(NXTConnection.NXT_BT_EMPTY_PACKET);
         
        PC_BT_PACKET_BYTES      = 51;
        PC_BT_PACKET_VALS       = 14;
        PC_BT_HEADER            = [uint8(NXTConnection.PC_BT_PACKET_BYTES), zeros(1, NXTConnection.ECROBOT_HEADER_BYTES-1, 'uint8')];
        PC_BT_EMPTY_PACKET      = struct(   'j1pt',         double(0),  ...
                                            'j1vt',         double(0),  ...
                                            'j2pt',         double(0),  ...
                                            'j2vt',         double(0),  ...
                                            'j3pt',         double(0),  ...
                                            'j3vt',         double(0),  ...
                                            'j4pt',         double(0),  ...
                                            'j4vt',         double(0),  ...
                                            'j5pt',         double(0),  ...
                                            'j5vt',         double(0),  ...
                                            'j6pt',         double(0),  ...
                                            'j6vt',         double(0),  ...
                                            'rcx',          uint8(0),   ...
                                            'nxtTransmitInterval', uint16(100) );
        PC_PACKET_VARS          = fields(NXTConnection.PC_BT_EMPTY_PACKET);
        
    end
    
    methods (Access=public, Static=false)
        
        % CONSTRUCTOR
        %    obj = NXTConnection(@packetReceivedCallbackFcn, @packetProcessingFcn)
        function this = NXTConnection(varargin)
            if nargin >= 1
                this.packetReceivedCallbackFcn = varargin{1};
            end
            if nargin >= 2
                this.packetProcessingFcn = varargin{2};
            end
            
            % Find dependent code
            addpath(NXTConnection.BLUETOOTH_CODE_PATH);
            
            % Preallocate space for history table
            this.resetHistory();
        end
        
        
        function resetHistory(this)
            if this.connected == false
                this.lastRow = 0;
                this.packetsSent = 0;
                this.packetsReceived = 0;
                this.lastPCPacket = NXTConnection.PC_BT_EMPTY_PACKET;

                % Preallocate space for history table
                this.history = struct();
                this.tableSize = NXTConnection.HISTORY_INITIAL_ROWS;

                for i=1:length(NXTConnection.NXT_PACKET_VARS)
                    field = NXTConnection.NXT_PACKET_VARS{i};
                    this.history.(field) = repmat(NXTConnection.NXT_BT_EMPTY_PACKET.(field), this.tableSize, 1);
                end

                for i=1:length(NXTConnection.PC_PACKET_VARS)
                    field = NXTConnection.PC_PACKET_VARS{i};
                    this.history.(field) = repmat(NXTConnection.PC_BT_EMPTY_PACKET.(field), this.tableSize, 1);
                end

                if ~isempty(this.packetProcessingFcn)
                    processedDataEmptyStruct = this.packetProcessingFcn(NXTConnection.NXT_BT_EMPTY_PACKET);
                    processedDataVars = fields(processedDataEmptyStruct);
                    for i=1:length(processedDataVars)
                        field = processedDataVars{i};
                        this.history.(field) = repmat(processedDataEmptyStruct.(field), this.tableSize, 1);
                    end
                end
            end
        end
        
        
        function tab = writeHistory(this, filename)
            tab = table();
            if this.connected == false && this.lastRow >= 1
                fprintf('Writing %d records to file: %s\n', this.lastRow, filename);
                
                varnames = fields(this.history);
                for i=1:length(varnames)
                    tab.(varnames{i}) = this.history.(varnames{i})(1:this.lastRow);
                end
                
                writetable(tab, filename);
                disp('Table written.');
            end
        end
        
                
        function connected = bluetoothConnect(this, name, channel)
            if ~isempty(this.thread) && strcmp(this.thread.State, 'running')
                this.bluetoothDisconnect();
            end
                      
            this.bluetoothName = name;
            this.bluetoothChannel = channel;
            
            this.packetsReceived = 0;
            this.packetsSent = 0;
            
            % Create a parallel pool if necessary
            disp('Starting IO process in background...');
            if isempty(gcp())
                parpool('local', 1);     % one worker
            end
            
            % txQueue: use in primary thread to send data to worker
            %  in primary:  send(txQueue, data)
            %  in worker:   primary calls sendPacket(data)
            
            % https://www.mathworks.com/matlabcentral/answers/424145-how-can-i-send-data-on-the-fly-to-a-worker-when-using-parfeval
            % Get the worker to construct a data queue on which it can receive messages from the client
            % then send the queue object back to the client
            txQueueConstant = parallel.pool.Constant(@parallel.pool.DataQueue);
            this.txQueue = fetchOutputs(parfeval(@(x) x.Value, 1, txQueueConstant));
            
            % rxQueue: use in worker thread to send data back to primary
            %  in worker:   send(rxQueue, data)
            %  in primary:  worker calls bluetoothReceived(data)
            this.rxQueue = parallel.pool.DataQueue;
            afterEach(this.rxQueue, @this.bluetoothReceived);
            
            % conQueue: use in worker thread to output data to primary console
            %  in worker:   send(conQueue, data)
            this.conQueue = parallel.pool.DataQueue;
            afterEach(this.conQueue, @disp);
            
            % Get the worker to start waiting for messages
            this.thread = parfeval(@NXTConnection.run, 0,  ...
                                   txQueueConstant,        ...
                                   this.rxQueue,           ...
                                   this.conQueue,          ...
                                   this.bluetoothName,     ...
                                   this.bluetoothChannel,  ...
                                   this.packetProcessingFcn);
            
            if isempty(this.thread) || ~strcmp(this.thread.State, 'running')
                disp('Failed to start background IO process.');
                this.connected = false;
                connected = this.connected;
                return;
            end
            
            
            for i=1:NXTConnection.BLUETOOTH_CONNECT_TIMEOUT
                pause(1);
                if this.packetsReceived > 0
                    break;
                end
            end
            
            if this.packetsReceived == 0    % reached timeout without receiving anything from NXT
                disp('Failed to connect to NXT - max time reached');
                this.bluetoothDisconnect();
                this.connected = false;
                connected = this.connected;
                return;
            end
            
            this.connected = true;
            connected = this.connected;
        end
    
    
        function connected = bluetoothDisconnect(this)
            if isempty(this.thread) || ~strcmp(this.thread.State, 'running')
                this.connected = false;
                connected = this.connected;
                return;
            end
            if this.packetsReceived > 0
                disconnect_packet = this.lastPCPacket;
                disconnect_packet.nxtTransmitInterval = 0;    % NXT expects this value on disconnect
                this.bluetoothSend(disconnect_packet);
                pause(1.0);
            end
            if strcmp(this.thread.State, 'running')
                cancel(this.thread);
            end
            this.connected = false;
            connected = this.connected;
        end
        
        
        function bluetoothSend(this, pcPacket)
            if this.connected == true
                this.packetsSent = this.packetsSent+1;
                send(this.txQueue, pcPacket);  % send packet to worker thread for transmission
                this.lastPCPacket = pcPacket;  % will get added to history next time an nxt packet is received
            end
        end
        
        
    end      % end of public methods
    
    methods (Access=private, Static=false)

        function bluetoothReceived(this, returnData) % called when background worker gets new data
            persistent PROCESSED_DATA_VARS;
            
            if isempty(PROCESSED_DATA_VARS)
                PROCESSED_DATA_VARS = fields(returnData.processed);
            end
            
            this.packetsReceived = this.packetsReceived+1;
                       
            % Add the return data to history. Also insert the most recent pc packet at this point.
            this.lastRow = this.lastRow+1;
            
            for i=1:length(NXTConnection.NXT_PACKET_VARS)
                field = NXTConnection.NXT_PACKET_VARS{i};
                this.history.(field)(this.lastRow) = returnData.nxt.(field);
            end
            
            for i=1:length(NXTConnection.PC_PACKET_VARS)
                field = NXTConnection.PC_PACKET_VARS{i};
                this.history.(field)(this.lastRow) = this.lastPCPacket.(field);
            end
            
            for i=1:length(PROCESSED_DATA_VARS)
                field = PROCESSED_DATA_VARS{i};
                this.history.(field)(this.lastRow) = returnData.processed.(field);
            end
            
            % If a callback fcn was provided to the constructor, call it now
            if ~isempty(this.packetReceivedCallbackFcn)
                this.packetReceivedCallbackFcn(returnData);
            end
            
            % Check if need to allocate more space to the history table
            if this.lastRow >= this.tableSize     
                this.tableSize = this.tableSize + NXTConnection.HISTORY_SIZE_INCREMENT;
                historyVars = fields(this.history);
                for i=1:length(historyVars)
                    field = historyVars{i};
                    this.history.(field)(this.tableSize) = 0;
                end
            end
        end
        
    end     % end of private methods
    
    
    methods (Access=private, Static=true)
        
        function run(txQueueConstant, rxQueue, conQueue, bluetoothName, bluetoothChannel, packetProcessingFcn)
            global conQueue;
            global nxt;
            
            send(conQueue, 'Background thread started.');
            nxt = NXTConnection.connect(bluetoothName, bluetoothChannel);
            if isempty(nxt) || ~strcmp(nxt.Status, 'open')    
                send(conQueue, 'Background thread aborted: failed to open NXT connection.');
                return;
            end
            
            
            % TX - sendPacket called automatically every time a packet is sent by the primary thread
            %   when sendPacket sees the disconnect signal, calls NXTConnection.disconnect(nxt), which also ends the RX loop
            txQueue = txQueueConstant.Value;
            afterEach(txQueue, @NXTConnection.sendPacket); % uses global nxt variable

            
            % Storage struct for return data:
            %  returnData.nxt:       struct containing values extracted from nxt packet
            %  returnData.processed: struct containing additional values calculated from returnData.nxt
            %                        (or empty struct if no processing function was provided to the class constructor)
            returnData = struct();
            
            
            % RX - readPacket called in this loop to clear the RX buffer as asap as possible
            while ~isempty(nxt) && strcmp(nxt.Status, 'open')

                returnData.nxt = NXTConnection.readPacket();  % uses global nxt variable
                
                % Process the incoming packet using the provided function handle
                if isempty(packetProcessingFcn)
                    returnData.processed = struct();
                else
                    returnData.processed = packetProcessingFcn(returnData.nxt);
                end
                send(rxQueue, returnData);
            end
            
            send(conQueue, 'Background thread closing.');
        end
        
        
        function nxtPacket = readPacket()
            global conQueue;
            global nxt;
            
            if ~isempty(nxt) && strcmp(nxt.Status, 'open')
                
                % read bytes until the header is consumed
                header = uint8([]);
                while isempty(strfind(header, NXTConnection.NXT_BT_HEADER))
                    header = [header, uint8(fread(nxt, 1, 'uint8'))];
                end

                % Read rest of packet from bluetooth
                payload = uint8(fread(nxt, NXTConnection.NXT_BT_PACKET_BYTES, 'uint8'));

                % Parse payload bytes into storage format and place in table
                offset = 1;
                nxtPacket = NXTConnection.NXT_BT_EMPTY_PACKET;
                nxtPacket.systick       = uint32(       typecast(payload(offset:offset+4-1),'uint32') ); offset=offset+4;
                nxtPacket.j1p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j1v           = fix16_to_dbl(	typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j1pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.j2p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j2v           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j2pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.j3p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4; 
                nxtPacket.j3v           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j3pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.j4p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j4v           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j4pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.j5p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j5v           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j5pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.j6p           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j6v           = fix16_to_dbl( typecast(payload(offset:offset+4-1),'int32' ) ); offset=offset+4;
                nxtPacket.j6pwm         = int8(         typecast(payload(offset:offset+1-1),'int8'  ) ); offset=offset+1;
                nxtPacket.tmux          = uint8(        typecast(payload(offset:offset+1-1),'uint8' ) ); offset=offset+1;
                nxtPacket.ea1           = double(       typecast(payload(offset:offset+1-1),'uint8' ) ); offset=offset+1;
                nxtPacket.ea2           = double(       typecast(payload(offset:offset+1-1),'uint8' ) ); offset=offset+1;
                nxtPacket.ea3           = double(       typecast(payload(offset:offset+1-1),'uint8' ) ); offset=offset+1;
            else
                nxtPacket = struct();
            end
        end
        
        
        function sendPacket(pcPacket)
            global conQueue;
            global nxt;
            
            if ~isempty(nxt) && strcmp(nxt.Status, 'open')
                %send(conQueue, 'Sending packet...');
                payload = zeros(1, NXTConnection.PC_BT_PACKET_BYTES, 'uint8');

                %Convert commands into robot-compatible values and insert into packet
                offset = 1;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j1pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j1vt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j2pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j2vt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j3pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j3vt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j4pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j4vt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j5pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j5vt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j6pt),	'uint8');	offset=offset+4;
                payload(offset:offset+4-1) = typecast(fix16_from_dbl(pcPacket.j6vt),	'uint8');	offset=offset+4;
                payload(offset:offset+1-1) = typecast(uint8(pcPacket.rcx),            'uint8');     offset=offset+1;
                payload(offset:offset+2-1) = typecast(uint16(pcPacket.nxtTransmitInterval), 'uint8');	offset=offset+2;
                %send(conQueue, payload);

                % Attach header and send over bluetooth
                fwrite(nxt, [NXTConnection.PC_BT_HEADER, payload]);
                %send(conQueue, 'Packet sent');

                if pcPacket.nxtTransmitInterval == 0     % signal to disconnect
                    disconnect(nxt);
                end
            else
                send(conQueue, 'Error sending packet: nxt connection not open');
            end

        end
        
        
        function nxt = connect(bluetoothName, bluetoothChannel)      
            global conQueue;
            
            send(conQueue, sprintf('Connecting to %s on channel %d...', bluetoothName, bluetoothChannel));
            
            nxt = Bluetooth(bluetoothName, bluetoothChannel);
            if isempty(nxt)
                send(conQueue, 'Failed to create Bluetooth object for NXT.');
                return;
            end
            
            send(conQueue, 'Bluetooth object created, opening connection.');
            
            nxt.Terminator = '';
            flushoutput(nxt);
            flushinput(nxt);
            fopen(nxt);
            if ~strcmp(nxt.Status, 'open')
                send(conQueue, 'Failed to open communications with NXT.');
                fclose(nxt);
                delete(nxt);
                return;
            end

            send(conQueue, 'NXT Connected.');
        end
        
        
        function disconnect(nxt)
            global conQueue;
            
            if ~isempty(nxt) && strcmp(nxt.Status, 'open')
                send(conQueue, 'Disconnecting from NXT...');
                fclose(nxt);
                delete(nxt);
            end
        end
                
    end     % end of private static methods
        

end     % end of class

