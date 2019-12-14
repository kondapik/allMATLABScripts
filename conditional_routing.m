function [] = conditional_routing(ModelNameWithoutSlx,unique_id)
%%
%   First Input: model name without slx extension and with single quotes eg., 'model_name'
%   Second Input: unique extra charecters to avoid same tag conflict eg., 'a' or 'b'
%
%	STEPS TO EXECUTE
%   1: Remove all ports and tags on top level
%   2: Make sure that there are no white characters (space, enter) in subsystem and port names 
%   3: Make sure that action subsystems are created for every condition and placed in order (Top to Bottom)
%   4: After running the script check signal propagation
%   5: Connect Goto blocks created in action subsystems
%   6: Verify variables with names tailing "_IN"

%%
%   CREATED BY : Kondapi V S Krishna Prasanth
%   DATE OF CREATION: 17-May-2018
%%
%   VERSION MANAGER
%   v1. Creation of script for routing on top level.
%   v2. Branching lines to connect goto tag and modify subsystem size according to number of ports
%   v3. Creating extra inports, gain, outports and tags(if inport available) in case of unequal ports
%   v4. Added progress bar

%%
    %close all;
    clc;
%%
%	Input the name of model
    model_name = ModelNameWithoutSlx;
    %model_name = 'zesty_1';
    %unique_id = 'a';
    load_system(model_name);
    sub = find_system(model_name,'SearchDepth', 1,'BlockType','SubSystem'); % list of paths of all subsystems on top level
    sub_list = struct('name',{},'position',{});
    set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
    bar = waitbar(0,'Collecting subsystem names...','Name','conditional_routing');
    
    for i = 1:length(sub) % creating an array of strcutures with subsystem name and position(top)
        pos = get_param(sub(i),'Position');
        temp = strsplit(char(sub(i)),'/');
        sub_list(i).name = temp(2);
        sub_list(i).position = pos{1,1}(2);
    end
    
    if ( ~isempty(sub_list)) % cheking if the list is not empty
        [~,I] = sort(arrayfun (@(x) x.position, sub_list)); %sorting the list
        list_sorted = sub_list(I); 
    end
    
    sub_list_top = [list_sorted.name]; 
    len_sub_top = length(sub_list_top);
    sub_top_pos = list_sorted(1).position;
%%
    cond = find_system(model_name,'SearchDepth', 1,'BlockType','If');
    tag_else = 'else';
    if isempty(cond) % checking if the conditional blocks is 'IF'
        cond = find_system(model_name,'SearchDepth', 1,'BlockType','SwitchCase');
        tag_else = 'case';
    end
    
    cond_name = strsplit(char(cond),'/');
    cond_name = char(cond_name(2));
    c_ports = get_param(cond,'PortConnectivity');
    cond_out = 0;
    cond_in = 0;
    %cond_ports = double.empty(0);
    for i = 1:length(c_ports{1,1})
        if (~isequal(c_ports{1,1}(i).SrcBlock, -1)) %checking if the port is output
            cond_out = cond_out + 1;
            cond_ports(cond_out,:) = (c_ports{1,1}(i).Position);
        else
            cond_in = cond_in + 1;
        end
    end
    
    new_height = cond_out*(35); %gap per port = 2*height of port + height of tag + 2* gap between tag and line
    current_position = get_param(cond,'Position');
    current_position = current_position{1,1};
    set_param(char(cond),'Position',[current_position(1), current_position(4)- new_height, current_position(3), current_position(4)]);
    
    k = 1;
    c_ports = get_param(cond,'PortConnectivity');
    for i = 1:length(c_ports{1,1})
        if (~isequal(c_ports{1,1}(i).SrcBlock, -1)) %checking if the port is output
            cond_ports(k,:) = (c_ports{1,1}(i).Position);
            k = k + 1;
        end
    end
%%
    stop = 0;
    if cond_out ~= len_sub_top 
        stop = 1;
        msgbox({'Unequal cases and subsystems'; sprintf('%d Cases and %d Action Subsystems',cond_out,len_sub_top)},'Error','error');
    end
%     if switch_case
%         if (isequal(char(get_param(cond,'ShowDefaultCase')),'on') || cond_out ~= len_sub_top)
%             stop = 1;
%         end
%     else
%         if (isequal(char(get_param(cond,'ShowElse')),'on') || cond_out ~= len_sub_top)
%             stop = 1;
%         end
%     end
%%
    if stop
    else
        waitbar(0.05,bar,'Collecting port details of action subsystems...');
        [ports, all_inports, all_outports,all_in_idx, all_out_idx] = port_analysis(model_name,sub_list_top);
%%        
        %Create a master list of all outports
        unique_outports = reshape(all_outports,1,[]);
        unique_outports = unique(unique_outports(~cellfun('isempty',unique_outports)));  
        len_unique = length(unique_outports);
        extra_outports = cell.empty(len_sub_top,0);
        all_extra = 0;
        for i = 1:len_sub_top
            if len_unique == all_out_idx(i)
            else
                sub_outports = all_outports(i,:);
                sub_outports = sub_outports(~cellfun('isempty',sub_outports));
                extra_outports(i) = {setdiff(unique_outports,sub_outports)};
                all_extra = all_extra + length(extra_outports{1,i});
            end
        end
        stat = 0;
        name_gap = 8*max(cellfun('length',unique_outports));
        
%%  
        if isempty(extra_outports)
            len_extra = 0;
        else
            
            for i = 1:len_sub_top
                %Find the limits of subsystem
                path = char(strcat(model_name,'/',sub_list_top(i)));
                blocks = find_system(path,'SearchDepth', 1);
                set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
                pos_limit = zeros(4);
                temp_pos = get_param(blocks(2),'Position');
                pos_limit = temp_pos{1,1};
                if length(blocks) > 2
                    for j = 3:length(blocks)
                    temp_pos = get_param(blocks(j),'Position');
                    temp_pos = temp_pos{1,1};
                        for k = 1:2
                            pos_limit(k) = min(temp_pos(k), pos_limit(k));
                        end
                        for k = 3:4
                            pos_limit(k) = max(temp_pos(k), pos_limit(k));
                        end
                    end
                end

                %creating extra ports and gain
                len_extra = length(extra_outports{1,i});
                side_pad = name_gap + 80;
                bot_pad = 25;
                for j = 1:len_extra
                    stat = stat+1;
                    port_idx = find(strcmp([ports.name], extra_outports{1,i}(j)));
                    in_stat = ports(port_idx).status(1,i);
                    waitbar(0.05+.65*(stat/(all_extra+length(ports))),bar,sprintf('Adding extra ports and tags in subsystem(%d/%d)... (%d/%d)',i,len_sub_top,j,len_extra));
                    if isempty(extra_outports{1,i})
                    elseif length(extra_outports{1,i}) == length(unique_outports)
                        if all_in_idx(i) == 0
                            %No ports
                            %inport, gain, outports
                            block_gap = pos_limit(3) - pos_limit(1) + side_pad;
                            inport_pos = [pos_limit(1)-side_pad,pos_limit(4)+bot_pad,pos_limit(1)-side_pad+30,pos_limit(4)+bot_pad+14];
                            in_gain_outport(path,char(extra_outports{1,i}(j)),inport_pos,block_gap);
                            pos_limit(4) = pos_limit(4)+bot_pad+14;
                        else
                            %No outports
                            %check for inport
                            block_gap = (pos_limit(3) - pos_limit(1) + side_pad)/2;
                            inport_pos = [pos_limit(1),pos_limit(4)+bot_pad,pos_limit(1)+30,pos_limit(4)+bot_pad+14];
                            if in_stat == 1
                                %check for inport name
                                tag_gain_outport(path,char(extra_outports{1,i}(j)),unique_id,inport_pos,block_gap)
                            else
                                in_gain_outport(path,char(extra_outports{1,i}(j)),inport_pos,block_gap);
                            end
                            pos_limit(4) = pos_limit(4)+bot_pad+14;
                        end
                    else
                        block_gap = (pos_limit(3) - pos_limit(1) - 30)/2;
                        inport_pos = [pos_limit(1),pos_limit(4)+bot_pad,pos_limit(1)+30,pos_limit(4)+bot_pad+14];
                        if in_stat == 1
                            %check for inport name
                            tag_gain_outport(path,char(extra_outports{1,i}(j)),unique_id,inport_pos,block_gap)
                        else
                            in_gain_outport(path,char(extra_outports{1,i}(j)),inport_pos,block_gap);
                        end
                        pos_limit(4) = pos_limit(4)+bot_pad+14;
                     end
                 end
            end
        end
%%
        % updating ports
        [ports, all_inports, all_outports,all_in_idx, all_out_idx] = port_analysis(model_name,sub_list_top);

%%
%       Modify size of Subsystem according to number of ports and get position of ports on it
        get_pos = cell.empty(len_sub_top,0);
        for i = 1:len_sub_top
            path = char(strcat(model_name,'/',sub_list_top(i)));
            max_port_no = max(all_in_idx(i),all_out_idx(i));
            current_position = get_param(path,'Position');
            new_height = max_port_no*(2*14+26+5); %gap per port = 2*height of port + height of tag + 2* gap between tag and line
            if new_height ~= 0
                set_param(path,'Position',[current_position(1), sub_top_pos, current_position(3), sub_top_pos + new_height]);
            else
                new_height = current_position(4) - current_position(2);
                set_param(path,'Position',[current_position(1), sub_top_pos, current_position(3), sub_top_pos + new_height]);
            end
            sub_top_pos = sub_top_pos + new_height + 70;
        end
  
        set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
        bottom_limit = get_param(path,'Position');
        bottom_limit = bottom_limit(4);
        for i = 1:len_sub_top
            path = strcat(model_name,'/',sub_list_top(i));    
            get_pos(i) = get_param(path,'PortConnectivity');
        end

        % 
        if stop
        else
            max_left = 0;
            max_width = 0;
            for i = 1:length(ports)
                waitbar(0.05+.65*((i+all_extra)/(all_extra+length(ports))),bar,sprintf('Adding inports and tags to action subsystems... (%d/%d)',i,length(ports)));
                width = 0;
                in_na = isempty(find(ports(i).status(1,:), 1)); % checking if there is an inport
                if in_na
                    in_first = 0; % not compulsory
                    in_last = 0; % 0 bcz the last inport comes on 0th subsystem (doesnt exist)
                    %fprintf('No Inport for variable %s \n',char(ports(i).name));
                else
                    in_first = find(ports(i).status(1,:), 1,'first'); %first subsystem with current variable inport
                    in_last = find(ports(i).status(1,:), 1,'last'); %last subsystem with current variable inport
                end

                for idx = 1:len_sub_top %traversing between subsystems and creating tags & merge blocks
                    % instance of input
                    if (ports(i).status(1,idx) == 1)
                        % Position of the port in subsystem
                        if(all_in_idx(idx) == 1)
                            pos = get_pos{1,idx}.Position;
                        else
                            pos = get_pos{1,idx}(find(strcmp(all_inports(idx,:), char(ports(i).name)))).Position;
                        end

                        if idx == in_first
                            % Create an inport
                            if isempty(find(ports(i).status(2,:), 1))
                                % create inport (without '_In')
                                handle = add_block('built-in/Inport',[model_name,'/',char(ports(i).name)],'BackgroundColor','Green','Position',[pos(1)-(name_gap + 150),pos(2)-7,pos(1)-(name_gap + 120),pos(2)+7]);
                            else
                                % create inport (include '_In')
                                handle = add_block('built-in/Inport',[model_name,'/',sprintf('%s_In',char(ports(i).name))],'BackgroundColor','Green','Position',[pos(1)-(name_gap + 150),pos(2)-7,pos(1)-(name_gap + 120),pos(2)+7]);
                            end
                            pos_port = get_param(handle,'PortConnectivity');
                            add_line(model_name,[pos_port.Position;pos]);
                            if in_first ~= in_last
                                % Create a goto tag with unique tag and "_in"
                                tag = sprintf('%s_In_%s',char(ports(i).name),char(unique_id));
                                width = 7*length(tag) + 20;
                                handle_1 = add_block('simulink/Signal Routing/Goto',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)-(60+width),pos(2)+10,pos(1)-60,pos(2)+36],'ShowName','off','GotoTag',tag);
                                %fprintf('"goto" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(in_first)), char(ports(i).name), goto_no);
                                add_line(model_name,sprintf('%s/1',get_param(handle,'Name')),sprintf('%s/1',get_param(handle_1,'Name')),'autorouting','on');
                                %pos_block = get_param(handle_1,'PortConnectivity');
                                %add_line(model_name,[pos;pos_block.Position]);
                            end
                        else
                            % Create a from tag with unique tag and "_in"
                            tag = sprintf('%s_In_%s',char(ports(i).name),unique_id);
                            width = 7*length(tag) + 20;
                            handle = add_block('simulink/Signal Routing/From',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)-(60+2*width),pos(2)-13,pos(1)-(60+width),pos(2)+13],'ShowName','off','GotoTag',tag);
                            %fprintf('"from" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                            pos_block = get_param(handle,'PortConnectivity');
                            add_line(model_name,[pos_block.Position;pos]);
                        end
                    end

                    % instance of output
                    if (ports(i).status(2,idx) == 1)

                        % position of port
                        if(all_out_idx(idx) == 1)
                            pos = get_pos{1,idx}(2 + all_in_idx(idx)).Position;
                        else
                            pos = get_pos{1,idx}((find(strcmp(all_outports(idx,:), char(ports(i).name))))+ all_in_idx(idx) + 1).Position;
                        end

                        tag = sprintf('%s_%d_%s',char(ports(i).name),idx,unique_id);
                        width = 7*length(tag) + 20;
                        handle = add_block('simulink/Signal Routing/Goto',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)+(40+name_gap),pos(2)-13,pos(1)+(40+name_gap+width),pos(2)+13],'ShowName','off','GotoTag',tag);
                        pos_port = get_param(handle,'PortConnectivity');
                        add_line(model_name,[pos;pos_port.Position]);
                        temp_position = get_param(handle,'Position');
                        if temp_position(3) > max_left
                            max_left = temp_position(3);
                        end
                    end
                    if width > max_width
                        max_width = width;
                    end
                end
            end
            % Creation of else or case tags
            for i = 2:cond_out
                % Create a goto tag at conditional block
                tag = sprintf('%s_%d_%s',tag_else,i-1,unique_id);
                width = 7*length(tag) + 20;
                pos = cond_ports(i,:);
                handle = add_block('simulink/Signal Routing/Goto',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)+40,pos(2)-13,pos(1)+(40+width),pos(2)+13],'ShowName','off','GotoTag',tag);
                pos_port = get_param(handle,'PortConnectivity');
                add_line(model_name,[pos;pos_port.Position]);
                
                % Create from above subsystem
                pos = get_pos{1,i}(1 + all_in_idx(i)).Position;
                handle = add_block('simulink/Signal Routing/From',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)-(20+width),pos(2)-36,pos(1)-20,pos(2)- 10],'ShowName','off','GotoTag',tag);
                pos_name = get_param(handle,'Name');
                add_line(model_name,{sprintf('%s/1',pos_name)},{sprintf('%s/%s',char(sub_list_top(i)),'ifaction')},'autorouting','on');
                %add_line(model_name,[pos_port.Position;pos]);
            end
            add_line(model_name,{sprintf('%s/%d',cond_name,cond_in)},{sprintf('%s/%s',char(sub_list_top(1)),'ifaction')},'autorouting','on');
            
            %add merge blocks
            bottom = bottom_limit;
            left_gap = 80+name_gap;
            height = 28*len_sub_top + 20;
            for i = 1:all_out_idx(1)
                waitbar(0.7+.20*(i/all_out_idx(1)),bar,sprintf('Adding tags, merge blocks and outports... (%d/%d)',i,all_out_idx(1)));
                handle = add_block('simulink/Signal Routing/Merge',[model_name,'/merge'],'MakeNameUnique','on','Inputs',sprintf('%d',len_sub_top),'Position',[max_left+left_gap+max_width,bottom-height,max_left+left_gap+max_width+55,bottom],'ShowName','off');
                bottom = bottom - height - 20;
                port = get_param(handle,'PortConnectivity');
                for idx = 1:len_sub_top
                    pos = port(idx).Position;
                    tag = sprintf('%s_%d_%s',char(all_outports(1,i)),idx,unique_id);
                    width = 7*length(tag) + 20;
                    handle = add_block('simulink/Signal Routing/From',[model_name,'/',tag],'MakeNameUnique','on','Position',[pos(1)-(left_gap+width-40),pos(2)-13,pos(1)-(left_gap-40),pos(2)+13],'ShowName','off','GotoTag',tag);
                    pos_port = get_param(handle,'PortConnectivity');
                    add_line(model_name,[pos_port.Position;pos]);
                end
                pos = port(len_sub_top + 1).Position;
                handle = add_block('built-in/Outport',[model_name,'/',char(all_outports(1,i))],'BackgroundColor','Red','Position',[pos(1)+(name_gap+20),pos(2)-7,pos(1)+(name_gap + 50),pos(2)+7]);
                pos_port = get_param(handle,'PortConnectivity');
                handle = add_line(model_name,[pos;pos_port.Position]);
                set_param(handle,'Name',char(all_outports(1,i)));
            end
            set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
%%
            % Create an array of handles to every signal line in the diagram
            signalLines = find_system(model_name,'FindAll','on','SearchDepth', 2,'type','line');

            % Enable or disable the property for each signal line
            for i = 1:length(signalLines)
                set(signalLines(i),'signalPropagation','off');
                set(signalLines(i),'signalPropagation','on');
                waitbar(.9+(0.1*(i/length(signalLines))),bar,sprintf('Updating signal names... (%d/%d)',i,length(signalLines)));
            end

            close(bar);
            
            msgbox({'Routing Completed';'Connect Goto blocks action subsystem';'Verify & align signal names';'Verify variables with names tailing "_IN"'},'Success');
        end
    end
    
    function [all_ports, inport_names, outport_names,in_idx, out_idx] = port_analysis(working_path,subsystem_list)
        all_ports = struct('name',{},'status',{}); % Strucuture definition for variables
        inports = find_system(working_path, 'SearchDepth', 2, 'BlockType', 'Inport');
        outports = find_system(working_path, 'SearchDepth', 2, 'BlockType', 'Outport');
        len_sub_list = length(subsystem_list); 
        inport_names = cell.empty(len_sub_list,0);
        outport_names = cell.empty(len_sub_list,0);
        in_idx = zeros(len_sub_list,1);
        out_idx = zeros(len_sub_list,1);

    %   Updating status of inports in ports
        if isempty(inports)
        else
            for in = 1:length(inports)
                in_name_string = char(inports{in});
                in_temp = strsplit(in_name_string,'/');
                sub_idx = find(strcmp(subsystem_list, in_temp(2))); % finding index correseponding to subsystem name
                inport_split = char(in_temp(3));
                if(length(inport_split) > 2)
                    if(strcmpi(inport_split(end-2:end),'_In'))
                        inport_split = inport_split(1:end-3); % removing '_In'
                    end
                end
                inport_split = strsplit(strcat(inport_split,' '),' ');
                inport_name = inport_split(1); % removing '_In'
    %             if (find(strcmp([], inport_name)))
    %             else
    %                 all_in_idx(sub_idx) = all_in_idx(sub_idx) + 1; 
    %                 all_inports(sub_idx,all_in_idx(sub_idx)) = inport_name;
    %             end
                in_idx(sub_idx) = in_idx(sub_idx) + 1; 
                inport_names(sub_idx,in_idx(sub_idx)) = inport_name;
                idx_port = find(strcmp([all_ports.name], inport_name));
                if (idx_port) % checking of strucure for port name is created
                else
                    % creating strucutre for port if not available
                    len_port = length(all_ports);
                    idx_port = len_port + 1;
                    all_ports(idx_port).name = inport_name;
                    all_ports(idx_port).status = zeros(2,len_sub_list);
                end
                all_ports(idx_port).status(1,sub_idx) = 1;
            end
        end

    %   Updating status of outports in ports
        if isempty(outports)
        else
            for out = 1:length(outports)
                out_name_string = char(outports{out});
                out_temp = strsplit(out_name_string,'/');
                sub_idx = find(strcmp(subsystem_list, out_temp(2))); % finding index correseponding to subsystem name
    %             if (find(strcmp([], outport_name)))
    %             else
    %                 all_out_idx(sub_idx) = all_out_idx(sub_idx) + 1; 
    %                 all_outports(sub_idx,all_out_idx(sub_idx)) = outport_name;
    %             end
                outport_name = out_temp(3);
                out_idx(sub_idx) = out_idx(sub_idx) + 1; 
                outport_names(sub_idx,out_idx(sub_idx)) = outport_name;
                idx_port = find(strcmp([all_ports.name], outport_name));
                if (idx_port) % checking of strucure for port name is created
                else
                    % creating strucutre for port if not available
                    len_port = length(all_ports);
                    idx_port = len_port + 1;
                    all_ports(idx_port).name = outport_name;
                    all_ports(idx_port).status = zeros(2,len_sub_list);
                end
                all_ports(idx_port).status(2,sub_idx) = 1;
            end
        end
    end

    function [] = in_gain_outport(working_path,name,in_position,mid)
        handle_In = add_block('built-in/Inport',[working_path,'/',sprintf('%s_In',name)],'BackgroundColor','Green','Position',in_position);
        handle_Out = add_block('built-in/Outport',[working_path,'/',name],'BackgroundColor','Red','Position',[in_position(1)+2*mid, in_position(2), in_position(3)+2*mid, in_position(4)]);
        handle_Gain = add_block('simulink/Math Operations/Gain',[working_path,'/',name],'MakeNameUnique','on','ShowName','off','Position',[in_position(1)+mid, in_position(2)-8, in_position(3)+mid, in_position(4)+8]);
        add_line(working_path,sprintf('%s/1',get_param(handle_In,'Name')),sprintf('%s/1',get_param(handle_Gain,'Name')),'autorouting','on');
        handle_line = add_line(working_path,sprintf('%s/1',get_param(handle_Gain,'Name')),sprintf('%s/1',get_param(handle_Out,'Name')),'autorouting','on');
        set_param(handle_line,'Name',name);
    end

    function [] = tag_gain_outport(working_path,name,id,in_position,mid)
        tag_name = sprintf('%s_Out_%s',name,id);
        tag_width = 7*length(tag_name) + 10;
        handle_in = getSimulinkBlockHandle([working_path,'/',name]);
        if handle_in == -1
        else
            set_param(handle_in,'Name',sprintf('%s_In',name));
        end
        add_block('simulink/Signal Routing/Goto',[working_path,'/',tag_name],'MakeNameUnique','on','Position',[in_position(1)+20,in_position(2)-6,in_position(1)+(tag_width)+20,in_position(4)+6],'ShowName','off','GotoTag',tag_name);
        handle_From = add_block('simulink/Signal Routing/From',[working_path,'/',tag_name],'MakeNameUnique','on','Position',[in_position(1)+tag_width+40,in_position(2)-6,in_position(1)+(2*tag_width)+40,in_position(4)+6],'ShowName','off','GotoTag',tag_name);
        handle_Out = add_block('built-in/Outport',[working_path,'/',name],'BackgroundColor','Red','Position',[in_position(1)+2*mid, in_position(2), in_position(3)+2*mid, in_position(4)]);
        handle_Gain = add_block('simulink/Math Operations/Gain',[working_path,'/',name],'MakeNameUnique','on','ShowName','off','Position',[in_position(1)+mid, in_position(2)-8, in_position(3)+mid, in_position(4)+8]);
        add_line(working_path,sprintf('%s/1',get_param(handle_From,'Name')),sprintf('%s/1',get_param(handle_Gain,'Name')),'autorouting','on');
        handle_line = add_line(working_path,sprintf('%s/1',get_param(handle_Gain,'Name')),sprintf('%s/1',get_param(handle_Out,'Name')),'autorouting','on');
        set_param(handle_line,'Name',name);
    end
end