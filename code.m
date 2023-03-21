% %% MATLAB code for License plate detection
% %% EEE F266: Study Project
% %% Name: Adhyan Ahuja
% %% ID: 2019B4A30548P

clc
clear all
close all


% Taking input of vehicle image and resizing it
Main_Image = imread('image6.jpg');
Main_Image = imresize(Main_Image,[1548 NaN],'bilinear');

% Displaying the original input image
figure(1);
imshow(Main_Image)
title('Input image')

% Sending input image for global binarization
[Bounding_Box, plate] = Detection(Main_Image, 'graythresh');

% If the previous output remains empty, we send the input image for adaptive binarization
if(size(plate, 1) == 0)
    % Licence plate detection (adaptive binarization)
    [Bounding_Box, plate] = Detection(Main_Image, 'adapt');
      
end

% Displaying the modified image with bounding box over the License plate
figure(2);
imshow(Main_Image)
rectangle('Position',Bounding_Box,'EdgeColor','g',LineWidth=2) 
title('Output image with bounding box over License plate')
