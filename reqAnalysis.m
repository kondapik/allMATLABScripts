%{
    DESCRIPTION:
	Analyses requirement IDs in document vs those in revision history
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 23-Feb-2020
    LAST MODIFIED: 23-Feb-2020
%
    VERSION MANAGER
    v1      
%}


classdef reqAnalysis < handle
    properties (Access = private)
        exitFlag
    end

    properties (Access = public)
        LetsPutASmileOnThatFace = 'sure?';
        %AnnieAreYouOk = 'maybe?';
    end

    methods (Access = public)
        function napp = reqAnalysis()
            %bdclose('all');
            currFolder = pwd;

            napp.framePath = uigetdir(currFolder,'Select folder with all frame models');
            napp.sourcePath = uigetdir(currFolder,'Select ASW source folder with all delivered models');
            %disp(napp.framePath);
            if isequal(napp.framePath,0) ||  isequal(napp.sourcePath,0)
                %!Folder Not Selected
                msgbox('Ahhhhh, you din''t select any folder and that''s not fair','Error','error');
            else
                napp.exitFlag = 1;
            end 
        end
    end

    methods (Access = private)
        
    end

    methods (Static)
        
    end
end