%%%%%%%%%%%%%%%%%%%%%%%%%%%CYBER SECURE LINEAR SYSTEM %%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Hardware Simulation 6                              %     
%                 Close loop Driving Motor and Steering Control                 %
%    Attacker can injects Square wave data to steering Motor, and a Driving     %
%    Motor false data whiach has linear relationship with the real_time         %
%    Angle Measurements. The system output estimatior can estimate an           %
%    output with previous information. By conpare the deviation between         %
%    estimation and measurement. Attack detection alarm can be triggered        %
%    when the deviation is larger than a preset threshold. The threshold is     %
%    obtained by experiment and concluded as a reasonable value containing      %
%    the information of the tolerant error that will not influence the          %
%    navigation of robot. Corrupted sensor will be replaced by the combined     %
%    redundancy data which is from the sensors that are not being attacked.     %
%    The corrputed sensor can be reactived when the measurement is same with    %
%    the estimation again.                                                      %
% UPADTE:                                                                       %
%       This is a Hardware Simulation for the whole project Testing, Risk Could %
%       happen result from unfixed sampling rate;                               %
%       Motor Initialization should be done in advance;                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of Motors;
mB.TachoLimit = 0;
mA.TachoLimit = 0;
mC.TachoLimit = 0;
mB.SpeedRegulation = 0;
mA.SpeedRegulation = 0;
mC.SpeedRegulation = 0;

%% Initialize the behaviour of Car;
theta = 0;                                % Initial outboard angular velocity, In degree/s; 
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
Attack_FLAG = [0 0 0];                    % Indication of Apperance of attack;

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
y_test = zeros(1, estimate_length);
Pos_est_mB = zeros(1, estimate_length);   % Output angle amended by last measurement;
Pos_mea_mB = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mB = zeros(1, estimate_length);  % To record the real Motor Angle;
angle_ref = zeros(1, estimate_length);
Attack_error_mB = 0;
Attack_error_sum_mB = 0;
Attack_FLAG_pre_mB = 0;

% For Right Driving Motor;
omega_mA = 0;                             % Initialzie angular velocity;
Pos_est_mA = zeros(1, estimate_length);   % Output angle amended by last measurement;
Pos_mea_mA = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mA = zeros(1, estimate_length);  % To record the real Motor Angle;
w_mA = zeros(1, estimate_length);

% For Left Driving Motor;
omega_mC = 0;                             % Initialzie angular velocity;
Pos_est_mC = zeros(1, estimate_length);   % Output angle amended by last measurement; 
Pos_mea_mC = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Pos_real_mC = zeros(1, estimate_length);  % To record the real Motor Angle;

Time_axis = zeros(1, estimate_length);    % For plotting;
Sampling_record = zeros(1, estimate_length); % For optimization, we need to check real sampling rate ;
mA_total = zeros(1, estimate_length);
mC_total = zeros(1, estimate_length);

%% Dell is deviation between measurement and estimation;
dell_mB = zeros(1, estimate_length);      % Difference for Steering Motor between pre-estimate and measured value ;
dell_mA = zeros(1, estimate_length);      % Difference for Right Driving Motor between pre-estimate and measured value;
dell_mC = zeros(1, estimate_length);      % Difference for Left Driving Motor between pre-estimate and measured value;

%% Initial Motor Input ;
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

%% Store 3 previous measurements for Smoothing the Estimation; 
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
t_last_sample = 0;
tic;                                      % Record the time of Starting;

while true
    % Motor Speed controlled by Pressing 1 or 2 button
    %% Check the running time;
    t_end = toc;
    if t_end >= Duration
       break;                             % Stop navigation;
    end
    theta = -60 * axis(joy, 1);
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
    t_sample = toc;                       % Time of a sampling;
    %Computer the sampling duration and the dynamic system Martices;  
    delta_t = round(t_sample - t_last_sample, 5);
    
    %% Active Steering Sensor Attack & Injecting false data.
    if button(joy,6)                      % Introduced attacker if pressed;
         attack_data_mB = 40 ;                       
    elseif button(joy,5)
         attack_data_mB = 60;
    else
         attack_data_mB = 0;
    end     
    if button(joy,1)
        attack_data_mC = y_real_mC * 0.1;  % The threshold of driving motor is set to be 1/50 of current
        attack_data_mC > pre_y(3) * 0.02;
    else
        attack_data_mC = 0;
    end  
    if button(joy,2)
        attack_data_mA = y_real_mA * 0.1;
    else
        attack_data_mA = 0;
    end
    
    %% Format the measurement Matrix and run Kalman estimation;
    %  The following Statement shows the software vulnerability which
    %  attacker can stealthes and injects false data.
    y_mea = [y_real_mA + attack_data_mA, y_real_mB + attack_data_mB, y_real_mC + attack_data_mC]; 
    
    %%  Get System Matrix by refering to the dictionary;
    sys_var = mat(char(string(delta_t)));
    A = cell2mat(sys_var(1)); 
    C = cell2mat(sys_var(3));
    
    %%  Update New state and Output;
    X = A * X + [1;0] * U;
    Y(1) = 0.1 * C * X(:,1) + 0.3*  pre_y(1) + 0.3* pre_2y(1) +  0.3 * pre_3y(1);
    Y(2) = 0.4 * C * X(:,2) + 0.3*  pre_y(2) + 0.2* pre_2y(2) +  0.1 * pre_3y(2);
    Y(3) = 0.1 * C * X(:,3) + 0.3*  pre_y(3) + 0.3* pre_2y(3) +  0.3 * pre_3y(3);
    residual = y_mea - Y;
    dell_mB(i) = residual(2);
    dell_mC(i) = residual(3);
    %w_mA(i) = (Y(1) - pre_y(1))/delta_t;
    
    %% We get the residual signal, we can now detect attack;
    %  Part1 : For Detecting the attack of Steering Sensor;
    %  Senor of Steering Motor Will be attack by a constant attacker;
    %  Kalman filter can trigger an alarm, two Driving motor associated
    %  with a LMS filter will derive the real output of the sensor.
    
    %% Driving Motor Threshold value;
    if abs(residual(3)) > abs( pre_y(3) * 0.05 ) && abs(pre_y(3)) > 360
        Attack_FLAG(3) = 1;
       else
        Attack_FLAG(3) = 0;
    end
    
    if abs(residual(1)) > abs( pre_y(1) * 0.05 ) && abs(pre_y(1)) > 360
        Attack_FLAG(1) = 1;
    else
        Attack_FLAG(1) = 0;
    end
    %% Steering Motor Threshold value;
    if residual(2) > 10
        Attack_FLAG(2) = 1;
    else 
        Attack_FLAG(2) = 0;
    end
    
    %% Shut done the system if attacker appears at two or more sensors;
% %     if sum(Attack_FLAG) >=2
% %         break;
% %     end
    
    %% LMS Algorithm on deriving the real-time Angular velocity of Driving Motors;
    if i == 1 || i == 2
        omega_mA = omega_mA + 2 * 0.6 * ((y_mea(1) - pre_3y(1)) / delta_t);
        omega_mC = omega_mC + 2 * 0.6 * ((y_mea(3) - pre_3y(3)) / delta_t);
    else
        omega_mA = omega_mA + 2 * 0.5 * ((y_mea(1) - pre_3y(1)) / (delta_t + Sampling_record(i - 1)+ Sampling_record(i - 2) ) - omega_mA);
        omega_mC = omega_mC + 2 * 0.5 * ((y_mea(3) - pre_3y(3)) / (delta_t + Sampling_record(i - 1)+ Sampling_record(i - 2) ) - omega_mC);
    end
    %% Driving Motor A correction;
    y_test(i) = pre_y(3) + delta_t * NXT_Demo_DrivingC_Corrector(y_mea(2), omega_mA);
    if Attack_FLAG(1)
        omega_mA = NXT_Demo_DrivingA_Corrector(y_mea(2), omega_mC);
        y_mea(1) = pre_y(1) + delta_t * omega_mA;
        residual(1) = y_mea(1) - Y(1);
    end
    %% Driving Motor C correction;    
    if Attack_FLAG(3)
        omega_mC = NXT_Demo_DrivingC_Corrector(y_mea(2), omega_mA);
        y_mea(3) = pre_y(3) + delta_t * omega_mC;
        residual(3) = y_mea(3) - Y(3);
    end
    
    %% Compute the Steering information based on the two driving Motors
    theta_standby = theta_standby +  2 * 0.1 * (NXT_Demo_Steering_Corrector(omega_mA, omega_mC) - theta_standby);
    theta_pre = theta;
    Attack_error_mB = y_mea(2) - theta_standby;  
    
    %% Correction of Steering Motor;
    if Attack_FLAG(2)
        if Attack_FLAG2_pre == 0
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
        Attack_error_mB = Attack_error_sum_mB / k;
        y_mea(2) = y_mea(2) - Attack_error_mB;
        residual(2) = y_mea(2) - Y(2); 
    end
    Attack_FLAG2_pre = Attack_FLAG(2);
    theta_pre = theta;
    
    %% Update the Kalman estimatior;
    K = Pk * C' / (C * Pk * C' + 1);
    X = X + K * residual;
    Pk = A * Pk * A + [25 0; 0 0] - K * C * Pk * C' * K';
    pre_3y = pre_2y;
    pre_2y = pre_y;
    pre_y = y_mea;

    %% Proceed to PID Control;
    if i == 1
        mA_total(i) = mA_total(i) + wA_ref * delta_t;
        mC_total(i) = mC_total(i) + wC_ref * delta_t;
    else
        mA_total(i) = mA_total(i-1) + wA_ref * delta_t;
        mC_total(i) = mC_total(i-1) + wC_ref * delta_t;
    end
    [u_mB, error_Pre_mB, error_sum_mB] = NXT_Demo_PID(0.8, ~Attack_FLAG(2) * 0.01, 0.04, theta, y_mea(2), error_Pre_mB, error_sum_mB);
    [u_mA, error_Pre_mA, error_sum_mA] = NXT_Demo_PID(0.5, 0, 0.1, mA_total(i), y_mea(1), error_Pre_mA, error_sum_mA);
    [u_mC, error_Pre_mC, error_sum_mC] = NXT_Demo_PID(0.5, 0, 0.1, mC_total(i), y_mea(3), error_Pre_mC, error_sum_mC);
    U = [u_mA, u_mB, u_mC];             % Update the value out of Controller;
    mB.Power = u_mB;
    mA.Power = u_mA;
    mC.Power = u_mC;                    % Engage the new control signal;
    mB.SendToNXT;
    mA.SendToNXT;
    mC.SendToNXT;
    
    %% Update the trajectories Information;
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
    %% Now for hardware part, we also need to calculate the input for next iteration, don't forget it's a CLOSE-LOOP control!
    Sampling_record(i) = delta_t;
    Time_axis(i) = t_sample;
    t_last_sample = t_sample;
    i = i + 1;                             % Indicator Auto-increat;
end
    %% Truncate the zeros part of all plotting components;
    mA_total = mA_total(1:i-1);
    mC_total = mC_total(1:i-1);
    y_test = y_test(1 : i-1);
    %w_mA = w_mA(1:i -1);
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
    plot(t, dell_mA ./ Pos_est_mA);
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
    plot(t, dell_mC ./ Pos_est_mC);
    grid;
    xlabel('Time(sec)');
    ylabel('Position(Degree)');
toc