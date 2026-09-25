function out = mgloSaveResults(R, opts)
%mgloSaveResults  Persist one session's analysis output to disk.
%
%   mgloSaveResults(R) writes the results struct returned by
%   mgloAnalyzeSession to <repo>/analysis/results in two forms:
%
%     <stem>.mat    the complete R struct, reloadable with load(). Nothing
%                   is dropped, so an old session can be re-examined without
%                   touching the raw .bhv2 again.
%     sessions.csv  one summary row per session, appended. Headline numbers
%                   only -- trials, engagement, overall and per-deviance-type
%                   accuracy, median RTs -- so a learning curve across days
%                   opens in Excel without MATLAB.
%
%   mgloSaveResults(R, opts) honours:
%     opts.save        true                     set false to skip writing
%     opts.resultsdir  <repo>/analysis/results  destination folder
%     opts.tag         R.date                   file stem / CSV key
%     opts.subject     ''                       prepended to the stem and
%                                               recorded in the CSV
%
%   Re-running the same tag REPLACES that session's CSV row rather than
%   appending a duplicate, so re-analysing a session is idempotent.
%
%   Returns a struct with fields mat and csv holding the paths written
%   (empty strings if saving was off or failed). Saving never interrupts an
%   analysis run: a failure warns and continues.
%
%   See also mgloAnalyzeSession, mgloSaveFigure.

out = struct('mat', '', 'csv', '');
if nargin < 2 || isempty(opts) || ~isstruct(opts), opts = struct(); end
if isfield(opts, 'save') && ~opts.save, return; end
if isempty(R) || ~isstruct(R), return; end

if isfield(opts, 'resultsdir') && ~isempty(opts.resultsdir)
    rdir = opts.resultsdir;
else
    % This file lives at <repo>/analysis/all analysis/, so up two = analysis.
    rdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
end

tag = '';
if isfield(opts, 'tag'), tag = char(opts.tag); end
if isempty(tag)
    if isfield(R, 'date') && ~isempty(R.date)
        tag = strrep(R.date, '/', '');
    else
        tag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    end
end

subject = '';
if isfield(opts, 'subject'), subject = char(opts.subject); end

stem = safeName(tag);
if isempty(stem), stem = 'session'; end
if ~isempty(safeName(subject)), stem = [safeName(subject) '_' stem]; end

try
    if ~isfolder(rdir), mkdir(rdir); end

    % --- full results, everything kept -----------------------------------
    R.meta = struct('tag', tag, 'subject', subject, ...
                    'savedAt', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
    out.mat = fullfile(rdir, [stem '.mat']);
    save(out.mat, 'R');

    % --- one summary row, appended ---------------------------------------
    row = summaryRow(R, tag, subject);
    out.csv = fullfile(rdir, 'sessions.csv');
    writeRow(out.csv, row, tag);

    fprintf('mgloSaveResults: %s  (+ row in sessions.csv)\n', [stem '.mat']);
catch ME
    warning('mgloSaveResults:failed', 'Could not save results: %s', ME.message);
    out = struct('mat', '', 'csv', '');
end
end


function row = summaryRow(R, tag, subject)
%summaryRow  Flatten the headline numbers into a one-row table.
row = table();
row.savedAt    = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
row.tag        = string(tag);
row.subject    = string(subject);
row.date       = string(getf(R, 'date', ''));
row.nTrials    = getf(R, 'nTrials', NaN);
row.nEngaged   = getf(R, 'nEngaged', NaN);
row.nCorrect   = getf(R, 'nCorrect', NaN);
row.overallAcc = getf(R, 'overallAcc', NaN);

% Accuracy per deviance type, contexts pooled and weighted by trial count.
if isfield(R, 'byType') && isfield(R.byType, 'acc') && isfield(R.byType, 'cnt')
    acc = R.byType.acc;
    cnt = R.byType.cnt;
    names = getf(R.byType, 'typeNames', {});
    for t = 1:size(acc, 1)
        a = acc(t, :); a(isnan(a)) = 0;
        c = cnt(t, :); c(isnan(c)) = 0;
        if 0 < sum(c), v = sum(a .* c) / sum(c); else, v = NaN; end
        if t <= numel(names), label = char(names{t}); else, label = sprintf('type%d', t); end
        row.(matlab.lang.makeValidName(['acc_' label])) = v;
    end
end

% Reaction times are absent in passive sessions; record NaN rather than
% dropping the columns, so the CSV schema stays stable across session types.
if isfield(R, 'rt') && isstruct(R.rt)
    row.medRT_correct   = getf(R.rt, 'medCorr', NaN);
    row.medRT_incorrect = getf(R.rt, 'medErr',  NaN);
else
    row.medRT_correct   = NaN;
    row.medRT_incorrect = NaN;
end
end


function writeRow(csvPath, row, tag)
%writeRow  Append row to csvPath, replacing any existing row with this tag.
if ~isfile(csvPath)
    writetable(row, csvPath);
    return
end

old = readSessions(csvPath);
if ismember('tag', old.Properties.VariableNames)
    old(string(old.tag) == string(tag), :) = [];
end

try
    combined = [old; row];
catch
    % Column set changed (e.g. a different deviance-type naming). Keep the
    % old file rather than silently losing it, and start a fresh one.
    bak = [csvPath '.bak_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))];
    copyfile(csvPath, bak);
    warning('mgloSaveResults:schemaChanged', ...
        ['sessions.csv columns no longer match; previous file backed up to ' ...
         '%s and a new one started.'], bak);
    combined = row;
end
writetable(combined, csvPath);
end


function T = readSessions(csvPath)
%readSessions  Read sessions.csv without letting readtable retype columns.
%   Left to itself, readtable turns a tag like "092326" into the number
%   92326 (dropping the leading zero, so the de-duplication key never
%   matches) and a date like "09/22/26" into a datetime rendered 09/22/0026.
%   These four columns are text and must stay text.
iopts = detectImportOptions(csvPath, 'TextType', 'string');
textCols = intersect({'savedAt', 'tag', 'subject', 'date'}, iopts.VariableNames);
if ~isempty(textCols)
    iopts = setvartype(iopts, textCols, 'string');
end
T = readtable(csvPath, iopts);
end


function v = getf(S, name, dflt)
if isstruct(S) && isfield(S, name) && ~isempty(S.(name)), v = S.(name); else, v = dflt; end
end


function s = safeName(x)
s = regexprep(char(x), '[^A-Za-z0-9_\-]+', '_');
s = regexprep(s, '^_+|_+$', '');
end
