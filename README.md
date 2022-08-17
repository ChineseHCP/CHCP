# Welcome to the Chinese Human Connectome Project (CHCP) repository!

CHCP repository is a package that provides following useful tools:

 * Brain parcellation algorithms based on both structural and functional connectivity. 
 * Surface-based resting-state fMRI ReHo and fALFF calculation.
 * Surface- and volume-based task fMRI analysis.
 * The diversity of brain structural and functional parcellation analysis.

Currently, CHCP mainly uses matlab, bash, python and only supports Linux system.

## Table of Contents
* [Prerequisities](#prerequisities)
* [Installation](#installation)
  * [Install HCP Pipelines](#Install-HCP-Pipelines)
  * [Install CBIG](#Install-CBIG)
  * [Install CHCP](#Install-CHCP)
* [Getting Example Data](#getting-example-data)
* [Running the HCP Pipeline on Example Data](#Running-the-HCP-Pipeline-on-Example-Data)
  * [Structural Preprocessing](#Structural-Preprocessing)
  * [Diffusion Preprocessing](#Diffusion-Preprocessing)
  * [Functional Preprocessing](#Functional-Preprocessing)
  * [Task Analysis](#Task-Analysis)
  * [The ICA-FIX Denoising](#The-ICA-FIX-Denoising)
* [Additional Processing for Resting-state Functional MRI (rfMRI)](#Additional-Processing-for-Resting-state-Functional-MRI)
* [Brain Parcellation Based on Diffusion MRI (dMRI)](#Brain-Parcellation-Based-on-Diffusion-MRI)
* [Seven-network Atlas Construction Based on rfMRI](#Seven-network-Atlas-Construction-Based-on-rfMRI)
* [Calculate ReHo and fALFF on Cortical Surface](#Calculate-ReHo-and-fALFF-on-Cortical-Surface)
* [Topographical Differences of Structural Parcellations Between the CHCP and HCP](#[Topographical-Differences-of-Structural-Parcellations-Between-the-CHCP-and-HCP)
* [The CHCP and HCP Seven-network Atlases Analysis](#The-CHCP-and-HCP-Seven-network-Atlases-Analysis)
* [Task Analysis between the CHCP and HCP](#Task-Analysis-between-the-CHCP-and-HCP)
* [Others](#Others)

-----

<a id="prerequisites"></a>
## Prerequisites

1.	A 64-bit Linux Operating System
2.	The FMRIB Software Library (a.k.a. FSL) version 6.0.2 or greater installed and configuration file properly sourced. FSL 6.0.4 is recommended.
3.	FreeSurfer version 6.0 available at http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall/
4.	Connectome Workbench version 1.4.2 or later. Our CHCP scripts use the `wb_command` which is part of the Connectome Workbench created by HCP. 
5.	The HCP Pipelines (Glasser et al., 2013), for more information, please see https://github.com/Washington-University/HCPpipelines.
6.	The Computational Brain Imaging Group (CBIG) repository shared by Prof. Thomas Yeo (https://github.com/ThomasYeoLab/CBIG).

-----

<a id="installation"></a>
## Installation

<a id="Install-HCP-Pipelines"></a>
### Install HCP Pipelines

1. Install the listed prerequisities first.
 * Installation Notes for FSL
   * Once you have downloaded and installed FSL, verify that you have the correct version of FSL by simply running hte `$ fsl` command. The FSL window that shows up should identify the version of FSL you have installed. Please follow the FSL version recommended by HCP Pipelines.
   * Sometimes FSL is installed without the separate documentation package, it is recommand to install the full of FSL documentation package.
 
 * Installation Notes for FreeSurfer
   * Considering the compatibility issue with HCP Pipelines, FreeSurfer version 6.0 is recommanded.
   * Ubuntu (starting with version 12.04 and running through version 14.04 LTS) is missing a library that is used by some parts of FreeSurfer. To install that library enter `$ sudo apt-get install libjpeg62`.

2. Download the necessary compressed tar file (.tar.gz) for the [HCP Pipelines release][HCP Pipelines release].
3. Move the compressed tar file that you download to the directory in which you want the HCP Pipelines to be installed, which refered as `${HCPPIPEDIR}`, e.g.

  - `$ mv Pipelines-4.0.0.tar.gz ~/projects`

4. Extract the files from the compressed tar file, e.g.

  ```
  cd ~/projects
  tar xvf Pipelines-4.0.0.tar.gz
  ```
 
<a id="Install-CBIG"></a>
### Install CBIG

1. After cloning/downloading the [CBIG repository][CBIG repository], move the compressed zip file that you download to the directory in which you want the CBIG repository to be installed, which refered as `${CBIG}`, e.g.

  - `$ mv CBIG-master.zip ~/proects`

2. Extract the file from the compressed zip file, e.g.

  ```
  cd ~/projects
  unzip -x CBIG-master.zip
  ```

3. Please see [README][README] inside `setup` directory to see how to set up your local environment to be compatible with our CBIG repository. 

<a id="Install-CHCP"></a>
### Install CHCP

1. Cloning/downloading the CHCP repository, move the compressed zip file that you download to the directory in which you want the CHCP repository to be installed, which refered as `${CHCP}`, e.g.

  - `$ mv CHCP-main.zip ~/proects`

2. Extract the file from the compressed zip file, e.g.

  ```
  cd ~/projects
  unzip -x CHCP-main.zip
  ```

-----

<a id="getting-example-data"></a>
## Getting Example Data

Example data for becoming familiar with the process of running the CHCP repository is available from the Chinese Human Connectome Project website (https://www.Chinese-HCP.cn).

The organization pattern of the CHCP raw data is consistent with that of the HCP unpreprocessed data in Human Connectome Project website (https://www.humanconnectome.org). 

The remainder of these instructions assumes you have extracted the example data into the directory `~/projects/CHCP/ExampleData`. You will need to modify the instructions accordingly if you have extracted the example data elsewhere.

-----

<a id="Running the HCP Pipelines on Example Data"></a>
## Running the HCP Pipelines on Example Data

Data preprocessing uses the *‘minimal preprocessing pipelines’* (Glasser et al., 2013, https://github.com/Washington-University/HCPpipelines)


<a id="Structural-Preprocessing"></a>
### Structural Preprocessing

Structural preprocessing is subdivided into 3 parts as a separate bash script documented by HCP pipelines (https://github.com/Washington-University/HCPpipelines/wiki/Installation-and-Usage-Instructions), including Pre-FreeSurfer processing, FreeSurfer processing, and Post-FreeSurfer processing.
These shell scripts are named as follow, and located in the `${HCPPIPEDIR}/Examples/Scripts` directory:

- `PreFreeSurferPipelineBatch.sh`
- `FreeSurferPipelineBatch.sh`
- `PostFreeSurferPipelineBatch.sh`

The `StudyFolder`, `Subjlist`, and `EnvironmentScript` variables set at the top of the batch script need to be verified or edited as follow:

```
StudyFolder=”${HOME}/projects/CHCP/ExampleData”
Subject=”3001”
EnvironmentScript=”${HCPPIPEDIR}/Examples/Scripts/SetUpHCPPipeline.sh”
```

<a id="Diffusion-Preprocessing"></a>
### Diffusion Preprocessing

Diffusion preprocessing depends on the outputs generated by Structural preprocessing. The diffusion preprocessing script in the `${HCPPIPEDIR}/Examples/Scripts` directory is much like the example scripts for the 3 phases of Structural Preprocessing. The `StudyFolder`, `Subjlist`, and `EnvironmentScript` variables set at the top of the batch script need to be verified or edited as above. The diffusion preprocessing scripts is named as: 

- `DiffusionPreprocessingBatch.sh`


<a id="Functional-Preprocessing"></a>
### Functional Preprocessing

Functional preprocessing depends on the outputs generated by Structural preprocessing. Functional preprocessing is divided into 2 parts: Generic fMRI volume preprocessing and generic fMRI surface preprocessing. Generic fMRI surface preprocessing depends upon output produced by the generic fMRI volume preprocessing. 
These shell scripts are named as follow, and located in the `${HCPPIPEDIR}/Examples/Scripts` directory:

- `GenericfMRIVolumeProcessingPipelineBatch.sh`
- `GenericfMRISurfaceProcessingPipelineBatch.sh`

The `StudyFolder`, `Subjlist`, and `EnvironmentScript` variables set at the top of the batch script need to be verified or edited as exhibited in structural preprocessing.


<a id="Task-Analysis"></a>
### Task Analysis

The `TaskfMRIAnalysisBatch.sh` script in the `${HCPPIPEDIR}/Examples/Scripts` directory was used for CHCP task fMRI analysis.

The `TaskfMRIAnalysisBatch.sh` script runs Level 1 and Level 2 Task fMRI Analysis. As has been the case with the other sample scripts, you will need to verify or edit the `StudyFolder`, `Subjlist`, and `EnvironmentScript` variables defined at the top of this batch processing script. 


<a id="The-ICA-FIX-Denoising"></a>
### The ICA-FIX Denoising

rfMRI data has been further processed (after Functional Preprocessing is complete) using the FMRIB group's ICA-based Xnoiseifer - FIX (ICA-FIX). This processing regressess out motion timeseries and artifact ICA components (ICA run using Melodic and components classified using FIX): (Salimi-Khorshidi et al 2014)

See `${HCPPIPEDIR}/ICAFIX/README` for further details and `IcaFixProcessingBatch.sh` for an example script in the `${HCPPIPEDIR}/Examples/Scripts` directory.

-----

<a id="Additional-Processing-for-Resting-state-Functional-MRI"></a>
## Additional Processing for Resting-state Functional MRI (rfMRI)

Additional processing steps to the rfMRI data in the fs_LR_32k surface were performed after ICA-FIX denoising as postprocessing using CBIG repository released by Prof. Thomas Yeo (https://github.com/ThomasYeoLab/CBIG). These additional processing including: i) regressing the global signal, averaged ventricular signal, six motion parameters, and their temporal derivatives (18 regressors). ii) motion censoring and interpolation, in which volumes with FD > 0.2 mm or DVARS > 75 were flagged as outliers. BOLD runs with more than half the volumes flagged as outliers were removed. iii) bandpass filtering (0.01-0.08 Hz).
The names of these shell scripts are as follow, and located in the `${CBIGDIR}/stable_projects/preprocessing/CBIG_fMRI_Preproc2016` directory:

- `CBIG_preproc_regression.csh`
- `CBIG_preproc_censor.csh`
- `CBIG_preproc_bandpass_fft.csh`


Finally, the output rfMRI data were smoothed using a Gaussian smoothing kernel with the amount of smoothing defined by the expression sqrt (4mm^2-2mm^2) FWHM using `wb_command –cifti-smoothing` in Connectome Workbench software (https://www.humanconnectome.org/software/workbench-command).

-----

<a id="Brain-Parcellation-Based-on-Diffusion-MRI"></a>
## Brain Parcellation Based on Diffusion MRI (dMRI)

Structural connectivity-based parcellations at the individual level for 140 demographically matched participants from CHCP and HCP datasets were generated using the technique proposed by Han and colleagues (Han et al., 2020). Then, the group-level brain pracellations were constructed based on the maximum probability maps for both CHCP and HCP datasets (Ge et al., 2022). For examples of how to use CHCP repository to construct structural parcellation, please take a look at scripts in structural parcellation folder in CHCP repository.

-----

<a id="Seven-network-Atlas-Construction-Based-on-rfMRI"></a>
## Seven-network Atlas Construction Based on rfMRI

We used the clustering algorithm method to construct a population-level canonical seven-network atlas based on the rfMRI data for both CHCP and HCP datasets. The clustering algorithm modeled the data with a von Mises-Fisher distribution (Yeo et al., 2011). The code for clustering procedure comes from the CBIG repository (https://github.com/ThomasYeoLab/CBIG). 

The main shell scripts used for clustering are named as follow, and located in the `${CBIGDIR}/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering` directory:

- `CBIG_Yeo2011_general_cluster_fcMRI_surf2surf_profiles.csh`

-----

<a id="Calculate-ReHo-and-fALFF-on-Cortical-Surface"></a>
## Calculate ReHo and fALFF on Cortical Surface

The `ReHo_fALFF` folder in CHCP repository contains the modified `DPABISurf_run_modified.m` files for calculating resting-state fMRI ReHo and fALFF in fs_LR32k grayordinates space (please see https://rfmri.org). After calculated the individualized ReHo and fALFF, the following code was used to average ReHo and fALFF of CHCP and HCP individuals.

- `average_surf_metric_ReHo_CHCP.m`
- `average_surf_metric_ReHo_HCP.m`
- `average_surf_metric_fALFF_CHCP.m`
- `average_surf_metric_fALFF_HCP.m`

-----

<a id="Topographical-Differences-of-Structural-Parcellations-Between-the-CHCP-and-HCP"></a>
## Topographical Differences of Structural Parcellations Between the CHCP and HCP

The `chcp140_hcp140_structural_parcellation_Dice` folder contains the matlab files for calculating structrual parcellations' Dice coefficient. The calculation process is divided into 3 parts, from the step 1 to the step 3. For details, please refer to the following scripts.

- `step1_lh_pm.m`
- `step1_rh_pm.m`
- `step2_mpm_annotation.m`
- `step3_racial_variability.m`

-----

<a id="The-CHCP-and-HCP-Seven-network-Atlases-Analysis"></a>
## The CHCP and HCP Seven-network Atlases Analysis

The `functional_atlas_analysis` folder contains the matlab, shell and python files for seven-network atlases analysis between CHCP and HCP datasets. These scripts including Dice coefficient calculation, GLM regression, surface area calculation and FDR correction. For detailed functions, please refer to the specific script in the folder.

-----

<a id="Task-Analysis-between-the-CHCP-and-HCP"></a>
## Task Analysis between the CHCP and HCP

The `task_analysis` folder contains the matlab and shell files for task analysis between CHCP and HCP datasets in Level 3 and reliability of the task-evoked activations across two sequential scans. Among them, the two-sample t-test and effect size calculation of CHCP and HCP task-state activation mainly use the following codes.


- `TaskfMRIAnalysisBatchlevel3_two_sample_ttest.sh`
- `TaskfMRIAnalysisBatchlevel3_two_sample_cohens_d.sh`


The calculation of the test-retest reliability of task-state activation is measured using ICC, and the specific code implementation is shown below.

- `Calculate_CHCP_ICC.m`

-----

<a id="Others"></a>
## Others

For other scripts and data descriptions of CHCP repository, please see [INSTRUCTION][INSTRUCTION] inside directory. If you have any issues, please email Guoyuan Yang (yanggy@bit.edu.cn) and Meizhen Han (hanmeizhen@pku.edu.cn), we are willing to help you to solve your problem.
Happy researching!


<!-- References -->
[HCP Pipelines release]: https://github.com/Washington-University/HCPpipelines/releases
[CBIG repository]: https://github.com/ThomasYeoLab/CBIG
[README]: https://github.com/ThomasYeoLab/CBIG/blob/master/README.md
[INSTRUCTION]: https://github.com/ChineseHCP/CHCP/blob/main/INSTRUCTION.md
