% this is the code for creating a csv file with the HEP amplitudes for each participant that will later
% be used for the LME models in R

[ALLEEG, EEG2, CURRENTSET, ALLCOM] = eeglab;

% directory = '/Volumes/Lolo/Aydan/heartbeatsAdded/good';
directory = '/Users/aydanyagublu/Thesis/Aydan/heartbeatsAdded/all';

fileList = dir(fullfile(directory, '*.set'));

% chans = 1:32;

%%
for fileIndex = 1:length(fileList)
    fileName = fileList(fileIndex).name;
    filePathy = fullfile(directory, fileName);
    
    EEG2 = pop_loadset('filename', fileName, 'filepath', directory);

    chans = [13,32,31,1,30,4,27,3,28,2,29,5,26,6,25,12, 19];
    

    thought_probe_events = find(strcmp({EEG2.event.type}, '15'));

    for i = 1:length(thought_probe_events)
        current_latency = EEG2.event(thought_probe_events(i)).latency;
        events_timeframe = find([EEG2.event.latency] >= (current_latency - 7681) & [EEG2.event.latency] < current_latency);
        if ~isempty(events_timeframe)
            self_values = [EEG2.event(events_timeframe).self];
            most_occurring_value = mode(self_values);

            type_111_events = find(strcmp({EEG2.event.type}, '111') & [EEG2.event.latency] >= (current_latency - 7681) & [EEG2.event.latency] < current_latency);
            for j = 1:length(type_111_events)
                EEG2.event(type_111_events(j)).self = most_occurring_value;
            end
        end
    end

    hbEventIndices = find(strcmp({EEG2.event.type}, '111')); 

    EEG_peak = pop_epoch(EEG2, {'111'}, [-0.1 0.6], 'newname', 'HEP', 'epochinfo', 'yes');
    % EEG_peak = pop_rmbase(EEG_peak, [-0.1, 0]);

    selfRelatedTrials = [];
    nonSelfRelatedTrials = [];
    neither = [];

    for trialIndex = 1:size(EEG_peak.epoch, 2)
        eventSelfArray = EEG2.event(hbEventIndices(trialIndex)).self;
        if isempty(eventSelfArray) || eventSelfArray == 55
            for j = trialIndex-1:-1:max(trialIndex-15,1)
                eventSelfArrayPrev = EEG2.event(hbEventIndices(j)).self;
                if ~isempty(eventSelfArrayPrev) && eventSelfArrayPrev ~= 55
                    EEG2.event(hbEventIndices(trialIndex)).self = eventSelfArrayPrev;
                    break;
                end
            end
        end

        if any(eventSelfArray >= 56 & eventSelfArray <= 59)
            selfRelatedTrials = [selfRelatedTrials, trialIndex];
        elseif any(eventSelfArray >= 51 & eventSelfArray <= 54)
            nonSelfRelatedTrials = [nonSelfRelatedTrials, trialIndex];
        elseif any(eventSelfArray == 55)
            neither = [neither, trialIndex];
        end
    end

    
    selfRelatedData = EEG_peak.data(chans, :, selfRelatedTrials);
    nonSelfRelatedData = EEG_peak.data(chans, :, nonSelfRelatedTrials);

    time_window = [180 350]; 
    % time_window = [300 500];

    [~, t_start] = min(abs(EEG_peak.times - time_window(1)));
    [~, t_end] = min(abs(EEG_peak.times - time_window(2)));

    dataMatrix = [];
    
    for i = 1:length(chans)
        selfChannelData = selfRelatedData(i, t_start:t_end, :);
        nonSelfChannelData = nonSelfRelatedData(i, t_start:t_end, :);

        selfAvgTrials = mean(selfChannelData, [1, 2]);
        nonSelfAvgTrials = mean(nonSelfChannelData, [1, 2]);

        selfAvgAmplitude = mean(selfAvgTrials, 'all');
        nonSelfAvgAmplitude = mean(nonSelfAvgTrials, 'all');

        dataMatrix = [dataMatrix, selfAvgAmplitude, nonSelfAvgAmplitude];
    end

    subjectID = repmat({fileName}, size(dataMatrix, 1), 1);
    dataMatrix = [subjectID, num2cell(dataMatrix)];

    columnHeaders = {'Subject_ID'};
    for i = 1:length(chans)
        columnHeaders = [columnHeaders, ...
            ['AAmplitude_Self_', num2str(chans(i))], ...
            ['AAmplitude_Non_Self_', num2str(chans(i))]];
    end

    dataTable = cell2table(dataMatrix, 'VariableNames', columnHeaders);
    csvFileName = 'HEPamplitude180-350.csv';
    if fileIndex == 1
        writetable(dataTable, csvFileName);
    else
        writetable(dataTable, csvFileName, 'WriteMode', 'append');
    end
end

