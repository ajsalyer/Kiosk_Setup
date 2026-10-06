function [dt, key, dateStr] = mgloSessionStart(bhv)
%mgloSessionStart  Date/time of a session's first trial, in a stable form.
%
%   [dt, key, dateStr] = mgloSessionStart(bhv) reads bhv.TrialDateTime,
%   which MonkeyLogic stores per trial as [year month day hour min sec]:
%     dt       1x6 [Y M D h m s] of the FIRST trial (NaNs if unavailable)
%     key      'yymmdd_HHMMSS' -- identifies the session regardless of how
%              it was loaded or what tag it was saved under, so it is the
%              de-duplication key for sessions.csv ('' if unavailable)
%     dateStr  'mm/dd/yy' ('' if unavailable)
%
%   Accepts both layouts in use: N x 6 (mlconcatenate) and 1 x 6N
%   (mlBHVunifier output from before it stacked rows, or any horizontally
%   concatenated set of per-trial rows).

dt = nan(1, 6);
key = '';
dateStr = '';
try
    T = double(bhv.TrialDateTime);
    if isempty(T), return; end
    if size(T, 2) ~= 6
        if mod(numel(T), 6) ~= 0, return; end
        T = reshape(T', 6, [])';   % 1 x 6N row -> N x 6
    end
    dt = T(1, :);
    if any(~isfinite(dt)), dt = nan(1, 6); return; end
    yy = mod(dt(1), 100);
    key = sprintf('%02d%02d%02d_%02d%02d%02d', yy, dt(2), dt(3), ...
                  dt(4), dt(5), floor(dt(6)));
    dateStr = sprintf('%02d/%02d/%02d', dt(2), dt(3), yy);
catch
    dt = nan(1, 6);
    key = '';
    dateStr = '';
end
end
