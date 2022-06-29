# Welcome to the Chinese Human Connectome Project (CHCP) repository!
We are from the Center for MRI Research (CMR) in Peking University, Beijing, China.

CHCP repository is a package that provides following useful tools:

- Brain parcellation algorithms based on both structural and functional connectivity.
- Surface-based resting-state fMRI ReHo and fALFF calculation.
- Surface- and volume-based task fMRI analysis.
- The diversity of brain structural and functional parcellation analysis.

Currently, CHCP mainly uses matlab, bash, python and only supports Linux system.

## Usage ##
After cloning/downloading this repository, please see INSTRUCTION inside directory to see instructions on how to use this repository. If you have issues, please email Guoyuan Yang (yanggy@bit.edu.cn) and Meizhen Han (hanmeizhen@pku.edu.cn), we are willing to help you to solve your problem.

Happy researching!

## Other Links ##
Data preprocessing using the ‘minimal preprocessing pipelines’ (Glasser et al., 2013), for more info, please see https://github.com/Washington-University/HCPpipelines website. Functional brain network parcellation were constructed using a clustering algorithm with a von Mises-Fisher distribution framework with the data sharing by Prof. Thomas Yeo (https://github.com/ThomasYeoLab/CBIG).

## Prerequisites ##
1.	A 64-bit Linux Operating System
2.	The FMRIB Software Library (a.k.a. FSL) version 6.0.2 or greater installed and configuration file properly sourced. FSL 6.0.4 is recommended.
3.	FreeSurfer version 6.0 available at http://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall/
4.	Connectome Workbench version 1.4.2 or later
Our CHCP scripts use the  wb_command which is part of the Connectome Workbench created by HCP. They locate the wb_command using an environment variable. Instructions for setting this environment variable are provided in HCPpipeline (https://github.com/Washington-University/HCPpipelines).
