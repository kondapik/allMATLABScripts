[ModelName,rootPath] = uigetfile({'*.slx;*.mdl','Models (*.slx, *.mdl)'},'Select model to update default values in excel');

if isequal(ModelName,0)
    %!Model Not Selected
    msgbox('Getting default values for a model that doesn''t exist!\nI am going back to bed now...','Error','error');
else
    [~,OnlyModelName,~] = fileparts(ModelName);

    load(sprintf('%s_TestHarness_data.mat', OnlyModelName));
    Excel = actxserver('Excel.Application');
    Ex_Workbook = Excel.Workbooks.Open(sprintf('%sMIL_Functional_TestReport_%s.xlsx',rootPath,OnlyModelName));
    Ex_Sheets = Excel.ActiveWorkbook.Sheets;
    Ex_actSheet = Ex_Sheets.get('Item',1);
    Excel.Visible = 1;
    AUTOSAR_stat = 1;

    DataDictObj = Simulink.data.dictionary.open(sprintf('%s.sldd', OnlyModelName));
    DataDictSec = getSection(DataDictObj,'Design Data');

    Ex_range = get(Ex_actSheet,'Range','F4');

    for port_no = no_rnbls+1: no_rnbls + no_inports + no_outports + 1 + AUTOSAR_stat
        if (port_no > no_rnbls) && port_no < (no_rnbls + no_inports + 1)
            %inports
            if isequal(port_data(port_no).BaseDataType,'Enum')
                Ex_range.Value = port_data(port_no).OutDataType;
                gcEntries = find(DataDictSec,'-regexp','Name',port_data(port_no).OutDataType(7:length(port_data(port_no).OutDataType)));
                enumValue = getValue(gcEntries(1));
                Ex_range.Value = enumValue.DefaultValue;
            else
                Ex_range.Value = 0;
            end
            Ex_range.EntireColumn.AutoFit;
            Ex_range = Ex_range.get('Offset',0,1);
        elseif port_no > (no_rnbls + no_inports + AUTOSAR_stat) && port_no < (no_rnbls+no_inports+no_outports+1+AUTOSAR_stat)
            if isequal(port_data(port_no).BaseDataType,'Enum')
                Ex_range.Value = port_data(port_no).OutDataType;
                gcEntries = find(DataDictSec,'-regexp','Name',port_data(port_no).OutDataType(7:length(port_data(port_no).OutDataType)));
                enumValue = getValue(gcEntries(1));
                Ex_range.Value = enumValue.DefaultValue;
            else
                Ex_range.Value = 0;
            end
            Ex_range.EntireColumn.AutoFit;
            Ex_range = Ex_range.get('Offset',0,1);
        end
    end
end

disp('Done')