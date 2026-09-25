function userplot(TrialRecord)
%userplot  Control-screen plot for mGLO -- picked up automatically.
%
%When the "User plot function" box in the MonkeyLogic main menu is left
%empty, MonkeyLogic falls back to a file called userplot.m in the experiment
%directory:
%   run_trial.m:11   userplotfunc = get_function_handle(MLConfig.UserPlotFunction);
%   run_trial.m:12   if isempty(userplotfunc), userplotpath = [MLPath.ExperimentDirectory 'userplot.m']; ...
%
%So this file wires up the live plot WITHOUT touching the saved rig config,
%the same way alert_function.m in the task directory overrides the stock one.
%Nothing to set in the GUI, and nothing to re-set if the config is replaced.
%
%The real work is in functions/user plot/mGLO_userplot.m. This only
%delegates, so there is one implementation rather than two copies that drift.
%
%MonkeyLogic calls this with TrialRecord alone when the function takes one
%argument (run_trial.m:308), and draws into an axes it has already selected
%-- so mGLO_userplot must keep using gca and must never call clf.
%
%To use the ACTIVE-task variant instead, change the call below to
%mGLO_active_plot(TrialRecord).

mGLO_userplot(TrialRecord);

end
