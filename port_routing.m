function [] = port_routing(ModelNameWithoutSlx,integration)
%%
%   First Input: model name without slx extension and with single quotes eg., 'model_name'
%   Second Input: 1 if integration, 0 if only port routing on top level
%
%	STEPS TO EXECUTE
%   1: Remove all ports and tags on top level and penultimate level (integration level)
%   2: Make sure that there are no white characters (space, enter) in subsystem and port names 
%   3: Make sure that there is enough space between ports to accommodate  goto tags
%   4: After running the script check signal propagation
%   5: Verify variables with names tailing "_IN"

%%
%   CREATED BY : Kondapi V S Krishna Prasanth
%   DATE OF CREATION: 16-May-2018
%%
%   VERSION MANAGER
%   v1. Creation of script for integration on top level.
%   v2. Port arrangement at top level included
%	v3. Complete integration (integration within subsystems and top level port arrangement)
%   v4. Branching lines to connect goto tag and modify subsystem size according to number of ports
%   v5. Updated the positions of ports and tags to accomodate signal name
%   v6. Added progress bar

%%
    %close all;
    clc;
%%
%	Input the name of model
    model_name = ModelNameWithoutSlx;
    load_system(model_name);
    
    bar = waitbar(0,'Collecting subsystem names...','Name','port_routing');
    sub = find_system(model_name,'SearchDepth', 1,'BlockType','SubSystem'); % list of paths of all subsystems on top level
    sub_list = struct('name',{},'position',{});
    set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
    
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
    for i = 1:len_sub_top 
        if cellfun(@isempty,regexpi(strrep(sub_list_top(i),' ',''),'modelheader'))
        else
            sub_list_top(i) = []; % removing model header (1st subsystem)
            break;
        end
    end
    len_sub_top = length(sub_list_top);
    waitbar(0.05,bar,'Subsystems list sorted');
%%
    if integration == 1
        for top = 1:len_sub_top 
            %load_system(strcat(model_name,'/',sub_list_top(top)));
            path_new = strcat(model_name,'/',sub_list_top(top));
            path_new_char = char(strcat(model_name,'/',sub_list_top(top)));
            sub = find_system(path_new,'SearchDepth', 1,'BlockType','SubSystem'); % list of all subsystem paths in current subsystem
            sub_list = struct('name',{},'position',{});
            set_param(path_new_char, 'ZoomFactor','FitSystem'); % fit to screen
            for i = 2:length(sub) % avoiding the path for current subsystem
                pos = get_param(sub(i),'Position');
                temp = strsplit(char(sub(i)),'/');
                sub_list(i-1).name = temp(3);
                sub_list(i-1).position = pos{1,1}(2);
            end
            if ( ~isempty(sub_list))
                [~,I] = sort(arrayfun (@(x) x.position, sub_list));
                list_sorted = sub_list(I);
            end
            sub_list = [list_sorted.name];
            
            len_sub = length(sub_list);
            for i = 1:len_sub 
                if cellfun(@isempty,regexpi(strrep(sub_list(i),' ',''),'docblock'))
                else
                    sub_list(i) = []; % removing doc block (1st subsystem)
                    break;
                end
            end
            
            waitbar(0.05+0.85*((top-1)/(len_sub_top+1)),bar,sprintf('Collecting port details of penultimate subsystems (%d/%d)',top,len_sub_top));
            % create list of inports and outports
            % include {'FollowLinks', 'on'} to also include library links
            inports = find_system(path_new, 'SearchDepth', 2,'FollowLinks', 'on', 'BlockType', 'Inport');
            outports = find_system(path_new, 'SearchDepth', 2,'FollowLinks', 'on', 'BlockType', 'Outport');
            len_sub = length(sub_list);
            ports = struct('name',{},'status',{}); % Strucuture definition for variables
            all_inports = cell.empty(len_sub,0);
            all_outports = cell.empty(len_sub,0);
            all_in_idx = zeros(len_sub,1);
            all_out_idx = zeros(len_sub,1);
            max_length = 0;

            % Updating status of inports in ports
            if isempty(inports)
            else
                for i = 1:length(inports)
                    in_name_string = char(inports{i});
                    in_temp = strsplit(in_name_string,'/');
                    sub_idx = find(strcmp(sub_list, in_temp(3))); % finding index correseponding to subsystem name
                    inport_split = char(in_temp(4));
                    if(length(inport_split) > 2)
                        if(strcmpi(inport_split(end-2:end),'_In'))
                            inport_split = inport_split(1:end-3); % removing '_In'
                        end
                    end
                    inport_split = strsplit(strcat(inport_split,' '),' '); %to convert string to cell
                    inport_name = inport_split(1);
%                     if (find(strcmp([], inport_name)))
%                     else
%                     	all_in_idx(sub_idx) = all_in_idx(sub_idx) + 1; 
%                     	all_inports(sub_idx,all_in_idx(sub_idx)) = inport_name;
%                     end
                    all_in_idx(sub_idx) = all_in_idx(sub_idx) + 1; %updating index 
                    all_inports(sub_idx,all_in_idx(sub_idx)) = inport_name; %updating name corresponding to idx
                    port_idx = find(strcmp([ports.name], inport_name));
                    if (max_length < length(char(inport_name)))
                        max_length = length(char(inport_name));
                    end
                    if (port_idx) % checking of strucure for port name is created
                    else
                        % creating strucutre for port if not available
                        len_port = length(ports);
                        port_idx = len_port + 1;
                        ports(port_idx).name = inport_name;
                        ports(port_idx).status = zeros(2,len_sub);
                    end
                    ports(port_idx).status(1,sub_idx) = 1;
                end
            end

    %   Updating status of outports in ports
            if isempty(outports)
            else
                for i = 1:length(outports)
                    out_name_string = char(outports{i});
                    out_temp = strsplit(out_name_string,'/');
                    sub_idx = find(strcmp(sub_list, out_temp(3))); % finding index correseponding to subsystem name
%                     if (find(strcmp([], outport_name)))
%                     else
%                         all_out_idx(sub_idx) = all_out_idx(sub_idx) + 1; 
%                         all_outports(sub_idx,all_out_idx(sub_idx)) = outport_name;
%                     end
                    outport_name = out_temp(4);
                    all_out_idx(sub_idx) = all_out_idx(sub_idx) + 1; 
                    all_outports(sub_idx,all_out_idx(sub_idx)) = outport_name;
                    port_idx = find(strcmp([ports.name], outport_name));
                    if (max_length < length(char(outport_name)))
                        max_length = length(char(outport_name));
                    end
                    if (port_idx) % checking of strucure for port name is created
                    else
                        % creating strucutre for port if not available
                        len_port = length(ports);
                        port_idx = len_port + 1;
                        ports(port_idx).name = outport_name;
                        ports(port_idx).status = zeros(2,len_sub);
                    end
                    ports(port_idx).status(2,sub_idx) = 1;
                end
            end
            
            % Position of ports on subsystems
            get_pos = cell.empty(len_sub,0);
            sub_top_pos = get_param(char(strcat(path_new,'/',sub_list(1))),'Position');
            sub_top_pos = sub_top_pos(2);
            for i = 1:len_sub
                path = char(strcat(path_new,'/',sub_list(i)));
                max_port_no = max(all_in_idx(i),all_out_idx(i));
                current_position = get_param(path,'Position');
                if max_port_no
                    new_height = max_port_no*(2*14+26+5); %gap per port = 2*height of port
                    set_param(path,'Position',[current_position(1), sub_top_pos, current_position(3), sub_top_pos + new_height]);
                    sub_top_pos = sub_top_pos + new_height + 40;
                else
                    new_height = current_position(4) - current_position(2);
                    set_param(path,'Position',[current_position(1), sub_top_pos, current_position(3), sub_top_pos + new_height]);
                    sub_top_pos = sub_top_pos + new_height + 40;
                end
            end
            set_param(path_new_char, 'ZoomFactor','FitSystem'); % fit to screen
            for i = 1:len_sub
                path = strcat(path_new,'/',sub_list(i));
                get_pos(i) = get_param(path,'PortConnectivity');
            end
            
            % Analysis and port & tag creation
            for i = 1:length(ports) % traversing variable by variable
                
                waitbar(0.05+0.85*((top-1)/(len_sub_top+1))+(i/(length(ports)*(len_sub_top+1))),bar,{sprintf('Integration in subsystem (%d/%d)',top,len_sub_top),sprintf('Variables integrated (%d/%d)',i,length(ports))});
                
                goto_no = 0; %tag number for goto and from
                in_na = isempty(find(ports(i).status(1,:), 1)); % checking if there is an inport
                if in_na
                    in_first = 0; % not compulsory
                    in_last = 0; % 0 bcz the last inport comes on 0th subsystem (doesnt exist)
                    %fprintf('No Inport for variable %s \n',char(ports(i).name));
                else
                    in_first = find(ports(i).status(1,:), 1,'first'); %first subsystem with current variable inport
                    in_last = find(ports(i).status(1,:), 1,'last'); %last subsystem with current variable inport
                end
                out_na = isempty(find(ports(i).status(2,:), 1));
                if out_na
                    out_first = len_sub + 1; % 0 bcz the last port comes after last subsystem (doesnt exist)
                    out_last = len_sub + 1; % not compulsory
                    %fprintf('No outport for variable %s \n',char(ports(i).name));
                else
                    out_first = find(ports(i).status(2,:), 1,'first'); %first subsystem with current variable outport
                    out_last = find(ports(i).status(2,:), 1,'last'); %last subsystem with current variable outport
                end

                for idx = 1:len_sub %traversing between subsystems and creating ports & tags
                    
                    % instance of input
                    if (ports(i).status(1,idx) == 1)
                        % Position of the port in subsystem
                        if(all_in_idx(idx) == 1)
                            pos = get_pos{1,idx}.Position;
                        else
                            pos = get_pos{1,idx}(find(strcmp(all_inports(idx,:), char(ports(i).name)))).Position;
                            pos_first = get_pos{1,in_first}(find(strcmp(all_inports(in_first,:), char(ports(i).name)))).Position;
                        end

                        if idx > out_first
                            % create 'from' related to 'goto' from 'latest outport'
                            tag = sprintf('%s_%d',char(ports(i).name),goto_no);
                            width = 8*length(tag) + 10;
                            handle = add_block('simulink/Signal Routing/From',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos(1)-(2*width),pos(2)-13,pos(1)-(width),pos(2)+13],'ShowName','off','GotoTag',tag);
                            pos_block = get_param(handle,'PortConnectivity');
                            add_line(path_new_char,[pos_block.Position;pos]);
                            %fprintf('"from" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                        elseif idx == in_first % first instance of inport with no previous outport
                            if out_na
                                % create inport (without '_In')
                                handle_In = add_block('built-in/Inport',[model_name,'/',char(sub_list_top(top)),'/',char(ports(i).name)],'BackgroundColor','Green','Position',[pos(1)-(2*8*max_length + 80),pos(2)-7,pos(1)-(2*8*max_length + 50),pos(2)+7]);
                                %fprintf('"inport" created at "%s" subssystem with name "%s" \n',char(sub_list(idx)), char(ports(i).name));
                            else
                                % create inport (include '_In')
                                handle_In = add_block('built-in/Inport',[model_name,'/',char(sub_list_top(top)),'/',sprintf('%s_In',char(ports(i).name))],'BackgroundColor','Green','Position',[pos(1)-(2*8*max_length + 80),pos(2)-7,pos(1)-(2*8*max_length + 50),pos(2)+7]);
                                %fprintf('"inport" created at "%s" subssystem with name "%s_In" \n',char(sub_list(idx)), char(ports(i).name));
                            end
                            pos_port = get_param(handle_In,'PortConnectivity');
                            handle = add_line(path_new_char,[pos_port.Position;pos]);
                            %set_param(handle,'Name',char(ports(i).name));
                        else % no previous outport
                            if goto_no
                                % create 'from' related to 'goto' from input
                                tag = sprintf('%s_%d',char(ports(i).name),goto_no);
                                width = 8*length(tag) + 10;
                                handle = add_block('simulink/Signal Routing/From',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos(1)-(2*width),pos(2)-13,pos(1)-(width),pos(2)+13],'ShowName','off','GotoTag',tag);
                                pos_block = get_param(handle,'PortConnectivity');
                                add_line(path_new_char,[pos_block.Position;pos]);
                                %fprintf('"from" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                            else %no 'goto' is created
                                % create a 'goto' @ input and corresponding 'from' @ idx
                                goto_no = goto_no + 1;
                                tag = sprintf('%s_%d',char(ports(i).name),goto_no);
                                width = 8*length(tag) + 10;
                                handle_1 = add_block('simulink/Signal Routing/Goto',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos_first(1)-(2*width),pos_first(2)+10,pos_first(1)-(width),pos_first(2)+36],'ShowName','off','GotoTag',tag);
                                add_line(path_new_char,sprintf('%s/1',get_param(handle_In,'Name')),sprintf('%s/1',get_param(handle_1,'Name')),'autorouting','on');
                                %fprintf('"goto" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(in_first)), char(ports(i).name), goto_no);
                                %pos_block = get_param(handle_1,'PortConnectivity');
                                %add_line(model_name,[pos_port.Position;pos_block.Position]);

                                handle = add_block('simulink/Signal Routing/From',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos(1)-(2*width),pos(2)-13,pos(1)-(width),pos(2)+13],'ShowName','off','GotoTag',tag);
                                %fprintf('"from" created at "%s" subssystem inport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                                pos_block = get_param(handle,'PortConnectivity');
                                add_line(path_new_char,[pos_block.Position;pos]);
                            end
                        end
                    end

                    % instance of output
                    if (ports(i).status(2,idx) == 1)
                        
                        % position of port
                        if(all_out_idx(idx) == 1)
                            port_idx = 1;
                            pos = get_pos{1,idx}(port_idx + all_in_idx(idx)).Position;
                        else
                            port_idx = (find(strcmp(all_outports(idx,:), char(ports(i).name))));
                            pos = get_pos{1,idx}(port_idx + all_in_idx(idx)).Position;
                        end

                        if idx == out_last %last instance of output
                            % create outport
                            handle = add_block('built-in/Outport',[model_name,'/',char(sub_list_top(top)),'/',char(ports(i).name)],'BackgroundColor','Red','Position',[pos(1)+(3*8*max_length - 30),pos(2)-7,pos(1)+(3*8*max_length),pos(2)+7]);
                            pos_port = get_param(handle,'PortConnectivity');
                            add_line(path_new_char,[pos;pos_port.Position]);
                            %fprintf('"outport" created at "%s" subssystem with name "%s" \n',char(sub_list(idx)), char(ports(i).name));
                            if idx < in_last
                                % also create a 'goto'
                                goto_no = goto_no + 1;
                                tag = sprintf('%s_%d',char(ports(i).name),goto_no);
                                width = 8*length(tag) + 10;
                                handle_goto = add_block('simulink/Signal Routing/Goto',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos(1)+(width),pos(2)+10,pos(1)+(2*width),pos(2)+36],'ShowName','off','GotoTag',tag);
                                add_line(path_new_char,sprintf('%s/%d',char(sub_list(idx)),port_idx),sprintf('%s/1',get_param(handle_goto,'Name')),'autorouting','on');
%                                 pos_port = get_param(handle,'PortConnectivity');
%                                 handle = add_line(model_name,[pos;pos_port.Position]);
%                                 fprintf('"goto" created at "%s" subssystem outport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                            end
                        elseif idx < in_last
                            % create a 'goto'
                            goto_no = goto_no + 1;
                            tag = sprintf('%s_%d',char(ports(i).name),goto_no);
                            width = 8*length(tag) + 10;
                            handle = add_block('simulink/Signal Routing/Goto',[model_name,'/',char(sub_list_top(top)),'/',tag],'MakeNameUnique','on','Position',[pos(1)+(width),pos(2)-13,pos(1)+(2*width),pos(2)+13],'ShowName','off','GotoTag',tag);
                            pos_port = get_param(handle,'PortConnectivity');
                            add_line(path_new_char,[pos;pos_port.Position]);
                            %fprintf('"goto" created at "%s" subssystem outport side with tag "%s_%d" \n',char(sub_list(idx)), char(ports(i).name), goto_no);
                        else
                            % create a 'terminator'
                            handle = add_block('built-in/Terminator',[model_name,'/',char(sub_list_top(top)),'/',sprintf('Terminator_%d',i)],'MakeNameUnique','on','Position',[pos(1)+60,pos(2)-10,pos(1)+80,pos(2)+10],'ShowName','off');
                            pos_port = get_param(handle,'PortConnectivity');
                            add_line(path_new_char,[pos;pos_port.Position]);
                            %fprintf('"terminator" created at "%s" subssystem outport side for outport "%s" \n',char(sub_list(idx)), char(ports(i).name));
                        end
                    end
                end
            end
            clear('sub','sub_list','set_param','pos','temp','list_sorted','inports','outports','len_sub','ports','all_inports','all_outports','all_in_idx','all_out_idx','in_name_string','in_temp','sub_idx','inport_split','inport_name','port_idx','len_port','out_name_string','out_temp','outport_name','get_pos','pos_first');
        end
    end

%%
%	create list of inports and outports
    % include {'FollowLinks', 'on'} to also include library links
    inports = find_system(model_name, 'SearchDepth', 2, 'FollowLinks', 'on', 'BlockType', 'Inport');
    outports = find_system(model_name, 'SearchDepth', 2, 'FollowLinks', 'on','BlockType', 'Outport');
    ports = struct('name',{},'status',{}); % Strucuture definition for variables
    all_inports = cell.empty(len_sub_top,0);
    all_outports = cell.empty(len_sub_top,0);
    all_in_idx = zeros(len_sub_top,1);
    all_out_idx = zeros(len_sub_top,1);
    max_length = 0;
%%
%   Updating status of inports in ports
    if integration ~= 1
        waitbar(0.05,bar,'Collecting port details of top level subsystems');
    end
    
    if isempty(inports)
    else
        for i = 1:length(inports)
            in_name_string = char(inports{i});
            in_temp = strsplit(in_name_string,'/');
            sub_idx = find(strcmp(sub_list_top, in_temp(2))); % finding index correseponding to subsystem name
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
            all_in_idx(sub_idx) = all_in_idx(sub_idx) + 1; 
            all_inports(sub_idx,all_in_idx(sub_idx)) = inport_name;
            port_idx = find(strcmp([ports.name], inport_name));
            if (max_length < length(char(inport_name)))
            	max_length = length(char(inport_name));
            end
            if (port_idx) % checking of strucure for port name is created
            else
                % creating strucutre for port if not available
                len_port = length(ports);
                port_idx = len_port + 1;
                ports(port_idx).name = inport_name;
                ports(port_idx).status = zeros(2,len_sub_top);
            end
            ports(port_idx).status(1,sub_idx) = 1;
        end
    end
    
%   Updating status of outports in ports
    if isempty(outports)
    else
        for i = 1:length(outports)
            out_name_string = char(outports{i});
            out_temp = strsplit(out_name_string,'/');
            sub_idx = find(strcmp(sub_list_top, out_temp(2))); % finding index correseponding to subsystem name
%             if (find(strcmp([], outport_name)))
%             else
%                 all_out_idx(sub_idx) = all_out_idx(sub_idx) + 1; 
%                 all_outports(sub_idx,all_out_idx(sub_idx)) = outport_name;
%             end
            outport_name = out_temp(3);
            all_out_idx(sub_idx) = all_out_idx(sub_idx) + 1; 
            all_outports(sub_idx,all_out_idx(sub_idx)) = outport_name;
            port_idx = find(strcmp([ports.name], outport_name));
            if (max_length < length(char(outport_name)))
                max_length = length(char(outport_name));
            end
            if (port_idx) % checking of strucure for port name is created
            else
                % creating strucutre for port if not available
                len_port = length(ports);
                port_idx = len_port + 1;
                ports(port_idx).name = outport_name;
                ports(port_idx).status = zeros(2,len_sub_top);
            end
            ports(port_idx).status(2,sub_idx) = 1;
        end
    end
%%
%   Position of ports on subsystems
    get_pos = cell.empty(len_sub_top,0);
    sub_top_pos = get_param(char(strcat(model_name,'/',sub_list_top(1))),'Position');
    sub_top_pos = sub_top_pos(2);
    for i = 1:len_sub_top
        path = char(strcat(model_name,'/',sub_list_top(i)));
        max_port_no = max(all_in_idx(i),all_out_idx(i));
        current_position = get_param(path,'Position');
        if max_port_no
            new_height = max_port_no*(2*14 + 10); %gap per port = 2*height of port
            set_param(path,'Position',[current_position(1), sub_top_pos, current_position(3), sub_top_pos + new_height]);
            sub_top_pos = sub_top_pos + new_height + 40;
        else
            sub_top_pos = current_position(4) + 40;
        end
    end
    set_param(model_name, 'ZoomFactor','FitSystem'); % fit to screen
    for i = 1:len_sub_top
        path = strcat(model_name,'/',sub_list_top(i));
        get_pos(i) = get_param(path,'PortConnectivity');
    end
    
    for i = 1:length(ports)
        if integration == 1
            waitbar(0.05+0.85*(len_sub_top/(len_sub_top+1))+(i/(length(ports)*(len_sub_top+1))),bar,{'Top level port routing...',sprintf('Variables integrated(%d/%d)',i,length(ports))});
        else
            waitbar(0.05+0.85*(i/(length(ports))),bar,{'Top level port routing...',sprintf('Variables integrated(%d/%d)',i,length(ports))});
        end
        in_count = 0;
        out_count = 0;
         for idx = 1:len_sub_top
            % instance of input
            if (ports(i).status(1,idx) == 1)
                if(all_in_idx(idx) == 1)
                    pos = get_pos{1,idx}.Position;
                else
                    pos = get_pos{1,idx}(find(strcmp(all_inports(idx,:), char(ports(i).name)))).Position;
                end

                if isempty(find(ports(i).status(2,:), 1))
                    % create inport (without '_In')
                    if in_count
                        handle = add_block('built-in/Inport',[model_name,'/',sprintf('%s_%d',char(ports(i).name),in_count)],'BackgroundColor','Green','Position',[pos(1)-(60+8*max_length),pos(2)-7,pos(1)-(30+8*max_length),pos(2)+7]);
                    else
                        handle = add_block('built-in/Inport',[model_name,'/',char(ports(i).name)],'BackgroundColor','Green','Position',[pos(1)-(60+8*max_length),pos(2)-7,pos(1)-(30+8*max_length),pos(2)+7]);
                    end
                        %fprintf('"inport" created at "%s" subssystem with name "%s" \n',char(sub_list(idx)), char(ports(i).name));
                else
                    % create inport (include '_In')
                    if in_count
                        handle = add_block('built-in/Inport',[model_name,'/',sprintf('%s_In_%d',char(ports(i).name),in_count)],'BackgroundColor','Green','Position',[pos(1)-(60+8*max_length),pos(2)-7,pos(1)-(30+8*max_length),pos(2)+7]);
                    else
                        handle = add_block('built-in/Inport',[model_name,'/',sprintf('%s_In',char(ports(i).name))],'BackgroundColor','Green','Position',[pos(1)-(60+8*max_length),pos(2)-7,pos(1)-(30+8*max_length),pos(2)+7]);
                    end
                    %fprintf('"inport" created at "%s" subssystem with name "%s_In" \n',char(sub_list(idx)), char(ports(i).name));
                end
                in_count = in_count + 1;
                pos_port = get_param(handle,'PortConnectivity');
                handle = add_line(model_name,[pos_port.Position;pos]);
                set_param(handle,'Name',char(ports(i).name));
            end

            if (ports(i).status(2,idx) == 1)
                if(all_out_idx(idx) == 1)
                    pos = get_pos{1,idx}(1 + all_in_idx(idx)).Position;
                else
                    pos = get_pos{1,idx}((find(strcmp(all_outports(idx,:), char(ports(i).name))))+ all_in_idx(idx)).Position;
                end
                if out_count
                    handle = add_block('built-in/Outport',[model_name,'/',sprintf('%s_%d',char(ports(i).name),out_count)],'BackgroundColor','Red','Position',[pos(1)+(30+8*max_length),pos(2)-7,pos(1)+(60+8*max_length),pos(2)+7]);
                else
                    handle = add_block('built-in/Outport',[model_name,'/',char(ports(i).name)],'BackgroundColor','Red','Position',[pos(1)+(30+8*max_length),pos(2)-7,pos(1)+(60+8*max_length),pos(2)+7]);
                end
                out_count = out_count + 1;
                pos_port = get_param(handle,'PortConnectivity');
                add_line(model_name,[pos;pos_port.Position]);
            end
         end
    end
%%
    if integration == 1
        % Create an array of handles to every signal line in the diagram
        signalLines = find_system(model_name,'FindAll','on','SearchDepth', 2,'type','line');

        % Enable or disable the property for each signal line
        for i = 1:length(signalLines)
            set(signalLines(i),'signalPropagation','off');
            set(signalLines(i),'signalPropagation','on');
            waitbar(.9+(0.1*(i/length(signalLines))),bar,sprintf('Updating signal names... (%d/%d)',i,length(signalLines)));
        end
        msgbox({'Integration Completed';'Verify & align signal names';'Verify variables with names tailing "_IN"'},'Success');
    else
        % Create an array of handles to every signal line in the diagram
        signalLines = find_system(model_name,'FindAll','on','SearchDepth', 1,'type','line');

        % Enable or disable the property for each signal line
        for i = 1:length(signalLines)
            set(signalLines(i),'signalPropagation','off');
            set(signalLines(i),'signalPropagation','on');
            waitbar(.9+(0.1*(i/length(signalLines))),bar,sprintf('Updating signal names... (%d/%d)',i,length(signalLines)));
        end
        msgbox({'Port Arrangement Completed';'Verify & align signal names';'Verify variables with names tailing "_IN"'},'Success');
    end
    
    close(bar);
    %clear('i','in_name_string', 'handle','len_sub','pos_block','pos_first','pos_port','signalLines','tag','width','in_temp', 'inport_name', 'inport_split', 'inports', 'outports', 'len_port', 'out_name_string', 'out_temp', 'outport_name', 'outport_split','goto_no','I','idx','in_first','in_last','in_na','list_sorted','offset','out_first','out_last','out_na','path','port_idx','pos','sub','sub_idx','temp');