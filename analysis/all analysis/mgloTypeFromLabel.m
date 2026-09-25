function [typeIdx, ctxIdx] = mgloTypeFromLabel(label)
%mgloTypeFromLabel  Type a trial from its 6-char 'VAVAVA' samp label.
%
%   [typeIdx, ctxIdx] = mgloTypeFromLabel(label) with label like 'AXAXBY':
%   pair 1 = presentations 1-2 context, pair 3 = presentation 3 (deviant slot).
%   An 'O' in either slot counts as a deviation in that modality.
%
%   typeIdx: 1 non-oddball, 2 auditory, 3 visual, 4 dual modality
%   ctxIdx:  1 A/X context (first visual is A), 2 B/Y context (first is B)
%
%   Label-derived typing agrees with mgloCondMap's COND table on all 26
%   conditions, but needs no hardcoded numbers, so it keeps working if a
%   future conditions file adds or renumbers sequences.

s = char(label);
if numel(s) < 6
    error('mgloTypeFromLabel:expected6char', 'Expected 6-char VAVAVA label, got "%s".', s);
end

visSame = s(1) == s(5);
audSame = s(2) == s(6);

if visSame && audSame
    typeIdx = 1;        % non-oddball
elseif ~visSame && audSame
    typeIdx = 3;        % visual deviant
elseif visSame && ~audSame
    typeIdx = 2;        % auditory deviant
else
    typeIdx = 4;        % dual deviant
end

if s(1) == 'A'
    ctxIdx = 1;
elseif s(1) == 'B'
    ctxIdx = 2;
else
    % O-first unimodal-auditory sequences (OX/OY...): context follows audio.
    if s(2) == 'X'
        ctxIdx = 1;
    else
        ctxIdx = 2;
    end
end
end
