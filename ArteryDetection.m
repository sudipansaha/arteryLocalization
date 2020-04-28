function ArteryDetection(inputFolder,imageExtension,outputFolder,saveAsExtension, noiseRemovalFlag, ...
    maximumAllowedRowLen,maximumAllowedColLen,removeLowerPeripheryObject, ...
    removeUpperPeripheryObject,removeSidePeripheryObject,minimumObjectSize, ...
    iterativeThresholdUpperVal,iterativeThresholdStepSize)



%This code is a part of project "Explicit (non-machine learning) approach based
%Carotid artery localization from B-Mode ultrasound images" which is a part of
%my M.Tech. thesis "Ultrasound image processing for CAD and other
%applications". This part is described in section 4.1 of my thesis

%Variables
%inputFolder - the folder where input images are stored
%imageExtension - extension/format of the input images
%outputFolder - the folder where output images need to be saved
%saveAsExtension - the extension / format in which outpunt images need to
%be saved
%noiseRemovalFlag- whether noise removal needs to be applied
%maximumAllowedRowLen- objects having row size greater than this size is to be ignored.
%It is to be input as a decimal number (fraction of the row size)
%maximumAllowedColLen - objects having col size greater than this size is to be ignored.
%It is to be input as a decimal number (fraction of the col size)
%removeLowerPeripheryObject - flag indicating whether lower periphery
%objects should be removed
%removeUpperPeripheryObject - flag indicating whether upper periphery
%objects should be removed
%removeSidePeripheryObject - flag indicating whether side periphery objects
%should be removed
%minimumObjectSize - objects having size lower than this size is to be ignored
%iterativeThresholdUpperVal- upper threshold value in the iterative
%threshold algorithm
%iterativeThresholdStepSize- step size in the iterative threshold algorithm

%Output is saved in the output folder and not displayed on the screen

if nargin<1
    inputFolder='.\input\';
end

if nargin<2
    imageExtension='png';
end

if nargin<3
    outputFolder='.\output\';
end

if nargin<4
    saveAsExtension='png';
end

if nargin<5
    noiseRemovalFlag=0;
end

if nargin<6
    maximumAllowedRowLen=0.3;
end

if nargin<7
    maximumAllowedColLen=0.3;
end

if nargin<8
    removeLowerPeripheryObject=1;
end

if nargin<9
    removeUpperPeripheryObject=1;
end

if nargin<10
    removeSidePeripheryObject=1;
end


%Checking whether the input directory exists
if (~exist(inputFolder,'dir'))
    error('Input Directory does not exist');
end

%Checking whether the output directory exists
if (~exist(outputFolder,'dir'))
    mkdir(outputFolder);
end

%Reading image files
imageFiles = dir(fullfile(inputFolder,strcat('*.',imageExtension))); %Gets all image files in Directory
numOfImage=length(imageFiles);

if numOfImage==0
    error('No image in the input directory');
end

for primeIter=1:numOfImage
    baseFileName = imageFiles(primeIter).name;
    fullFileName = fullfile(inputFolder, baseFileName);
    
    im=imread(fullFileName); %Reading image
    
    %B-mode ultrasound images are grayscale
    [numRow,numCol,numChannel]=size(im);
    if numChannel>1
        im=im(:,:,1);
    end
    
    if nargin<11
        minimumObjectSize=floor(0.005*numRow*numCol); %Setting minimum object size threshold
    end
    iterativeThresholdLowerVal=minimumObjectSize;
    
    if nargin<12
        iterativeThresholdUpperVal=floor(0.0125*numRow*numCol);
    end
    
    if nargin<13
        iterativeThresholdStepSize=floor(0.0025*numRow*numCol);
    end
    
    %Noise removal pre-processing
    if noiseRemovalFlag==1
        im=noiseRemove(im);
    end
    
    
    %Detecting connected objects
    imBinary=im2bw(histeq(im));
    se = strel('disk',5);
    imBinary = imclose(imBinary,se);
    for angle=0:90
        se = strel('line',8,angle);
        imBinary = imclose(imBinary,se);
    end
    imBinary=bwareaopen((~(imBinary)),minimumObjectSize,4);
    [connMatrix, numConnComp] = bwlabel(imBinary, 4);
    
    
    maxmAllowedRowLen=floor(maximumAllowedRowLen*numRow);
    maxmAllowedColLen=floor(maximumAllowedColLen*numCol);
    maxmAllowedLen=min(maxmAllowedRowLen,maxmAllowedColLen);
    
    regionStats=regionprops(connMatrix,'MajorAxisLength','MinorAxisLength','Centroid');
    
    %Checking for lower periphery object
    lowerPeripheryObject=zeros(1,numConnComp);
    
    if removeLowerPeripheryObject==1
        coordToInspectRowVal=floor(0.9*numRow);
        for lowerPeripheryIter=1:numCol
            if connMatrix(coordToInspectRowVal,lowerPeripheryIter)~=0
                lowerPeripheryObject(connMatrix(coordToInspectRowVal,lowerPeripheryIter))=1;
            end
        end
        
        coordToInspectRowVal=floor(0.95*numRow);
        for lowerPeripheryIter=1:numCol
            if connMatrix(coordToInspectRowVal,lowerPeripheryIter)~=0
                lowerPeripheryObject(connMatrix(coordToInspectRowVal,lowerPeripheryIter))=1;
            end
        end
        
        for addingToRegionStatsIter=1:numConnComp
            regionStats(addingToRegionStatsIter).lowerPeripheryObject=lowerPeripheryObject(addingToRegionStatsIter);
        end
    end
    %Checking for lower periphery object ends
    
    %Checking for upper periphery object
    upperPeripheryObject=zeros(1,numConnComp);
    
    if removeUpperPeripheryObject==1
        coordToInspectRowVal=floor(0.12*numRow);
        for upperPeripheryIter=1:numCol
            if connMatrix(coordToInspectRowVal,upperPeripheryIter)~=0
                upperPeripheryObject(connMatrix(coordToInspectRowVal,upperPeripheryIter))=1;
            end
        end
        
        
        coordToInspectRowVal=floor(0.08*numRow);
        for upperPeripheryIter=1:numCol
            if connMatrix(coordToInspectRowVal,upperPeripheryIter)~=0
                upperPeripheryObject(connMatrix(coordToInspectRowVal,upperPeripheryIter))=1;
            end
        end
        
        coordToInspectRowVal=floor(0.04*numRow);
        for upperPeripheryIter=1:numCol
            if connMatrix(coordToInspectRowVal,upperPeripheryIter)~=0
                upperPeripheryObject(connMatrix(coordToInspectRowVal,upperPeripheryIter))=1;
            end
        end
        
        for addingToRegionStatsIter=1:numConnComp
            regionStats(addingToRegionStatsIter).upperPeripheryObject=upperPeripheryObject(addingToRegionStatsIter);
        end
    end
    %Checking for upper periphery object ends
    
    
    %Calculating threshold for side periphery checks
    if removeSidePeripheryObject==1
        sidePeripheryThreshold1=floor(0.15*numCol);
        sidePeripheryThreshold2=floor(0.85*numCol);
    else
        sidePeripheryThreshold1=1;
        sidePeripheryThreshold2=numCol;
    end
    
    %Preprocessing centroids Value
    centroids = cat(1, regionStats.Centroid);
    CentroidsXVal=(centroids(:,1))';
    
    
    idxInvalid = ( ([regionStats.MajorAxisLength] > maxmAllowedLen & [regionStats.MinorAxisLength]> maxmAllowedLen) ...
        |[regionStats.upperPeripheryObject]==1 | [regionStats.lowerPeripheryObject]==1 ...
        | CentroidsXVal<sidePeripheryThreshold1 | CentroidsXVal>sidePeripheryThreshold2);
    idx=~idxInvalid;
    newObject=ismember(connMatrix,find(idx));
    
    
    %Finding connected components and roudness metric for the valid objects only
    [connMatrix, numValidConnComp] = bwlabel(newObject, 4);
    if numValidConnComp>0
        regionstats=regionprops(connMatrix,'FilledArea','Perimeter','MajorAxisLength','MinorAxisLength');
        finalRoundnessMetric=zeros(numValidConnComp,1);
        bestSuitedCircle=zeros(numValidConnComp,1);
        %Iterative threshold algorithm to find best suited area
        for validAreaIt=iterativeThresholdUpperVal:-(iterativeThresholdStepSize):iterativeThresholdLowerVal
            for ratioCalcIt=1:numValidConnComp
                axisRatio=((regionstats(ratioCalcIt). MajorAxisLength)/(regionstats(ratioCalcIt). MinorAxisLength));
                roundnessMetric= (4*pi*(regionstats(ratioCalcIt). FilledArea))/((regionstats(ratioCalcIt).Perimeter)^2);
                if ((regionstats(ratioCalcIt). FilledArea)>=validAreaIt)
                    finalRoundnessMetric(ratioCalcIt,1)=roundnessMetric/axisRatio;  %Calculating roundness metric
                end
            end
            circleIndex=find(finalRoundnessMetric==max(finalRoundnessMetric));
            bestSuitedCircle(circleIndex,1)=bestSuitedCircle(circleIndex,1)+1;
        end
        [~,sortIndex] = sort(bestSuitedCircle(:),'descend');
        
        
        
        %Saving best suited result
        bestSuitedIndex=sortIndex(1);
        if length(bestSuitedIndex)>1
            newAreaArray=zeros(length(bestSuitedIndex),1);
            for areaComparisonIt=1:length(bestSuitedIndex)
                suitedIndexContent=bestSuitedIndex(areaComparisonIt,1);
                newAreaArray(areaComparisonIt,1)=regionstats(suitedIndexContent). FilledArea;
            end
            [~,maxAreaIndex]=max(newAreaArray);
            bestSuitedIndex=bestSuitedIndex(maxAreaIndex);
        end
        circleIndex=bestSuitedIndex;
        
        circularObject=(connMatrix==circleIndex);
        circularStats=regionprops(circularObject,'Centroid','MajorAxisLength','MinorAxisLength');
        centroid=floor(circularStats.Centroid);
        radii=(circularStats.MajorAxisLength+circularStats.MinorAxisLength)/4;
    else   %If no circle detected, just saving the image as output
        centroid=[5 5];
        radii=0;
    end
    
    
    %Creating output figure and saving the result to output directory
    handleToOutput=figure();
    set(handleToOutput, 'visible','off')
    hold on;
    subplot(1,2,1);
    imshow(im);
    title('Input image');
    subplot(1,2,2);
    imshow(im);
    viscircles(centroid,radii);
    title('Detected carotid artery');
    outputFilename=strcat(outputFolder,num2str(primeIter),'.',saveAsExtension);
    saveas(handleToOutput,outputFilename,saveAsExtension);
    %Creating output figure and saving the result to output directory ends
    
    
end
end


function [noiseProcessedImg]=noiseRemove(inputImg)
noiseProcessedImg=medfilt2(inputImg,[5 5]);
end
