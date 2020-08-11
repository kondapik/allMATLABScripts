%{
    DESCRIPTION:
	Integrates ASW source code according to ARXML
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 11-Aug-2020
    LAST MODIFIED: 13-Aug-2020
%
    VERSION MANAGER
    v1      First version
%}


classdef codeIntegration < handle
    properties (Access = private)
        framePath
        sourcePath
        integPath
        progBar
        exitFlag
        nvmFlg = 0;
    end

    properties (Access = public)
        %LetsPutASmileOnThatFace = 'ok?';
        AnnieAreYouOk = 'maybe?';
    end

    methods (Access = public)
        function napp = codeIntegration()
            %bdclose('all');
            currFolder = pwd;

            napp.framePath = uigetdir(currFolder,'Select folder with all frame models');
            napp.sourcePath = uigetdir(currFolder,'Select ASW source folder with all delivered models');
            %disp(napp.framePath);
            if isequal(napp.framePath,0) ||  isequal(napp.sourcePath,0)
                %!Folder Not Selected
                msgbox('Ahhhhh, you din''t select any folder and that''s not fair','Error','error');
            else
                % warning('off','MATLAB:rmpath:DirNotFound');
                % rmpath(napp.framePath);
                % warning('on','MATLAB:rmpath:DirNotFound');
                napp.exitFlag = 1;
                copyFiles(napp);
                if napp.exitFlag
                    copySldd(napp);
                end
                if napp.exitFlag
                    reconnectSignals(napp);
                    warning('on','all');
                end
                if napp.exitFlag
                    addStubs(napp);
                end
                if napp.exitFlag
                    add_ports(napp);
                end
                if napp.exitFlag
                    nvmFlg = napp.nvmFlg;
                    save('RootSWComposition_IntegrationData.mat','nvmFlg');
                    close(napp.progBar);
                    msgbox({'ASW Integration Completed';'Use ''replaceInports'' and ''integrationPanel''';'to test ASW root composition'},'Success');
                end
            end 
        end
    end

    methods (Access = private)
        % #define\s*(?<oldFun>\w*)\s*(?<xpFun>\w*) -> get expanded function call

        % (?<funProto>Std_ReturnType\s*\w*\(\s*\w*\**\s*\w*\)) -> get only function prototype
        % Std_ReturnType\s*(?<oldFun>\w*)\(\s*\w*\**\s*(?<funArg>\w*)\) -> get funName and arg
        %! (?<funProto>Std_ReturnType\s*(?<oldFun>\w*)\(\s*\w*\**\s*(?<funArg>\w*)\)) -> get function prototype (doesn't work -> MATLAB doesn't support nested tokens)

        % (?<paramFun>\w*\s*\w*\(\w*\)\s*{\s*return\s*\w*;\s*}) -> get only parameter function definition
        % \w*\s*(?<oldFun>\w*)\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*} ->get funName and return variable
        %! (?<paramFun>\w*\s*(?<oldFun>\w*)\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*}) -> get parameter function definition (doesn't work -> MATLAB doesn't support nested tokens)
    end

    methods (Static)
        
    end
end