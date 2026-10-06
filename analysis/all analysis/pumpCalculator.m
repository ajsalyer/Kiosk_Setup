%pumpCalculator  Reward-pump calibration from recorded mGLO sessions.
%
%   Reads the .bhv2 sessions from the task root -- where MonkeyLogic writes
%   them -- AND from "data archive/", where they are moved afterwards, pairs
%   each one with a hand-measured row in MANUAL below, and plots fluid
%   delivered per correct trial against the reward duration configured for
%   that session.
%
%   MANUAL holds the bench measurements that are not in the data file --
%   one row per session, [trials, amount], in file-name order across both
%   folders (the YYMMDD_ prefix puts them oldest-first, and moving a file
%   into the archive does not change its place). Add a row each time you
%   measure a new session.
%
%   Sessions that will not load are skipped with a warning rather than
%   killing the run. VariableChanges is recorded per trial, so the settings
%   below are read from the first trial and a warning is raised if one of
%   them was edited mid-session.
%
%   Edit DATA_DIRS or PATTERN to read from somewhere else.

%--- Configuration ---------------------------------------------------------
DATA_DIRS = {};              % {} = task root + "data archive"
PATTERN   = '*mGLO*.bhv2';   % session files to calibrate against

% Hand-measured per session: [trials, amount]
MANUAL = [332 210; 497 350; 477 320; 381 270; 459 280];
%MANUAL = [310 310; 290 315; 310 336; 230 233; 340 387; 290 306; 440 523];

%--- Locate the sessions ---------------------------------------------------
if isempty(DATA_DIRS)
    % This script lives at <repo>/analysis/all analysis/, so up three = the
    % task root, which is where MonkeyLogic leaves its recordings; they are
    % then moved into "data archive" (README, mglo_collect_data).
    taskRoot  = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    DATA_DIRS = {taskRoot, fullfile(taskRoot, 'data archive')};
end
DATA_DIR = strjoin(DATA_DIRS, ' + ');   % for messages

files = [];
for d = 1:numel(DATA_DIRS)
    files = [files; dir(fullfile(DATA_DIRS{d}, PATTERN))]; %#ok<AGROW>
end
if isempty(files)
    error('pumpCalculator:noData', ...
          'No files matching "%s" in %s', PATTERN, DATA_DIR);
end
% One ordering regardless of which folder a file currently sits in.
[~, order] = sort({files.name});
files = files(order);

% One bench measurement per session, or the pairing is meaningless.
nFiles = numel(files);
nManual = size(MANUAL, 1);
if nManual ~= nFiles
    n = min(nFiles, nManual);
    warning('pumpCalculator:countMismatch', ...
        ['%d session(s) matched "%s" but MANUAL has %d row(s). ' ...
         'Using the first %d of each -- add or remove MANUAL rows so they ' ...
         'line up with the sessions you actually measured.'], ...
        nFiles, PATTERN, nManual, n);
    files = files(1:n);
else
    n = nFiles;
end

fprintf('pumpCalculator: %d session(s) from %s\n', n, DATA_DIR);

%--- Pull the configured reward settings out of each session ---------------
pumpCalc = zeros(n, 6);
pumpCalc(:, 2:3) = MANUAL(1:n, :);
loaded = false(n, 1);   % rows backed by a session that actually opened

for f = 1:n
    fname = fullfile(files(f).folder, files(f).name);
    try
        dataFile = mlconcatenate(fname);
    catch ME
        warning('pumpCalculator:unreadable', ...
                'Skipping %s -- could not read it (%s).', files(f).name, ME.message);
        continue
    end
    loaded(f) = true;

    day = dataFile.TrialDateTime(1, 3);
    pumpCalc(f, 1) = day;

    % VariableChanges has one entry per trial; take the session's setting.
    vc = dataFile.VariableChanges;
    pumpDur = sessionSetting(vc, 'reward_dur', files(f).name);
    pumpCalc(f, 4) = pumpDur;

    % Column 5 (pump count) feeds nothing that this script currently plots --
    % only the commented-out flow_rates line below. mGLO has no plain
    % num_reward variable, so if you re-enable flow_rates, read
    % NUM_REWARD_BASELINE or NUM_REWARD_TOKENS here depending on which one
    % you are calibrating.
    pumpCalc(f, 5) = NaN;

    try
        manualReward = dataFile.UserVars(end).ManReward;
        pumpCalc(f, 6) = manualReward;
    catch
        pumpCalc(f, 6) = 0;
    end

    fprintf('  %-46s reward_dur=%g\n', files(f).name, pumpDur);
end

if ~any(loaded)
    error('pumpCalculator:noneLoaded', ...
          'None of the %d matched session(s) could be read.', n);
end
pumpCalc = pumpCalc(loaded, :);

% flow_rates = pumpCalc(:,2) ./ (pumpCalc(:,3) .* pumpCalc(:,4) .* pumpCalc(:,5) * 1e-3);
% avg_flow_rate = mean(flow_rates);
%
% fluid_per_trial = avg_flow_rate * current_pump_duration * current_num_pumps * 1e-3;
% total_fluid = numCorrect * fluid_per_trial;

% MANUAL is [trials, amount] in columns 2:3, so amount / trials.
mls_per_correct = pumpCalc(:, 3) ./ pumpCalc(:, 2);

% Sorted by duration so the line does not zig-zag between sessions.
[dur, order] = sort(pumpCalc(:, 4));
fh = figure('Name', 'Pump Calibration');
plot(dur, mls_per_correct(order), 'o-')
ylabel('mLs per Correct'); xlabel('Reward Duration (ms)')
mgloSaveFigure(fh, 'Pump Calibration');


function v = sessionSetting(vc, name, sessionName)
%sessionSetting  One VariableChanges setting for a whole session.
%   VariableChanges is a 1-per-trial struct array. Returns the value from
%   the first trial, NaN if the task never recorded that variable, and warns
%   if it was changed part-way through the session.
    if ~isfield(vc, name)
        warning('pumpCalculator:missingVar', ...
                '%s does not record "%s"; leaving it NaN.', sessionName, name);
        v = NaN;
        return
    end
    vals = [vc.(name)];
    if isempty(vals)
        v = NaN;
        return
    end
    v = vals(1);
    if any(vals ~= v)
        warning('pumpCalculator:varChanged', ...
                '"%s" changed mid-session in %s (%g..%g); using the first value %g.', ...
                name, sessionName, min(vals), max(vals), v);
    end
end
