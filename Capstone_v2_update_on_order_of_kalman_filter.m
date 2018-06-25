%%%%%%%%%%%%%%%%%%%%%%%%%%%CYBER SECURE LINEAR SYSTEM %%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Hardware Simulation 1                              %     
%Close loop Driving Motor and Steering Control With Generalisation kalman filter%
% UPADTE:                                                                       %
%       This is a  Hardware Simulation for the whole project Testing, Risk Could%
%       happen result from unfixed sampling rate;                               %
%       Motor Initialization should be done in advance;                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize the behaviour of Car;
theta = - 60;                             % Initial outboard angular velocity, In degree/s; 
w_ref = 700;                              % Initial Steering Angle;
Duration = 10;                            % IN SECOND THE WHOLE SIMULATION DUARTION;
OpenSwitch(SENSOR_1);                     % Initialize Attacker Injection Switch;
load('Matrices_dic.mat');                 % Load the pre-derived state space matrices;
mat = Matrices_dic;                       % Assign 'mat' as the reference matrices dictionary;

%%%%%%%%%%%%%%%% CREATE THE JOYSTICK OBJECT FOR DRIVING CAR %%%%%%%%%%%%%%%%%%%%%%
joy = vrjoystick(1);                                                             %
controllerLibrary = NET.addAssembly([pwd ' \Joystick_Tools\SharpDX.XInput.dll']);%
myController = SharpDX.XInput.Controller(SharpDX.XInput.UserIndex.One);          %
VibrationLevel = SharpDX.XInput.Vibration;                                       %                                                                            %
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
attack_data_mA = 0;                     % Constant attack for Right Driving Motor;
attack_data_mC = 0;                     % Constant attack for Left Driving Motor;

%%  Initialize System and Output Vectors;
x_mB = [0; 0];                            % Reserved for Steering State Vector;
y_mB = 0;                                 % Reserved for Steering Output;
x_mA = [0; 0];                            % Reserved for Right Driving State Vector;
y_mA = 0;                                 % Resetved for Right Driving Output;
x_mC = [0; 0];                            % Reserved for Left Driving Output;
y_mC = 0;                                 % Reserved for Left Driving Output;                         % Reserved for proecss noise;
Pk_A = [1^2 0; 0 0];            % Motor System Process noise Covariance Matrix;
Pk_B = [5^2 0; 0 0]; 
Pk_C = [5^2 0; 0 0]; 
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
pre_y_mB = 0;
pre_y_mC = 0;
%% Navigation Start;
%t_B_last_sample = 0;                        % Reserved for time of last sample;
t_A_last_sample = 0;
%t_C_last_sample = 0;
tic;                                      % Record the time of Starting;

while true
    % Motor Speed controlled by Pressing 1 or 2 button
    %theta = -60 * axis(joy, 1);
    %w_ref = -800 * axis(joy, 3); 
    % theta_control = axis(joy, 1);
    % if theta_control == 1
    %     theta = theta - 5;
    % elseif theta_control == -1
    %     theta = theta + 5;
    % end
    % speed_control = axis(joy, 5);
    % if speed_control == 1
    %     w_ref = w_ref - 20;
    % elseif speed_control == -1
    %     w_ref = w_ref + 20;
    % end
    %% Assign specific speed to Motor A and Motor C;
    if theta == 0
        wA_ref = w_ref;
        wC_ref = w_ref;
    elseif theta < 0
        [wA_ref, wC_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    else
        [wC_ref, wA_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    end
    %% Check the running time;
    t_end = toc;
    if t_end >= Duration
       break;                             % Stop navigation;
    end
    %% Press Button for Sensor 1 if there is attacker.
   % if GetSwitch(SENSOR_1)               % Introduced attacker if pressed;
   %     Attack = attack_data;                       
   % else
   %     Attack = 0;
   % end
    
    %% Sensor_Reading_Iteration;
    y_real_mB = mB.ReadFromNXT.Position();% The real value of steering sensor reading; 
   % t_B_sample = toc;
    y_real_mA = mA.ReadFromNXT.Position();% The real value of Right Seneor reading;
    y_real_mC = mC.ReadFromNXT.Position();% The real value of Left Sensor reading;
    t_A_sample = toc;
   % t_C_sample = toc;                     % Time of a sampling;
    %% Computer the sampling duration and the dynamic system Martices;
   % delta_B_t = round(t_B_sample - t_B_last_sample, 6);
    delta_A_t = round(t_A_sample - t_A_last_sample, 6);
   % delta_C_t = round(t_C_sample - t_C_last_sample, 6);
    
    y_mea_mB = y_real_mB + attack_data_mB;% Steering Senesor attack;
    y_mea_mA = y_real_mA + attack_data_mA;% Right Motor Sensor attack;
    y_mea_mC = y_real_mC + attack_data_mC;% Left Motor Sensor attack;
    
    [y_mB, x_mB, pre_y_mB, Pk_B, residual_mB] = NXT_Demo_Kalman_Motor2(u_mB, x_mB, y_mea_mB, delta_A_t, Pk_B, pre_y_mB, mat);
    [y_mA, x_mA, pre_y_mA, Pk_A, residual_mA] = NXT_Demo_Kalman_Motor2(u_mA, x_mA, y_mea_mA, delta_A_t, Pk_A, pre_y_mA, mat);
    [y_mC, x_mC, pre_y_mC, Pk_C, residual_mC] = NXT_Demo_Kalman_Motor2(u_mC, x_mC, y_mea_mC, delta_A_t, Pk_C, pre_y_mC, mat);
    
    % if abs(residual) >= 10
    %    VibrationLevel.LeftMotorSpeed = 255^2;
    %    VibrationLevel.RightMotorSpeed = 255^2;
    %    attack_indicator = VibrationLevel.LeftMotorSpeed;
    %    myController.SetVibration(VibrationLevel); % If your controller supports vibration
    %    clf
    %elseif residual < -10
    %    VibrationLevel.LeftMotorSpeed = 0;
    %    VibrationLevel.RightMotorSpeed = 0;
    %    myController.SetVibration(VibrationLevel);
    %end
    
    mA_total = mA_total + wA_ref * delta_A_t;
    mC_total = mC_total + wC_ref * delta_A_t;
    [u_mB, error_Pre_mB, error_sum_mB] = NXT_Demo_PID(1, 0.01, 0.1, theta, y_mea_mB, error_Pre_mB, error_sum_mB);
    [u_mA, error_Pre_mA, error_sum_mA] = NXT_Demo_PID(1, 0, 0.001, mA_total, y_mea_mA, error_Pre_mA, error_sum_mA);
    [u_mC, error_Pre_mC, error_sum_mC] = NXT_Demo_PID(1, 0, 0.001, mC_total, y_mea_mC, error_Pre_mC, error_sum_mC);
    
    mB.Power = u_mB;
%    mA.Power = u_mA;
    mC.Power = u_mC
    
    mB.SendToNXT;
%    mA.SendToNXT;
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
    Sampling_record(i) = delta_A_t;
    Time_axis(i) = t_A_sample;
    t_A_last_sample = t_A_sample;
 %   t_B_last_sample = t_B_sample;
 %   t_C_last_sample = t_C_sample;
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