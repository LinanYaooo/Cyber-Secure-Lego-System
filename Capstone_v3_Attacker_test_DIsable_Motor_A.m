%%%%%%%%%%%%%%%%%%%%%%%%%%%CYBER SECURE LINEAR SYSTEM %%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Hardware Simulation 1                              %     
%Close loop Driving Motor and Steering Control With Generalisation kalman filter%
% UPADTE:                                                                       %
%       This is a  Hardware Simulation for the whole project Testing, Risk Could%
%       happen result from unfixed sampling rate;                               %
%       Motor Initialization should be done in advance;                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mB.TachoLimit = 0;
mB.SpeedRegulation = 0;
mA.SpeedRegulation = 0;
mC.SpeedRegulation = 0;
%% Initialize the behaviour of Car;
theta = 30;                             % Initial outboard angular velocity, In degree/s; 
w_ref = 400;                              % Initial Steering Angle;
Duration = 60;                            % IN SECOND THE WHOLE SIMULATION DUARTION;
OpenSwitch(SENSOR_2);                     % Initialize Attacker Injection Switch;
load('Matrices_dic.mat');                 % Load the pre-derived state space matrices;
mat = Matrices_dic;                       % Assign 'mat' as the reference matrices dictionary;

%%%%%%%%%%%%%%%% CREATE THE JOYSTICK OBJECT FOR DRIVING CAR %%%%%%%%%%%%%%%%%%%%%%
joy = vrjoystick(1);                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reserve SIX factors for Steering PID controller;
%  For Steering Motor;
error_sum_mB = 0;
error_Pre_mB = 0;
%  For Right Driving Motor;
error_sum_mA = 0;
error_Pre_mA = 0;
%  For Left Driving Motor;
error_sum_mC = 0;
error_Pre_mC = 0;

%%  Reserve a variable for Attack Signal (software vulnerability);
attack_data_mB = 0;                      % Constant attack for Steering Motor;
attack_data_mA = 0;                       % Constant attack for Right Driving Motor;
attack_data_mC = 0;                       % Constant attack for Left Driving Motor;
Attack_FLAG = 0;
%%  Initialize System and Output Vectors;
x_mB = [0; 0];                            % Reserved for Steering State Vector;
y_mB = 0;                                 % Reserved for Steering Output;
x_mA = [0; 0];                            % Reserved for Right Driving State Vector;
y_mA = 0;                                 % Resetved for Right Driving Output;
x_mC = [0; 0];                            % Reserved for Left Driving Output;
y_mC = 0;                                 % Reserved for Left Driving Output;                         % Reserved for proecss noise;
Pk_A = [1^2 0; 0 0];            % Motor System Process noise Covariance Matrix;
Pk_B = [1^2 0; 0 0]; 
Pk_C = [1^2 0; 0 0]; 
R = 0;                                    % Measurement noise Covariance(default = 0);

% Reserve a Memory Space for plotting;
i = 1;                                    % ith Sample indicatior;
estimate_length = Duration / 0.01;
% For Steering Motor;
Pos_est_mB = zeros(1, estimate_length);   % Output angle amended by last measurement;
Pos_mea_mB = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mB = zeros(1, estimate_length);  % To record the real Motor Angle;

% For Right Driving Motor;
Pos_est_mA = zeros(1, estimate_length);   % Output angle amended by last measurement;
Pos_mea_mA = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mA = zeros(1, estimate_length);  % To record the real Motor Angle;

% For Left Driving Motor;
Pos_est_mC = zeros(1, estimate_length);   % Output angle amended by last measurement; 
Pos_mea_mC = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mC = zeros(1, estimate_length);  % To record the real Motor Angle;

Time_axis = zeros(1, estimate_length);    % For plotting;
Sampling_record = zeros(1, estimate_length); % For optimization, we need to check real sampling rate ;

mA_total = 0;
mC_total = 0;
% Dell is flag for attack detection;
dell_mB = zeros(1, estimate_length);      % Difference for Steering Motor between pre-estimate and measured value ;
dell_mA = zeros(1, estimate_length);      % Difference for Right Driving Motor between pre-estimate and measured value;
dell_mC = zeros(1, estimate_length);      % Difference for Left Driving Motor between pre-estimate and measured value;

% Initial Motor Input ;
mB.ResetPosition;                         % Reset the position of Motor;
mB.Power = 0;
mA.ResetPosition;                         % Reset the position of Motor;
mA.Power = 0;
mC.ResetPosition;                         % Reset the position of Motor;
mC.Power = 0;

u_mB = 0;
u_mA = 0;
u_mC = 0;

pre_y_mA = 0;
pre_2y_mA = 0;
pre_3y_mA = 0;
pre_y_mB = 0;
pre_3y_mB = 0;
pre_2y_mB = 0;
pre_y_mC = 0;
pre_3y_mC = 0;
pre_2y_mC = 0;
%% Navigation Start;

t_B_last_sample = 0;                        % Reserved for time of last sample;
t_A_last_sample = 0;
t_C_last_sample = 0;
tic;                                      % Record the time of Starting;

while true
    % Motor Speed controlled by Pressing 1 or 2 button
    %% Check the running time;
    t_end = toc;
    if t_end >= Duration
       break;                             % Stop navigation;
    end
    theta = -70 * axis(joy, 1);
    w_ref = -700 * axis(joy, 5); 
      
    %% Assign specific speed to Motor A and Motor C;
    if theta == 0
        wA_ref = w_ref;
        wC_ref = w_ref;
    elseif theta < 0
        [wA_ref, wC_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    else
        [wC_ref, wA_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    end
    
    %% Sensor_Reading_Iteration;
    y_real_mB = mB.ReadFromNXT.Position();% The real value of steering sensor reading; 
    t_B_sample = toc;
    y_real_mA = mA.ReadFromNXT.Position();% The real value of Right Seneor reading;
    t_A_sample = toc;
    y_real_mC = mC.ReadFromNXT.Position();% The real value of Left Sensor reading;
    t_C_sample = toc;                     % Time of a sampling;
    %% Press Button for Sensor 1 if there is an attacker.
    if GetSwitch(SENSOR_2)               % Introduced attacker if pressed;
         attack_data_mB = 40 ;                       
    else
         attack_data_mB = 0;
    end
    
    %% Computer the sampling duration and the dynamic system Martices;
    delta_B_t = round(t_B_sample - t_B_last_sample, 5);
    delta_A_t = round(t_A_sample - t_A_last_sample, 5);
    delta_C_t = round(t_C_sample - t_C_last_sample, 5);
    
    y_mea_mB = y_real_mB + attack_data_mB;% Steering Senesor attack;
    y_mea_mA = y_real_mA + attack_data_mA;% Right Motor Sensor attack;
    y_mea_mC = y_real_mC + attack_data_mC;% Left Motor Sensor attack;
    
    [y_mB, x_mB, pre_y_mB, pre_2y_mB,pre_3y_mB, Pk_B, residual_mB] = NXT_Demo_Kalman_Motor2(u_mB, x_mB, y_mea_mB, delta_B_t, Pk_B, pre_y_mB, pre_2y_mB, pre_3y_mB, mat);
    [y_mA, x_mA, pre_y_mA, pre_2y_mA,pre_3y_mA, Pk_A, residual_mA] = NXT_Demo_Kalman_Motor2(u_mA, x_mA, y_mea_mA, delta_A_t, Pk_A, pre_y_mA, pre_2y_mA, pre_3y_mA, mat);
    [y_mC, x_mC, pre_y_mC, pre_2y_mC,pre_3y_mC, Pk_C, residual_mC] = NXT_Demo_Kalman_Motor2(u_mC, x_mC, y_mea_mC, delta_C_t, Pk_C, pre_y_mC, pre_2y_mC, pre_3y_mC, mat);
   
    %% Check residual signal ------ is there any attack?
    if abs(residual_mB) >= 10
        Attack_FLAG = 1;
        toc
    end
    %% Make correction before get error signal;  
 %   if Attack_FLAG
 %       y_mea_mB = round();
 %   end
   
    mA_total = mA_total + wA_ref * delta_A_t;
    mC_total = mC_total + wC_ref * delta_C_t;
    [u_mB, error_Pre_mB, error_sum_mB] = NXT_Demo_PID(1, 0.02, 0.04, theta, y_mea_mB, error_Pre_mB, error_sum_mB);
    [u_mA, error_Pre_mA, error_sum_mA] = NXT_Demo_PID(0.75, 0, 0.05, mA_total, y_mea_mA, error_Pre_mA, error_sum_mA);
    [u_mC, error_Pre_mC, error_sum_mC] = NXT_Demo_PID(0.75, 0, 0.05, mC_total, y_mea_mC, error_Pre_mC, error_sum_mC);
    
    mB.Power = u_mB;
    mA.Power = u_mA;
    mC.Power = u_mC;
    
    mB.SendToNXT;
    mA.SendToNXT;
    mC.SendToNXT;
    
    
    %% Update the trajectories memories;
    Pos_est_mB(i) = y_mB;
    Pos_est_mA(i) = y_mA;
    Pos_est_mC(i) = y_mC;
    Pos_mea_mB(i) = y_mea_mB;
    Pos_mea_mA(i) = y_mea_mA;
    Pos_mea_mC(i) = y_mea_mC;
    Pos_real_mB(i) = y_real_mB;
    Pos_real_mA(i) = y_real_mA;
    Pos_real_mC(i) = y_real_mC;
    dell_mB(i) = residual_mB;
    dell_mA(i) = residual_mA;
    dell_mC(i) = residual_mC;
    %% Now for hardware part, we also need to calculate the input for next iteration, don't forget it's a CLOSE-LOOP control!
    Sampling_record(i) = delta_C_t;
    Time_axis(i) = t_C_sample;
    t_A_last_sample = t_A_sample;
    t_B_last_sample = t_B_sample;
    t_C_last_sample = t_C_sample;
    i = i + 1;                             % Indicator Auto-increat;
end
    %% Truncate the zeros part of all plotting components;
    Pos_est_mB = Pos_est_mB(1: i-1);
    Pos_mea_mB = Pos_mea_mB(1: i-1);
    Pos_real_mB = Pos_real_mB(1: i-1);
    Pos_est_mA = Pos_est_mA(1: i-1);
    Pos_mea_mA = Pos_mea_mA(1: i-1);
    Pos_real_mA = Pos_real_mA(1: i-1);
    Pos_est_mC = Pos_est_mC(1: i-1);
    Pos_mea_mC = Pos_mea_mC(1: i-1);
    Pos_real_mC = Pos_real_mC(1: i-1);
    dell_mB = dell_mB(1: i-1);
    dell_mA = dell_mA(1: i-1);
    dell_mC = dell_mC(1: i-1);
    Sampling_record = Sampling_record(1: i-1);
    Time_axis = Time_axis(1: i-1);
    
    %% When Simulation is over, plot each trajectory and check the mBtching degree.
    mB_reset = 0 - mB.ReadFromNXT.Position();
    mB.TachoLimit = abs(mB_reset);
    mB.Power = sign(mB_reset) * 20;
    mB.SendToNXT;
    pause(1.5);
    mB.Stop;
    mA.Stop;
    mC.Stop;
    close all;
    t = Time_axis;
    subplot(2,1,1);
    plot(t,Pos_est_mB,t,Pos_mea_mB,t,Pos_real_mB);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
    legend('est','mea','real');
    subplot(2,1,2);
    plot(t,dell_mB);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
    figure();
    subplot(2,1,1);
    plot(t,Pos_est_mA,t,Pos_mea_mA,t,Pos_real_mA);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
    legend('est','mea','real');
    subplot(2,1,2);
    plot(t,dell_mA);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
    figure();
    subplot(2,1,1);
    plot(t,Pos_est_mC,t,Pos_mea_mC,t,Pos_real_mC);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
    legend('est','mea','real');
    subplot(2,1,2);
    plot(t,dell_mC);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
toc