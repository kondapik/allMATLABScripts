[ModelName,rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to get default values of ports');

if isequal(ModelName,0)
    %!Model Not Selected
     msgbox('Getting default values for a model that doesn''t exist!\nI am going back to bed now...','Error','error');
else
    [~,OnlyModelName,~] = fileparts(ModelName);
    dataMatfile = matfile(sprintf('%s_TestHarness_data.mat', OnlyModelName),'Writable',true);

    load(sprintf('%s_TestHarness_data.mat', OnlyModelName));
    AUTOSAR_stat = 1;

    DataDictObj = Simulink.data.dictionary.open(sprintf('%s.sldd',OnlyModelName));
    DataDictSec = getSection(DataDictObj,'Design Data');

    portNames = cell.empty(0,1);
    portDefVal = cell.empty(0,1);

    for port_no = no_rnbls + 1: no_rnbls + no_inports + no_outports + 1 + AUTOSAR_stat
        if (port_no > no_rnbls) && port_no < (no_rnbls + no_inports + 1)
            %inports
            portNames{length(portNames) + 1} = port_data(port_no).Name;
            if isequal(port_data(port_no).BaseDataType,'Enum')
                gcEntries = find(DataDictSec,'-regexp','Name',port_data(port_no).OutDataType(7:length(port_data(port_no).OutDataType)));
                enumValue = getValue(gcEntries(1));
                portDefVal{length(portDefVal) + 1} = enumValue.DefaultValue;
            else
                portDefVal{length(portDefVal) + 1} = 0;
            end

        elseif port_no > (no_rnbls + no_inports + AUTOSAR_stat) && port_no < (no_rnbls+no_inports+no_outports+1+AUTOSAR_stat)
            portNames{length(portNames) + 1} = port_data(port_no).Name;
            if isequal(port_data(port_no).BaseDataType,'Enum')
                gcEntries = find(DataDictSec,'-regexp','Name',port_data(port_no).OutDataType(7:length(port_data(port_no).OutDataType)));
                enumValue = getValue(gcEntries(1));
                portDefVal{length(portDefVal) + 1} = enumValue.DefaultValue;
            else
                portDefVal{length(portDefVal) + 1} = 0;
            end
        end
    end

    dataMatfile.sigDefValues = containers.Map(portNames,portDefVal);
    disp('Done')
end