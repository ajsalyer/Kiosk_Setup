% MULTIMODAL Global Local Oddball - ACTIVE/PASSIVE toggle - Tokenized - OPTIMIZED
%
% Works with the rig condition file mGLO_conditions_main.txt (26 conditions,
% single MonkeyLogic block, TaskObjects 1-7: fix + [snd mov] x 3) plus
% mglo_condition_selector / mglo_block_selector (virtual blocks in the day's
% trial_orders/*.mat, created on first use by make_trial_order, published as
% TrialRecord.User.VirtualBlock).
%
% samp labels are 'VAVAVA': one [visual audio] letter pair per presentation,
% three presentations, the third being the one that can deviate. 'O' in either
% slot means that stimulus is OMITTED on that presentation (the object still
% exists in the conditions file -- MonkeyLogic collapses runs of tabs, so a
% blank cell would renumber everything after it -- it is simply never shown).
%
% ACTIVE = true   2-target software choice (CircleGraphic ports, no conditions
%                 file change needed). Correct side is randomized per trial.
% ACTIVE = false  passive fixation only; choice scene is skipped entirely.
%
% STIMULUS JITTER: nonzero orientationRand/frequencyRand switches the trial
% to procedural stimuli (as in the original mGLO.m): grating angle =
% orientationA/B + rand*orientationRand, tone freq = frequencyX/Y *
% (1+rand*min(frequencyRand,1)). Zero (default) = rig TaskObject path.

if TrialRecord.CurrentTrialNumber == 1
    currentFolder = pwd;
    addpath(genpath(currentFolder));
    TrialRecord.User.TaskDir = currentFolder; % cached for measuring art files
end

if TrialRecord.CurrentTrialWithinBlock == 1
    TrialRecord.User.numCorrectWithinBlock = 0;
end

% set_bgcolor([0.5 0.5 0.5]);

%%%%%%%%%%%%%%%%%%% V-MENU VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

VISSCALE = 1.0;
SINGLE_MODALITY_BLOCKS = true;
ACTIVE = true;

INCORRECT_TIME_OUT_PENALTY = 1000;
PUMP_DURATION = reward_dur;
NUM_REWARD_BASELINE = 1;
NUM_REWARD_TOKENS = 10;

MAX_TOKENS = 10;
MIN_TOKENS = 0;
CASHOUT_BONUS_TOKENS = 4;

STANDARD_REWARD_TOKENS = 3;
STANDARD_PENALTY_TOKENS = 3;
ODDBALL_REWARD_TOKENS = 3;
ODDBALL_PENALTY_TOKENS = 3;

CUE_TOKENS = 0;
CUE_TRIALS = 0;
GUIDE_THRESH = 10000;

STRD_RATIO = 0.50;
OB_RATIO = 0.10;

FIXATION_DUR = 500;
STIM_DUR = 500;
STIM_DELAY_DUR = 500;
PRE_CHOICE_DELAY = 1000;
MAX_REACTION_TIME = 2500;

INCORRECT_SCALE = 1;
SCALE_CORRECT_TRIALS = 50;

REPEAT_ERROR_PROB = 0.0;
DYNAMIC_DELTA_GUIDE = 0.001;
DYNAMIC_DELTA_GUIDE_VIS = 0.001;
DYNAMIC_DELTA_GUIDE_AUD = 0.001;
AUD_STIM_GUIDE = 0.5;
VIZ_STIM_GUIDE = 1;

% Stimulus jitter ranges (procedural path; 0 = off = TaskObject path).
orientationRand = 0;
orientationA = 45;
orientationB = 135;
frequencyRand = 0;
frequencyX = 432;
frequencyY = 864;

FIX_RADIUS = 5.0;
HOLD_RADIUS = 3.0;
RESPONSEPORT_RADIUS = 2.5;
SEQ_LENGTH = 3;
DEG_PER_REL = 15;

hold_equals_fix = true;

% editable('hold_equals_fix');

if hold_equals_fix == true
    FIX_RADIUS = HOLD_RADIUS;
end

%%%%%%%%%%%%%%%%%%% V-MENU EDITABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MODE = {'MULTISENSORY', 'AUDITORY', 'VISUAL', 'MULTISENSORY'}; % the last element indicates the selected item
editable('-category', 'MODE');
editable('ACTIVE');
editable('SINGLE_MODALITY_BLOCKS');
editable('DEG_PER_REL');

modeCNT = numel(MODE);
TrialRecord.User.MODE = MODE{end};

TOKENS =  {'BILLS', 'CIRCLES', 'UNTOKENIZED', 'UNTOKENIZED'}; % the last element indicates the selected item
editable('-category', 'TOKENS');

%%% REWARD SETTINGS
editable('NUM_REWARD_BASELINE');
editable('NUM_REWARD_TOKENS');
editable('INCORRECT_TIME_OUT_PENALTY');

%%% TOKENS SETTINGS
editable('MAX_TOKENS');
editable('CASHOUT_BONUS_TOKENS');
editable('STANDARD_REWARD_TOKENS');
editable('STANDARD_PENALTY_TOKENS');
editable('ODDBALL_REWARD_TOKENS');
editable('ODDBALL_PENALTY_TOKENS');

%%% TASK SPECIFICS
editable('CUE_TRIALS');
editable('STRD_RATIO');
editable('OB_RATIO');

%%% STIMULUS SETTINGS
editable('FIXATION_DUR');
editable('STIM_DUR');
editable('STIM_DELAY_DUR');
editable('PRE_CHOICE_DELAY');
editable('MAX_REACTION_TIME');

editable('RESPONSEPORT_RADIUS');
editable('HOLD_RADIUS');

editable('SCALE_CORRECT_TRIALS');
editable('INCORRECT_SCALE');
editable('DYNAMIC_DELTA_GUIDE');

editable('AUD_STIM_GUIDE');
editable('VIZ_STIM_GUIDE');
editable('DYNAMIC_DELTA_GUIDE_VIS');
editable('DYNAMIC_DELTA_GUIDE_AUD');

editable('VISSCALE');

%%% Stimulus jitter (orientation / frequency randomization)
editable('orientationRand');
editable('orientationA');
editable('orientationB');
editable('frequencyRand');
editable('frequencyX');
editable('frequencyY');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TrialRecord.User.GuideTokenTreshold = GUIDE_THRESH;
TrialRecord.User.MaxTokens = MAX_TOKENS;
TrialRecord.User.MinTokens = MIN_TOKENS;
TrialRecord.User.Standard_Ratio  = STRD_RATIO;
TrialRecord.User.Primary_OB_Ratio = OB_RATIO;
TrialRecord.User.CurrentGuideScale = 1.0;

if TrialRecord.CurrentTrialNumber == 1 % Initiate Variables

    TrialRecord.User.CurrentTokens = TrialRecord.User.MinTokens;
    TrialRecord.User.TokenScore = 0;
    TrialRecord.User.TokenOuts = 0;
    TrialRecord.User.LastTokenOut = 1;

    TrialRecord.User.ChoiceLog = [];
    TrialRecord.User.AnsweredCount = 0; % correct + incorrect (error 0 or 6)
    TrialRecord.User.CorrectTrials = 0;

    TrialRecord.User.ManReward = 0;
    TrialRecord.User.EngagedWithinBlock = 0;

    TrialRecord.User.NumberStandards = 0;
    TrialRecord.User.NumberDoubleOddballs = 0;

    TrialRecord.User.NumberVisualOddballs = 0;
    TrialRecord.User.NumberAuditoryOddballs = 0;

    TrialRecord.User.ConditionType = [];

    TrialRecord.User.ConditionInfo = string([]);
    TrialRecord.User.NumConditions = zeros(1, 60);
    TrialRecord.User.SensitivityIndex = [];
    TrialRecord.User.SensIndex = 0;

    TrialRecord.User.BlockNames = ["multisensory A", "multisensory B", "omission A", "omission B", "visual A", "visual B", "auditory X", "auditory Y"];

end

%--- Screen geometry + relative-axes layout --------------------------------
% Rel-unit layout and derived scales live in
% functions/screen match adjust/mglo_screen_match_adjust.m. Unpacked into
% the same local names the rest of this file already uses.
%
% The geometry is DETECTED, not configured here, so the same file runs on a
% rig, a training kiosk or a laptop: MonkeyLogic's Screen (resolution and
% PixelsPerDegree) and MLConfig (diagonal size and viewing distance, as
% entered in that machine's MonkeyLogic menu) are both in scope in a timing
% file (trialholder_v2.m). PixelsPerDegree is the conversion MonkeyLogic
% itself uses for every TaskObject and fixation window; it comes from the
% adapter's native display mode, not MATLAB's DPI-scaled screen size, so
% Windows display scaling does not distort it. If the screen spans fewer
% degrees than the layout needs, the token row and choice ports are
% compressed to fit; the stimulus keeps its size in degrees.
if exist('Screen','var') && exist('MLConfig','var')
    SCR = mglo_screen_match_adjust(DEG_PER_REL, Screen, [], MLConfig);
elseif exist('Screen','var')
    SCR = mglo_screen_match_adjust(DEG_PER_REL, Screen);
else
    SCR = mglo_screen_match_adjust(DEG_PER_REL);   % offline preview panel
end
if TrialRecord.CurrentTrialNumber == 1
    if SCR.Measured
        geomSource = 'measured by MonkeyLogic';
    else
        geomSource = 'NOT measured -- offline preview panel';
    end
    user_text(sprintf('Screen %dx%d px, %.1f px/deg (%s)', SCR.SCREEN_RES_WIDTH, ...
        SCR.SCREEN_RES_HEIGHT, SCR.PX_PER_DEG, geomSource));
end
% Reported once, and again only if the fit changes (e.g. DEG_PER_REL edited
% mid-session), so it does not fill the message box every trial.
if SCR.LayoutFitted && (~isfield(TrialRecord.User,'LayoutFitShown') || ...
        TrialRecord.User.LayoutFitShown ~= SCR.REL2DEG)
    TrialRecord.User.LayoutFitShown = SCR.REL2DEG;
    user_text(sprintf('Layout fitted to screen: +/-%.1f deg (DEG_PER_REL %g)', SCR.REL2DEG, DEG_PER_REL));
end

REL2DEG            = SCR.REL2DEG;
TOKEN_REL_Y        = SCR.TOKEN_REL_Y;
TOKEN_REL_HALFSPAN = SCR.TOKEN_REL_HALFSPAN;
PORT_REL_X         = SCR.PORT_REL_X;
STIM_REL_DIAM      = SCR.STIM_REL_DIAM;

CONTRAST           = SCR.CONTRAST;
DONUT_SIZE         = SCR.DONUT_SIZE;
SCREEN_HEIGHT      = SCR.SCREEN_HEIGHT;
SCREEN_WIDTH       = SCR.SCREEN_WIDTH;
SCREEN_RES_WIDTH   = SCR.SCREEN_RES_WIDTH;
SCREEN_RES_HEIGHT  = SCR.SCREEN_RES_HEIGHT;
DISTANCE_TO_SCREEN = SCR.DISTANCE_TO_SCREEN;
A_DEGREE           = SCR.A_DEGREE;
B_DEGREE           = SCR.B_DEGREE;
SPATIAL_FREQUENCY  = SCR.SPATIAL_FREQUENCY;
TEMPORAL_FREQUENCY = SCR.TEMPORAL_FREQUENCY;

PX_PER_DEG         = SCR.PX_PER_DEG;
STIM_SLOT_PX       = SCR.STIM_SLOT_PX;
STIM_FALLBACK_PX   = SCR.STIM_FALLBACK_PX;
TOKEN_IMG_FILL     = SCR.TOKEN_IMG_FILL;
TOKEN_IMG_MAXH_REL = SCR.TOKEN_IMG_MAXH_REL;
SIZE               = SCR.SIZE; % stimulus diameter, visual degrees (barcode)

maxTokens = TrialRecord.User.MaxTokens;
xPositions = linspace(-TOKEN_REL_HALFSPAN, TOKEN_REL_HALFSPAN, maxTokens) * REL2DEG;
yPosition = TOKEN_REL_Y * REL2DEG;

% OPTIMIZATION: Define Token Styles ONCE here to avoid repetitive checking in loops
if strcmp(TOKENS{end}, 'UNTOKENIZED')
    activeToken = {'stimulus/visual/nullGrey.png'};
    inactiveToken = {'stimulus/visual/nullGrey.png'};
    isCircles = false;
elseif strcmp(TOKENS{end}, 'CIRCLES')
    activeToken = {[1 1 0], [1 1 0], 1};
    inactiveToken = {[1 1 0], [.5 .5 .5], 1};
    isCircles = true;
else % BILLS or default
    activeToken = {'stimulus/visual/reward.png'};
    inactiveToken = {'stimulus/visual/nullreward.png'};
    isCircles = false;
end

% Measure native art sizes (trial 1, or when TOKENS mode changes) so image
% and video assets of ANY size fit their slots. Falls back to 1 (current
% behavior) if a file cannot be read.
if ~isfield(TrialRecord.User,'TokenArtMode') || ~strcmp(TrialRecord.User.TokenArtMode, TOKENS{end})
    TrialRecord.User.TokenArtMode = TOKENS{end};
    TrialRecord.User.TokenImgScale = 1;
    TrialRecord.User.G000WH = [400 400];
    try
        taskDir = TrialRecord.User.TaskDir;
        if ~isCircles
            ia = imfinfo(fullfile(taskDir, activeToken{1}));
            ib = imfinfo(fullfile(taskDir, inactiveToken{1}));
            nw = max(ia.Width, ib.Width);
            nh = max(ia.Height, ib.Height);
            spacingPx = (2*TOKEN_REL_HALFSPAN*REL2DEG/max(maxTokens-1,1))*PX_PER_DEG;
            TrialRecord.User.TokenImgScale = min([1, TOKEN_IMG_FILL*spacingPx/max(nw,1), ...
                TOKEN_IMG_MAXH_REL*REL2DEG*PX_PER_DEG/max(nh,1)]);
        end
        try
            r = VideoReader(fullfile(taskDir, 'stimulus', 'visual', 'g000.avi'));
            TrialRecord.User.G000WH = [r.Width r.Height];
        catch
        end
    catch
    end
end
tis = TrialRecord.User.TokenImgScale;
g000Scale = STIM_SLOT_PX / max(TrialRecord.User.G000WH(1), 1);

% Pre-allocate
if isCircles
    tokenList = cell(maxTokens, 6);
else
    tokenList = cell(maxTokens, 3);
end

% OPTIMIZATION: Vectorized loop logic
for i = 1:maxTokens
    if i <= TrialRecord.User.CurrentTokens
        prop = activeToken;
    else
        prop = inactiveToken;
    end

    if isCircles
        tokenList(i, :) = [prop, {[xPositions(i) yPosition], 1, 0}];
    else
        tokenList(i, :) = [prop, {[xPositions(i) yPosition], tis}];
    end
end

if isCircles
    crc = CircleGraphic(null_);
    crc.List = tokenList;
else
    crc = ImageGraphic(null_);
    crc.List = tokenList;
end

choice_count = 0;

% define time intervals (in ms):
wait_for_fix = 4000;
initial_fix = FIXATION_DUR;
stimulus_time = STIM_DUR;
delay = STIM_DELAY_DUR;
CHOICE_TIME = 3;

% (Screen geometry + relative-axes layout lives above, before token init.)

hotkey('x', 'escape_screen;');
hotkey('p', 'escape_screen; error("Force stop by investigator/user.");');
hotkey('r', ['try ','TrialRecord.User.ManReward = TrialRecord.User.ManReward + 1; ','goodmonkey(100, ''juiceline'',7, ''numreward'',1, ''pausetime'',50, ''nonblocking'',1); ','catch ','escape_screen(); ','end']);
% ManReward is saved at the END of the trial (with the other bhv_variables),
% so presses made during this trial are included in this trial's count.

% detect an available tracker (rig autodetect; falls back to touch_)
if exist('eye_','var'), tracker = eye_;
elseif exist('eye2_','var'), tracker = eye2_;
elseif exist('touch_', 'var'), tracker = touch_;
elseif exist('joy_','var'), tracker = joy_; showcursor(true);
elseif exist('joy2_','var'), tracker = joy2_; showcursor2(true);
elseif exist('null_','var'), tracker = null_;
else, error('This task requires eye, touch or joystick input. Please set it up or turn on the simulation mode.');
end

%Mark the condition using a behavorial code
% NOTE: 100+condition (101-126) shares numbers with the scene codes
% (101-106, 109, 110) sent by run_scene below. The value is kept for
% compatibility with the recording-side decoders; offline analysis must not
% look scene codes up by value alone -- mgloCalculateRT anchors on the
% scene ORDER (106 -> 109 -> 50) instead.
current_condition = TrialRecord.CurrentCondition;
eventmarker(current_condition+100);
correctColor = [1 0 0];
wrongColor = [0 1 0];

% 6-char 'VAVAVA' label: [visual audio] x 3 presentations, 3rd can deviate.
CCI = TrialRecord.CurrentConditionInfo.samp;
isStandard = strcmp(CCI(1:2), CCI(5:6));
isDoubleOddballTrial = ~strcmp(CCI(1), CCI(5)) && ~strcmp(CCI(2), CCI(6));
isVisualOddballTrial = ~strcmp(CCI(1), CCI(5)) && strcmp(CCI(2), CCI(6));
isAudioOddballTrial = strcmp(CCI(1), CCI(5)) && ~strcmp(CCI(2), CCI(6));

if isStandard % Standard = 0
    TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) = 0;
    correctColor = [0 1 0];
    wrongColor = [1 0 0];
elseif isDoubleOddballTrial % Double Oddball = 1
    TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) = 1;
elseif isVisualOddballTrial % Visual Oddball = 1
    TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) = 1;
else % Auditory Oddball = 1 (includes O-deviants: AO/OX/OO all count as deviant)
    TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) = 1;
end

autoContrastVis = VIZ_STIM_GUIDE;
autoContrastAud = AUD_STIM_GUIDE;

if autoContrastVis < 1
    Ccount = TrialRecord.User.numCorrectWithinBlock;
    autoContrastVis = autoContrastVis + DYNAMIC_DELTA_GUIDE_VIS*Ccount;
end

if autoContrastAud < 1
    Ccount = TrialRecord.User.numCorrectWithinBlock;
    autoContrastAud = autoContrastAud + DYNAMIC_DELTA_GUIDE_AUD*Ccount;
    autoContrastAud = min(autoContrastAud, 1.0);
elseif autoContrastAud > 1
    Ccount = TrialRecord.User.numCorrectWithinBlock;
    autoContrastAud = autoContrastAud - DYNAMIC_DELTA_GUIDE_AUD*Ccount;
    autoContrastAud = max(autoContrastAud, 1.0);
end

autoContrastVis = min(autoContrastVis, 1.0);

MULTISENSORY = false;
AUDITORY = false;
VISUAL = false;
modeFLAG = MODE{modeCNT};

% Virtual blocks (mglo_condition_selector) drive single-modality overrides.
% Falls back to MonkeyLogic's own block when the selector is not running.
% Deliberately NOT written back to TrialRecord.User.VirtualBlock: only the
% selector may set that field. Writing it here made it look as if the
% selector were running, so from trial 2 on XBlock froze at trial 1's value
% and the legacy branch below could never be reached.
hasVirtualBlock = isfield(TrialRecord.User,'VirtualBlock');
if hasVirtualBlock
    XBlock = TrialRecord.User.VirtualBlock;
else
    XBlock = TrialRecord.CurrentBlock;
end

switch modeFLAG
    case "MULTISENSORY"
        MULTISENSORY = true;
    case "VISUAL"
        VISUAL = true;
    case "AUDITORY"
        AUDITORY = true;
end

if SINGLE_MODALITY_BLOCKS && hasVirtualBlock
    % Unimodal virtual blocks (5,6 visual / 7,8 auditory) already omit the
    % other modality on every presentation via 'O', so this only forces the
    % MODE mask to match the schedule. Multisensory + omission blocks (1-4)
    % stay MULTISENSORY so the O-deviants can show.
    vb = XBlock;
    if vb == 5 || vb == 6
        VISUAL = true; AUDITORY = false; MULTISENSORY = false;
    elseif vb == 7 || vb == 8
        VISUAL = false; AUDITORY = true; MULTISENSORY = false;
    else
        VISUAL = false; AUDITORY = false; MULTISENSORY = true;
    end
elseif SINGLE_MODALITY_BLOCKS
    % Legacy fallback for multi-block conditions files without VirtualBlock.
    if TrialRecord.CurrentBlock == 4
        VISUAL = true; AUDITORY = false; MULTISENSORY = false;
    elseif TrialRecord.CurrentBlock == 5
        VISUAL = false; AUDITORY = true; MULTISENSORY = false;
    elseif TrialRecord.CurrentBlock == 7
        VISUAL = false; AUDITORY = false; MULTISENSORY = true;
    else
        VISUAL = false; AUDITORY = false; MULTISENSORY = true;
    end
end

% The modality mask actually applied this trial (after the block override
% above), not merely the MODE menu selection. Saved as the Modality bhv
% variable at the end of the trial.
if VISUAL
    TrialRecord.User.Modality = 'VISUAL';
elseif AUDITORY
    TrialRecord.User.Modality = 'AUDITORY';
else
    TrialRecord.User.Modality = 'MULTISENSORY';
end
TrialRecord.User.ActiveMode = ACTIVE; % read by userplot.m to pick the live plot

% Rig TaskObjects: 1 fix, 2/4/6 snd, 3/5/7 mov. Objects always exist in the
% conditions file; an 'O' in the label drops that object from the scene.
fixation_point = 1;
aud_stim_1 = 2;
viz_stim_1 = 3;
aud_stim_2 = 4;
viz_stim_2 = 5;
aud_stim_3 = 6;
viz_stim_3 = 7;

% Guided visual deviant: shrink the 3rd-presentation movie while it is still
% a deviant (present, differs from presentation 1). Asset itself (A4/B4)
% already marks the deviant; this only scales it. All three movies are set
% every trial from their MEASURED native sizes (TaskObject.Size, px), so
% movie assets of any size render STIM_REL_DIAM in the middle.
try
    allSz = TaskObject.Size;
    w1 = allSz(viz_stim_1, 1); w2 = allSz(viz_stim_2, 1); w3 = allSz(viz_stim_3, 1);
catch
    w1 = STIM_FALLBACK_PX; w2 = STIM_FALLBACK_PX; w3 = STIM_FALLBACK_PX;
end
s1 = VISSCALE*STIM_SLOT_PX/max(w1,1);
s2 = VISSCALE*STIM_SLOT_PX/max(w2,1);
s3base = VISSCALE*STIM_SLOT_PX/max(w3,1);
rescale_object(viz_stim_1, [s1, s1]);
rescale_object(viz_stim_2, [s2, s2]);
if 'O' ~= CCI(5) && CCI(5) ~= CCI(1)
    rescale_object(viz_stim_3, [autoContrastVis*s3base, autoContrastVis*s3base]);
else
    rescale_object(viz_stim_3, [s3base, s3base]);
end

% Build each presentation from the label. MODE masks a whole modality on top.
aud_obj = [aud_stim_1 aud_stim_2 aud_stim_3];
viz_obj = [viz_stim_1 viz_stim_2 viz_stim_3];
stim = cell(1,3);
for k = 1:3
    stim{k} = fixation_point;
    if ~VISUAL   && 'O' ~= CCI(2*k),   stim{k} = [stim{k} aud_obj(k)]; end
    if ~AUDITORY && 'O' ~= CCI(2*k-1), stim{k} = [stim{k} viz_obj(k)]; end
end
stim1 = stim{1};
stim2 = stim{2};
stim3 = stim{3};

% Stimulus jitter (same draws as the original mGLO.m). Nonzero
% orientationRand/frequencyRand switches this trial to procedural stimuli:
% grating angle = orientationA/B + rand*orientationRand, tone freq =
% frequencyX/Y * (1+rand*min(frequencyRand,1)). Presentations 1-2 always
% show the standard pair CCI(1:2); presentation 3 shows CCI(5:6).
stdV = CCI(1); stdA = CCI(2); devV = CCI(5); devA = CCI(6);
orientationD = rand(1) * orientationRand;
frequencyD = 1 + (rand(1) * min(frequencyRand, 1));
useProceduralStim = (orientationRand ~= 0) || (frequencyRand ~= 0);

% Per-presentation show flags (mirror the TaskObject stim-building above).
showVisStd = (stdV ~= 'O') && ~AUDITORY;
showAudStd = (stdA ~= 'O') && ~VISUAL;
showVisDev = (devV ~= 'O') && ~AUDITORY;
showAudDev = (devA ~= 'O') && ~VISUAL;

% Actual presented orientations/frequencies (NaN = omitted). Saved below.
stdOri = NaN; devOri = NaN; stdFreq = NaN; devFreq = NaN;

if useProceduralStim
    try
        if stdV == 'A', stdOri = orientationA + orientationD;
        elseif stdV == 'B', stdOri = orientationB + orientationD; end
        if devV == 'A', devOri = orientationA + orientationD;
        elseif devV == 'B', devOri = orientationB + orientationD; end
        if stdA == 'X', stdFreq = frequencyX * frequencyD;
        elseif stdA == 'Y', stdFreq = frequencyY * frequencyD; end
        if devA == 'X', devFreq = frequencyX * frequencyD;
        elseif devA == 'Y', devFreq = frequencyY * frequencyD; end

        if ~isnan(stdOri)
            movStd = MovieGraphic(null_);
            movStd.List = {'stimulus/visual/g000.avi', [0 0]};
            movStd.Angle = stdOri;
            movStd.Scale = [VISSCALE*g000Scale VISSCALE*g000Scale];
            movStd.Looping = 1;
        end
        if ~isnan(devOri)
            movDev = MovieGraphic(null_);
            movDev.List = {'stimulus/visual/g000.avi', [0 0]};
            movDev.Angle = devOri;
            if devV ~= stdV
                movDev.Scale = [autoContrastVis*VISSCALE*g000Scale, autoContrastVis*VISSCALE*g000Scale];
            else
                movDev.Scale = [VISSCALE*g000Scale VISSCALE*g000Scale];
            end
            movDev.Looping = 1;
        end
        if ~isnan(stdFreq)
            sndStd = AudioSound(null_);
            sndStd.List = {[2000 stdFreq], true;};
            sndStd.Looping = 1;
        end
        if ~isnan(devFreq)
            sndDev = AudioSound(null_);
            sndDev.List = {[2000 devFreq], true;};
            sndDev.Looping = 1;
        end
    catch
        user_text('Procedural stimulus failed; falling back to TaskObjects.');
        useProceduralStim = false;
    end
end

%%%%%%% BEGIN CREATING SCENES %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scene 1: fixation
fix1 = SingleTarget(tracker);
fix1.Target = fixation_point;
fix1.Threshold = FIX_RADIUS;
wth1 = WaitThenHold(fix1);
wth1.WaitTime = wait_for_fix;
wth1.HoldTime = initial_fix;

con1 = Concurrent(wth1);
con1.add(fix1);
con1.add(crc);
intial_fixation_scene = create_scene(con1);

% scene 2: Show Stimulus 1
fix2 = SingleTarget(tracker);
fix2.Target = fixation_point;
fix2.Threshold = HOLD_RADIUS;
wth2 = WaitThenHold(fix2);
wth2.WaitTime = 0;
wth2.HoldTime = stimulus_time;

con2 = Concurrent(wth2);
con2.add(fix2);
con2.add(crc);
if useProceduralStim
    if showAudStd
        tsStd1 = TimeCounter(sndStd);
        tsStd1.Duration = STIM_DUR;
        con2.add(tsStd1);
    end
    if showVisStd
        tcStd1 = TimeCounter(movStd);
        tcStd1.Duration = STIM_DUR;
        con2.add(tcStd1);
    end
    stim_1_scene = create_scene(con2);
else
    stim_1_scene = create_scene(con2, stim1);
end

% scene 3: delay
fix3 = SingleTarget(tracker);
fix3.Target = fixation_point;
fix3.Threshold = HOLD_RADIUS;
wth3 = WaitThenHold(fix3);
wth3.WaitTime = 0;
wth3.HoldTime = delay;

con3 = Concurrent(wth3);
con3.add(fix3);
con3.add(crc);
delay1_scene = create_scene(con3);

% scene 4: Show Stimulus 2
fix4 = SingleTarget(tracker);
fix4.Target = fixation_point;
fix4.Threshold = HOLD_RADIUS;
wth4 = WaitThenHold(fix4);
wth4.WaitTime = 0;
wth4.HoldTime = stimulus_time;

con4 = Concurrent(wth4);
con4.add(fix4);
con4.add(crc);
if useProceduralStim
    if showAudStd
        tsStd2 = TimeCounter(sndStd);
        tsStd2.Duration = STIM_DUR;
        con4.add(tsStd2);
    end
    if showVisStd
        tcStd2 = TimeCounter(movStd);
        tcStd2.Duration = STIM_DUR;
        con4.add(tcStd2);
    end
    stim_2_scene = create_scene(con4);
else
    stim_2_scene = create_scene(con4, stim2);
end

% scene 5: delay 2
fix5 = SingleTarget(tracker);
fix5.Target = fixation_point;
fix5.Threshold = HOLD_RADIUS;
wth5 = WaitThenHold(fix5);
wth5.WaitTime = 0;
wth5.HoldTime = delay;

con5 = Concurrent(wth5);
con5.add(fix5);
con5.add(crc);
delay2_scene = create_scene(con5);

% scene 6: Show Stimulus 3 (the one that can deviate)
fix6 = SingleTarget(tracker);
fix6.Target = fixation_point;
fix6.Threshold = HOLD_RADIUS;
wth6 = WaitThenHold(fix6);
wth6.WaitTime = 0;
wth6.HoldTime = stimulus_time;

con6 = Concurrent(wth6);
con6.add(fix6);
con6.add(crc);
if useProceduralStim
    if showAudDev
        tsDev3 = TimeCounter(sndDev);
        tsDev3.Duration = STIM_DUR;
        con6.add(tsDev3);
    end
    if showVisDev
        tcDev3 = TimeCounter(movDev);
        tcDev3.Duration = STIM_DUR;
        con6.add(tcDev3);
    end
    stim_3_scene = create_scene(con6);
else
    stim_3_scene = create_scene(con6, stim3);
end

% scene 7: post-stimulus delay (PRE_CHOICE_DELAY doubles as this in passive)
fix7 = SingleTarget(tracker);
fix7.Target = fixation_point;
fix7.Threshold = HOLD_RADIUS;
wth7 = WaitThenHold(fix7);
wth7.WaitTime = 0;
wth7.HoldTime = PRE_CHOICE_DELAY;

con7 = Concurrent(wth7);
con7.add(fix7);
con7.add(crc);
delay3_scene = create_scene(con7,fixation_point);

if (TrialRecord.User.numCorrectWithinBlock >= SCALE_CORRECT_TRIALS)
    autoScale = 1;
    TrialRecord.User.CurrentGuideScale = 1;
else
    autoScale = INCORRECT_SCALE;
end

if autoScale < 1
    Ccount = TrialRecord.User.numCorrectWithinBlock;
    autoScale = autoScale + DYNAMIC_DELTA_GUIDE*Ccount;
end

autoScale = min(autoScale, 1);

GR = min([autoContrastAud, autoContrastVis, autoScale]);
TrialRecord.User.CurrentGuideScale = GR;
user_text(">Ig=" + num2str(autoScale) + ">Vg=" + num2str(autoContrastVis) + ">Ag=" + num2str(autoContrastAud));

if ACTIVE
    % Software ports: no conditions-file change needed. Side randomized per
    % trial (rig file has no -R/-L suffix). choiceA = correct (index 1),
    % choiceB = wrong (index 2); guide shrinks the wrong port.
    correctSideSign = 0;
    if rand(1) < 0.5
        correct_choice = [PORT_REL_X*REL2DEG 0];
        wrong_choice = [-PORT_REL_X*REL2DEG 0];
    else
        correct_choice = [-PORT_REL_X*REL2DEG 0];
        wrong_choice = [PORT_REL_X*REL2DEG 0];
    end
    correctSideSign = sign(correct_choice(1)); % +1 right, -1 left
    TrialRecord.User.LastCorrectSide = correct_choice;

    choice_count = 2;

    choiceA = CircleGraphic(null_);
    choiceA.List = {correctColor, correctColor, RESPONSEPORT_RADIUS*2, correct_choice, 1, 0};

    choiceB = CircleGraphic(null_);
    choiceB.List = {wrongColor, wrongColor, RESPONSEPORT_RADIUS*2, wrong_choice, 1, 0};
    choiceB.Scale = [autoScale, autoScale];
    gc = GraphicContainer(choiceA);
    gc.add(choiceB);
    choice1 = MultiTarget(tracker);
    choice1.Target = gc;
    choice1.Threshold = RESPONSEPORT_RADIUS;
    choice1.WaitTime = MAX_REACTION_TIME;
    choice1.HoldTime = CHOICE_TIME;

    con10 = Concurrent(choice1);
    con10.add(crc);
    choice_scene = create_scene(con10);

    show1 = FrameCounter(crc);
    show1.NumFrame = 1;

    con11 = Concurrent(show1);
    con11.add(crc);
    show_scene = create_scene(con11);

end

%%%%%%% BEGIN WRITING TASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clamped: AUD_STIM_GUIDE > 1 is allowed by the ramp above, but SoundVolume
% throws on anything outside [0, 1].
SoundVolume(min(max(autoContrastAud, 0), 1));
error_type = 0;
stims_observed = 0;
startTime = tic();

%Intial Fixation
run_scene(intial_fixation_scene, 10);        % Run the first scene (eventmaker 10)

if ~wth1.Success
    if wth1.Waiting
        error_type = 4;      % no fixation (4)
        eventmarker(50);
        eventmarker(4);
    else
        error_type = 3;      % fixation break (3)
        eventmarker(50);
        eventmarker(3);
    end
    % idle(0) removed for speed
end

intanTriggerSent = 0;
if 0==error_type %S1
    % Trigger flag for INTAN. Uses the legacy Data Acquisition Toolbox
    % interface (digitalio/addline/putvalue), which newer MATLAB releases no
    % longer ship. A failure must not stop the trial, but it must not be
    % silent either: warn once per session and record the outcome per trial
    % (IntanTrigger bhv variable) so unsynced trials can be found offline.
    try
        do = digitalio('nidaq','Dev1');
        addline(do,1,2,'out');
        putvalue(do,1);
        putvalue(do,0);
        intanTriggerSent = 1;
    catch ME
        if ~isfield(TrialRecord.User,'IntanWarned') || ~TrialRecord.User.IntanWarned
            TrialRecord.User.IntanWarned = true;
            warning('mGLO:intanTrigger', 'INTAN trigger failed: %s', ME.message);
            user_text('WARNING: INTAN trigger failed -- recording is NOT synced.');
        end
    end
    run_scene(stim_1_scene,101);
    stims_observed = stims_observed + 1;
    if ~wth2.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

if 0==error_type %Delay 1
    run_scene(delay1_scene,102);
    if ~wth3.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

if 0==error_type %S2
    run_scene(stim_2_scene, 103);
    stims_observed = stims_observed + 1;
    if ~wth4.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

if 0==error_type %Delay 2
    run_scene(delay2_scene,104);
    if ~wth5.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

% Auditory guide: while AUD_STIM_GUIDE < 1, presentations 1-2 play at the
% reduced autoContrastAud volume and an AUDITORY deviant on presentation 3
% plays at full volume -- the loudness step is the training cue, the audio
% counterpart of the visual guide above (which likewise only applies when
% the movie itself deviates). Only boost when the third sound is present AND
% differs from the standard; boosting on every deviant trial made standard
% tones on visual/omission deviants louder, so loudness alone gave the
% answer away.
isAudDeviantSound = 'O' ~= CCI(6) && CCI(6) ~= CCI(2);
if isAudDeviantSound
    SoundVolume(1.0);
else
    SoundVolume(min(max(autoContrastAud, 0), 1));
end

if 0==error_type %S3 (deviant slot)
    run_scene(stim_3_scene,105);
    stims_observed = stims_observed + 1;
    if ~wth6.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

if 0==error_type %Delay 3 (post-stimulus)
    run_scene(delay3_scene,106);
    if ~wth7.Success
        error_type = 3;
        eventmarker(50);
        eventmarker(3);
    end
end

if ACTIVE
    if 0==error_type
        run_scene(choice_scene,109);
        if ~choice1.Success
            % Outcome pair "50, <trialerror>" like every other outcome
            % above. The 9 here is the trialerror code, framed by the 50
            % before it; it is not MonkeyLogic's start-trial code, and
            % decoders must read it as the value following 50.
            error_type = 9;
            eventmarker(50);
            eventmarker(9);
        else
            if choice1.ChosenTarget == 2
                error_type = 6;
                eventmarker(50);
                eventmarker(6);
            else
                eventmarker(50);
                eventmarker(0);
            end
        end
    end
end

LastBalance = TrialRecord.User.CurrentTokens;
JuicePumpCnt = 0;
TrialRecord.User.trialLength = toc(startTime);

if error_type == 0
    TrialRecord.User.EngagedWithinBlock = TrialRecord.User.EngagedWithinBlock + 1;
elseif error_type == 6
    r_tmp = rand(1) > REPEAT_ERROR_PROB;
    TrialRecord.User.EngagedWithinBlock = TrialRecord.User.EngagedWithinBlock + r_tmp;
end

%%%%%%%%%%%%%%%%%%%%%%%% TOKENS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TokenLatestPerformance = TrialRecord.CurrentTrialNumber - TrialRecord.User.LastTokenOut;

if ~strcmp(TOKENS{end}, 'UNTOKENIZED')

    if 0==error_type

        if (TrialRecord.CurrentTrialWithinBlock <= CUE_TRIALS || TokenLatestPerformance > GUIDE_THRESH)
            TrialRecord.User.CurrentTokens = TrialRecord.User.CurrentTokens + CUE_TOKENS;
            TrialRecord.User.TokenScore = TrialRecord.User.TokenScore + CUE_TOKENS;
            JuicePumpCnt = NUM_REWARD_BASELINE;
        elseif TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) == 0 % standard
            TrialRecord.User.CurrentTokens = TrialRecord.User.CurrentTokens + STANDARD_REWARD_TOKENS;
            TrialRecord.User.TokenScore = TrialRecord.User.TokenScore + STANDARD_REWARD_TOKENS;
            JuicePumpCnt = NUM_REWARD_BASELINE;
        else % oddball
            TrialRecord.User.CurrentTokens = TrialRecord.User.CurrentTokens + ODDBALL_REWARD_TOKENS;
            TrialRecord.User.TokenScore = TrialRecord.User.TokenScore + ODDBALL_REWARD_TOKENS;
            JuicePumpCnt = NUM_REWARD_BASELINE;
        end

    elseif 6==error_type
        if TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber) == 0 % standard
            TrialRecord.User.CurrentTokens = TrialRecord.User.CurrentTokens - STANDARD_PENALTY_TOKENS;
            TrialRecord.User.TokenScore = TrialRecord.User.TokenScore - STANDARD_PENALTY_TOKENS;
        else
            TrialRecord.User.CurrentTokens = TrialRecord.User.CurrentTokens - ODDBALL_PENALTY_TOKENS;
            TrialRecord.User.TokenScore = TrialRecord.User.TokenScore - ODDBALL_PENALTY_TOKENS;
        end
    end

    TokenOutFlag = 0;

    if TrialRecord.User.CurrentTokens >= TrialRecord.User.MaxTokens % Token out +
        TrialRecord.User.CurrentTokens = max(CASHOUT_BONUS_TOKENS + mod(TrialRecord.User.CurrentTokens, TrialRecord.User.MaxTokens), CASHOUT_BONUS_TOKENS + TrialRecord.User.MinTokens);
        TrialRecord.User.TokenOuts = TrialRecord.User.TokenOuts + 1;
        TokenOutFlag = 1;
        JuicePumpCnt = NUM_REWARD_BASELINE + NUM_REWARD_TOKENS;
        TrialRecord.User.LastTokenOut = TrialRecord.CurrentTrialNumber;
    elseif TrialRecord.User.CurrentTokens < TrialRecord.User.MinTokens % Token off -
        TrialRecord.User.CurrentTokens = TrialRecord.User.MinTokens;
    end

    if TokenOutFlag

        for tk = 1:TrialRecord.User.MaxTokens

            % OPTIMIZATION: Vectorized creation
            if isCircles
                 tokenList2 = cell(tk, 6);
                 for i = 1:tk
                      tokenList2(i, :) = [activeToken, {[xPositions(i) yPosition], 1, 0}];
                 end
                 crc = CircleGraphic(null_);
                 crc.List = tokenList2;
            else
                 tokenList = cell(tk, 3);
                 for i = 1:tk
                      tokenList(i, :) = [activeToken, {[xPositions(i) yPosition], tis}];
                 end
                 crc = ImageGraphic(null_);
                 crc.List = tokenList;
            end

            show1 = FrameCounter(crc);
            show1.NumFrame = 1;
            token_scene = create_scene(show1);
            run_scene(token_scene);

            try
                if JuicePumpCnt > 1
                    % One pulse per token step of the cash-out animation;
                    % the last pulse is left for the residue loop below.
                    goodmonkey(PUMP_DURATION, 'juiceline',7, 'numreward', 1, 'pausetime', 80, 'eventmarker',40);
                    JuicePumpCnt = JuicePumpCnt - 1;
                end
            catch
                user_text("Juicer problem; check juice pump power source or wires");
            end
        end

        while JuicePumpCnt > 0 % reward residue
            goodmonkey(PUMP_DURATION, 'juiceline',7, 'numreward', 1, 'pausetime', 80, 'eventmarker',40);
            JuicePumpCnt = JuicePumpCnt - 1;
        end

    elseif 0==error_type

        for tk = LastBalance+1:TrialRecord.User.CurrentTokens
            if JuicePumpCnt > 0
                goodmonkey(PUMP_DURATION, 'juiceline',7, 'numreward', 1, 'pausetime', 80, 'eventmarker',40);
                JuicePumpCnt = JuicePumpCnt - 1;
            end
        end

        while JuicePumpCnt > 0 % reward residue
            goodmonkey(PUMP_DURATION, 'juiceline',7, 'numreward', 1, 'pausetime', 80, 'eventmarker',40);
            JuicePumpCnt = JuicePumpCnt - 1;
        end

    elseif 6==error_type

        % Incorrect: tokens were already deducted above and the timeout
        % penalty runs after the token display is rebuilt below. No reward.

    else
        user_text("Trial break.");
    end

else

    TokenOutFlag = -1;

    if error_type == 0
        try
            goodmonkey(PUMP_DURATION, 'juiceline',7, 'numreward', NUM_REWARD_BASELINE, 'pausetime', 120, 'eventmarker',40);
        catch
            user_text("Juicer problem; check juice pump power source or wires");
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%% END TOKENS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Answered-trial tallies (correct OR incorrect choice), not correct-only.
if error_type == 0 || error_type == 6
    TrialRecord.User.AnsweredCount = TrialRecord.User.AnsweredCount + 1;
    if isStandard
        TrialRecord.User.NumberStandards = TrialRecord.User.NumberStandards + 1;
    elseif isDoubleOddballTrial
        TrialRecord.User.NumberDoubleOddballs = TrialRecord.User.NumberDoubleOddballs + 1;
    elseif isVisualOddballTrial
        TrialRecord.User.NumberVisualOddballs = TrialRecord.User.NumberVisualOddballs + 1;
    else
        TrialRecord.User.NumberAuditoryOddballs = TrialRecord.User.NumberAuditoryOddballs + 1;
    end
end

TrialRecord.User.ChoiceLog(end+1) = choice_count;
trialerror(error_type);

% Rebuild final token display only if the balance changed during this trial.
if LastBalance ~= TrialRecord.User.CurrentTokens
    if isCircles
        tokenList = cell(maxTokens, 6);
    else
        tokenList = cell(maxTokens, 3);
    end

    for i = 1:maxTokens
        if i <= TrialRecord.User.CurrentTokens
            prop = activeToken;
        else
            prop = inactiveToken;
        end

        if isCircles
            tokenList(i, :) = [prop, {[xPositions(i) yPosition], 1, 0}];
        else
            tokenList(i, :) = [prop, {[xPositions(i) yPosition], tis}];
        end
    end

    if isCircles
        crc = CircleGraphic(null_);
        crc.List = tokenList;
    else
        crc = ImageGraphic(null_);
        crc.List = tokenList;
    end
end

if error_type == 6

    show1 = FrameCounter(crc);
    show1.NumFrame = 1;

    con11 = Concurrent(show1);
    con11.add(crc);

    tc = TimeCounter(con11);
    tc.Duration = INCORRECT_TIME_OUT_PENALTY;

    show_scene = create_scene(tc);

    run_scene(show_scene);

else

    show1 = FrameCounter(crc);
    show1.NumFrame = 1;

    con11 = Concurrent(show1);
    con11.add(crc);
    show_scene = create_scene(con11);
    run_scene(show_scene);

end

if error_type == 0
    TrialRecord.User.ConditionInfo(TrialRecord.CurrentCondition) = cellstr(struct2cell(TrialRecord.CurrentConditionInfo));
    TrialRecord.User.numCorrectWithinBlock = TrialRecord.User.numCorrectWithinBlock + 1;
    TrialRecord.User.CorrectTrials = TrialRecord.User.CorrectTrials + 1;
end

if error_type == 0 || error_type == 6
    TrialRecord.User.NumConditions(TrialRecord.CurrentCondition) = TrialRecord.User.NumConditions(TrialRecord.CurrentCondition) + 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

all_trials_so_far_values = TrialRecord.TrialErrors;
relevant_trials = ismember(all_trials_so_far_values,[0,6]);
each_condition = TrialRecord.ConditionsPlayed;
condition_percentages = zeros(max(each_condition),1);

for ii = 1:length(condition_percentages)
    denom = sum(each_condition == ii & relevant_trials);
    if denom > 0
        condition_percentages(ii) = sum(each_condition == ii & relevant_trials & all_trials_so_far_values == 0) / denom;
    else
        condition_percentages(ii) = 0;
    end
end

TrialRecord.User.ConditionAccuracy = condition_percentages;
TrialRecord.User.SensitivityIndex = TrialRecord.User.SensIndex;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bhv_variable('TokenOut', TokenOutFlag);
bhv_variable('ConditionInfo', TrialRecord.User.ConditionInfo);
bhv_variable('TokenBalance', TrialRecord.User.CurrentTokens);
bhv_variable('Sensitivity', TrialRecord.User.SensitivityIndex);
bhv_variable('GuideScale', TrialRecord.User.CurrentGuideScale);
% Per-trial metadata for offline analysis (analysis/*.m): virtual schedule
% block (ML Block is always 1 under mglo_block_selector), 0/1 standard-vs-
% deviant flag, modality mask actually applied, passive/active mode, and the
% correct side in active choice trials (+1 right, -1 left, 0 passive).
bhv_variable('VirtualBlock', XBlock);
bhv_variable('ConditionType', TrialRecord.User.ConditionType(TrialRecord.CurrentTrialNumber));
bhv_variable('Modality', TrialRecord.User.Modality);
bhv_variable('ActiveMode', ACTIVE);
if ACTIVE
    bhv_variable('CorrectSide', correctSideSign);
else
    bhv_variable('CorrectSide', 0);
end
% Stimulus-jitter metadata (analysis/*.m): 1 = procedural path this trial,
% plus the actual presented grating angles (deg) and tone freqs (Hz) for the
% standard (presentations 1-2) and deviant (presentation 3) pairs. NaN =
% omitted (TaskObject path also records NaN).
bhv_variable('Procedural', double(useProceduralStim));
bhv_variable('StdOri', stdOri);
bhv_variable('DevOri', devOri);
bhv_variable('StdFreq', stdFreq);
bhv_variable('DevFreq', devFreq);
bhv_variable('TokenImgScale', tis);
% Cumulative manual ('r' hotkey) rewards so far, including this trial's.
bhv_variable('ManReward', TrialRecord.User.ManReward);
% 1 = INTAN sync pulse sent before stimulus 1 this trial, 0 = not sent
% (trial ended before stimulus 1, or the DAQ call failed).
bhv_variable('IntanTrigger', intanTriggerSent);
% Detected display geometry, so sessions from different setups (rig, kiosk,
% laptop) can be compared: [Xsize Ysize] px, MonkeyLogic's pixels/degree,
% the layout scale actually used (deg per rel; < DEG_PER_REL when fitted),
% and whether the values were measured (1) or the offline preview (0).
bhv_variable('ScreenSizePx', [SCREEN_RES_WIDTH SCREEN_RES_HEIGHT]);
bhv_variable('PixelsPerDegree', PX_PER_DEG);
bhv_variable('LayoutDegPerRel', REL2DEG);
bhv_variable('ScreenMeasured', double(SCR.Measured));

numCorrectString = append('Number of Correct Trials within Block: ', num2str(TrialRecord.User.numCorrectWithinBlock));
user_text(numCorrectString);

%Create the barcode
eventmarker(84);
eventmarker(84);
eventmarker(84);

%Task identifier
% mGLO = 11. Hamed set this on the recording PC (visible at ~14:20 in
% IMG_3695.MOV), superseding the 10 that was proposed here.
% The original 9 was wrong twice over: it is glo_omission's task ID
% (glo_omission.m:355) and it is also MonkeyLogic's own reserved "Start
% trial" code -- see codes.txt in the NIMH ML directory, and
% trialholder_v2.m:981, which fires eventmarker(9) at the start of every
% non-test trial. Reserved set: 9 start trial, 13 frame skipped,
% 14 manual reward, 18 end trial. In use elsewhere: four_glo 1, omission 9.
eventmarker(1001);
eventmarker(11); % mGLO : 11

%trial number
eventmarker(1002);
eventmarker(TrialRecord.CurrentTrialNumber);

%Correct or not
eventmarker(1003);
if 0==error_type
    eventmarker(1);
else
    eventmarker(0);
end

%Task Sequence
eventmarker(1004);
eventmarker(0);

% Virtual block, published by mglo_condition_selector from blocks_today:
%   1 = multisensory A   2 = multisensory B   3 = omission A   4 = omission B
%   5 = visual A         6 = visual B         7 = auditory X   8 = auditory Y
% Falls back to MonkeyLogic's own block if the selector is not running.
%Block Number
eventmarker(1005);
eventmarker(XBlock);

%Condition from monkeylogic
eventmarker(1006);
eventmarker(TrialRecord.CurrentCondition);

%Background color
eventmarker(1007);
eventmarker(round(CONTRAST*255));
eventmarker(1008);
eventmarker(round(CONTRAST*255));
eventmarker(1009);
eventmarker(round(CONTRAST*255));

%Screen height and width
eventmarker(1010);
eventmarker(round(SCREEN_HEIGHT * 10));
eventmarker(1011);
eventmarker(round(SCREEN_WIDTH * 10));

%Distance to screen
eventmarker(1012);
eventmarker(round(DISTANCE_TO_SCREEN * 10));

%Screen resolution
eventmarker(1013);
eventmarker(round(SCREEN_RES_WIDTH));
eventmarker(1014);
eventmarker(round(SCREEN_RES_HEIGHT));

%Fixation dot stimulus information
eventmarker(2001);
eventmarker(1);
eventmarker(2020);
eventmarker(1);

%Information about the rest of the stimuli
ORI_NOT_SHOWN = 999; % 2008 value when no movie was shown on a presentation
if stims_observed > 0
    for k = 1:stims_observed
        % mGLO interleaves one sound and one movie per presentation, so
        % presentation k is the TaskObject pair (2k, 2k+1) -- see the
        % aud_stim_/viz_stim_ declarations above. Every marker below describes
        % a visual property, so index the movie object 2k+1 (3, 5, 7).
        ii = 2*k + 1;

        %Mark which stimulus it was
        eventmarker(2001);
        eventmarker(ii);

        %Which task_event the start happened
        eventmarker(2002);
        start_event = (k-1) * 2 + 101;
        eventmarker(start_event)

        eventmarker(2003);
        finish_event = start_event + 1;
        if 0==error_type
            eventmarker(finish_event);
        else
            eventmarker(110);
        end

        %Fixation window size
        eventmarker(2004);
        eventmarker(HOLD_RADIUS*100);

        %Positions are easy this time, all 0
        eventmarker(2005);
        eventmarker(0);
        eventmarker(2006);
        eventmarker(0);

        %Size is the same for all of them too
        eventmarker(2007);
        eventmarker(round(SIZE*100));

        %Orientation is a bit different depending on the stimulus.
        % ORI_NOT_SHOWN (999) = no movie on this presentation: an 'O' in the
        % label, or the movie masked by the AUDITORY modality. It replaces
        % the old -1 (event codes must be non-negative) and the old TaskObject
        % path's habit of reporting A/B for movies that were never shown.
        eventmarker(2008);
        visLetter = CCI(2*k-1);
        if useProceduralStim
            % Actual grating angle this presentation.
            if k < 3
                o = stdOri;
                shown = showVisStd;
            else
                o = devOri;
                shown = showVisDev;
            end
        else
            shown = ~AUDITORY && 'O' ~= visLetter;
            if 'A' == visLetter
                o = A_DEGREE;
            else
                o = B_DEGREE;
            end
        end
        if shown
            eventmarker(mod(round(o), 360));
        else
            eventmarker(ORI_NOT_SHOWN);
        end

        %Phase
        eventmarker(2009);
        eventmarker(0);

        %Spatial Frequency
        eventmarker(2010);
        eventmarker(SPATIAL_FREQUENCY*1000);

        %temporal frequency
        eventmarker(2011);
        eventmarker(TEMPORAL_FREQUENCY*10);

        %RGB
        eventmarker(2012);
        eventmarker(round(255*CONTRAST));
        eventmarker(2013);
        eventmarker(round(255*CONTRAST));
        eventmarker(2014);
        eventmarker(round(255*CONTRAST));

        %x_length y length
        eventmarker(2016);
        eventmarker(round(SIZE*10*2));
        eventmarker(2017);
        eventmarker(round(SIZE*10*2));

        %Shape
        eventmarker(2018);
        eventmarker(1);

        %Gabor
        eventmarker(2019);
        eventmarker(0);

        %Contrast
        eventmarker(2021);
        eventmarker(round(CONTRAST*1000));

        %Oddball status: the final presentation is now the 3rd.
        eventmarker(2025);
        if 3 == k
            condition_type = TrialRecord.CurrentCondition;
            eventmarker(condition_type); %each trial condition type gets a separate marker; can decode from condition .txt file later in nwb
        else
            eventmarker(0);
        end

        %Donut size
        eventmarker(2026);
        eventmarker(round(DONUT_SIZE*100));

    end
end

%Finished with barcode
eventmarker(85);
eventmarker(85);
eventmarker(85);

%%
