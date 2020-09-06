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
        % dstPath
        sourcePath
        integPath
        arxmlName
        arxmlPath

        allASWCmp
        delConMap
        asmConn
        dataTypeMap
        idtrStructMap
        defValueMap
        glbConfigMap
        cmpDirMap
        allMdlData
        rnblRteData
        lctData
        allPortMap

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

            % [napp.arxmlName, napp.arxmlPath] = uigetfile({'*.arxml','AUTOSAR XML (*.arxml)'},'Select root ARXML');
            % napp.sourcePath = uigetdir(currFolder,'Select ASW source folder with all delivery artifacts');
            % napp.integPath = uigetdir(currFolder,'Select path to save integrated model');

            napp.arxmlName = 'RootSWComposition.arxml';
            napp.arxmlPath = 'D:\R0019983\Branches\OBC_A3_1\20_Design\ASW\SW_Composition_ARXML';
            napp.sourcePath = 'D:\R0019983\Branches\OBC_A3_1\30_Software\Source\ASW';
            napp.integPath = 'D:\Temp_Project\ASW_Integration\integrationBuildTest';

            %disp(napp.framePath);
            if isequal(napp.integPath,0) ||  isequal(napp.sourcePath,0) || isequal(napp.arxmlPath,0)
                %!Folder Not Selected
                msgbox('Ahhhhh, you din''t select any folder and that''s not fair','Error','error');
            else
                % warning('off','MATLAB:rmpath:DirNotFound');
                % rmpath(napp.framePath);
                % warning('on','MATLAB:rmpath:DirNotFound');
                napp.exitFlag = 1;
                tmpMat(napp, 0);
                if exist('RootSWComposition_IntegrationData.mat')
                    napp.progBar = waitbar(0,{'Reading model data(2/5)','Collecting paths of components...'},'Name','ASW Code Integration (v1)');
                    napp.cmpDirMap = napp.getComponentPath(napp.sourcePath);
                    napp.dataTypeMap('Std_ReturnType') = 'uint8';
                    napp.dataTypeMap('Dem_EventStatusType') = 'uint8';
                    napp.dataTypeMap('Dem_UdsStatusByteType') = 'uint8';
                    napp.dataTypeMap('CANSM_BSWM_MG') = 'uint8';
                    matNames = who('-file', 'RootSWComposition_IntegrationData.mat');
                    if ismember('modelData', matNames)
                        readRteFiles(napp);
                    else
                        collectModelData(napp);
                    end
                else
                    readARXML(napp);
                end
                % copyFiles(napp);
                % if napp.exitFlag
                %     copySldd(napp);
                % end
                % if napp.exitFlag
                %     reconnectSignals(napp);
                %     warning('on','all');
                % end
                % if napp.exitFlag
                %     addStubs(napp);
                % end
                % if napp.exitFlag
                %     add_ports(napp);
                % end
                % if napp.exitFlag
                %     nvmFlg = napp.nvmFlg;
                %     save('RootSWComposition_IntegrationData.mat','nvmFlg');
                %     close(napp.progBar);
                %     msgbox({'ASW Integration Completed';'Use ''replaceInports'' and ''integrationPanel''';'to test ASW root composition'},'Success');
                % end
                close(napp.progBar);
                msgbox({'Done'},'Success');
            end 
        end
    end

    methods (Access = private)

        function readARXML(napp)
            cd(napp.arxmlPath);
            napp.progBar = waitbar(0,{'Reading root ARXML(1/5)','Accessing ARXML file...'},'Name','ASW Code Integration (v1)');

            %? Reading all application component names from ARXML
            xDoc = xmlread(napp.arxmlName);
            allApp = xDoc.getElementsByTagName('SW-COMPONENT-PROTOTYPE');
            napp.allASWCmp = struct('cmpName',{},'refPath',{});
            %exclName = {'InProc';'IoHwAb_Composition';'OutProc';'ECU_ECUC_CTP_Base_AR4x'};
            for appNo  = 0 : allApp.getLength - 1
                waitbar(0.1*(appNo/(allApp.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting ASW component names...')});

                appName = allApp.item(appNo).getElementsByTagName('TYPE-TREF');
                tgt = strsplit(char(appName.item(0).getFirstChild.getData),'/');
                
            %     applName = allApp.item(i).getElementsByTagName('SHORT-NAME');
            %     findIdx = find(contains(exclName,char(applName.item(0).getFirstChild.getData)));
                if isequal(tgt{3},'BSW_components') || isequal(tgt{2},'SwCompositions')
                else
                    appName = allApp.item(appNo).getElementsByTagName('TYPE-TREF');
                    napp.allASWCmp(length(napp.allASWCmp) + 1).refPath = char(appName.item(0).getFirstChild.getData);

                    appName = allApp.item(appNo).getElementsByTagName('SHORT-NAME');
                    napp.allASWCmp(length(napp.allASWCmp)).cmpName = char(appName.item(0).getFirstChild.getData);
                end
            end

            %? Collecting all inter-component connections
            %* Collecting delegation connection between component and composition signals
            allConn = xDoc.getElementsByTagName('DELEGATION-SW-CONNECTOR');
            napp.delConMap = containers.Map();
            for conNo = 0 : allConn.getLength - 1
                waitbar(0.1 + 0.1*(conNo/(allConn.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting delegation connections...')});

                inIntf = allConn.item(conNo).getElementsByTagName('CONTEXT-COMPONENT-REF');
                inIntf = strsplit(char(inIntf.item(0).getFirstChild.getData),'/');
                
                outIntf = allConn.item(conNo).getElementsByTagName('OUTER-PORT-REF');
                outIntf = strsplit(char(outIntf.item(0).getFirstChild.getData),'/');

                napp.delConMap([outIntf{length(outIntf) - 1} '/' outIntf{length(outIntf)}]) = inIntf{length(inIntf)};
            end
            napp.delConMap('OutProc/DIO_NoCrshLnStat_P') = 'OutProc_DIO';

            %* Collecting all assembly connections between components
            allConn = xDoc.getElementsByTagName('ASSEMBLY-SW-CONNECTOR');
            napp.asmConn = struct('prvCmp',{},'prvPort',{},'rcvCmp',{},'rcvPort',{});
            allCmp = {napp.allASWCmp.cmpName};

            for conNo = 0 : allConn.getLength - 1
                waitbar(0.2 + 0.2*(conNo/(allConn.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting assembly connections...')});

                provIntf = allConn.item(conNo).getElementsByTagName('PROVIDER-IREF');
                provCmp = provIntf.item(0).getElementsByTagName('CONTEXT-COMPONENT-REF');
                provCmp = strsplit(char(provCmp.item(0).getFirstChild.getData),'/');
                
                rqsIntf = allConn.item(conNo).getElementsByTagName('REQUESTER-IREF');
                rqsCmp = rqsIntf.item(0).getElementsByTagName('CONTEXT-COMPONENT-REF');
                rqsCmp = strsplit(char(rqsCmp.item(0).getFirstChild.getData),'/');
                
                findPrv = find(contains(allCmp,provCmp{length(provCmp)}));
                findRqs = find(contains(allCmp,rqsCmp{length(rqsCmp)}));
                
                if ~isempty(findPrv) || ~isempty(findRqs)
                    if isempty(findPrv)
                        napp.asmConn(length(napp.asmConn) + 1).prvCmp = 'viaBSW';
                        connIdx = length(napp.asmConn); 
                    else
                        provPort = provIntf.item(0).getElementsByTagName('TARGET-P-PORT-REF');
                        provPort = strsplit(char(provPort.item(0).getFirstChild.getData),'/');
                        napp.asmConn(length(napp.asmConn) + 1).prvPort = provPort{length(provPort)};
                        connIdx = length(napp.asmConn); 
                        
                        if isequal(provCmp{length(provCmp)},'InProc') || isequal(provCmp{length(provCmp)},'OutProc')
                            napp.asmConn(connIdx).prvCmp = napp.delConMap([provCmp{length(provCmp)} '/' napp.asmConn(connIdx).prvPort]);
                        else
                            napp.asmConn(connIdx).prvCmp = provCmp{length(provCmp)};
                        end
                    end
                    
                    if isempty(findRqs)
                        napp.asmConn(connIdx).rcvCmp = 'viaBSW';
                    else
                        rcvPort = rqsIntf.item(0).getElementsByTagName('TARGET-R-PORT-REF');
                        rcvPort = strsplit(char(rcvPort.item(0).getFirstChild.getData),'/');
                        napp.asmConn(connIdx).rcvPort = rcvPort{length(rcvPort)};
                        
                        if isequal(rqsCmp{length(rqsCmp)},'InProc') || isequal(rqsCmp{length(rqsCmp)},'OutProc')
                            napp.asmConn(connIdx).rcvCmp = napp.delConMap([rqsCmp{length(rqsCmp)} '/' napp.asmConn(connIdx).rcvPort]);
                        else
                            napp.asmConn(connIdx).rcvCmp = rqsCmp{length(rqsCmp)};
                        end
                    end
                end
            end

            %? Base datatype map for application data types
            allDataTypes = xDoc.getElementsByTagName('DATA-TYPE-MAP');
            napp.dataTypeMap = containers.Map();

            for dataNo  = 0 : allDataTypes.getLength - 1
                waitbar(0.4 + 0.1*(dataNo/(allDataTypes.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Mapping base data types...')});

                adtsType = allDataTypes.item(dataNo).getElementsByTagName('APPLICATION-DATA-TYPE-REF');
                if adtsType.getLength
                    adtsType = strsplit(char(adtsType.item(0).getFirstChild.getData),'/');

                    impType = allDataTypes.item(dataNo).getElementsByTagName('IMPLEMENTATION-DATA-TYPE-REF');
                    impType = strsplit(char(impType.item(0).getFirstChild.getData),'/');

                    napp.dataTypeMap(adtsType{length(adtsType)}) = impType{length(impType)};
                end
            end

            %* Collecting bus structure elements
            allBusTypes = xDoc.getElementsByTagName('IMPLEMENTATION-DATA-TYPE');
            napp.idtrStructMap = containers.Map();

            for strNo  = 0 : allBusTypes.getLength - 1
                waitbar(0.5 + 0.1*(strNo/(allBusTypes.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting bus structures...')});

                busCat = allBusTypes.item(strNo).getElementsByTagName('CATEGORY');
                
                if ~isempty(busCat) && isequal(char(busCat.item(0).getFirstChild.getData),'STRUCTURE')
                    idtrName = allBusTypes.item(strNo).getElementsByTagName('SHORT-NAME');
                    idtrName = char(idtrName.item(0).getFirstChild.getData);

                    busElements = allBusTypes.item(strNo).getElementsByTagName('IMPLEMENTATION-DATA-TYPE-ELEMENT');
                    structVars = struct('varName',{},'dataType',{});
                    for elemNo = 0 : busElements.getLength - 1
                        varName = busElements.item(elemNo).getElementsByTagName('SHORT-NAME');
                        structVars(length(structVars) + 1).varName = char(varName.item(0).getFirstChild.getData);
                        
                        varType = busElements.item(elemNo).getElementsByTagName('IMPLEMENTATION-DATA-TYPE-REF');
                        varType = strsplit(char(varType.item(0).getFirstChild.getData),'/');
                        structVars(length(structVars)).dataType = varType{length(varType)};
                    end
                    napp.idtrStructMap(idtrName) = structVars;
                end
            end

            %? Collecting default values of all signals
            %* Collecting constant specs for constant references of default values
            allConstSpec = xDoc.getElementsByTagName('CONSTANT-SPECIFICATION');
            constSpecMap = containers.Map();

            for consNo  = 0 : allConstSpec.getLength - 1
                waitbar(0.6 + 0.05*(consNo/(allConstSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting constant specs of default values...')});

                constSpecName = allConstSpec.item(consNo).getElementsByTagName('SHORT-NAME');
                constSpecValue = allConstSpec.item(consNo).getElementsByTagName('VT');
                if constSpecValue.getLength
                    constSpecMap(char(constSpecName.item(0).getFirstChild.getData)) = char(constSpecValue.item(0).getFirstChild.getData);
                end
            end

            %* Collecting ROM values of NV data ports
            allNvSpec = xDoc.getElementsByTagName('NV-BLOCK-DESCRIPTOR');
            nvSpecMap = containers.Map();

            for consNo  = 0 : allNvSpec.getLength - 1
                waitbar(0.65 + 0.05*(consNo/(allNvSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting NV-ROM value specs of default values...')});

                nvSpecName = allNvSpec.item(consNo).getElementsByTagName('SHORT-NAME');
                nvSpecElement = allNvSpec.item(consNo).getElementsByTagName('TARGET-DATA-PROTOTYPE-REF');
                nvSpecValue = allNvSpec.item(consNo).getElementsByTagName('VALUE');
                if nvSpecElement.getLength ~= 0 && nvSpecValue.getLength ~= 0
                    nvSpecElement = char(nvSpecElement.item(0).getFirstChild.getData);
                    nvSpecElement = strsplit(nvSpecElement,'/');
                    nvSpecElement = nvSpecElement{length(nvSpecElement)};

                    dataElements = struct('elemName',{nvSpecElement},'defValue',{char(nvSpecValue.item(0).getFirstChild.getData)});
                    nvSpecMap(char(nvSpecName.item(0).getFirstChild.getData)) = dataElements;
                end
            end

            napp.defValueMap = containers.Map();
            %* Default values of receiver ports 
            allPortSpec = xDoc.getElementsByTagName('R-PORT-PROTOTYPE');
            for portNo = 0 : allPortSpec.getLength - 1
                waitbar(0.7 + 0.1*(portNo/(allPortSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting default values of receiver ports...')});

                portName = allPortSpec.item(portNo).getElementsByTagName('SHORT-NAME');
                portName = char(portName.item(0).getFirstChild.getData);
            
                if isequal(portName(1:3),'NV_')
                    napp.defValueMap(portName) = nvSpecMap([portName(4 : length(portName) - 2) '_BD']);
                else
                    portElements = allPortSpec.item(portNo).getElementsByTagName('NONQUEUED-RECEIVER-COM-SPEC');
                    initValue = allPortSpec.item(portNo).getElementsByTagName('INIT-VALUE');
                    if initValue.getLength
                        dataElements = struct('elemName',{},'defValue',{});
                        for elemNo = 0 : portElements.getLength - 1
                            varName = portElements.item(elemNo).getElementsByTagName('DATA-ELEMENT-REF');
                            varName = strsplit(char(varName.item(0).getFirstChild.getData),'/');
                            dataElements(length(dataElements) + 1).elemName = varName{length(varName)};
                
                            defValue = portElements.item(elemNo).getElementsByTagName('V');
                            if defValue.getLength
                                dataElements(length(dataElements)).defValue = char(defValue.item(0).getFirstChild.getData);
                            else
                                constRef = portElements.item(elemNo).getElementsByTagName('CONSTANT-REF');
                                constRef = strsplit(char(constRef.item(0).getFirstChild.getData),'/');
                                dataElements(length(dataElements)).defValue = constSpecMap(constRef{length(constRef)});
                            end
                        end
                        if portElements.getLength
                            if isKey(napp.defValueMap, portName)
                                if length(napp.defValueMap(portName)) < length(dataElements)
                                    napp.defValueMap(portName) = dataElements;
                                end
                            else
                                napp.defValueMap(portName) = dataElements;
                            end
                        end
                    end
                end
            end

            %* Default values of provider ports
            allPortSpec = xDoc.getElementsByTagName('P-PORT-PROTOTYPE');
            for portNo = 0 : allPortSpec.getLength - 1
                waitbar(0.8 + 0.1*(portNo/(allPortSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting default values of provider ports...')});

                portName = allPortSpec.item(portNo).getElementsByTagName('SHORT-NAME');
                portName = char(portName.item(0).getFirstChild.getData);

                if isequal(portName(1:3),'NV_')
                    napp.defValueMap(portName) = nvSpecMap([portName(4 : length(portName) - 2) '_BD']);
                else
                    portElements = allPortSpec.item(portNo).getElementsByTagName('NONQUEUED-SENDER-COM-SPEC');
                    initValue = allPortSpec.item(portNo).getElementsByTagName('INIT-VALUE');
                    if initValue.getLength
                        dataElements = struct('elemName',{},'defValue',{});
                        for elemNo = 0 : portElements.getLength - 1
                            varName = portElements.item(elemNo).getElementsByTagName('DATA-ELEMENT-REF');
                            varName = strsplit(char(varName.item(0).getFirstChild.getData),'/');
                            dataElements(length(dataElements) + 1).elemName = varName{length(varName)};

                            defValue = portElements.item(elemNo).getElementsByTagName('V');
                            if defValue.getLength
                                dataElements(length(dataElements)).defValue = char(defValue.item(0).getFirstChild.getData);
                            else
                                constRef = portElements.item(elemNo).getElementsByTagName('CONSTANT-REF');
                                constRef = strsplit(char(constRef.item(0).getFirstChild.getData),'/');
                                dataElements(length(dataElements)).defValue = constSpecMap(constRef{length(constRef)});
                            end
                        end
                        if portElements.getLength
                            if isKey(napp.defValueMap, portName)
                                if length(napp.defValueMap(portName)) < length(dataElements)
                                    napp.defValueMap(portName) = dataElements;
                                end
                            else
                                napp.defValueMap(portName) = dataElements;
                            end
                        end
                    end
                end
            end

            %* Global configurations
            napp.glbConfigMap = containers.Map();
            paramCmp = xDoc.getElementsByTagName('PARAMETER-SW-COMPONENT-TYPE');
            allPortSpec = paramCmp.item(0).getElementsByTagName('P-PORT-PROTOTYPE');

            for confNo = 0 : allPortSpec.getLength - 1
                waitbar(0.9 + 0.1*(confNo/(allPortSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting all global configurations...')});

                portName = allPortSpec.item(confNo).getElementsByTagName('SHORT-NAME');
                portName = char(portName.item(0).getFirstChild.getData);
                
                defValue = allPortSpec.item(confNo).getElementsByTagName('V');
                if defValue.getLength
                    napp.glbConfigMap(portName) = char(defValue.item(0).getFirstChild.getData);
                else
                    constRef = allPortSpec.item(confNo).getElementsByTagName('CONSTANT-REF');
                    constRef = strsplit(char(constRef.item(0).getFirstChild.getData),'/');
                    napp.glbConfigMap(portName) = constSpecMap(constRef{length(constRef)});
                end
            end

            %! Saving autosar data in matFile
            tmpMat(napp, 1);
        end

        function collectModelData(napp)
            napp.allMdlData = containers.Map();

            waitbar(0,napp.progBar,{'Collecting model data(2/5)',sprintf('Loading model...')});
            for cmpNo = 1 : length(napp.allASWCmp)
            % for cmpNo = 12
                cmpName = napp.allASWCmp(cmpNo).cmpName;
                cmpPath = napp.cmpDirMap(cmpName);

                % waitbar((cmpNo-1/length(napp.allASWCmp)) + ((0.3*(confNo/(allPortSpec.getLength - 1)))/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Loading model...')});
                waitbar(((cmpNo-1)/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Loading ''%s'' model...',regexprep(cmpName,'_','\\_'))});
                cd([cmpPath '\Model'])
                load_system(sprintf('%s.slx', cmpName));
                DataDictionary = get_param(cmpName,'DataDictionary');
                DataDictObj = Simulink.data.dictionary.open(DataDictionary);
                DataDictSec = getSection(DataDictObj,'Design Data');

                mdlRnbls = find_system(cmpName,'SearchDepth',1,'regexp','on','BlockType','SubSystem','Name','Rnbl_.*');
                mdlData = struct('rnblData',{},'glbConfig',{},'funcData',{});
                rnblData = struct('rnblName',{},'inportData',{},'outportData',{},'sampleTime',{});
                
                waitbar(((cmpNo-1)/length(napp.allASWCmp)) + (0.1/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Reading port data of ''%s'' model...',regexprep(cmpName,'_','\\_'))});
                for rnblNo = 1 : length(mdlRnbls)
                    %? initializing structures
                    inportData = struct('portName',{},'appDataType',{},'baseDataType',{},'isBus',{});
                    outportData = struct('portName',{},'appDataType',{},'baseDataType',{},'isBus',{});
                    %? Collect port data
                    portConn = get_param(mdlRnbls{rnblNo},'PortConnectivity');
                    for portNo = 1 : length(portConn)
                        if isequal(portConn(portNo).Type,'trigger')
                            rnblData(rnblNo).rnblName = get_param(portConn(portNo).SrcBlock,'Name');
                            rnblData(rnblNo).sampleTime = get_param(portConn(portNo).SrcBlock,'SampleTime');
                        else
                            if isempty(portConn(portNo).DstBlock)
                                %* Collecting inport Data
                                %Looking for inport
                                if isequal(get_param(portConn(portNo).SrcBlock,'BlockType'),'Inport')
                                    portHandle = portConn(portNo).SrcBlock;
                                else
                                    gotoBlk = find_system(cmpName,'SearchDepth',1,'BlockType','Goto','GotoTag',get_param(portConn(portNo).SrcBlock,'GotoTag'));
                                    gotoPort = get_param(gotoBlk{1},'PortConnectivity');
                                    portHandle = gotoPort(1).SrcBlock;
                                end
                                inportNo = length(inportData) + 1;
                                inportData = napp.getPortData(inportData, inportNo, portHandle, napp.dataTypeMap);
                            else
                                %* Collecting outport Data
                                outportNo = length(outportData) + 1;
                                outportData = napp.getPortData(outportData, outportNo, portConn(portNo).DstBlock, napp.dataTypeMap);
                            end
                        end
                    end
                    rnblData(rnblNo).inportData = inportData;
                    rnblData(rnblNo).outportData = outportData;
                end
                mdlData(1).rnblData = rnblData;

                funcData = struct('functionProto',{},'funcName',{},'inArg',{},'outArg',{},'inArgSpc',{},'inBase',{},'outArgSpc',{},'outBase',{},'dstBlocks',{},'srcBlocks',{});


                %? Collecting function data
                allCaller = find_system(cmpName,'BlockType','FunctionCaller'); 
                for calNo = 1:length(allCaller)
                    waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.1 + (0.4*calNo/length(allCaller)))/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Reading caller data of ''%s'' model...',regexprep(cmpName,'_','\\_'))});

                    funcData(calNo).functionProto = get_param(allCaller(calNo),'FunctionPrototype');

                    if ~isequal(get_param(allCaller(calNo),'InputArgumentSpecifications'),{'<Enter example>'})
                        funcData(calNo).inArgSpc = get_param(allCaller(calNo),'InputArgumentSpecifications');
                    end
                    if ~isequal(get_param(allCaller(calNo),'OutputArgumentSpecifications'),{'<Enter example>'})
                        funcData(calNo).outArgSpc = get_param(allCaller(calNo),'OutputArgumentSpecifications');
                    end

                    %( = )*(?<funName>\w*(?=\()) -> gives function name under 'funName' token
                    %\[*(?<ouArg>,*\w*)*\]*(?=( = )) -> gives output arguments: Comma delimited under 'ouArg' token
                    %\((?<inArg>,*\w*)*\) -> gives input arguments: Comma delimited under 'inArg' token
                    %* Collecting output arguments
                    outArg = regexp(funcData(calNo).functionProto,'\[*(?<ouArg>,*\w*)*\]*(?=( = ))','names');
                    outArg = outArg{1};
                    if ~isempty(outArg)
                        outputArg = outArg.ouArg;
                        funcData(calNo).outArg = strsplit(outputArg,',');
                        funcData(calNo).outArgSpc = strsplit(funcData(calNo).outArgSpc{1},',');
                        %funcParts(funcNo).inputArg = inputArg;
                        for outNo = 1:length(funcData(calNo).outArg)
                            dataType = strtrim(funcData(calNo).outArgSpc{outNo});
                            enumType = regexp(dataType,'(?<enumName>\w*)\(\d*\)','names');
                            %enumType = enumType{1};
                            if ~isempty(enumType)
                                funcData(calNo).outArgSpc{outNo} = enumType.enumName;
                            else
                                entryObj = getEntry(DataDictSec,dataType);
                                paramValue = getValue(entryObj);
                                if isequal(paramValue.DataType(1 : 4),'Enum')
                                    funcData(calNo).outArgSpc{outNo} =  paramValue.DataType(7 : length(paramValue.DataType));
                                else
                                    funcData(calNo).outArgSpc{outNo} =  paramValue.DataType;
                                end
                            end
                            funcData(calNo).outBase{outNo} = napp.dataTypeMap(funcData(calNo).outArgSpc{outNo});
                        end
                    else
                        funcData(calNo).outArg = outArg;
                    end

                    funcName = regexp(funcData(calNo).functionProto,'( = )*(?<funName>\w*(?=\())','names');
                    funcName = funcName{1};
                    funcData(calNo).funcName = funcName.funName;
                    
                    %* Collecting input arguments
                    inpArg = regexp(funcData(calNo).functionProto,'\((?<inArg>,*\w*)*\)','names');
                    inpArg = inpArg{1};
                    if ~isequal(inpArg.inArg,'')
                        inputArg = inpArg.inArg;
                        funcData(calNo).inArg = strsplit(inputArg,',');
                        funcData(calNo).inArgSpc = strsplit(funcData(calNo).inArgSpc{1},',');
                        %funcParts(funcNo).outputArg = outputArg;
                        for inpNo = 1:length(funcData(calNo).inArg)
                            dataType = strtrim(funcData(calNo).inArgSpc{inpNo});
                            enumType = regexp(dataType,'(?<enumName>\w*)\(\d*\)','names');
                            %enumType = enumType{1};
                            if ~isempty(enumType)
                                funcData(calNo).inArgSpc{inpNo} = enumType.enumName;
                            else
                                entryObj = getEntry(DataDictSec,dataType);
                                paramValue = getValue(entryObj);
                                if isequal(paramValue.DataType(1 : 4),'Enum')
                                    funcData(calNo).inArgSpc{inpNo}  =  paramValue.DataType(7 : length(paramValue.DataType));
                                else
                                    funcData(calNo).inArgSpc{inpNo}  =  paramValue.DataType;
                                end
                            end
                            funcData(calNo).inBase{inpNo} = napp.dataTypeMap(funcData(calNo).inArgSpc{inpNo});
                        end
                    else
                        funcData(calNo).inArg = [];
                    end

                    %* Checking usage of output and input arguments
                    dstBlk = cell.empty(1,0);
                    srcBlk = cell.empty(1,0);
                    portCon = get_param(allCaller(calNo),'PortConnectivity');
                    portCon = portCon{1};
                    for portNo = 1:length(portCon)
                        if ~isempty(portCon(portNo).SrcBlock)
                            srcBlk{length(srcBlk) + 1} = get_param(portCon(portNo).SrcBlock,'BlockType');
                        end
                        if ~isempty(portCon(portNo).DstBlock)
                            dstBlk{length(dstBlk) + 1} = get_param(portCon(portNo).DstBlock,'BlockType');
                        end
                    end
                    funcData(calNo).dstBlocks = dstBlk;
                    funcData(calNo).srcBlocks = srcBlk;
                end
                mdlData(1).funcData = funcData;

                glbConfig = struct('name',{},'appDataType',{},'baseDataType',{},'arxmlValue',{},'slddValue',{},'isUsed',{});
                gcEntries = find(DataDictSec,'-regexp','Name','GC_+');

                %? Collecting global configurations
                waitbar(((cmpNo-1)/length(napp.allASWCmp)) + (0.7/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Reading glb configs of ''%s'' model...',regexprep(cmpName,'_','\\_'))});
                if ~isempty(gcEntries)
                    for gcNo = 1:length(gcEntries)
                        param = getValue(gcEntries(gcNo));
                        glbConfig(gcNo).name = gcEntries(gcNo).Name;
                        if isequal(param.DataType(1 : 4),'Enum')
                            glbConfig(gcNo).appDataType = param.DataType(7 : length(param.DataType));
                        else
                            glbConfig(gcNo).appDataType = param.DataType;
                        end
                        glbConfig(gcNo).baseDataType = napp.dataTypeMap(glbConfig(gcNo).appDataType);
                        glbConfig(gcNo).slddValue = param.Value;
                        gcName = strsplit(glbConfig(gcNo).name,'_');
                        gcName = gcName(1 : length(gcName) - 2);
                        gcName{length(gcName) + 1} = 'P';
                        gcName = join(gcName,'_'); 
                        glbConfig(gcNo).arxmlValue = napp.glbConfigMap(gcName{1});
                        glbConst = find_system(cmpName,'BlockType','Constant', 'Value',glbConfig(gcNo).name);
                        glbPortConn = get_param(glbConst, 'PortConnectivity');
                        glbConfig(gcNo).isUsed = ~isequal(get_param(glbPortConn{1}.DstBlock, 'BlockType'),'Terminator');
                    end
                end
                mdlData(1).glbConfig = glbConfig;

                napp.allMdlData(cmpName) = mdlData(1);

                %?closing model files 
                while ~isempty(gcs)
                close_system(gcs,0);
                end
                Simulink.data.dictionary.closeAll
            end

            %! Saving autosar data in matFile
            tmpMat(napp, 1);
        end

        function readRteFiles(napp)
            % #define\s*(?<oldFun>\w*)\s*(?<xpFun>\w*) -> get expanded function call

            % (?<funProto>Std_ReturnType\s*\w*\s*\(\s*(const)*\s*\w*\**\s*\w*\)) -> get only function prototype
            % Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*\w*\**\s*(?<funArg>\w*)\) -> get funName and arg
            %! (?<funProto>Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*\w*\**\s*(?<funArg>\w*)\)) -> get function prototype (doesn't work -> MATLAB doesn't support nested tokens)

            % (?<paramFun>\w*\s*\w*\s*\(\w*\)\s*{\s*return\s*\w*;\s*}) -> get only parameter function definition
            % \w*\s*(?<oldFun>\w*)\s*\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*} ->get funName and return variable
            %! (?<paramFun>\w*\s*(?<oldFun>\w*)\s*\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*}) -> get parameter function definition (doesn't work -> MATLAB doesn't support nested tokens)

            % (?<funProto>\w*\s*Rte_Mode_\w*\s*\(void\)) -> get only function prototype
            % \w*\s*(?<oldFun>Rte_Mode_\w*)\s*\(void\) -> get funName
            %! (?<funProto>\w*\s*(?<oldFun>Rte_Mode_\w*)\s*\(void\)) -> get function calls without any inputs - which are not global configurations

            napp.rnblRteData = containers.Map();
            % [~,I] = sort({<structName>.<fieldName>}); & <structName> = <structName>(I); %* To sort a structure

            cd(napp.integPath);
            for cmpNo = 1 : length(napp.allASWCmp)
            % for cmpNo = 12
                cmpName = napp.allASWCmp(cmpNo).cmpName;
                cmpPath = napp.cmpDirMap(cmpName);

                waitbar(((cmpNo-1)/length(napp.allASWCmp)),napp.progBar,{'Collecting RTE data(3/5)',sprintf('Copying generated code of ''%s'' model...',regexprep(cmpName,'_','\\_'))});

                %? Copying code files
                copyfile([cmpPath '\Code'], napp.integPath);
                copyfile([cmpPath '\Code\' cmpName '_autosar_rtw\stub'], [napp.integPath '\' cmpName '_autosar_rtw']);
                copyfile([napp.integPath '\headerFiles'], [napp.integPath '\' cmpName '_autosar_rtw']);

                %? Reading Rte_<modelName> files
                glbConfigRteData = struct('paramDef',{},'retNames',{});
                headerRteData = struct('funProto',{},'argNames',{},'callExp',{}); 
                %* collecting global configuration data from 'Rte_<modelName>.c'
                if exist([napp.integPath '\' cmpName '_autosar_rtw\stub\Rte_' cmpName '.c'])
                    delete([napp.integPath '\' cmpName '_autosar_rtw\Rte_' cmpName '.c']);
                    data = fileread([napp.integPath '\' cmpName '_autosar_rtw\stub\Rte_' cmpName '.c']);
                    glbConfigRteData(1).paramDef = regexp(data,'(?<paramFun>\w*\s*\w*\s*\(\w*\)\s*{\s*return\s*\w*;\s*})','names');
                    glbConfigRteData(1).retNames = regexp(data,'\w*\s*(?<oldFun>\w*)\s*\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*}','names');
                end

                %* collecting rte function data from 'Rte_<modelName>.h'
                data = fileread([napp.integPath '\' cmpName '_autosar_rtw\Rte_' cmpName '.h']);
                headerRteData(1).funProto = regexp(data,'(?<funProto>Std_ReturnType\s*\w*\s*\(\s*(const)*\s*\w*\**\s*\w*\))','names');
                headerRteData(1).argNames = regexp(data,'Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*\w*\**\s*(?<funArg>\w*)\)','names');

                headerRteData(1).callExp = regexp(data,'#define\s*(?<oldFun>\w+)\s+(?<xpFun>\w+)','names');

                headerRteData(1).voidProto = regexp(data,'(?<funProto>\w*\s*Rte_Mode_\w*\s*\(void\))','names');
                % headerRteData(1).voidName = regexp(data,'\w*\s*(?<oldFun>Rte_Mode_\w*)\s*\(void\)','names');

                % Rte_Invalidate
                % find(contains({headerRteData.callExp.oldFun},mdlData.rnblData.outportData(1).portName))
                %? Updating rteData for rte call generation
                mdlData = napp.allMdlData(cmpName);
                for rnblNo = 1 : length(mdlData.rnblData)
                    rteGenerationData = struct('signalName',{},'portType',{},'funProto',{},'argName',{},'dataType',{},'varName',{},'defValue',{},'portName',{},'dataElement',{},'isBus',{},'isVoid',{});

                    for inpNo = 1 : length(mdlData.rnblData(rnblNo).inportData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.25 * inpNo/length(mdlData.rnblData(rnblNo).inportData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting receiver RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});

                        funNameIdx = find(contains({headerRteData.callExp.oldFun},mdlData.rnblData(rnblNo).inportData(inpNo).portName));
                        rteNo = length(rteGenerationData) + 1;
                        
                        rteGenerationData(rteNo).signalName = mdlData.rnblData(rnblNo).inportData(inpNo).portName;
                        rteGenerationData(rteNo).portType = 'inPort';

                        if ~isempty(funNameIdx)
                            %* Checking if rte function is generated (not generated if port is not connected)
                            funNo = 1;
                            while contains(headerRteData.callExp(funNameIdx(funNo)).oldFun,'Rte_Invalidate')
                                funNo = funNo + 1;
                            end

                            %* Getting function proto based on <oldFun> in callExp 
                            funProtoIdx = find(contains({headerRteData.funProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                            if ~isempty(funProtoIdx)
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.funProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);
                                funProtoIdx = find(contains({headerRteData.argNames.oldFun},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).argName = headerRteData.argNames(funProtoIdx(1)).funArg;
                                rteGenerationData(rteNo).isVoid = 0;
                            else
                                %* Getting void function prototype
                                funProtoIdx = find(contains({headerRteData.voidProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.voidProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);

                                rteGenerationData(rteNo).isVoid = 1;
                            end
                            rteGenerationData(rteNo).dataType = mdlData.rnblData(rnblNo).inportData(inpNo).baseDataType;
                            rteGenerationData(rteNo).isBus = mdlData.rnblData(rnblNo).inportData(inpNo).isBus;

                            portSplit = strsplit(rteGenerationData(rteNo).signalName,'_');
                            portSplit = portSplit(2 : length(portSplit));
                            rteGenerationData(rteNo).varName = strjoin(portSplit,'_');
                            
                            portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            rteGenerationData(rteNo).portName = portSplit.portName;
                            rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                            if ~isempty(portDefValues)
                                elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                rteGenerationData(rteNo).defValue = portDefValues(elemIdx).defValue;
                            else
                                % disp(rteGenerationData(rteNo).portName)
                                rteGenerationData(rteNo).defValue = 0;
                            end
                        end
                    end

                    for outNo = 1 : length(mdlData.rnblData(rnblNo).outportData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.5 * outNo/length(mdlData.rnblData(rnblNo).outportData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting sender RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});

                        funNameIdx = find(contains({headerRteData.callExp.oldFun},mdlData.rnblData(rnblNo).outportData(outNo).portName));
                        rteNo = length(rteGenerationData) + 1;
                        
                        rteGenerationData(rteNo).signalName = mdlData.rnblData(rnblNo).outportData(outNo).portName;
                        rteGenerationData(rteNo).portType = 'outPort';

                        if ~isempty(funNameIdx)
                            %* Checking if rte function is generated (not generated if port is not connected)
                            funNo = 1;
                            while contains(headerRteData.callExp(funNameIdx(funNo)).oldFun,'Rte_Invalidate')
                                funNo = funNo + 1;
                            end

                            %* Getting function proto based on <oldFun> in callExp 
                            funProtoIdx = find(contains({headerRteData.funProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                            if ~isempty(funProtoIdx)
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.funProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);
                                funProtoIdx = find(contains({headerRteData.argNames.oldFun},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).argName = headerRteData.argNames(funProtoIdx(1)).funArg;
                                rteGenerationData(rteNo).isVoid = 0;
                            else
                                %* Getting void function prototype
                                funProtoIdx = find(contains({headerRteData.voidProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.voidProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);

                                rteGenerationData(rteNo).isVoid = 1;
                            end
                            rteGenerationData(rteNo).dataType = mdlData.rnblData(rnblNo).outportData(outNo).baseDataType;
                            rteGenerationData(rteNo).isBus = mdlData.rnblData(rnblNo).outportData(outNo).isBus;

                            
                            portSplit = strsplit(rteGenerationData(rteNo).signalName,'_');
                            portSplit = portSplit(2 : length(portSplit));
                            rteGenerationData(rteNo).varName = strjoin(portSplit,'_');
                            
                            portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            rteGenerationData(rteNo).portName = portSplit.portName;
                            rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                            if ~isempty(portDefValues)
                                elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                rteGenerationData(rteNo).defValue = portDefValues(elemIdx).defValue;
                            else
                                % disp(rteGenerationData(rteNo).portName)
                                rteGenerationData(rteNo).defValue = 0;
                            end
                        end
                    end

                    for glbNo = 1 : length(mdlData.glbConfig)
                        if mdlData.glbConfig(glbNo).isUsed
                            waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.75 * glbNo/length(mdlData.glbConfig)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting glbConfig RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});

                            funNameIdx = find(contains({headerRteData.callExp.oldFun},mdlData.glbConfig(glbNo).name));
                            rteNo = length(rteGenerationData) + 1;
                            
                            rteGenerationData(rteNo).signalName = mdlData.glbConfig(glbNo).name;
                            rteGenerationData(rteNo).portType = 'glbConfig';

                            %* Getting function proto based on <oldFun> in callExp 
                            funProtoIdx = find(contains({glbConfigRteData.paramDef.paramFun},headerRteData.callExp(funNameIdx(1)).oldFun));
                            rteGenerationData(rteNo).funProto = regexprep(glbConfigRteData.paramDef(funProtoIdx(1)).paramFun, [headerRteData.callExp(funNameIdx(funNo)).oldFun '\s*('], [headerRteData.callExp(funNameIdx(funNo)).xpFun '(']);

                            
                            rteGenerationData(rteNo).dataType = mdlData.glbConfig(glbNo).baseDataType;
                            
                            
                            portSplit = strsplit(rteGenerationData(rteNo).signalName,'_');
                            portSplit = portSplit(2 : length(portSplit));
                            rteGenerationData(rteNo).varName = strjoin(portSplit,'_');
                            
                            glbConfDataIdx = find(contains({glbConfigRteData.retNames.oldFun},headerRteData.callExp(funNameIdx(1)).oldFun));
                            rteGenerationData(rteNo).funProto = strrep(rteGenerationData(rteNo).funProto, glbConfigRteData.retNames(glbConfDataIdx(1)).retVar, rteGenerationData(rteNo).varName);

                            portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            rteGenerationData(rteNo).portName = portSplit.portName;
                            rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            rteGenerationData(rteNo).defValue = mdlData.glbConfig(glbNo).arxmlValue;
                        end
                    end

                    %? sorting structure
                    [~,sortedIdx] = sort({rteGenerationData.portType});
                    napp.rnblRteData(mdlData.rnblData(rnblNo).rnblName) = rteGenerationData(sortedIdx);
                end
            end

            %! Saving autosar data in matFile
            tmpMat(napp, 1);
        end

        function createLCTBlocks(napp)
            cd(napp.integPath);
            
            autTypesMap = containers.Map({'boolean','sint16','sint32','sint8','uint16','uint32','uint8','float32','float64'},{'boolean_T','int16_T','int32_T','int8_T','uint16_T','uint32_T','uint8_T','real_T','real_T'});
            simTypesMap = containers.Map({'boolean_T','int16_T','int32_T','int8_T','uint16_T','uint32_T','uint8_T','real_T'},{'boolean','int16','int32','int8','uint16','uint32','uint8','double'});

            napp.lctData = struct('cmpName',{},'rnblName',{},'sFunName',{},'inputData',{},'outputData',{});
            napp.allPortMap = containers.Map();

            % for cmpNo = 1 : length(napp.allASWCmp)
            for cmpNo = 12
                cmpName = napp.allASWCmp(cmpNo).cmpName;
                mdlData = napp.allMdlData(cmpName);
                for rnblNo = 1 : length(mdlData.rnblData)
                    lctIdx = length(napp.lctData) + 1;
                    napp.lctData(lctIdx).cmpName = cmpName;
                    napp.lctData(lctIdx).rnblName = mdlData.rnblData(rnblNo).rnblName;
                    napp.lctData(lctIdx).sFunName = [cmpName '_Code_' mdlData.rnblData(rnblNo).rnblName];

                    rteCodeFid = fopen([[cmpName '_' mdlData.rnblData(rnblNo).rnblName '.c']],'w');
                    rteHeadFid = fopen([[cmpName '_' mdlData.rnblData(rnblNo).rnblName '.h']],'w');
                    
                    fprintf(rteCodeFid, '#include "%s_%s.h"\n\n', cmpName, mdlData.rnblData(rnblNo).rnblName);
                    fprintf(rteHeadFid, '#include "%s_autosar_rtw\%s.h"\n\n', cmpName, cmpName);

                    inputData = struct('portName',{},'dataElement',{},'sigName',{},'defValue',{},'autoType',{},'simType',{},'varName',{},'dataType',{},'isBus',{},'busElements',{});
                    outputData = inputData;
                    lctPortMap = containers.Map(); % Map of block port number to signal data element
                    inpNo = 0;
                    outNo = 0;
                    % prevOutPort = '';

                    rteData = napp.rnblRteData(mdlData.rnblData(rnblNo).rnblName);
                    for rteNo = 1 : length(rteData)
                        %* Creating global variable in psudo rte
                        fprintf(rteHeadFid, '%s %s;\n', rteData(rteNo).dataType, rteData(rteNo).varName);

                        %* Create rte function
                        % adding function prototype
                        fprintf(rteCodeFid, 'extern %s\n{\n', rteData(rteNo).funProto);
                        if isequal(rteData(rteNo).portType,'inPort')
                            %adding code to transfer data (*<funArg> = glbVar;)
                            if rteData(rteNo).isBus
                                busElems = napp.idtrStructMap(rteData(rteNo).dataType);
                                for elemNo = 1 : length(busElems)
                                    fprintf(rteCodeFid, '\t(*%s).%s = %s.%s;\n', rteData(rteNo).argName, busElems(elemNo).varName, rteData(rteNo).varName, busElems(elemNo).varName);

                                    inpNo = length(inputData) + 1; 
                                    inputData(inpNo).portName = rteData(rteNo).portName;
                                    inputData(inpNo).dataElement = rteData(rteNo).dataElement;
                                    inputData(inpNo).sigName = rteData(rteNo).signalName;
                                    inputData(inpNo).defValue = rteData(rteNo).defValue;
                                    inputData(inpNo).varName = rteData(rteNo).varName;
                                    inputData(inpNo).dataType = rteData(rteNo).dataType;
                                    inputData(inpNo).autoType = autTypesMap(rteData(rteNo).dataType);
                                    inputData(inpNo).simType = simTypesMap(inputData(inpNo).autoType);

                                    lctPortMap(busElems(elemNo).varName) = inpNo;
                                end
                            else
                                fprintf(rteCodeFid, '\t*%s = %s;\n', rteData(rteNo).argName, rteData(rteNo).varName);
                                %Adding inport data for connection ref
                                [inputData, lctPortMap] = lctPortData(inputData, lctPortMap, rteData(rteNo));
                            end
                            fprintf(rteCodeFid, '}\n');
                        elseif isequal(rteData(rteNo).portType,'outPort')
                            %adding code to transfer data (glbVar = <funArg>;)
                            if rteData(rteNo).isBus
                                busElems = napp.idtrStructMap(rteData(rteNo).dataType);
                                for elemNo = 1 : length(busElems)
                                    fprintf(rteCodeFid, '\t%s.%s = %s.%s;\n', rteData(rteNo).varName, busElems(elemNo).varName, rteData(rteNo).argName, busElems(elemNo).varName);
                                end
                            else
                                fprintf(rteCodeFid, '\t%s = %s;\n', rteData(rteNo).varName, rteData(rteNo).argName);
                            end
                            fprintf(rteCodeFid, '}\n');
                            %Adding inport data for connection ref
                            outNo = length(outputData) + 1; 
                            outputData(outNo).portName = rteData(rteNo).portName;
                            outputData(outNo).dataElement = rteData(rteNo).dataElement;
                            outputData(outNo).sigName = rteData(rteNo).signalName;
                            outputData(outNo).defValue = rteData(rteNo).defValue;
                            outputData(outNo).varName = rteData(rteNo).varName;
                            outputData(outNo).dataType = rteData(rteNo).dataType;
                            outputData(outNo).autoType = autTypesMap(rteData(rteNo).dataType);
                            outputData(outNo).simType = simTypesMap(outputData(outNo).autoType);

                            lctPortMap(outputData(outNo).dataElement) = outNo;
                        else
                            %Adding inport data for connection ref
                            inpNo = length(inputData) + 1; 
                            inputData(inpNo).portName = rteData(rteNo).portName;
                            inputData(inpNo).dataElement = rteData(rteNo).dataElement;
                            inputData(inpNo).sigName = rteData(rteNo).signalName;
                            inputData(inpNo).defValue = rteData(rteNo).defValue;
                            inputData(inpNo).varName = rteData(rteNo).varName;
                            inputData(inpNo).dataType = rteData(rteNo).dataType;
                            inputData(inpNo).autoType = autTypesMap(rteData(rteNo).dataType);
                            inputData(inpNo).simType = simTypesMap(inputData(inpNo).autoType);

                            lctPortMap(inputData(inpNo).dataElement) = inpNo;
                        end
                        fprintf(rteCodeFid, '\n');

                        if isequal(rteNo,length(rteData)) || ~isequal(rteData(rteNo).portName, rteData(rteNo + 1).portName)
                            napp.allPortMap([napp.lctData(lctIdx).cmpName '/' rteData(rteNo).portName]) = struct('sFunName',napp.lctData(lctIdx).sFunName,'portMap',lctPortMap);
                            lctPortMap = containers.Map(); % Resetting the map for next port
                        end
                    end

                    napp.lctData(lctIdx).inputData = inputData;
                    napp.lctData(lctIdx).outputData = outputData;

                    %? Add wrapper functions
                    %* Adding starter wrapper
                    fprintf(rteCodeFid, '//Start function - Initialization function wrapper\n');
                    % Adding function proto
                    fprintf(rteHeadFid, 'extern void %s_Start_wrapper(void);\n\n', napp.lctData(lctIdx).cmpName);

                    fprintf(rteCodeFid, 'void %s_Start_wrapper(void)\n{\n', napp.lctData(lctIdx).cmpName);
                    for outNo = 1 : length(napp.lctData(lctIdx).outputData)
                        if napp.lctData(lctIdx).outputData(outNo).isBus
                            busElems = napp.idtrStructMap(napp.lctData(lctIdx).outputData(outNo).dataType);
                            for elemNo = 1 : length(busElems)
                                fprintf(rteCodeFid, '%s.%s = 0;\n',napp.lctData(lctIdx).outputData(outNo).varName, busElems(elemNo).varName);
                            end
                        else
                            fprintf(rteCodeFid, '\t%s = %s;\n', napp.lctData(lctIdx).outputData(outNo).varName, napp.lctData(lctIdx).outputData(outNo).defValue);
                        end
                    end
                    fprintf(rteCodeFid, '%s_Init();\n',napp.lctData(lctIdx).cmpName);
                    fprintf(rteCodeFid, '}\n\n');

                    %* Adding output wrapper
                    fprintf(rteCodeFid, '//Output function - Runnable function wrapper\n');
                    % Adding function proto
                    fprintf(rteHeadFid, 'extern void %s_Outputs_wrapper(\n', napp.lctData(lctIdx).rnblName);
                    fprintf(rteCodeFid, 'extern void %s_Outputs_wrapper(\n', napp.lctData(lctIdx).rnblName);

                    for rteNo = 1 : length(rteData)
                        if isequal(rteData(rteNo).portType,'outPort')
                            % autTypesMap(rteData(rteNo).dataType)

                        else
                        end
                    end

                    %Adding legacy code block


                end
            end
        end

        function tmpMat(napp, writeData)
            cd(napp.integPath);
            
            if writeData == 1
                arxmlData.allASWCmp = napp.allASWCmp;
                arxmlData.delConMap = napp.delConMap;
                arxmlData.asmConn = napp.asmConn;
                arxmlData.dataTypeMap = napp.dataTypeMap;
                arxmlData.idtrStructMap = napp.idtrStructMap;
                arxmlData.defValueMap = napp.defValueMap;
                arxmlData.glbConfigMap = napp.glbConfigMap;
                modelData.allMdlData = napp.allMdlData;
                rteData = napp.rnblRteData;
                save('RootSWComposition_IntegrationData.mat','arxmlData','modelData','rteData');
            elseif exist('RootSWComposition_IntegrationData.mat')
                matVariables = load('RootSWComposition_IntegrationData.mat');
                napp.allASWCmp = matVariables.arxmlData.allASWCmp;
                napp.delConMap = matVariables.arxmlData.delConMap;
                napp.asmConn = matVariables.arxmlData.asmConn;
                napp.dataTypeMap = matVariables.arxmlData.dataTypeMap;
                napp.idtrStructMap = matVariables.arxmlData.idtrStructMap;
                napp.defValueMap = matVariables.arxmlData.defValueMap;
                napp.glbConfigMap = matVariables.arxmlData.glbConfigMap;
                matNames = who('-file', 'RootSWComposition_IntegrationData.mat');
                if ismember('modelData', matNames)
                    napp.allMdlData = matVariables.modelData.allMdlData;
                end
                if ismember('rteData', matNames)
                    napp.rnblRteData = matVariables.rteData;
                end
            end
        end
    end

    methods (Static)
        function cmpDirMap = getComponentPath(srcPath)
            allDir = dir(srcPath);
            cmpDirMap = containers.Map();
            for dirNo = 1 : length(allDir)
                if ~isequal(allDir(dirNo).name,'.') && ~isequal(allDir(dirNo).name,'..')
                    codeDir = dir([allDir(dirNo).folder '\' allDir(dirNo).name '\Code']);
                    cmpDirMap(codeDir(3).name(1:length(codeDir(3).name) - 12)) = [allDir(dirNo).folder '\' allDir(dirNo).name];
                end
            end
        end

        function portData = getPortData(portData, portNo, portHandle, dataTypeMap)
            portData(portNo).portName = get_param(portHandle,'Name');
            portData(portNo).isBus = 0;
            outDataType = get_param(portHandle,'OutDataTypeStr');
            if isequal(outDataType(1 : 4),'Enum')
                portData(portNo).appDataType =  outDataType(7 : length(outDataType));
            elseif isequal(outDataType(1 : 3),'Bus')
                portData(portNo).appDataType =  outDataType(6 : length(outDataType));
                portData(portNo).isBus = 1;
            else
                portData(portNo).appDataType =  outDataType;
            end
            portData(portNo).baseDataType = dataTypeMap(portData(portNo).appDataType);
        end

        function [portData, lctPortMap] = lctPortData(portData, portNo, lctPortMap, rteData)
            inpNo = length(portData) + 1; 
            portData(inpNo).portName = rteData.portName;
            portData(inpNo).dataElement = rteData.dataElement;
            portData(inpNo).sigName = rteData.signalName;
            portData(inpNo).defValue = rteData.defValue;
            portData(inpNo).varName = rteData.varName;
            portData(inpNo).dataType = rteData.dataType;
            portData(inpNo).isBus = rteData.isBus;
            portData(inpNo).autoType = autTypesMap(portData(inpNo).dataType);
            portData(inpNo).simType = simTypesMap(portData(inpNo).autoType);

            lctPortMap(portData(inpNo).dataElement) = portNo;
        end

        function portDefValues = getDefValues(defValueMap, portName)
            if ~isKey(defValueMap,portName)
                if isequal(portName((length(portName) - 1):length(portName)), '_R')
                    portName = [portName(1:(length(portName) - 2)) '_P'];
                else
                    portName = [portName(1:(length(portName) - 2)) '_R'];
                end
            end

            if ~isKey(defValueMap,portName)
                portDefValues = '';
            else
                portDefValues = defValueMap(portName);
            end
        end
    end
end