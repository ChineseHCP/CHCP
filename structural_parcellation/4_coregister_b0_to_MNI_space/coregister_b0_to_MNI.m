clc;clear;
WD='/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');
TEMPLATE='/md_disk4/meizhen/MNI152_T1_1mm_brain.nii';
SPM='/meizhen_data/Software/spm8';

% coregistered T1 image from b0 to MNI space
parfor i=1:length(SUB)
	spm_norm_e(WD,SUB,i,TEMPLATE)
end 
matlabbatch=[];

delete(gcp('nocreate'))


