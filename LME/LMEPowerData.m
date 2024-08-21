% this is where i was doing everything related to brain oscillations, lines 19 to 76 are for getting the
% average and plotting them, but the rest of the code is for getting the power frequency for each
% participant, for select bands and electrodes and creating a csv to be used later in R

cfg = [];
cfg.channel = 'all';
cfg.latency = 'all';
cfg.parameter = 'avg';


combinedSelf = {group1Self{:}, group2Self{:}};
combinedNonSelf = {group1NSelf{:}, group2NSelf{:}};

avgSelf = ft_timelockgrandaverage(cfg, combinedSelf{:});
avgNSelf = ft_timelockgrandaverage(cfg, combinedNonSelf{:});

%%
cfg = [];
cfg.method = 'mtmfft'; 
cfg.output = 'pow'; 
cfg.taper = 'hanning'; 
cfg.foi = 1:30;
cfg.channel = {'Pz', 'Cz', 'Fz', 'Fp1', 'Fp2', 'F3', 'F4', 'F7', 'F8','AF3', 'AF4', 'FC1', 'FC2', 'FC5', 'FC6'};
cfg.keeptrials = 'yes'; 
cfg.trials = 'all'; 
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
% cfg.t_ftimwin    = 7./cfg.foi; % random
% cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5; % from FT tutorial https://www.fieldtriptoolbox.org/workshop/madrid2019/tutorial_freq/
% cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.4;  % from other ft tutorial https://www.fieldtriptoolbox.org/workshop/paris2019/handson_sensoranalysis/


cfg.t_ftimwin = linspace(0.05, 0.2, numel(cfg.foi)); 
% cfg.t_ftimwin = linspace(0.1, 0.5, numel(cfg.foi)); % longer time window


% cfg.foi    = 2.5:2.5:30;
% cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.4;

cfg.pad    = 4;

% cfg.toi    = (-0.1:0.05:0.6);
cfg.toi          = 0.18:0.01:0.40;    


freqSelf = ft_freqanalysis(cfg, avgSelf);
freqNSelf = ft_freqanalysis(cfg, avgNSelf);


%%
cfg = [];
cfg.baselinetype = 'absolute';
cfg.maskstyle    = 'saturation';
cfg.channel      = 'AF4';
cfg.ylim = [8 12];
cfg.layout = 'biosemi64.lay'; 


figure;

subplot(2,1,1);
cfg.figure = 'gcf';
ft_singleplotTFR(cfg, freqSelf); 
title('Self-focused trials');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

subplot(2,1,2);
cfg.figure = 'gcf';
ft_singleplotTFR(cfg, freqNSelf); 
title('Non-self focused trials');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

%%
cfg = [];
cfg.method = 'mtmfft'; 
cfg.output = 'pow'; 
cfg.taper = 'hanning'; 
cfg.foi = 1:30;
cfg.channel = {'Pz', 'Cz', 'Fz', 'Fp1', 'Fp2', 'F3', 'F4', 'F7', 'F8','AF3', 'AF4', 'FC1', 'FC2', 'FC5', 'FC6'};
cfg.keeptrials = 'yes'; 
cfg.trials = 'all'; 
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.t_ftimwin = linspace(0.05, 0.2, numel(cfg.foi)); 
cfg.pad    = 4;
% cfg.toi          = 0.18:0.01:0.35;    
% cfg.toi          = 0:0.01:0.18;    
cfg.toi          = 0.35:0.01:0.6;   

freqSelf = cell(size(combinedSelf));
freqNSelf = cell(size(combinedNonSelf));

for trial_idx = 1:numel(group1Self)
    freqSelf{trial_idx} = ft_freqanalysis(cfg, group1Self{trial_idx});
end

% for trial_idx = 1:numel(combinedNonSelf)
%     freqNSelf{trial_idx} = ft_freqanalysis(cfg, combinedNonSelf{trial_idx});
% end


%%
frequency_bands = [4 7; 8 12; 13 30];
chans = {'Pz', 'Cz', 'Fz', 'Fp1', 'Fp2', 'F3', 'F4', 'F7', 'F8','AF3', 'AF4', 'FC1', 'FC2', 'FC5', 'FC6'};
dataMatrix = {};

participant_ids = 1:102;

for participant_idx = 1:length(participant_ids)
    participant_id = participant_ids(participant_idx);
    
    self_trials = freqSelf{participant_idx};
    nself_trials = freqNSelf{participant_idx};
    
    row_data = {participant_id};
    
    for band_idx = 1:size(frequency_bands, 1)
        band_range = frequency_bands(band_idx,:);
        for chan_idx = 1:length(chans)
            channel = chans{chan_idx};
            channel_idx_self = strcmp(self_trials.label, channel);
            channel_idx_nself = strcmp(nself_trials.label, channel);
            
            band_idx_self = self_trials.freq >= band_range(1) & self_trials.freq <= band_range(2);
            self_power = mean(mean(self_trials.powspctrm(:,channel_idx_self,band_idx_self), 3), 1);
            
            band_idx_nself = nself_trials.freq >= band_range(1) & nself_trials.freq <= band_range(2);
            nself_power = mean(mean(nself_trials.powspctrm(:,channel_idx_nself,band_idx_nself), 3), 1);
            
            row_data{end+1} = self_power;
            row_data{end+1} = nself_power;
        end
    end
    
    dataMatrix(end+1, :) = row_data;
end

columnHeaders = {'Participant'};
for band_idx = 1:size(frequency_bands, 1)
    band_range = frequency_bands(band_idx,:);
    for chan_idx = 1:length(chans)
        channel = chans{chan_idx};
        columnHeaders{end+1} = ['self_avg_power_', num2str(band_range(1)), '_', num2str(band_range(2)), '_', channel];
        columnHeaders{end+1} = ['nself_avg_power_', num2str(band_range(1)), '_', num2str(band_range(2)), '_', channel];
    end
end

dataTable = cell2table(dataMatrix, 'VariableNames', columnHeaders);
csvFileName = 'powerLME350600.csv';
writetable(dataTable, csvFileName);


