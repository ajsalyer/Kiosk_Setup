function M = mgloCondMap()
%mgloCondMap  Single source of truth for mGLO condition metadata.
%
%   M = mgloCondMap() describes the 26 conditions of
%   mGLO_conditions_main.txt (used by mGLO.m in ACTIVE and passive mode).
%
%   samp labels are 6-char 'VAVAVA': one [visual audio] letter pair per
%   presentation, three presentations, the third able to deviate. 'O' in
%   either slot is an omission (counts as a deviation in that modality).
%
%   Fields:
%     NCOND        26
%     SAMP         1x26 cell of samp labels, in condition-number order
%     TYPE_NAMES   {'Non-oddball','Auditory','Visual','Dual modality'}
%     CTX_NAMES    {'A / X ctx','B / Y ctx'}
%     BLOCK_NAMES  1x8 virtual-block names (see make_trial_order.m)
%     COND         2x4 cell: COND{ctx,type} = condition numbers
%     TYPE_OF      1x26 deviance type index per condition
%     CTX_OF       1x26 context index per condition
%     BLOCK_CONDS  1x8 cell: conditions appearing in each virtual block
%                  (standards 1 and 5 are shared across blocks)
%
%   See also mgloTypeFromLabel for label-based typing that works on any
%   condition file without hardcoded numbers.

M.NCOND = 26;
M.SAMP = {'AXAXAX','AXAXAY','AXAXBX','AXAXBY', ...
          'BYBYBY','BYBYBX','BYBYAY','BYBYAX', ...
          'AXAXAO','AXAXOX','AXAXOO','BYBYBO', ...
          'BYBYOY','BYBYOO','AOAOAO','AOAOBO', ...
          'AOAOOO','BOBOBO','BOBOAO','BOBOOO', ...
          'OXOXOX','OXOXOY','OXOXOO','OYOYOY', ...
          'OYOYOX','OYOYOO'};

M.TYPE_NAMES = {'Non-oddball','Auditory','Visual','Dual modality'};
M.CTX_NAMES  = {'A / X ctx','B / Y ctx'};
M.BLOCK_NAMES = {'multisensory A','multisensory B','omission A','omission B', ...
                 'visual A','visual B','auditory X','auditory Y'};

% condition -> type / context. Type is which modality deviates on the third
% presentation, counting an omission as a deviation in that modality:
%   AXAXAO and OXOXOO are auditory, AXAXOX and AOAOOO are visual,
%   AXAXBY and AXAXOO are dual.
M.COND = { [1 15 21], [2 9 22 23],  [3 10 16 17], [4 11] ; ...
           [5 18 24], [6 12 25 26], [7 13 19 20], [8 14] };

nTYPE = size(M.COND,2);
M.TYPE_OF = zeros(1,M.NCOND);
M.CTX_OF  = zeros(1,M.NCOND);
for cc = 1:2
    for tt = 1:nTYPE
        M.TYPE_OF(M.COND{cc,tt}) = tt;
        M.CTX_OF(M.COND{cc,tt})  = cc;
    end
end

% virtual block -> conditions (row = block, from make_trial_order.m COND).
% Standards 1 and 5 are shared: 1 serves blocks 1 and 3, 5 serves 2 and 4.
M.BLOCK_CONDS = {[1 2 3 4],[5 6 7 8],[1 9 10 11],[5 12 13 14], ...
                 [15 16 17],[18 19 20],[21 22 23],[24 25 26]};
end
