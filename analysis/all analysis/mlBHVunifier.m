function file = mlBHVunifier(baseFilename, bhvPath)
    % Inputs:
        % baseFilename -> the main file; e.g. 230816_Cajal_glo_omission
        % bhvPath -> the directory in which .bhv2 files are located.
    
    % Handle optional input more robustly
    if nargin < 2 || isempty(bhvPath) || strcmp(bhvPath, " ")
        bhvPath = pwd;
    end

    % IMPROVEMENT 1: Direct filtering in dir() is faster than loading all names
    % and filtering with loops/contains. fullfile handles OS path separators.
    searchPattern = fullfile(bhvPath, [baseFilename, '*.bhv2']);
    dirInfo = dir(searchPattern);
    
    if isempty(dirInfo)
        error('No .bhv2 files found matching: %s', searchPattern);
    end
    
    bhvFiles = {dirInfo.name};
    N = length(bhvFiles);
    
    % Preallocate memory
    bhx = cell(1, N);
    bhxTimex = zeros(1, N);
    
    % Load files
    for ik = 1:N
        % IMPROVEMENT 2: Ensure full path is used so mlread finds the file
        fullFilePath = fullfile(dirInfo(ik).folder, dirInfo(ik).name);
        bhx{ik} = mlread(fullFilePath);
        
        % IMPROVEMENT 3: Use datenum for sorting. The original code only summed 
        % Hour/Min/Sec, which would fail if files had different dates.
        % We check if TrialDateTime has enough elements (usually [Y M D H M S])
        if length(bhx{ik}(1).TrialDateTime) >= 6
            bhxTimex(ik) = datenum(bhx{ik}(1).TrialDateTime);
        else
            % Fallback to original logic if format differs
            t = bhx{ik}(1).TrialDateTime;
            bhxTimex(ik) = t(end-2)*3600 + t(end-1)*60 + t(end);
        end
    end
    
    % IMPROVEMENT 4: Correct Sorting. 
    % The original 'r(p)=r' logic created an inverse permutation which 
    % does not sort correctly for N > 2. Direct indexing is the standard fix.
    [~, p] = sort(bhxTimex, 'ascend');
    bhx = bhx(p);
    
    disp(">Loaded " + num2str(N) + " bhv files to merge");
    
    % IMPROVEMENT 5: Vectorized merging.
    % Instead of concatenating [bhvUni, new] inside the loop (slow O(N^2)),
    % we calculate offsets, update the cells, and concatenate once at the end.
    
    cumulativeTrials = 0;
    cumulativeTime = 0;
    
    % Loop starts from 2 because the first file needs no offset
    for ik = 2:N
        prevFile = bhx{ik-1};
        currFile = bhx{ik};
        
        % Update Accumulators
        cumulativeTrials = cumulativeTrials + length(prevFile);
        
        % Calculate time gap between end of previous and start of current
        % Using etime handles day-rollovers (midnight) correctly.
        % Multiplied by 1000 to convert seconds to ms.
        timeGap = etime(currFile(1).TrialDateTime, prevFile(end).TrialDateTime) * 1000;
        
        % Add the duration of previous file + the gap
        cumulativeTime = cumulativeTime + prevFile(end).AbsoluteTrialStartTime + timeGap;
        
        % Apply offsets to current file 
        for jk = 1:length(currFile)
            currFile(jk).AbsoluteTrialStartTime = currFile(jk).AbsoluteTrialStartTime + cumulativeTime;
            currFile(jk).Trial = currFile(jk).Trial + cumulativeTrials;
        end
        
        bhx{ik} = currFile;
    end
    
    % Concatenate all at once (Fast)
    bhvUni = [bhx{:}];
    
    % Convert to output structure (Original Logic)
    file = struct();
    field_names = fieldnames(bhvUni);
    for ik = 1:length(field_names)
        % Using [ ] allows converting struct array to vector/matrix
        file.(field_names{ik}) = [bhvUni.(field_names{ik})];
    end
    
    save(baseFilename + ".mat", "file");
end
