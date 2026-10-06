function [trials_today, blocks_today, completed, segments_today] = make_trial_order(order_filename, order_day)
%make_trial_order  Build the whole day's mGLO trial order up front.
%
%Translated from the oGLO/omission version (pristine copy in
%stuff_hamed_gaveme\) to mGLO's 26 conditions. Same three-part design:
%this function builds the schedule, mglo_condition_selector serves it, and
%mglo_block_selector ends the session.
%
%   make_trial_order                       % today's file, see mglo_order_file
%   make_trial_order(order_filename, order_day)
%   [trials_today, blocks_today, completed, segments_today] = make_trial_order(...)
%
%Writes order_filename and returns what it saved. segments_today labels
%every slot with the habituation run or packet it belongs to, so the
%condition selector can keep error retries inside one segment.

if nargin < 2 || isempty(order_filename) || isempty(order_day)
    [order_filename, order_day] = mglo_order_file();
end

%get a unique rand seed for each recording day (which will also be
%consistent if rerun on the same day if things crashed)
today_seed = order_day;
rng(today_seed);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STRUCTURE -- change these, not the code below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eight virtual blocks. Blocks 1-4 are multisensory/omission and run 100
% trials; blocks 5-8 are unimodal and run 66. Every block runs twice a
% session, so 2*(4*100 + 4*66) = 1328 correct trials.
BLOCK_TRIALS = [100 100 100 100 66 66 66 66];

% Habituation is INSIDE the block, not extra trials on top: the first
% HAB_TRIALS of each block are standards with certainty, and the deviants
% are packed into what is left. The RATIO below is the whole-block split, so
% e.g. block 1 is 20 forced standards + 80 trials split 50/10/10/10, which
% comes out at the 70/10/10/10 required over the block.
HAB_TRIALS = [20 20 20 20 10 10 10 10];

% Whole-block split per block. Blocks 1-4: standard, auditory, visual, dual.
% Blocks 5-8: standard, deviant, omission. Rounding slack goes to the
% standard, so blocks 5-8 land on 46/10/10 out of 66.
RATIO = { [70 10 10 10], [70 10 10 10], [70 10 10 10], [70 10 10 10], ...
          [70 15 15],    [70 15 15],    [70 15 15],    [70 15 15]    };

% PACKETS -- local balancing, carried over from the four_glo original.
%
% The trials after habituation are NOT shuffled as one lump. They are split
% into equal packets, and each packet carries an exact share of every trial
% type. Deviants therefore cannot clump into one stretch: the deviant rate is
% stable ACROSS the block, not merely correct on average over it.
%
%   blocks 1-4:  80 post-habituation trials / 5 packets = 16 per packet
%                = 10 standard + 2 auditory + 2 visual + 2 dual
%   blocks 5-8:  56 post-habituation trials / 2 packets = 28 per packet
%                = 18 standard + 5 deviant + 5 omission
%
% 66-trial blocks cannot be cut finer: 4 packets of 14 would need 2.5 of each
% deviant type. The checks below refuse any PACKETS value that does not
% divide the block exactly, rather than silently rounding.
PACKETS = [5 5 5 5 2 2 2 2];

% Trial structure is three presentations, the third being the one that can
% deviate. Per block, with A the visual gradient and X the tone:
%   1  multisensory A   AX AX AX  70% | AX AX AY 10% | AX AX BX 10% | AX AX BY 10%
%   2  multisensory B   the exact inverse of block 1 (A<->B, X<->Y)
%   3  omission A       AX AX AX  70% | AX AX AO 10% | AX AX OX 10% | AX AX OO 10%
%   4  omission B       the exact inverse of block 3, O's in the same slots
%   5  visual A         A A A     70% | A A B    15% | A A O    15%
%   6  visual B         the exact inverse of block 5
%   7  auditory X       X X X     70% | X X Y    15% | X X O    15%
%   8  auditory Y       the exact inverse of block 7
% 'O' is an omission -- that stimulus simply does not appear. mGLO.m reads
% the O's straight out of the condition's samp label, so the unimodal blocks
% are just blocks whose omitted modality is omitted on all three
% presentations (AOAOAO, OXOXOX, ...).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONDITION MAP -- the 26 conditions of mGLO_conditions_main.txt
%   row = virtual block, column = trial type in the order RATIO lists them
%
% One condition per stimulus sequence. The active version had two of each,
% -R and -L, to counterbalance which side the correct response port sat on;
% the passive task has no ports, so those pairs collapsed.
%
% Blocks 3 and 4 reuse blocks 1 and 2's standard: AX AX AX is the same
% stimulus sequence whether or not the block's deviants are omissions, and
% the block is recorded separately in blocks_today.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COND = {  1,  2,  3,  4 ;   % 1 multisensory A
          5,  6,  7,  8 ;   % 2 multisensory B
          1,  9, 10, 11 ;   % 3 omission A
          5, 12, 13, 14 ;   % 4 omission B
         15, 16, 17, [] ;   % 5 visual A
         18, 19, 20, [] ;   % 6 visual B
         21, 22, 23, [] ;   % 7 auditory X
         24, 25, 26, [] };  % 8 auditory Y

NUM_BLOCKS = size(COND,1);

completed      = [];
trials_today   = [];
blocks_today   = [];
segments_today = [];   % habituation run / packet id of every slot
seg_no         = 0;

% Block order. Blocks 1-4 run first in a random order, then blocks 5-8 in
% their own random order. The second cycle replays each half backwards, so
% (1 4 2 3 | 7 8 6 5) is followed by (3 2 4 1 | 5 6 8 7).
first_half  = randperm(4);
second_half = randperm(4) + 4;
block_order = [first_half second_half fliplr(first_half) fliplr(second_half)];

% One RNG seed per packet, unique within the day AND across days, and
% consistent if the day's order is rebuilt. The original derived the index
% as b*p, which is NOT unique -- over b=1:8, p=1:5 that yields only 24
% distinct values, so a dozen packets shared a seed and drew identical
% deviant positions. A later today_seed+365+k fixed that within a day, but
% tomorrow's packet k then reused today's packet k+1 seed, so consecutive
% days repeated the same deviant positions shifted by one packet. Scaling
% the day by 1000 gives every day its own disjoint range of seeds, well
% clear of the block-order seed (today_seed itself) and inside rng's
% 0..2^32-1 limit.
totalNumPacket = sum(PACKETS(block_order));
if totalNumPacket >= 1000
    error('make_trial_order: %d packets would overlap the next day''s seeds', totalNumPacket);
end
rng_list  = today_seed*1000 + (1:totalNumPacket);
packet_no = 0;

for b = block_order

    ntrial = BLOCK_TRIALS(b);
    nhab   = HAB_TRIALS(b);
    ratio  = RATIO{b};

    % counts per type over the whole block; rounding slack to the standard
    type_counts = round(ratio / sum(ratio) * ntrial);
    type_counts(1) = type_counts(1) + (ntrial - sum(type_counts));

    % the habituation trials come out of the standard's allowance
    if type_counts(1) < nhab
        error('block %d: habituation (%d) exceeds its standards (%d)', ...
            b, nhab, type_counts(1));
    end
    type_counts(1) = type_counts(1) - nhab;

    % the packets must divide the remainder, and every type within it
    npack      = PACKETS(b);
    per_packet = type_counts / npack;
    if 0 ~= mod(ntrial - nhab, npack)
        error('block %d: %d packets do not divide its %d post-habituation trials', ...
            b, npack, ntrial - nhab);
    end
    if any(per_packet ~= round(per_packet))
        error('block %d: %d packets do not divide its type counts [%s]', ...
            b, npack, num2str(type_counts));
    end

    % ---- habituation: standards only ---------------------------------
    hab = repmat(COND{b,1},1,nhab);
    seg_no = seg_no + 1;
    segs = repmat(seg_no,1,nhab);

    % ---- packets: each carries an exact share of every type ----------
    mixed = [];
    for p = 1:npack
        packet_no = packet_no + 1;
        rng(rng_list(packet_no));
        packet = [];
        for t = 1:numel(type_counts)
            if isempty(COND{b,t}), continue, end
            packet = [packet repmat(COND{b,t},1,per_packet(t))]; %#ok<AGROW>
        end
        mixed = [mixed packet(randperm(numel(packet)))]; %#ok<AGROW>
        seg_no = seg_no + 1;
        segs = [segs repmat(seg_no,1,numel(packet))]; %#ok<AGROW>
    end

    trials_today   = [trials_today hab mixed];       %#ok<AGROW>
    blocks_today   = [blocks_today repmat(b,1,ntrial)]; %#ok<AGROW>
    segments_today = [segments_today segs];         %#ok<AGROW>

end

totalNumTrial = numel(trials_today);

if numel(segments_today) ~= totalNumTrial
    error('make_trial_order: segment labels (%d) do not cover the %d trials', ...
        numel(segments_today), totalNumTrial);
end

order_dir = fileparts(order_filename);
if ~isempty(order_dir) && ~isfolder(order_dir), mkdir(order_dir); end
save(order_filename,'blocks_today','trials_today','completed','totalNumTrial','segments_today');
disp(append('new trial order made (mglo) - ',num2str(totalNumTrial),' trials'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Report what was actually built, so a changed RATIO can be checked at a
% glance. Percentages are of the whole block, habituation included, which is
% the split RATIO asks for.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BLOCK_NAMES = {'multisensory A','multisensory B','omission A','omission B', ...
               'visual A','visual B','auditory X','auditory Y'};
TYPE_NAMES  = {'standard','type 2','type 3','type 4'};
fprintf('  block order: %s\n', mat2str(block_order));
for b = 1:NUM_BLOCKS
    sel = blocks_today == b;
    n_b = sum(sel);
    fprintf('  %-15s %4d trials :', BLOCK_NAMES{b}, n_b);
    for t = 1:size(COND,2)
        if isempty(COND{b,t}), continue, end
        n = sum(ismember(trials_today(sel),COND{b,t}));
        fprintf('  %s %d (%.0f%%)', TYPE_NAMES{t}, n, 100*n/n_b);
    end
    fprintf('\n');
end
fprintf('  %d trials total, %d packets\n', totalNumTrial, totalNumPacket);

% Packet composition, so a changed PACKETS can be checked at a glance. Walks
% the schedule the same way it was built and re-counts each packet in place.
fprintf('  packet composition (post-habituation, per block appearance):\n');
shown = false(1,NUM_BLOCKS);
pos = 1;
for b = block_order
    ntrial = BLOCK_TRIALS(b); nhab = HAB_TRIALS(b); npack = PACKETS(b);
    psize  = (ntrial - nhab) / npack;
    if ~shown(b)
        fprintf('    %-15s %d packets x %d trials :', BLOCK_NAMES{b}, npack, psize);
        for t = 1:size(COND,2)
            if isempty(COND{b,t}), continue, end
            first = pos + nhab;
            n = sum(ismember(trials_today(first:first+psize-1),COND{b,t}));
            fprintf('  %s %d', TYPE_NAMES{t}, n);
        end
        fprintf('\n');
        shown(b) = true;
    end
    pos = pos + ntrial;
end

% %
% figure;plot(trials_today);ylim([0,27])
% ylabel('condition')
% xlabel('numTrl')
