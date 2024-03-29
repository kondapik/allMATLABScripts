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
        
        missingPorts = struct('rnblName',{} ,'signalName',{} ,'portType',{}); %! Sneak peak code
    end

    methods (Access = public)
        function napp = codeIntegration()
            %bdclose('all');
            currFolder = pwd;

            % [napp.arxmlName, napp.arxmlPath] = uigetfile({'*.arxml','AUTOSAR XML (*.arxml)'},'Select root ARXML');
            % napp.sourcePath = uigetdir(currFolder,'Select ASW source folder with all delivery artifacts');
            % napp.integPath = uigetdir(currFolder,'Select path to save integrated model');

            napp.arxmlName = 'RootSWComposition.arxml';
            % napp.arxmlPath = 'D:\R0019983\Branches\OBC_A3_1\20_Design\ASW\SW_Composition_ARXML';
            % napp.sourcePath = 'D:\R0019983\Branches\OBC_A3_1\30_Software\Source\ASW';
            % napp.integPath = 'D:\Temp_Project\ASW_Integration\integrationBuildTest';
            % napp.integPath = 'D:\MATLAB\ASW_Integration\integrationBuildTest';

            napp.arxmlPath = 'D:\R0019983\Branches\OBC_A4\20_Design\ASW\SW_Composition_ARXML';
            napp.sourcePath = 'D:\R0019983\Branches\OBC_A4\30_Software\Source\ASW';
            napp.integPath = 'D:\MATLAB\ASW_Integration\a4BuildTest';

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
                    if ismember('rteData', matNames)
                        createLCTBlocks(napp)
                    elseif ismember('modelData', matNames)
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
            cmpBlackList = {'EcuM', 'BSW_components', 'IoHwAb_Adc_SWC', 'IoHwAb_Dio_SWC', 'IoHwAb_Icu_SWC', 'IoHwAb_Pwm_SWC', 'Bswm', 'CDD_BSW', 'CDD_CHAdeMO', 'CDD_GBT', 'CDD_SBC',...
                             'CDD_V2G', 'Dcm', 'GlbConfg', 'NvBlockSwc_Appl', 'Dem', 'NvBlockSwc_V2G', 'ComM', 'Det', 'NvM'};
            for appNo  = 0 : allApp.getLength - 1
                waitbar(0.1*(appNo/(allApp.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting ASW component names...')});

                appName = allApp.item(appNo).getElementsByTagName('TYPE-TREF');
                tgt = strsplit(char(appName.item(0).getFirstChild.getData),'/');
                
            %     applName = allApp.item(i).getElementsByTagName('SHORT-NAME');
            %     findIdx = find(contains(exclName,char(applName.item(0).getFirstChild.getData)));
                if ~isempty(find(contains(cmpBlackList, tgt{3}), 1)) || isequal(tgt{2},'SwCompositions')
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
                        napp.asmConn(length(napp.asmConn)).prvPort = '';
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
                        napp.asmConn(connIdx).rcvPort = '';
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
                waitbar(0.4 + 0.075*(dataNo/(allDataTypes.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Mapping base data types...')});

                adtsType = allDataTypes.item(dataNo).getElementsByTagName('APPLICATION-DATA-TYPE-REF');
                if adtsType.getLength
                    adtsType = strsplit(char(adtsType.item(0).getFirstChild.getData),'/');

                    impType = allDataTypes.item(dataNo).getElementsByTagName('IMPLEMENTATION-DATA-TYPE-REF');
                    impType = strsplit(char(impType.item(0).getFirstChild.getData),'/');

                    napp.dataTypeMap(adtsType{length(adtsType)}) = impType{length(impType)};
                end
            end

            %? Base data type map for mode request data types
            allDataTypes = xDoc.getElementsByTagName('MODE-REQUEST-TYPE-MAP');

            for dataNo  = 0 : allDataTypes.getLength - 1
                waitbar(0.475 + 0.025*(dataNo/(allDataTypes.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Mapping base data types...')});

                adtsType = allDataTypes.item(dataNo).getElementsByTagName('MODE-GROUP-REF');
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
                    if isKey(nvSpecMap, [portName(4 : length(portName) - 2) '_BD'])
                        napp.defValueMap(portName) = nvSpecMap([portName(4 : length(portName) - 2) '_BD']);
                    else
                        napp.defValueMap(portName) = 0;
                        fprintf('Default of ''%s'' NV port not found, giving value of 0\n', portName)
                    end
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
                    if isKey(nvSpecMap, [portName(4 : length(portName) - 2) '_BD'])
                        napp.defValueMap(portName) = nvSpecMap([portName(4 : length(portName) - 2) '_BD']);
                    else
                        napp.defValueMap(portName) = 0;
                        fprintf('Default of ''%s'' NV port not found, giving value of 0\n', portName)
                    end
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

            simDataTypes = {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','boolean'};

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
                
                % slMap = autosar.api.getSimulinkMapping(gcs)
                % [arPortName,arDataElementName,arDataAccessMode]=getInport(slMap,inprocICAN(2).signalName) %ErrorStatus -> for error messages -> RTE_E_TIMEOUT (uint8 - 64)
                % [arPortName,arDataElementName,arDataAccessMode]=getOutport(slMap,inprocICAN(1).signalName)
                % [arPortName,arOperationName]=getFunctionCaller(slMap,get_param(gcb,'name'))
                % arDataAccessMode -> 'ErrorStatus'

                autosarMap = autosar.api.getSimulinkMapping(cmpName);

                waitbar(((cmpNo-1)/length(napp.allASWCmp)) + (0.1/length(napp.allASWCmp)),napp.progBar,{'Collecting model data(2/5)',sprintf('Reading port data of ''%s'' model...',regexprep(cmpName,'_','\\_'))});
                for rnblNo = 1 : length(mdlRnbls)
                    %? initializing structures
                    inportData = struct('signalName',{},'portName',{},'dataElementName',{},'retError',{},'appDataType',{},'baseDataType',{},'isBus',{});
                    outportData = struct('signalName',{},'portName',{},'dataElementName',{},'retError',{},'appDataType',{},'baseDataType',{},'isBus',{});
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
                                inportData = napp.getPortData(inportData, inportNo, portHandle, autosarMap, napp.dataTypeMap, simDataTypes);
                            else
                                %* Collecting outport Data
                                outportNo = length(outportData) + 1;
                                outportData = napp.getPortData(outportData, outportNo, portConn(portNo).DstBlock, autosarMap, napp.dataTypeMap, simDataTypes);
                            end
                        end
                    end
                    rnblData(rnblNo).inportData = inportData;
                    rnblData(rnblNo).outportData = outportData;
                end
                mdlData(1).rnblData = rnblData;

                funcData = struct('functionProto',{},'funcName',{},'portName',{},'oprName',{},'inArg',{},'outArg',{},'inArgSpc',{},'inBase',{},'outArgSpc',{},'outBase',{},'dstBlocks',{},'srcBlocks',{});


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
                    [funcData(calNo).portName,funcData(calNo).oprName] = getFunctionCaller(autosarMap, funcData(calNo).funcName);

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

            %! Saving model data in matFile
            tmpMat(napp, 2);
        end

        function readRteFiles(napp)
            % #define\s*(?<oldFun>\w*)\s*(?<xpFun>\w*) -> get expanded function call

            % (?<funProto>Std_ReturnType\s*\w*\s*\(\s*(const)*\s*\w*\**\s*\w*\)) -> get only function prototype
            % Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*\w*\**\s*(?<funArg>\w*)\) -> get funName and arg

            % (?<funProto>Std_ReturnType\s*\w*\s*\(\s*(const)*\s*(,*\s*\w+\**\s*\w*){1,}\))
            % Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*(?<funArg>(,*\s*\w+\**\s*\w*){1,})\)
            % \s*(const)*\s*(?<dataType>\w*)\**\s*(?<argName>\w*) -> get data type and argument name from delimited function argument
            %* if needed check if argument is 'void' (after removing trailing spaces)...
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
                headerRteData(1).funProto = regexp(data,'(?<funProto>Std_ReturnType\s*\w*\s*\(\s*(const)*\s*(,*\s*\w+\**\s*\w*){1,}\))','names');
                headerRteData(1).argNames = regexp(data,'Std_ReturnType\s*(?<oldFun>\w*)\s*\(\s*(const)*\s*(?<funArg>(,*\s*\w+\**\s*\w*){1,})\)','names');

                headerRteData(1).callExp = regexp(data,'#define\s*(?<oldFun>\w+)\s+(?<xpFun>\w+)','names');

                headerRteData(1).voidProto = regexp(data,'(?<funProto>\w*\s*Rte_Mode_\w*\s*\(void\))','names');
                % headerRteData(1).voidName = regexp(data,'\w*\s*(?<oldFun>Rte_Mode_\w*)\s*\(void\)','names');

                % Rte_Invalidate
                % find(contains({headerRteData.callExp.oldFun},mdlData.rnblData.outportData(1).portName))
                %? Updating rteData for rte call generation
                mdlData = napp.allMdlData(cmpName);
                for rnblNo = 1 : length(mdlData.rnblData)
                    rteGenerationData = struct('signalName',{},'portType',{},'funProto',{},'argName',{},'dataType',{},'varName',{},'defValue',{},'portName',{},'dataElement',{},'retError',{},'isBus',{},'isVoid',{},'dataTypeMisMatch',{},'doNothing',{});

                    for inpNo = 1 : length(mdlData.rnblData(rnblNo).inportData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.25 * inpNo/length(mdlData.rnblData(rnblNo).inportData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting receiver RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});
                        
                        funNameIdx = find(contains({headerRteData.callExp.oldFun},mdlData.rnblData(rnblNo).inportData(inpNo).signalName));

                        if ~isempty(funNameIdx)
                            rteNo = length(rteGenerationData) + 1;
                            
                            rteGenerationData(rteNo).signalName = mdlData.rnblData(rnblNo).inportData(inpNo).signalName;
                            rteGenerationData(rteNo).portType = 'inPort';
                            rteGenerationData(rteNo).retError = mdlData.rnblData(rnblNo).inportData(inpNo).retError;

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
                                [rteGenerationData(rteNo).argName, rteGenerationData(rteNo).dataType, rteGenerationData(rteNo).dataTypeMisMatch] = napp.getFunArg(headerRteData.argNames(funProtoIdx(1)).funArg, mdlData.rnblData(rnblNo).inportData(inpNo).baseDataType);
                                % rteGenerationData(rteNo).argName = headerRteData.argNames(funProtoIdx(1)).funArg;
                                rteGenerationData(rteNo).isVoid = 0;
                            else
                                %* Getting void function prototype
                                funProtoIdx = find(contains({headerRteData.voidProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.voidProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);

                                rteGenerationData(rteNo).isVoid = 1;
                            end
                            % rteGenerationData(rteNo).dataType = mdlData.rnblData(rnblNo).inportData(inpNo).baseDataType;
                            rteGenerationData(rteNo).isBus = mdlData.rnblData(rnblNo).inportData(inpNo).isBus;

                            rteGenerationData(rteNo).portName = mdlData.rnblData(rnblNo).inportData(inpNo).portName;
                            rteGenerationData(rteNo).dataElement = mdlData.rnblData(rnblNo).inportData(inpNo).dataElementName;

                            portSplit = strsplit(rteGenerationData(rteNo).signalName,'_');
                            portSplit = portSplit(2 : length(portSplit));
                            rteGenerationData(rteNo).varName = strjoin(portSplit,'_');
                            
                            % portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            % rteGenerationData(rteNo).portName = portSplit.portName;
                            % rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                            if ~isempty(portDefValues)
                                elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                rteGenerationData(rteNo).defValue = portDefValues(elemIdx).defValue;
                            else
                                % disp(rteGenerationData(rteNo).portName)
                                rteGenerationData(rteNo).defValue = 0;
                            end
                        % else
                        %     %! Sneak peak code
                        %     misLen = length(napp.missingPorts) + 1;
                        %     napp.missingPorts(misLen).rnblName = mdlData.rnblData(rnblNo).rnblName;
                        %     napp.missingPorts(misLen).signalName = mdlData.rnblData(rnblNo).inportData(inpNo).signalName;
                        %     napp.missingPorts(misLen).portType = 'inPort';
                        %     disp(mdlData.rnblData(rnblNo).inportData(inpNo).signalName)
                        end
                    end

                    for outNo = 1 : length(mdlData.rnblData(rnblNo).outportData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.5 * outNo/length(mdlData.rnblData(rnblNo).outportData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting sender RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});

                        funNameIdx = find(contains({headerRteData.callExp.oldFun},mdlData.rnblData(rnblNo).outportData(outNo).signalName));

                        if ~isempty(funNameIdx)
                            rteNo = length(rteGenerationData) + 1;
                            
                            rteGenerationData(rteNo).signalName = mdlData.rnblData(rnblNo).outportData(outNo).signalName;
                            rteGenerationData(rteNo).portType = 'outPort';
                            rteGenerationData(rteNo).retError = mdlData.rnblData(rnblNo).outportData(outNo).retError;

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
                                [rteGenerationData(rteNo).argName, rteGenerationData(rteNo).dataType, rteGenerationData(rteNo).dataTypeMisMatch] = napp.getFunArg(headerRteData.argNames(funProtoIdx(1)).funArg, mdlData.rnblData(rnblNo).outportData(outNo).baseDataType);
                                % rteGenerationData(rteNo).argName = headerRteData.argNames(funProtoIdx(1)).funArg;
                                rteGenerationData(rteNo).isVoid = 0;
                            else
                                %* Getting void function prototype
                                funProtoIdx = find(contains({headerRteData.voidProto.funProto},headerRteData.callExp(funNameIdx(funNo)).oldFun));
                                rteGenerationData(rteNo).funProto = strrep(headerRteData.voidProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(funNo)).oldFun, headerRteData.callExp(funNameIdx(funNo)).xpFun);

                                rteGenerationData(rteNo).isVoid = 1;
                            end
                            % rteGenerationData(rteNo).dataType = mdlData.rnblData(rnblNo).outportData(outNo).baseDataType;
                            rteGenerationData(rteNo).isBus = mdlData.rnblData(rnblNo).outportData(outNo).isBus;

                            rteGenerationData(rteNo).portName = mdlData.rnblData(rnblNo).outportData(outNo).portName;
                            rteGenerationData(rteNo).dataElement = mdlData.rnblData(rnblNo).outportData(outNo).dataElementName;
                            
                            portSplit = strsplit(rteGenerationData(rteNo).signalName,'_');
                            portSplit = portSplit(2 : length(portSplit));
                            rteGenerationData(rteNo).varName = strjoin(portSplit,'_');
                            
                            % portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            % rteGenerationData(rteNo).portName = portSplit.portName;
                            % rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                            if ~isempty(portDefValues)
                                elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                rteGenerationData(rteNo).defValue = portDefValues(elemIdx).defValue;
                            else
                                % disp(rteGenerationData(rteNo).portName)
                                rteGenerationData(rteNo).defValue = 0;
                            end
                        % else
                        %     %! Sneak peak code
                        %     misLen = length(napp.missingPorts) + 1;
                        %     napp.missingPorts(misLen).rnblName = mdlData.rnblData(rnblNo).rnblName;
                        %     napp.missingPorts(misLen).signalName = mdlData.rnblData(rnblNo).outportData(outNo).signalName;
                        %     napp.missingPorts(misLen).portType = 'outPort';
                        %     disp(mdlData.rnblData(rnblNo).outportData(outNo).portName)
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
                            rteGenerationData(rteNo).funProto = strrep(rteGenerationData(rteNo).funProto, glbConfigRteData.retNames(glbConfDataIdx(1)).retVar, rteGenerationData(rteNo).signalName);

                            portSplit = regexp(rteGenerationData(rteNo).signalName,'(?<portName>\w+_(P|R))_(?<dataElem>\w+)','names');
                            rteGenerationData(rteNo).portName = portSplit.portName;
                            rteGenerationData(rteNo).dataElement = portSplit.dataElem;

                            rteGenerationData(rteNo).defValue = mdlData.glbConfig(glbNo).arxmlValue;
                        end
                    end

                    %! Add client - server functions
                    for funcNo = 1 : length(mdlData.funcData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((funcNo/length(mdlData.funcData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Collecting RTE data(3/5)',sprintf('Collecting client - server RTE calls of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});
                        
                        funNameIdx = find(contains({headerRteData.callExp.oldFun}, mdlData.funcData(funcNo).funcName));
                        rteNo = length(rteGenerationData) + 1;

                        %* Getting function proto based on <oldFun> in callExp 
                        funProtoIdx = find(contains({headerRteData.funProto.funProto},headerRteData.callExp(funNameIdx(1)).oldFun));
                        rteGenerationData(rteNo).funProto = strrep(headerRteData.funProto(funProtoIdx(1)).funProto, headerRteData.callExp(funNameIdx(1)).oldFun, headerRteData.callExp(funNameIdx(1)).xpFun);

                        % Checking if function caller is used i.e connected to something
                        if ~((isempty(mdlData.funcData(funcNo).dstBlocks) || isequal(mdlData.funcData(funcNo).dstBlocks, repmat({'Terminator'},size(mdlData.funcData(funcNo).dstBlocks)))) && ...
                            (isempty(mdlData.funcData(funcNo).srcBlocks) || isequal(mdlData.funcData(funcNo).srcBlocks, repmat({'Ground'},size(mdlData.funcData(funcNo).srcBlocks)))))
                            
                            %TODO client server interfaces are not void functions and doest return a structure (at least for the moment)
                            rteGenerationData(rteNo).isVoid = 0;
                            rteGenerationData(rteNo).isBus = 0;

                            splitName = strsplit(mdlData.funcData(funcNo).portName,'_');
                            smlPortName = strjoin(splitName(2 : length(splitName)),'_');
                            funArgNo = 0;
                            for funInpNo = 1 : length(mdlData.funcData(funcNo).inArg)
                                if ~isequal(mdlData.funcData(funcNo).srcBlocks{funInpNo},'Ground')
                                    funArgNo = funArgNo + 1;
                                    rteGenerationData(rteNo).signalName{funArgNo} = [mdlData.funcData(funcNo).portName '_' mdlData.funcData(funcNo).oprName '_' mdlData.funcData(funcNo).inArg{funInpNo}];
                                    rteGenerationData(rteNo).portType{funArgNo} = 'outPort';
                                    [rteGenerationData(rteNo).argName{funArgNo}, rteGenerationData(rteNo).dataType{funArgNo}, rteGenerationData(rteNo).dataTypeMisMatch{funArgNo}] = ...
                                    napp.getFunArg(headerRteData.argNames(funProtoIdx(1)).funArg, mdlData.funcData(funcNo).inBase{funInpNo}, mdlData.funcData(funcNo).inArg{funInpNo});

                                    rteGenerationData(rteNo).portName{funArgNo} = mdlData.funcData(funcNo).portName;
                                    rteGenerationData(rteNo).dataElement{funArgNo} = [mdlData.funcData(funcNo).oprName '_' mdlData.funcData(funcNo).inArg{funInpNo}];
                                    rteGenerationData(rteNo).varName{funArgNo} = [smlPortName '_' mdlData.funcData(funcNo).inArg{funInpNo}];

                                    rteGenerationData(rteNo).defValue{funArgNo} = 0; %default value not found in arxml

                                    % portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                                    % if ~isempty(portDefValues)
                                    %     elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                    %     rteGenerationData(rteNo).defValue{funArgNo} = portDefValues(elemIdx).defValue;
                                    % else
                                    %     % disp(rteGenerationData(rteNo).portName)
                                    %     rteGenerationData(rteNo).defValue{funArgNo} = 0;
                                    % end
                                end
                            end

                            for funOutNo = 1 : length(mdlData.funcData(funcNo).outArg)
                                if ~isequal(mdlData.funcData(funcNo).dstBlocks{funOutNo},'Terminator')
                                    funArgNo = funArgNo + 1;
                                    rteGenerationData(rteNo).signalName{funArgNo} = [mdlData.funcData(funcNo).portName '_' mdlData.funcData(funcNo).oprName '_' mdlData.funcData(funcNo).outArg{funOutNo}];
                                    rteGenerationData(rteNo).portType{funArgNo} = 'inPort';
                                    [rteGenerationData(rteNo).argName{funArgNo}, rteGenerationData(rteNo).dataType{funArgNo}, rteGenerationData(rteNo).dataTypeMisMatch{funArgNo}] = ...
                                    napp.getFunArg(headerRteData.argNames(funProtoIdx(1)).funArg, mdlData.funcData(funcNo).outBase{funOutNo}, mdlData.funcData(funcNo).outArg{funOutNo});

                                    rteGenerationData(rteNo).portName{funArgNo} = mdlData.funcData(funcNo).portName;
                                    rteGenerationData(rteNo).dataElement{funArgNo} = [mdlData.funcData(funcNo).oprName '_' mdlData.funcData(funcNo).outArg{funOutNo}];
                                    rteGenerationData(rteNo).varName{funArgNo} = [smlPortName '_' mdlData.funcData(funcNo).outArg{funOutNo}];

                                    rteGenerationData(rteNo).defValue{funArgNo} = 0; %default value not found in arxml
                                   
                                    % portDefValues = napp.getDefValues(napp.defValueMap, rteGenerationData(rteNo).portName);
                                    % if ~isempty(portDefValues)
                                    %     elemIdx = find(contains({portDefValues.elemName},rteGenerationData(rteNo).dataElement));
                                    %     rteGenerationData(rteNo).defValue{funArgNo} = portDefValues(elemIdx).defValue;
                                    % else
                                    %     % disp(rteGenerationData(rteNo).portName)
                                    %     rteGenerationData(rteNo).defValue{funArgNo} = 0;
                                    % end
                                end
                            end
                            % [rteGenerationData(rteNo).argName, rteGenerationData(rteNo).dataType, rteGenerationData(rteNo).dataTypeMisMatch] = napp.getFunArg(headerRteData.argNames(funProtoIdx(1)).funArg, mdlData.rnblData(rnblNo).inportData(inpNo).baseDataType);
                        else
                            rteGenerationData(rteNo).doNothing = 1;
                            rteGenerationData(rteNo).portType{1} = 'noPort';
                        end
                    end

                    % %? sorting structure
                    % [~,sortedIdx] = sort({rteGenerationData.portType});
                    % napp.rnblRteData(mdlData.rnblData(rnblNo).rnblName) = rteGenerationData(sortedIdx);
                    napp.rnblRteData(mdlData.rnblData(rnblNo).rnblName) = rteGenerationData;
                end
            end

            %! Saving rte data in matFile
            tmpMat(napp, 3);
        end

        function createLCTBlocks(napp)
            cd(napp.integPath);
            
            testMode = 1;

            autTypesMap = containers.Map({'boolean','sint16','sint32','sint8','uint16','uint32','uint8','float32','float64'},{'boolean_T','int16_T','int32_T','int8_T','uint16_T','uint32_T','uint8_T','real_T','real_T'});
            simTypesMap = containers.Map({'boolean_T','int16_T','int32_T','int8_T','uint16_T','uint32_T','uint8_T','real_T'},{'boolean','int16','int32','int8','uint16','uint32','uint8','double'});

            napp.lctData = struct('cmpName',{},'rnblName',{},'sampleTime',{},'sFunName',{},'inputData',{},'outputData',{}, 'codePreFill',{});
            napp.allPortMap = containers.Map();

            if testMode
                tstDirMap = napp.getTestingPath('D:\R0019983\Branches\OBC_A4\60_Testing\ASW');
            end
            
            rteErrDef = 'RTE_E_OK'; %* default return value of RTE calls which return errors
            rteErrType = 'uint8';

            % for cmpNo = 1 : length(napp.allASWCmp)
            for cmpNo = 1
                cmpName = napp.allASWCmp(cmpNo).cmpName;
                mdlData = napp.allMdlData(cmpName);
                for rnblNo = 1 : length(mdlData.rnblData)
                    lctIdx = length(napp.lctData) + 1;
                    napp.lctData(lctIdx).cmpName = cmpName;
                    napp.lctData(lctIdx).rnblName = mdlData.rnblData(rnblNo).rnblName;
                    napp.lctData(lctIdx).sampleTime = mdlData.rnblData(rnblNo).sampleTime;
                    napp.lctData(lctIdx).sFunName = [cmpName '_Code_' mdlData.rnblData(rnblNo).rnblName];

                    rteCodeFid = fopen([cmpName '_' mdlData.rnblData(rnblNo).rnblName '.c'],'w');
                    rteHeadFid = fopen([cmpName '_' mdlData.rnblData(rnblNo).rnblName '.h'],'w');
                    
                    fprintf(rteCodeFid, '#include "%s_%s.h"\n\n', cmpName, mdlData.rnblData(rnblNo).rnblName);
                    fprintf(rteHeadFid, '#include "%s_autosar_rtw\\%s.h"\n\n', cmpName, cmpName);

                    inputData = struct('portName',{},'dataElement',{},'argName',{},'sigName',{},'defValue',{},'autoType',{},'simType',{},'varName',{},'dataType',{},'isBus',{},'busElement',{},'isError',{},'isGlbConfig',{}, 'isCSI',{});
                    outputData = inputData;
                    lctPortMap = containers.Map(); % Map of block port number to signal data element
                    inpNo = 0;
                    outNo = 0;
                    % prevOutPort = '';

                    % collecting text for default value assignment (startup wrapper), input and output variable argument (output wrapper declaration), input and output variable assignment (output wrapper definition)
                    codePreFill = struct('defValueAssign', '', 'inputVarArg', '', 'outputVarArg', '', 'inputVarAssign', '','outputVarAssign', '','lctInpSpec', '', 'lctOutSpec', '');

                    rteData = napp.rnblRteData(mdlData.rnblData(rnblNo).rnblName);
                    for rteNo = 1 : length(rteData)
                        waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((0.5 * rteNo/length(rteData)) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Creating LCT blocks(4/5)',sprintf('Writing RTE functions of ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});
                        %* Create rte function
                        % adding function prototype
                        fprintf(rteCodeFid, 'extern %s\n{\n', rteData(rteNo).funProto);
                        if isequal(rteData(rteNo).portType,'inPort')
                            %* Creating global variable in psudo rte
                            fprintf(rteHeadFid, '%s %s;\n', rteData(rteNo).dataType, rteData(rteNo).signalName);

                            %adding code to transfer data (*<funArg> = glbVar;)
                            if rteData(rteNo).isBus
                                busElems = napp.idtrStructMap(rteData(rteNo).dataType);
                                for elemNo = 1 : length(busElems)
                                    fprintf(rteCodeFid, '\t(*%s).%s = %s.%s;\n', rteData(rteNo).argName, busElems(elemNo).varName, rteData(rteNo).signalName, busElems(elemNo).varName);

                                    [inputData, inpNo, lctPortMap] = napp.lctPortData(inputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap, 'busSignal', busElems(elemNo).varName, busElems(elemNo).dataType);

                                    codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 inputData(inpNo).sigName '.' inputData(inpNo).busElement ' = ' inputData(inpNo).defValue ';']; 
                                    codePreFill.inputVarArg = [codePreFill.inputVarArg 10 9 9 9 inputData(inpNo).autoType ' *u' num2str(inpNo) ','];
                                    codePreFill.lctInpSpec = [codePreFill.lctInpSpec ' ' inputData(inpNo).simType ' u' num2str(inpNo) '[1],'];
                                    codePreFill.inputVarAssign = [codePreFill.inputVarAssign 10 9 inputData(inpNo).sigName '.' inputData(inpNo).busElement ' = *u' num2str(inpNo) ';'];
                                end
                            else
                                fprintf(rteCodeFid, '\t*%s = %s;\n', rteData(rteNo).argName, rteData(rteNo).signalName);
                                %Adding inport data for connection ref
                                [inputData, inpNo, lctPortMap] = napp.lctPortData(inputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap);

                                codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 inputData(inpNo).sigName ' = ' inputData(inpNo).defValue ';']; 
                                codePreFill.inputVarArg = [codePreFill.inputVarArg 10 9 9 9 inputData(inpNo).autoType ' *u' num2str(inpNo) ','];
                                codePreFill.lctInpSpec = [codePreFill.lctInpSpec ' ' inputData(inpNo).simType ' u' num2str(inpNo) '[1],'];
                                codePreFill.inputVarAssign = [codePreFill.inputVarAssign 10 9 inputData(inpNo).sigName ' = *u' num2str(inpNo) ';'];
                            end

                            % rte error is uint8 and default value
                            napp.rteErrorRet(inputData, rteData(rteNo), rteErrDef, rteErrType, rteHeadFid, rteCodeFid, codePreFill, autTypesMap, simTypesMap);

                            fprintf(rteCodeFid, '}\n');
                        elseif isequal(rteData(rteNo).portType,'outPort')
                            %* Creating global variable in psudo rte
                            fprintf(rteHeadFid, '%s %s;\n', rteData(rteNo).dataType, rteData(rteNo).signalName);

                            %adding code to transfer data (glbVar = <funArg>;)
                            if rteData(rteNo).isBus
                                busElems = napp.idtrStructMap(rteData(rteNo).dataType);
                                for elemNo = 1 : length(busElems)
                                    fprintf(rteCodeFid, '\t%s.%s = %s.%s;\n', rteData(rteNo).signalName, busElems(elemNo).varName, rteData(rteNo).argName, busElems(elemNo).varName);
                                    [outputData, outNo, lctPortMap] = napp.lctPortData(outputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap, 'busSignal', busElems(elemNo).varName, busElems(elemNo).dataType);

                                    codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 outputData(outNo).sigName '.' outputData(outNo).busElement ' = ' outputData(outNo).defValue ';']; 
                                    codePreFill.outputVarArg = [codePreFill.outputVarArg 10 9 9 9 outputData(outNo).autoType ' *y' num2str(outNo) ','];
                                    codePreFill.lctOutSpec = [codePreFill.lctOutSpec ' ' outputData(outNo).simType ' y' num2str(outNo) '[1],'];
                                    codePreFill.outputVarAssign = [codePreFill.outputVarAssign 10 9  '*y' num2str(outNo) ' = ' outputData(outNo).sigName '.' outputData(outNo).busElement ';'];
                                end
                            else
                                fprintf(rteCodeFid, '\t%s = %s;\n', rteData(rteNo).signalName, rteData(rteNo).argName);
                                [outputData, outNo, lctPortMap] = napp.lctPortData(outputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap);

                                codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 outputData(outNo).sigName ' = ' outputData(outNo).defValue ';']; 
                                codePreFill.outputVarArg = [codePreFill.outputVarArg 10 9 9 9 outputData(outNo).autoType ' *y' num2str(outNo) ','];
                                codePreFill.lctOutSpec = [codePreFill.lctOutSpec ' ' outputData(outNo).simType ' y' num2str(outNo) '[1],'];
                                codePreFill.outputVarAssign = [codePreFill.outputVarAssign 10 9  '*y' num2str(outNo) ' = ' outputData(outNo).sigName ';'];
                            end
                            fprintf(rteCodeFid, '}\n');
                        elseif isequal(rteData(rteNo).portType,'glbConfig')
                            %* Creating global variable in psudo rte
                            fprintf(rteHeadFid, '%s %s;\n', rteData(rteNo).dataType, rteData(rteNo).signalName);

                            %Adding inport data for connection ref
                            [inputData, inpNo, lctPortMap] = napp.lctPortData(inputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap);
                            inputData(inpNo).isGlbConfig = 1;

                            codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 inputData(inpNo).sigName ' = ' inputData(inpNo).defValue ';']; 
                            codePreFill.inputVarArg = [codePreFill.inputVarArg 10 9 9 9 inputData(inpNo).autoType ' *u' num2str(inpNo) ','];
                            codePreFill.lctInpSpec = [codePreFill.lctInpSpec ' ' inputData(inpNo).simType ' u' num2str(inpNo) '[1],'];
                            codePreFill.inputVarAssign = [codePreFill.inputVarAssign 10 9 inputData(inpNo).sigName ' = *u' num2str(inpNo) ';'];
                        elseif iscell(rteData(rteNo).portType)
                            if ~isequal(rteData(rteNo).doNothing, 1)
                                for argNo = 1 : length(rteData(rteNo).portType)
                                    %* Creating global variable in psudo rte
                                    fprintf(rteHeadFid, '%s %s;\n', rteData(rteNo).dataType{argNo}, rteData(rteNo).signalName{argNo});

                                    if isequal(rteData(rteNo).portType{argNo},'inPort')
                                        fprintf(rteCodeFid, '\t*%s = %s;\n', rteData(rteNo).argName{argNo}, rteData(rteNo).signalName{argNo});
                                        %Adding inport data for connection ref
                                        [inputData, inpNo, lctPortMap] = napp.lctPortData(inputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap, 'clientServer', argNo);

                                        codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 inputData(inpNo).sigName ' = ' num2str(inputData(inpNo).defValue) ';']; 
                                        codePreFill.inputVarArg = [codePreFill.inputVarArg 10 9 9 9 inputData(inpNo).autoType ' *u' num2str(inpNo) ','];
                                        codePreFill.lctInpSpec = [codePreFill.lctInpSpec ' ' inputData(inpNo).simType ' u' num2str(inpNo) '[1],'];
                                        codePreFill.inputVarAssign = [codePreFill.inputVarAssign 10 9 inputData(inpNo).sigName ' = *u' num2str(inpNo) ';'];
                                    elseif isequal(rteData(rteNo).portType{argNo},'outPort')
                                        fprintf(rteCodeFid, '\t%s = %s;\n', rteData(rteNo).signalName{argNo}, rteData(rteNo).argName{argNo});
                                        [outputData, outNo, lctPortMap] = napp.lctPortData(outputData, lctPortMap, rteData(rteNo), autTypesMap, simTypesMap, 'clientServer', argNo);

                                        codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 outputData(outNo).sigName ' = ' num2str(outputData(outNo).defValue) ';']; 
                                        codePreFill.outputVarArg = [codePreFill.outputVarArg 10 9 9 9 outputData(outNo).autoType ' *y' num2str(outNo) ','];
                                        codePreFill.lctOutSpec = [codePreFill.lctOutSpec ' ' outputData(outNo).simType ' y' num2str(outNo) '[1],'];
                                        codePreFill.outputVarAssign = [codePreFill.outputVarAssign 10 9  '*y' num2str(outNo) ' = ' outputData(outNo).sigName ';'];
                                    end
                                end
                            end
                            fprintf(rteCodeFid, '}\n');
                        else
                            %! If code comes here something is wrong
                        end
                        fprintf(rteCodeFid, '\n');

                        if isequal(rteNo,length(rteData)) || ~isequal(rteData(rteNo).portName, rteData(rteNo + 1).portName)
                            if iscell(rteData(rteNo).portName)
                                napp.allPortMap([napp.lctData(lctIdx).cmpName '/' rteData(rteNo).portName{1}]) = struct('rnblName', napp.lctData(lctIdx).rnblName, 'sFunName', napp.lctData(lctIdx).sFunName, 'isBus', rteData(rteNo).isBus ,'portMap', lctPortMap); %TODO considering all dataElements in a port are buses or none of them are
                            else
                                napp.allPortMap([napp.lctData(lctIdx).cmpName '/' rteData(rteNo).portName]) = struct('rnblName', napp.lctData(lctIdx).rnblName, 'sFunName', napp.lctData(lctIdx).sFunName, 'isBus', rteData(rteNo).isBus ,'portMap', lctPortMap); %TODO considering all dataElements in a port are buses or none of them are
                            end
                            lctPortMap = containers.Map(); % Resetting the map for next port
                        end
                    end

                    napp.lctData(lctIdx).inputData = inputData;
                    napp.lctData(lctIdx).outputData = outputData;
                    napp.lctData(lctIdx).codePreFill = codePreFill;

                    %? Add wrapper functions
                    %* Adding starter wrapper
                    fprintf(rteCodeFid, '//Start function - Initialization function wrapper\n');
                    % Adding function proto
                    fprintf(rteHeadFid, 'extern void %s_Start_wrapper(void);\n\n', napp.lctData(lctIdx).rnblName);

                    fprintf(rteCodeFid, 'extern void %s_Start_wrapper(void)\n{\n', napp.lctData(lctIdx).rnblName);
                    fprintf(rteCodeFid, '%s', napp.lctData(lctIdx).codePreFill.defValueAssign);
                    fprintf(rteCodeFid, '\n\t%s_Init();\n',napp.lctData(lctIdx).cmpName);
                    fprintf(rteCodeFid, '}\n\n');

                    %* Adding output wrapper
                    fprintf(rteCodeFid, '//Output function - Runnable function wrapper\n');
                    % Adding function proto
                    fprintf(rteHeadFid, 'extern void %s_Outputs_wrapper(', napp.lctData(lctIdx).rnblName);
                    fprintf(rteHeadFid, '%s%s);', napp.lctData(lctIdx).codePreFill.inputVarArg, napp.lctData(lctIdx).codePreFill.outputVarArg(1 : length(napp.lctData(lctIdx).codePreFill.outputVarArg) - 1));

                    fprintf(rteCodeFid, 'extern void %s_Outputs_wrapper(', napp.lctData(lctIdx).rnblName);
                    fprintf(rteCodeFid, '%s%s)', napp.lctData(lctIdx).codePreFill.inputVarArg, napp.lctData(lctIdx).codePreFill.outputVarArg(1 : length(napp.lctData(lctIdx).codePreFill.outputVarArg) - 1));
                    fprintf(rteCodeFid, '{\n');
                    fprintf(rteCodeFid, '%s', napp.lctData(lctIdx).codePreFill.inputVarAssign);
                    fprintf(rteCodeFid, '\n\n\t%s();\n',napp.lctData(lctIdx).rnblName);
                    fprintf(rteCodeFid, '%s', napp.lctData(lctIdx).codePreFill.outputVarAssign);
                    fprintf(rteCodeFid, '\n}\n');

                    fclose(rteHeadFid);
                    fclose(rteCodeFid);
                    
                    waitbar(((cmpNo-1)/length(napp.allASWCmp)) + ((1) * (rnblNo/length(mdlData.rnblData)) * (1/length(napp.allASWCmp))),...
                                napp.progBar,{'Creating LCT blocks(4/5)',sprintf('Adding LCT block for ''%s'' runnable...',regexprep(mdlData.rnblData(rnblNo).rnblName,'_','\\_'))});
                    %!Adding legacy code block
                    % limits of simulink canvas : -32768 to 32767
                    %* update LCT specifications structure
                    lct_spec = legacy_code('initialize');
                    lct_spec.SampleTime = str2num(napp.lctData(lctIdx).sampleTime);
                    %lct_spec.IncPaths  = {'CtrlPltMt_autosar_rtw'};
                    lct_spec.SourceFiles = {[napp.lctData(lctIdx).cmpName '_' napp.lctData(lctIdx).rnblName '.c'], [napp.lctData(lctIdx).cmpName '_autosar_rtw\' napp.lctData(lctIdx).cmpName '.c']};
                    lct_spec.HeaderFiles = {[napp.lctData(lctIdx).cmpName '_' napp.lctData(lctIdx).rnblName '.h']};
                    lct_spec.SFunctionName = napp.lctData(lctIdx).sFunName;
                    lct_spec.StartFcnSpec = ['void ' napp.lctData(lctIdx).rnblName '_Start_wrapper(void)'];
                    lct_spec.OutputFcnSpec = ['void ' napp.lctData(lctIdx).rnblName '_Outputs_wrapper(' napp.lctData(lctIdx).codePreFill.lctInpSpec napp.lctData(lctIdx).codePreFill.lctOutSpec(1 : length(napp.lctData(lctIdx).codePreFill.lctOutSpec) - 1) ')'];
                    
                    if testMode
                        milHarnessName = ['MIL_Functional_TestHarness_' napp.lctData(lctIdx).cmpName];
                        if isequal(exist([milHarnessName '.slx']), 0)
                            % Copying harness and sldd files 
                            status = copyfile(fullfile(tstDirMap(napp.lctData(lctIdx).cmpName),[milHarnessName '.slx']),napp.integPath);
                            if status == 0
                                msgbox({sprintf('Unable to copy harness of ''%s''', napp.lctData(lctIdx).cmpName), 'Delete any created folders, restart MATLAB and try again?'},'Error','error');
                                error('Unable to copy harness of ''%s''. Delete any created folders, restart MATLAB and try again?', napp.lctData(lctIdx).cmpName);
                            end
                            status = copyfile(fullfile(tstDirMap(napp.lctData(lctIdx).cmpName),'*.sldd'),napp.integPath);
                            if status == 0
                                msgbox({sprintf('Unable to copy data dictionary of ''%s''', napp.lctData(lctIdx).cmpName), 'Delete any created folders, restart MATLAB and try again?'},'Error','error');
                                error('Unable to copy data dictionary of ''%s''. Delete any created folders, restart MATLAB and try again?', napp.lctData(lctIdx).cmpName);
                            end
                            % tstDirMap(napp.lctData(lctIdx).cmpName)
                        end
                        load_system(milHarnessName)
                        
                        %Commenting out refrenced model all related blocks
                        mdlRef = find_system(milHarnessName, 'SearchDepth', 1, 'IncludeCommented', 'on', 'BlockType', 'ModelReference');
                        napp.commentAll(mdlRef{1});

                        %Commenting out all simulink functions
                        allSims = find_system(milHarnessName, 'SearchDepth', 1, 'IncludeCommented', 'on', 'BlockType', 'SubSystem');
                        for sysNo = 1 : length(allSims)
                            if ~isequal(get_param(allSims{sysNo},'MaskType'),'Sigbuilder block')
                                napp.commentAll(allSims{sysNo});
                            end
                        end

                        refPos = get_param(mdlRef{1}, 'position');

                        legacy_code('generate_for_sim', lct_spec, milHarnessName);
                        legacy_code('slblock_generate', lct_spec, milHarnessName);

                        lctBlk = find_system(milHarnessName, 'Name', napp.lctData(lctIdx).sFunName);
                        lctBlk = lctBlk{1};
    
                        set_param(lctBlk, 'Position', [refPos(1) refPos(4) + 200 refPos(3) (refPos(4) + 200) + (55 * (max(get_param(lctBlk, 'Ports'))))]);

                    end
                end
            end

            %! Saving lct data in matFile
            tmpMat(napp, 4);
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
                save('RootSWComposition_IntegrationData.mat','arxmlData');
            elseif writeData == 2
                arxmlData.allASWCmp = napp.allASWCmp;
                arxmlData.delConMap = napp.delConMap;
                arxmlData.asmConn = napp.asmConn;
                arxmlData.dataTypeMap = napp.dataTypeMap;
                arxmlData.idtrStructMap = napp.idtrStructMap;
                arxmlData.defValueMap = napp.defValueMap;
                arxmlData.glbConfigMap = napp.glbConfigMap;
                modelData.allMdlData = napp.allMdlData;
                save('RootSWComposition_IntegrationData.mat','arxmlData','modelData');
            elseif writeData == 3
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
            elseif writeData == 4
                arxmlData.allASWCmp = napp.allASWCmp;
                arxmlData.delConMap = napp.delConMap;
                arxmlData.asmConn = napp.asmConn;
                arxmlData.dataTypeMap = napp.dataTypeMap;
                arxmlData.idtrStructMap = napp.idtrStructMap;
                arxmlData.defValueMap = napp.defValueMap;
                arxmlData.glbConfigMap = napp.glbConfigMap;
                modelData.allMdlData = napp.allMdlData;
                rteData = napp.rnblRteData;
                lctBlcksData = napp.lctData;
                save('RootSWComposition_IntegrationData.mat','arxmlData','modelData','rteData', 'lctBlcksData');
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

        function tstDirMap = getTestingPath(tstPath)
            allDir = dir(tstPath);
            tstDirMap = containers.Map();
            for dirNo = 1 : length(allDir)
                if ~isequal(allDir(dirNo).name,'.') && ~isequal(allDir(dirNo).name,'..')
                    codeDir = dir([allDir(dirNo).folder '\' allDir(dirNo).name '\MIL\*.mat']);
                    tstDirMap(codeDir.name(1:length(codeDir.name) - 21)) = codeDir.folder;
                end
            end
        end

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

        function portData = getPortData(portData, portNo, portHandle, autosarMap, dataTypeMap, simDataTypes)
            % portData(portNo).portName = get_param(portHandle,'Name');
            if isequal(get_param(portHandle,'BlockType'),'Inport')
                [arPortName, arDataElementName, arDataAccessMode] = getInport(autosarMap, get_param(portHandle,'Name'));
            else
                [arPortName, arDataElementName, arDataAccessMode] = getOutport(autosarMap, get_param(portHandle,'Name'));
            end

            portIdx = 0;
            if isequal(arDataAccessMode,'ErrorStatus')
                portIdx = find(contains({portData.signalName}, [arPortName '_' arDataElementName]));
                if ~isempty(portIdx)
                    portData(portIdx(1)).retError = 1;
                else
                    portData(portNo).retError = 1;
                    portIdx = 0;
                end
            end

            if portIdx == 0
                portData(portNo).portName = arPortName;
                portData(portNo).dataElementName = arDataElementName;
                portData(portNo).signalName = [arPortName '_' arDataElementName];
                portData(portNo).isBus = 0;
                outDataType = get_param(portHandle,'OutDataTypeStr');
                if isempty(find(contains(simDataTypes, outDataType)))
                    if isequal(outDataType(1 : 4),'Enum')
                        portData(portNo).appDataType =  outDataType(7 : length(outDataType));
                    elseif isequal(outDataType(1 : 3),'Bus')
                        portData(portNo).appDataType =  outDataType(6 : length(outDataType));
                        portData(portNo).isBus = 1;
                    else
                        portData(portNo).appDataType =  outDataType;
                    end
                    portData(portNo).baseDataType = dataTypeMap(portData(portNo).appDataType);
                else
                    portData(portNo).baseDataType = outDataType;
                end
            end
        end

        function [args, dataType, dtMisMatch] = getFunArg(funArgs, mdlDataType, varargin)
            if ~isempty(varargin)
                indArgs = strsplit(funArgs,',');
                for argNo = 1 : length(indArgs)
                    argTypes = regexp(indArgs{argNo},'\s*(const)*\s*(?<dataType>\w*)\**\s*(?<argName>\w*)','names');
                    args{argNo} = argTypes(1).argName;
                    dataType{argNo} = argTypes(1).dataType;
                end
                % varargin -> argument in function caller
                argIdx = find(contains(args, varargin));
                args = args{argIdx(1)};
                dataType = dataType{argIdx(1)};
            else
                argTypes = regexp(funArgs,'\s*(const)*\s*(?<dataType>\w*)\**\s*(?<argName>\w*)','names');
                args = argTypes(1).argName;
                dataType = argTypes(1).dataType;
            end
            dtMisMatch = ~isequal(dataType, mdlDataType);
        end

        function [portData, portNo, lctPortMap] = lctPortData(portData, lctPortMap, rteData, autTypesMap, simTypesMap, varargin)
            portNo = length(portData) + 1;
            if ~isempty(varargin) && isequal(varargin{1}, 'clientServer')
                portData(portNo).portName = rteData.portName{varargin{2}};
                portData(portNo).dataElement = rteData.dataElement{varargin{2}};
                portData(portNo).argName = rteData.argName{varargin{2}};
                portData(portNo).sigName = rteData.signalName{varargin{2}};
                portData(portNo).varName = rteData.varName{varargin{2}};
                portData(portNo).isBus = 0;
                portData(portNo).defValue = rteData.defValue{varargin{2}};
                portData(portNo).dataType = rteData.dataType{varargin{2}};
                lctPortMap(portData(portNo).dataElement) = portNo;
                portData(portNo).autoType = autTypesMap(portData(portNo).dataType);
                portData(portNo).simType = simTypesMap(portData(portNo).autoType);
                portData(portNo).isCSI = 1;
            else
                portData(portNo).portName = rteData.portName;
                portData(portNo).dataElement = rteData.dataElement;
                portData(portNo).argName = rteData.argName;
                portData(portNo).sigName = rteData.signalName;
                portData(portNo).varName = rteData.varName;
                portData(portNo).isBus = rteData.isBus;
                if isempty(varargin)
                    portData(portNo).defValue = rteData.defValue;
                    portData(portNo).dataType = rteData.dataType;
                    lctPortMap(portData(portNo).dataElement) = portNo;
                elseif isequal(varargin{1}, 'busSignal')
                    portData(portNo).defValue = '0'; %TODO default values are not available for bus elements
                    portData(portNo).dataType = varargin{3};
                    portData(portNo).busElement = varargin{2};
                    lctPortMap([portData(portNo).dataElement '/' portData(portNo).busElement]) = portNo;
                end
                portData(portNo).autoType = autTypesMap(portData(portNo).dataType);
                portData(portNo).simType = simTypesMap(portData(portNo).autoType);
            end
        end

        function rteErrorRet(portData, rteData, errDef, errDataType, rteHeadFid, rteCodeFid, codePreFill, autTypesMap, simTypesMap)
            if isequal(rteData.retError, 1)
                portNo = length(portData) + 1;
                portData(portNo).portName = rteData.portName;
                portData(portNo).dataElement = rteData.dataElement;
                portData(portNo).sigName = [rteData.signalName '_ErrSt'];
                portData(portNo).varName = [rteData.varName '_ErrSt'];
                portData(portNo).isBus = 0;
                portData(portNo).defValue = errDef;
                portData(portNo).dataType = errDataType;
                % lctPortMap(portData(portNo).dataElement) = portNo;
                portData(portNo).autoType = autTypesMap(portData(portNo).dataType);
                portData(portNo).simType = simTypesMap(portData(portNo).autoType);

                fprintf(rteHeadFid, '%s %s;\n', portData(portNo).dataType, portData(portNo).sigName);
                fprintf(rteCodeFid, '\n\treturn %s;\n', portData(portNo).sigName);

                codePreFill.defValueAssign = [codePreFill.defValueAssign 10 9 portData(portNo).sigName ' = ' portData(portNo).defValue ';']; 
                codePreFill.inputVarArg = [codePreFill.inputVarArg 10 9 9 9 portData(portNo).autoType ' *u' num2str(portNo) ','];
                codePreFill.lctInpSpec = [codePreFill.lctInpSpec ' ' portData(portNo).simType ' u' num2str(portNo) '[1], '];
                codePreFill.inputVarAssign = [codePreFill.inputVarAssign 10 9 portData(portNo).sigName ' = *u' num2str(portNo) ','];
            end
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

        function commentAll(blockHandle)
            portConn = get_param(blockHandle,'PortConnectivity');
            for portNo = 1 : length(portConn)
                if ~isempty(portConn(portNo).DstBlock) && ~isequal(portConn(portNo).Type, 'trigger')
                    set_param(portConn(portNo).DstBlock,'Commented','on');
                elseif ~isempty(portConn(portNo).SrcBlock) && ~isequal(portConn(portNo).Type, 'trigger')
                    set_param(portConn(portNo).SrcBlock,'Commented','on');
                end
            end
            set_param(blockHandle,'Commented','on');
        end
    end
end