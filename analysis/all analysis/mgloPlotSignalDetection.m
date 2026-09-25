function R = mgloPlotSignalDetection(bhv, CONST, opts)
%mgloPlotSignalDetection  d-prime and criterion per deviance type.
%
%   R = mgloPlotSignalDetection(bhv, CONST) treats each deviance type
%   (auditory / visual / dual, contexts pooled via mgloCondMap) as the
%   signal and the pooled non-oddball trials as the noise:
%     hit = correct on a deviant trial, false alarm = error on a standard.
%   Rates use the log-linear correction (+0.5/+1) and z-scores via erfcinv
%   (no Statistics Toolbox needed). Types with no signal or no noise trials
%   return NaN.
%
%   opts.plots (default true) controls figure creation. Returns R with
%   dPrime (3x1: aud/vis/dual), criterion, hitRate and faRate.

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

M = mgloCondMap();
cond = bhv.Condition(:)';
err  = bhv.TrialError(:)';
n    = min(numel(cond), numel(err));
cond = cond(1:n);
err  = err(1:n);

z = @(p) sqrt(2) * erfcinv(2 * (1 - min(max(p, 1e-6), 1 - 1e-6)));

noiseSel = (ismember(cond, M.COND{1,1}) | ismember(cond, M.COND{2,1})) & ...
    ismember(err, [CONST.CORRECT, CONST.INCORRECT]);
nNoise = sum(noiseSel);
nFA = sum(noiseSel & err == CONST.INCORRECT);
faRate = (nFA + 0.5) / (nNoise + 1);

types = 2:4; % auditory, visual, dual
dPrime = nan(3, 1);
criterion = nan(3, 1);
hitRate = nan(3, 1);
for k = 1:3
    t = types(k);
    sigSel = ismember(cond, [M.COND{1,t}, M.COND{2,t}]) & ...
        ismember(err, [CONST.CORRECT, CONST.INCORRECT]);
    nSig = sum(sigSel);
    nHit = sum(sigSel & err == CONST.CORRECT);
    if 0 == nSig || 0 == nNoise
        continue;
    end
    hitRate(k) = (nHit + 0.5) / (nSig + 1);
    dPrime(k) = z(hitRate(k)) - z(faRate);
    criterion(k) = -0.5 * (z(hitRate(k)) + z(faRate));
end

R = struct('dPrime', dPrime, 'criterion', criterion, ...
           'hitRate', hitRate, 'faRate', faRate, ...
           'typeNames', {{M.TYPE_NAMES{2:4}}});

if ~opts.plots, return; end

fh = figure('Name', 'Signal Detection');
subplot(2,1,1);
bar(1:3, dPrime);
set(gca, 'XTick', 1:3, 'XTickLabel', M.TYPE_NAMES(2:4));
title("Sensitivity (d')");
ylabel("d'");
subplot(2,1,2);
bar(1:3, criterion);
set(gca, 'XTick', 1:3, 'XTickLabel', M.TYPE_NAMES(2:4));
title('Bias (C)');
ylabel('Criterion');
yline(0, 'k--');
legend('Positive=Conservative / Negative=Liberal');
mgloSaveFigure(fh, 'Signal Detection', opts);
end
