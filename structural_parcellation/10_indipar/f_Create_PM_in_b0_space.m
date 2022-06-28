function f_Create_PM_in_b0_space(dti,PWD,outfolder,sub_num,ROI_LABEL)
%-------------------------------------------------------------------------%
% transform ROIs(PM) from MNI space to DTI(b0) space
%-------------------------------------------------------------------------%
% b0_3001 is b0 image in individual diff space
% T1_3001 is T1 image in individual T1 space
% rT1_3001 is T1 image in individual diff space
% rT1_3032_sn.mat is transform matrix from b0 to MNI space
% wSUBROIs is from MNI space to b0 space using inverse matrix
pmfolder = strcat(outfolder,'pm');
if ~exist(pmfolder,'dir'); mkdir(pmfolder); end
% WD = '/meizhen_data/DTI/Data/';
TEMPLATE = '/md_disk4/meizhen/github/share/MNI152_T1_1mm_brain.nii';
SPM = '/md_disk4/meizhen/github/share/spm8';
% ROI should be put in the current work space
parfor ilabel=1:numel(ROI_LABEL)
    ROI = strcat('/md_disk4/meizhen/github/share/BNA_PM_3D_246/r',num2str(ROI_LABEL(ilabel),'%03d'),'.nii');
    spm_util_deform(dti,pmfolder,sub_num,ROI)
end
matlabbatch=[];
delete(gcp('nocreate'))

% ROIs from MNI space to b0 space using inverse matrix
function spm_util_deform(WD,pmfolder,sub_num,ROI)
sourcepath = strcat(WD,'/',sub_num);
disp(sourcepath);
roimat = strcat(sourcepath,'/rT1_brain_sn.mat');
refimg = strcat(sourcepath,'/rT1_brain','.nii');
roiimg = ROI;
spm('defaults','fmri');
spm_jobman('initcfg');

matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.matname = {roimat};
matlabbatch{1}.spm.util.defs.comp{1}.inv.space = {refimg};
matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.vox = [NaN NaN NaN];
matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.bb = [NaN NaN NaN
    NaN NaN NaN];
matlabbatch{1}.spm.util.defs.ofname = '';
matlabbatch{1}.spm.util.defs.fnames = {roiimg};
matlabbatch{1}.spm.util.defs.savedir.saveusr = {pmfolder};
matlabbatch{1}.spm.util.defs.interp = 0;

spm_jobman('run',matlabbatch)


