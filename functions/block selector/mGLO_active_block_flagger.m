function blockChange = mGLO_active_block_flagger(TrialRecord)

    % ML Block Change function that changes the block when the block size is
    % between a set range.
    
    if TrialRecord.User.numCorrectWithinBlock == TrialRecord.User.blockSize
    
        blockChange = 1;
        % TrialRecord.User.numCorrectWithinBlock = 0;
        TrialRecord.User.EngagedWithinBlock = 0;
    
    else
    
        blockChange = 0;
    
    end


end