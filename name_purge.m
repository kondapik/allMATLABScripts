function [] = name_purge(ModelNameWithoutSlx)
%%
%   Input: model name without slx extension and with single quotes eg., 'model_name'
%
%%
%   CREATED BY : Kondapi V S Krishna Prasanth
%   DATE OF CREATION: 12-June-2018
%%
%   VERSION MANAGER
%   v1. Creation of script using regexpressions
%   v2. Added progress bar

%all_ports,all_tags
%%
    %close all;
    %clc;
%%
    load_system(ModelNameWithoutSlx);
    %ModelNameWithoutSlx = 'dysfunctional_3';
    %all = find_system(ModelNameWithoutSlx,'FindAll','on','FollowLinks','on','LookUnderMasks','all'); % list of paths of all subsystems on top level
    bar = waitbar(0,'Collecting block handles...','Name','name_purge');
    all_blocks = find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','SubSystem');
    all_blocks = vertcat(all_blocks,find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','Inport'));
    all_blocks = vertcat(all_blocks,find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','Outport'));
    all_blocks = vertcat(all_blocks,find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','Goto'));
    all_blocks = vertcat(all_blocks,find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','From'));
    all_blocks = getSimulinkBlockHandle(all_blocks);
    all_blocks = vertcat(all_blocks,find_system(ModelNameWithoutSlx,'FindAll','on','FollowLinks','on','type','line'));
    waitbar(.05,bar,'Updating names...');
    for i = 1:length(all_blocks)
        temp_name = get_param(all_blocks(i),'Name');
        try 
            set_param(all_blocks(i),'Name',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
%            if isequal(get_param(all_ports(i),'type'),'port')
%                handle = get_param(all_ports(i),'Line');
%                temp_name = get_param(handle,'Name');
%                set_param(handle,'Name',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
%            end
        catch ME
            %disp(ME.identifier);
            if isequal(ME.identifier, 'Simulink:blocks:DupBlockName')
                if isequal(get_param(all_blocks(i),'BlockType'),'Outport')
                    set_param(regexprep(getfullname(all_blocks(i)),'[^a-zA-Z0-9/_]',''),'Name',sprintf('%s_In',regexprep(temp_name,'[^a-zA-Z0-9_]','')));
                    set_param(all_blocks(i),'Name',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
                elseif isequal(get_param(all_blocks(i),'BlockType'),'Inport')
                    set_param(all_blocks(i),'Name',sprintf('%s_In',regexprep(temp_name,'[^a-zA-Z0-9_]','')));
                end
            else
                msgbox({'Error Identifier: ',ME.identifier; 'Error: ',ME.message; 'Error Cause: ',ME.cause},'Error','error');
                break;
            end
        end
        if ~isequal(get_param(all_blocks(i),'type'),'line')
            if isequal(get_param(all_blocks(i),'BlockType'),'Goto') || isequal(get_param(all_blocks(i),'BlockType'),'From')
                temp_name = get_param(all_blocks(i),'GotoTag');
                set_param(all_blocks(i),'GotoTag',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
            end
        end
        
        waitbar(0.9*(i/length(all_blocks)),bar,sprintf('Updating names... (%d/%d)',i,length(all_blocks)));
    end
    
%     all_tags = find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','Goto');
%     all_tags = vertcat(all_tags,find_system(ModelNameWithoutSlx,'FollowLinks','on','BlockType','From'));
%     all_tags = getSimulinkBlockHandle(all_tags);
%     for j = 1:length(all_tags)
%         temp_name = get_param(all_tags(j),'GotoTag');
%         set_param(all_tags(j),'GotoTag',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
%         temp_name = get_param(all_tags(j),'Name');
%         set_param(all_tags(j),'Name',regexprep(temp_name,'[^a-zA-Z0-9_]',''));
%     end
%     
    waitbar(.9,bar,'Updating signal names...');
    signalLines = find_system(ModelNameWithoutSlx,'FindAll','on','type','line');
    % Enable or disable the property for each signal line
    for j = 1:length(signalLines)
        set(signalLines(j),'signalPropagation','off');
        set(signalLines(j),'signalPropagation','on');
        waitbar(.9+(0.1*(j/length(signalLines))),bar,sprintf('Updating signal names... (%d/%d)',j,length(signalLines)));
    end
        
    close(bar);
    if isequal(i, length(all_blocks)) %&& isequal(j,length(all_tags)) 
        msgbox({'All non-alphanumeric charecters are deleted'},'Success'); 
    end
    
end