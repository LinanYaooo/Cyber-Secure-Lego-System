%% LEGO_NXT_INITIALIZATION_PROGRAM
%% TASK
% 1.Set up the USB connection between USB and Matlab;
% 2.Enable three Motors;
% 3.Deactive the Speedregulation mode of motor;
%% Start
function [mA, mB, mC] = NXT_Demo_Initialise()
%% First Set up the USB connection;
COM_CloseNXT all;
h = COM_OpenNXT();
COM_SetDefaultNXT(h);
%% Enable Three Motor A B and C;
% Deactive SpeedRegulation Mode to to have a constant torque
% And Initialise the distance to 0 of each motor;
mA = NXTMotor('A');
mA.SpeedRegulation = 0; 
mA.ResetPosition();
mB = NXTMotor('B');
mB.SpeedRegulation = 0;
mB.ResetPosition();
mC = NXTMotor('C');
mC.SpeedRegulation = 0;
mC.ResetPosition();
% Beep when connection finish;
NXT_PlayTone(440, 500);
NXT_PlayTone(940, 500);
end