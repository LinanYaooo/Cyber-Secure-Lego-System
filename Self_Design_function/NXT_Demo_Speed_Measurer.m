%% NXT_Demo_Speed_Measurer;
%% Motor_Speed_Measurement_Function;
% w = (Theta1 - Theta2) / t;
% Author: Linan yao;
%% Assuming the Motor has been running;
function w = NXT_Demo_Speed_Measurer( Port );
         Theta1 = Port.ReadFromNXT.Position;
         t1 = clock;
         pause(5);
         Theta2 = Port.ReadFromNXT.Position;
         t2 = clock;
         w = (Theta2 - Theta1) / etime(t2,t1);