%remake_trial_order  Rebuild today's trial order after changing the ratios.
%
%The day's schedule is built ONCE and cached in trial_orders/, so editing
%BLOCK_TRIALS, HAB_TRIALS, PACKETS or RATIO in make_trial_order.m has no
%effect until the cached file is deleted. Run this after any such change.
%
%   1. edit the STRUCTURE block at the top of make_trial_order.m
%   2. run  remake_trial_order
%   3. check the printed composition matches what you wanted
%
%Step 3 matters: make_trial_order refuses to build if PACKETS no longer
%divides a block's trials or its type counts, so a changed ratio can fail
%outright rather than silently rounding.
%
%WARNING: this discards any progress recorded in today's order file. Do not
%run it partway through a recording session.
%
%NOTE: this is not a reshuffle. make_trial_order seeds from the day number,
%which is constant all day, so rebuilding without editing anything
%regenerates the identical schedule. That is what lets a crashed session resume the same
%order; it also means you cannot use this to get a different randomisation.

[order_filename, order_day] = mglo_order_file();

if isfile(order_filename)
    old = load(order_filename,'completed');
    n_done = numel(old.completed);
    if 0 < n_done
        fprintf(2,'WARNING: today''s order already has %d completed trials.\n', n_done);
        fprintf(2,'Rebuilding discards that progress. Ctrl-C now to abort.\n');
        pause(5);
    end
    delete(order_filename);
    disp('deleted the cached order');
end

make_trial_order(order_filename, order_day);
