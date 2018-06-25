%% Function For Kalman filter;
%% Input value are the state vector, the measurements, Process covariance and 
%  Sampling Invertal, and a input value;
%  The output value are the Estimated output and the estimate state;
function [out_est, x_est, Pk, residual] = NXT_Demo_Kalman_Motor(in, x, y_mea, delta_t, Pk, mat)
%  First, find out proper dynamics based on the given delta_t;
sys_var = mat(char(string(delta_t)));
A = cell2mat(sys_var(1));
C = cell2mat(sys_var(3));
%  Secondly, estimate the cureent output;
out_est = C * x;
%  TO estimate the next state;
x = A * x + [1; 0] * in;
K = Pk * C' / (C * Pk * C');
residual = y_mea - out_est;
x_est = x + K * residual;
Pk = A * Pk * A' + Pk - K * (C * Pk * C') * K';
end