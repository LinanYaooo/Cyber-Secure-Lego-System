%% Simulation_Parameter_Edit_environment
% Before run experiment on lego robot, we can set up a SIMULINK model
% to Simulate the real experimemnt, and investigate the behaviour of 
% attacker and correcter.
% In this script, we will define some relevant parameters of the the ROBOT
% We've measured in advance and the necessary Transfer Function of the 
% Driving Motor and the Steering Motor, parameters can be altered at here
% for further purpose;
%% Start;
function Inner_speed =  NXT_Demo_Speed_ratio(theta,Outboard_speed)
% Give Some Basic Specification of our LEGO Robot we assamblyed;
r = 15.12; % half length of '' rear drive axle '';
L = 19.07;% Length of transmission shaft ;
error = 2.25;
%R = 2.12; % Radius of each Wheel ;
% Reference Steering Angle and Angular Speed of Outside Spinning Wheel;
% By the two given condition above we can therefore calculate the inner 
% Spinning wheel's angular speed, which is derived by the ratio k;
if theta == 0
    k = 1;
else
k = (L/tand(abs(theta)) - error)/(L/tand(abs(theta)) - error + r);
end
% Where we can conclude the anglular speed of inner wheel is;
Inner_speed = Outboard_speed * k ;
end
