function [EEG] = addHeartbeat(EEG, locs_new)
    
    k = length(EEG.event);
    urevents = num2cell(k+1:k+length(locs_new));
    evt = num2cell(locs_new);
    types = repmat({111}, 1, length(evt));
    
    for i = 1:length(locs_new)
        EEG.event(k + i).latency = ceil(locs_new(i));
        EEG.event(k + i).type = '111';
        EEG.event(k + i).urevent = k + i;
    end
    
    [~, idx] = sort([EEG.event.latency]);
    EEG.event = EEG.event(idx);
    
end
