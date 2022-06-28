clear; clc;
WD='/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');
f_reslice_aparc_to_b0_space(WD,SUB);

function f_reslice_aparc_to_b0_space(WD,SUB)
%-----------------------------------------------------------------------
% reslice aparc from T1 space to bo space
%-----------------------------------------------------------------------
parfor i=1:numel(SUB)
    spm_reslice(WD,SUB{i});
    display(SUB{i});
end
matlabbatch=[];

delete(gcp('nocreate'))
end


function spm_reslice(WD,sub)
matlabbatch{1}.spm.spatial.realign.write.data = {
    strcat('/md_disk4/meizhen/CHCP/hcp_indipar/add5/',sub,'/',sub,'_indipar_mask/wBN_Atlas_246_1.5mm.nii,1')  % 1.5mm
    strcat('/md_disk4/meizhen/CHCP/hcp_indipar/add5/',sub,'/',sub,'_indipar_mask/aparc+aseg.nii,1')
    };
matlabbatch{1}.spm.spatial.realign.write.roptions.which = [1 0];
matlabbatch{1}.spm.spatial.realign.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.realign.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.realign.write.roptions.prefix = 'r';

spm_jobman('run',matlabbatch)
end
