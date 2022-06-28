% normalize T1w (in b0 space) to MNI space
function spm_norm_e(WD,SUB,i,TEMPLATE)
    sourcepath = strcat(WD,SUB{i});
	disp(sourcepath);
	sourceimg = strcat(sourcepath,'/rT1_brain.nii');

	spm('defaults','fmri');
	spm_jobman('initcfg');
	
	matlabbatch{1}.spm.spatial.normalise.est.subj.source = {sourceimg};
    matlabbatch{1}.spm.spatial.normalise.est.subj.wtsrc = '';
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.template = {TEMPLATE};
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.weight = '';
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.smosrc = 8;
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.smoref = 0;
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.regtype = 'mni';
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.cutoff = 25;
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.nits = 16;
	matlabbatch{1}.spm.spatial.normalise.est.eoptions.reg = 1; 

	spm_jobman('run',matlabbatch)

