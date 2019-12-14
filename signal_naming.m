top_inports = find_system(gcs,'SearchDepth',1,'BlockType','Inport');

for inpNo = 1:length(top_inports)
    signalName = get_param(top_inports{inpNo,1},'Name');
    lineHandle = get_param(top_inports{inpNo,1},'LineHandles');
    set_param(lineHandle.Outport,'Name',signalName);
end

top_outports = find_system(gcs,'SearchDepth',1,'BlockType','Outport');

for otpNo = 1:length(top_outports)
    lineHandle = get_param(top_outports{otpNo,1},'LineHandles');
    set(lineHandle.Inport,'SignalPropagation','on');
end

allLines = find_system(gcs,'FindAll','on','FollowLinks','on','type','line');

for lineNo = 1:length(allLines)
    if isequal(get_param(top_inports(lineNo),'Name'),'')
        
        
    else
    end
end

% pen_inports = find_system(gcs,'SearchDepth',2,'BlockType','Inport');
% pen_inports = pen_inports((length(top_inports) + 1):end);
% 
% for pinNo = 1:length(pen_inports)
%     lineHandle = get_param(pen_inports{pinNo,1},'LineHandles');
%     set(lineHandle.Outport,'SignalPropagation','on');
% end

disp('Done');