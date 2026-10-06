function mGLO_set_trial_count(cfgfile, n)
%mGLO_set_trial_count  Raise MonkeyLogic's per-block trial cap to 1328.
%
%Run this ONCE on the rig, with MonkeyLogic CLOSED, before the first session.
%
%   mGLO_set_trial_count                                 % defaults below
%   mGLO_set_trial_count('mGLO_conditions_main_cfg2.mat', 1328)
%
%WHY THIS IS NEEDED
%  MonkeyLogic keeps its own trial cap, NumberOfTrialsToRunInThisBlock, and
%  ends the block as soon as it is reached -- see mltrialrecord.m:229, which
%  sets BlockChange the moment CompletedTrialsInThisBlock hits it. With
%  CountOnlyCorrectTrials on, that counts correct trials, exactly like our
%  schedule does. Any saved value below 1328 stops a session short of the
%  schedule (the rig has carried 960 from the previous design, and lower
%  test values since), and the block-change path then fires in a state
%  mglo_block_selector does not expect. The table this prints shows what
%  each subject's profile held before the change.
%
%  It cannot be fixed from the task code: TrialRecord's copy of the property
%  is SetAccess = protected (mltrialrecord.m:43-48), so the timing file and
%  the selectors cannot write it. It has to be changed in the config.
%
%WHY NOT JUST TYPE IT INTO THE GUI
%  You can -- it is the "trials to run in this block" box. But the config
%  stores a SEPARATE MLConfig per subject, and the GUI only ever shows the
%  one currently loaded. This sets every subject in the file at once, which
%  is the part that is easy to get wrong by hand.
%
%mglo_block_selector still ends the session on its own by returning -1 once
%the schedule is exhausted, so setting this higher than 1328 is harmless.
%The point is only that it must not be LOWER.

if ~exist('cfgfile','var') || isempty(cfgfile)
    cfgfile = 'mGLO_conditions_main_cfg2.mat';
end
if ~exist('n','var') || isempty(n), n = 1328; end
if ~isfile(cfgfile)
    error(['Cannot find %s. Run this from the task directory, or pass the ' ...
           'path to the conditions file''s _cfg2.mat.'], cfgfile);
end

S = load(cfgfile);
f = fieldnames(S);

% Back up before touching anything. This file holds the rig's screen
% geometry, eye tracker, reward and saved editables for every subject.
bak = sprintf('%s.bak_%s', cfgfile, datestr(now,'yyyymmdd_HHMMSS')); %#ok<TNOW1,DATST>
copyfile(cfgfile, bak);
fprintf('backed up to %s\n\n', bak);

fprintf('%-18s %-10s %10s -> %-10s %s\n', 'variable','subject','old','new','countCorrectOnly');
changed = 0;
for i = 1:numel(f)
    v = S.(f{i});
    if ~isprop(v,'NumberOfTrialsToRunInThisBlock') && ~isfield(v,'NumberOfTrialsToRunInThisBlock')
        continue
    end

    % Only ever RAISE the cap. A profile already set higher than n was set
    % that way on purpose and is harmless -- mglo_block_selector ends the
    % session after the schedule's last correct trial regardless. Lowering it would be a silent change to
    % somebody else's setting.
    old = v.NumberOfTrialsToRunInThisBlock;
    v.NumberOfTrialsToRunInThisBlock = max(old, n);

    % 1328 is a count of CORRECT trials, so the cap has to be counting the
    % same thing. Every profile already has this on; set it in case one does not.
    ccot = v.CountOnlyCorrectTrials;
    if ~all(ccot)
        v.CountOnlyCorrectTrials = true(size(ccot));
        warning('%s had CountOnlyCorrectTrials off; turned on.', f{i});
    end

    subj = '';
    if isprop(v,'SubjectName') || isfield(v,'SubjectName'), subj = v.SubjectName; end
    note = '';
    if isequal(old, v.NumberOfTrialsToRunInThisBlock), note = '(already high enough)'; end
    fprintf('%-18s %-10s %10s -> %-10s %-6s %s\n', f{i}, subj, mat2str(old), ...
        mat2str(v.NumberOfTrialsToRunInThisBlock), mat2str(v.CountOnlyCorrectTrials), note);

    S.(f{i}) = v;
    changed = changed + 1;
end

if 0 == changed
    error('No MLConfig found in %s -- is that the right file?', cfgfile);
end

save(cfgfile, '-struct', 'S');
fprintf('\n%d config(s) updated in %s\n', changed, cfgfile);
fprintf('Open MonkeyLogic and confirm the trials-per-block box reads %d.\n', n);
end
