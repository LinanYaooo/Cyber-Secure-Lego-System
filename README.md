# Cyber-Secure-Lego-System
My unimelb Capstone project, playing around sensor attacker &amp; security solution;
I'll attach my project reoprt, but firstly, I am gonna talk about some details about this project;
This project is leat by my supervisor Prof Margreta Kuijper, who is a well-known researcher and professor in Melbourne uni;
She gave us the inspiration of this project and recommand us how to make it kick start;
The co-supervisor is ZHanghan Tang, a phD student of Melbourne uni, who taught several foudmental knowledge of this project;
Ok, let's see what did we do in this project;

1.
We are talking about the Cyber Security, which describe a scenario a cyber hacker comes and get involveed a system,          
the system could be any kinds of cyber-physical system which involves cyber connection and physical machine. In our          
concept, this system could be an driverless car system (which we actually simulated in our project) or a drone controlled    
through internet. The common features of them is that all of them need to be controlled through feed-back controlling        
manner. While the physcial machine is working, the sensors will be used to sensor the state of the machine, and the local    
controller can retrive the sensoring data through the wireless network, then, relevant controlling stragety can be launched  
accordingly. In our project, the security problem is found at the sensors, where if a cyber hacker could stealth into the    
system without being awared. And the hacker can tamper the sensoring data of part of these sensors, then the messy sensoring 
data will be sent back to the local controlling center. And therefore wrong controlling command would be given. Thus, the    
core task of this project is to develop a security solution of these kind of cyber-physical system to enable them to have the
ability of detectiong the cyber attack(the wrong sensoring data) and make corresponding correction, which is to correct the  
tampered data. This is the big picture of how our proeject works.                                                            
                
2.
Now it's time to introduce the content of what we have done for this project:                                                   
1. We build a detection algorithm, the algorithm                                                                               
deploys a Kalman predictor to detect the cyber attack happen on the sensors. It can predict the range of the sensor measurement
for next sample based on the samples in the past, whose fundmental logic is Bayesian estimation.
2. We deliver a correction algorithm which utlise the thinking of sensor fusion, for more you can view the capstoen report at below,
I have also upload a pdf version of our capstone project.

3.
Demonstration is important, in this project we build our algorithm by MATLAB and program in a LEGO NXT car model. Which can demon-
strates the our Capstone project. To completely make the deonstration, we use the NXT robot Toolbo developed by RWTH - Mindstorms NXT Toolbox group (http://www.mindstorms.rwth-aachen.de/).


If you have any question or recommandation, please no hesitate to ask.
my e-mail: ieyaolinan@163.com
