[ALLEEG, EEG2, CURRENTSET, ALLCOM] = eeglab;
folderPaths = {'/Users/aydanyagublu/Thesis/Aydan/heartbeatsAdded/good', '/Users/aydanyagublu/Thesis/Aydan/heartbeatsAdded/shift'};

group1Self = {};
group1NSelf = {};
group2Self = {};
group2NSelf = {};

for folderIndex = 1:length(folderPaths)
    folderPath = folderPaths{folderIndex};
    
    files = dir(fullfile(folderPath, '*.set'));

for fileIndex = 1:length(files)
    fileName = files(fileIndex).name;
    filePath = fullfile(folderPath, fileName);
    
    if contains(fileName, 'g1')
        group = 1;
    elseif contains(fileName, 'g2')
        group = 2;
    else
        continue;
    end
    
    EEG2 = pop_loadset('filename', fileName, 'filepath', folderPath);
    
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

    selfRelatedTrials = [];
    nonSelfRelatedTrials = [];
    neither = [];

    for trialIndex = 1:size(EEG_peak.epoch, 2)
        eventSelfArray = EEG2.event(hbEventIndices(trialIndex)).self;
        if isempty(eventSelfArray) || eventSelfArray == 55
            current_latency = EEG2.event(hbEventIndices(trialIndex)).latency;
            for j = trialIndex-1:-1:1
                if EEG2.event(hbEventIndices(j)).latency < current_latency - 7681
                    break;
                end
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
    fprintf('Number of Non-Self-Focused Trials: %d\n', numel(nonSelfRelatedTrials));
    fprintf('Number of Other Trials: %d\n', numel(neither));

    for i = 1:length(EEG_peak.event)
        if any(EEG_peak.event(i).self >= 56 & EEG_peak.event(i).self <= 59)
            EEG_peak.event(i).self = 1;  
        elseif any(EEG_peak.event(i).self >= 51 & EEG_peak.event(i).self <= 54)
            EEG_peak.event(i).self = 2;  
        elseif any(EEG_peak.event(i).self == 55)
            EEG_peak.event(i).self = 3;  
        elseif isempty(EEG_peak.event(i).self)
            EEG_peak.event(i).self = 5;
        end
    end

    ft_data = eeglab2fieldtrip(EEG_peak, 'raw');
    % self_values =  cell2mat(ft_data.trialinfo.self);

    cfg = [];
    cfg.trials = ft_data.trialinfo.self == 1;
    dataSelf = ft_redefinetrial(cfg, ft_data);

    cfg = [];
    cfg.trials = ft_data.trialinfo.self == 2;
    dataNonSelf = ft_redefinetrial(cfg, ft_data);
 
    cfg = [];
    cfg.output = 'pow'; 
    cfg.taper = 'hanning'; 
    cfg.foi = 1:30;
    cfg.channel = {'Pz', 'Cz', 'Fz', 'Fp1', 'Fp2', 'F3', 'F4', 'F7', 'F8','AF3', 'AF4', 'FC1', 'FC2', 'FC5', 'FC6', 'P3', 'P4'};
    cfg.keeptrials = 'yes'; 
    cfg.trials = 'all'; 
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.t_ftimwin = linspace(0.05, 0.2, numel(cfg.foi)); 
    cfg.pad    = 4;
    cfg.toi          = 0.18:0.01:0.35;    
    % cfg.toi          = 0:0.01:0.18;    
    % cfg.toi          = 0.35:0.01:0.6;   

    cfg.keeptrials = 'yes';
    timelockSelf    = ft_freqanalysis(cfg, dataSelf);
    timelockNSelf    = ft_freqanalysis(cfg, dataNonSelf);
    
     timelockSelf.fileName = fileName;
     timelockNSelf.fileName = fileName;

   if group == 1
        group1Self{end+1} = timelockSelf;
        group1NSelf{end+1} = timelockNSelf;
    elseif group == 2
        group2Self{end+1} = timelockSelf;
        group2NSelf{end+1} = timelockNSelf;
    end
end
end

save('/Users/aydanyagublu/All Code/datapowerG1180350.mat', 'group1Self', 'group1NSelf');
save('/Users/aydanyagublu/All Code/datapowerG2180350.mat', 'group2Self', 'group2NSelf');


eeglab redaw;
