function v = mgloGetUserVar(bhv, name, default)
%mgloGetUserVar  Read a per-trial UserVars value with a fallback default.
%
%   v = mgloGetUserVar(bhv, name, default) returns one value per trial.
%
%   Numeric/logical variables come back as a 1 x nTrials row. A trial whose
%   value is missing or empty gets DEFAULT for that trial only -- e.g. a
%   session merged from files recorded before and after mGLO.m began saving
%   VirtualBlock keeps the real values for the trials that have them. (The
%   old version concatenated [bhv.UserVars.(name)], which silently drops
%   empties, noticed the length mismatch and replaced EVERY trial with the
%   default.) A variable absent from every trial gives repmat(default).
%
%   Text variables (Modality, ConditionInfo, ...) come back as a 1 x nTrials
%   cell, one entry per trial, with DEFAULT in trials that lack it.

n = numel(bhv.Trial);
isText = iscell(default) || isstring(default) || ischar(default);

hasVar = isfield(bhv, 'UserVars') && ~isempty(bhv.UserVars) && ...
         isfield(bhv.UserVars, name);

if isText
    v = cell(1, n);
    v(:) = {default};
    if hasVar
        for i = 1:min(n, numel(bhv.UserVars))
            x = bhv.UserVars(i).(name);
            if ~isempty(x), v{i} = x; end
        end
    end
    return
end

v = repmat(default, 1, n);
if ~hasVar, return; end
if isscalar(bhv.UserVars) && n > 1
    % One struct holding a per-trial vector rather than one struct per trial.
    x = bhv.UserVars.(name);
    if (isnumeric(x) || islogical(x)) && numel(x) == n
        v = double(x(:)');
    elseif (isnumeric(x) || islogical(x)) && isscalar(x)
        v = repmat(double(x), 1, n);
    end
    return
end
for i = 1:min(n, numel(bhv.UserVars))
    x = bhv.UserVars(i).(name);
    if (isnumeric(x) || islogical(x)) && isscalar(x)
        v(i) = x;
    end
end
end
