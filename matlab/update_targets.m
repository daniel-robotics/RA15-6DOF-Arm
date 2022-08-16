% Called in main loop.
% Defines multiple procedures to be executed in series.
% Each procedure consists of a command set for the robot to complete.
% When the robot has reached its targets, the procedure increments and
%   new targets are set.
% When all procedures are completed, returns all_procedures_complete=1.

function all_procedures_complete = update_targets()
    global command;
    
    switch(command.procedure)
        case 1
            command.mode = Modes.POSITION_AND_VELOCITY;
            command.j1pt = 100;
            command.j3pt = 100;
            command.j5pt = -100;
            
            if(targets_reached(15))
                command.procedure = command.procedure+1;
            end
           
        case 2
            command.mode = Modes.POSITION_AND_VELOCITY;
            command.j1pt = 0;
            command.j3pt = 0;
            command.j5pt = 0;
            
            if(targets_reached(15))
                command.procedure = command.procedure+1;
            end
    end
    
    if(command.procedure > 2)
        all_procedures_complete = 1;
    else
        all_procedures_complete = 0;
    end
end

