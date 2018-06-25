%% This script will compute out all possible sampling period of LEGO_NXT robot, ranging 0.005 : 0.0001 : 0.09; And will 
%  work out corresponding state space matrices for future call, in terms of
%  reducing complexity and saving running time;
%% Preparation;
function matrix_mat = NXT_Demo_Matrix_dictionary(start, precision, tend)  
Km =9.812 ; % V-to-ThetaDot motor model gain parameter (degrees/V.s) 
Tm = 0.055; % V-to-ThetaDot motor model time-constant (s
COL = tf([Km],[Tm 1 0]);  % open-loop controller = approx inverse of Km0/s*(Tm0 s + 1)
A = [0 0; 0 0];
B = [0 0]';
C = [0 0];
D = [0];
Matrices_dic = containers.Map(double(1),{A B C D});
Matrices_dic.remove(1);
h = waitbar(1,'In Progress');
for Ts = start : precision : tend
    waitbar(Ts/0.09,h,'In Progress' + string( Ts / 0.09 * 100) + '%')
COLdisc = c2d(COL,Ts,'zoh');         % time discretization of open-loop controller
[COLnum,COLden] = tfdata(COLdisc,'v');  % discrete transfer fnc numerator and denominator 
[A, B, C, D] = tf2ss(COLnum, COLden);
keys = {A B C D};
Matrices_dic(Ts) = keys;
end
close(h)
matrix_mat = Matrices_dic;
save('Matrices_dic.mat', 'Matrices_dic');
end