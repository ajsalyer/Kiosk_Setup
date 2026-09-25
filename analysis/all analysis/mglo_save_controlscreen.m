function outPath = mglo_save_controlscreen(tag, outDir)
%mglo_save_controlscreen  Save MonkeyLogic's control screen as a .jpg.
%
%   Captures the window you were watching during the session -- timeline,
%   performance bars and the user plot -- exactly as it looked when the task
%   ended, and writes it to analysis/figures.
%
%   TIMING MATTERS. MonkeyLogic destroys the control figure immediately
%   after the task_end / task_aborted hook:
%       run_trial.m:155   alertfunc('task_end' | 'task_aborted', ...)
%       run_trial.m:156   if ishandle(hFig), close(hFig); end
%       run_trial.m:182   alertfunc('fini', ...)
%   So this must be called from task_end or task_aborted. By 'fini' the
%   window is already gone and there is nothing left to capture.
%
%   The figure is found by the tag MonkeyLogic gives it (run_trial.m:881,
%   'mlmonitor'), since the handle is not passed to the alert function.
%
%   mglo_save_controlscreen(tag)          name stem for the .jpg
%   mglo_save_controlscreen(tag, outDir)  destination folder
%
%   Returns the path written, or '' if there was nothing to capture. Never
%   throws: it runs on a rig at the end of a session and must not be able to
%   take the task down.

outPath = '';
if nargin < 1, tag = ''; end
if nargin < 2 || isempty(outDir)
    % This file lives at <repo>/analysis/all analysis/, so up two = analysis.
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'figures');
end

try
    h = findall(0, 'Type', 'figure', 'Tag', 'mlmonitor');
    if isempty(h)
        warning('mglo_save_controlscreen:noWindow', ...
            ['No MonkeyLogic control screen found (tag ''mlmonitor''). ' ...
             'Called too late? It is destroyed right after task_end.']);
        return
    end
    h = h(1);

    stem = regexprep(char(tag), '[^A-Za-z0-9_\-]+', '_');
    stem = regexprep(stem, '^_+|_+$', '');
    if isempty(stem), stem = char(datetime('now','Format','yyyyMMdd_HHmmss')); end

    if ~isfolder(outDir), mkdir(outDir); end
    outPath = fullfile(outDir, ['ControlScreen_' stem '.jpg']);

    % getframe grabs the rendered window, so uicontrols (the performance
    % bars, message box and buttons) are included. print/exportgraphics
    % render the graphics objects only and would drop them, so that is the
    % fallback rather than the first choice.
    try
        fr = getframe(h);
        imwrite(fr.cdata, outPath, 'jpg', 'Quality', 95);
    catch
        print(h, outPath, '-djpeg', '-r150');
    end

    if isfile(outPath)
        fprintf('mglo_save_controlscreen: saved %s\n', outPath);
    else
        outPath = '';
    end

catch ME
    warning('mglo_save_controlscreen:failed', ...
            'Could not save the control screen: %s', ME.message);
    outPath = '';
end
end
