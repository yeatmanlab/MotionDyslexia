function q = PrepareQuest(config)

nInterval = 2;
tGuess = config.startPoint;
tGuessSd = 0.5;
pThreshold = 0.82; % performance
beta = 3.5;
delta = 0.01;
gamma = 1 / nInterval;
% grain = .001;
% range = .8;

for i = 1: config.nStairs
	q(i) = QuestCreate(log10(tGuess), tGuessSd, pThreshold, beta, delta, gamma);
end