function param_struct = jpmtr(joint_index)
    persistent joint_parameter;
    
    if isempty(joint_parameter)
        joint_parameter(1).d = 176.0;
        joint_parameter(1).r = 0.0;
        joint_parameter(1).a = 90.0;
        joint_parameter(1).prest = 0.0;
        joint_parameter(1).pmin = -45.0;
        joint_parameter(1).pmax = 45.0;
        joint_parameter(1).vmax = 1000/5;
        joint_parameter(1).phome = 0.0;
        joint_parameter(1).tmux_mask = 0b00000001;
        
		joint_parameter(2).d = 0.0;
		joint_parameter(2).r = 208.0;
		joint_parameter(2).a = 0.0;
		joint_parameter(2).prest = 90.0;
		joint_parameter(2).pmin	= 38.0;
		joint_parameter(2).pmax	= 142.0;
		joint_parameter(2).vmax	= (1000.0/21.0);
		joint_parameter(2).phome = 142.0;
		joint_parameter(2).tmux_mask = 0b00000010;
        
        joint_parameter(3).d = 0.0;
		joint_parameter(3).r = 48.0;
		joint_parameter(3).a = 90.0;
		joint_parameter(3).prest = 0.0;
		joint_parameter(3).pmin	= -52.0;
		joint_parameter(3).pmax	= 52.0;
		joint_parameter(3).vmax	= (1000.0/15.0);
		joint_parameter(3).phome = 0.0;
		joint_parameter(3).tmux_mask = 0b00000100;
        
        joint_parameter(4).d = 184.0;
		joint_parameter(4).r = 0.0;
		joint_parameter(4).a = 90.0;
		joint_parameter(4).prest = 0.0;
		joint_parameter(4).pmin	= -110.0;
		joint_parameter(4).pmax	= 110.0;
		joint_parameter(4).vmax	= (1500.0/(25.0/3.0));
		joint_parameter(4).phome = 0.0;
		joint_parameter(4).tmux_mask = 0b00001000;
        
        joint_parameter(5).d = 0.0;
		joint_parameter(5).r = 0.0;
		joint_parameter(5).a = -90.0;
		joint_parameter(5).prest = 0.0;
		joint_parameter(5).pmin	= -125.0;
		joint_parameter(5).pmax	= 105.0;
		joint_parameter(5).vmax	= (1000.0/5.0);
		joint_parameter(5).phome = 0.0;
		joint_parameter(5).tmux_mask = 0b00010000;
        
        joint_parameter(6).d = 112.0;
		joint_parameter(6).r = 0.0;
		joint_parameter(6).a = 0.0;
		joint_parameter(6).prest = 0.0;
		joint_parameter(6).pmin	= -180.0;
		joint_parameter(6).pmax	= 180.0;
		joint_parameter(6).vmax	= (1500.0/7.0);
		joint_parameter(6).phome = 0.0;
		joint_parameter(6).tmux_mask = 0b00100000;
        
    end
    
    param_struct = joint_parameter(joint_index);
end

