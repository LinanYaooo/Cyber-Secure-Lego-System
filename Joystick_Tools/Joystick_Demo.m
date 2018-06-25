%% Sample Code for Xbox 360 Controller for Windows

% Visit http://sharpdx.org/documentation/api for more API details

controllerLibrary = NET.addAssembly([pwd ' \Joystick_Tools\SharpDX.XInput.dll']);
myController = SharpDX.XInput.Controller(SharpDX.XInput.UserIndex.One);
VibrationLevel = SharpDX.XInput.Vibration;

Left = zeros(100,1);
Right = zeros(100,1);
Time = zeros(100,1);

for i = 1:1000
    t_start = clock;
    State = myController.GetState();
    ButtonStates = ButtonStateParser(State.Gamepad.Buttons); % Put this into a structure
    disp(State.Gamepad);
    disp(ButtonStates);
    VibrationLevel.LeftMotorSpeed = double(State.Gamepad.LeftTrigger) * 255;
    VibrationLevel.RightMotorSpeed = double(State.Gamepad.RightTrigger) * 255;
    Left(i) = double(State.Gamepad.LeftTrigger);
    Right(i) = double(State.Gamepad.RightTrigger);
    mA.Power = round(Left(i) / 256 * 100);
    mC.Power = round(Right(i) / 256 * 100);
    mA.SendToNXT;
    mC.SendToNXT;
    mA.ReadFromNXT;
    mC.ReadFromNXT;
    Time(i) = i;
    myController.SetVibration(VibrationLevel); % If your controller supports vibration
    clf
    plot(Time, Left, 'r');
    hold on
    plot(Time, Right, 'b');
    pause(.001);
    t_end =clock;
    etime(t_end,t_start)
end    
mA.Stop;
mC.Stop;
VibrationLevel.LeftMotorSpeed = 0;
VibrationLevel.RightMotorSpeed = 0;
myController.SetVibration(VibrationLevel); % If your controller supports vibration

