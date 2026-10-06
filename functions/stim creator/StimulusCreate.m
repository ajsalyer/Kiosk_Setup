%%

%STIM MAKER (VISUAL CONTRAST) >>>>>>
currentFolder = pwd;
addpath(genpath(currentFolder));
% The third argument REDUCES contrast (0 = full, 0.3 = flat grey); see
% create_drifting_sine_grating_simple.m.
% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000c.avi', 0); %full contrast (0.20-0.80)
% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000c.avi', 0.05); %high contrast (0.25-0.75)
% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000c.avi', 0.10); %mid contrast (0.30-0.70)
% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000c.avi', 0.15); %low contrast (0.35-0.65)

% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000.avi', 0.0);
% create_drifting_sine_grating_simple(0, 'stimulus/visual/g000c.avi', 0.0);
create_drifting_sine_grating_simple(0, 'stimulus/visual/g000cc.avi', 0.2); %very low contrast (0.40-0.60)

%%