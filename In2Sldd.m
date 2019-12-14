%{

    DECRIPTION:
    Also creates a new data dictionary 

    CREATED BY : Kondapi V S Krishna Prasanth
    DATE OF CREATION: 16-Sep-2019
    LAST MODIFIED: 19-Sep-2019

    VERSION MANAGER
    v1      adsf;l

%}

[ModelName,rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to replace Inports');
[~,OnlyModelName,~] = fileparts(ModelName);

allInputValues = struct('Name',{},'Value',{},'BaseDataType',{},'Unit',{});
allOutputValues = struct('Name',{},'Value',{},'BaseDataType',{},'Unit',{});
loggedInputs = struct('Name',{},'InputSet',{});
loggedRuns = struct('Name',{},'DataLog',{});

slddName = sprintf('%s_InConst.sldd',OnlyModelName);
if isequal(exist(slddName,'file'),2)
    ConstDictObj = Simulink.data.dictionary.open(slddName);
    ConstDictSec = getSection(ConstDictObj,'Design Data');
else
    ConstDictObj = Simulink.data.dictionary.create(slddName);
    ConstDictSec = getSection(ConstDictObj,'Design Data');
end

constFile = fullfile(rootPath,sprintf('%s_InputConsts.m',OnlyModelName));
fid = fopen(constFile,'w');

progBar = waitbar(0,{'Replacing Inports with constants(1/2)','Loading model...'},'Name','Preparing for integration');
load_system(ModelName);
DataDictObj = Simulink.data.dictionary.open(get_param(OnlyModelName,'DataDictionary'));
DataDictSec = getSection(DataDictObj,'Design Data');


AllInports = find_system(OnlyModelName,'SearchDepth',1,'BlockType','Inport');
inpNo = 0;
for index = 1:length(AllInports)
%     Block_Data = get_param(AllInports{index},'VariableName');
    portHandles = get_param(AllInports{index},'PortHandles');
    set_param(portHandles.Outport,'DataLogging','on');
    blockName = get_param(AllInports{index},'Name');
    OutDataType = get_param(AllInports{index},'OutDataTypeStr');
    if ~contains(blockName,'Rnbl_')
        %Block_Signal = get_param(AllInports{index},'OutputSignalNames');
        inpNo = inpNo + 1;
        allInputValues(inpNo).Name = blockName;
        waitbar(0.5*(index/length(AllInports)),progBar,{'Replacing Inports with constants(1/2)',sprintf('Replacing ''%s''...',regexprep(blockName,'_','\\_'))});
        RepName = replace_block(AllInports{index},'Inport','Constant','noprompt');
        CBlock = sprintf('%s/%s',OnlyModelName,blockName);
        set_param(CBlock,'Value',blockName);
        set_param(CBlock,'SampleTime', '-1');
        set_param(CBlock,'OutDataTypeStr', OutDataType);
        set_param(CBlock,'Name', [blockName '_Constant']);

        entryParam = Simulink.Parameter;
        entryParam.Value = 0;
        entryParam.DataType = OutDataType;

        entryFound = find(ConstDictSec,'Name',blockName);
        if isempty(entryFound)
        	addEntry(ConstDictSec,blockName,entryParam);
        else
        	setValue(entryFound,entryParam);
        end

        if isempty(regexpi(OutDataType,'Enum: .*'))
            entryObj = getEntry(DataDictSec,OutDataType);
            aliasValue = getValue(entryObj);
            OutDataType = aliasValue.BaseType;
        end

        allInputValues(inpNo).Value = 0;
        allInputValues(inpNo).BaseDataType = OutDataType;

        fprintf(fid, 'InpConsts.%s\n', [blockName ' = 0 ; % DataType :- ' OutDataType]);
    end   
end

addDataSource(DataDictObj,slddName);
addDataSource(ConstDictObj,get_param(OnlyModelName,'DataDictionary'));

fprintf(fid, '\n\nOnlyModelName = ''%s'';\n', OnlyModelName);
fprintf(fid, 'if bdIsLoaded(OnlyModelName)\n');
fprintf(fid, 'else\n');
fprintf(fid, '    load_system(sprintf(''%%s.slx'',OnlyModelName));\n');
fprintf(fid, 'end\n');
fprintf(fid, 'DataDictObj = Simulink.data.dictionary.open(get_param(OnlyModelName,''DataDictionary''));\n');
fprintf(fid, 'DataSectObj = getSection(DataDictObj,''Design Data'');\n');
fprintf(fid, 'inpNames = fieldnames(InpConsts);\n');
fprintf(fid, 'for inpNo = 1 : length(inpNames)\n');
fprintf(fid, '    ConstObj = getEntry(DataSectObj,inpNames{inpNo});\n');
fprintf(fid, '    ConstParam = getValue(ConstObj);\n');
fprintf(fid, '    ConstParam.Value = eval(sprintf(''InpConsts.%%s'',inpNames{inpNo}));\n');
fprintf(fid, '    setValue(ConstObj,ConstParam);\n');
fprintf(fid, 'end\n');
fprintf(fid, 'saveChanges(DataDictObj);\n');
fprintf(fid, 'save_system(OnlyModelName);\n');
fclose(fid);

waitbar(0.5,progBar,{'Collecting outports(2/2)','Updating Model...'});
set_param(OnlyModelName,'SimulationCommand','update');
refSystems = find_system(OnlyModelName,'SearchDepth',1,'BlockType','ModelReference');
dioOutputs = find_system('RootSWComposition/OutProc_Stub_Functions','SearchDepth',1,'BlockType','SubSystem');
dioOutputs = dioOutputs(2:end);
refSystems = vertcat(refSystems,dioOutputs);

tableIndex = 0;
for refNo = 1:length(refSystems)
    allOutputs = get_param(refSystems{refNo},'OutputSignalNames');
    portHandles = get_param(refSystems{refNo},'PortHandles');
    %runTimeObj = get_param(app.refSystems{refNo},'RunTimeObject');
    for outNo = 1:length(allOutputs)
        waitbar(0.5+0.5*(refNo/length(refSystems)),progBar,{'Collecting outports(2/2)',sprintf('''%s''...',regexprep(allOutputs{outNo},'_','\\_'))});
        set_param(portHandles.Outport(outNo),'DataLogging','on');
        tableIndex = tableIndex + 1;
        allOutputValues(tableIndex).Name = allOutputs{outNo};
        allOutputValues(tableIndex).Value = 0;
        %app.outTableData{tableIndex,3} = 0;
    end
end
close(progBar);
save(sprintf('%s_IntegrationData.mat',OnlyModelName),'allInputValues','loggedInputs','loggedRuns','allOutputValues');

disp('Done');
%Simulink.data.dictionary.closeAll