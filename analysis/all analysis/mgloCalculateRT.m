function bhv = mgloCalculateRT(bhv, maxRT)
%mgloCalculateRT  Reaction time from choice-onset (109) to choice (50).
%
%   bhv = mgloCalculateRT(bhv) adds bhv.ReactionTime (ms, NaN when the trial
%   had no choice: passive trials, fixation breaks, or missing codes).
%   maxRT (default 2500, the MAX_REACTION_TIME choice window) rejects
%   outliers with |RT| > maxRT as NaN.

if nargin < 2 || isempty(maxRT), maxRT = 2500; end

nTrials = numel(bhv.Trial);
customRT = nan(nTrials, 1);

for i = 1:nTrials
    if isempty(bhv.BehavioralCodes(i).CodeNumbers)
        continue;
    end
    codes = bhv.BehavioralCodes(i).CodeNumbers;
    times = bhv.BehavioralCodes(i).CodeTimes;

    idxChoice = find(codes == 109, 1); % choice scene on
    idxMade   = find(codes == 50, 1);  % choice registered
    if ~isempty(idxChoice) && ~isempty(idxMade)
        customRT(i) = times(idxMade) - times(idxChoice);
        if abs(customRT(i)) > maxRT
            customRT(i) = NaN;
        end
    end
end

bhv.ReactionTime = customRT;
fprintf('mgloCalculateRT: RTs for %d of %d trials.\n', sum(~isnan(customRT)), nTrials);
end
