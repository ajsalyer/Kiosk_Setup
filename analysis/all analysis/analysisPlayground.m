%% analysisPlayground -- thin wrapper around the mGLO analysis set.
%
% The analyses used to live here as local functions with hardcoded 4-char
% labels and 7 legacy blocks. They now live in analysis/ as proper
% functions sharing one condition map (mgloCondMap, 26 conditions,
% 6-char VAVAVA labels, 8 virtual blocks) and work with
% mGLO_conditions_main.txt, ACTIVE or passive.
%
%   1. load:  bhv = mlBHVunifier(baseFilename, bhvPath);
%   2. run:   R = mgloAnalyzeSession(bhv);
%   3. extra: R = mgloAnalyzeSession(bhv, struct('psychometric',true,'signal',true,'goal',true));
%
% Files are matched as <yymmdd>_<subject>*.bhv2, so only ONE subject's
% sessions from today are merged. Set subject to '' to merge every subject
% recorded today (rarely what you want).

subject = 'Joule';
bhvPath = ' ';                       % ' ' = current folder
baseFilename = datestr(datetime('today'), 'yymmdd'); %#ok<DATST>
if ~isempty(subject)
    baseFilename = [baseFilename '_' subject];
end
bhv = mlBHVunifier(baseFilename, bhvPath);

% Minimal complete set: tokens, type x context, virtual blocks, RTs.
R = mgloAnalyzeSession(bhv, struct('subject', subject));

% Opt-ins (ex- commented-out playground calls):
% R = mgloAnalyzeSession(bhv, struct('subject', subject, 'psychometric', true));
% R = mgloAnalyzeSession(bhv, struct('subject', subject, 'signal', true));
% R = mgloAnalyzeSession(bhv, struct('subject', subject, 'goal', true));
