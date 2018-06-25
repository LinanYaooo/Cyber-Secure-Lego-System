%% Function, Used to calculate a real angular velocity, by the knowledege of 
function omega = NXT_Demo_DrivingA_Corrector(theta, omega_mC)
R = 15.12; % half length of '' rear drive axle '';
L = 19.07;% Length of transmission shaft ;
if theta == 0
   k = 1;
else
    k = ((L/tand(abs(theta)) - R/2) / (L/tand(abs(theta)) + R/2));
end
if theta >= 0
   omega = omega_mC / k;
else
   omega = omega_mC * k;
end