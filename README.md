# Multisensory GLO (mGLO)

Multimodal global–local oddball task for NIMH MonkeyLogic 2.4, with its
stimuli, offline analysis and rig setup.

---

## Before you can run it: four movie files are missing

The conditions file loads `stimulus/visual/A.avi`, `B.avi`, `A4.avi` and
`B4.avi` — **all four**: `A`/`B` are the standards on every condition, and
`A4`/`B4` are the visual deviants in conditions 3, 4, 7, 8, 16 and 19. None
of them is in this repository: each is about 159 MB (151 MiB), past
GitHub's 100 MB per-file limit. MonkeyLogic loads every TaskObject when the
conditions file opens, so the task will not start without them, even with
the procedural-stimulus (jitter) path switched on.

Copy them into `stimulus/visual/` from the rig before running. On the rig,
`A.avi` is byte-identical to `A4.avi` and `B.avi` to `B4.avi`, so only
**two distinct files** need copying — copy each one under both names.

`stimulus/visual/Contrast - I/` contains small (~3 MB) movies with the same
four names. They are **not** the rig files (different size and encoding)
and nothing loads them. Do not copy them up a level as stand-ins without
checking they show the intended stimulus.

Everything else — the other movies, all audio, all images — is included.

---

## Layout

```
mGLO.m                       the task (MonkeyLogic timing file)
mGLO_conditions_main.txt     26 conditions, all in MonkeyLogic block 1
mGLO_conditions_main_cfg2.mat  rig config (subject profiles, screen, reward)
alert_function.m             session-end hooks  -- see "Automation" below
userplot.m                   live control-screen plot

analysis/
  performance/               per-session performance plots
  all analysis/              driver, helpers, optional analyses, auto-analysis
functions/
  condition selector/        serves the day's schedule
  block selector/            ends the session
  trial order/               builds the schedule
  user plot/                 live plot implementations
  stim creator/              generates gratings, tones, response ports
  screen match adjust/       screen geometry and layout constants
  KioskArduinoJuiceCode/     reward pump firmware
stimulus/
  visual/                    .avi movies and .png images
  audio/                     .wav tones
data archive/                move recordings here by hand (contents ignored)
```

`alert_function.m` and `userplot.m` must stay at the top level: MonkeyLogic
finds them by location, and a copy in the task directory takes priority over
the one in the MonkeyLogic installation. Nothing in the rig config points at
them, so they work on any machine without configuration.

---

## Task design

Three stimulus presentations per trial; the third may deviate. Labels read
`VAVAVA` — one [visual audio] pair per presentation, `O` meaning that
stimulus is omitted.

Eight **virtual blocks**, each run twice per session. MonkeyLogic's own
`Block` is always 1; the real block identity is built by `make_trial_order`,
served by `mglo_condition_selector`, and published as
`TrialRecord.User.VirtualBlock`.

| Virtual block | Trials/run | Standard | Deviants |
|---|---|---|---|
| 1–4  multisensory A/B, omission A/B | 100 | 70% | 10% / 10% / 10% |
| 5–8  visual A/B, auditory X/Y       | 66  | 70% | 15% / 15% |

**1328 correct trials** per full session. Blocks 5–8 land on 46/10/10 of 66
(69.7% / 15.2% / 15.2%) because 66 cannot split 70/15/15 exactly.

The first `HAB_TRIALS` of each block are standards with certainty; the rest
are split into **packets** that each carry an exact share of every trial
type, so deviants cannot clump — the deviant rate is stable across the
block, not merely correct on average over it.

When a trial fails, `mglo_condition_selector` pushes its condition a few
slots later so it is retried — but never past the end of its own
habituation run or packet. Retries therefore cannot move a deviant into
habituation or change any packet's composition.

The schedule file is `trial_orders/trial_order_<yyyymmdd>.mat`, named for
the day a session **starts**: a session that runs past midnight keeps using
it. Each day's packets are seeded from that date, so a rebuilt order is
identical within a day and no two days share deviant positions.

Edit `RATIO`, `BLOCK_TRIALS`, `HAB_TRIALS` or `PACKETS` at the top of
`functions/trial order/make_trial_order.m`, then run `remake_trial_order`.
It prints the realised percentages so a change can be checked at a glance,
and refuses any `PACKETS` value that does not divide a block exactly rather
than silently rounding.

---

## Rig setup

**Trials per block.** MonkeyLogic keeps its own cap,
`NumberOfTrialsToRunInThisBlock`, and ends the block the moment it is
reached — independently of the schedule. Any value below 1328 stops a
session early (the rig has carried 960 and lower test values; check the
"trials to run in this block" box). Raise it for every subject at once,
with MonkeyLogic closed:

```matlab
mGLO_set_trial_count          % defaults to the main config, 1328
```

Setting it higher than 1328 is harmless — `mglo_block_selector` ends the
session on its own once the schedule is exhausted. It must simply never be
lower.

**Display.** Stimulus sizes are computed from constants in
`functions/screen match adjust/mglo_screen_match_adjust.m`, currently
1920×1080 at 22×15 cm and 20 cm viewing distance. **Those two do not agree**:
22×15 cm is 1.47:1 and 1920×1080 is 1.78:1, so at least one of them is
wrong, and because `PX_PER_DEG` comes from the height, a wrong height
mis-sizes every stimulus. Measure the subject screen and correct the
constants; the function warns while they disagree. `DEG_PER_REL` (editable in
the V-menu, default 15) sets the layout half-range in visual degrees — the
subject screen must span at least that much, or the layout runs off the
edges and everything looks zoomed in.

MonkeyLogic needs true pixels. Windows display scaling must be **100%**, and
`MATLAB.exe` must not carry a *high DPI override* compatibility flag —
either one makes MATLAB misreport the screen and `PixelsPerDegree` comes out
wrong. With both fixed, `mglo_screen_match_adjust` can take MonkeyLogic's
measured screen instead of the constants above and fit any panel
automatically; see the "Screen geometry" note in `mGLO.m`.

---

## Automation

With the **alert button on** in the MonkeyLogic task panel (saved in the
config as `RemoteAlert`; check it before a session), `alert_function.m`
runs:

- **task end / abort** — saves the control screen to
  `analysis/figures/ControlScreen_<session>.jpg`. Last possible moment:
  MonkeyLogic destroys that window one line later.
- **window closed** — re-analyses the recording: figures to
  `analysis/figures/` as `.jpg`, full results to `analysis/results/` as
  `.mat`, and one summary row appended to `analysis/results/sessions.csv`.

Both helpers are written never to throw, so an analysis failure cannot take
down the task or lose a recording. The auto-analysis closes only the
figures it created; MonkeyLogic's windows and your own are left open.

**Live plot.** `userplot.m` shows `mGLO_active_plot` when the task runs with
`ACTIVE` on and `mGLO_userplot` for passive sessions, switching on its own.

---

## Analysis

```matlab
bhv = mlconcatenate('260925_Joule_mGLO_conditions_main.bhv2');
R   = mgloAnalyzeSession(bhv, struct('subject', 'Joule'));
```

Options: `plots`, `psychometric`, `signal`, `goal`, `save`, `savedir`,
`tag`, `saveResults`, `subject`. Every figure is written as `.jpg`; files
are suffixed with the session's start time (`yymmdd_HHMMSS`) unless you pass
a `tag`.
`sessions.csv` accumulates one row per session for cross-day comparison.
Each row carries a `sessionKey` (the first trial's start time), so
re-analysing a session — by hand or automatically, under any tag —
replaces its row rather than duplicating it.

Per-trial variables worth knowing: `VirtualBlock`, `ConditionType`,
`Modality` (the modality actually shown, after the block override),
`ManReward` (cumulative manual rewards, including that trial's), and
`IntanTrigger` (1 if the INTAN sync pulse was sent that trial — if the DAQ
call fails, the task warns once on the control screen and logs 0).

**Event codes.** The trial-start condition marker is `100 + condition`,
which reuses the scene-code numbers (101–106, 109, 110). Decode scene events
by their order, as `mgloCalculateRT` does, not by value alone. In the
stimulus barcode, orientation (`2008`) is `999` when no movie was shown on
that presentation (an `O` in the label, or the visual modality masked).

`pumpCalculator` reads sessions from both the task root and
`data archive/`. Its hand-measured `MANUAL` rows must stay in step with the
sessions it finds, one `[trials, amount]` row each, in file-name order; it
plots `amount / trials` against the reward duration.

---

## Recordings

MonkeyLogic has no setting for an output folder, so recordings land next to
the conditions file at the task root. Move them into `data archive/` by
hand; its contents are ignored, so nothing is ever committed.
`mglo_collect_data` will do the move, never renaming and never overwriting —
same-day repeat sessions collide by name and are left in place for you to
sort out.
