classdef Kinematics
    
    properties (Constant)
        
    end
    
    methods (Access=public, Static=true)
       
        function processedData = process(nxtPacket)
            persistent d;   % these three are constant for a given robot
            persistent r;
            persistent alpha;
            if isempty(d)
                d = [jpmtr(1:6).d]';
                r = [jpmtr(1:6).r]';
                alpha = [jpmtr(1:6).a]';    
            end
            theta = zeros(6, 1);        % joint angles
            for ji=1:6
                theta(ji) = nxtPacket.(['j',num2str(ji),'p']);
            end
            
            processedData = struct();
            
            for ji=1:6
                T{ji} = Kinematics.ht(theta(ji), alpha(ji), r(ji), d(ji));
            end
        end
        
        % homogenous transformation matrix using DH parameter convention
        function T = ht(theta, alpha, r, d)
            st = sin(theta);
            ct = cos(theta);
            sa = sin(alpha);
            ca = cos(alpha);
            T = [   ct, -st*ca,  st*sa, r*ct;    ...
                    st,  ct*ca, -ct*sa, r*st;    ...
                     0,     sa,     ca,    d;    ...
                     0,      0,      0,    1   ];
        end
        
    end
end

