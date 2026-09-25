%% analysisPlayground -- thin wrapper around the mGLO analysis set.
%
% The analyses used to live here as local functions with hardcoded 4-char
% labels and 7 legacy blocks. They now live in analysis/ as proper
% functions sharing one condition map (mgloCondMap, 26 conditions,
% 6-char VAVAVA labels, 8 virtual blocks) and work with both
% mGLO_conditions_1block.txt and mGLO_conditions_main.txt, ACTIVE or passive.
%
%   1. load:  bhv = mlBHVunifier(baseFilename, bhvPath);
%   2. run:   R = mgloAnalyzeSession(bhv);
%   3. extra: R = mgloAnalyzeSession(bhv, struct('psychometric',true,'signal',true,'goal',true));

bhvPath = ' ';
baseFilename = datestr(datetime('today'), 'yymmdd');
bhv = mlBHVunifier(baseFilename, bhvPath);

% Minimal complete set: tokens, type x context, virtual blocks, RTs.
R = mgloAnalyzeSession(bhv);

% Opt-ins (ex- commented-out playground calls):
% R = mgloAnalyzeSession(bhv, struct('psychometric', true));
% R = mgloAnalyzeSession(bhv, struct('signal', true));
% R = mgloAnalyzeSession(bhv, struct('goal', true));
