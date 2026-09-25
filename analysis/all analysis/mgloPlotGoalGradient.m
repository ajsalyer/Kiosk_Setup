function R = mgloPlotGoalGradient(bhv, CONST, opts)
%mgloPlotGoalGradient  Accuracy as a function of distance to token cash-out.
%
%   R = mgloPlotGoalGradient(bhv, CONST) bins engaged trials by tokens
%   remaining to MAX (maxTokens - balance at trial start, using the same
%   next-trial balance convention as mgloPlotTokenPerformance) and plots
%   accuracy per distance with a linear fit (goal-gradient slope).
%
%   opts.plots (default true) controls figure creation. Returns R with
%   distances, accuracy, counts and the fitted slope.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

R = struct('distances', [], 'acc', [], 'n', [], 'slope', NaN);

if ~isfield(bhv, 'UserVars') || ~isfield(bhv.UserVars, 'TokenBalance')
    fprintf('mgloPlotGoalGradient: no TokenBalance saved -- skipping.\n');
    return;
end

tokens = [bhv.UserVars.TokenBalance]';
errs = bhv.TrialError(:);
n = min(numel(tokens), numel(errs)) - 1; % -1: balance(i) applies to trial i+1
if n < 1
    return;
end
bal = tokens(1:n);          % end-of-trial balance = start balance of trial i+1
errs = errs(2:n+1);

maxToken = max(tokens);
distToReward = maxToken - bal;

uDist = unique(distToReward);
perf = nan(numel(uDist), 1);
cnt = zeros(numel(uDist), 1);
for i = 1:numel(uDist)
    idx = distToReward == uDist(i) & ...
        ismember(errs, [CONST.CORRECT, CONST.INCORRECT]);
    cnt(i) = sum(idx);
    if 0 < cnt(i)
        perf(i) = 100 * sum(errs(idx) == CONST.CORRECT) / cnt(i);
    end
end

R.distances = uDist;
R.acc = perf;
R.n = cnt;

ok = isfinite(uDist) & isfinite(perf);
if 2 <= sum(ok) && 1 < numel(unique(uDist(ok)))
    p = polyfit(uDist(ok), perf(ok), 1);
    R.slope = p(1);
else
    p = [];
end

if ~opts.plots, return; end

fh = figure('Name', 'Goal Gradient');
bar(uDist, perf);
xlabel('Distance to Reward (tokens remaining)');
ylabel('Accuracy (%)');
title('Goal Gradient Effect');
set(gca, 'XDir', 'reverse');
if ~isempty(p)
    hold on;
    plot(uDist, polyval(p, uDist), 'r-', 'LineWidth', 2);
    legend('Data', sprintf('Slope: %.2f', p(1)));
    hold off;
end
mgloSaveFigure(fh, 'Goal Gradient', opts);
end
