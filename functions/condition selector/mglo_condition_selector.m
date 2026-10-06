function output_condition = mglo_condition_selector(TrialRecord)
%mglo_condition_selector  Serve the next scheduled mGLO trial.
%
%Set this as the Condition selection function ("user-defined") in the
%MonkeyLogic main menu. Translated from the oGLO version; pristine copy in
%stuff_hamed_gaveme\.
%
%Progress is counted in CORRECT trials only. An error does not advance the
%pointer -- instead the failed condition is pushed a few trials down the
%queue so it still gets run. The push never leaves the current SEGMENT (the
%block's habituation run, or one packet), so a retry cannot drag a deviant
%into habituation or move trials between packets: every packet keeps its
%exact composition however many errors there are.

[order_filename, order_day] = mglo_order_file(TrialRecord);
if isfile(order_filename)
    S = load(order_filename);
    trials_today = S.trials_today;
    completed    = S.completed;
    blocks_today = S.blocks_today;
    if isfield(S,'segments_today')
        segments_today = S.segments_today;
    else
        % Order file written before segments were recorded: fall back to
        % the old behaviour, bounded by the virtual block only.
        segments_today = blocks_today;
    end
else
    [trials_today, blocks_today, completed, segments_today] = ...
        make_trial_order(order_filename, order_day);
end

%Figure out if the previous trial was correct or not
previous_error = TrialRecord.TrialErrors;
try
    previous_error = previous_error(end);
catch
    previous_error = 0;
end

if previous_error == 0 && TrialRecord.CurrentTrialNumber > 1
    previous_conditions = TrialRecord.ConditionsPlayed;
    completed = [completed,previous_conditions(end)];
end

current_correct_count = length(completed);

%Schedule finished. Hold on the last condition; mglo_block_selector ends
%the session on this same trial.
if current_correct_count >= numel(trials_today)
    output_condition = trials_today(end);
    TrialRecord.User.VirtualBlock = blocks_today(end);
    return
end

idx = current_correct_count + 1;

if previous_error ~= 0
    %Throw the error 5 trials down, but never past the end of the current
    %segment (habituation run or packet). oGLO could hardcode 40 here
    %because its blocks were a uniform length; mGLO's segments are 10 to 28
    %trials, so read the boundary instead.
    this_seg = segments_today(idx);
    numTrltilSegEnd = find(segments_today(idx:end) ~= this_seg, 1) - 1;
    if isempty(numTrltilSegEnd)
        numTrltilSegEnd = numel(segments_today) - idx + 1;
    end

    if numTrltilSegEnd > 5
        trials_today(idx:idx+4) = circshift(trials_today(idx:idx+4),4); %throw error 5 trials down
    elseif numTrltilSegEnd > 1
        trials_today(idx:idx+numTrltilSegEnd-1) = circshift(trials_today(idx:idx+numTrltilSegEnd-1),numTrltilSegEnd-1);
    end
end

output_condition = trials_today(idx);

%Publish the virtual block for the timing file's event marker and the user
%plot. mGLO cannot derive it from the condition number the way oGLO did,
%because its standards appear in both the habituation and the mixed blocks.
TrialRecord.User.VirtualBlock    = blocks_today(idx);
TrialRecord.User.TrialsCompleted = current_correct_count;
TrialRecord.User.TotalScheduled  = numel(trials_today);

totalNumTrial = numel(trials_today);
save(order_filename,'trials_today','completed','blocks_today','segments_today','totalNumTrial')

end
