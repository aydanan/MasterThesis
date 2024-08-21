% after running fieldtripdata.m, i then load the saved .mat files and combine them. from there i run
% there are a lot of section in this file dedicated for plotting and looking at the data, near the bottom
% is where the clustering analysis is preformed


cfg = [];
cfg.channel = 'all';
cfg.latency = 'all';
% cfg.parameter = 'trial';

% combinedSelf = {group1Self{:}, group2Self{:}, sgroup1Self{:}, sgroup2Self{:}};
% combinedNonSelf = {group1NSelf{:}, group2NSelf{:}, sgroup1NSelf{:}, sgroup2NSelf{:}};

combinedSelf = {group1Self{:}, group2Self{:}};
combinedNonSelf = {group1NSelf{:}, group2NSelf{:}};

avgSelf = ft_timelockgrandaverage(cfg, combinedSelf{:});
avgNSelf = ft_timelockgrandaverage(cfg, combinedNonSelf{:});




%%

cfg = [];
cfg.xlim = [-0.2 1.0];
% cfg.ylim = [-10 8];
cfg.baseline = [-0.1 0];
cfg.channel = 'Pz';
cfg.fontsize = 18;
cfg.linewidth = 2;
ft_singleplotER(cfg,avgSelf,avgNSelf);
legend('Self related thoughts','Non-self related thoughts')

%%
cfg = [];
cfg.layout = 'biosemi64.lay';
cfg.channel = 'all'; 
cfg.showlabels = 'yes';
cfg.showoutline = 'yes';
cfg.xlim = [0.18 0.35];
cfg.ylim =[-1.5 3];
figure; ft_multiplotER(cfg, avgSelf, avgNSelf);
axis on

%%
% plotting all HEPs for each channel (figure for thesis)
chanids= [13,32,31,1,30,4,27,3,28,2,29,5,26,6,25,12,19];

highlight_start1 = 0.18;
highlight_end1 = 0.35;

highlight_start2 = 0.30;
highlight_end2 = 0.50;

figure;
for i = 1:numel(chanids)
    subplot(3, 6, i);
    
    erfSelf = mean(avgSelf.avg(chanids(i),:), 1);
    erfNSelf = mean(avgNSelf.avg(chanids(i),:), 1);
    
    plot(avgSelf.time, erfSelf, 'Color', '#ff4d40', 'LineWidth', 2); hold on;
    plot(avgNSelf.time, erfNSelf, 'Color', '#6b7ff2', 'LineWidth', 2); hold off;
    xlabel('Time (s)', 'FontSize', 14);
    ylabel('Amplitude (μV)', 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom','FontSize', 14);
    title(avgSelf.label{chanids(i)});
    ax = gca();
    ax.FontSize = 14;
    ax.XAxisLocation = 'bottom';
    ax.XTickLabelRotation = 45; 
    xlims = xlim;
    line(xlims, [0, 0], 'Color', 'k', 'LineStyle', '--');
    hold on;
    xregion(highlight_end1, highlight_start1, 'FaceColor', '#9babcc');
    xregion(highlight_end2, highlight_start2, 'FaceColor', '#609c84'); 


end

lgd = legend({'Self focused', 'Non-Self focused'});
lgd.FontSize = 15;
lgd.EdgeColor = 'none';
lgd.Orientation = 'horizontal';
lgd.Position = [0.45 0 0.2 0.05];


%%
% Clustering analysis 

cfg_neighb        = [];
cfg_neighb.method = 'distance';
neighbours        = ft_prepare_neighbours(cfg_neighb, avgSelf);


%%
cfg = [];
cfg.channel = 'all';
cfg.latency = [0.4 0.6];
cfg.channel = {'Pz', 'Cz', 'Fz', 'Fp1', 'Fp2', 'F3', 'F4', 'F7', 'F8','AF3', 'AF4', 'FC1', 'FC2', 'FC5', 'FC6', 'P3', 'P4'};
cfg.neighbours = neighbours;
cfg.parameter = 'avg';
cfg.method = 'montecarlo';
cfg.statistic = 'ft_statfun_depsamplesT';
cfg.alpha = 0.05;
cfg.correctm = 'cluster';
cfg.correcttail = 'prob';
cfg.numrandomization = 10000;

Nsub = 99;

cfg.design(1, 1:2*Nsub) = [ones(1, Nsub) 2*ones(1, Nsub)];
cfg.design(2, 1:2*Nsub) = [1:Nsub 1:Nsub];
cfg.ivar = 1; % the 1st row in cfg.design contains the independent variable
cfg.uvar = 2; % the 2nd row in cfg.design contains the subject number

[stat_c] = ft_timelockstatistics(cfg, combinedSelf{:}, combinedNonSelf{:});

%%

cfg = [];
cfg.style     = 'blank';
cfg.layout    = 'elec1010.lay';
cfg.highlight = 'on';
cfg.alpha = 0.05;
cfg.highlightchannel = find(stat_c.mask);
cfg.comment   = 'no';
figure; ft_topoplotER(cfg, avgSelf, avgNSelf)


