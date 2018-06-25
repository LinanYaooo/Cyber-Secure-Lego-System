%% Steering Close Loop Control
% Author: Linan Yao
% Based on RWTH - Mindstorms NXT Toolbox for MATLAB 
% Steering and being Steady at a Given Steering Angle;
%% Consider the LEGO NXT has already gotten initialised;
function temp = NXT_Demo_Steering_Control(Theta, SMotor)
SMotor.SpeedRegulation = 1;
SMotor.ResetPosition();
SMotor.TachoLimit = Theta;
SMotor.Power = 50;
SMotor.SendToNXT;
file = [];
t1 = clock;
temp = 0;
tstart = clock;
while 1
% pause(0.5)
Angle_real = SMotor.ReadFromNXT.Position;
Angle = Angle_real;
% if Angle == Theta
%     break;
% end
if abs(Angle_real)>60
    break;
end
t2 = clock;
t_delta = etime(t2,t1);
file = [file; t_delta Angle];
Theta_Delta = Theta - Angle;
SMotor.Power = sign( Theta_Delta )*50;
SMotor.TachoLimit = abs(Theta_Delta);
SMotor.SendToNXT;
t1 = clock;
end
tend = clock;
transient_response = etime(tend,tstart)
SMotor.Stop();


