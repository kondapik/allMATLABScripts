%{
    DESCRIPTION:
	Reads requirements and simulink requirement
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 16-Jun-2020
    LAST MODIFIED: 16-Jun-2020
%
    VERSION MANAGER
    v1      First Draft
%}


classdef doc2Sim < handle
    properties (Access = private)
        fileName;
        rootPath;
        reqText;
        reqSet;
        setReqs;
        setReqIds;

        nvmFlg = 0;
    end

    properties (Access = public)
        %LetsPutASmileOnThatFace = 'ok?';
        reqData;
        noOfReq = 0;
    end

    methods (Access = public)
        function napp = doc2Sim()
            currFolder = pwd;

            [napp.fileName,napp.rootPath] = uigetfile({'*.txt','Text File (*.txt)'},'Select requirement text file');

            if isequal(napp.fileName,0)
                %!Folder Not Selected
                msgbox('You cant expect to import non existent requirements, that''s not fair','Error','error');
            else
                cd(napp.rootPath);
                napp.reqText = fileread(napp.fileName);

                fprintf('Reading Requirements...');
                readReq(napp);
                fprintf('Done\n');

                disp('Loading requirements in matlab...');
                updateReq(napp);

                disp('We are done, You can update summary');
            end
            cd(currFolder)
        end
    end

    methods (Access = private)
        
        %readReq: Read 
        function readReq(napp)
            napp.reqData  = struct('Tag',{},'Description',{},'Type',{},'UseCase',{});

            [startIndices,stopIndices] = regexpi(napp.reqText,'<\w*>');

            for idxNo = 1 : length(startIndices)
                napp.reqData(idxNo).Tag = napp.reqText(startIndices(idxNo) + 1: stopIndices(idxNo) - 1);

                if  idxNo == length(startIndices)
                    napp.reqData(idxNo).Description = strip(napp.reqText(stopIndices(idxNo) + 1 : length(napp.reqText)));
                else
                    napp.reqData(idxNo).Description = strip(napp.reqText(stopIndices(idxNo) + 1: startIndices(idxNo + 1) - 1));
                end

                if ~isempty(regexpi(napp.reqData(idxNo).Tag,'Information'))
                    napp.reqData(idxNo).Type = 'Informational';
                    %add(reqSet,'Type','Informational','Id','Infomation','Description',reqStruct(idxNo).Description,'Summary',reqStruct(idxNo).Description);
                else
                    napp.reqData(idxNo).Type = 'Functional';
                    useCaseName = regexp(napp.reqData(idxNo).Tag,'MCB_SWRS_ASW_(?<model>\w*)_\d{3}','names');
                    napp.reqData(idxNo).UseCase = useCaseName.model;

                    napp.noOfReq = napp.noOfReq + 1;
                end
            end

            infCount = 0;
            for idxNo = 1 : length(startIndices)
                if isempty(napp.reqData(idxNo).UseCase)
                    infCount = infCount + 1;
                else
                    if infCount > 0
                        for cntNo = infCount : -1 : 1
                            napp.reqData(idxNo - cntNo).UseCase = napp.reqData(idxNo).UseCase;
                        end
                        infCount = 0;
                    end
                end
            end
        end

        %readReq: Read 
        function updateReq(napp)

            loadSets(napp,napp.reqData(1).UseCase);

            for idxNo = 1 : length(napp.reqData)
                if (idxNo ~= 1) && ~isequal(napp.reqData(idxNo).UseCase,napp.reqData(idxNo - 1).UseCase)
                    save(napp.reqSet);
                    close(napp.reqSet);
                    fprintf('Loading %s requirements\n',napp.reqData(idxNo).UseCase);
                    loadSets(napp,napp.reqData(idxNo).UseCase);
                end

                if length(napp.reqData(idxNo).Tag) > (13 + length(napp.reqData(idxNo).UseCase) + 4)
                    reqId = napp.reqData(idxNo).Tag(1 : (13 + length(napp.reqData(idxNo).UseCase) + 4));
                else
                    reqId = napp.reqData(idxNo).Tag;
                end
                %disp(reqId);
                if ~isempty(napp.setReqIds)
                    foundIdx = find(contains(napp.setReqIds, reqId));
                else
                    foundIdx = cell.empty(0);
                end

                if isempty(foundIdx)
                    add(napp.reqSet,'Type',napp.reqData(idxNo).Type,'Id',napp.reqData(idxNo).Tag,'Description',napp.reqData(idxNo).Description,'Summary',napp.reqData(idxNo).Description);
                else
                    napp.setReqs(foundIdx).Id = napp.reqData(idxNo).Tag;
                    napp.setReqs(foundIdx).Description = napp.reqData(idxNo).Description;
                    napp.setReqs(foundIdx).Summary = napp.reqData(idxNo).Description;
                end
            end 
        end

        function loadSets(napp,useCase)
            if exist([useCase '.slreqx']) == 0
                napp.reqSet = slreq.new(useCase);
            else
                napp.reqSet = slreq.load(useCase);

                allReq = find(napp.reqSet,'Type','Requirement','Id','Information');
                for Idx = 1 : length(allReq)
                    remove(allReq(Idx));
                end
                save(napp.reqSet);

                napp.setReqs = find(napp.reqSet,'Type','Requirement');
                napp.setReqIds = {napp.setReqs.Id};
            end
        end
    end
end