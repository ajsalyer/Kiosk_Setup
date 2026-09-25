function report = mglo_collect_data(srcDir, dstDir)
%mglo_collect_data  Move recorded .bhv2 sessions from the task root into data/.
%
%   MonkeyLogic writes each session next to the conditions file, i.e. the
%   project root, and has no persisted setting for an output folder. The
%   analysis code reads from <repo>/data. This sweeps the gap.
%
%   mglo_collect_data                 % root -> <repo>/data
%   mglo_collect_data(src, dst)       % explicit folders
%   report = mglo_collect_data(...)   % table of what happened
%
%   FILENAMES ARE NEVER CHANGED AND FILES ARE NEVER OVERWRITTEN.
%
%   MonkeyLogic names sessions yymmdd_subject_conditionsfile, so two runs
%   with the same subject, same day and same conditions file collide. If a
%   file of that name already exists in the destination, this leaves the new
%   one where it is and reports it, rather than clobbering the older
%   recording or inventing a new name. Resolve those by hand -- only you
%   know which session is which.
%
%   Returns a table with columns file, action ("moved" | "skipped" |
%   "failed") and detail.
%
%   See also mgloAnalyzeSession, mlBHVunifier.

if nargin < 1 || isempty(srcDir)
    % This file lives at <repo>/analysis/all analysis/, so up three = repo.
    srcDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
if nargin < 2 || isempty(dstDir)
    dstDir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'data');
end

files = dir(fullfile(srcDir, '*.bhv2'));
files = files(~[files.isdir]);

report = table('Size', [0 3], 'VariableTypes', {'string','string','string'}, ...
               'VariableNames', {'file','action','detail'});

if isempty(files)
    fprintf('mglo_collect_data: no .bhv2 in %s -- nothing to move.\n', srcDir);
    return
end

if ~isfolder(dstDir)
    mkdir(dstDir);
end

nMoved = 0; nSkipped = 0; nFailed = 0;
for i = 1:numel(files)
    src = fullfile(files(i).folder, files(i).name);
    dst = fullfile(dstDir, files(i).name);   % same name, always

    if isfile(dst)
        d = dir(dst);
        nSkipped = nSkipped + 1;
        report(end+1,:) = {string(files(i).name), "skipped", ...
            sprintf('%s already holds a file of this name (%.2f MB vs %.2f MB)', ...
                    dstDir, d.bytes/1e6, files(i).bytes/1e6)}; %#ok<AGROW>
        warning('mglo_collect_data:collision', ...
            ['%s already exists in %s -- left at the source, nothing renamed ' ...
             'or overwritten. Same subject/day/conditions file? Resolve by hand.'], ...
            files(i).name, dstDir);
        continue
    end

    try
        movefile(src, dst, 'f');
        nMoved = nMoved + 1;
        report(end+1,:) = {string(files(i).name), "moved", string(dstDir)}; %#ok<AGROW>
    catch ME
        nFailed = nFailed + 1;
        report(end+1,:) = {string(files(i).name), "failed", string(ME.message)}; %#ok<AGROW>
        warning('mglo_collect_data:moveFailed', ...
                'Could not move %s: %s', files(i).name, ME.message);
    end
end

fprintf('mglo_collect_data: %d moved, %d skipped, %d failed  (%s -> %s)\n', ...
        nMoved, nSkipped, nFailed, srcDir, dstDir);
end
