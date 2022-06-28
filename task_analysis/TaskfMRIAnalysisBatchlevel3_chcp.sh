#!/bin/bash 

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_study_folder
    unset command_line_specified_subj
    unset command_line_specified_run_local

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --Subjlist=*)
                command_line_specified_subj=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
	    *)
		echo ""
		echo "ERROR: Unrecognized Option: ${argument}"
		echo ""
		exit 1
		;;
        esac
    done
}

get_batch_options "$@"

StudyFolder="/md_disk3/guoyuan/CHCP_preproc" #Location of Subject folders (named by subjectID)
#Subjlist="3001" #Space delimited list of subject IDs
sub_list=/md_disk3/guoyuan/HCP_group_activation/a_bash/CHCP140.txt;
EnvironmentScript="/md_disk3/guoyuan/software/HCPpipelines-4.2.0/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj}" ]; then
    Subjlist="${command_line_specified_subj}"
fi

# Requirements for this script
#  installed versions of: FSL, Connectome Workbench (wb_command)
#  environment: HCPPIPEDIR, FSLDIR, CARET7DIR 

#Set up pipeline environment variables and software
source ${EnvironmentScript}

# Log the originating call
echo "$@"

if [ X$SGE_ROOT != X ] ; then
#    QUEUE="-q long.q"
    QUEUE="-q all.q"
fi

PRINTCOM=""
#PRINTCOM="echo"

########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the results of the HCP minimal preprocesing pipelines from Q2

######################################### DO WORK ##########################################

TaskNameList=""
#TaskNameList="${TaskNameList} Emotion"
#TaskNameList="${TaskNameList} Gambling"
#TaskNameList="${TaskNameList} Language"
#TaskNameList="${TaskNameList} Motor"
#TaskNameList="${TaskNameList} Relation"
#TaskNameList="${TaskNameList} Social"
TaskNameList="${TaskNameList} Nback"

Analysis="GrayordinatesStats";
Extension="${ExtensionList}dtseries.nii"
NumContrasts=12;
for TaskName in ${TaskNameList}
do
	#LevelOneTasksList="rfMRI_${TaskName}_AP@rfMRI_${TaskName}_PA" #Delimit runs with @ and tasks with space
	#LevelOneF SFsList="rfMRI_${TaskName}_AP@rfMRI_${TaskName}_PA" #Delimit runs with @ and tasks with space
	#LevelTwoTaskList="NONE"  #"rfMRI_${TaskName}" #Space delimited list
	#LevelTwoFSFList="NONE"  #"rfMRI_${TaskName}" #Space delimited list

	LevelOneTasksList="rfMRI_${TaskName}_AP" #Delimit runs with @ and tasks with space
	LevelOneFSFsList="rfMRI_${TaskName}_AP" #Delimit runs with @ and tasks with space
	LevelTwoTaskList="rfMRI_${TaskName}"  #"rfMRI_${TaskName}" #Space delimited list
	LevelTwoFSFList="rfMRI_${TaskName}"   #"rfMRI_${TaskName}" #Space delimited list

	SmoothingList="4" #Space delimited list for setting different final smoothings.  2mm is no more smoothing (above minimal preprocessing pipelines grayordinates smoothing).  Smoothing is added onto minimal preprocessing smoothing to reach desired amount
	LowResMesh="32" #32 if using HCP minimal preprocessing pipeline outputs
	GrayOrdinatesResolution="2" #2mm if using HCP minimal preprocessing pipeline outputs
	OriginalSmoothingFWHM="2" #2mm if using HCP minimal preprocessing pipeline outputes
	Confound="NONE" #File located in ${SubjectID}/MNINonLinear/Results/${fMRIName} or NONE
	TemporalFilter="200" #Use 2000 for linear detrend, 200 is default for HCP task fMRI
	VolumeBasedProcessing="YES" #YES or NO. CAUTION: Only use YES if you want unconstrained volumetric blurring of your data, otherwise set to NO for faster, less biased, and more senstive processing (grayordinates results do not use unconstrained volumetric blurring and are always produced).  
	RegNames="NONE" # Use NONE to use the default surface registration
	ParcellationList="NONE" # Use NONE to perform dense analysis, non-greyordinates parcellations are not supported because they are not valid for cerebral cortex.  Parcellation superseeds smoothing (i.e. smoothing is done)
	ParcellationFileList="NONE" # Absolute path the parcellation dlabel file


	echo "  ${LevelTwoTask}"
	LevelTwoFEATDir="/md_disk3/guoyuan/HCP_group_activation/group_activation_s4_CHCP_match/${TaskName}";
	#feat_model ${LevelTwoFEATDir}/${TaskName};
	i=1

	NumFirstLevelFolders=0; # counter
	for Subject in `cat ${sub_list}` ; do
		data_file=${StudyFolder}/${Subject}/MNINonLinear/Results/${LevelTwoTaskList}/${LevelTwoTaskList}_hp200_s4_level2.feat/design.con
                if [ -f "${data_file}" ] ; then
  			NumFirstLevelFolders=$(($NumFirstLevelFolders+1));
		fi
	done
        
        ## copy cope files to group dir

	for Subject in `cat ${sub_list}` ; do
		echo "    ${Subject}"
                data_file=${StudyFolder}/${Subject}/MNINonLinear/Results/${LevelTwoTaskList}/${LevelTwoTaskList}_hp200_s4_level2.feat/design.con
                        
                       
                if [ -f "${data_file}" ] ; then
                        LevelOneFEATDir=${StudyFolder}/${Subject}/MNINonLinear/Results/${LevelTwoTaskList}/${LevelTwoTaskList}_hp200_s4_level2.feat
                        ### Copy Level 1 stats folders into Level 2 analysis directory
			mkdir -p ${LevelTwoFEATDir}/${Analysis}/${i}
			cp -r ${LevelOneFEATDir}/${Analysis}/* ${LevelTwoFEATDir}/${Analysis}/${i}
			i=$(($i+1))

			### convert CIFTI files to fakeNIFTI if required
			if [ "${Analysis}" != "StandardVolumeStats" ] ; then
			fakeNIFTIused="YES"
				for CIFTI in ${LevelTwoFEATDir}/${Analysis}/*/*.feat/*.${Extension} ; do
					fakeNIFTI=$( echo $CIFTI | sed -e "s|.${Extension}|.nii.gz|" );
					${CARET7DIR}/wb_command -cifti-convert -to-nifti $CIFTI $fakeNIFTI
					rm $CIFTI
				done
			else
				fakeNIFTIused="NO";
			fi
				
                fi
	done   



	### Create dof and Mask files for input to flameo (Level 2 analysis)
	MERGESTRING=""
	i=1
	while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		# dof=`cat ${LevelTwoFEATDir}/${Analysis}/${i}/dof`
                dof=2       # level2 analysis was concatenated the AP and PA cope files, so dof equal to 2. 
		fslmaths ${LevelTwoFEATDir}/${Analysis}/${i}/cope1.feat/res4d.nii.gz -Tstd -bin -mul $dof ${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz                          # all copes used the same res4d.nii.gz file.
		MERGESTRING=`echo "${MERGESTRING}${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz "`
		i=$(($i+1))
	done
	fslmerge -t ${LevelTwoFEATDir}/${Analysis}/dof.nii.gz $MERGESTRING
	fslmaths ${LevelTwoFEATDir}/${Analysis}/dof.nii.gz -Tmin -bin ${LevelTwoFEATDir}/${Analysis}/mask.nii.gz

	### Create merged cope and varcope files for input to flameo (Level 2 analysis)
        
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do

		COPEMERGE=""
		VARCOPEMERGE=""
		i=1
		while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		  	COPEMERGE="${COPEMERGE}${LevelTwoFEATDir}/${Analysis}/${i}/cope${copeCounter}.feat/cope1.nii.gz "
		  	VARCOPEMERGE="${VARCOPEMERGE}${LevelTwoFEATDir}/${Analysis}/${i}/cope${copeCounter}.feat/varcope1.nii.gz "
		  	i=$(($i+1))
		done
		fslmerge -t ${LevelTwoFEATDir}/${Analysis}/cope${copeCounter}.nii.gz $COPEMERGE
		fslmerge -t ${LevelTwoFEATDir}/${Analysis}/varcope${copeCounter}.nii.gz $VARCOPEMERGE
		copeCounter=$(($copeCounter+1))
	done          


	### Run 2nd level analysis using flameo
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do

		cd ${LevelTwoFEATDir}; # run flameo within LevelTwoFEATDir so relative paths work
		flameo --cope=${Analysis}/cope${copeCounter}.nii.gz \
			   --vc=${Analysis}/varcope${copeCounter}.nii.gz \
			   --dvc=${Analysis}/dof.nii.gz \
			   --mask=${Analysis}/mask.nii.gz \
			   --ld=${Analysis}/cope${copeCounter}.feat \
			   --dm=${TaskName}.mat \
			   --cs=${TaskName}.grp \
			   --tc=${TaskName}.con \
			   --runmode=fe

		cd $OLDPWD; # Go back to previous directory using bash built-in $OLDPWD
		copeCounter=$(($copeCounter+1))
	done    

	### Cleanup Temporary Files (which were copied from Level1 stats directories)
	#i=1
	#while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
	#	rm -r ${LevelTwoFEATDir}/${Analysis}/${i}
	#	i=$(($i+1))
	#done	
	
	
	### Convert fakeNIFTI Files back to CIFTI (if necessary)
        LevelOneFEATDir1=${StudyFolder}/3001/MNINonLinear/Results/${LevelOneTasksList}/${LevelOneTasksList}_hp200_s2_level1.feat;
        echo "LevelOneFEATDir=${LevelOneFEATDir}";
        #  fakeNIFTIused="YES"
	if [ "$fakeNIFTIused" = "YES" ] ; then
		log_Msg "Convert fakeNIFTI files back to CIFTI"
		CIFTItemplate="${LevelOneFEATDir1}/${Analysis}/pe1.${Extension}"

		# convert flameo input files for review: ${LevelTwoFEATDir}/${Analysis}/*.nii.gz
		# convert flameo output files for each cope: ${LevelTwoFEATDir}/${Analysis}/cope*.feat/*.nii.gz
		for fakeNIFTI in ${LevelTwoFEATDir}/${Analysis}/*.nii.gz ${LevelTwoFEATDir}/${Analysis}/cope*.feat/*.nii.gz; do
			CIFTI=$( echo $fakeNIFTI | sed -e "s|.nii.gz|.${Extension}|" );
			${CARET7DIR}/wb_command -cifti-convert -from-nifti $fakeNIFTI $CIFTItemplate $CIFTI -reset-timepoints 1 1
			rm $fakeNIFTI 
		done
	fi		
done


