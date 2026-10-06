function alert_function(hook,MLConfig,TrialRecord) %#ok<INUSD>
% mGLO task-directory alert function.
%
% MonkeyLogic gives priority to an alert_function.m in the task directory
% over the one in the main ML directory, so this customises behaviour for
% mGLO WITHOUT modifying the MonkeyLogic installation. The stock file lives
% at <ML>/alert_function.m and still applies to every other experiment.
%
% TO MAKE THIS RUN: the alert button on the task panel of the MonkeyLogic
% main menu must be ON (saved in the config as RemoteAlert). MonkeyLogic
% ships with it off, and with it off none of these hooks fire -- check the
% button before a session rather than assuming the loaded config has it on.
%
% What it does, in two stages, because the two things need different moments:
%
%   task_end / task_aborted  -> save the control screen you were watching.
%       MonkeyLogic closes that window one line later (run_trial.m:155 fires
%       the hook, :156 closes hFig), so this is the last chance to capture
%       it. Both hooks are wired because they are mutually exclusive and a
%       session ending either way is still worth a picture.
%
%   fini                     -> re-analyse the recording from the .bhv2.
%       Deliberately later: by 'fini' (run_trial.m:182) MonkeyLogic has
%       closed the data file, so it is safe to read. Writes .jpg figures to
%       analysis/figures and .mat + a sessions.csv row to analysis/results.
%
% Both helpers are written never to throw -- failures warn and leave the
% recording untouched, so neither can take the task down.

switch hook
    case 'init'         % when the [RUN] button is clicked

    case 'task_start'   % when the task is started by '[Space] Start'

    case 'block_start'

    case 'trial_start'

    case 'trial_end'

    case 'block_end'

    case 'task_paused'   % when the task is paused with ESC

    case 'task_resumed'  % when the task is resumed by '[Space] Resume'

% 'task_end' and 'task_aborted' are mutually exclusive.  If one occurs, the
% other does not.  If you want to run some clean-up code for both events,
% use 'fini'.

    case {'task_end','task_aborted'}   % LAST moment the control screen exists
        try
            mglo_save_controlscreen(sessionTag(MLConfig));
        catch ME
            warning('mGLO:alert', 'Control-screen capture failed: %s', ME.message);
        end

    case 'fini'          % when the task window is closed
        try
            mglo_autoanalyze(MLConfig);
        catch ME
            warning('mGLO:alert', 'Auto-analysis hook failed: %s', ME.message);
        end

end


function s = sessionTag(MLConfig)
%sessionTag  Name stem for this session's files, best effort.
s = '';
try
    p = MLConfig.MLPath.DataFile;          % the recording just written
    if ~isempty(p), [~,s] = fileparts(char(p)); end
catch
end
if isempty(s)
    try, s = char(MLConfig.FormattedName); catch, end   % e.g. 260923_Joule_
end
if isempty(s)
    try
        s = sprintf('%s_%s', char(MLConfig.SubjectName), ...
                    char(datetime('now','Format','yyMMdd')));
    catch
        s = char(datetime('now','Format','yyMMdd_HHmmss'));
    end
end
end

end
