function s = mgloTrialStats(errs, CONST)
%mgloTrialStats  Universal per-trial-error summary for mGLO.
%
%   s = mgloTrialStats(errs, CONST) with errs a vector of MonkeyLogic trial
%   errors and CONST a struct with CORRECT (0), INCORRECT (6), AVOID (9).
%   Returns struct with counts and rates (%):
%     total, nCorr, nErr, nAvoid, nNoFix (4), nBreak (3),
%     perf (correct / correct+incorrect),
%     sens (sensitivity index, (corr-err)/(corr+err)),
%     avoidRate (avoid / avoid+incorrect, choice trials only),
%     idleRate (no-fix / total), breakRate (fix-break / total).
%
%   Rates are NaN (not 0) when their denominator is 0, so group means with
%   'omitnan' are not dragged down by empty cells. Use n = total to check
%   whether a cell had any trials.

s.total  = numel(errs);
s.nCorr  = sum(errs == CONST.CORRECT);
s.nErr   = sum(errs == CONST.INCORRECT);
s.nAvoid = sum(errs == CONST.AVOID);
s.nNoFix = sum(errs == 4);
s.nBreak = sum(errs == 3);

denom = s.nCorr + s.nErr;
if 0 < denom
    s.perf = 100 * (s.nCorr / denom);
    s.sens = 100 * ((s.nCorr - s.nErr) / denom);
else
    s.perf = NaN;
    s.sens = NaN;
end

denomAvoid = s.nAvoid + s.nErr;
if 0 < denomAvoid
    s.avoidRate = 100 * (s.nAvoid / denomAvoid);
else
    s.avoidRate = NaN;
end

if 0 < s.total
    s.idleRate  = 100 * (s.nNoFix / s.total);
    s.breakRate = 100 * (s.nBreak / s.total);
else
    s.idleRate  = NaN;
    s.breakRate = NaN;
end
end
