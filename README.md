# Multisensory GLO (mGLO)

Multimodal global–local oddball task for NIMH MonkeyLogic 2.4, with its
stimuli, offline analysis and rig setup.

---

## Before you can run it: two stimuli are missing

`stimulus/visual/A.avi` and `stimulus/visual/B4.avi` are referenced by the
conditions file but are **not in this repository** — they are 159 MB each,
past GitHub's 100 MB per-file limit. `A4.avi` and `B.avi` are excluded for
the same reason.

Copy them in from the rig before running. `A.avi` is byte-identical to
`A4.avi`, and `B.avi` to `B4.avi`, so only **two distinct files** need
copying even though four names are missing.

Everything else — the other 19 movies, all audio, all images — is included.

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

Edit `RATIO`, `BLOCK_TRIALS`, `HAB_TRIALS` or `PACKETS` at the top of
`functions/trial order/make_trial_order.m`, then run `remake_trial_order`.
It prints the realised percentages so a change can be checked at a glance,
and refuses any `PACKETS` value that does not divide a block exactly rather
than silently rounding.

---

## Rig setup

**Trials per block.** MonkeyLogic keeps its own cap,
`NumberOfTrialsToRunInThisBlock`, and ends the block the moment it is
reached — independently of the schedule. It currently reads **10** for
Joule, which stops a session after 10 correct trials. Raise it with
MonkeyLogic closed:

```matlab
mGLO_set_trial_count          % defaults to the main config, 1328
```

Setting it higher than 1328 is harmless — `mglo_block_selector` ends the
session on its own once the schedule is exhausted. It must simply never be
lower.

**Display.** Stimulus sizes are computed from constants in
`functions/screen match adjust/mglo_screen_match_adjust.m`, currently
1920×1080 at 22×15 cm and 20 cm viewing distance. `DEG_PER_REL` (editable in
the V-menu, default 15) sets the layout half-range in visual degrees — the
subject screen must span at least that much, or the layout runs off the
edges and everything looks zoomed in.

MonkeyLogic needs true pixels. Windows display scaling must be **100%**, and
`MATLAB.exe` must not carry a *high DPI override* compatibility flag —
either one makes MATLAB misreport the screen and `PixelsPerDegree` comes out
wrong. With both fixed, `mglo_screen_match_adjust` can take MonkeyLogic's
measured screen instead of the constants above and fit any panel
automatically; see the note at `mGLO.m:214`.

---

## Automation

With the **alert button on** in the MonkeyLogic task panel (`RemoteAlert`,
already set in the tracked config), `alert_function.m` runs:

- **task end / abort** — saves the control screen to
  `analysis/figures/ControlScreen_<session>.jpg`. Last possible moment:
  MonkeyLogic destroys that window one line later.
- **window closed** — re-analyses the recording: figures to
  `analysis/figures/` as `.jpg`, full results to `analysis/results/` as
  `.mat`, and one summary row appended to `analysis/results/sessions.csv`.

Both helpers are written never to throw, so an analysis failure cannot take
down the task or lose a recording.

---

## Analysis

```matlab
bhv = mlconcatenate('260925_Joule_mGLO_conditions_main.bhv2');
R   = mgloAnalyzeSession(bhv);
```

Options: `plots`, `psychometric`, `signal`, `goal`, `save`, `savedir`,
`tag`, `saveResults`, `subject`. Every figure is written as `.jpg`.
`sessions.csv` accumulates one row per session for cross-day comparison;
re-running a session replaces its row rather than duplicating it.

`pumpCalculator` needs its hand-measured `MANUAL` rows kept in step with the
sessions it finds, one `[trials, amount]` row each.

---

## Recordings

MonkeyLogic has no setting for an output folder, so recordings land next to
the conditions file at the task root. Move them into `data archive/` by
hand; its contents are ignored, so nothing is ever committed.
`mglo_collect_data` will do the move, never renaming and never overwriting —
same-day repeat sessions collide by name and are left in place for you to
sort out.
