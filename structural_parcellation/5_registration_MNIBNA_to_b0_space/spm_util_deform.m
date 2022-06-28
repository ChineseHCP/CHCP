% registrate BNA (in MNI space) to b0 space
function spm_util_deform(WD,SUB,i,ROI)
	sourcepath = strcat(WD,'/',SUB{i});
    disp(sourcepath);
	roimat = strcat(sourcepath,'/rT1_brain_sn.mat');
   	refimg = strcat(sourcepath,'/rT1_brain.nii');

	spm('defaults','fmri');
	spm_jobman('initcfg');
	
   	matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.matname = {roimat};
	matlabbatch{1}.spm.util.defs.comp{1}.inv.space = {refimg};
	matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.vox = [NaN NaN NaN];
	matlabbatch{1}.spm.util.defs.comp{1}.inv.comp{1}.sn2def.bb = [NaN NaN NaN
       	                                                      	  NaN NaN NaN];
	matlabbatch{1}.spm.util.defs.ofname = '';
	matlabbatch{1}.spm.util.defs.fnames = {ROI};
	matlabbatch{1}.spm.util.defs.savedir.saveusr = {sourcepath};
	matlabbatch{1}.spm.util.defs.interp = 0;

	spm_jobman('run',matlabbatch)

