%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MK3 CAPSTONE PROJECT MATLAB CODE   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialize the behaviour of Car;
theta = 10;                              % Initial outboard angular velocity, In degree/s; 
theta_standby = 0;                       % LMS algoithm for extrating the redundancy steering angle;
right_standby = 0;                       % LMS for right driving motor;
left_standby = 0;                        % LMS for left driving motor;
w_ref = 0;                             % Initial Steering Angle;
Duration = 20;                           % Define how long enables the navigation;
load('Matrices_dic_driving.mat');        % Load the pre-derived state space matrices;
mat_driving = Matrices_dic_driving;      % Assign 'mat' as the reference matrices dictionary for driving motor;
load('Matrices_dic_steering.mat');       % Dictionary for steering motor;
mat_steering = Matrices_dic_steering;

%% Threshold Value                   
thre_steering = 10;                      % Define the detection threshold of steering subsystem;
thre_driving = 10;                       % Define the detection threshold of driving subsystem;
joy = vrjoystick(1);                     % Enable the gamppad controlling method;

%% Reserve SIX factors for Steering PID controller;
% Sun of all error history for integral control;
% Record previous one error for diffreential control;
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
attack_data_mB = 0;                       % Constant attack for Steering Motor;
attack_data_mA = 0;                       % Constant attack for Right Driving Motor;
attack_data_mC = 0;                       % Constant attack for Left Driving Motor;
Attack_FLAG = [0 0 0];                    % Indication of Apperance of attack;
pre_Attack_FLAG = [0 0 0];                % Previous flag of Attack_FLAG;
error = [0 0 0];                          % Record the innovation signal;
benchmark = [0 0 0];                      % One component in data reconstruction;
attack_benchmark = [0 0 0];               % The other component in data reconstruction;
signal_change = [0 0 0];                  % Record change of sensor measurement during attack period;

%%  Initialize System and Output Vectors;
x_mB = [0; 0];                            % Reserved for Steering State Vector;
y_mB = 0;                                 % Reserved for Steering Output;
y_mA = 0;                                 % Resetved for Right Driving Output;
y_mC = 0;                                 % Reserved for Left Driving Output;
Y = [y_mA, y_mB, y_mC];                   % The process noise of driving modoel;
Pk = [5^2 0; 0 0];                        % Steering Motor Process noise Covariance Matrix;
R = 1/12;                                 % Measurement noise covariance;
pre_residual = [0 0 0];                  
%% Reserve the Memory Space for plotting;
i = 1;                                    % ith Sample indicatior;
estimate_length = Duration / 0.01;        % Pre-compute how much samples are needed;

K_G = [];                                 % Kalman Gain;
steering_sub = zeros(1, estimate_length);
% For Steering Motor;
Ang_est_mB = zeros(1, estimate_length);   % Output angle amended by last measurement;
Ang_mea_mB = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Ang_real_mB = zeros(1, estimate_length);  % To record the real Motor Angle;
Steering_Ref = zeros(1, estimate_length); % Record history of reference signal for steering system;

attack_alarm = zeros(1, estimate_length); 

% For Right Driving Motor;
omega_mA = 0;                             % Initialzie angular velocity;
Ang_est_mA = zeros(1, estimate_length);   % Output angle amended by last measurement;
Ang_mea_mA = zeros(1, estimate_length);   % Output angle Measured By Sensor;
Ang_real_mA = zeros(1, estimate_length);  % To record the real Motor Angle;
mA_total = zeros(1, estimate_length);      % Record history of reference signal right driving motors;

% For Left Driving Motor;
omega_mC = 0;                               % Initialzie angular velocity;
Ang_est_mC = zeros(1, estimate_length);     % Output angle amended by last measurement; 
Ang_mea_mC = zeros(1, estimate_length);     % Output angle Measured By Sensor;
Ang_real_mC = zeros(1, estimate_length);    % To record the real Motor Angle;
mC_total = zeros(1, estimate_length);       % Record history of reference signal of left driving;


Time_axis = zeros(1, estimate_length);       % For plotting;
Sampling_record = zeros(1, estimate_length); % For optimization, we need to check real sampling rate ;

%% Dell is deviation between measurement and estimation;
dell_mB = zeros(1, estimate_length);      % Difference for Steering Motor between pre-estimate and measured value ;
dell_mA = zeros(1, estimate_length);      % Difference for Right Driving Motor between pre-estimate and measured value;
dell_mC = zeros(1, estimate_length);      % Difference for Left Driving Motor between pre-estimate and measured value;
dell_steering_tst = zeros(1, estimate_length);
%% Initial Motor Input ;
mB.ResetPosition;                         % Reset the position of Motor;
mB.Power = 0;                             % Initial input 0
mA.ResetPosition;                         % Reset the position of Motor;
mA.Power = 0;                             % Initial input 0
mC.ResetPosition;                         % Reset the position of Motor;
mC.Power = 0;                             % Initial input 0
u_mB = 0;
u_mA = 0;
u_mC = 0;

%% Store 3 previous measurements for Smoothing the Estimation; 
pre_y = [0 0 0];                       
pre_2y = [0 0 0];
pre_3y = [0 0 0];

%% Navigation Start;
t_last_sample = 0;                  % Set for calculating sampling interval
tic;                                % Record the time of Starting;

while true
    FlushEvents();
    [Keydown,sec,keycode,deltases]=KbCheck(-1);
    if Keydown == 1
        pressed = find(keycode);
        if pressed < 70
        attack_data_mB = 10 * (find(keycode) - 53);
        else
        attack_data_mC = 1000 *(find(keycode) - 100); 
        end
    else
        attack_data_mB = 0;
        attack_data_mC = 0;
    end
    %% Check the running time;
    t_end = toc;
    if t_end >= Duration
       break;                       % Stop navigation if time is reached;
    end
   theta = -60 * axis(joy, 1);      % Control the steering angle
   w_ref = -600 * axis(joy, 5);     % Control the speed
   Steering_Ref(i) = theta;         % Record steering angle;

    if theta == 0                   % Ensure which driving motor is the outside/inside;
        wA_ref = w_ref;
        wC_ref = w_ref;
    elseif theta < 0
        [wA_ref, wC_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    else
        [wC_ref, wA_ref] = NXT_Demo_driving_speed_calculator(theta, w_ref);
    end
    
    %% Sensor_Reading_Iteration;
    y_real_mB = mB.ReadFromNXT.Position();  % The real value of steering sensor reading; 
    y_real_mA = mA.ReadFromNXT.Position();  % The real value of Right Seneor reading;
    y_real_mC = mC.ReadFromNXT.Position();  % The real value of Left Sensor reading;
    
    %Computer the sampling duration and the dynamic system Martices;  
    t_sample = toc;                               % Time of a sampling;
    delta_t = round(t_sample - t_last_sample, 5); % Sampling interval
    
%     
%     if t_end > 5 && t_end < 10
%         attack_data_mB = 30;
%     elseif t_end > 15 && t_end < 20
%         attack_data_mB = 40;
%     else 
%         attack_data_mB = 0;
%     end
%     
%     
    
    
    %% Active Steering & Driving Sensor Attack & Injecting false data.
%     if button(joy,1)                        % Introduced attacker if pressed;
%          attack_data_mB = 20 ;                       
%     elseif button(joy,2)
%          attack_data_mB = -40;
%     elseif button(joy,3)
%          attack_data_mB = 60;
%     elseif button(joy,4)
%          attack_data_mB = -80;
%     end   

    %% Format the measurement Matrix and run Kalman estimation;
    %  The following Statement shows the software vulnerability which
    %  attacker can stealthes and injects false data.
    y_mea = [y_real_mA + attack_data_mA, y_real_mB + attack_data_mB, y_real_mC + attack_data_mC]; 
    y_mea_fake = y_mea;
    
    %%  Get System Matrix by refering to the dictionary;
    % For steering
    % motor;
    sys_steering = mat_steering(char(string(delta_t)));
    A_s = cell2mat(sys_steering(1)); 
    C_s = cell2mat(sys_steering(3));
    
    % For dirving motor;
    sys_driving =  mat_driving(char(string(delta_t)));
    A_d = cell2mat(sys_driving(1)); 
    C_d = cell2mat(sys_driving(3)); 

    %% Kalman filtering step 1
    %  Update New state and Output;
    %  
    x_mB = A_s * x_mB + [1;0] * u_mB;
    K_s = A_s * Pk * C_s' / (C_s * Pk * C_s' + R);
    x_mB = x_mB + K_s * pre_residual(2);
    Pk = A_s * Pk * A_s' + [5^2 0; 0 0] - K_s *( C_s * Pk * C_s' + R)* K_s';
    Steering_tst = C_s * x_mB;
    Y(2) = 0.25 * Steering_tst +  0.25 * pre_y(2) + 0.25 * pre_2y(2) +  0.25 * pre_3y(2);
    
%   K_G(i)=K_s; % Store the Kalman gain;
    Y(1) = 8.725 * delta_t * u_mA + pre_y(1); 
    Y(3) = 8.725 * delta_t * u_mC + pre_y(3);
    
    %  Get the innovation signal;
    residual = y_mea - Y;
    steering_inno = y_mea(2) - Steering_tst;
    %  LMS estimation of innovation attack; 
    error(1) = error(1) + 2 * 0.5 * (residual(1) - error(1));
    error(2) =residual(2);% error(2) + 2 * 0.3 * (residual(2) - error(2));
    error(3) = error(3) + 2 * 0.5 * (residual(3) - error(3));
    % Record the innovation;
    dell_mA(i) = error(1);
    dell_mB(i) = error(2);
    dell_mC(i) = error(3);
    dell_steering_tst(i) = steering_inno;
    %% LMS Algorithm on deriving the real-time Angular velocity of Driving Motors;
    if i == 1 || i == 2
        omega_mA = omega_mA + 2 * 0.5 * ((y_mea(1) - pre_3y(1)) / delta_t);
        omega_mC = omega_mC + 2 * 0.5 * ((y_mea(3) - pre_3y(3)) / delta_t);
    else
        omega_mA = omega_mA + 2 * 0.1 * ((y_mea(1) - pre_3y(1)) / (delta_t + Sampling_record(i - 1)+ Sampling_record(i - 2)) - omega_mA);
        omega_mC = omega_mC + 2 * 0.1 * ((y_mea(3) - pre_3y(3)) / (delta_t + Sampling_record(i - 1)+ Sampling_record(i - 2)) - omega_mC);
    end
    
    %% Compute the Reduandant substitution for each motor;
    
    % Substitution angle ofor steering motor;
    theta_standby = theta_standby +  2 * 0.8 * (NXT_Demo_Steering_Corrector(omega_mA, omega_mC) - theta_standby);  
    
    steering_sub(i) = pre_y(2);
    
    % For driving motors, the redundant substitutions are given as angular velocity; 
    right_standby = right_standby + 2 * 0.3 * (NXT_Demo_DrivingA_Corrector(y_mea(2), omega_mC) - right_standby);
    left_standby = left_standby + 2 * 0.3 * (NXT_Demo_DrivingC_Corrector(y_mea(2), omega_mA) - left_standby);
    
    %Driving_Motor_Right_Detection
    if abs(residual(1)) > thre_driving
       Attack_FLAG(1) = 1;
       if pre_Attack_FLAG(1) == 0
          attack_benchmark(1) = y_mea(1);
          benchmark(1) = pre_y(1) + right_standby * delta_t;
       end
    else
          Attack_FLAG(1) = 0;
    end
 
    % Detection for LEFT Motor 
    if abs(residual(3)) > thre_driving
       Attack_FLAG(3) = 1;
       if pre_Attack_FLAG(3) == 0
           attack_benchmark(3) = y_mea(3);
           benchmark(3) = pre_y(3) + left_standby * delta_t;
       end
     else 
         Attack_FLAG(3) = 0;
    end
    
    % Steering Motor Detection;
    if abs(residual(2)) > thre_steering
       Attack_FLAG(2) = 1;
       if pre_Attack_FLAG(2) == 0 
          attack_benchmark(2) = y_mea(2);
          benchmark(2) = pre_y(2);
       end
    else 
        Attack_FLAG(2) = 0;
    end
    
% If attacked sensors are more than 2, stop the car; 
     if sum(Attack_FLAG) > 1
         break;
     end
     
% Data Correction;
     if Attack_FLAG(1)
        signal_change(1) = y_mea(1) - attack_benchmark(1);
        y_driving_temp1 = benchmark(1) + signal_change(1);
        residual(1) = y_driving_temp1 - Y(1);
        if abs(residual(1)) > thre_driving
            attack_benchmark(1) = y_mea(1);
            benchmark(1) = pre_y(1) + right_standby * delta_t;
            y_driving_temp1 = benchmark(1);
            residual(1) = y_driving_temp1 - Y(1);
        end
        y_mea(1) = y_driving_temp1;
     end

     if Attack_FLAG(2)
        signal_change(2) = y_mea(2) - attack_benchmark(2);
        y_steering_temp = benchmark(2) + signal_change(2);
        residual(2) = y_steering_temp - Y(2);
        if abs(residual(2)) > thre_steering
           attack_benchmark(2) = y_mea(2);
           benchmark(2) = pre_y(2);
           y_steering_temp = benchmark(2);
           residual(2) = y_steering_temp - Y(2);
        end
        y_mea(2) = y_steering_temp;
     end
          
     if Attack_FLAG(3)
        signal_change(3) = y_mea(3) - attack_benchmark(3);
        y_driving_temp2 = benchmark(3) + signal_change(3);
        residual(3) = y_driving_temp2 - Y(3);
        if abs(residual(3)) > thre_driving
            attack_benchmark(3) = y_mea(3);
            benchmark(3) = pre_y(3) + left_standby * delta_t;
            y_driving_temp2 = benchmark(3);
            residual(3) = y_driving_temp2 - Y(3);
        end
        y_mea(3) =y_driving_temp2;
     end
     
     
    pre_Attack_FLAG = Attack_FLAG;
 
    
    % Record previous information
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
    
    [u_mB, error_Pre_mB, error_sum_mB] = NXT_Demo_PID(0.8, 0.02 , 0.3, theta, y_mea(2), error_Pre_mB, error_sum_mB);
    [u_mA, error_Pre_mA, error_sum_mA] = NXT_Demo_PID(1, 0, 0.3, mA_total(i), y_mea(1), error_Pre_mA, error_sum_mA);
    [u_mC, error_Pre_mC, error_sum_mC] = NXT_Demo_PID(1, 0, 0.3, mC_total(i), y_mea(3), error_Pre_mC, error_sum_mC);
    
    % Output data from controller
    mB.Power = u_mB;
    mA.Power = u_mA;
    mC.Power = u_mC;                    % Engage the new control signal;
    
    mB.SendToNXT;
    mA.SendToNXT;
    mC.SendToNXT;
    
    %% Update the trajectories Information;
    Ang_est_mB(i) = Y(2);
    Ang_est_mA(i) = Y(1);
    Ang_est_mC(i) = Y(3);
    Ang_mea_mB(i) = y_mea_fake(2);
    Ang_mea_mA(i) = y_mea_fake(1);
    Ang_mea_mC(i) = y_mea_fake(3);
    Ang_real_mB(i) = y_real_mB;
    Ang_real_mA(i) = y_real_mA;
    Ang_real_mC(i) = y_real_mC;
    %% Now for hardware part, we also need to calculate the input for next iteration, don't forget it's a CLOSE-LOOP control!
    Sampling_record(i) = delta_t;
    Time_axis(i) = t_sample;
    t_last_sample = t_sample;
    i = i + 1;                             % Indicator Auto-increat;
    pre_residual = residual;
end
    %% Truncate the zeros part of all plotting components;
    dell_steering_tst = dell_steering_tst(1:i-1);
    steering_sub = Ang_mea_mB(1:i-1);
    steering_sub = circshift(steering_sub, 1);
    steering_sub(1) = 0;
    attack_alarm = attack_alarm(1:i-1);
    mA_total = mA_total(1:i-1);
    mC_total = mC_total(1:i-1);
    Steering_Ref = Steering_Ref(3: i+1);
    Ang_est_mB = Ang_est_mB(1: i-1);
    Ang_mea_mB = Ang_mea_mB(1: i-1);
    Ang_real_mB = Ang_real_mB(1: i-1);
    Ang_est_mA = Ang_est_mA(1: i-1);
    Ang_mea_mA = Ang_mea_mA(1: i-1);
    Ang_real_mA = Ang_real_mA(1: i-1);
    Ang_est_mC = Ang_est_mC(1: i-1);
    Ang_mea_mC = Ang_mea_mC(1: i-1);
    Ang_real_mC = Ang_real_mC(1: i-1);
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
    mB.TachoLimit = 0;
    close all;
    t = Time_axis;
    figure();
    subplot(2,1,1);
    plot(t,Ang_real_mB,t,Ang_est_mB,'*',t,Ang_mea_mB,t,Ang_real_mB,'LineWidth',3);
    grid;
    title('Reference,Estimation, Measurement and Real Steering Angle');
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
    legend('Reference','Estimation','Measurement','Real');
    subplot(2,1,2);
    plot(t,dell_mB,'LineWidth',2);
    grid on;
    title('Innovation signal(Value of attack signal)')
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
    figure();
    
    subplot(2,1,1);
    plot(t,mA_total,t,Ang_est_mA,'*',t,Ang_mea_mA,t,Ang_real_mA,'LineWidth',3);
    grid;
    title('Estimation, Measurement and Real Signal of Right Driving Motor');
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
    legend('Ref','Estimation','Measurement','Real');
    subplot(2,1,2);
    plot(t, dell_mA,'LineWidth',3);
    grid;
    title('Innovation signal(Vale of attack signal)')
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
    figure();
    subplot(2,1,1);
    plot(t,mC_total,t,Ang_est_mC,'*',t,Ang_mea_mC,t,Ang_real_mC,'LineWidth',3);
    grid;
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
    legend('Ref','Estimation','Measurement','Real');
    subplot(2,1,2);
    plot(t, dell_mC,'LineWidth',3);
    grid;
    xlabel('Time(sec)');
    ylabel('Angle(Degree)');
toc