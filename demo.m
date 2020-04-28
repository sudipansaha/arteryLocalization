%This code is a demo of project "Explicit (non-machine learning) approach based
%Carotid artery localization from B-Mode ultrasound images" which is a part of
%my M.Tech. thesis "Ultrasound image processing for CAD and other
%applications". This part is described in section 4.1 of my thesis

%Main function is "ArteryDetection.m". Please refer to the comments
%provided at the top of that code to know in more details about the code
%and variables used

%After running this code, a new directory '.\output\' will be created where
%all output images will be saved

clc
clear all
close all

ArteryDetection('.\input\','png','.\output\','png',0,0.3,0.3,1,1,1,800,2000,400);