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
        dstPath
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

            [napp.arxmlName, napp.arxmlPath] = uigetfile({'*.arxml','AUTOSAR XML (*.arxml)'},'Select root ARXML');
            %napp.sourcePath = uigetdir(currFolder,'Select ASW source folder with all delivered models');
            napp.dstPath = uigetdir(currFolder,'Select path to save integrated model');
            napp.sourcePath = 1;

            %disp(napp.framePath);
            if isequal(napp.dstPath,0) ||  isequal(napp.sourcePath,0) || isequal(napp.arxmlPath,0)
                %!Folder Not Selected
                msgbox('Ahhhhh, you din''t select any folder and that''s not fair','Error','error');
            else
                % warning('off','MATLAB:rmpath:DirNotFound');
                % rmpath(napp.framePath);
                % warning('on','MATLAB:rmpath:DirNotFound');
                napp.exitFlag = 1;
                tmpMat(napp, 0);
                if exist('RootSWComposition_IntegrationData.mat')
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
        % #define\s*(?<oldFun>\w*)\s*(?<xpFun>\w*) -> get expanded function call

        % (?<funProto>Std_ReturnType\s*\w*\(\s*\w*\**\s*\w*\)) -> get only function prototype
        % Std_ReturnType\s*(?<oldFun>\w*)\(\s*\w*\**\s*(?<funArg>\w*)\) -> get funName and arg
        %! (?<funProto>Std_ReturnType\s*(?<oldFun>\w*)\(\s*\w*\**\s*(?<funArg>\w*)\)) -> get function prototype (doesn't work -> MATLAB doesn't support nested tokens)

        % (?<paramFun>\w*\s*\w*\(\w*\)\s*{\s*return\s*\w*;\s*}) -> get only parameter function definition
        % \w*\s*(?<oldFun>\w*)\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*} ->get funName and return variable
        %! (?<paramFun>\w*\s*(?<oldFun>\w*)\(\w*\)\s*{\s*return\s*(?<retVar>\w*);\s*}) -> get parameter function definition (doesn't work -> MATLAB doesn't support nested tokens)

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
                waitbar(0.6 + 0.1*(strNo/(allBusTypes.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting constant specs of default values...')});

                constSpecName = allConstSpec.item(consNo).getElementsByTagName('SHORT-NAME');
                constSpecValue = allConstSpec.item(consNo).getElementsByTagName('VT');
                if constSpecValue.getLength
                    constSpecMap(char(constSpecName.item(0).getFirstChild.getData)) = char(constSpecValue.item(0).getFirstChild.getData);
                end
            end

            napp.defValueMap = containers.Map();
            %* Default values of receiver ports 
            allPortSpec = xDoc.getElementsByTagName('R-PORT-PROTOTYPE');
            for portNo = 0 : allPortSpec.getLength - 1
                waitbar(0.7 + 0.1*(portNo/(allPortSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting default values of receiver ports...')});

                portName = allPortSpec.item(portNo).getElementsByTagName('SHORT-NAME');
                portName = char(portName.item(0).getFirstChild.getData);
            
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
                        napp.defValueMap(portName) = dataElements;
                    end
                end
            end

            %* Default values of provider ports
            allPortSpec = xDoc.getElementsByTagName('P-PORT-PROTOTYPE');
            for portNo = 0 : allPortSpec.getLength - 1
                waitbar(0.8 + 0.1*(portNo/(allPortSpec.getLength - 1)),napp.progBar,{'Reading root ARXML(1/5)',sprintf('Collecting default values of provider ports...')});

                portName = allPortSpec.item(portNo).getElementsByTagName('SHORT-NAME');
                portName = char(portName.item(0).getFirstChild.getData);

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
                        napp.defValueMap(portName) = dataElements;
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

        function tmpMat(napp, writeData)
            cd(napp.dstPath);
            if exist('RootSWComposition_IntegrationData.mat')
                matVariables = load('RootSWComposition_IntegrationData.mat');
                napp.allASWCmp = matVariables.arxmlData.allASWCmp;
                napp.delConMap = matVariables.arxmlData.delConMap;
                napp.asmConn = matVariables.arxmlData.asmConn;
                napp.dataTypeMap = matVariables.arxmlData.dataTypeMap;
                napp.idtrStructMap = matVariables.arxmlData.idtrStructMap;
                napp.defValueMap = matVariables.arxmlData.defValueMap;
                napp.glbConfigMap = matVariables.arxmlData.glbConfigMap;
            elseif writeData == 1
                arxmlData.allASWCmp = napp.allASWCmp;
                arxmlData.delConMap = napp.delConMap;
                arxmlData.asmConn = napp.asmConn;
                arxmlData.dataTypeMap = napp.dataTypeMap;
                arxmlData.idtrStructMap = napp.idtrStructMap;
                arxmlData.defValueMap = napp.defValueMap;
                arxmlData.glbConfigMap = napp.glbConfigMap;
                save('RootSWComposition_IntegrationData.mat','arxmlData');
            end
        end
    end

    methods (Static)
        
    end
end