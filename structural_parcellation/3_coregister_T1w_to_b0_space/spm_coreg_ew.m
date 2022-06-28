% coregister T1 to b0 space
function spm_coreg_ew(WD,SUB,i)
	sourcepath = strcat(WD,SUB{i});
	disp(sourcepath);
	b0refimg = strcat(sourcepath,'/T1w/Diffusion/nodif_brain.nii');
	T1sourceimg = strcat(sourcepath,'/T1_brain.nii');

	spm('defaults','fmri');
	spm_jobman('initcfg');

 	matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {b0refimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {T1sourceimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
	matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
	matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
	matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.002 0.002 0.002 0.0001 0.0001 0.0001 0.001 0.001 0.001 0.0001 0.0001 0.0001];
	matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
	matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 1;
	matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
	matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
	matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';

	spm_jobman('run',matlabbatch)
