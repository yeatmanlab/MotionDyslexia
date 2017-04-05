function RunPractice(NB,subjectIni,ver)

clearvars -except subjectName subjectIni ver

mainDir = pwd;
%%
kb = InitKeyboard;

mt_prepSounds;

% Screen('Preference', 'SkipSyncTests', 1);
 
bkIm = imread('Instruction2.jpg');

if ver == 2
    joymex2('open',0);
end

%%
% subjectName = input('Your name? : ', 's');
% subjectIni = input('Your Initials? : ', 's');

oldenablekeys = RestrictKeysForKbCheck([kb.escKey, kb.spaceKey, kb.downKey, kb.rightKey]);

display.bkColor = [128 128 128];
display.fixColor = [0 0 0];

display.dist = 56;
display.width = 53;
display.widthInVisualAngle = 2*atan(display.width/2/display.dist) * 180/pi;

display.screenNum = max(Screen('Screens'));

display = OpenWindow(display);
HideCursor(display.wPtr);
ListenChar(2);

display.fixShape = 'bullseye';
display.fixSize = 1*display.ppd;
% display.fixation = [display.cx display.cy];

if display.frameRate == 120
    dots.dotLife = 24; %frames
else
    dots.dotLife = 12;
end

dots.nDots = 130;
dots.speed = 8;  %speeds for each field deg/sec
dots.color = [0 0 0]; %colors for each field [r,g,b]
dots.size = 5; %pixels
dots.wSize = 6.5;
dots.fixBkSize = 1;
% dots.window = dots.wSize*[-1,1,1,-1]; %aperture [l,r,t,b] from center (degrees)

% dots.nFields = length(dots.nDots); %number of dot fields
totalDots = sum(dots.nDots);
dots.xy = zeros(2,totalDots);

dots.dxdy = zeros(2,totalDots);

dots.dotAge = zeros(1,totalDots);
dots.dotSize = zeros(1,totalDots);

dots.dotColor = zeros(3,totalDots);
dots.rmax = dots.wSize;	% maximum radius of annulus (pixels from center)
dots.rmin = dots.fixBkSize; % minimum

dots.dur = .9; % 600 ms

dots.nFrames = round(dots.dur / display.ifi);

dots.center = [display.cx display.cy];

display.fixation = dots.center;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.nStairs = 2;
config.nTrials = 20;

config.nTotalTrials = 10; % 10 dummay easy trials

result.response = NaN * ones(1, config.nTotalTrials);

config.startPoint = .4;

config.coherence = [1  1 .9 .9 .8 .8 .7 .7 .6 .6];
% config.coherence = Shuffle(config.coherence);

% result.q = PrepareQuest(config);
% result.quest = zeros(config.nTrials, 3, config.nStairs);
result.response = NaN * ones(1,config.nTotalTrials);
result.keyResponse = NaN * ones(1,config.nTotalTrials);
config.randOrder = repmat([1 2], 1, 5);
config.randOrder = Shuffle(config.randOrder);
config.dir = repmat([0 1], 1, config.nTotalTrials/2);
config.dir = Shuffle(config.dir) .* 180;
stair1 = 1; stair2 = 1; trial = 1;

scaleFactor = display.wRect(3)/size(bkIm,2);
srcRect = [0 0 size(bkIm,2)-1 size(bkIm,1)-1];
destRect = CenterRectOnPoint(ScaleRect(srcRect,scaleFactor,scaleFactor),display.cx,display.cy);

bkTexture = Screen('MakeTexture', display.wPtr, bkIm);

% Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
Screen('Flip', display.wPtr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ver == 1
    str1 = 'Left motion = left arrow';
    str2 = 'Right motion = right arrow';
    str5 = 'Hit space key to continue.';
    str6 = 'HIT ESCAPE to EXIT';
else
    str1 = 'Left motion = move or rotate joystick to left';
    str2 = 'Right motion = move or rotate joystick to right';
    str5 = 'Hit space key to continue.';
    str6 = 'HIT ESCAPE to EXIT';
end

textBounds1 = Screen('TextBounds',display.wPtr,str1);
textBounds2 = Screen('TextBounds',display.wPtr,str2);
textBounds5 = Screen('TextBounds',display.wPtr,str5);
textBounds6 = Screen('TextBounds',display.wPtr,str6);

Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
        display.cy - 400,[0 0 0]);
Screen('DrawText',display.wPtr, str2, display.cx - round((textBounds2(3)-textBounds2(1))/2), ...
        display.cy - 300,[0 0 0]);
Screen('DrawText',display.wPtr, str5, display.cx - round((textBounds5(3)-textBounds5(1))/2), ...
        display.cy,[0 0 0]);
Screen('DrawText',display.wPtr, str6, display.cx - round((textBounds6(3)-textBounds6(1))/2), ...
        display.cy + 200,[0 0 0]);


Screen('Flip', display.wPtr);

wait4Space = 0;
while ~wait4Space
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
    if keyIsDown && keyCode(kb.spaceKey)
        wait4Space = 1;
    end
end

if ver == 2
    joyTrial = 1;
    str1 = 'Test the joystick.';
    str2 = 'Move the joystick to the left.';
    str3 = 'Move the joystick to the right.';
    str4 = 'Rotate the joystick to the left.';
    str8 = 'Rotate the joystick to the right.';
    
    textBounds1 = Screen('TextBounds',display.wPtr,str1);
    textBounds2 = Screen('TextBounds',display.wPtr,str2);
    textBounds3 = Screen('TextBounds',display.wPtr,str3);
    textBounds4 = Screen('TextBounds',display.wPtr,str4);
    textBounds8 = Screen('TextBounds',display.wPtr,str8);

    for joyTrial = 1: 4
        switch joyTrial
            case 1
                Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
                    display.cy - 100,[0 0 0]);
                Screen('DrawText',display.wPtr, str2, display.cx - round((textBounds2(3)-textBounds2(1))/2), ...
                    display.cy,[0 0 0]);
            case 2
                Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
                    display.cy - 100,[0 0 0]);
                Screen('DrawText',display.wPtr, str3, display.cx - round((textBounds3(3)-textBounds3(1))/2), ...
                    display.cy,[0 0 0]);
            case 3
                Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
                    display.cy - 100,[0 0 0]);
                Screen('DrawText',display.wPtr, str4, display.cx - round((textBounds4(3)-textBounds4(1))/2), ...
                    display.cy,[0 0 0]);
            case 4
                Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
                    display.cy - 100,[0 0 0]);
                Screen('DrawText',display.wPtr, str8, display.cx - round((textBounds8(3)-textBounds8(1))/2), ...
                    display.cy,[0 0 0]);
        end
        Screen('Flip', display.wPtr);
        
        str = 'Great';
        strBounds = Screen('TextBounds', display.wPtr, str);
        
        isResponded = 0;
        while ~isResponded
            a = joymex2('query',0);
            switch joyTrial
                case 1
                    if a.axes(1) < -10000
                        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                        Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
                            display.cy,[0 0 0]);
                        Screen('Flip',display.wPtr);
                        isResponded = 1;
                    end
                case 2
                    if a.axes(1) > 10000
                        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                        Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
                            display.cy,[0 0 0]);
                        Screen('Flip',display.wPtr);
                        isResponded = 1;
                    end
                case 3
                    if a.axes(3) < -10000
                        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                        Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
                            display.cy,[0 0 0]);
                        Screen('Flip',display.wPtr);
                        isResponded = 1;
                    end
                case 4
                    if a.axes(3) > 10000
                        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
                        Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
                            display.cy,[0 0 0]);
                        Screen('Flip',display.wPtr);
                        isResponded = 1;
                    end
            end
        end
        WaitSecs(1);
    end
    str = 'Hit the space to continue';
    strBounds = Screen('TextBounds', display.wPtr, str);
    Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
    Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
        display.cy,[0 0 0]);
    Screen('Flip',display.wPtr);
    
    wait4Space = 0;
    while ~wait4Space
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
        if keyIsDown && keyCode(kb.spaceKey)
            wait4Space = 1;
        end
    end
else
    str = 'Hit the space to continue';
    strBounds = Screen('TextBounds', display.wPtr, str);
    Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
    Screen('DrawText',display.wPtr, str, display.cx - round((strBounds(3)-strBounds(1))/2), ...
        display.cy,[0 0 0]);
    Screen('Flip',display.wPtr);
    
    WaitSecs(.5);
    wait4Space = 0;
    while ~wait4Space
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
        if keyIsDown && keyCode(kb.spaceKey)
            wait4Space = 1;
        end
    end
end

score = 0;
%% Trials
while trial <= config.nTotalTrials

    dots.coherence = config.coherence(trial);

    dots = CreateDots(dots,config.dir(trial),display);
    
    Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
    MakeFixation(display);
    Screen('Flip', display.wPtr);
    WaitSecs(.5);
    
    j = 1; t = GetSecs;
%     PsychPortAudio('Start', 2, 1, 0, 1);
    while j <= dots.dur*display.frameRate  
        m = dots.xy(:,:,j) * display.ppd;
        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
        Screen('DrawDots', display.wPtr, m, dots.size, dots.dotColor, dots.center, 2);
        MakeFixation(display);
        Screen('Flip', display.wPtr);
        j = j + 1;
        while GetSecs-t < (j-1)*display.ifi, ;, end
        %         KbStrokeWait;
    end
    result.motionDur(trial) = GetSecs - t;
    
%     MakeFixation(display);
    Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
    Screen('Flip', display.wPtr);
    
    isResponded = 0;
    FlushEvents('keyDown');
    while ~isResponded
        if ver == 1 % keyboard response
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
            if keyIsDown
                if keyCode(kb.downKey)
                    result.keyResponse(trial) = 1;
                    isResponded = 1;
                elseif keyCode(kb.rightKey)
                    result.keyResponse(trial) = 0;
                    isResponded = 1;
                elseif keyCode(kb.escKey)
                    Screen('CloseAll');
                    ListenChar(0);
                    ShowCursor;
                    break;
                end
            end
        else % joystick response
            a = joymex2('query',0);
            if a.axes(1) < -10000 || a.axes(3) < -10000
                result.keyResponse(trial) = 1;
                isResponded = 1;
            elseif a.axes(1) > 10000 || a.axes(3) > 10000
                result.keyResponse(trial) = 0;
                    isResponded = 1;
            else
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
                if keyCode(kb.escKey)
                    Screen('CloseAll');
                    ListenChar(0);
                    ShowCursor;
                    break;
                end
            end
        end
    end
    result.response(trial) = result.keyResponse(trial) == config.dir(trial)/180;
    repeatAgain = 0;
    if result.response(trial)
        PsychPortAudio('Start', 0, 1, 0, 1);
        str = '+3';
        textBounds = Screen('TextBounds',display.wPtr,str);
        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
        Screen('DrawText',display.wPtr, str, display.cx - round((textBounds(3)-textBounds(1))/2), ...
            display.cy - round((textBounds(4)-textBounds(2))/2),[0 255 0]);
        score = score + 1;
    else
        PsychPortAudio('Start', 2, 1, 0, 1);
        str = '+0';
        textBounds = Screen('TextBounds',display.wPtr,str);
        Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
        Screen('DrawText',display.wPtr, str, display.cx - round((textBounds(3)-textBounds(1))/2), ...
            display.cy - round((textBounds(4)-textBounds(2))/2),[255 0 0]);
        if stair1 == 1 || stair2 == 1
            repeatAgain = 1;
        end
    end
    Screen('Flip',display.wPtr);
    
    if ver == 2
        joyCorrect = 0;
        while ~joyCorrect
            a = joymex2('query',0);
            if a.axes(1) > -500 && a.axes(3) > -500 && a.axes(1) < 500 && a.axes(3) < 500
                joyCorrect = 1;
            end
        end
    end
                
    trial = trial + 1;
%     if ~repeatAgain
%         if config.randOrder(trial) == 1
%             result.quest(stair1, 1, 1) = result.response(trial);
%             result.quest(stair1, 2, 1) = QuestMean(result.q(1));
%             result.quest(stair1, 3, 1) = 10^(QuestMean(result.q(1)));
%             result.q(1) = QuestUpdate(result.q(1),QuestMean(result.q(1)),result.response(trial));
%             stair1 = stair1 + 1;
%         elseif config.randOrder(trial) == 2
%             result.quest(stair2, 1, 2) = result.response(trial);
%             result.quest(stair2, 2, 2) = QuestMean(result.q(2));
%             result.quest(stair2, 3, 2) = 10^(QuestMean(result.q(2)));
%             result.q(2) = QuestUpdate(result.q(2),QuestMean(result.q(2)),result.response(trial));
%             stair2 = stair2 + 1;
%         end
%         trial = trial + 1;
%     end
    
    WaitSecs(1);
end

% if isempty(dir('Data'))
%     mkdir('Data');
% end
% cd('Data');
% fn = sprintf('%s-%s.mat',subjectIni,datestr(now,'yyyymmdd-HHMM'));
% save(fn,'display','config','result','dots');
% cd(mainDir);

% str1 = 'HALL of FAME';
% str2 = sprintf('1. %s \t 30', 'Chloe');
% str3 = sprintf('2. %s \t %d', subjectName, score*3);
% str4 = sprintf('3. %s \t %d', 'Jason', max(score*3-6,3));
% str5 = 'Hit space key to continue.';
% 
% textBounds1 = Screen('TextBounds',display.wPtr,str1);
% textBounds2 = Screen('TextBounds',display.wPtr,str2);
% textBounds3 = Screen('TextBounds',display.wPtr,str3);
% textBounds4 = Screen('TextBounds',display.wPtr,str4);
% textBounds5 = Screen('TextBounds',display.wPtr,str5);
% 
% Screen('DrawText',display.wPtr, str1, display.cx - round((textBounds1(3)-textBounds1(1))/2), ...
%         display.cy - 400,[0 0 0]);
% Screen('DrawText',display.wPtr, str2, display.cx - round((textBounds2(3)-textBounds2(1))/2), ...
%         display.cy - 300,[0 0 0]);
% Screen('DrawText',display.wPtr, str3, display.cx - round((textBounds3(3)-textBounds3(1))/2), ...
%         display.cy - 200,[0 0 0]);
% Screen('DrawText',display.wPtr, str4, display.cx - round((textBounds4(3)-textBounds4(1))/2), ...
%         display.cy - 100,[0 0 0]);
Screen('DrawTexture', display.wPtr, bkTexture,srcRect,destRect);
Screen('DrawText',display.wPtr, str5, display.cx - round((textBounds5(3)-textBounds5(1))/2), ...
        display.cy,[0 0 0]);

Screen('Flip', display.wPtr);

wait4Space = 0;
while ~wait4Space
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(-1);
    if keyIsDown && keyCode(kb.spaceKey)
        wait4Space = 1;
    end
end

Screen('CloseAll');
ShowCursor(display.wPtr);
ListenChar(0);
RestrictKeysForKbCheck([]); % Re-enable all keys

