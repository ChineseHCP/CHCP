# Welcome to the Chinese Human Connectome Project (CHCP) repository!

CHCP repository is a package that provides following useful tools:

 * Brain parcellation algorithms based on both structural and functional connectivity.
 * Surface-based resting-state fMRI ReHo and fALFF calculation.
 * Surface- and volume-based task fMRI analysis.
 * The diversity of brain structural and functional parcellation analysis.
 
Currently, CHCP mainly uses matlab, bash, python and only supports Linux system.

## Table of Contents
* [Prerequisities](#prerequisities)
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
* [Others](#Others)

-----

<a id="prerequisites"></a>
## Prerequisites

1.	A 64-bit Linux Operating System
2.	The FMRIB Software Library (a.k.a. FSL) version 6.0.2 or greater installed and configuration file properly sourced. FSL 6.0.4 is recommended.
3.	FreeSurfer version 6.0 available at http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall/
4.	Connectome Workbench version 1.4.2 or later Our CHCP scripts use the wb_command which is part of the Connectome Workbench created by HCP. 
5.	The ‘minimal preprocessing pipelines’ (Glasser et al., 2013), for more information, please see https://github.com/Washington-University/HCPpipelines.
6.	Functional brain network parcellation framework with the code sharing by Prof. Thomas Yeo (https://github.com/ThomasYeoLab/CBIG).

-----

<a id="getting-example-data"></a>
## Getting Example Data

Example data for becoming familiar with the process of running the CHCP repository is available from the Chinese Human Connectome Project website (https://www.Chinese-HCP.cn).

The organization pattern of the CHCP raw data is consistent with that of the HCP unpreprocessed data in Human Connectome Project website (https://www.humanconnectome.org). 

The remainder of these instructions assume you have extracted the example data into the directory ~/projects/CHCP/ExampleData. You will need to modify the instructions accordingly if you have extracted the example data elsewhere.

-----

<a id="Running the HCP Pipelines on Example Data"></a>
## Running the HCP Pipelines on Example Data

Data preprocessing uses the *‘minimal preprocessing pipelines’* (Glasser et al., 2013, https://github.com/Washington-University/HCPpipelines)


<a id="Structural-Preprocessing"></a>
### Structural Preprocessing

Structural preprocessing is subdivided into 3 parts as a separate bash script documented by HCP pipelines (https://github.com/Washington-University/HCPpipelines/wiki/Installation-and-Usage-Instructions), including Pre-FreeSurfer processing, FreeSurfer processing, and Post-FreeSurfer processing.
These shell scripts are named as follow, and located in the `${HCPPIPEDIR}/Examples/Scripts` directory:

`PreFreeSurferPipelineBatch.sh`

`FreeSurferPipelineBatch.sh`

`PostFreeSurferPipelineBatch.sh`


The `StudyFolder`, `Subjlist`, and `EnvironmentScript` variables set at the top of the batch script need to be verified or edited as follow:

`StudyFolder=”${HOME}/projects/CHCP/ExampleData”`

`Subject=”3001”`

`EnvironmentScript=”${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh”`


<a id="Diffusion-Preprocessing"></a>
### Diffusion Preprocessing

Diffusion preprocessing depends on the outputs generated by Structural preprocessing. The diffusion preprocessing script in the `${HCPPIPEDIR}/Examples/Scripts` directory is much like the example scripts for the 3 phases of Structural Preprocessing. The `StudyFolder`, `Subjlist`, and `EnvironmentScrip` variables set at the top of the batch script need to be verified or edited as above. The diffusion preprocessing scripts is named as: 

`DiffusionPreprocessingBatch.sh`


<a id="Functional-Preprocessing"></a>
### Functional Preprocessing

Functional preprocessing depends on the outputs generated by Structural preprocessing. Functional preprocessing is divided into 2 parts: Generic fMRI volume preprocessing and generic fMRI surface preprocessing. Generic fMRI surface preprocessing depends upon output produced by the generic fMRI volume preprocessing. 
These shell scripts are named as follow, and located in the `${HCPPIPEDIR}/Examples/Scripts` directory:

`GenericfMRIVolumeProcessingPipelineBatch.sh`

`GenericfMRISurfaceProcessingPipelineBatch.sh`


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
### Additional Processing for Resting-state Functional MRI (rfMRI)

Additional processing steps to the rfMRI data in the fs_LR_32k surface were performed after ICA-FIX denoising as postprocessing using Computational Brain Imaging Group (CBIG) repository released by Prof. Thomas Yeo (https://github.com/ThomasYeoLab/CBIG). These additional processing including: i) regressing the global signal, averaged ventricular signal, six motion parameters, and their temporal derivatives (18 regressors). ii) motion censoring and interpolation, in which volumes with FD > 0.2 mm or DVARS > 75 were flagged as outliers. BOLD runs with more than half the volumes flagged as outliers were removed. iii) bandpass filtering (0.01-0.08 Hz).
The names of these shell scripts are as follow, and located in the `${CBIGDIR}/stable_projects/preprocessing/CBIG_fMRI_Preproc2016` directory:

`CBIG_preproc_regression.csh`

`CBIG_preproc_censor.csh`

`CBIG_preproc_bandpass_fft.csh`


Finally, the output rfMRI data were smoothed using a Gaussian smoothing kernel with the amount of smoothing defined by the expression sqrt (4mm^2-2mm^2) FWHM using `wb_command –cifti-smoothing` in Connectome Workbench software (https://www.humanconnectome.org/software/workbench-command).

-----

<a id="Brain-Parcellation-Based-on-Diffusion-MRI"></a>
### Brain Parcellation Based on Diffusion MRI (dMRI)

Structural connectivity-based parcellations at the individual level for 140 demographically matched participants from CHCP and HCP datasets were used the technique proposed by Han and colleagues (Han et al., 2020). Then, the group-level brain pracellations were constructed based on the maximum probability maps for both CHCP and HCP datasets (Ge et al., 2022). For examples of how to use CHCP repository to construct structural parcellation, please take a look at scripts in structural parcellation folder in CHCP repository.

-----

<a id="Seven-network-Atlas-Construction-Based-on-rfMRI"></a>
### Seven-network Atlas Construction Based on rfMRI

We used the clustering algorithm method to construct a population-level canonical seven-network atlas based on the rfMRI data for both CHCP and HCP datasets, the clustering algorithm modeled the data with a von Mises-Fisher distribution (Yeo et al., 2011). The code for clustering procedure comes from the CBIG repository (https://github.com/ThomasYeoLab/CBIG). 

The main shell scripts used for clustering are named as follow, and located in the `${CBIGDIR}/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering` directory:

`CBIG_Yeo2011_general_cluster_fcMRI_surf2surf_profiles.csh`

-----

<a id="Others"></a>
### Others

For other scripts and data descriptions of CHCP repository, please see [INSTRUCTION][INSTRUCTION] inside directory. If you have issues, please email Guoyuan Yang (yanggy@bit.edu.cn) and Meizhen Han (hanmeizhen@pku.edu.cn), we are willing to help you to solve your problem.
Happy researching!


<!-- References -->

[INSTRUCTION]: https://github.com/ChineseHCP/CHCP/blob/main/INSTRUCTION.md
