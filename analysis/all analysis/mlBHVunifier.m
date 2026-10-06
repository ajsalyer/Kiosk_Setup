function file = mlBHVunifier(baseFilename, bhvPath, saveMat)
    % Inputs:
        % baseFilename -> the main file; e.g. 230816_Cajal_glo_omission
        % bhvPath -> the directory in which .bhv2 files are located.
        % saveMat -> optional, default false. true also writes the merged
        %            struct to <bhvPath>/<baseFilename>_unified.mat. (It used
        %            to ALWAYS write <baseFilename>.mat into whatever folder
        %            MATLAB happened to be in -- the task root, usually.)
    %
    % Output: one struct, one field per bhv field, trials in time order.
    % TrialDateTime is N x 6 (one row per trial), as from mlconcatenate.

    if nargin < 3 || isempty(saveMat)
        saveMat = false;
    end
    baseFilename = char(baseFilename);
    
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
    orig = bhx;   % unshifted copies: offsets are computed from these only
    
    % Loop starts from 2 because the first file needs no offset
    for ik = 2:N
        prevFile = orig{ik-1};   % NOT bhx{ik-1}, which already carries the
        currFile = bhx{ik};      % previous offset (double-counted from file 3)
        
        % Update Accumulators
        cumulativeTrials = cumulativeTrials + length(prevFile);
        
        % Calculate time gap between the last trial of the previous file and
        % the first trial of the current one (TrialDateTime is each trial's
        % start). Using etime handles day-rollovers (midnight) correctly.
        % Multiplied by 1000 to convert seconds to ms.
        timeGap = etime(currFile(1).TrialDateTime, prevFile(end).TrialDateTime) * 1000;
        
        % Place the current file's first trial timeGap after the previous
        % file's last trial, on the merged clock:
        %   offset_k = offset_(k-1) + prevLast + gap - currFirst
        cumulativeTime = cumulativeTime + prevFile(end).AbsoluteTrialStartTime ...
                         + timeGap - currFile(1).AbsoluteTrialStartTime;
        
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
        if strcmp(field_names{ik}, 'TrialDateTime')
            % One [Y M D h m s] row per trial, like mlconcatenate. [ ] would
            % run them together into a single 1 x 6N row.
            file.TrialDateTime = vertcat(bhvUni.TrialDateTime);
        else
            % Using [ ] allows converting struct array to vector/matrix
            file.(field_names{ik}) = [bhvUni.(field_names{ik})];
        end
    end
    
    if saveMat
        save(fullfile(bhvPath, [baseFilename '_unified.mat']), 'file');
    end
end
