function bhv = mgloCalculateRT(bhv, maxRT)
%mgloCalculateRT  Reaction time from choice-onset (109) to choice (50).
%
%   bhv = mgloCalculateRT(bhv) adds bhv.ReactionTime (ms, NaN when the trial
%   had no choice: passive trials, fixation breaks, or missing codes).
%   maxRT (default 2500, the MAX_REACTION_TIME choice window) rejects
%   outliers with |RT| > maxRT as NaN.
%
%   Codes are matched by their ORDER, not just their value. mGLO.m marks
%   each trial's condition as 100+condition at trial start, which reuses
%   the scene codes' numbers (condition 9 sends 109, condition 6 sends 106),
%   and the barcode after the choice carries arbitrary values (a trial
%   number can be 50 or 109). The choice scene is the 109 sent straight
%   after the post-stimulus delay scene (106) and followed straight by the
%   outcome marker (50) -- a run that only the real scene sequence produces.
%   MonkeyLogic's own frame-skip (13) and manual-reward (14) codes can land
%   between them and are skipped over.

if nargin < 2 || isempty(maxRT), maxRT = 2500; end

SCENE_DELAY3 = 106;   % post-stimulus delay scene, directly before the choice
SCENE_CHOICE = 109;   % choice scene on
CHOICE_MADE  = 50;    % outcome marker, sent as soon as the choice resolves
ML_INTERLEAVED = [13 14];

nTrials = numel(bhv.Trial);
customRT = nan(nTrials, 1);

for i = 1:nTrials
    if isempty(bhv.BehavioralCodes(i).CodeNumbers)
        continue;
    end
    codes = bhv.BehavioralCodes(i).CodeNumbers(:);
    times = bhv.BehavioralCodes(i).CodeTimes(:);

    keep  = ~ismember(codes, ML_INTERLEAVED);
    codes = codes(keep);
    times = times(keep);

    n = numel(codes);
    k = find(codes(2:n-1) == SCENE_CHOICE & ...
             codes(1:n-2) == SCENE_DELAY3 & ...
             codes(3:n)   == CHOICE_MADE, 1) + 1;
    if ~isempty(k)
        customRT(i) = times(k+1) - times(k);
        if abs(customRT(i)) > maxRT
            customRT(i) = NaN;
        end
    end
end

bhv.ReactionTime = customRT;
fprintf('mgloCalculateRT: RTs for %d of %d trials.\n', sum(~isnan(customRT)), nTrials);
end
