function [] = code_analysis()
%%
%	
%clear
%%
%   CREATED BY : Kondapi V S Krishna Prasanth
%   DATE OF CREATION: 8-July-2018
%%
%   VERSION MANAGER
%   v1. Creation of script to extract called functions and local functions.
%   v2. Fixed bug in removing comments (bug: code after first // is removed), fixed duplicate in result and updated the script for export to excel
%	v3. Fixed the bug which prevents a match when function is preceded by special charecter
%   v4. Fixed the bug which considers return as a datatype

%%
    file_name = 0;
    while(file_name == 0)
        [file_name,folder_path] = uigetfile('*.c','Select C code');
        if file_name == 0
            msgbox({'File not opened'},'Error','error');
            %quit
            error('Are you kidding me');
        else
            fileID = -1;
            errmsg = '';
            while fileID < 0 
               disp(errmsg);
               [fileID,errmsg] = fopen(strjoin({folder_path,file_name},''));
            end
            file_info = dir(strjoin({folder_path,file_name},''));
            if file_info.bytes == 0
                file_name = 0;
                msgbox({'File is empty'},'Error','error');
            end
        end
    end
    
    [data,~] = fscanf(fileID,'%c');
    %disp(data);
    
%%  removing all the comments
    
    %data = regexprep(data,'(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)','');
    %data = regexprep(data,'(/\*(.|[\r\n])*?\*+/)|(//.*)',''); % removing comments
    data = regexprep(data,'(/\*(.|[\r\n])*?\*+/)|(//[^\r\n]*)',''); % removing comments
    
    %disp(data);
    %data_new = regexprep(data,'//*.*/*/)','') '/\*(.|[\r\n])*\*+/'
    
%%  extracting called function list (both local and global)
    
    %[startIndex,endIndex] = regexp(data,'[^(void)(uint8)(static)(for)(if)(while)][ \t]\w+?\(');
    %[^(void)(uint8)(static)(for)(if)(while)][ \t]\w+?\( 
    %[(void)(uint8)(static)] (\w+?)\(
    %[^(void)(uint32)(static)(inline)(enum)(for)(if)(while)(eSPICY_STATE)][ \t]((?!(if|elseif|while|for))\w+?)\(
    %[^(void)(uint8)(static)(inline)(enum)(eSPICY_STATE)(for)(if)(while)][ \t](\w+?)\(
    %([\W][ \t])+?((?!(if|elseif|while|for|return|switch|(\s[A-Z_0-9]+[ \(])))\w+?)(\(| \()
    %\s([A-Z_0-9]+)[ \(]
    
    %called_functions = regexp(data,'[^(void)(uint32)(static)(inline)(enum)(for)(if)(while)(eSPICY_STATE)][ \t]((?!(if|elseif|while|for|return))\w+?)\(','tokens');
    called_functions = regexp(data,'([\W])+?((?!(if|elseif|while|for|switch|return))\w+?)(\(| +\()','tokens');
    for i = 1:length(called_functions)
        called_functions(i) = cellstr(called_functions{i}{2});
    end
    called_functions = unique(called_functions);
    %called_functions(ismember(called_functions,'if')) = [];
    
    macro_functions = regexp(data,'\s([A-Z_0-9]+)(\(| +\()','tokens');
    for i = 1:length(macro_functions)
        macro_functions(i) = cellstr(macro_functions{i}{1});
    end
    macro_functions = unique(macro_functions);
    called_functions = setdiff(called_functions,macro_functions);
    
%%  extracting local functions (declared or defined)
    
%     local_functions = regexp(data,'[(void)(uint8)(uint32)(static)(inline)(eSPICY_STATE)(enum)] ((?!(if|elseif|while|for))\w+?)\(','tokens');
%     for i = 1:length(local_functions)
%         local_functions(i) = cellstr(local_functions{i}{1});
%     end
%     local_functions = unique(local_functions);
    
%%  extracting the fuction prototypes
    %void unit8 uint16 uint32 float float32 boolean sint8 sint16 sint32 bool enum
    %([ \t]*?(static|void|uint32|inline|enum|bool|eSPICY_STATE)[ \t])+?((?!(if|elseif|while|for))\w+?)\((.|[\r\n])+?\)
    %([ \t]*?(static|void[\*]?|float[32\*]*?|[su]int[32168\*]*?|inline|enum|bool[ean]?|\w+?)[ \t])+?((?!(if|elseif|while|for))\w+?)\((.|[\r\n])+?\)
    %([ \t]*?([\w\*]+?)[ \t])+?((?!(if|elseif|while|for))\w+?)\((.|[\r\n])+?\)
    %([ \t]*?([\w\*]+?)[ \t])+?((?!(if|elseif|while|for|switch|return))\w+?) *\((.|[\r\n])+?\)
    %([ \t]*?((?!(return|eturn|turn|urn|rn|n)+)[\w\*]+?)[ \t])+?((?!(if|elseif|while|for|switch|return))\w+?)\((.|[\r\n])+?\)
    %([ \t]*?([\w\*]+?)(?<!return)[ \t])+?((?!(if|elseif|while|for|switch|return))\w+?)\((.|[\r\n])+?\)
    [prototype_matches,prototype_tokens] = regexp(data,'([ \t]*?([\w\*]+?)(?<!return)[ \t])+?((?!(if|elseif|while|for|switch|return))\w+?)\((.|[\r\n])+?\)','match','tokens');
    prototype_matches = cellfun(@(x)regexprep(x,'( |[\r\n]){2,}',' '), prototype_matches,'UniformOutput',false);
    
    %function_prototypes = unique(function_prototypes);
    
    local_functions = struct('name',{},'prototype',{}); % Strucuture definition for local functions
    
    for i = 1:length(prototype_matches)
        function_idx = find(strcmp({local_functions.name}, prototype_tokens{1,i}{1,2}));
        if (isempty(function_idx)) % checking of strucure for port name is created
            % creating strucutre for local functions if not available
            len_function = length(local_functions);
            function_idx = len_function + 1;
            local_functions(function_idx).name = prototype_tokens{1,i}{1,2};
            local_functions(function_idx).prototype = prototype_matches(i);
        end
    end
    
%    local_functions = setdiff(local_functions,macro_functions);
%%      
    only_called_functions = reshape(setdiff(called_functions,{local_functions.name}),[],1);
    
%%
    excel_name = strsplit(file_name,'.');
    excel_name = sprintf('functionlist_%s.xlsx',char(excel_name(1)));
    warning('off','all');
    delete(excel_name);
    warning('on','all');
    warning('off','MATLAB:xlswrite:AddSheet');
    xlswrite(excel_name,{'Local Function Name'},'Local Functions','A1');
    xlswrite(excel_name,{'Local Function Prototype'},'Local Functions','B1');
    xlswrite(excel_name,reshape({local_functions.name},[],1),'Local Functions','A2');
    xlswrite(excel_name,reshape([local_functions.prototype],[],1),'Local Functions','B2');
    
    xlswrite(excel_name,{'Called Functions'},'Called Functions','A1');
    xlswrite(excel_name,only_called_functions,'Called Functions','A2');
       