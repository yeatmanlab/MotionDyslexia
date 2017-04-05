%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The causal relationship between dyslexia and motion perception reconsidered
% Joo S.J., Donnelly P.M. and Yeatman J.D.
%
% Analysis code to reproduce each figure and statistic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup

clear variables;

parentDir = '~/git/MotionDyslexia/'; % Point to directory of repo
dataDir = 'Data'; % Data directory within repo

ccolor = [
    0.8941    0.1020    0.1098;
    0.2157    0.4941    0.7216;
    0.3020    0.6863    0.2902;
    0.5961    0.3059    0.6392;
    1.0000    0.4980         0;
    1.0000    1.0000    0.2000;
    0.6510    0.3373    0.1569;
    0.9686    0.5059    0.7490;
    0.6000    0.6000    0.6000];

%% Load in data for the 20 intervention subjects

subjectList = {'102','110','145','150','151','152','160','161','162', ...
    '163','164','170','172','174','179','180','207','208','210','211'};

cd(sprintf(fullfile(parentDir,dataDir)));

% Load reading scores
T = readtable('NLR_Scores.csv','Delimiter','\t');
% Mark subjects who do not have data on motion experiment as zero
T.spacerace(isnan(T.spacerace)) = 0;

%% Extract staircases and calculate the average threshold

cd(sprintf(fullfile(parentDir,dataDir)));

% We want to exclude runs where subjects are not paying attention and
% therefor give us bad threshold estimates. The experiment included 10
% easy trials (70% coherence) per run. If subjects are below 70% correct
% on these easy trials then we exclude the run.
badCriterion = .7;

% Loop over intervention subjects and build a data structure
for iSubject = 1:length(subjectList)
    thresh(iSubject).name = subjectList{iSubject};
    temp1.age = T.Age(T.Subject == str2num(subjectList{iSubject}));
    thresh(iSubject).age = temp1.age(1)/12;
    
    % These subjects have multiple sessions (intervention). Collect this
    % subject's data for all sessions
    for iSession = 1:max(T.LMB_session(T.Subject == str2num(subjectList{iSubject})))
        % Try to load the data and avoid trying to load non-existing data.
        % For example in our intake session we did not run this experiment.
        % Only load sessions where the space race was run.
        if T.spacerace(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject}))
            d = dir(sprintf('%s_%s*',subjectList{iSubject}, ...
                num2str(T.Date(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject})))));
            thresh(iSubject).quest{iSession} = [];
            thresh(iSubject).when{iSession} = sprintf('%s',d(1).name(5:12));
            
            % Looping over sessions
            for j = 1: length(d)
                load(d(j).name);
                % Condition 999 is the easy trials. We calculate the
                % percent correct on these easy trials to see if they are
                % paying attention.
                pCorr(iSubject,iSession) = sum(result.response(config.randOrder==999))/length(result.response(config.randOrder==999));
                % Mark as a bad run if they were below badCriterion. This
                % will appear as a missing data point for all future
                % analyses in this script
                if pCorr(iSubject,iSession) <= badCriterion
                    thresh(iSubject).badRun(j,iSession) = 1;
                else
                    thresh(iSubject).badRun(j,iSession) = 0;
                    % Re-fit the data with both threshold and beta (slope)
                    % as free parameters. During the QUEST run beta was
                    % fixed. There are 2 staircases per block
                    [t(1), sd(1), betaEstimate(1), betaSd(1)] = QuestBetaAnalysis_Joo(result.q(1));
                    [t(2), sd(2), betaEstimate(2), betaSd(2)] = QuestBetaAnalysis_Joo(result.q(2));
                    
                    % Concatenate all the good data. We will average for a
                    % reliable estimate of threshold.
                    thresh(iSubject).quest{iSession} = [thresh(iSubject).quest{iSession} 10^t(1) 10^t(2)];
                end
                cd(sprintf(fullfile(parentDir,dataDir)));
            end
            
            % Mark as a bad session if threshold estimates are greater than
            % 100%
            badSession1 = thresh(iSubject).quest{iSession} >= 1;
            thresh(iSubject).quest{iSession}(badSession1==1) = NaN;
          
            % Record the number of good staircases
            thresh(iSubject).nStairs(iSession) = sum(~isnan(thresh(iSubject).quest{iSession}));
            
        else
            fprintf('Spacerace data do not exist: subject[%s], session[%d]',subjectList{iSubject},iSession);
        end
    end
    
    % Total excluded blocks per subject
    excludedRun(iSubject) = sum(sum(thresh(iSubject).badRun));
end

% Collect subject ages
for iSubject = 1:length(subjectList)
    dysAge(iSubject) = thresh(iSubject).age;
end

% Initialize variables for reading scores as a matrix on NaN
wj.lwid.ss = NaN *ones(length(subjectList),4);
wj.wa.ss = NaN *ones(length(subjectList),4);
wj.brs = NaN *ones(length(subjectList),4);

% Read in each subjects scores
for iSubject = 1: length(subjectList)
    % Find the subject
    temp2.row = [];
    for i = 1: length(T.Subject)
        if T.Subject == str2num(subjectList{iSubject})
            temp2.row = [temp2.row i];
        end
    end
    for iSession = 1: max(T.LMB_session(T.Subject == str2num(subjectList{iSubject})))
        % Find the session
        if T.spacerace(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject}))
            wj.lwid.ss(iSubject,iSession) = T.WJ_LWID_SS(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject}));
            wj.wa.ss(iSubject,iSession) = T.WJ_WA_SS(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject}));
            wj.brs(iSubject,iSession) = T.WJ_BRS(T.LMB_session == iSession & T.Subject == str2num(subjectList{iSubject}));
        end
    end
end

% y will be session average motion thresholds
y = NaN*ones(length(subjectList),4);

% Looping over subjects
for i = 1:length(subjectList)
    % Looping over sessions
    for j = 1: size(thresh(i).quest,2)
        % Taking the mean of all the good QUEST runs within a session. Bad
        % QUEST runs are nan
        y(i,j) = nanmean(thresh(i).quest{j});
    end
end

%% Get thresholds for control (non-intervention) subjects
% Note that some of these subjects are dyslexic. By control we mean
% non-intervention.

cd(fullfile(parentDir,dataDir));

% This subject group includes both good and poor readers who did not
% participate in the intervention
controlSubjects = {'105','108','109','117','127','130','132','133'...
    '138','143','146','155','165','167','175','176','177', ...
    '178','181','182','184','185','186','187','188','195','197','199'};

yControl = NaN *ones(length(controlSubjects),1);

for iSubject = 1: length(controlSubjects)
    baseline.name{iSubject} = controlSubjects{iSubject};
    temp.age = T.Age(T.Subject == str2num(controlSubjects{iSubject}));
    temp.id = find(T.Subject == str2num(controlSubjects{iSubject}));
    baseline.age(iSubject) = temp.age(1)/12;
    baseline.id(iSubject) = temp.id(1);
    d = dir(sprintf('%s_*',baseline.name{iSubject}));
    temp.session = [];
    for i = 1: length(d)
        temp.session = [temp.session; d(i).name(5:12)];
    end
    session = unique(temp.session,'rows');
    
    for iSession = 1: size(session,1)
        
        d = dir(sprintf('%s_%s*',controlSubjects{iSubject}, ...
            num2str(session(iSession,:))));
        baseline.quest{iSubject,iSession} = [];
        baseline.when{iSubject,iSession} = sprintf('%s',d(1).name(8:15));
        
        for j = 1: length(d)
            load(d(j).name);
            
            if sum(result.response(config.randOrder==999))/length(result.response(config.randOrder==999)) <= badCriterion
                baseline.badRun(iSubject,j) = 1;
            else
                baseline.badRun(iSubject,j) = 0;
                [t(1), sd(1), betaEstimate(1), betaSd(1)] = QuestBetaAnalysis_Joo(result.q(1));
                [t(2), sd(2), betaEstimate(2), betaSd(2)] = QuestBetaAnalysis_Joo(result.q(2));
                
                baseline.quest{iSubject,iSession} = [baseline.quest{iSubject,iSession} 10^t(1) 10^t(2)];
            end
            cd(sprintf('%s/%s',parentDir,dataDir));
        end
        
        badSession1 = baseline.quest{iSubject,iSession} >= 1;
        baseline.quest{iSubject,iSession}(badSession1==1) = NaN;
        
        baseline.nStairs(iSubject,iSession) = sum(~isnan(baseline.quest{iSubject,iSession}));
        
        excludedRun(iSubject) = sum(sum(baseline.badRun(iSubject,:)));
        % Session average motion thresholds
        yControl(iSubject,iSession) = nanmean(baseline.quest{iSubject,iSession});
    end
end

% Read reading scores
for ii = 1: length(controlSubjects)
    baseline.brs(ii) = T.WJ_BRS(baseline.id(ii));
    baseline.wj.lwidSS(ii) = T.WJ_LWID_SS(baseline.id(ii));
    baseline.wj.waSS(ii) = T.WJ_WA_SS(baseline.id(ii));
    cd(fullfile(parentDir,dataDir));
end

%% Plot correlation between motion sensitivity and Basic Reading (Figure 1)

figure(1); clf; hold on;

% Concatenate reading scores and motion thresholds
readingAll = [wj.brs(~isnan(y(:,1)),1); baseline.brs'];
motionAll = [y(~isnan(y(:,1)),1); yControl(:,1)];

[b1All,~,~,~,statsAll] = regress(readingAll, [ones(length(readingAll),1), motionAll]);

x = linspace(.05,.65,100);
yFit = b1All(1) + b1All(2)*x;
plot(x, yFit, 'Color',[0 0 0],'LineWidth',2);

plot(motionAll,readingAll,'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',9);

text(.48, 80, sprintf('r = -%0.2f, p = %0.3f',sqrt(statsAll(1)),statsAll(3)),'Color',[0 0 0],'FontName','Arial','FontSize',12);
set(gca,'XLim',[-.05 .7],'YLim',[45 130],'XTick',0:.1:.7,'XTickLabel',{'0','10','20','30','40','50','60','70'},'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)

xlabel('Motion discrimination threshold (% coherence)','FontName','Arial','FontSize',16);
ylabel('Basic reading skills','FontName','Arial','FontSize',16);
title('Figure 1')
axis square

% Concatenate WID and WA scores
widAll = [wj.lwid.ss(~isnan(y(:,1)),1); baseline.wj.lwidSS'];
waAll = [wj.wa.ss(~isnan(y(:,1)),1); baseline.wj.waSS'];

% Define dyslexia 
dysID2 = widAll < 90 | waAll < 90;

% Non-parametric test
pVal = ranksum(motionAll(dysID2), motionAll(~dysID2));

%% Bootstrapping confidence intervals on correlation coefficient

% Bootstrapping
nBoots = 10e3;
bootStats = bootstrp(nBoots, @corr, readingAll, motionAll);
% Calculate 99% Confidence interval
CI = prctile(bootStats,[0.5 99.5]);

figure(2); clf; hold on;
if exist('histogram','builtin')
    histogram(bootStats)
else
    hist(bootStats);
end
ylim = get(gca, 'YLim');
plot(CI(1)*[1 1], ylim, '-', 'Color', ccolor(5,:), 'LineWidth', 2);
plot(CI(2)*[1 1], ylim, '-', 'Color', ccolor(5,:), 'LineWidth', 2);
plot(-sqrt(statsAll(1))*[1 1], ylim, '-', 'Color', ccolor(1,:), 'LineWidth', 2);
set(gca,'XLim',[-0.8 0.1])
xlabel('Correlation coefficient')
ylabel('Frequency')

%% Mixed linear model of growth in reading scores

motion = [];
session = [];
subject = [];
br = [];

% Format the data structure for mixed effects model
for i = 1: length(subjectList)
    for j = 1: 4
        motion = [motion; y(i,j)];
        session = [session; j];
        subject = [subject; i];
        br = [br; wj.brs(i,j)];
    end
end
% session = nominal(session);
subject = nominal(subject);

ds = dataset(subject,session,motion,br);

lme = fitlme(ds, 'br ~ session +(1|subject)');

% If you want to include session as a random effect
% lme2 = fitlme(ds, 'br ~ session +(session|subject)');

%% Figure 2a - Growth in reading scores during the intervention

figure(4); clf; hold on;

for i = 1: 4
    plot([i,i],[nanmean(wj.brs(:,i))-nanstd(wj.brs(:,i))/sqrt(length(wj.brs(:,i))),nanmean(wj.brs(:,i))+nanstd(wj.brs(:,i))/sqrt(length(wj.brs(:,i)))], ...
        '-','Color',[0 0 0],'LineWidth',1);
    plot(i,nanmean(wj.brs(:,i)),'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',12);
end

plot([.9 4.1],[100 100],'--','Color',[0 0 0],'LineWidth',1)
set(gca,'YLim',[73,105],'YTick',75:10:105,'XLim',[.5 4.5],'XTick',1:4,'XTickLabel',1:4,'TickDir','out','FontName','Arial','FontSize',12,'LineWidth',1); %{'Session1','Session2','Session3','Session4'});

axis square
ylabel('Basic reading skills','FontName','Arial','FontSize',16);

lmReading = fitlm([1:4],[nanmean(wj.brs(:,1)) nanmean(wj.brs(:,2)) nanmean(wj.brs(:,3)) nanmean(wj.brs(:,4))]);

readingInterceptReading(1) = lmReading.Coefficients.Estimate(1);
readingSlopeReading(1) = lmReading.Coefficients.Estimate(2);
title('Figure 2a')

%% Analysis of thresholds by block (Figure 2b)
% The purpose of this is to charachterize the task-learning effect.
% We pull out thresholds for each block. There are 3 blocks per session.
% And 4 sessions. Then we fit an exponential decay function to sumarize how
% thresholds change as a function of practice without any need to account
% for intervention driven learning effects.

% Applying two different criteria for defining dyslexia
low = wj.lwid.ss(:,1)<90 | wj.wa.ss(:,1)<90;
low2 = wj.lwid.ss(:,1)<85 | wj.wa.ss(:,1)<85;

figure(3); clf; hold on;
set(gca,'FontName','Arial','FontSize',14)
blockData = NaN*ones(6,4,length(subjectList));
% Get each block data
for i = 1: length(subjectList)
    for j = 1: 4 % session
        for k = 1: length(thresh(i).quest{j})
            blockData(k,j,i) = thresh(i).quest{j}(k); % run X session X subject
        end
    end
end

yBlock = [];
errBlock = [];
yLow2 = [];
yLowErr2 = [];
yLow = [];
yLowErr = [];
% Each block has two runs
for session = 1: 4
    yBlock = [yBlock nanmean([squeeze(blockData(1,session,:)); squeeze(blockData(2,session,:))]) ...
        nanmean([squeeze(blockData(3,session,:)); squeeze(blockData(4,session,:))]) ...
        nanmean([squeeze(blockData(5,session,:)); squeeze(blockData(6,session,:))])];
    errBlock = [errBlock nanstd([squeeze(blockData(1,session,:)); squeeze(blockData(2,session,:))])/sqrt(sum(~isnan([squeeze(blockData(1,session,:)); squeeze(blockData(2,session,:))]))) ... ...
        nanstd([squeeze(blockData(3,session,:)); squeeze(blockData(4,session,:))])/sqrt(sum(~isnan([squeeze(blockData(3,session,:)); squeeze(blockData(4,session,:))]))) ...
        nanstd([squeeze(blockData(5,session,:)); squeeze(blockData(6,session,:))])/sqrt(sum(~isnan([squeeze(blockData(5,session,:)); squeeze(blockData(6,session,:))])))];

    yLow = [yLow nanmean([squeeze(blockData(1,session,low)); squeeze(blockData(2,session,low))]) ...
        nanmean([squeeze(blockData(3,session,low)); squeeze(blockData(4,session,low))]) ...
        nanmean([squeeze(blockData(5,session,low)); squeeze(blockData(6,session,low))])];
    yLowErr = [yLowErr nanstd([squeeze(blockData(1,session,low)); squeeze(blockData(2,session,low))])/sqrt(sum(~isnan([squeeze(blockData(1,session,low)); squeeze(blockData(2,session,low))]))) ... ...
        nanstd([squeeze(blockData(3,session,low)); squeeze(blockData(4,session,low))])/sqrt(sum(~isnan([squeeze(blockData(3,session,low)); squeeze(blockData(4,session,low))]))) ...
        nanstd([squeeze(blockData(5,session,low)); squeeze(blockData(6,session,low))])/sqrt(sum(~isnan([squeeze(blockData(5,session,low)); squeeze(blockData(6,session,low))])))];

    yLow2 = [yLow2 nanmean([squeeze(blockData(1,session,low2)); squeeze(blockData(2,session,low2))]) ...
        nanmean([squeeze(blockData(3,session,low2)); squeeze(blockData(4,session,low2))]) ...
        nanmean([squeeze(blockData(5,session,low2)); squeeze(blockData(6,session,low2))])];
    yLowErr2 = [yLowErr2 nanstd([squeeze(blockData(1,session,low2)); squeeze(blockData(2,session,low2))])/sqrt(sum(~isnan([squeeze(blockData(1,session,low2)); squeeze(blockData(2,session,low2))]))) ... ...
        nanstd([squeeze(blockData(3,session,low2)); squeeze(blockData(4,session,low2))])/sqrt(sum(~isnan([squeeze(blockData(3,session,low2)); squeeze(blockData(4,session,low2))]))) ...
        nanstd([squeeze(blockData(5,session,low2)); squeeze(blockData(6,session,low2))])/sqrt(sum(~isnan([squeeze(blockData(5,session,low2)); squeeze(blockData(6,session,low2))])))];
end

xxx = 1:12;
patch([xxx fliplr(xxx)],[(yBlock(3)-errBlock(3))*ones(1,12) fliplr((yBlock(3)+errBlock(3))*ones(1,12))],[.4 .4 .4],'FaceAlpha',.5,'LineStyle','none')

plot([3.5 3.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
plot([6.5 6.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
plot([9.5 9.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
set(gca,'XLim',[0 13],'XTIck',1:12,'XTicklabel',{'1','2','3','1','2','3','1','2','3','1','2','3'},'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
set(gca,'YLim',[.05 .45],'YTIck',.1:.1:.4,'YTickLabel',{'10','20','30','40'},'LineWidth',1,'FontName','Arial','FontSize',12)

xlabel('Block within a session','FontName','Arial','FontSize',18)
ylabel('Motion threshold (% coherence)','FontName','Arial','FontSize',18)

options = optimset('MaxFunEvals',1e7,'MaxIter',1e7);

x = 1:12;
obs = yBlock;

% All subjects
p0 = [2 .15 obs(1)]; % initial points -- lamda, y shift, first block data

f = @(x,p)p(2) + p(3)*exp(-x./p(1)); % exponential decay function
errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2); % error function to minimize

p = fminsearch(errf,p0,options,x,obs);

realX = linspace(1,12,100);
plot(realX,f(realX,p), '-', 'Color', [0 0 0],'LineWidth',2);
meanLamda = p(1); % growth rate
meanYShift = p(2); % asymptote

for i = 1: length(errBlock)
    plot([i i],[yBlock(i)-errBlock(i) yBlock(i)+errBlock(i)],'-','Color',[0 0 0],'LineWidth',1);
end
plot(yBlock,'o','MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],'MarkerSize',10);

title('Figure 2b')

% Non-parametric test
[pVal,n] = signrank(nanmean([squeeze(blockData(1,1,:)) squeeze(blockData(2,1,:))],2),meanYShift);

%% Supplementary figure 2
% Figure 2b does not depend on any specific definition of dyslexia
% This code takes a while to run because we bootstrap the exponential fits

% Low group 1
figure(30); clf; hold on;

nBoots = 5e3;
% Bootstrap here and fit each bootstrapped sample
for session = 1: 4
    yLowBoot{1,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(1,session,low))),2);
    yLowBoot{2,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(2,session,low))),2);
    yLowBoot{3,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(3,session,low))),2);
    yLowBoot{4,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(4,session,low))),2);
    yLowBoot{5,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(5,session,low))),2);
    yLowBoot{6,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(6,session,low))),2);
    
    yLow2Boot{1,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(1,session,low2))),2);
    yLow2Boot{2,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(2,session,low2))),2);
    yLow2Boot{3,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(3,session,low2))),2);
    yLow2Boot{4,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(4,session,low2))),2);
    yLow2Boot{5,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(5,session,low2))),2);
    yLow2Boot{6,session} = nanmean(bootstrp(nBoots, @(x) x, squeeze(blockData(6,session,low2))),2);
end

for i = 1: length(errBlock)
    plot([i i],[yLow(i)-yLowErr(i) yLow(i)+yLowErr(i)],'-','Color',ccolor(1,:));
end
plot(yLow,'o','MarkerFaceColor',ccolor(1,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',10);

for i = 1: length(errBlock)
    plot([i i],[yLow2(i)-yLowErr2(i) yLow2(i)+yLowErr2(i)],'-','Color',ccolor(2,:));
end
plot(yLow2,'o','MarkerFaceColor',ccolor(2,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',10);

% From main analysis
plot(realX,f(realX,p), '-', 'Color', [0 0 0],'LineWidth',2);

% Low Group 1
% Using MATLAB parallel toolbox it takes 93 seconds
% Without parallel toolbox it takes 266 seconds
% If parallel toolbox is unavailable, simply replace 'parfor' with 'for'
tic
parfor iBoot = 1: nBoots
    obs = [];
    for iSession = 1: 4
        obs = [obs mean([yLowBoot{1,iSession}(iBoot);yLowBoot{2,iSession}(iBoot)]) mean([yLowBoot{3,iSession}(iBoot);yLowBoot{4,iSession}(iBoot)]) ...
            mean([yLowBoot{5,iSession}(iBoot);yLowBoot{6,iSession}(iBoot)])];
    end
    p0 = [2 .15 obs(1)]; % lamda, y shift, initial point

    f = @(x,p)p(2) + p(3)*exp(-x./p(1));
    errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2);

    pBoot(iBoot,:) = fminsearch(errf,p0,options,x,obs);
end
toc
bootCI = prctile(pBoot(:,2),[16 84]);
patch([xxx fliplr(xxx)],[bootCI(1)*ones(1,12) bootCI(2)*ones(1,12)],ccolor(1,:),'FaceAlpha',.3,'LineStyle','none')

obs = yLow;

p0 = [2 .15 obs(1)]; % lamda, y shift, initial point

f = @(x,p)p(2) + p(3)*exp(-x./p(1));
errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2);

p = fminsearch(errf,p0,options,x,obs);

realX = linspace(1,12,100);
plot(realX,f(realX,p), '-', 'Color', ccolor(1,:),'LineWidth',2);

clear pBoot

% Low group 2
tic
parfor iBoot = 1: nBoots
    obs = [];
    for iSession = 1: 4
        obs = [obs mean([yLow2Boot{1,iSession}(iBoot);yLow2Boot{2,iSession}(iBoot)]) mean([yLow2Boot{3,iSession}(iBoot);yLow2Boot{4,iSession}(iBoot)]) ...
            mean([yLow2Boot{5,iSession}(iBoot);yLow2Boot{6,iSession}(iBoot)])];
    end
    p0 = [2 .15 obs(1)]; % lamda, y shift, initial point

    f = @(x,p)p(2) + p(3)*exp(-x./p(1));
    errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2);

    pBoot(iBoot,:) = fminsearch(errf,p0,options,x,obs);
end
toc
bootCI = prctile(pBoot(:,2),[16 84]);
patch([xxx fliplr(xxx)],[bootCI(1)*ones(1,12) bootCI(2)*ones(1,12)],ccolor(2,:),'FaceAlpha',.3,'LineStyle','none')

obs = yLow2;

p0 = [2 .15 obs(1)]; % lamda, y shift, initial point

f = @(x,p)p(2) + p(3)*exp(-x./p(1));
errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2);

p = fminsearch(errf,p0,options,x,obs);

realX = linspace(1,12,100);
plot(realX,f(realX,p), '-', 'Color', ccolor(2,:),'LineWidth',2);

plot([3.5 3.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
plot([6.5 6.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
plot([9.5 9.5],[0 .5],'--','Color',[0 0 0],'LineWidth',1)
set(gca,'XLim',[0 13],'XTIck',1:12,'XTicklabel',{'1','2','3','1','2','3','1','2','3','1','2','3'},'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
set(gca,'YLim',[.05 .45],'YTIck',.1:.1:.4,'YTickLabel',{'10','20','30','40'},'LineWidth',1,'FontName','Arial','FontSize',12)

xlabel('Block within a session','FontName','Arial','FontSize',18)
ylabel('Motion threshold (% coherence)','FontName','Arial','FontSize',18)

title('Supplementary Figure 2')

%% Figure 3 - Reading score growth split by motion sensitivity
% Compare growth rates for subjects with low versus high motion sensitivity

% Median split based on the first session
high = y(:,1) > nanmedian(y(:,1));
low = y(:,1) <= nanmedian(y(:,1));

figure(5); clf; hold on;
% set(gca,'FontName','Arial','FontSize',14)
nReps = 10e3;

for i = 1: 4
    boot1.dist = mean(bootstrp(nReps, @(x) x, wj.brs(high,i)),2);
    boot1.ci = prctile(boot1.dist, [16 84]);
    boot2.dist = mean(bootstrp(nReps, @(x) x, wj.brs(low,i)),2);
    boot2.ci = prctile(boot2.dist, [16 84]);
    
    plot([i,i],[boot1.ci(1) boot1.ci(2)], '-','Color',[0 0 0],'LineWidth',1);
    plot(i,nanmean(wj.brs(high,i)),'o','MarkerFaceColor',ccolor(2,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9,'LineWidth',1);
    
    plot([i,i],[boot2.ci(1) boot2.ci(2)], '-','Color',[0 0 0],'LineWidth',1);
    plot(i,nanmean(wj.brs(low,i)),'o','MarkerFaceColor',ccolor(1,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9,'LineWidth',1);
end

set(gca,'YLim',[65 110],'YTick',70:10:110,'XLim',[.5 4.5],'XTick',1:4,'FontName','Arial','FontSize',12,'TickDir','out','LineWidth',1);
axis square
% set(gca,'YLim',[65 105]);
ylabel('Basic reading skills','FontName','Arial','FontSize',16);

lmHigh = fitlm([1:4],[nanmean(wj.brs(high,1)) nanmean(wj.brs(high,2)) nanmean(wj.brs(high,3)) nanmean(wj.brs(high,4))]);
lmLow = fitlm([1:4],[nanmean(wj.brs(low,1)) nanmean(wj.brs(low,2)) nanmean(wj.brs(low,3)) nanmean(wj.brs(low,4))]);
readingInterceptAll(1) = lmHigh.Coefficients.Estimate(1);
readingSlopeAll(1) = lmHigh.Coefficients.Estimate(2);
readingInterceptAll(2) = lmLow.Coefficients.Estimate(1);
readingSlopeAll(2) = lmLow.Coefficients.Estimate(2);

% Bootstrap the slope!!!
for iSubject = 1: length(subjectList)
    temp1 = fitlm([1:4],wj.brs(iSubject,:));
    slopeSubject(iSubject) = temp1.Coefficients.Estimate(2);
end

nBoots = 10e3;
boot.high = mean(PsychRandSample(slopeSubject(high),[sum(high) nBoots]));
boot.low = mean(PsychRandSample(slopeSubject(low),[sum(low) nBoots]));
boot.ci.high = prctile(boot.high,[2.5 97.5]);
boot.ci.low = prctile(boot.low,[2.5 97.5]);

title('Figure 3')

%% Supplementary Figure 3 - Reading growth does not depend on motion sensitivity

for iSubject = 1: length(subjectList)
    lm = fitlm([1:4],wj.brs(iSubject,:));
    readingIntercept(iSubject) = lm.Coefficients.Estimate(1);
    readingSlope(iSubject) = lm.Coefficients.Estimate(2);
end

[b1All,~,~,~,statsAll] = regress(readingSlope', [ones(length(readingIntercept),1) y(:,1)]);

figure(6); clf; hold on;
set(gca,'FontName','Arial','FontSize',14)
x = linspace(0, .7,100);
yFit = b1All(1) + b1All(2)*x;
plot(x, yFit, 'Color',[0 0 0],'LineWidth',2);

plot(y(:,1), readingSlope,'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',9);
set(gca,'XTickLabel',{'0','20','40','60','80'})
xlabel('Motion discrimination threshold (% coherence)')
ylabel('Learning growth rate')
title('Supplementary figure 3')

