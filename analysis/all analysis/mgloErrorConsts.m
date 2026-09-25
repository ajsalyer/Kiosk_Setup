function C = mgloErrorConsts()
%mgloErrorConsts  Standard MonkeyLogic trial-error codes used by mGLO.
%
%   C = mgloErrorConsts() returns struct with CORRECT (0), INCORRECT (6),
%   AVOID (9, active choice timeout), NOFIX (4, never acquired), BREAK (3,
%   fixation break). Pass to mgloTrialStats and the mgloPlot* functions.

C.CORRECT   = 0;
C.INCORRECT = 6;
C.AVOID     = 9;
C.NOFIX     = 4;
C.BREAK     = 3;
end
