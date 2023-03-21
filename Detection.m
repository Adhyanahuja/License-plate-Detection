function [Bounding_Box, plate] = Detection(Main_Image, Binarization_Method)

%% Image Preprocessing Stage

% All images larger than certain threshold are resized to give best results
Main_Image = imresize(Main_Image, [1548 NaN],'bilinear');
[height, width, ~] = size(Main_Image);

% Converting RGB to grayscale image
Preprocessed_Image = rgb2gray(Main_Image);

% Contrast enhancement of image using contrast stretching
Contrast_Stretch = stretchlim(Preprocessed_Image);
Preprocessed_Image = imadjust(Preprocessed_Image, Contrast_Stretch,[]);

% Noise reduction using median filter
Preprocessed_Image = medfilt2(Preprocessed_Image,[3,3]);
Preprocessed_Image = medfilt2(Preprocessed_Image,[3,3]);
Preprocessed_Image = medfilt2(Preprocessed_Image,[3,3]);

%% Image binarization stage 

% Binarization using Otsu method
if(strcmp(Binarization_Method, 'graythresh'))
    Binarized_Image = imbinarize(Preprocessed_Image, graythresh(Preprocessed_Image));
elseif(strcmp(Binarization_Method, 'adapt'))
    Binarized_Image = imbinarize(Preprocessed_Image, adaptthresh(Preprocessed_Image,0.9));
end

%% Image Region Localization stage

% we start by rejection componenets that have less than 50 pixels
Binarized_Image = bwareaopen(Binarized_Image,50);

% Finding all regions in image
[L, n] = bwlabel(Binarized_Image);
stats = regionprops(L, 'BoundingBox', 'Image', 'Euler');

% Euler number of all regions
Euler_Number = [stats.EulerNumber];

% Index of regions with negative Euler number
Negative_Euler_number = find(Euler_Number < 0 & Euler_Number > -40);

% Removal of the regions that do not satisfy the dimensions and aspect ratio for representing licence plate 
j = 0;
region = [];

% As positive Euler number regions do not satisy License plate criteria 
for i = Negative_Euler_number
   Contour = stats(i).BoundingBox;
   % Aspect ratio between 1.4 and 1.6 and other basic specs mentioned in paper
   if(Contour(3)/Contour(4) > 1.4 && Contour(3)/Contour(4) < 6 && Contour(2) > round(height/4) &&  Contour(3) < 0.80 * width && Contour(3) > 100 )
       j = j + 1;
       region(j).BoundingBox = stats(i).BoundingBox;
       region(j).Image = stats(i).Image;
       region(j).EulerNumber = stats(i).EulerNumber;
   end
end

%% Candidate Selection Stage

% Extracting candidates and detecting edges 

if(j)
    % List of variances
    var_list = zeros(numel(region),1);
    
    % List of mean values of vertical projection calculated based on image with detected vertical edges
    ver_pr = zeros(numel(region),1);
    
    for i = 1 : numel(region)
        % Vertical edge detection using Sobel filter
        IE = edge(region(i).Image,'sobel','vertical');
        
        % Vertical projection of current region
        S = sum(IE,2);
        
        % Mean value of vertical projection of current region (discarding first 25 percent and last 25 percent)
        ver_pr(i)=mean( S( round(0.25 * length(S)) : round(0.75 * length(S)) ) );
        
        % Variance of vertical projection of current region (discarding first 25 percent and last 25 percent)
        var_list(i) = var(S( round(0.25 * length(S)) : round(0.75 * length(S)) ) );
    end
    
    % Licence plate = candidate with maximal mean vertical projection
    [~,ind] = max(ver_pr);
    
    if length(ver_pr) > 1
        [ver_pr_sort, index] = sort(ver_pr, 'descend');
        if ver_pr_sort(2) > 0.9 * ver_pr_sort(1)
            if var_list(index(1)) < var_list(index(2))
                ind = index(1);
            else
                ind = index(2);
            end
        end
    end
    
    Contour = region(ind).BoundingBox;
    
    % Cropping the licence plate
    plate = imcrop(Main_Image,[Contour(1) - 0.1 * Contour(3) Contour(2) Contour(3) + 0.1 * Contour(3) Contour(4)]);
    Bounding_Box = [Contour(1) - 0.1 * Contour(3) Contour(2) Contour(3) + 0.1 * Contour(3) Contour(4)];
else
    plate = [];
    Bounding_Box = [];
end
