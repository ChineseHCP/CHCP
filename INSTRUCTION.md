Please read the following instructions in order to understand the data and code functions contained in each folder. 

# Environment
Linux system needs to be installed.
Other softwares used by this repository, which are
[FreeSurfer](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall),
[FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation),
[SPM](https://www.fil.ion.ucl.ac.uk/spm/),
[Connectome Workbench](https://www.humanconnectome.org/software/connectome-workbench),and Matlab.
Linux distribution choices include but are not limited to RedHat, SuSE, Ubuntu and their derivatives.

If you want to use a specific function in this repository you may not need to install all the above mentioned softwares. Please refer to the project's README page for more information on software requirements.

Detailed description of each folder.
# 1) ReHo_fALFF
The ReHo_fALFF folder contains the modified DPABISurf_run_modified.m files for calculating resting-state fMRI ReHo and fALFF in fs_LR32k grayordinates space (please see https://rfmri.org).

# 2) chcp140_hcp140_structural_parcellation_Dice
The chcp140_hcp140_structural_parcellation_Dice folder contains the matlab files for calculating topographic differences between CHCP and HCP group-level brainnetome atlases.

# 3) functional_atlas_analysis
The functional_atlas_analysis folder contains the topographic differences and surface area size ratio between CHCP and HCP 7-network atlases and other statistical test methods.

# 4) preprocessing
The preprocessing folder only contains the deface functional for both the T1W and T2W MR images using for the anonymous of CHCP data. Other data preprocessing method please see https://github.com/Washington-University/HCPpipelines.

# 5) share
The share folder contains the standard brain template and other ROIs used in structural brainnetome atlas construction.

# 6) structural_connectivity
The structural_connectivity folder contains matlab and bash files for calculating structural connectivity for both CHCP and HCP dMRI data.  

# 7) structural_functional_atlas
The structural_functional_atlas folder contains the structural and functional atlases (i.e. brainnetome and 7-network atlases), which were constructed using CHCP and HCP rfMRI and dMRI data.
  
# 8) structural_parcellation
The structural_parcellation folder contains the methods for constructing structural brainnetome atlas.

# 9) task_analysis
The task_analysis folder contains the bash files of task fMRI analysis using FEAT in FSL (please see https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSL).
