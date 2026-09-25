function output_condition = mglo_condition_selector(TrialRecord)
%mglo_condition_selector  Serve the next scheduled mGLO trial.
%
%Set this as the Condition selection function ("user-defined") in the
%MonkeyLogic main menu. Translated from the oGLO version; pristine copy in
%stuff_hamed_gaveme\.
%
%Progress is counted in CORRECT trials only. An error does not advance the
%pointer -- instead the failed condition is pushed a few trials down the
%queue so it still gets run.

order_filename = append('trial_orders\','trial_order_',string(datetime("today",'Format','yyyyMMdd')),'.mat');
if isfile(order_filename)
    load(order_filename,'trials_today','completed','blocks_today')
else
    make_trial_order
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
    %virtual block. oGLO could hardcode 40 here because its blocks were a
    %uniform length; mGLO's are 20 and 100, so read the boundary instead.
    this_block = blocks_today(idx);
    numTrltilBlockEnd = find(blocks_today(idx:end) ~= this_block, 1) - 1;
    if isempty(numTrltilBlockEnd)
        numTrltilBlockEnd = numel(blocks_today) - idx + 1;
    end

    if numTrltilBlockEnd > 5
        trials_today(idx:idx+4) = circshift(trials_today(idx:idx+4),4); %throw error 5 trials down
    elseif numTrltilBlockEnd > 1
        trials_today(idx:idx+numTrltilBlockEnd-1) = circshift(trials_today(idx:idx+numTrltilBlockEnd-1),numTrltilBlockEnd-1);
    end
end

output_condition = trials_today(idx);

%Publish the virtual block for the timing file's event marker and the user
%plot. mGLO cannot derive it from the condition number the way oGLO did,
%because its standards appear in both the habituation and the mixed blocks.
TrialRecord.User.VirtualBlock    = blocks_today(idx);
TrialRecord.User.TrialsCompleted = current_correct_count;
TrialRecord.User.TotalScheduled  = numel(trials_today);

save(order_filename,'trials_today','completed','blocks_today')

end
