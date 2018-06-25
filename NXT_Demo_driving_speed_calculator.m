%% Simulation_Parameter_Edit_environment
% Before run experiment on lego robot, we can set up a SIMULINK model
% to Simulate the real experimemnt, and investigate the behaviour of 
% attacker and correcter.
% In this script, we will define some relevant parameters of the the ROBOT
% We've measured in advance and the necessary Transfer Function of the 
% Driving Motor and the Steering Motor, parameters can be altered at here
% for further purpose;
%% Start;
function [M_inner, M_outer] =  NXT_Demo_driving_speed_calculator(theta,Outboard_speed)
% Give Some Basic Specification of our LEGO Robot we assamblyed;
R = 15.12; % half length of '' rear drive axle '';
L = 19.07;% Length of transmission shaft ;
k = (L/tand(abs(theta)) - R/2)/(L/tand(abs(theta)) + R/2);
M_outer = Outboard_speed;
M_inner = M_outer * k;
end
