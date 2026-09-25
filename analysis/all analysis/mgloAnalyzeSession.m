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
%     tag           ''     filename suffix ('' = session date, so repeat
%                          runs on different sessions do not overwrite)
%     saveResults   true   write R to <repo>/analysis/results as a .mat and
%                          append a summary row to sessions.csv
%     resultsdir    ''     results folder ('' = <repo>/analysis/results)
%     subject       ''     subject name, used in the results filename and
%                          recorded in sessions.csv
%
%   Saved .jpg paths are collected in R.figures, saved result paths in
%   R.results.
%
%   Works with sessions run under mGLO_conditions_1block.txt or
%   mGLO_conditions_main.txt (identical 26-condition sets), in ACTIVE and
%   passive mode. Example:
%     bhv = mlBHVunifier('260921_mGLO', 'C:\data');
%     R = mgloAnalyzeSession(bhv);

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
try
    R.date = sprintf('%02d/%02d/%02d', bhv.TrialDateTime(end, 2:4));
catch
    R.date = '';
end

% Default the figure-name suffix to the session date so successive sessions
% do not overwrite each other's .jpg files.
tag = opts.tag;
if isempty(tag), tag = strrep(R.date, '/', ''); end

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

% Collect the .jpg files written this run (empty when saving is off).
R.figures = {};
if opts.plots && opts.save
    if ~isempty(opts.savedir), figDir = opts.savedir;
    else, figDir = fullfile(analysisDir, 'figures'); end
    if isfolder(figDir)
        d = dir(fullfile(figDir, '*.jpg'));
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
    'resultsdir', opts.resultsdir, 'tag', tag, 'subject', opts.subject));
end
