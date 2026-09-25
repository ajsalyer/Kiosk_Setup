function mGLO_active_plot(TrialRecord)
%mGLO_active_plot  Live control-screen plot for ACTIVE mGLO.
%
%Set this as the User plot function in the MonkeyLogic main menu when
%running with ACTIVE on (use mGLO_userplot for passive fixation sessions).
%
%MonkeyLogic calls the user plot as userplotfunction(TrialRecord) after
%selecting its own single axes, so this draws into gca and must never call
%clf, subplot or figure -- that axes sits inside MonkeyLogic's control
%panel and clearing the figure wipes the layout.
%
%Shows the minimal complete live view: accuracy per deviance type split by
%sensory context (26 conditions -> 4 types x 2 ctx via mgloCondMap, same
%grouping as the offline analysis), engaged-trial counts on each bar,
%overall Perf/Sens in the title, and session progress through the day's
%scheduled trial order. Harmless in passive sessions (no error-6 trials, so
%it shows fixation-completion counts).

try
    M = mgloCondMap();
    TYPE_NAMES = M.TYPE_NAMES;
    CTX_NAMES = M.CTX_NAMES;
    BLOCK_NAMES = M.BLOCK_NAMES;
    TYPE_OF = M.TYPE_OF;
    CTX_OF = M.CTX_OF;
    NCOND = M.NCOND;
catch
    % Rig fallback when analysis/ is not on the path: same 26-condition map.
    TYPE_NAMES = {'Non-oddball','Auditory','Visual','Dual modality'};
    CTX_NAMES  = {'A / X ctx','B / Y ctx'};
    BLOCK_NAMES = {'multisensory A','multisensory B','omission A','omission B', ...
                   'visual A','visual B','auditory X','auditory Y'};
    COND = { [1 15 21], [2 9 22 23],  [3 10 16 17], [4 11] ; ...
             [5 18 24], [6 12 25 26], [7 13 19 20], [8 14] };
    NCOND = 26;
    TYPE_OF = zeros(1,NCOND); CTX_OF = zeros(1,NCOND);
    for cc = 1:2
        for tt = 1:size(COND,2)
            TYPE_OF(COND{cc,tt}) = tt;
            CTX_OF(COND{cc,tt})  = cc;
        end
    end
end
nTYPE = numel(TYPE_NAMES);

ax = gca;
cla(ax);

cond = TrialRecord.ConditionsPlayed(:)';
err  = TrialRecord.TrialErrors(:)';
n    = min(numel(cond),numel(err));
if 0 == n
    text(0.5,0.5,'waiting for first trial','Parent',ax, ...
        'HorizontalAlignment','center','Units','normalized');
    axis(ax,'off');
    return
end
cond = cond(1:n); err = err(1:n);

valid   = cond >= 1 & cond <= NCOND;
engaged = ismember(err,[0 6]) & valid; % correct + incorrect choices only
correct = err == 0 & valid;

type = zeros(1,numel(cond)); ctx = zeros(1,numel(cond));
type(valid) = TYPE_OF(cond(valid));
ctx(valid)  = CTX_OF(cond(valid));

acc = nan(nTYPE,2); cnt = zeros(nTYPE,2);
for t = 1:nTYPE
    for c = 1:2
        sel = engaged & type == t & ctx == c;
        cnt(t,c) = sum(sel);
        if 0 < cnt(t,c), acc(t,c) = 100*sum(correct & sel)/cnt(t,c); end
    end
end

nCorr = sum(correct);
nEng  = sum(engaged);
if 0 < nEng
    perfOverall = 100*nCorr/nEng;
    sensOverall = 100*(nCorr - (nEng-nCorr))/nEng;
else
    perfOverall = 0;
    sensOverall = 0;
end
TrialRecord.User.SensIndex = sensOverall/100;

plotAcc = acc; plotAcc(isnan(plotAcc)) = 0;
hb = bar(ax,plotAcc,'grouped');
if 2 == numel(hb)
    set(hb(1),'FaceColor',[0.30 0.45 0.75]);
    set(hb(2),'FaceColor',[0.85 0.55 0.20]);
end
set(ax,'XTick',1:nTYPE,'XTickLabel',TYPE_NAMES,'FontSize',7);
ylim(ax,[0 105]); ylabel(ax,'% correct');
legend(ax,CTX_NAMES,'Location','southeast','FontSize',7);

hold(ax,'on');
for t = 1:nTYPE
    for c = 1:2
        if 0 < cnt(t,c)
            text(t+(c-1.5)*0.29,plotAcc(t,c)+3,sprintf('%d',cnt(t,c)),'Parent',ax, ...
                'HorizontalAlignment','center','FontSize',7);
        end
    end
end
hold(ax,'off');

% ---- title: performance, choice count, schedule progress --------------- %
blk = '';
if isfield(TrialRecord.User,'VirtualBlock')
    vb = TrialRecord.User.VirtualBlock;
    if isscalar(vb) && vb >= 1 && vb <= 8, blk = BLOCK_NAMES{vb}; ...
    elseif isscalar(vb), blk = sprintf('block %d',vb); end
end
prog = '';
if isfield(TrialRecord.User,'TrialsCompleted') && isfield(TrialRecord.User,'TotalScheduled')
    done  = TrialRecord.User.TrialsCompleted;
    total = TrialRecord.User.TotalScheduled;
    prog = sprintf('  |  %d/%d scheduled (%.0f%%)',done,total,100*done/max(total,1));
end
nChoice = nEng;
if isfield(TrialRecord.User,'ChoiceLog')
    cl = TrialRecord.User.ChoiceLog(:)';
    nChoice = sum(engaged & cl(1:n) == 2);
end
title(ax,{sprintf('%s%s',blk,prog), ...
    sprintf('Perf %.0f%% | Sens %.0f | %d choice trials (%d correct)', ...
    perfOverall, sensOverall, nChoice, nCorr)}, 'FontSize',8);
end
