close all
clear variables
clc
%% Folders
folder = 'C:\Users\paulo\Desktop\TIA\data\Rollout_teste_cruze';
%% Data Log
PIG = "PIG";
Acc = "Accelerometer";
GPS = "Location";
Gyr = "Gyroscope";
sensor = Acc;
%% Parameters
phi = 0.58;
X = 0.1613;
m = 376;                    % total weight (Kg)
Rpf = 0.252;
RpR = 0.252;                % braque pad radious (front, rear)
IMF = 1.64;
IMR = 1.64;                 % moment of inercia of the wheel (front, rear)
RextF = 0.097;
RextR = 0.106;              % external radious of brake caliper (front, rear)
HpF = 0.021;
HpR = 0.021;                % brake pad higth from wheel center
mup = 0.45;                 % coefficient of friction of the brake pad 
Acp = 0.00098;              % total area of the brake pads cylinders (front, rear)
Acm = 0.00019;              % master cylinder area
Hr = 0.2;                   % brake pedal ratio (cylinder/brake shoe)
%% Objects
brake = BrakeClass(folder, sensor);
%gps = LocationClass(folder, GPS);
%% Calculos
brake.calcFz
...
%% Graphs
brake.acc()
brake.hydpressure()
brake.pedalforce()