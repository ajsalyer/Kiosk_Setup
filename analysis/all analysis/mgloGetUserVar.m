function v = mgloGetUserVar(bhv, name, default)
%mgloGetUserVar  Read a per-trial UserVars vector with a fallback default.
%
%   v = mgloGetUserVar(bhv, name, default) returns [bhv.UserVars.(name)] as a
%   row vector, or repmat(default, 1, nTrials) when the field is missing
%   (e.g. sessions recorded before mGLO.m saved VirtualBlock/ActiveMode).
%   String/cell UserVars (ConditionInfo, Modality) are returned as-is when
%   present.

n = numel(bhv.Trial);
if isfield(bhv, 'UserVars') && ~isempty(bhv.UserVars) && isfield(bhv.UserVars, name)
    try
        v = [bhv.UserVars.(name)];
        if iscell(v) || isstring(v)
            return; % non-numeric metadata: return as collected
        end
        v = v(:)';
        if numel(v) ~= n
            % Scalar broadcast (e.g. single saved value): expand; otherwise
            % fall back so lengths never silently mismatch.
            if isscalar(v)
                v = repmat(v, 1, n);
            else
                v = repmat(default, 1, n);
            end
        end
        return;
    catch
        % fall through to default
    end
end
if iscell(default) || isstring(default)
    v = default;
else
    v = repmat(default, 1, n);
end
end
