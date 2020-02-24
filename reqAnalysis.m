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
        reqSentences
        docIdx
        progBar
    end

    properties (Access = public)
        %LetsPutASmileOnThatFace = 'sure?';
        %AnnieAreYouOk = 'maybe?';
        revNo = 0;
        revReq
        Requirements
    end

    methods (Access = public)
        function [napp] = reqAnalysis()
            %bdclose('all');
            currFolder = pwd;

            [docName,reqPath] = uigetfile({'*.doc;*.docx','Word Files (*.doc;*.docx)'},'Select Requirement Document');
            cd(reqPath);

            %disp(napp.framePath);
            if isequal(docName,0)
                %!File Not Selected
                msgbox('Ahhhhh, you din''t select any file and that''s not fair','Error','error');
            else
                napp.progBar = waitbar(0,{'Importing requirements(1/4)','Reading word file...'},'Name','Requirement Analysis');
                napp.exitFlag = 1;
                %* Reading word file
                word = actxserver('Word.Application');
                wdoc = word.Documents.Open([reqPath,docName]);
                reqText = wdoc.Content.Text;
                word.Quit;
                reqText = regexprep(reqText,'[^A-Za-z0-9\n\r.\/\-,%''": =\t()<>_#\[\]]','');
                %* Completed reading word file
                waitbar(0.25,napp.progBar,{'Reading revision history(2/4)',sprintf('Reading revision history')});
                napp.reqSentences = strsplit(reqText,{'\n','\r'});
                napp.docIdx = 0;
                exitWhile = 1;
                while exitWhile
                    napp.docIdx = napp.docIdx + 1;
                    if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^Revision History','ONCE'))
                        %* Reading Revision History
                        exitWhile = 0;
                    end
                end


                %<\w*> -> just the requirement
                %>\s*to -> > to
                %>\s*to(?!\s*<) -> > to *(not foloowed by <) 
                %>\s*to\s*< -> > to <
                napp.revReq = struct('ReqID',{},'Revision',{},'Tag',{},'Found',{});
                readingHistory(napp);

                exitWhile = 1;
                while exitWhile
                    napp.docIdx = napp.docIdx + 1;
                    if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^ASW Requirements','ONCE'))
                        %*disp('ASW requirements');
                        exitWhile = 0;
                    end
                end

                napp.Requirements = struct('ReqID',{},'Revs',{},'Revisions',{},'Deleted',{},'Found',{});

                allRequirements(napp);

                close(napp.progBar);
                msgbox({'Done';'Done Dana Done'},'Success');
                cd(currFolder);
            end 
        end
    end

    methods (Access = private)
        function readingHistory(napp)
            reqIdx = 0;
            revHis = 0;
            revTag = 'New';
            goTo = 0;
            exitWhile = 1;
            while exitWhile
                napp.docIdx = napp.docIdx + 1;
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^\d.\d','ONCE'))
                    %*fprintf('Found Revision History:%s\n',napp.reqSentences{napp.docIdx});
                    revHis = strip(napp.reqSentences{napp.docIdx});
                    napp.revNo = napp.revNo + 1;
                    waitbar(0.25 + (napp.revNo / 7)*(0.25),napp.progBar,{'Reading revision history(2/4)',sprintf('Current revision: %s...',revHis)});
                end
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^\s*\(N\)','ONCE'))
                    %disp('New requirements');
                    revTag = 'New';
                elseif ~isempty(regexp(napp.reqSentences{napp.docIdx},'^\s*\(M\)','ONCE'))
                    %disp('Modified requirements');
                    revTag = 'Modified';
                elseif ~isempty(regexp(napp.reqSentences{napp.docIdx},'^\s*\(D\)','ONCE'))
                    %disp('Deleted requirements');
                    revTag = 'Deleted';
                elseif ~isempty(regexp(napp.reqSentences{napp.docIdx},'^\s*\(Moved\)','ONCE'))
                    %disp('Moved requirements');
                    revTag = 'Moved';
                end

                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'<\w*>','ONCE'))
                    [startPos,endPos] = regexp(napp.reqSentences{napp.docIdx},'<\w*>');

                    if (length(startPos) > 1) && ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*to\s*<','ONCE'))
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1));
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(2) + 1:endPos(2) - 1));
                        lastNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo,lastNo,revHis,revTag);
                    elseif goTo == 1
                        requirementID = napp.revReq(reqIdx).ReqID;
                        regLen = length(requirementID);
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1));
                        lastNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo + 1,lastNo,revHis,revTag);
                        goTo = 0;
                    elseif length(startPos) > 1
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(2) + 1:endPos(2) - 1));
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo,firstNo,revHis,revTag);
                    else
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1));
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo,firstNo,revHis,revTag);
                    end

                    if ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*to(?!\s*<)','ONCE'))
                        %*disp('found out-to');
                        goTo = 1;
                    end
                end
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^Table of Contents','ONCE'))
                    disp('Found Table of Contents');
                    exitWhile = 0;
                end
            end
        end

        function allRequirements(napp)
            maxReq = 700;
            reqIdx = 0;
            exitWhile = 1;
            while exitWhile
                napp.docIdx = napp.docIdx + 1;
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'<\w*>','ONCE'))
                    [startPos,endPos] = regexp(napp.reqSentences{napp.docIdx},'<\w*>');
                    requirementID = napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1);

                    if ~strcmpi(strip(requirementID),'Information')
                        reqIdx = reqIdx + 1;
                        [requirementID, ~, napp.Requirements(reqIdx).Revs] = napp.getReqId(requirementID);
                        napp.Requirements(reqIdx).ReqID = 'ID';
                        waitbar(0.5 + (reqIdx / maxReq)*(0.25),napp.progBar,{'Reading requirement IDs(3/4)',sprintf('Current Requirement ID: %s...',requirementID)});

                        if reqIdx > 1 && ~isempty(find(contains(string({napp.Requirements.ReqID}),requirementID)))
                            %!fprintf('Found Duplicate:%s\n',requirementID);
                            exitWhile = 0;
                        else
                            napp.Requirements(reqIdx).ReqID = requirementID;
                            napp.Requirements(reqIdx).Found = 'No';
                            napp.Requirements(reqIdx).Revisions = zeros(1,napp.revNo);
                            if ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*#\s*(D|d)(E|e)(L|l)(E|e)(T|t)(E|e)(D|d)','ONCE'))
                                napp.Requirements(reqIdx).Deleted = 'Deleted';
                            else
                                napp.Requirements(reqIdx).Deleted = 'InUse';
                            end
                            %*fprintf('ID:%s\n',requirementID);
                        end
                    end
                end
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^BSW Requirements','ONCE'))
                    disp('BSW requirements');
                    exitWhile = 0;
                end
            end
        end
    end

    methods (Static)
        function [filteredName, nameLen, extNo] = getReqId(unfilteredName)
            nameLen = length(unfilteredName);
            if isequal(unfilteredName(nameLen - 2),'_')
                extNo = str2num(unfilteredName(nameLen - 1 : nameLen));
                filteredName = unfilteredName(1 : nameLen - 3);
                nameLen = nameLen - 3;
            else
                extNo = 0;
                filteredName = unfilteredName;
            end
        end

        function [revReq,reqIdx] = reqHistory(revReq,requirementID,reqIdx,firstNo,lastNo,revHis,revTag)
            for reqNo = firstNo:lastNo
                reqIdx = reqIdx + 1;
                revReq(reqIdx).ReqID = sprintf('%s%03d',requirementID(1:length(requirementID)-3),reqNo);
                revReq(reqIdx).Revision = revHis;
                revReq(reqIdx).Tag = revTag;
                revReq(reqIdx).Found = 'No';
                %*fprintf('Revision:%s,\t ID:%s\n',revHis,requirementID);
            end
        end
    end
end