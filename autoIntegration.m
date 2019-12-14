%{
    DESCRIPTION:
	Integrates source models with composition frame models from ARXML
%
    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 12-Nov-2019
    LAST MODIFIED: 16-Nov-2019
%
    VERSION MANAGER
    v1      Completes Step 1 and Step 2 of integration procedure
    v1.1    Checks for input signals to all referenced models not just InProc
    v1.2    InProc_Misc and OutProc_Misc support with nvmFlg saved to mat file
            Copies user created Enum definitions to root param data dictionary 
%}


classdef autoIntegration < handle
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
        function napp = autoIntegration()
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
        
        %copyFiles: replace frame models with source models and data dictionaries in a separate 'IntegratedSoftware' folder  
        function copyFiles(napp)
            cd(napp.framePath);
            cd ../
            currFolder = pwd;

            napp.progBar = waitbar(0,{'Copying source files(1/5)','Collecting file details...'},'Name','ASW Integration');
            folderNo = 1;
            while folderNo
                [status, msg, ~] = mkdir(sprintf('IntegratedSoftware_%d',folderNo));
                if isempty(msg)
                    napp.integPath = fullfile(currFolder,sprintf('IntegratedSoftware_%d',folderNo));
                    folderNo = 0;
                elseif status == 1
                    folderNo = folderNo + 1;
                else
                    napp.exitFlag = 0;
                    msgbox({sprintf('Unable to create integration folder ''IntegrationSoftware_%d''',folderNo),'Delete any existing folder and try again?'},'Error','error');
                    error('Unable to create integration folder ''IntegrationSoftware_%d''. Delete any existing folder and try again?',folderNo);
                    %!Unable to create new folder for integrated models
                end
            end
            
            allFrmMdl = dir(fullfile(napp.framePath,'*.slx'));
            allSrcMdl = dir(fullfile(napp.sourcePath,'**','*.slx'));
            allSrcSldd = dir(fullfile(napp.sourcePath,'**','*.sldd'));
            %assignin('base','allFrmMdl',allFrmMdl);
            %assignin('base','allSrcMdl',allSrcMdl);
            %assignin('base','allSrcSldd',allSrcSldd);
            
            
            %status = copyfile(fullfile(napp.framePath,'RootSWComposition.sl*'),napp.integPath);
            allSrcMdlNames = {allSrcMdl.name};

            %copy all models to IntegratedSoftware
            for mdlNo = 1:length(allFrmMdl)

                waitbar(0.5*(mdlNo/length(allFrmMdl)),napp.progBar,{'Copying source files(1/5)',sprintf('Copying ''%s''...',regexprep(allFrmMdl(mdlNo).name,'_','\\_'))});
                foundStat = 0;

                srcIndex = find(ismember(allSrcMdlNames,allFrmMdl(mdlNo).name),1);
                if isempty(srcIndex)
                else
                    foundStat = 1;
                    status = copyfile(fullfile(allSrcMdl(srcIndex).folder,'*.slx'),napp.integPath);
                end

                if isequal(allFrmMdl(mdlNo).name,'RootSWComposition.slx') || isequal(allFrmMdl(mdlNo).name,'OutProc.slx') || isequal(allFrmMdl(mdlNo).name,'InProc.slx') ||...
                    isequal(allFrmMdl(mdlNo).name,'OutProc_Misc.slx') || isequal(allFrmMdl(mdlNo).name,'InProc_Misc.slx')
                    status = copyfile(fullfile(napp.framePath,allFrmMdl(mdlNo).name),napp.integPath);
                    foundStat = 1;
                    if isequal(allFrmMdl(mdlNo).name,'OutProc_Misc.slx') || isequal(allFrmMdl(mdlNo).name,'InProc_Misc.slx')
                        napp.nvmFlg = 1;
                    end
                end
                if status == 0
                    napp.exitFlag = 0;
                    close(napp.progBar);
                    msgbox({sprintf('Unable to copy ''%s''',allFrmMdl(mdlNo).name),'Delete any created folders, restart MATLAB and try again?'},'Error','error');
                    error('Unable to copy ''%s''. Delete any created folders, restart MATLAB and try again?',allFrmMdl(mdlNo).name);
                    %!Unable to copy file
                end
                if foundStat == 0
                    %!Unable to find model in source path
                    close(napp.progBar);
                    msgbox({sprintf('Unable to find ''%s'' in source folder',allFrmMdl(mdlNo).name),'Try again with "actual" path of source files'},'Error','error');
                    error('Unable to find ''%s'' in source folder. Try again with "actual" path of source files',allFrmMdl(mdlNo).name);
                end
            end

            %Create temp SLDD folder
            folderNo = 1;
            while folderNo
                [~, msg, ~] = mkdir('tempSLDD');
                if isempty(msg)
                    folderNo = 0;
                else
                    rmdir('tempSLDD','s');
                end
            end
            
            %Copy root SLDD to 'tempSLDD'
            status = copyfile(fullfile(napp.framePath,'*.sldd'),fullfile(currFolder,'tempSLDD'));
            if status == 0
                %!Unable to copy file
                close(napp.progBar);
                msgbox({'Unable to copy root SLDD files from frame model path','Try again after restarting MATLAB?'},'Error','error');
                error('Unable to copy root SLDD files from frame model path. Try again after restarting MATLAB?');
            end

            %Copy all SLDD s to 'tempSLDD'
            for slddNo = 1:length(allSrcSldd)
                waitbar(0.5+0.5*(slddNo/length(allSrcSldd)),napp.progBar,{'Copying source files(1/5)',sprintf('Copying ''%s''...',regexprep(allSrcSldd(slddNo).name,'_','\\_'))});
                status = copyfile(fullfile(allSrcSldd(slddNo).folder,allSrcSldd(slddNo).name),fullfile(currFolder,'tempSLDD')); 
                if status == 0
                    %!Unable to copy file
                    close(napp.progBar);
                    msgbox({sprintf('Unable to copy ''%s''',allSrcSldd(slddNo).name),'Delete any created folders, restart MATLAB and try again?'},'Error','error');
                    error('Unable to copy ''%s''. Delete any created folders, restart MATLAB and try again?',allSrcSldd(slddNo).name);
                end
            end
        end

        %copySldd: copying parameters from source SLDD s to root parameter SLDD  
        function copySldd(napp)
            cd(napp.framePath);
            cd ../tempSLDD
            currFolder = pwd;
            allSldd = dir('*.sldd');
            srcIndex = find(ismember({allSldd.name},'RootSWComposition.sldd'),1);
            allSldd = vertcat(allSldd(1:srcIndex-1),allSldd(srcIndex+1:end)); %removing root SLDD from list

            waitbar(0,napp.progBar,{'Copying parameters(2/5)','Creating data dictionary for parameters'});
            % Creating parameter data dictionary
            paramDictObj = Simulink.data.dictionary.create('RootSWComposition_param.sldd');
            paramDictSec = getSection(paramDictObj,'Design Data');
            
            for slddNo = 1:length(allSldd)
                if ~contains(allSldd(slddNo).name,'_param.sldd','IgnoreCase',true) %all parameter SLDD s will be linked to model SLDD
                    srcDictObj = Simulink.data.dictionary.open(allSldd(slddNo).name);
                    srcDictSec = getSection(srcDictObj,'Design Data');

                    foundEntries = find(srcDictSec,'-value','-class','Simulink.Parameter');
                    extraEnums = find(srcDictSec,'-value','-class','Simulink.data.dictionary.EnumTypeDefinition'); %User defined Enums Eg., Mode management
                    for entryNo = 1:length(extraEnums)
                        if ~contains({extraEnums(entryNo).Name},'ADTS_','IgnoreCase',true)
                            foundEntries(end+1) = extraEnums(entryNo);
                        end
                    end

                    for entryNo = 1:length(foundEntries)
                        if exist(paramDictSec,foundEntries(entryNo).Name)
                            close(napp.progBar);
                            msgbox({sprintf('''%s'' parameter is duplicated in',foundEntries(entryNo).Name),...
                                    sprintf('''%s'' data dictionary. Change its name and try again',allSldd(slddNo).name)},'Error','error');
                            error('''%s'' parameter is duplicated in ''%s'' data dictionary. Change its name and try again',foundEntries(entryNo).Name,allSrcSldd(slddNo).name);
                        else
                            waitbar(((slddNo*entryNo)/(length(allSldd)*length(foundEntries))),napp.progBar,...
                            {'Copying parameters(2/5)',sprintf('Copying ''%s'' parameter',regexprep(foundEntries(entryNo).Name,'_','\\_'))});
                            addEntry(paramDictSec,foundEntries(entryNo).Name,getValue(foundEntries(entryNo)));
                        end
                    end

                    if isequal(allSldd(slddNo).name,'MdMgmt.sldd')
                        %Getting configuration from Mode Management data dictionary in list
                        srcSectConfig = getSection(srcDictObj,'Configurations');
                        configEntry = find(srcSectConfig);
                        configSet = getValue(configEntry);
                        set_param(configSet,'StopTime','inf');
                        setValue(configEntry,configSet);
                        saveChanges(srcDictObj);
                    end
                end
            end

            waitbar(1,napp.progBar,{'Copying parameters(2/5)','Saving and moving SLDDs to integration folder'});
            %Deleting simulink parameters created by frame model for InProc and OutProc
            rootDictObj = Simulink.data.dictionary.open('RootSWComposition.sldd');
            rootDictSec = getSection(rootDictObj,'Design Data');
            foundEntries = find(rootDictSec,'-value','-class','Simulink.Parameter');
            for entNo = 1:length(foundEntries)
                deleteEntry(foundEntries(entNo));
            end

            %Adding configuration to root param data dictionary
            paramSectConfig = getSection(paramDictObj,'Configurations');
            addEntry(paramSectConfig,configEntry(1).Name,getValue(configEntry(1)));

            %Linking root and root param data dictionaries
            addDataSource(rootDictObj,'RootSWComposition_param.sldd');
            addDataSource(paramDictObj,'RootSWComposition.sldd');

            saveChanges(rootDictObj);
            saveChanges(paramDictObj);
            Simulink.data.dictionary.closeAll;

            %Copy root SLDD s back to integration folder
            status = copyfile(fullfile(currFolder,'RootSWComposition*.sldd'),napp.integPath);
            if status == 0
                %!Unable to copy file
                close(napp.progBar);
                msgbox({'Unable to copy SLDDs to integration folder','Delete any created folders, restart MATLAB and try again?'},'Error','error');
                error('Unable to copy SLDDs to integration folder. Delete any created folders, restart MATLAB and try again?');
            end

            cd ../
            rmdir('tempSLDD','s');
        end

        %reconnectSignals
        function reconnectSignals(napp)
            cd(napp.integPath);

            warning('off','all');
            
            waitbar(0,napp.progBar,{'Updating model references(3/5)','Loading models'});

            %Creating configuration reference
            rootDictObj = Simulink.data.dictionary.open('RootSWComposition.sldd');
            rootSectConfig = getSection(rootDictObj,'Configurations');
            configEntry = find(rootSectConfig);
            configSet = getValue(configEntry);
            cref = Simulink.ConfigSetRef;
            cref.Name = 'IntegRefConfig';
            cref.SourceName = configSet.Name;

            %List of compositions
            modelNames = {'InProc','OutProc','RootSWComposition'};
            %miscBlocks = {'InProc_Misc','OutProc_Misc'};
            allRefNo = zeros(length(modelNames),1);
            allRefNames = cell.empty(length(modelNames),0);
            %fillItUp(systemName)
            for mdlNo = 1:length(modelNames)
                load_system(modelNames{mdlNo});

                refBlocks = find_system(modelNames{mdlNo},'SearchDepth',1,'BlockType','ModelReference');
                allRefNo(mdlNo) = length(refBlocks);

                allHandle = getSimulinkBlockHandle(refBlocks);
                allPos = get_param(allHandle,'Position');

                extremes = zeros(2,length(allPos));
                for i = 1:length(allPos)
                    extremes(1,i) = allPos{i}(1);
                    extremes(2,i) = allPos{i}(2);
                end

                %creating function call generator and splitter
                if mdlNo == length(modelNames)
                    refPosition(1) = min(extremes(1,:));
                    refPosition(2) = min(extremes(2,:));
                    refNo = sum(allRefNo) - 2;

                    add_block('simulink/Ports & Subsystems/Function-Call Split','RootSWComposition/FunCallSplit','NumOutputPorts',num2str(refNo),...
                                'Position',[refPosition(1)-(40+20) refPosition(2)-(40+20*refNo) refPosition(1)-(40) refPosition(2)-(40)]);
                    
                    add_block('simulink/Ports & Subsystems/Function-Call Generator','RootSWComposition/FunCallGen','sample_time','0.01',...
                                'Position',[refPosition(1)-(40+20+40+20) refPosition(2)-(40+10*refNo+11) refPosition(1)-(40+20+40) refPosition(2)-(40+10*refNo-11)]);
                    
                    add_line('RootSWComposition',{'FunCallGen/1'},{'FunCallSplit/1'},'autorouting','on');

                    %setting config reference to compositions
                    set_param(modelNames{mdlNo},'DataDictionary','RootSWComposition.sldd');
                    attachConfigSet(modelNames{mdlNo},cref,true);
                    setActiveConfigSet(modelNames{mdlNo},'IntegRefConfig');
                end

                rnblNo = 0;
                for blkNo = 1:length(refBlocks)
                    allRefNames{mdlNo,blkNo} = get_param(refBlocks{blkNo},'Name');
                    waitbar(((mdlNo*blkNo)/(length(modelNames)*length(refBlocks))),napp.progBar,...
                            {'Updating model references(3/5)',sprintf('Updating ''%s'' model',regexprep(allRefNames{mdlNo,blkNo},'_','\\_'))});
                    %napp.nvmFlg = 1;
                    load_system(allRefNames{mdlNo,blkNo});
                    if isequal(allRefNames{mdlNo,blkNo},'OutProc_Misc') || isequal(allRefNames{mdlNo,blkNo},'InProc_Misc')
                        napp.nvmFlg = 1;
                        napp.fillItUp(allRefNames{mdlNo,blkNo});
                    end
                    set_param(allRefNames{mdlNo,blkNo},'DataDictionary','RootSWComposition.sldd');
                    save_system(allRefNames{mdlNo,blkNo});
                    load_system(allRefNames{mdlNo,blkNo});
                    cRefCopy = attachConfigSetCopy(allRefNames{mdlNo,blkNo},cref,true);
                    setActiveConfigSet(allRefNames{mdlNo,blkNo},cRefCopy.Name);
                    close_system(allRefNames{mdlNo,blkNo},1);
                    lineHandles = get_param(refBlocks{blkNo},'LineHandles');
                    lineHandles = lineHandles.Inport;

                    portHandles = get_param(refBlocks{blkNo},'PortHandles');
                    portHandles = portHandles.Inport;
                    if lineHandles(end) == -1
                        for lineNo = 1:(length(lineHandles)-1)
                            srcPort = get_param(lineHandles(end-lineNo),'SrcPortHandle');
                            delete_line(lineHandles(end-lineNo));
                            add_line(modelNames{mdlNo},srcPort,portHandles(end-lineNo+1),'autorouting','on');
                        end
                    end

                    if ~isequal(modelNames{mdlNo},'RootSWComposition')
                        inLine = get_param(sprintf('%s_Run_0.01',refBlocks{blkNo}),'LineHandles'); 
                        delete_line(inLine.Outport);
                        blkName = get_param(refBlocks{blkNo},'Name');
                        add_line(modelNames{mdlNo},sprintf('%s_Run_0.01/1',blkName),sprintf('%s/1',blkName),'autorouting','on')
                    else
                        %remove inports and outports and corresponding line
                        if isequal(allRefNames{mdlNo,blkNo},'InProc')
                            for portNo = 1:allRefNo(1)
                                rnblNo = rnblNo+1;
                                portName = sprintf('RootSWComposition/%s_Run_0.01',allRefNames{1,portNo});
                                inLine = get_param(portName,'LineHandles');
                                delete_line(inLine.Outport);
                                delete_block(portName);
                                add_line('RootSWComposition',{sprintf('FunCallSplit/%d',rnblNo)},{sprintf('InProc/%d',portNo)},'autorouting','on');
                            end 
                        elseif isequal(allRefNames{mdlNo,blkNo},'OutProc')
                            for portNo = 1:allRefNo(2)
                                rnblNo = rnblNo+1;
                                portName = sprintf('RootSWComposition/%s_Run_0.01',allRefNames{2,portNo});
                                inLine = get_param(portName,'LineHandles');
                                delete_line(inLine.Outport);
                                delete_block(portName);
                                add_line('RootSWComposition',{sprintf('FunCallSplit/%d',rnblNo)},{sprintf('OutProc/%d',portNo)},'autorouting','on');
                            end 
                        else
                            rnblNo = rnblNo+1;
                            inLine = get_param(sprintf('%s_Run_0.01',refBlocks{blkNo}),'LineHandles');
                            delete_line(inLine.Outport);
                            delete_block(sprintf('%s_Run_0.01',refBlocks{blkNo}));
                            if isequal(allRefNames{mdlNo,blkNo},'OutProc_Misc') || isequal(allRefNames{mdlNo,blkNo},'InProc_Misc')
                                add_line('RootSWComposition',{sprintf('FunCallSplit/%d',rnblNo)},{sprintf('%s/%d',get_param(refBlocks{blkNo},'Name'),length(lineHandles))},'autorouting','on');
                            else
                                add_line('RootSWComposition',{sprintf('FunCallSplit/%d',rnblNo)},{sprintf('%s/1',get_param(refBlocks{blkNo},'Name'))},'autorouting','on');
                            end
                        end                        
                    end
                end
                close_system(modelNames{mdlNo},1);
            end
            warning('on','all');
        end

        %addStubs
        function addStubs(napp)
            cd(napp.integPath);
            allProc = vertcat(dir('InProc_*.slx'),dir('OutProc_*.slx'));

            funcData = struct('subSystem',{},'functionProto',{},'inArg',{},'outArg',{},'dstBlocks',{},'srcBlocks',{}); %Check if Terminator or Ground

            funCaller = 0;
            for procNo = 1:length(allProc)
                split = strsplit(allProc(procNo).name,'_');
                %funcData(procNo).subSystem = sprintf('%s_Stub_Functions',split{1});
                waitbar(0.3*(procNo/length(allProc)),napp.progBar,...
                        {'Adding stub functions(4/5)',sprintf('Collecting function callers from ''%s'' model',regexprep(allProc(procNo).name,'_','\\_'))});
                load_system(allProc(procNo).name);
                [~,modelName,~] = fileparts(allProc(procNo).name);
                allCaller = find_system(modelName,'BlockType','FunctionCaller');
                for calNo = 1:length(allCaller)
                    dstNo = 0;
                    srcNo = 0;
                    dstBlk = cell.empty(1,0);
                    srcBlk = cell.empty(1,0);
                    funCaller = funCaller + 1;
                    funcData(funCaller).subSystem = sprintf('%s_Stub_Functions',split{1});
                    funcData(funCaller).functionProto = get_param(allCaller(calNo),'FunctionPrototype');
                    
                    if ~isequal(get_param(allCaller(calNo),'InputArgumentSpecifications'),{'<Enter example>'})
                        funcData(funCaller).inArg = get_param(allCaller(calNo),'InputArgumentSpecifications');
                    end
                    if ~isequal(get_param(allCaller(calNo),'OutputArgumentSpecifications'),{'<Enter example>'})
                        funcData(funCaller).outArg = get_param(allCaller(calNo),'OutputArgumentSpecifications');
                    end

                    portCon = get_param(allCaller(calNo),'PortConnectivity');
                    portCon = portCon{1};
                    for portNo = 1:length(portCon)
                        if ~isempty(portCon(portNo).SrcBlock)
                            srcNo = srcNo + 1;
                            srcBlk{srcNo} = get_param(portCon(portNo).SrcBlock,'BlockType'); 
                        end
                        if ~isempty(portCon(portNo).DstBlock)
                            dstNo = dstNo + 1;
                            dstBlk{dstNo} = get_param(portCon(portNo).DstBlock,'BlockType'); 
                        end
                    end

                    funcData(funCaller).dstBlocks = dstBlk;
                    funcData(funCaller).srcBlocks = srcBlk;
                end
                
                close_system(allProc(procNo).name);
            end

            load_system('RootSWComposition.slx');
            inPos = get_param('RootSWComposition/InProc','Position');
            outPos = get_param('RootSWComposition/OutProc','Position');

            %Adding inProc stub functions
            add_block('simulink/Ports & Subsystems/Subsystem','RootSWComposition/InProc_Stub_Functions','Position',[inPos(1) inPos(4)+(50) inPos(3) inPos(4)+(150)]);
            %delete existing blocks in subsystem
            tempPorts = find_system('RootSWComposition/InProc_Stub_Functions');
            delete_block(tempPorts(2:end));
            tempLine = find_system('RootSWComposition/InProc_Stub_Functions','FindAll','on','type','line');
            delete_line(tempLine);

            %Adding outProc stub functions
            add_block('simulink/Ports & Subsystems/Subsystem','RootSWComposition/OutProc_Stub_Functions','Position',[outPos(1) outPos(4)+(50) outPos(3) outPos(4)+(150)]);
            %delete existing blocks in subsystem
            tempPorts = find_system('RootSWComposition/OutProc_Stub_Functions');
            delete_block(tempPorts(2:end));
            tempLine = find_system('RootSWComposition/OutProc_Stub_Functions','FindAll','on','type','line');
            delete_line(tempLine);

            inFuncPos = [0 0 320 0];
            outFuncPos = [0 0 320 0];
            %funcParts = struct('inputArg',{},'FunctionName',{},'outputArg',{});
            for funcNo = 1:length(funcData)

                %( = )*(?<funName>\w*(?=\()) -> gives function name under 'funName' token
                %\[*(?<ouArg>,*\w*)*\]*(?=( = )) -> gives output arguments: Comma delimited under 'ouArg' token
                %\((?<inArg>,*\w*)*\) -> gives input arguments: Comma delimited under 'inArg' token
                outArg = regexp(funcData(funcNo).functionProto,'\[*(?<ouArg>,*\w*)*\]*(?=( = ))','names');
                outArg = outArg{1};
                if ~isempty(outArg)
                    outputArg = outArg.ouArg;
                    outputArg = strsplit(outputArg,',');
                    outData = strsplit(funcData(funcNo).outArg{1},',');
                    %funcParts(funcNo).inputArg = inputArg;
                    totOut = length(outputArg);
                else
                    outputArg = outArg;
                    totOut = 0;
                end

                funcName = regexp(funcData(funcNo).functionProto,'( = )*(?<funName>\w*(?=\())','names');
                funcName = funcName{1};
                functionName = funcName.funName;
                %funcParts(funcNo).FunctionName = functionName;

                waitbar(0.3+0.7*(funcNo/length(funcData)),napp.progBar,...
                        {'Adding stub functions(4/5)',sprintf('Adding ''%s'' stub function',regexprep(functionName,'_','\\_'))});

                inpArg = regexp(funcData(funcNo).functionProto,'\((?<inArg>,*\w*)*\)','names');
                inpArg = inpArg{1};
                if ~isequal(inpArg.inArg,'')
                    inputArg = inpArg.inArg;
                    inputArg = strsplit(inputArg,',');
                    inData = strsplit(funcData(funcNo).inArg{1},',');
                    %funcParts(funcNo).outputArg = outputArg;
                    totIn = length(inputArg);
                else
                    inputArg = inpArg;
                    totIn = 0;
                end

                if isequal(funcData(funcNo).subSystem,'InProc_Stub_Functions')
                    inFuncPos(2) = inFuncPos(4)+60;
                    inFuncPos(4) = inFuncPos(4)+60+50*max(totIn,totOut);
                    suffix = 'read';
                    prefix = 'InProc';
                    blockPosition = inFuncPos;
                else
                    outFuncPos(2) = outFuncPos(4)+60;
                    outFuncPos(4) = outFuncPos(4)+60+50*max(totIn,totOut);
                    suffix = 'write';
                    prefix = 'OutProc';
                    blockPosition = outFuncPos;
                end

                add_block('simulink/User-Defined Functions/Simulink Function',sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'Position',blockPosition);

                %'TriggerPort'-> 'FunctionName','FunctionVisibility','FunctionPrototype'
                %'ArgOut'/'ArgIn' ->'OutDataTypeStr','ArgumentName'
                %'Port' ->'OutDataTypeStr'

                tempLine = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'FindAll','on','type','line');
                delete_line(tempLine);

                %Updating properties of trigger port
                funcBlock = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'BlockType','TriggerPort');
                funcPosition = get_param(funcBlock,'Position');
                funcPosition = funcPosition{1};
                set_param(funcBlock{1},'Name',functionName,'FunctionName',functionName,'FunctionVisibility','global','FunctionPrototype',funcData(funcNo).functionProto{1});
                
                %Adding or deleting ArgIn ports and corresponding terminator or outport
                if isequal(inpArg.inArg,'')
                    tempBlock = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'BlockType','ArgIn');
                    delete_block(tempBlock);
                else
                    allArgIn = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'BlockType','ArgIn');
                    for inpNo = 1:length(inputArg)
                        dataType = strtrim(inData{inpNo});
                        portName = sprintf('%s_%s_%s',prefix,inputArg{inpNo},suffix);
                        set_param(allArgIn{inpNo},'Name',inputArg{inpNo},'ArgumentName',inputArg{inpNo},'OutDataTypeStr',dataType(3:end),...
                                        'Position', [funcPosition(3)+10 funcPosition(4)+inpNo*60 funcPosition(3)+110 funcPosition(4)+inpNo*60+30]);
                        if isequal(funcData(funcNo).srcBlocks{inpNo},'Ground')
                            add_block('simulink/Sinks/Terminator',sprintf('RootSWComposition/%s/%s/%s',funcData(funcNo).subSystem,functionName,portName),...
                                        'Position',[funcPosition(3)+250 funcPosition(4)+inpNo*60+5 funcPosition(3)+270 funcPosition(4)+inpNo*60+25]);
                        else
                            add_block('simulink/Sinks/Out1',sprintf('RootSWComposition/%s/%s/%s',funcData(funcNo).subSystem,functionName,portName),...
                                        'Position',[funcPosition(3)+250 funcPosition(4)+inpNo*60+8 funcPosition(3)+280 funcPosition(4)+inpNo*60+22],...
                                        'OutDataTypeStr',dataType(3:end));
                        end
                        lineHandle = add_line(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),...
                                        sprintf('%s/1',inputArg{inpNo}),sprintf('%s/1',portName));
                        set_param(lineHandle,'Name',portName);
                    end
                end

                %Adding or deleting ArgOut ports and corresponding terminator or outport
                if isempty(outArg)
                    tempBlock = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'BlockType','ArgOut');
                    delete_block(tempBlock);
                else
                    allArgOut = find_system(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),'BlockType','ArgOut');
                    for outNo = 1:length(outputArg)
                        dataType = strtrim(outData{outNo});
                        portName = sprintf('%s_%s_%s',prefix,outputArg{outNo},suffix);
                        set_param(allArgOut{outNo},'Name',outputArg{outNo},'ArgumentName',outputArg{outNo},'OutDataTypeStr',dataType(3:end),...
                                    'Position', [funcPosition(3)-110 funcPosition(4)+outNo*60 funcPosition(3)-10 funcPosition(4)+outNo*60+30]);
                        if isequal(funcData(funcNo).dstBlocks{outNo},'Terminator')
                            add_block('simulink/Sources/Ground',sprintf('RootSWComposition/%s/%s/%s',funcData(funcNo).subSystem,functionName,portName),...
                                        'Position',[funcPosition(3)-270 funcPosition(4)+outNo*60+5 funcPosition(3)-250 funcPosition(4)+outNo*60+25]);
                        else
                            add_block('simulink/Sources/In1',sprintf('RootSWComposition/%s/%s/%s',funcData(funcNo).subSystem,functionName,portName),...
                                        'Position',[funcPosition(3)-280 funcPosition(4)+outNo*60+8 funcPosition(3)-250 funcPosition(4)+outNo*60+22],...
                                        'OutDataTypeStr',dataType(3:end));
                        end
                        lineHandle = add_line(sprintf('RootSWComposition/%s/%s',funcData(funcNo).subSystem,functionName),...
                                        sprintf('%s/1',portName),sprintf('%s/1',outputArg{outNo}));
                        %set_param(lineHandle,'Name',portName);
                        set(lineHandle,'signalPropagation','on');
                    end
                end
            end
            close_system('RootSWComposition',1);
        end

        function add_ports(napp)
            cd(napp.integPath);
            open_system('RootSWComposition.slx');
            
            %Removing ground and terminator blocks
            %systemNames = {'InProc','OutProc'};
            modelRefs = find_system('RootSWComposition','SearchDepth',1,'BlockType','ModelReference');
            for sysNo = 1:length(modelRefs)
                systemName = strsplit(modelRefs{sysNo},'/');
                systemName = systemName{2};
                if isequal(systemName,'InProc') || isequal(systemName,'InProc_Misc') || isequal(systemName,'OutProc') || isequal(systemName,'OutProc_Misc')
                    waitbar(0.7*(sysNo/length(modelRefs)),napp.progBar,...
                            {'Adding In & Out ports(5/5)',sprintf('Adding ports to ''%s''',systemName)});
                    load_system(sprintf('%s.slx',systemName));
                    allRef = find_system(systemName,'SearchDepth',1,'BlockType','ModelReference');
                    allLines = get_param(modelRefs{sysNo},'LineHandles');
                    if isequal(systemName,'InProc') || isequal(systemName,'InProc_Misc')
                        lineHandles = allLines.Inport;
                    elseif isequal(systemName,'OutProc') || isequal(systemName,'OutProc_Misc')
                        lineHandles = allLines.Outport;
                    end
                    for lnNo = 1:length(lineHandles)
                        if isequal(systemName,'InProc') || isequal(systemName,'InProc_Misc')
                            blkHandle = get_param(lineHandles(lnNo),'SrcBlockHandle');
                        elseif isequal(systemName,'OutProc') || isequal(systemName,'OutProc_Misc')
                            blkHandle = get_param(lineHandles(lnNo),'DstBlockHandle');
                        end
                        blkType = get_param(blkHandle,'BlockType');
                        if isequal(blkType,'Ground') || isequal(blkType,'Terminator')
                            delete_block(blkHandle);
                            delete_line(lineHandles(lnNo));
                        end
                    end
                    rnblNo = length(allRef);
                    allPorts = get_param(modelRefs{sysNo},'PortHandles');
                    allLines = get_param(modelRefs{sysNo},'LineHandles');
                    if isequal(systemName,'InProc') || isequal(systemName,'InProc_Misc')
                        portHandles = allPorts.Inport;
                        lineHandles = allLines.Inport;
                        for inpNo = rnblNo+1:length(portHandles)
                            if lineHandles(inpNo) == -1
                                portSrc = find_system(systemName,'SearchDepth',1,'BlockType','Inport','Port',num2str(inpNo));
                                portDst = strsplit(portSrc{1},'/');
                                %subPath = strjoin(portDst(1:1+padNo),'/');
                                portName = portDst{2};
                                portDst = [{'RootSWComposition'} {portName}];
                                portDst = strjoin(portDst,'/');
                                
                                portPos = get_param(portHandles(inpNo),'Position');
                                add_block(portSrc{1},portDst,'Position',[portPos(1)-160 portPos(2)-7 portPos(1)-130 portPos(2)+7]);
                                lineHandle = add_line('RootSWComposition',sprintf('%s/1',portName),sprintf('%s/%d',systemName,inpNo));
                                set_param(lineHandle,'Name',portName);
                            end
                        end
                    elseif isequal(systemName,'OutProc') || isequal(systemName,'OutProc_Misc')
                        portHandles = allPorts.Outport;
                        for outNo = 1:length(portHandles)
                            portSrc = find_system(systemName,'SearchDepth',1,'BlockType','Outport','Port',num2str(outNo));
                            portDst = strsplit(portSrc{1},'/');
                            %subPath = strjoin(portDst(1:1+padNo),'/');
                            portName = portDst{2};
                            portDst = [{'RootSWComposition'} {portName}];
                            portDst = strjoin(portDst,'/');
                            
                            portPos = get_param(portHandles(outNo),'Position');
                            add_block(portSrc{1},portDst,'Position',[portPos(1)+230 portPos(2)-7 portPos(1)+260 portPos(2)+7]);
                            lineHandle = add_line('RootSWComposition',sprintf('%s/%d',systemName,outNo),sprintf('%s/1',portName));
                            set(lineHandle,'signalPropagation','on');
                        end
                    end
                    close_system(sprintf('%s.slx',systemName),0);
                end
            end
            
            %adding inports/outports to simulink functions 
            systemNames = {'InProc_Stub_Functions','OutProc_Stub_Functions'};
            for sysNo = 1:length(systemNames)
                waitbar(0.7+0.3*(sysNo/length(systemNames)),napp.progBar,...
                        {'Adding In & Out ports(5/5)',sprintf('Adding ports to ''%s''',regexprep(systemNames{sysNo},'_','\\_'))});
                allFuncs = find_system(sprintf('RootSWComposition/%s',systemNames{sysNo}),'SearchDepth',1,'BlockType','SubSystem');
                for funNo = 2:length(allFuncs)
                    napp.extendPorts(allFuncs{funNo},-1,0);
                end
                allPorts = get_param(sprintf('RootSWComposition/%s',systemNames{sysNo}),'PortHandles');
                maxPorts = max(length(allPorts.Inport),length(allPorts.Outport));
                sysPosition = get_param(sprintf('RootSWComposition/%s',systemNames{sysNo}),'Position');
                set_param(sprintf('RootSWComposition/%s',systemNames{sysNo}),'Position',[sysPosition(1) sysPosition(2) sysPosition(3) sysPosition(2)+maxPorts*60]);
                napp.extendPorts(sprintf('RootSWComposition/%s',systemNames{sysNo}),sysNo,0);
            end
            %find_system(gcs,'BlockType','SubSystem');
            close_system('RootSWComposition',1);
        end
    end

    methods (Static)
        function fillItUp(systemName)
            rnblName = ['Rnbl_' systemName '_sys'];
            %Delete ground and terminator blocks with connecting lines
            tempLine = find_system([systemName '/' rnblName],'FindAll','on','type','line');
            delete_line(tempLine);
            extraBlks = find_system([systemName '/' rnblName],'BlockType','Ground');
            extraBlks = vertcat(extraBlks, find_system([systemName '/' rnblName],'BlockType','Terminator'));
            delete_block(extraBlks);

            allInports = find_system([systemName '/' rnblName],'BlockType','Inport');
            allOutports = find_system([systemName '/' rnblName],'BlockType','Outport');

            inpNames = struct('Name',{},'fullName',{});
            outNames = struct('Name',{},'fullName',{});

            for inpNo = 1:length(allInports)
                blockName = get_param(allInports{inpNo},'Name');
                nameSplit = strsplit(blockName,'_');
                inpNames(inpNo).Name = nameSplit{2};
                inpNames(inpNo).fullName = blockName; 
            end

            for outNo = 1:length(allOutports)
                blockName = get_param(allOutports{outNo},'Name');
                nameSplit = strsplit(blockName,'_');
                outNames(outNo).Name = nameSplit{2};
                outNames(outNo).fullName = blockName;
            end

            allOutNames = {outNames.Name};
            for inpNo = 1:length(inpNames)
                findIndex = find(contains(string(allOutNames),inpNames(inpNo).Name));
                %width - 75 height - 20 gap - 200
                blkPos = get_param(allInports{inpNo},'Position');
                add_block('simulink/Signal Attributes/Data Type Conversion',[systemName '/' rnblName '/convert_' num2str(inpNo)],...
                    'Position',[blkPos(3)+200 blkPos(2) blkPos(3)+200+75 blkPos(4)], 'OutDataTypeStr',get_param([systemName '/' outNames(findIndex).fullName(1:end-6)],'OutDataTypeStr'),'ShowName','off');
                lineHandle = add_line([systemName '/' rnblName],[inpNames(inpNo).fullName '/1'],['convert_' num2str(inpNo) '/1']);
                set(lineHandle,'signalPropagation','on');
                lineHandle = add_line([systemName '/' rnblName],['convert_' num2str(inpNo) '/1'],[outNames(findIndex).fullName '/1']);
                set_param(lineHandle,'Name',outNames(findIndex).fullName);
            end
        end

        function extendPorts(systemPath,procNo,rnblNo) %procNo: 1->InProc 2->OutProc
            allInports = find_system(systemPath,'SearchDepth',1,'BlockType','Inport');
            portConn = get_param(systemPath,'PortConnectivity');
            if procNo == -1
                padNo = 1;
            else
                padNo = 0;
            end
            
            if procNo == 1 || procNo == -1
                if ~isempty(allInports)
                    for inpNo = rnblNo+1:length(allInports)
                        portSrc = find_system(systemPath,'SearchDepth',1,'BlockType','Inport','Port',num2str(inpNo));
                        portDst = strsplit(portSrc{1},'/');
                        subPath = strjoin(portDst(1:1+padNo),'/');
                        subName = portDst{2+padNo};
                        portName = portDst{3+padNo};
                        portDst = [portDst(1:1+padNo) portDst(3+padNo)];
                        
                        portDst = strjoin(portDst,'/');
                        portPos = portConn(inpNo).Position;
                        add_block(portSrc{1},portDst,'Position',[portPos(1)-260 portPos(2)-7 portPos(1)-230 portPos(2)+7]);
                        lineHandle = add_line(subPath,sprintf('%s/1',portName),sprintf('%s/%d',subName,inpNo));
                        %set(lineHandle,'signalPropagation','on');
                        if procNo == 1
                            set_param(lineHandle,'Name',portName);
                        end
                    end
                end
            end
            allOutports = find_system(systemPath,'SearchDepth',1,'BlockType','Outport');
            if procNo == 2 || procNo == -1
                if ~isempty(allOutports)
                    for outNo = 1:length(allOutports)
                        portSrc = find_system(systemPath,'SearchDepth',1,'BlockType','Outport','Port',num2str(outNo));
                        portDst = strsplit(portSrc{1},'/');
                        subPath = strjoin(portDst(1:1+padNo),'/');
                        subName = portDst{2+padNo};
                        portName = portDst{3+padNo};
                        portDst = [portDst(1:1+padNo) portDst(3+padNo)];
                        
                        portDst = strjoin(portDst,'/');
                        portPos = portConn(length(allInports)+padNo+outNo).Position;
                        add_block(portSrc{1},portDst,'Position',[portPos(1)+230 portPos(2)-7 portPos(1)+260 portPos(2)+7]);
                        lineHandle = add_line(subPath,sprintf('%s/%d',subName,outNo),sprintf('%s/1',portName));
                        set(lineHandle,'signalPropagation','on');
                    end
                end
            end
        end
    end
end