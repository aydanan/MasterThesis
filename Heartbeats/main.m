% this is the code for finding the heartbeat events, labeling them and then 
% adding them to the pre-processed data

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
file = 'SART_13_g1_m2';
fileName = strcat(file, '.bdf');
filePath = '/Volumes/Lolo/Aydan/SART';
EEG = pop_biosig(fullfile(filePath, fileName));

[EEG] = CutContu_biosemi(EEG,91,199);
%%

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);

%%
[qrspeaks_new, locs_new ] = detectHeartbeat(EEG);
%% 

latencies = (locs_new / 1000) * EEG.srate + 1;
latencies = round(latencies);

% pop_eegplot(EEG, 1, 1, 0);

fileName = strcat(file, '.mat');
filePath = '/Volumes/Lolo/Aydan/prepro';
filePath2 = '/Volumes/Lolo/Aydan/heartbeatsAdded'; 

EEG2 = pop_loadset('filename', fileName, 'filepath', filePath);

[EEG] = addHeartbeat(EEG, latencies);
[EEG2] = addHeartbeat(EEG2, latencies);


% pop_eegplot(EEG2, 1, 1, 0);
% pop_eegplot(EEG, 1, 1, 0);


filePath3 = '/Volumes/Lolo/Aydan/heartbeatsAdded/new'; 
EEG2 = pop_saveset(EEG2, 'filename', strcat(file, '.set'), 'filepath', filePath3);
% pause(10);
% close;
% eeglab redraw;

%%


chans = [11, 13, 31, 32];  % 11 =P79 ,16 = Oz, Pz, Fz, Cz

thought_probe_events = find(strcmp({EEG2.event.type}, '15'));

%%

%7681 latencies is 15 seconds

for i = 1:length(thought_probe_events)
    current_latency = EEG2.event(thought_probe_events(i)).latency;
    events_timeframe = find([EEG2.event.latency] >= (current_latency - 15000) & [EEG2.event.latency] < current_latency);
    % disp('here');
    if ~isempty(events_timeframe)
        self_values = [EEG2.event(events_timeframe).self];
        most_occurring_value = mode(self_values);
        % disp(most_occurring_value);

        % type_111_events = find(strcmp({EEG.event.type}, '111'));
        type_111_events = find(strcmp({EEG2.event.type}, '111') & [EEG2.event.latency] >= (current_latency - 15000) & [EEG2.event.latency] < current_latency);
        for j = 1:length(type_111_events)
            EEG2.event(type_111_events(j)).self = most_occurring_value;
        end
    end
end



hbEventIndices = find(strcmp({EEG2.event.type}, '111')); 

%%

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

fprintf('Number of Self-Focused Trials: %d\n', numel(selfRelatedTrials));
fprintf('Number of Non-Self-Fcused Trials: %d\n', numel(nonSelfRelatedTrials));
fprintf('Number of Other Trials: %d\n', numel(neither));

selfRelatedData = EEG_peak.data(chans, :, selfRelatedTrials);
nonSelfRelatedData = EEG_peak.data(chans, :, nonSelfRelatedTrials);
otherData = EEG_peak.data(chans, :, neither);


%%
figure('Name', ['File: ', fileName]);
for i = 1:length(chans)
    subplot(length(chans), 1, i);
    plot(EEG_peak.times, mean(selfRelatedData(i, :, :), 3), 'b', 'LineWidth', 2);
    hold on;
    plot(EEG_peak.times, mean(nonSelfRelatedData(i, :, :), 3), 'r', 'LineWidth', 2);
    % plot(EEG_peak.times, mean(otherData(i, :, :), 3), 'k', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(['Average HEP for Channel ', num2str(chans(i))]);
    legend('Self-related', 'Non-self-related');
    % ylim([-4 4]);
    grid on;
end