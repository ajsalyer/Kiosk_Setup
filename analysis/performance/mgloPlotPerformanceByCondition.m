function R = mgloPlotPerformanceByCondition(bhv, CONST, opts)
%mgloPlotPerformanceByCondition  Accuracy by deviance type x context.
%
%   R = mgloPlotPerformanceByCondition(bhv, CONST) groups trials with
%   mgloCondMap (26 conditions -> 4 deviance types x 2 contexts) instead of
%   the old assumption of -R/-L condition pairs or 4-char labels. Works with
%   both mGLO_conditions_1block.txt and mGLO_conditions_main.txt.
%
%   Figure 1: grouped bars (type x context) with engaged-trial counts --
%   the same view as the live mGLO_userplot, for offline checking.
%   Figure 2: split-half stability (first vs second half of session).
%
%   opts.plots (default true) controls figure creation. Returns R with
%   acc (4x2 %), cnt (4x2 engaged n), condAcc/condN (per condition),
%   splitAcc (2x4 %: halves x types) and nEngaged/nCorrect session totals.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

M = mgloCondMap();
cond = bhv.Condition(:)';
err  = bhv.TrialError(:)';
n    = min(numel(cond), numel(err));
cond = cond(1:n);
err  = err(1:n);

valid   = cond >= 1 & cond <= M.NCOND;
engaged = ismember(err, [CONST.CORRECT, CONST.INCORRECT]) & valid;
correct = (err == CONST.CORRECT) & valid;

type = zeros(size(cond));
ctx  = zeros(size(cond));
type(valid) = M.TYPE_OF(cond(valid));
ctx(valid)  = M.CTX_OF(cond(valid));

nTYPE = numel(M.TYPE_NAMES);
acc = nan(nTYPE, 2);
cnt = zeros(nTYPE, 2);
for t = 1:nTYPE
    for c = 1:2
        sel = engaged & type == t & ctx == c;
        cnt(t,c) = sum(sel);
        if 0 < cnt(t,c)
            acc(t,c) = 100 * sum(correct & sel) / cnt(t,c);
        end
    end
end

condAcc = nan(M.NCOND, 1);
condN   = zeros(M.NCOND, 1);
for cnd = 1:M.NCOND
    sel = engaged & cond == cnd;
    condN(cnd) = sum(sel);
    if 0 < condN(cnd)
        condAcc(cnd) = 100 * sum(correct & sel) / condN(cnd);
    end
end

% Split-half by type (contexts pooled): session stability check.
trialNums = bhv.Trial(:)';
trialNums = trialNums(1:n);
halfPoint = ceil(max(trialNums) / 2);
splitAcc = nan(2, nTYPE);
for h = 1:2
    if h == 1, hm = trialNums <= halfPoint; else, hm = halfPoint < trialNums; end
    for t = 1:nTYPE
        sel = engaged & hm & type == t;
        if 0 < sum(sel)
            splitAcc(h,t) = 100 * sum(correct & sel) / sum(sel);
        end
    end
end

R = struct('acc', acc, 'cnt', cnt, 'condAcc', condAcc, 'condN', condN, ...
           'splitAcc', splitAcc, 'nEngaged', sum(engaged), ...
           'nCorrect', sum(correct), 'nTrials', n, ...
           'typeNames', {M.TYPE_NAMES}, 'ctxNames', {M.CTX_NAMES});

if ~opts.plots, return; end

fh = figure('Name', 'Perf by Type x Context');
plotAcc = acc;
plotAcc(isnan(plotAcc)) = 0;
hb = bar(plotAcc, 'grouped');
if 2 == numel(hb)
    set(hb(1), 'FaceColor', [0.30 0.45 0.75]);
    set(hb(2), 'FaceColor', [0.85 0.55 0.20]);
end
set(gca, 'XTick', 1:nTYPE, 'XTickLabel', M.TYPE_NAMES);
ylim([0 105]);
ylabel('% correct (correct / correct+incorrect)');
legend(M.CTX_NAMES, 'Location', 'southeast');
hold on;
for t = 1:nTYPE
    for c = 1:2
        if 0 < cnt(t,c)
            text(t + (c-1.5)*0.29, plotAcc(t,c)+3, sprintf('%d', cnt(t,c)), ...
                'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end
end
hold off;
title(sprintf('%d trials, %d engaged, %d correct', n, sum(engaged), sum(correct)));
mgloSaveFigure(fh, 'Perf by Type x Context', opts);

fh = figure('Name', 'Split-Half by Type');
plotSplit = splitAcc;
plotSplit(isnan(plotSplit)) = 0;
bar(plotSplit, 'grouped');
set(gca, 'XTick', 1:2, 'XTickLabel', {'First half', 'Second half'});
ylim([0 105]);
ylabel('% correct');
legend(M.TYPE_NAMES, 'Location', 'southeast');
mgloSaveFigure(fh, 'Split-Half by Type', opts);
end
