clc;clear;
WD='/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');
TEMPLATE='/md_disk4/meizhen/github/share/MNI152_T1_1mm_brain.nii';
SPM='/md_disk4/meizhen/github/share/spm8';
ROI=strcat('/md_disk4/meizhen/github/share/','BN_Atlas_246_1mm.nii');

% ROIs from MNI space to b0 space using inverse matrix
parfor i=1:length(SUB)
    file = strcat('/md_disk4/meizhen/CHCP/hcp_indipar/add5/',SUB{i},'/',SUB{i},'_indipar_mask');
    if ~exist('wBN_Atlas_246_1.5mm.nii','file')
        spm_util_deform(WD,SUB,i,ROI)
        copyfile(strcat(WD,SUB{i},'/wBN_Atlas_246_1mm.nii'),strcat('/md_disk4/meizhen/CHCP/hcp_indipar/add5/',SUB{i},'/',SUB{i},'_indipar_mask/wBN_Atlas_246_1.5mm.nii'));
    end
end
matlabbatch=[];

delete(gcp('nocreate'))

