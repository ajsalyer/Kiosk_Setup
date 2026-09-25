function R = mgloPlotPsychometric(bhv, CONST, opts)
%mgloPlotPsychometric  Accuracy vs guidance strength (GuideScale bins).
%
%   R = mgloPlotPsychometric(bhv, CONST) bins the per-trial GuideScale
%   UserVar (0..1) and plots engaged-trial accuracy per bin -- the offline
%   version of the guided-stimulus manipulation (VIZ_STIM_GUIDE /
%   AUD_STIM_GUIDE ramping in mGLO.m). Bins with fewer than 5 engaged
%   trials are left empty (NaN).
%
%   opts.plots (default true) controls figure creation. Returns R with bin
%   centers, accuracy and engaged-trial counts.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

R = struct('centers', [], 'acc', [], 'n', []);

if ~isfield(bhv, 'UserVars') || ~isfield(bhv.UserVars, 'GuideScale')
    fprintf('mgloPlotPsychometric: no GuideScale saved -- skipping.\n');
    return;
end

scales = [bhv.UserVars.GuideScale]';
errs = bhv.TrialError(:);
n = min(numel(scales), numel(errs));
scales = scales(1:n);
errs = errs(1:n);

edges = 0:0.1:1;
[~, ~, binIdx] = histcounts(scales, edges);
nBins = numel(edges) - 1;
acc = nan(nBins, 1);
cnt = zeros(nBins, 1);
centers = (edges(1:end-1) + 0.05)';

for i = 1:nBins
    idx = binIdx == i;
    engaged = idx & ismember(errs, [CONST.CORRECT, CONST.INCORRECT]);
    cnt(i) = sum(engaged);
    if 5 <= cnt(i)
        acc(i) = 100 * sum(errs(engaged) == CONST.CORRECT) / cnt(i);
    end
end

R.centers = centers;
R.acc = acc;
R.n = cnt;

if ~opts.plots, return; end

fh = figure('Name', 'Psychometric Curve');
plot(centers, acc, 'o-', 'LineWidth', 2, 'MarkerFaceColor', 'b');
xlabel('Guide Scale (contrast/size fraction)');
ylabel('Accuracy (%)');
title('Performance vs. Guidance Strength');
yline(75, 'r--', 'Threshold');
grid on;
mgloSaveFigure(fh, 'Psychometric Curve', opts);
end
