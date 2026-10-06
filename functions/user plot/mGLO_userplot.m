function mGLO_userplot(TrialRecord)
%mGLO_userplot  Live control-screen plot for mGLO.
%
%Set this as the User plot function in the MonkeyLogic main menu.
%
%MonkeyLogic calls the user plot as userplotfunction(TrialRecord) after
%selecting its own single axes:
%   run_trial.m:301   set(hFig,'CurrentAxes',hTag.hUserplot);
%   run_trial.m:308   userplotfunc(TrialRecord);
%So this draws into gca and must never call clf or subplot -- that axes sits
%inside MonkeyLogic's control panel and clearing the figure wipes the layout.
%
%Shows accuracy per deviance type split by sensory context, trial counts on
%each bar, and session progress through the day's scheduled trial order.

TYPE_NAMES = {'Non-oddball','Auditory','Visual','Dual modality'};
CTX_NAMES  = {'A / X ctx','B / Y ctx'};
BLOCK_NAMES = {'multisensory A','multisensory B','omission A','omission B', ...
               'visual A','visual B','auditory X','auditory Y'};

% condition -> type / context, over the 26 conditions of
% mGLO_conditions_main.txt.
% Type is which modality deviates on the third presentation, counting an
% omission as a deviation in that modality:
%   AXAXAO and OXOXOO are auditory, AXAXOX and AOAOOO are visual,
%   AXAXBY and AXAXOO are dual. Shared with analysis/mgloCondMap.m.
try
    M = mgloCondMap();
    TYPE_NAMES = M.TYPE_NAMES;
    CTX_NAMES = M.CTX_NAMES;
    BLOCK_NAMES = M.BLOCK_NAMES;
    TYPE_OF = M.TYPE_OF;
    CTX_OF = M.CTX_OF;
    NCOND = M.NCOND;
catch
    TYPE_NAMES = {'Non-oddball','Auditory','Visual','Dual modality'};
    CTX_NAMES  = {'A / X ctx','B / Y ctx'};
    BLOCK_NAMES = {'multisensory A','multisensory B','omission A','omission B', ...
                   'visual A','visual B','auditory X','auditory Y'};
    COND = { [1 15 21], [2 9 22 23],  [3 10 16 17], [4 11] ;
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
engaged = ismember(err,[0 6]) & valid;
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

% ---- title: where we are in the day's schedule ------------------------- %
blk = '';
if isfield(TrialRecord.User,'VirtualBlock')
    vb = TrialRecord.User.VirtualBlock;
    if isscalar(vb) && vb >= 1 && vb <= 8, blk = BLOCK_NAMES{vb}; ...
    elseif isscalar(vb), blk = sprintf('block %d',vb); end
else
    blk = sprintf('ML block %d',TrialRecord.CurrentBlock); % selector not running
end
prog = '';
if isfield(TrialRecord.User,'TrialsCompleted') && isfield(TrialRecord.User,'TotalScheduled')
    done  = TrialRecord.User.TrialsCompleted;
    total = TrialRecord.User.TotalScheduled;
    prog = sprintf('  |  %d/%d scheduled (%.0f%%)',done,total,100*done/max(total,1));
end
nCorrect = sum(correct);
title(ax,{sprintf('%s%s',blk,prog), ...
    sprintf('%d trials run, %d correct (%.0f%%)',n,nCorrect,100*nCorrect/max(n,1))}, ...
    'FontSize',8);
end
