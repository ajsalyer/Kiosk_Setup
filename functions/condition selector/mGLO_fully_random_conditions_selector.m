function output_condition = mGLO_fully_random_conditions_selector(TrialRecord)
    try
        C = TrialRecord.ConditionsThisBlock;
    catch
        C = 1:24; %Select all conditions if needed
    end

    standardConditions = C(ismember(C, [1, 2, 9, 10, 17, 18]));
    doubleOddballConditions = C(ismember(C, [7:8, 15:16, 23:24]));

    visualOddballConditions = C(ismember(C, [3:4, 11:12, 19:20]));
    auditoryOddballConditions = C(ismember(C, [5:6, 13:14, 21:22]));

    singleOddballConditions = C(ismember(C, [3:6, 11:14, 19:22]));

    try
        SR = TrialRecord.User.Standard_Ratio;
        DOB = TrialRecord.User.Primary_OB_Ratio;

        MODE = TrialRecord.User.MODE;
    catch
        SR = 1; DOB = 0;
        MODE = 'MULTISENSORY';
    end

    % VOB = (1 - (SR + DOB))/2;
    % AOB = VOB;

    r = rand();
    switch MODE
        case 'AUDITORY'
            if r < SR
                output_condition = standardConditions(randi(length(standardConditions)));
            else
                output_condition = auditoryOddballConditions(randi(length(auditoryOddballConditions)));
            end
        case 'VISUAL'
            if r < SR
                output_condition = standardConditions(randi(length(standardConditions)));
            else
                output_condition = visualOddballConditions(randi(length(visualOddballConditions)));
            end
        case 'MULTISENSORY'
            if r < SR
                output_condition = standardConditions(randi(length(standardConditions)));
            elseif (r < SR + DOB) && ~isempty(doubleOddballConditions)
                output_condition = doubleOddballConditions(randi(length(doubleOddballConditions)));
            elseif ~isempty(singleOddballConditions)
                output_condition = singleOddballConditions(randi(length(singleOddballConditions)));
            else
                output_condition = doubleOddballConditions(randi(length(doubleOddballConditions)));
            end
    end
end