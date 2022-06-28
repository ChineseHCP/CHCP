% List of open inputs
% Coregister: Reslice: Images to Reslice - cfg_files
nrun = 246; % enter the number of runs here
jobfile = {'/meizhen/DTI/Data/BNA_PM_3D_246/resample_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
%     directory=fullfile('/meizhen/DTI/Data/BNA_PM_3D_246/',[num2str(crun,'%03d')]);
%     img = spm_select('FPList',fullfile(directory,'.nii$'));
    inputs{1, crun} = cellstr(strcat('/meizhen/DTI/Data/BNA_PM_3D_246/',num2str(crun,'%03d'),'.nii')); % Coregister: Reslice: Images to Reslice - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('serial', jobs, '', inputs{:});
