function [qrspeaks_new, locs_new] = detectHeartbeat(EEG)
    % Default ECG channel indices
    ECG = EEG.data(39,:) - EEG.data(40,:);
    ECG = pop_select( EEG, 'channel',{'EXG8','EXG7'});% ECG channel
    
    ECG = pop_reref(ECG, [2]);
    ECG.data = ECG.data - mean(ECG.data);
    ECG_filtered = pop_eegfiltnew(ECG, 'locutoff',0.5,'hicutoff',30,'plotfreqz',0);


    ecgsig = double(ECG_filtered.data)';
    % ecgsig = -ecgsig;

    wt = modwt(ecgsig, 5);
    wtrec = zeros(size(wt));
    wtrec(4:5, :) = wt(4:5, :);
    y = imodwt(wtrec, 'sym4');
    y2 = abs(y).^2;
    t =  50400;
    tn = 20400;
    

    [qrspeaks,locs] = findpeaks(y,ECG.times, 'MinPeakHeight',120, 'MinPeakDistance',600);    
    peak_latency_0 = find(ismember(ECG.times,locs));
    peak_latency = zeros(1,length(peak_latency_0));
    for lat_i = 1:length(peak_latency_0)
        if  ecgsig(peak_latency_0(lat_i)) > ecgsig(peak_latency_0(lat_i)+1)
          peak_latency(lat_i) = peak_latency_0(lat_i);
        elseif ecgsig(peak_latency_0(lat_i)) < ecgsig(peak_latency_0(lat_i)+1)
          peak_latency(lat_i) = peak_latency_0(lat_i) + 1;
        end
    end
    locs_new = ECG.times(peak_latency);
    qrspeaks_new = ecgsig(peak_latency);

    
     %% Test the peak detection for a short ECG signal
%     
% % %     t =1430000;
    ann_times = find(ECG.times>=t&ECG.times<=t+tn);
%     ann = find(locs>=t&locs<=t+tn);
    ann = find(locs_new>=t&locs_new<=t+tn);
%     peak_latency_ann = find(ismember(ECG.times(ann_times),locs(ann)));
    peak_latency_ann = find(ismember(ECG.times(ann_times),locs_new(ann)));
    figure
    subplot(2,1,1)
    plot(ECG.times(ann_times),y2(ann_times),'b')
    hold on
%     plot(locs(ann),qrspeaks(ann),'ro')
    plot(locs_new(ann),qrspeaks_new(ann),'ro')
    
    % hold on
    % xlabel('Seconds')
    title('R Peaks Localized by Wavelet Transform with Automatic Annotations')
    subplot(2,1,2)
    plot(ECG.times(ann_times),ecgsig(ann_times),'k')
    hold on
%     plot(locs(ann),ecgsig(ann_times(peak_latency_ann)),'ro')
    plot(locs_new(ann),ecgsig(ann_times(peak_latency_ann)),'ro')

%         %% Find inconsistencies with HEPLAB.
%     ecg = ECG.data;
%     srate = ECG.srate;
% %     save('ECG.mat','ecg','srate');
% %   HEPlab  
%     self_detection = find(ismember(ECG.times,locs_new));
%     qrs = heplab_fastdetect(ecg,srate);
% %     setdiff(self_detection,qrs);
% 
%     t = 164000;
%     tn = 50000;
%     ann_times = find(ECG.times>=t&ECG.times<=t+tn);
%     ann = find(ECG.times(qrs)>=t&ECG.times(qrs)<=t+tn);
%     peak_latency_ann = ECG.times(qrs(ann));
%     amp_heplab_ann = ecgsig(qrs(ann));
% % Find self-written
%     ann2 = find(locs_new>=t&locs_new<=t+tn);
%     ann_times2 = find(ECG.times>=t&ECG.times<=t+tn);
%     peak_latency_ann2 = locs_new(ann2);
%     idx_latency_ann2 = find(ismember(ECG.times(ann_times2),locs_new(ann2)));
%     amp_self_ann = ecgsig(ann_times2(idx_latency_ann2));
% % Plot comparisons
%     figure
%     subplot(2,1,1)
%     plot(ECG.times,ecgsig,'k--')
%     hold on
% %     plot(ECG.times(qrs),ecgsig(qrs),'ro','MarkerSize',3);
% %     hold on;
%     plot(locs_new,ecgsig(find(ismember(ECG.times,locs_new))),'go','MarkerSize',8);    
%     xlabel('Seconds')
%     subplot(2,1,2)
%     plot(ECG.times(ann_times),ecgsig(ann_times),'k')
%     hold on
% %     plot(peak_latency_ann,amp_heplab_ann,'ro','MarkerSize',5)
% %     hold on
%     plot(peak_latency_ann2,amp_self_ann,'go','MarkerSize',8)
% %         legend('Raw Data ', 'HEPlab','Wavelet decomposition',...
%         legend('Raw Data ', 'HEPlab',...
%         'Location','SouthEast');
%     title(['Participant ' num2str(i)])
% %     set(gcf,'units','points','position',[10,810,1400,300])