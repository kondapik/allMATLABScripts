EnumConsts = find_system(gcs,'MaskType','Enumerated Constant');
for i = 1:length(EnumConsts)
    hilite_system(EnumConsts{i,1});
    if isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCStatus') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCStatus.Error') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_OBCSt','Value','ADTS_OBCSt.Error');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCStatus') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCStatus.Boot') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_OBCSt','Value','ADTS_OBCSt.Enter_in_Boot');
    end
    
    if isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Zero_OBC') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.ZeroOBC');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.One_OBC') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.OneOBC');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Two_OBC_Parallel') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.TwoOBCParallel');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Two_OBC_Series') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.TwoOBCSeries');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Four_OBC_Parallal') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.FourOBCParallel');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Four_OBC_Series') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.FourOBCSeries');
    elseif isequal(get_param(EnumConsts{i,1},'OutDataTypeStr'),'Enum: OBCConfig') && isequal(get_param(EnumConsts{i,1},'Value'),'OBCConfig.Three_OBC_Parallel') 
        set_param(EnumConsts{i,1},'OutDataTypeStr','Enum: ADTS_SEOBCConfg','Value','ADTS_SEOBCConfg.ThreeOBCParallel');  
    end
end
disp('Done');