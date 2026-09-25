function output_block = mglo_block_selector(TrialRecord)
%mglo_block_selector  Keep MonkeyLogic in block 1 and end the session.
%
%Set this as BOTH the Block selection function ("user-defined") AND the
%Block change function in the MonkeyLogic main menu. MonkeyLogic special
%cases the two being the same handle (mltrialrecord.m:236), which is what
%makes the return value mean "next block" rather than merely "change".
%
%  -1  quit the task        (mltrialrecord.m:142 and :232)
%   0  stay in this block   (mltrialrecord.m:234, no change)
%   1  go to block 1        (first trial only)
%
%The real blocks are virtual and live in blocks_today inside the day's
%trial_orders\*.mat. Every condition sits in MonkeyLogic block 1, exactly
%like glo_omission.txt, so the condition selector is free to return any of
%the 16. Translated from the oGLO version; pristine copy in
%stuff_hamed_gaveme\.

order_filename = append('trial_orders\','trial_order_',string(datetime("today",'Format','yyyyMMdd')),'.mat');
if isfile(order_filename)
    load(order_filename,'trials_today','completed')
else
    make_trial_order
end

current_correct_count = length(completed);

previous_error = TrialRecord.TrialErrors;
try
    previous_error = previous_error(end);
catch
    previous_error = 0;
end

if current_correct_count >= numel(trials_today)-1 && previous_error == 0
    output_block = -1;
elseif TrialRecord.CurrentTrialNumber == 1
    output_block = 1;
elseif isprop(TrialRecord,'BlockChange') && TrialRecord.BlockChange
    %MonkeyLogic has already decided to change block for a reason of its own
    %-- in practice its per-block trial cap, NumberOfTrialsToRunInThisBlock,
    %being reached (mltrialrecord.m:229). Returning 0 here means "stay", but
    %0 is not a block number: BlockChange stays set, the next trial enters
    %block-change logic, calls this same file as the block SELECTION
    %function, gets 0 back and dies at mltrialrecord.m:145 with
    %"Block #0 is not available". That is what ended the 960-trial run.
    %
    %Returning 1 sends it to the only block that exists. The block counter
    %resets, the session carries on, and the schedule -- not the cap --
    %decides when to stop. With the cap set clear of 1328 this never fires;
    %it is here so that a config that drifts back cannot kill a session.
    output_block = 1;
else
    output_block = 0;
end

end
