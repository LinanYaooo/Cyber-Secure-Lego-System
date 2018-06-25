%% Function For Kalman filter;
%% Input value are the state vector, the measurements, Process covariance and 
%  Sampling Invertal, and a input value;
%  The output value are the Estimated output and the estimate state;
function [out_est, x, pre_y, pre_2y, pre_3y, Pk, residual] = NXT_Demo_Kalman_Motor3(in, x, y_mea, delta_t, Pk, pre_y,  pre_2y, pre_3y, mat)
%  First, find out proper dynamics based on the given delta_t;
sys_var = mat(char(string(delta_t)));
A = cell2mat(sys_var(1));
C = cell2mat(sys_var(3));
K = Pk * C' / (C * Pk * C');
x = A * x + [1; 0] * in;
out_est = (C * x + pre_y + pre_2y + pre_3y)/4;
residual = y_mea - out_est;
x = x + K * residual;
Pk = A * Pk * A + [25 0;0 0] - K * C * Pk * C' * K';
pre_3y = pre_2y;
pre_2y = pre_y;
pre_y = out_est;
end