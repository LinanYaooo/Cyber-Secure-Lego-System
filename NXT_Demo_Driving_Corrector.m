%% Function, Used to calculate a real angular velocity, by the knowledege of 
%  Steering angle and the other angular velocity;
function omega = NXT_Demo_Driving_Corrector(theta, omega_other, Attack_FLAG)
R = 15.12; % half length of '' rear drive axle '';
L = 19.07;% Length of transmission shaft ;
k = ((L/tand(abs(theta)) - R/2)/(L/tand(abs(theta)) + R/2));
if theta >= 0 && Attack_FLAG(1) == 1
    omega = omega_other / k;
elseif theta < 0 && Attack_FLAG(1) == 1
    omega = omega_other * k;
elseif theta >= 0 && Attack_FLAG(3) == 1
    omega = omega_other * k;
elseif theta < 0 && Attack_FLAG(3) == 1
    omega = omega_other / k;
end
end