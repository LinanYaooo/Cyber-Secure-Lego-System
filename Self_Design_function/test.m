% Based on RWTH - Mindstorms NXT Toolbox for mBTLAB 
% Steering and being Steady at a Given Steering Angle;
%% Consider the LEGO NXT has already gotten initialised;
Ref = 30;
mB.ResetPosition;
mB.SpeedRegulation = 0;
Theta = Ref;
pause(2)
t1 = clock;
file = [];
while true
current_angle = mB.ReadFromNXT.Position();
t2 = clock;
t_delta = etime(t2,t1);
file = [file; t_delta current_angle];
Error = Theta - current_angle;
if abs(Error) <= 2
    continue;
end
mB.TachoLimit = abs(Error);
mB.Power = sign(Error) * 50;
mB.SendToNXT;

end