function R = mgloPlotReactionTimes(bhv, CONST, opts)
%mgloPlotReactionTimes  RT distributions for correct vs incorrect choices.
%
%   R = mgloPlotReactionTimes(bhv, CONST) computes RTs with mgloCalculateRT
%   when bhv.ReactionTime is missing, then plots the correct/incorrect
%   histograms plus a boxplot spread. Passive sessions (no code 109/50,
%   e.g. fixation-only) have no RTs: prints a note and returns R with empty
%   fields instead of erroring.
%
%   opts.plots (default true) controls figure creation. Returns R with
%   rtCorr/rtErr vectors and median/mean/count summaries.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

R = struct('rtCorr', [], 'rtErr', [], 'medCorr', NaN, 'medErr', NaN, ...
           'meanCorr', NaN, 'meanErr', NaN, 'nCorr', 0, 'nErr', 0);

if ~isfield(bhv, 'ReactionTime')
    bhv = mgloCalculateRT(bhv);
end

rts = bhv.ReactionTime(:);
errs = bhv.TrialError(:);
n = min(numel(rts), numel(errs));
rts = rts(1:n);
errs = errs(1:n);

ok = ~isnan(rts);
rts = rts(ok);
errs = errs(ok);

rtCorr = rts(errs == CONST.CORRECT);
rtErr  = rts(errs == CONST.INCORRECT);

R.rtCorr = rtCorr;
R.rtErr = rtErr;
R.nCorr = numel(rtCorr);
R.nErr = numel(rtErr);
if ~isempty(rtCorr)
    R.medCorr = median(rtCorr);
    R.meanCorr = mean(rtCorr);
end
if ~isempty(rtErr)
    R.medErr = median(rtErr);
    R.meanErr = mean(rtErr);
end

if isempty(rtCorr) && isempty(rtErr)
    fprintf('mgloPlotReactionTimes: no valid RT data (no codes 109/50 -- passive session?). Skipping.\n');
    return;
end
if ~opts.plots, return; end

fh = figure('Name', 'Chronometry');
subplot(2,1,1);
hold on;
if ~isempty(rtCorr)
    histogram(rtCorr, 40, 'Normalization', 'probability', ...
        'FaceColor', 'g', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'Correct');
end
if ~isempty(rtErr)
    histogram(rtErr, 40, 'Normalization', 'probability', ...
        'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'Incorrect');
end
legend('show');
xlabel('Reaction Time (ms, code 50 - code 109)');
ylabel('Probability');
title('Reaction Time Distribution');
grid on;
hold off;

subplot(2,1,2);
data = [rtCorr; rtErr];
group = [zeros(numel(rtCorr), 1); ones(numel(rtErr), 1)];
if ~isempty(data)
    boxplot(data, group, 'Labels', {'Correct', 'Incorrect'}, 'Symbol', 'k.');
    ylabel('RT (ms)');
    title(sprintf('RT Spread (med %.0f vs %.0f ms)', R.medCorr, R.medErr));
    grid on;
end
mgloSaveFigure(fh, 'Chronometry', opts);
end
