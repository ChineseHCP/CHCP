clear all; clc;
WD='/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');
parfor i=1:numel(SUB)
    spm_reslice(WD,SUB{i});
end
matlabbatch=[];
delete(gcp('nocreate'))

function spm_reslice(WD,SUB)
matlabbatch{1}.spm.spatial.realign.write.data = {
    strcat('/md_disk4/meizhen/github/share/ribbon.nii,1')
    strcat(WD,SUB,'/label_l.nii,1')
    };
matlabbatch{1}.spm.spatial.realign.write.roptions.which = [1 0];
matlabbatch{1}.spm.spatial.realign.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.realign.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.realign.write.roptions.prefix = strcat(SUB,'_0.8mm_');

spm_jobman('run',matlabbatch)
end

