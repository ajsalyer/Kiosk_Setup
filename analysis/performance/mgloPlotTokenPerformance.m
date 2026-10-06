function R = mgloPlotTokenPerformance(bhv, CONST, opts)
%mgloPlotTokenPerformance  Accuracy as a function of token balance.
%
%   R = mgloPlotTokenPerformance(bhv, CONST) reproduces the "Token
%   Economics" view: for each token balance B, performance over trials that
%   STARTED at B (UserVars saves end-of-trial balance, so trial i+1 ran at
%   balance(i)). Returns R with balances, perf/sens/idle/break rates, trial
%   counts and correct counts.
%
%   opts.plots (default true) controls figure creation.
%   Missing TokenBalance (e.g. UNTOKENIZED sessions) prints a note and
%   returns R with empty fields instead of erroring.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

R = struct('balances', [], 'perf', [], 'sens', [], 'idleRate', [], ...
           'breakRate', [], 'nTrials', [], 'nCorr', []);

if ~isfield(bhv, 'UserVars') || ~isfield(bhv.UserVars, 'TokenBalance')
    fprintf('mgloPlotTokenPerformance: no TokenBalance saved (UNTOKENIZED?) -- skipping.\n');
    return;
end

tokenBal = [bhv.UserVars.TokenBalance]';
errCodes = bhv.TrialError(:);
n = min(numel(tokenBal), numel(errCodes));
tokenBal = tokenBal(1:n);
errCodes = errCodes(1:n);

uniqueTokens = unique(tokenBal)';
nLevels = numel(uniqueTokens);
rows = nan(nLevels, 7); % [Balance Perf Sens Total Idle Break nCorr]

for i = 1:nLevels
    % Balance(i) is end-of-trial: trial i+1 started at this balance.
    idx = find(tokenBal == uniqueTokens(i)) + 1;
    idx(idx > numel(errCodes)) = [];
    if isempty(idx), continue; end
    stats = mgloTrialStats(errCodes(idx), CONST);
    rows(i, :) = [uniqueTokens(i), stats.perf, stats.sens, stats.total, ...
                  stats.idleRate, stats.breakRate, stats.nCorr];
end
% A balance with no following trial (e.g. only ever the session's last
% balance) has no row; drop it rather than plotting it as balance 0.
rows = rows(isfinite(rows(:,1)), :);
nLevels = size(rows, 1);

R.balances = rows(:,1);
R.perf = rows(:,2);
R.sens = rows(:,3);
R.nTrials = rows(:,4);
R.idleRate = rows(:,5);
R.breakRate = rows(:,6);
R.nCorr = rows(:,7);

if ~opts.plots || isempty(rows), return; end

fh = figure('Name', 'Token Economics');
plotLimit = min(nLevels, 16);
dataToPlot = rows(1:plotLimit, :);

bar(dataToPlot(:,1), dataToPlot(:, [2, 3, 5, 6]));
hold on;
text(dataToPlot(:,1), ones(plotLimit, 1), string(dataToPlot(:,4)));
text(dataToPlot(:,1), ones(plotLimit, 1)+4, string(dataToPlot(:,7)));
text(-0.5, 1, 'Trials');
text(-0.5, 4, 'Correct');

ylim([-100 100]);
xlim([-1 max(dataToPlot(:,1))+1]);
xlabel('Token Balance (balance at start of next trial)');
legend('Performance', 'Sensitivity', 'Idle %', 'Break %', 'Location', 'southeast');

% Trendlines only where fittable (needs >= 2 distinct x and finite y).
colors = ["#0072BD", "#EDB120", "#AC00DC"];
metrics = [2, 5, 6];
names = ["Fit Perf", "Fit Idle", "Fit Break"];  % columns 2, 5, 6
xx = dataToPlot(:,1);
for k = 1:3
    yy = dataToPlot(:, metrics(k));
    ok = isfinite(xx) & isfinite(yy);
    if 1 < sum(ok) && 1 < numel(unique(xx(ok)))
        p = polyfit(xx(ok), yy(ok), 1);
        xFit = linspace(min(xx(ok)), max(xx(ok)), 100);
        plot(xFit, polyval(p, xFit), 'Color', colors(k), ...
            'LineWidth', 2, 'LineStyle', '--', 'DisplayName', names(k));
    end
end
hold off;
[~, ~, sessionDate] = mgloSessionStart(bhv);   % mm/dd/yy, '' if unknown
if ~isempty(sessionDate)
    title(['Session: ' sessionDate]);
end
mgloSaveFigure(fh, 'Token Economics', opts);
end
