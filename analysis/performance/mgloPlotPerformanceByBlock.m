function R = mgloPlotPerformanceByBlock(bhv, CONST, guideThresh, opts)
%mgloPlotPerformanceByBlock  Accuracy per virtual block (schedule blocks).
%
%   R = mgloPlotPerformanceByBlock(bhv, CONST) splits trials by the
%   per-trial VirtualBlock UserVar saved by mGLO.m (1..8, see
%   make_trial_order.m). MonkeyLogic's own Block is always 1 under
%   mglo_block_selector, so bhv.Block cannot be used; when VirtualBlock is
%   missing (older files) it falls back to bhv.Block with a printed note.
%
%   Each observed block gets a subplot: per-condition accuracy bars (short
%   samp labels) plus the block mean. guideThresh (default 0.99) marks
%   guided trials (GuideScale < thresh); the guided fraction is reported in
%   each title rather than plotted on a doubled scale.
%
%   opts.plots (default true) controls figure creation. Returns R.blocks, a
%   struct array with block, name, conds, condAcc, condN, meanAcc, n, nGuided.

if nargin < 3 || isempty(guideThresh), guideThresh = 0.99; end
if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'plots'), opts.plots = true; end

M = mgloCondMap();
cond = bhv.Condition(:)';
err  = bhv.TrialError(:)';
n    = min(numel(cond), numel(err));
cond = cond(1:n);
err  = err(1:n);

if isfield(bhv, 'UserVars') && isfield(bhv.UserVars, 'VirtualBlock')
    vb = mgloGetUserVar(bhv, 'VirtualBlock', 1);
    vb = vb(1:n);
    usedFallback = false;
else
    vb = bhv.Block(:)';
    vb = vb(1:n);
    usedFallback = true;
    fprintf('mgloPlotPerformanceByBlock: no VirtualBlock saved -- falling back to ML Block.\n');
end
gs = mgloGetUserVar(bhv, 'GuideScale', 1);
gs = gs(1:n);

engaged = ismember(err, [CONST.CORRECT, CONST.INCORRECT]);
correct = err == CONST.CORRECT;

blocks = unique(vb);
blocks = blocks(isfinite(blocks) & blocks >= 1 & blocks <= 8);

R.blocks = struct('block', {}, 'name', {}, 'conds', {}, 'condAcc', {}, ...
                  'condN', {}, 'meanAcc', {}, 'n', {}, 'nGuided', {}, ...
                  'usedFallback', {});
R.usedFallback = usedFallback;

for bi = 1:numel(blocks)
    b = blocks(bi);
    sel = engaged & vb == b;
    nEng = sum(sel);
    nGui = sum(sel & gs < guideThresh);
    if 1 <= b && b <= numel(M.BLOCK_CONDS)
        want = M.BLOCK_CONDS{b};
    else
        want = unique(cond(vb == b));
    end
    want = want(ismember(want, unique(cond(vb == b & (cond >= 1 & cond <= M.NCOND)))));
    if isempty(want)
        want = unique(cond(vb == b));
    end
    cAcc = nan(numel(want), 1);
    cN = zeros(numel(want), 1);
    for k = 1:numel(want)
        ks = sel & cond == want(k);
        cN(k) = sum(ks);
        if 0 < cN(k)
            cAcc(k) = 100 * sum(correct & ks) / cN(k);
        end
    end
    if 0 < nEng
        mAcc = 100 * sum(correct & sel) / nEng;
    else
        mAcc = NaN;
    end
    R.blocks(bi).block = b;
    if 1 <= b && b <= numel(M.BLOCK_NAMES)
        R.blocks(bi).name = M.BLOCK_NAMES{b};
    else
        R.blocks(bi).name = sprintf('block %d', b);
    end
    R.blocks(bi).conds = want;
    R.blocks(bi).condAcc = cAcc;
    R.blocks(bi).condN = cN;
    R.blocks(bi).meanAcc = mAcc;
    R.blocks(bi).n = sum(vb == b);
    R.blocks(bi).nGuided = nGui;
    R.blocks(bi).usedFallback = usedFallback;
end

if ~opts.plots || isempty(R.blocks), return; end

fh = figure('Name', 'Block Performance');
nB = numel(R.blocks);
nCols = ceil(nB / 2);
for bi = 1:nB
    subplot(2, nCols, bi);
    B = R.blocks(bi);
    toPlot = B.condAcc;
    toPlot(isnan(toPlot)) = 0;
    bar(1:numel(B.conds), toPlot);
    xticks(1:numel(B.conds));
    labels = cell(1, numel(B.conds));
    for k = 1:numel(B.conds)
        if B.conds(k) >= 1 && B.conds(k) <= M.NCOND
            labels{k} = M.SAMP{B.conds(k)};
        else
            labels{k} = sprintf('C%d', B.conds(k));
        end
    end
    xticklabels(labels);
    xtickangle(30);
    yline(50, 'k:');
    if isfinite(B.meanAcc)
        yline(B.meanAcc, 'r--', sprintf('mean %.0f%%', B.meanAcc));
    end
    ylim([0 105]);
    title(sprintf('%s | n=%d (guided %d)', B.name, B.n, B.nGuided), ...
        'FontSize', 8);
end
mgloSaveFigure(fh, 'Block Performance', opts);
end
