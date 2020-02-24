%{
    DESCRIPTION:
	Analyses requirement IDs in document vs those in revision history
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 23-Feb-2020
    LAST MODIFIED: 24-Feb-2020
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
        revNo = 0;
        reqPath
    end

    properties (Access = public)
        %LetsPutASmileOnThatFace = 'sure?';
        %AnnieAreYouOk = 'maybe?';
        allReqHis
        revReq
        Requirements
    end

    methods (Access = public)
        function [napp] = reqAnalysis()
            %bdclose('all');
            currFolder = pwd;

            [docName,napp.reqPath] = uigetfile({'*.doc;*.docx','Word Files (*.doc;*.docx)'},'Select Requirement Document');
            

            %disp(napp.framePath);
            if isequal(docName,0)
                %!File Not Selected
                msgbox('Ahhhhh, you din''t select any file and that''s not fair','Error','error');
            else
                cd(napp.reqPath);
                napp.progBar = waitbar(0,{'Importing requirements(1/4)','Reading word file...'},'Name','Requirement Analysis');
                pos = get(napp.progBar,'Position');
                pos(4) = pos(4) + 20;
                set(napp.progBar,'Position',pos);
                
                napp.exitFlag = 1;
                %* Reading word file
                word = actxserver('Word.Application');
                wdoc = word.Documents.Open([napp.reqPath,docName]);
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

                napp.Requirements = struct('ReqID',{},'Revs',{},'Revisions',{},'Usage',{},'Found',{},'TagErr',{},'RevErr',{},'ExpRev',{});

                allRequirements(napp);

                reqCheck(napp);

                updateResults(napp);

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
                    end

                    if goTo == 1
                        requirementID = napp.revReq(reqIdx).ReqID;
                        regLen = length(requirementID);
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1));
                        lastNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo + 1,lastNo,revHis,revTag);
                    end
                    
                    if length(startPos) > 1 && isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*to\s*<','ONCE'))
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(2) + 1:endPos(2) - 1));
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo,firstNo,revHis,revTag);
                    elseif goTo == 0 && isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*to\s*<','ONCE'))
                        [requirementID, regLen, ~] = napp.getReqId(napp.reqSentences{napp.docIdx}(startPos(1) + 1:endPos(1) - 1));
                        firstNo = str2num(requirementID(regLen - 2 : regLen));
                        [napp.revReq,reqIdx] = napp.reqHistory(napp.revReq,requirementID,reqIdx,firstNo,firstNo,revHis,revTag);
                    end
                    

                    if ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*to(?!\s*<)','ONCE'))
                        %*disp('found out-to');
                        goTo = 1;
                    else
                        goTo = 0;
                    end
                end
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^Table of Contents','ONCE'))
                    %disp('Found Table of Contents');
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
                        waitbar(0.5 + (reqIdx / maxReq)*(0.25),napp.progBar,{'Reading requirement IDs(3/4)','Current Requirement ID',regexprep(requirementID,'_','\\_')});

                        if reqIdx > 1 && ~isempty(find(contains(string({napp.Requirements.ReqID}),requirementID)))
                            msgbox()
                            %!fprintf('Found Duplicate:%s\n',requirementID);
                            msgbox(sprintf('Duplicate Requirement IDs found: %s',regexprep(requirementID,'_','\\_')),'Error','error');
                            exitWhile = 0;
                        else
                            napp.Requirements(reqIdx).ReqID = requirementID;
                            napp.Requirements(reqIdx).Found = 'No';
                            napp.Requirements(reqIdx).Revisions = zeros(1,napp.revNo);
                            if ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*#\s*(D|d)(E|e)(L|l)(E|e)(T|t)(E|e)(D|d)','ONCE'))
                                napp.Requirements(reqIdx).Usage = 'Deleted';
                            elseif ~isempty(regexp(napp.reqSentences{napp.docIdx},'>\s*#\s*(M|m)(O|o)(V|v)(E|e)(D|d)','ONCE'))
                                napp.Requirements(reqIdx).Usage = 'Moved';
                            else
                                napp.Requirements(reqIdx).Usage = 'InUse';
                            end
                            %*fprintf('ID:%s\n',requirementID);
                        end
                    end
                end
                if ~isempty(regexp(napp.reqSentences{napp.docIdx},'^BSW Requirements','ONCE'))
                    %disp('BSW requirements');
                    exitWhile = 0;
                end
            end
        end

        function reqCheck(napp)
            napp.allReqHis = unique({napp.revReq.Revision});
            histIDs = {napp.revReq.ReqID};
            for reqNo = 1 : length(napp.Requirements)
                revHisNo = 0;
                foundIdx = find(contains(string(histIDs),napp.Requirements(reqNo).ReqID));
                waitbar(0.75 + (reqNo / length(napp.Requirements))*(0.25),napp.progBar,{'Analysing requirement IDs(4/4)','Current Requirement ID',regexprep(napp.Requirements(reqNo).ReqID,'_','\\_')});
                if ~isempty(foundIdx)
                    napp.Requirements(reqNo).Found = 'Yes';
                    for histNo = 1 : length(foundIdx)

                        napp.revReq(foundIdx(histNo)).Found = 'Yes';
                        %Criteria to check the revisions of requirements
                        revIdx = find(contains(string(napp.allReqHis),napp.revReq(foundIdx(histNo)).Revision));
                        revIdx = revIdx(1);
                        napp.Requirements(reqNo).Revisions(revIdx) = 1;

                        if isequal(napp.revReq(foundIdx(histNo)).Tag,'Modified') & (revIdx > 3)
                            revHisNo = revHisNo + 1;
                        end

                        if histNo == length(foundIdx)
                            if isequal(napp.revReq(foundIdx(histNo)).Tag,'Deleted')
                                if isequal(napp.Requirements(reqNo).Usage,'Deleted')
                                    napp.Requirements(reqNo).TagErr = 'No Error';
                                else
                                    napp.Requirements(reqNo).TagErr = 'Error';
                                end
                            elseif isequal(napp.revReq(foundIdx(histNo)).Tag,'Moved')
                                if isequal(napp.Requirements(reqNo).Usage,'Moved')
                                    napp.Requirements(reqNo).TagErr = 'No Error';
                                else
                                    napp.Requirements(reqNo).TagErr = 'Error';
                                end
                            else
                                napp.Requirements(reqNo).TagErr = 'No Error';
                            end

                            if isequal(napp.Requirements(reqNo).Revs,revHisNo)
                                napp.Requirements(reqNo).RevErr = 'No Error';
                            else
                                napp.Requirements(reqNo).RevErr = 'Error';
                            end
                            napp.Requirements(reqNo).ExpRev = revHisNo;
                        end
                    end
                else
                    %Considering no error if ID is not found in Revision History
                    napp.Requirements(reqNo).TagErr = 'No Error';
                    napp.Requirements(reqNo).RevErr = 'No Error';
                    napp.Requirements(reqNo).ExpRev = 0;
                end
            end
        end

        function updateResults(napp)
            waitbar(0,napp.progBar,{'Exporting results to Excel'});
            if isfile('requirementAnalysis.xlsx')
                delete('requirementAnalysis.xlsx')
            end

            Excel = actxserver('Excel.Application');
            Ex_Workbook = Excel.Workbooks.Add;
            Ex_Sheets = Excel.ActiveWorkbook.Sheets;
            Ex_actSheet = Ex_Sheets.get('Item',1);
            SaveAs(Ex_Workbook,sprintf('%srequirementAnalysis.xlsx',napp.reqPath));
            Excel.Visible = 1;
            Ex_actSheet.Name = 'Revision History';
            Ex_actSheet.Cells.HorizontalAlignment = -4108;
            Ex_actSheet.Cells.VerticalAlignment = -4108;
            Ex_range = get(Ex_actSheet,'Range','A1');
            Ex_range.Value = 'Requirement ID';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Revision';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Requirement Tag';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Found in Req';
            Ex_range.Interior.ColorIndex = 20;

            for reqNo = 1 : length(napp.revReq)
                waitbar((reqNo / length(napp.revReq))*(0.5),napp.progBar,{'Exporting results to Excel','Current Revision',napp.revReq(reqNo).Revision});
                Ex_range = Ex_range.get('Offset',1,-3);
                Ex_range.Value = napp.revReq(reqNo).ReqID;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.revReq(reqNo).Revision;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.revReq(reqNo).Tag;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.revReq(reqNo).Found;
            end
            Ex_actSheet.Range(sprintf('A1:%s%d',(65 + 3),(reqNo + 1))).Borders.Item('xlInsideHorizontal').LineStyle = 1;
            Ex_actSheet.Range(sprintf('A1:%s%d',(65 + 3),(reqNo + 1))).Borders.Item('xlInsideVertical').LineStyle = 1;

            Ex_range = Ex_range.get('Offset',1,-(3));
            for reqNo = 1:4
                Ex_range.EntireColumn.AutoFit;
                Ex_range = Ex_range.get('Offset',0,1);
            end
            Ex_Workbook.Save;

            Ex_actSheet = Ex_Sheets.Add();
            %Ex_actSheet = Ex_Sheets.get('Item',2);
            Ex_actSheet.Name = 'Requirement Analysis';
            Ex_actSheet.Cells.HorizontalAlignment = -4108;
            Ex_actSheet.Cells.VerticalAlignment = -4108;
            Ex_range = get(Ex_actSheet,'Range','A1');
            Ex_range.Value = 'Requirement ID';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'No of Revisions';
            Ex_range.Interior.ColorIndex = 20;
            for revIdx = 1 : napp.revNo
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = sprintf('Revision: %s', napp.allReqHis{revIdx});
                Ex_range.Interior.ColorIndex = 20;
            end
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Current Usage';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Found in R.Hist';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Tag Error';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Revision Error';
            Ex_range.Interior.ColorIndex = 20;
            Ex_range = Ex_range.get('Offset',0,1);
            Ex_range.Value = 'Exp Revisions';
            Ex_range.Interior.ColorIndex = 20;
            
            for reqNo = 1 : length(napp.Requirements)
                waitbar(0.5+(reqNo / length(napp.Requirements))*(0.5),napp.progBar,{'Exporting results to Excel','Current Requirement ID',regexprep(napp.Requirements(reqNo).ReqID,'_','\\_')});
                Ex_range = Ex_range.get('Offset',1,-(6 + napp.revNo));
                Ex_range.Value = napp.Requirements(reqNo).ReqID;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).Revs;
                for revIdx = 1 : napp.revNo
                    Ex_range = Ex_range.get('Offset',0,1);
                    Ex_range.Value = napp.Requirements(reqNo).Revisions(revIdx);
                end
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).Usage;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).Found;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).TagErr;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).RevErr;
                Ex_range = Ex_range.get('Offset',0,1);
                Ex_range.Value = napp.Requirements(reqNo).ExpRev;
            end

            Ex_actSheet.Range(sprintf('A1:%s%d',(65 + 6 + napp.revNo),(reqNo + 1))).Borders.Item('xlInsideHorizontal').LineStyle = 1;
            Ex_actSheet.Range(sprintf('A1:%s%d',(65 + 6 + napp.revNo),(reqNo + 1))).Borders.Item('xlInsideVertical').LineStyle = 1;

            Ex_range = Ex_range.get('Offset',1,-(6 + napp.revNo));
            for reqNo = 1: (7+ napp.revNo)
                Ex_range.EntireColumn.AutoFit;
                Ex_range = Ex_range.get('Offset',0,1);
            end

            Ex_Workbook.Save;
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
