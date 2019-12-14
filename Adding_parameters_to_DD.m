%Adding constant parameters to data dictionary
%%
%Loading Data Dcitionary
DictionaryObj = Simulink.data.dictionary.open('NoOprOBCDtr_Param.sldd'); %Change data dictionary name
DataSectObj = getSection(DictionaryObj,'Design Data');

%%
%Adding Parameter entries
ParamObj = Simulink.Parameter;
ParamObj.StorageClass = 'Auto';

ParamObj.Value = 2.38; % Change Value
ParamObj.DataType = 'ADTS_PrxmtyVtg'; % Change Data type to AliasType
addEntry(DataSectObj,'PPVolt_PC_LL',ParamObj); % Change name of the parameter

ParamObj.Value = 3.2; % Change Value
ParamObj.DataType = 'ADTS_PrxmtyVtg'; % Change Data type to AliasType
addEntry(DataSectObj,'PPVolt_PC_UL',ParamObj); % Change name of the parameter
%%
saveChanges(DictionaryObj);