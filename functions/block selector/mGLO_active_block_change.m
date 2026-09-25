function output_block = mGLO_active_block_change(TrialRecord)

    B = TrialRecord.BlocksSelected;
    Bc = TrialRecord.CurrentBlock;
    % Btally = TrialRecord.User.BlockTally;
    % Bi = find(B == Bc);
    
    if Bc == 1

        output_block = 8;

    elseif Bc == 2

        output_block = 5;

    elseif Bc == 3

        output_block = 4;

    elseif Bc == 4

        output_block = 1;

    elseif Bc == 5

        output_block = 3;

    elseif Bc == 6

        output_block = 7;

    elseif Bc == 7

        output_block = 2;

    elseif Bc == 8

        output_block = 6;

    else

        output_block = B(1);

    end

    if ~sum(ismember(B, output_block))

        output_block = B(randi(length(B)));

    end

end