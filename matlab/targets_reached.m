% mode == POSITION_AND_VELOCITY:
%   returns reached=1 if sumsqr(position error) <= convergence.
% mode == POSITION_AND_VELOCITY:
%   returns reached=1 if sumsqr(velocity error) is <= convergence.

function reached = targets_reached(convergence)
    global data;
    global command;
    
    error = zeros(1, 6);
    last_row = size(data, 1);
    
    switch(command.mode)
        case Modes.POSITION_AND_VELOCITY
            error(1) = command.j1pt - data.j1p(last_row);
            error(2) = command.j2pt - data.j2p(last_row);
            error(3) = command.j3pt - data.j3p(last_row);
            error(4) = command.j4pt - data.j4p(last_row);
            error(5) = command.j5pt - data.j5p(last_row);
            error(6) = command.j6pt - data.j6p(last_row);
        case Modes.VELOCITY_ONLY
            error(1) = command.j1vt - data.j1v(last_row);
            error(2) = command.j2vt - data.j2v(last_row);
            error(3) = command.j3vt - data.j3v(last_row);
            error(4) = command.j4vt - data.j4v(last_row);
            error(5) = command.j5vt - data.j5v(last_row);
            error(6) = command.j6vt - data.j6v(last_row);
    end
    
    if(sumsqr(error) <= convergence)
        reached = 1;
    else
        reached = 0;
    end  
end

