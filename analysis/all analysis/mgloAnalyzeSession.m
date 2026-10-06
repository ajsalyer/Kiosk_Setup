function R = mgloAnalyzeSession(bhv, opts)
%mgloAnalyzeSession  Minimal complete offline analysis for one mGLO session.
%
%   R = mgloAnalyzeSession(bhv) runs the full set on a bhv struct as
%   returned by mlBHVunifier/mlread (fields Trial, TrialError, Condition,
%   Block, UserVars, BehavioralCodes):
%     - token economics (accuracy vs token balance)
%     - performance by deviance type x context (+ split-half stability)
%     - performance by virtual schedule block
%     - reaction times (active choice trials; skipped cleanly when passive)
%   and returns everything in R (plots are figures; data stays in R even
%   with plotting off).
%
%   opts fields (all default as in the old playground script):
%     plots         true   create figures
%     psychometric  false  add GuideScale psychometric curve
%     signal        false  add d-prime / criterion per deviance type
%     goal          false  add token goal-gradient analysis
%     guideThresh   0.99   GuideScale threshold marking guided trials
%     save          true   write every figure to disk as a .jpg
%     savedir       ''     figure folder ('' = <repo>/analysis/figures)
%     tag           ''     filename suffix ('' = the session's start time,
%                          yymmdd_HHMMSS, so sessions never overwrite each
%                          other, even two on the same day)
%     saveResults   true   write R to <repo>/analysis/results as a .mat and
%                          append a summary row to sessions.csv
%     resultsdir    ''     results folder ('' = <repo>/analysis/results)
%     subject       ''     subject name, used in the results filename and
%                          recorded in sessions.csv
%
%   The .jpg paths written by THIS run are collected in R.figures, saved
%   result paths in R.results. R.sessionKey (yymmdd_HHMMSS of the first
%   trial, see mgloSessionStart) identifies the session in sessions.csv, so
%   re-analysing it -- by hand or automatically, under any tag -- replaces
%   its row instead of adding a duplicate.
%
%   Works with sessions run under mGLO_conditions_main.txt, in ACTIVE and
%   passive mode. Example:
%     bhv = mlconcatenate('260925_Joule_mGLO_conditions_main.bhv2');
%     R = mgloAnalyzeSession(bhv, struct('subject', 'Joule'));

if nargin < 2 || isempty(opts), opts = struct(); end
defs = struct('plots', true, 'psychometric', false, 'signal', false, ...
              'goal', false, 'guideThresh', 0.99, 'save', true, ...
              'savedir', '', 'tag', '', 'saveResults', true, ...
              'resultsdir', '', 'subject', '');
fn = fieldnames(defs);
for i = 1:numel(fn)
    if ~isfield(opts, fn{i}), opts.(fn{i}) = defs.(fn{i}); end
end

% The plot functions live in the sibling analysis/performance folder; make
% sure both halves of analysis/ are reachable however this was called.
analysisDir = fileparts(fileparts(mfilename('fullpath')));
if isempty(strfind([path pathsep], [fullfile(analysisDir, 'performance') pathsep])) %#ok<STREMP>
    addpath(genpath(analysisDir));
end

CONST = mgloErrorConsts();
R = struct();
R.nTrials = numel(bhv.Trial);
R.const = CONST;
[~, R.sessionKey, R.date] = mgloSessionStart(bhv);   % date is mm/dd/yy

% Default the figure-name suffix to the session start time so successive
% sessions -- including two on the same day -- do not overwrite each
% other's .jpg files.
tag = opts.tag;
if isempty(tag), tag = R.sessionKey; end

% Figures written from here on belong to this run (see R.figures below).
runStart = now; %#ok<TNOW1>

plotOpts = struct('plots', opts.plots, 'save', opts.save, ...
                  'savedir', opts.savedir, 'tag', tag);

R.token     = mgloPlotTokenPerformance(bhv, CONST, plotOpts);
R.byType    = mgloPlotPerformanceByCondition(bhv, CONST, plotOpts);
R.byBlock   = mgloPlotPerformanceByBlock(bhv, CONST, opts.guideThresh, plotOpts);
R.rt        = mgloPlotReactionTimes(bhv, CONST, plotOpts);

if opts.psychometric
    R.psychometric = mgloPlotPsychometric(bhv, CONST, plotOpts);
end
if opts.signal
    R.signal = mgloPlotSignalDetection(bhv, CONST, plotOpts);
end
if opts.goal
    R.goal = mgloPlotGoalGradient(bhv, CONST, plotOpts);
end

% Collect the .jpg files written this run (empty when saving is off). The
% folder also holds every earlier session's figures and control screens, so
% keep only files modified since this run started (2 s of slack for
% filesystem timestamp resolution).
R.figures = {};
if opts.plots && opts.save
    if ~isempty(opts.savedir), figDir = opts.savedir;
    else, figDir = fullfile(analysisDir, 'figures'); end
    if isfolder(figDir)
        d = dir(fullfile(figDir, '*.jpg'));
        d = d([d.datenum] >= runStart - 2/86400);
        R.figures = fullfile(figDir, {d.name});
    end
    fprintf('mgloAnalyzeSession: figures saved as .jpg in %s\n', figDir);
end

engaged = ismember(bhv.TrialError(:), [CONST.CORRECT, CONST.INCORRECT]);
R.nEngaged = sum(engaged);
R.nCorrect = sum(bhv.TrialError(:) == CONST.CORRECT);
if 0 < R.nEngaged
    R.overallAcc = 100 * R.nCorrect / R.nEngaged;
else
    R.overallAcc = NaN;
end
fprintf('mgloAnalyzeSession: %d trials, %d engaged, %d correct (%.1f%%).\n', ...
    R.nTrials, R.nEngaged, R.nCorrect, R.overallAcc);

% Persist last, so the saved struct contains the session totals above.
R.results = mgloSaveResults(R, struct('save', opts.saveResults, ...
    'resultsdir', opts.resultsdir, 'tag', tag, 'subject', opts.subject, ...
    'key', R.sessionKey));
end
