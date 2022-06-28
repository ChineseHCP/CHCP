clc;clear;
WD='/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5_3.txt';
SUB = textread(SUB_LIST,'%s');
TEMPLATE=strcat('/meizhen_data/DTI/Data/','MNI152_T1_1mm_brain.nii');
SPM='/meizhen_data/Software/spm8';

% T1w and b0 have been realigned in HCP pipeline, 
% here we transform T1w to b0 space and resolution
parfor i=1:numel(SUB)
        spm_coreg_ew(WD,SUB,i)
        display(SUB{i});
end
matlabbatch=[];

delete(gcp('nocreate'))
