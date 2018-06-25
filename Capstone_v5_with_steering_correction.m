%%%%%%%%%%%%%%%%%%%%%%%%%%%CYBER SECURE LINEAR SYSTEM %%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Hardware Simulation 5                              %     
%Close loop Driving Motor and Steering Control With Generalisation kalman filter%
% UPADTE:                                                                       %
%       This is a Hardware Simulation for the whole project Testing, Risk Could%
%       happen result from unfixed sampling rate;                               %
%       Motor Initialization should be done in advance;                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of Motors;
mB.TachoLimit = 0;
mB.SpeedRegulation = 0;
mA.SpeedRegulation = 0;
mC.SpeedRegulation = 0;

%% Initialize the behaviour of Car;
theta = 30;                               % Initial outboard angular velocity, In degree/s; 
theta_pre = 0;                            % Condition for steering RLS algorithm;
theta_standby = 0;                        % Recursive value for RLS algoithm;
w_ref = 300;                              % Initial Steering Angle;
Duration = 30;                            % IN SECOND THE WHOLE SIMULATION DUARTION;
OpenSwitch(SENSOR_2);                     % Initialize Attacker Injection Switch;
load('Matrices_dic.mat');                 % Load the pre-derived state space matrices;
mat = Matrices_dic;                       % Assign 'mat' as the reference matrices dictionary;
%%CREATE THE JOYSTICK OBJECT FOR DRIVING CAR 
joy = vrjoystick(1);       

%% Reserve SIX factors for Steering PID controller;
%  For Steering Motor;
error_sum_mB = 0;                         % For integration control;
error_Pre_mB = 0;                         % For Differential contorl;
%  For Right Driving Motor;
error_sum_mA = 0;
error_Pre_mA = 0;
%  For Left Driving Motor;
error_sum_mC = 0;
error_Pre_mC = 0;

%%  Reserve a variable for Attack Signal (software vulnerability);
attack_data_mB = 0;                       % Constant attack for Steering Motor;
attack_data_mA = 0;                       % Constant attack for Right Driving Motor;
attack_data_mC = 0;                       % Constant attack for Left Driving Motor;
Attack_FLAG = 0;                          % Indication of Apperance of attack;

%%  Initialize System and Output Vectors;
x_mB = [0; 0];                            % Reserved for Steering State Vector;
y_mB = 0;                                 % Reserved for Steering Output;
x_mA = [0; 0];                            % Reserved for Right Driving State Vector;
y_mA = 0;                                 % Resetved for Right Driving Output;
x_mC = [0; 0];                            % Reserved for Left Driving Output;
y_mC = 0;                                 % Reserved for Left Driving Output;
X = [x_mA, x_mB, x_mC];
Y = [y_mA, y_mB, y_mC];
Pk = [5^2 0; 0 0];                        % Motor System Process noise Covariance Matrix;


% Reserve a Memory Space for plotting;
i = 1;                                    % ith Sample indicatior;
k = 0;                                    % k for RLS in steering data reconstruction;
estimate_length = Duration / 0.01;

% For Steering Motor;
Pos_est_mB = zeros(1, estimate_length);   % Output angle amended by last measurement;
Pos_mea_mB = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mB = zeros(1, estimate_length);  % To record the real Motor Angle;
angle_ref = zeros(1, estimate_length);
Attack_error_mB = 0;
Attack_error_sum_mB = 0;
Attack_FLAG_pre_mB = 0;
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
U = [u_mA, u_mB, u_mC];

pre_y = [0 0 0];
pre_2y = [0 0 0];
pre_3y = [0 0 0];

pre_y_mB = 0;
pre_3y_mB = 0;
pre_2y_mB = 0;

pre_y_mC = 0;
pre_3y_mC = 0;
pre_2y_mC = 0;

%% Navigation Start;
y_A_last_mea = 0;
y_C_last_mea = 0;
t_last_sample = 0;
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
    angle_ref(i) = theta;

      
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
    y_real_mA = mA.ReadFromNXT.Position();% The real value of Right Seneor reading;
    y_real_mC = mC.ReadFromNXT.Position();% The real value of Left Sensor reading;
    t_sample = toc;                     % Time of a sampling;
    %Computer the sampling duration and the dynamic system Martices;  
    delta_t = round(t_sample - t_last_sample, 5);
    
    %% Active Steering Sensor Attack & Injecting false data.
    if button(joy,6)               % Introduced attacker if pressed;
         attack_data_mB = 40 ;                       
    elseif button(joy,5)
         attack_data_mB = 20;
    else
         attack_data_mB = 0;
    end    
    %% Format the measurement Matrix and run Kalman estimation;
    y_mea = [y_real_mA + attack_data_mA, y_real_mB + attack_data_mB, y_real_mC + attack_data_mC]; 
    %  Get System Matrix by refering to the dictionary;
    sys_var = mat(char(string(delta_t)));
    A = cell2mat(sys_var(1));
    C = cell2mat(sys_var(3));
    %  Update New state and Output;
    X = A * X + [1;0] * U;
    Y = ( C * X + pre_y + pre_2y + pre_3y) / 4;
    residual = y_mea - Y;
    dell_mB(i) = residual(2);
    %% We get the residual signal, we can now detect attack;
    %  Part1 : For Detecting the attack of Steering Sensor;
    %  Senor of Steering Motor Will be attack by a constant attacker;
    %  Kalman filter can trigger an alarm, two Driving motor associated
    %  with a RLS filter will derive the real output of the sensor, 
    if residual(2) > 10
        Attack_FLAG = 1;
    else 
        Attack_FLAG = 0;
    end
    omega_mA = (y_mea(1) - y_A_last_mea)/delta_t;
    omega_mC = (y_mea(3) - y_C_last_mea)/delta_t;
    
    theta_standby = theta_standby +  2 * 0.25 * (NXT_Demo_Steering_Corrector(omega_mA, omega_mC) - theta_standby);
    theta_pre = theta;
        Attack_error_mB = y_mea(2) - theta_standby;
   if Attack_FLAG
        if Attack_FLAG_pre == 0
            Attack_error_sum_mB = 0;
            k = 0;
        end
        if theta == theta_pre
            k = k + 1;
        else
            k = 1;
            Attack_error_sum_mB = 0;
        end
        Attack_error_sum_mB = Attack_error_sum_mB + Attack_error_mB;
        Attack_error_mB = Attack_error_sum_mB / k
        y_mea(2) = y_mea(2) - Attack_error_mB;
        residual(2) = y_mea(2) - Y(2); 
    end
    Attack_FLAG_pre = Attack_FLAG;
    theta_pre = theta;
    K = Pk * C' / (C * Pk * C');
    X = X + K * residual;
    Pk = A * Pk * A + [25 0; 0 0] - K * C * Pk * C' * K';
    pre_3y = pre_2y;
    pre_2y = pre_y;
    pre_y = Y;


    mA_total = mA_total + wA_ref * delta_t;
    mC_total = mC_total + wC_ref * delta_t;
    [u_mB, error_Pre_mB, error_sum_mB] = NXT_Demo_PID(1, 0.025, 0.04, theta, y_mea(2), error_Pre_mB, error_sum_mB);
    [u_mA, error_Pre_mA, error_sum_mA] = NXT_Demo_PID(0.75, 0, 0.05, mA_total, y_mea(1), error_Pre_mA, error_sum_mA);
    [u_mC, error_Pre_mC, error_sum_mC] = NXT_Demo_PID(0.75, 0, 0.05, mC_total, y_mea(3), error_Pre_mC, error_sum_mC);
    U = [u_mA, u_mB, u_mC];
    
    mB.Power = u_mB;
    mA.Power = u_mA;
    mC.Power = u_mC;
    
    mB.SendToNXT;
    mA.SendToNXT;
    mC.SendToNXT;
    
    
    %% Update the trajectories memories;
    Pos_est_mB(i) = Y(2);
    Pos_est_mA(i) = Y(1);
    Pos_est_mC(i) = Y(3);
    Pos_mea_mB(i) = y_mea(2);
    Pos_mea_mA(i) = y_mea(1);
    Pos_mea_mC(i) = y_mea(3);
    Pos_real_mB(i) = y_real_mB;
    Pos_real_mA(i) = y_real_mA;
    Pos_real_mC(i) = y_real_mC;

    dell_mA(i) = residual(1);
    dell_mC(i) = residual(3);
    %% Now for hardware part, we also need to calculate the input for next iteration, don't forget it's a CLOSE-LOOP control!
    Sampling_record(i) = delta_t;
    Time_axis(i) = t_sample;
    t_last_sample = t_sample;
    y_A_last_mea = y_mea(1);
    y_C_last_mea = y_mea(3);
    i = i + 1;                             % Indicator Auto-increat;
end
    %% Truncate the zeros part of all plotting components;
    angle_ref = angle_ref(1: i -1);
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
    plot(t,Pos_est_mB,t,Pos_mea_mB,t,Pos_real_mB, t,angle_ref);
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