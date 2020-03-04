
% Clear the workspace and the screen
sca;
close all;
clearvars;

% call some default settings for setting up Psychtoolbox.
% SynchTests are skipped--doesn't work on this computer.
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Set the initial position of the mouse to be in the centre of the
% screen
SetMouse(xCenter, yCenter, window);

% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);


% Clear port for sensor
delete(instrfind({'Port'},{'COM5'}));
% Create sensor port, open data
s = serial('COM5', 'BaudRate', 9600);
fopen(s);

%--------------------------Load Images---------------------------
% Load two NS stimuli images from file
location1 = ['\\KUHLMAN-NAS.bio.cmu.edu' filesep 'Projects' filesep 'Pati' filesep 'Stimuli'... 
    filesep 'NS_behavior' filesep 'manhattan_cropped_25.png'];
location2 = ['\\KUHLMAN-NAS.bio.cmu.edu' filesep 'Projects' filesep 'Pati' filesep 'Stimuli'... 
    filesep 'NS_behavior' filesep 'manhattan_cropped_50.png'];
image1 = imread(location1);
image2 = imread(location2);

% Make the images into textures, then concatenates them into one matrix
imageTexture1 = Screen('MakeTexture', window, image1);
imageTexture2 = Screen('MakeTexture', window, image2);
bothTextures = [imageTexture1 imageTexture2];

% get the size and aspect ratio of the image
[s1, s2, s3] = size(image1);
aspectRatio = s2 / s1;

% set the width of the image to a fraction of the screen's width - 20%
imageWidth = screenXpixels / 2;
imageWidth = imageWidth - (imageWidth * 0.1);
originalImageWidth = imageWidth;
imageHeight = imageWidth / aspectRatio;

% define destination rectange size
theRects = [0 0 imageWidth imageHeight];
destRects = zeros(4, 2);
leftImageX = imageWidth/2;
rightImageX = screenXpixels - imageWidth/2;

%--------------------------------------------------------------------     
% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;


% Define destination
    destRects(:, 1) = CenterRectOnPointd(theRects, leftImageX, yCenter);
    destRects(:, 2) = CenterRectOnPointd(theRects, rightImageX, yCenter);

% Draw textures to screen, one in each rectangle.
    Screen('DrawTextures', window, bothTextures, [], destRects);

% Flip to the screen
    vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

%------------------------------Stage 1: Center Image-------------------
inCentering = true;

% Size of for center of rectangle to fall within--20% of image width
centerBox = [0 0 imageWidth * 0.2 100];

% To reduce jitter, set a minimum value to ignore
sensorminimum = 0;

while inCentering
    % Exit centering if key is pressed
    if KbCheck
        inCentering = false;
    end

    sensoroutput = fscanf(s,'%f'); %read from serial
    sensoroutput = sensoroutput';
    
    % fill output if empty (flushed before reading)
    if isempty(sensoroutput)
        sensoroutput = [0, 0];
    else 
        lastsense = sensoroutput;
    end
    
    %reduce jitter
    if abs(sensoroutput(1)) <= sensorminimum
        sensoroutput(1) = 0;
    end
    
    
    % Moves images left and right based on sensor output
        leftImageX = leftImageX + sensoroutput(1);
        rightImageX = rightImageX + sensoroutput(1);

    % Determines if an image is centered based on if center poit falls
    % within centerbox
    
    centeredBox = CenterRectOnPointd(centerBox, xCenter, yCenter);
    centeredLeftImage = IsInRect(leftImageX, yCenter, centeredBox);
    centeredRightImage = IsInRect(rightImageX, yCenter, centeredBox);
    % no tunnels entered in beginning
    leftTunnel = false;
    rightTunnel = false;
    
    % start centering timer
    tic;
    % Center images 
    while centeredLeftImage
        
        sensoroutput = fscanf(s,'%f'); %read from serial
        sensoroutput = sensoroutput';
        if isempty(sensoroutput)
            sensoroutput = [0, 0];
        else 
            lastsense = sensoroutput;
        end
        
        if abs(sensoroutput(1)) <= sensorminimum
            sensoroutput(1) = 0;
        end
    
        
        % Moves images left and right based on sensor output
        leftImageX = leftImageX + sensoroutput(1);
        rightImageX = rightImageX + sensoroutput(1);

        centeredBox = CenterRectOnPointd(centerBox, xCenter, yCenter);
        centeredLeftImage = IsInRect(leftImageX, yCenter, centeredBox);

        % update timer
        toc;
        elapsedLeftTime = toc;
       
        if elapsedLeftTime > 2
            leftTunnel = true;
            rightTunnel = false;
            centeredLeftImage = false;
            inCentering = false;
        end
        disp = strcat('Left centered for:', num2str(elapsedLeftTime));
        DrawFormattedText(window, disp);
        
        destRects(:, 1) = CenterRectOnPointd(theRects, leftImageX, yCenter);
        destRects(:, 2) = CenterRectOnPointd(theRects, rightImageX, yCenter);
        Screen('DrawTextures', window, bothTextures, [], destRects);

        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    
    while centeredRightImage
        
        sensoroutput = fscanf(s,'%f'); %read from serial
        sensoroutput = sensoroutput';
        if isempty(sensoroutput)
            sensoroutput = [0, 0];
        else 
            lastsense = sensoroutput;
        end
        
        if abs(sensoroutput(1)) <= sensorminimum
            sensoroutput(1) = 0;
        end
        
        % Moves images left and right based on sensor output
        leftImageX = leftImageX + sensoroutput(1);
        rightImageX = rightImageX + sensoroutput(1);

        centeredBox = CenterRectOnPointd(centerBox, xCenter, yCenter);
        centeredLeftImage = IsInRect(leftImageX, yCenter, centeredBox);
        centeredBox = CenterRectOnPointd(centerBox, xCenter, yCenter);
        centeredRightImage = IsInRect(rightImageX, yCenter, centeredBox);
        % update timer
        toc;
        elapsedRightTime = toc;
        
        if elapsedRightTime > 2
            leftTunnel = false;
            rightTunnel = true;
            centeredRightImage= false;
            inCentering = false;
        end
        disp = strcat('Right centered for:', num2str(elapsedRightTime));
        DrawFormattedText(window, disp);
        
        destRects(:, 1) = CenterRectOnPointd(theRects, leftImageX, yCenter);
        destRects(:, 2) = CenterRectOnPointd(theRects, rightImageX, yCenter);
        Screen('DrawTextures', window, bothTextures, [], destRects);
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end

     
% Define destination
    destRects(:, 1) = CenterRectOnPointd(theRects, leftImageX, yCenter);
    destRects(:, 2) = CenterRectOnPointd(theRects, rightImageX, yCenter);

% Draw textures to screen, one in each rectangle.
    Screen('DrawTextures', window, bothTextures, [], destRects);

% Flip to the screen
    vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    disp(sensoroutput);
    flushinput(s);
    sensoroutput = [0;0];
end
 
if leftTunnel
    DrawFormattedText(window, 'Entering Left Tunnel', 'center');
    isRunning = true;

elseif rightTunnel
    DrawFormattedText(window, 'Entering Right Tunnel', 'center');
    isRunning = true;
else
    DrawFormattedText(window, 'No Tunnel Chosen', 'center');
    WaitSecs(1);
    sca;
end
  vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%--------------------------------End Stage 1------------------------------

%--------------------------Stage 2: Corridor-----------------------------

% Set corridor length for tunnels
if leftTunnel
    hallwayLength = 75;
    hallwayTexture = imageTexture1;
    
elseif rightTunnel
    hallwayLength = 50;
    hallwayTexture = imageTexture2;
    
end

%-----------------------build corridor---------------------------------
h = 1;
% Set size multiplier to 1
sizeMultiplier = 1;

while h <= hallwayLength 
    
    % set the width of the image to a fraction of the screen's width, set
    % image separation distance as a percentage of image width.
    imageWidth = screenXpixels / 2 * sizeMultiplier;
    imageHeight = imageWidth / aspectRatio;

    % make the destination rectangle for the image, locate them on either edge
    % of the screen.
    theRect = [0 0 imageWidth imageHeight];
    destRect = zeros(4, 1);
    destRect(:, 1) = CenterRectOnPointd(theRect, xCenter, yCenter); 

    % Draw textures to screen, one in each rectangle.
    Screen('DrawTextures', window, hallwayTexture, [], destRect);
    
    sizeMultiplier = sizeMultiplier - 0.01;
    
    % Flip to the screen
    Screen('Flip', window);
    
    h = h + 1;
end
%------------------------------------------------------------------------

%----------------------------Mouse in corridor---------------------------
tunnelEnd = false;
while isRunning 
    if KbCheck
        isRunning = false;
    end
    
    sensoroutput = fscanf(s,'%f'); %read from serial
    sensoroutput = sensoroutput';
    
    % fill output if empty (flushed before reading)
    if isempty(sensoroutput)
        sensoroutput = [0, 0];
    else 
        lastsense = sensoroutput;
    end
    
    %reduce jitter
    if abs(sensoroutput(2)) <= sensorminimum
        sensoroutput(2) = 0;
    end
       
    sizeMultiplier = sensoroutput(2) / 1000;
    
    
    imageWidth = imageWidth * (1 + sizeMultiplier);
    imageHeight = imageWidth / aspectRatio;
    
    % make the destination rectangle for the image, locate them on either edge
    % of the screen.
    theRect = [0 0 imageWidth imageHeight];
    destRect = zeros(4, 1);
    destRect(:, 1) = CenterRectOnPointd(theRect, xCenter, yCenter);

    % Draw textures to screen
    Screen('DrawTextures', window, hallwayTexture, [], destRect);
    
    if imageWidth >=  screenXpixels / 2;
        tunnelEnd = true;
        isRunning = false;
    end
    
    % Flip to the screen
    Screen('Flip', window);
    
    flushinput(s);
    sensoroutput = [0, 0];
    end
     
if tunnelEnd == true
    DrawFormattedText(window, 'End of corridor reached, reward','center');
    vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi); 
end
%--------------------------------End Stage 2----------------------------- 
WaitSecs(2);
% Clear the screen
sca;