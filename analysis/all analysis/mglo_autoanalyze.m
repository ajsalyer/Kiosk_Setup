function R = mglo_autoanalyze(sessionFile)
%mglo_autoanalyze  Analyse a just-finished mGLO session, unattended.
%
%   Called from alert_function.m when MonkeyLogic closes the task window, so
%   figures and results land on disk without anyone remembering to run the
%   analysis. Also usable by hand:
%
%     mglo_autoanalyze                    % newest .bhv2 at the task root
%     mglo_autoanalyze(file)              % a specific recording
%     mglo_autoanalyze(MLConfig)          % the file MonkeyLogic just wrote
%
%   MonkeyLogic writes recordings next to the conditions file, i.e. the task
%   root, and has no setting for an output folder -- so that is where this
%   looks.
%
%   THIS MUST NEVER THROW. It runs inside MonkeyLogic's own process, at the
%   end of a session, on a rig. An analysis bug must not take down the task
%   or lose a recording, so every step is guarded and failures degrade to a
%   warning. The recording itself is never modified, moved or deleted.
%
%   Figures are built invisibly and closed after saving, so nothing pops up
%   over the control screen.

R = [];
taskRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));

try
    %--- work out which file to analyse --------------------------------
    if nargin < 1 || isempty(sessionFile)
        sessionFile = newestRecording(taskRoot);
    elseif isobject(sessionFile) || isstruct(sessionFile)
        % An MLConfig: its MLPath.DataFile is the session just written.
        sessionFile = fromMLConfig(sessionFile, taskRoot);
    end

    if isempty(sessionFile) || ~isfile(sessionFile)
        warning('mglo_autoanalyze:noFile', ...
                'No .bhv2 found to analyse in %s.', taskRoot);
        return
    end

    %--- load ----------------------------------------------------------
    % mgloAnalyzeSession wants the flattened form (one array per field),
    % which is what mlconcatenate returns; mlread gives one struct per trial.
    fprintf('mglo_autoanalyze: analysing %s\n', sessionFile);
    bhv = mlconcatenate(sessionFile);
    if ~isstruct(bhv) || ~isfield(bhv, 'Trial') || isempty(bhv.Trial)
        warning('mglo_autoanalyze:emptySession', ...
                '%s holds no trials -- nothing to analyse.', sessionFile);
        return
    end

    %--- analyse, with figures kept off screen --------------------------
    [~, stem] = fileparts(sessionFile);
    subject = subjectFromStem(stem);

    old = get(0, 'DefaultFigureVisible');
    cleanup = onCleanup(@() set(0, 'DefaultFigureVisible', old));
    set(0, 'DefaultFigureVisible', 'off');

    R = mgloAnalyzeSession(bhv, struct('tag', stem, 'subject', subject));

    close all force;
    fprintf('mglo_autoanalyze: done (%d trials, %.1f%% correct).\n', ...
            R.nTrials, R.overallAcc);

catch ME
    % Never propagate: MonkeyLogic is mid-shutdown and the recording is safe
    % on disk regardless. Report enough to debug later.
    warning('mglo_autoanalyze:failed', ...
            'Automatic analysis failed (%s): %s\nThe recording is untouched; run the analysis by hand.', ...
            ME.identifier, ME.message);
    try, close all force; catch, end
end
end


function f = newestRecording(taskRoot)
d = dir(fullfile(taskRoot, '*.bhv2'));
d = d(~[d.isdir]);
if isempty(d), f = ''; return; end
[~, i] = max([d.datenum]);
f = fullfile(d(i).folder, d(i).name);
end


function f = fromMLConfig(cfg, taskRoot)
%fromMLConfig  Pull the session path out of an MLConfig, else fall back.
f = '';
try
    p = cfg.MLPath.DataFile;
    if ~isempty(p)
        if isfile(p)
            f = char(p);
        elseif isfile(fullfile(taskRoot, p))   % relative to the task dir
            f = fullfile(taskRoot, char(p));
        end
    end
catch
end
if isempty(f), f = newestRecording(taskRoot); end
end


function s = subjectFromStem(stem)
%subjectFromStem  FilenameFormat is yymmdd_sname_cname, so field 2.
s = '';
parts = strsplit(char(stem), '_');
if 2 <= numel(parts), s = parts{2}; end
end
