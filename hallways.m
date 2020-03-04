% Clear the workspace and the screen
sca;
close all;
clearvars;

% Here we call some default settings for setting up Psychtoolbox.
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

% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Load two stimuli images from file
location1 = ['Y:\' filesep 'Pati' filesep 'Stimuli'... 
    filesep 'NS_behavior' filesep 'manhattan_cropped_25.png'];
image1 = imread(location1);

% Make the images into textures, then concatenate them into one matrix
imageTexture1 = Screen('MakeTexture', window, image1);

% get the size and aspect ratio of the image. Note: size and aspect ratio 
%is read from first image loaded. Images should be the same size.
[s1, s2, s3] = size(image1);
aspectRatio = s2 / s1;

% Set size multiplier to 1
sizeMultiplier = 1;

% --------------------------Build Hallway---------------------------------
% Set hallway length to length of hallway
hallwayLength = 70;

for h = 1:hallwayLength 
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
    Screen('DrawTextures', window, imageTexture1, [], destRect);
    
    sizeMultiplier = sizeMultiplier - 0.01;
    h = h + 1;
    
    % Flip to the screen
    Screen('Flip', window);
end

WaitSecs(2);
% -----------------------------Mouserun-----------------------------------
% Set the initial position of the mouse to be in the bottom of the screen
SetMouse(xCenter, screenYpixels, window);

isRunning = true;
while isRunning == true
    if KbCheck
        isRunning = false;
    end
% Get mouse coordinates    
[mx, my, buttons] = GetMouse(window);
    
% We clamp the values at the maximum values of the screen in X and Y
% in case people have two monitors connected.
    mx = min(mx, screenXpixels);
    my = min(my, screenYpixels);
    
    % set the width of the image to a fraction of the screen's width, set
    % image separation distance as a percentage of image width.
    imageWidth = screenXpixels / 2 * sizeMultipliers
    imageHeight = imageWidth / aspectRatio;

    % make the destination rectangle for the image, locate them on either edge
    % of the screen.
    theRect = [0 0 imageWidth imageHeight];
    destRect = zeros(4, 1);
    destRect(:, 1) = CenterRectOnPointd(theRect, xCenter, yCenter);

    % Draw textures to screen, one in each rectangle.
    Screen('DrawTextures', window, imageTexture1, [], destRect);

    sizeMultiplier = sizeMultiplier * ((screenYpixels - my) / screenYpixels);
    
     
    % Flip to the screen
    Screen('Flip', window);
    
end
    
    


WaitSecs(2);

% Clear the screen
sca;