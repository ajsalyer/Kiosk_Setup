function [order_filename, order_day] = mglo_order_file(TrialRecord)
%mglo_order_file  Path of the trial-order file the current session uses.
%
%   [order_filename, order_day] = mglo_order_file(TrialRecord) returns
%   trial_orders/trial_order_<yyyymmdd>.mat (relative to the task directory,
%   built with fullfile so it works on any OS) and the day number (datenum,
%   whole days) the schedule belongs to.
%
%   The day is fixed the first time a session asks and cached in
%   TrialRecord.User.OrderDay, so a session that runs past midnight keeps
%   serving and recording progress in the schedule it started with instead
%   of switching to a fresh one half way through.
%
%   mglo_order_file() with no TrialRecord returns today's file -- what
%   remake_trial_order and command-line use want.
%
%   Shared by mglo_condition_selector, mglo_block_selector,
%   make_trial_order and remake_trial_order so all four agree on the name.

if nargin >= 1 && ~isempty(TrialRecord) && isfield(TrialRecord.User, 'OrderDay')
    order_day = TrialRecord.User.OrderDay;
else
    order_day = floor(now); %#ok<TNOW1>
    if nargin >= 1 && ~isempty(TrialRecord)
        TrialRecord.User.OrderDay = order_day;
    end
end

order_filename = fullfile('trial_orders', ...
    ['trial_order_' datestr(order_day, 'yyyymmdd') '.mat']); %#ok<DATST>
end
