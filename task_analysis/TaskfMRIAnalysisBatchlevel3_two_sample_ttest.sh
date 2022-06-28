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

StudyFolder="/md_disk4/guoyuan/HCP_tfMRI_data/individual_analysis" #Location of Subject folders (named by subjectID)
#Subjlist="3001" #Space delimited list of subject IDs
sub_list=/md_disk3/guoyuan/HCP_group_activation/a_bash/HCP.txt;
StudyFolder1="/md_disk3/guoyuan/CHCP_preproc" #Location of Subject folders (named by subjectID)
#Subjlist="3001" #Space delimited list of subject IDs
Subjlist1=/md_disk3/guoyuan/HCP_group_activation/a_bash/CHCP.txt;
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
    QUEUE="-q all.q"
fi

PRINTCOM=""
#PRINTCOM="echo"

########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the results of the HCP minimal preprocesing pipelines from Q2

######################################### DO WORK ##########################################

TaskNameList=""
#TaskNameList="${TaskNameList} EMOTION"
#TaskNameList="${TaskNameList} GAMBLING"
#TaskNameList="${TaskNameList} LANGUAGE"
#TaskNameList="${TaskNameList} MOTOR"
#TaskNameList="${TaskNameList} RELATIONAL"
TaskNameList="${TaskNameList} SOCIAL"
#TaskNameList="${TaskNameList} WM"

TaskNameList1=""
#TaskNameList1="${TaskNameList1} Emotion"
#TaskNameList1="${TaskNameList1} Gambling"
#TaskNameList1="${TaskNameList1} Language"
#TaskNameList1="${TaskNameList1} Motor"
#TaskNameList1="${TaskNameList1} Relation"
TaskNameList1="${TaskNameList1} Social"
#TaskNameList1="${TaskNameList1} WM"


Analysis="GrayordinatesStats";
Extension="${ExtensionList}dtseries.nii"
NumContrasts=6;
for TaskName1 in ${TaskNameList1}
do
for TaskName in ${TaskNameList}
do


	LevelTwoTaskList="tfMRI_${TaskName}"  #"rfMRI_${TaskName}" #Space delimited list
	LevelTwoTaskList1="rfMRI_${TaskName1}"  #"rfMRI_${TaskName}" #Space delimited list


	feat_file="/md_disk3/guoyuan/HCP_group_activation/Two_sample_ttest/${TaskName}";
	
	#feat_model ${feat_file}/${TaskName};
	i=1
        
        ### Calculate the HCP subject number
	NumFirstLevelFolders=0; # counter
	for Subject in `cat ${sub_list}` ; do
		data_file=${StudyFolder}/${Subject}/MNINonLinear/Results/${LevelTwoTaskList}/${LevelTwoTaskList}_hp200_s4_level2.feat/design.con
		
                if [ -f "${data_file}" ] ; then
			echo "Subject=${data_file}";
  			NumFirstLevelFolders=$(($NumFirstLevelFolders+1));
		fi
	done
        ### Calculate the CHCP subject number
	NumFirstLevelFolders1=0; # counter
	for Subject1 in $Subjlist1 ; do
		data_file1=${StudyFolder1}/${Subject1}/MNINonLinear/Results/${LevelTwoTaskList1}/${LevelTwoTaskList1}_hp200_s4_level2.feat/design.con

                if [ -f "${data_file1}" ] ; then
                	echo "Subject1=${data_file1}";
  			NumFirstLevelFolders1=$(($NumFirstLevelFolders1+1));
		fi
	done


	### Create dof and Mask files in HCP dataset
	MERGESTRING=""
	i=1
        LevelTwoFEATDir_HCP="/md_disk3/guoyuan/HCP_group_activation/group_activiation_s4/${TaskName}"
	while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		# dof=`cat ${LevelTwoFEATDir}/${Analysis}/${i}/dof`
                #dof=2       # level2 analysis was concatenated the AP and PA cope files, so dof equal to 2. 
		#fslmaths ${LevelTwoFEATDir}/${Analysis}/${i}/cope1.feat/res4d.nii.gz -Tstd -bin -mul $dof ${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz                          # all copes used the same res4d.nii.gz file.
		MERGESTRING=`echo "${MERGESTRING}${LevelTwoFEATDir_HCP}/${Analysis}/${i}/dofmask.nii.gz "`
		i=$(($i+1))
	done

        i=1
	### Create dof and Mask files in CHCP dataset
        LevelTwoFEATDir_CHCP="/md_disk3/guoyuan/CHCP_preproc/0_group_activation_s4/${TaskName1}";
	while [ "$i" -le "${NumFirstLevelFolders1}" ] ; do
		# dof=`cat ${LevelTwoFEATDir}/${Analysis}/${i}/dof`
                #dof=2       # level2 analysis was concatenated the AP and PA cope files, so dof equal to 2. 
		#fslmaths ${LevelTwoFEATDir}/${Analysis}/${i}/cope1.feat/res4d.nii.gz -Tstd -bin -mul $dof ${LevelTwoFEATDir}/${Analysis}/${i}/dofmask.nii.gz                          # all copes used the same res4d.nii.gz file.
		MERGESTRING=`echo "${MERGESTRING}${LevelTwoFEATDir_CHCP}/${Analysis}/${i}/dofmask.nii.gz "`
		i=$(($i+1))
	done
        LevelTwoFEATDir1="/md_disk3/guoyuan/HCP_group_activation/Two_sample_ttest/smoothed/${TaskName}"
        mkdir -p ${LevelTwoFEATDir1}/${Analysis}
	fslmerge -t ${LevelTwoFEATDir1}/${Analysis}/dof.nii.gz $MERGESTRING
	fslmaths ${LevelTwoFEATDir1}/${Analysis}/dof.nii.gz -Tmin -bin ${LevelTwoFEATDir1}/${Analysis}/mask.nii.gz

	### Create merged cope and varcope files for input to flameo (Level 2 analysis)
        
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do

		COPEMERGE=""
		VARCOPEMERGE=""
		### merge HCP cope and varcope files
		i=1
		while [ "$i" -le "${NumFirstLevelFolders}" ] ; do
		  	COPEMERGE="${COPEMERGE}${LevelTwoFEATDir_HCP}/${Analysis}/${i}/cope${copeCounter}.feat/cope1.nii.gz "
		  	VARCOPEMERGE="${VARCOPEMERGE}${LevelTwoFEATDir_HCP}/${Analysis}/${i}/cope${copeCounter}.feat/varcope1.nii.gz "
		  	i=$(($i+1))
		done
                
		### merge CHCP cope and varcope files
		i=1
		while [ "$i" -le "${NumFirstLevelFolders1}" ] ; do
		  	COPEMERGE="${COPEMERGE}${LevelTwoFEATDir_CHCP}/${Analysis}/${i}/cope${copeCounter}.feat/cope1.nii.gz "
		  	VARCOPEMERGE="${VARCOPEMERGE}${LevelTwoFEATDir_CHCP}/${Analysis}/${i}/cope${copeCounter}.feat/varcope1.nii.gz "
		  	i=$(($i+1))
		done
		fslmerge -t ${LevelTwoFEATDir1}/${Analysis}/cope${copeCounter}.nii.gz $COPEMERGE
		fslmerge -t ${LevelTwoFEATDir1}/${Analysis}/varcope${copeCounter}.nii.gz $VARCOPEMERGE
		copeCounter=$(($copeCounter+1))
	done          


	### Run 2nd level analysis using flameo
	copeCounter=1
	while [ "$copeCounter" -le "${NumContrasts}" ] ; do

		cd ${LevelTwoFEATDir1}; # run flameo within LevelTwoFEATDir so relative paths work
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
        LevelOneFEATDir0=/md_disk3/guoyuan/CHCP_preproc/3001/MNINonLinear/Results/rfMRI_Motor_AP/rfMRI_Motor_AP_hp200_s2_level1.feat;
        echo "LevelOneFEATDir=${LevelOneFEATDir}";
        fakeNIFTIused="YES"
	if [ "$fakeNIFTIused" = "YES" ] ; then
	
		CIFTItemplate="${LevelOneFEATDir0}/${Analysis}/pe1.${Extension}"

		# convert flameo input files for review: ${LevelTwoFEATDir}/${Analysis}/*.nii.gz
		# convert flameo output files for each cope: ${LevelTwoFEATDir}/${Analysis}/cope*.feat/*.nii.gz
		for fakeNIFTI in ${LevelTwoFEATDir1}/${Analysis}/*.nii.gz ${LevelTwoFEATDir1}/${Analysis}/cope*.feat/*.nii.gz; do
			CIFTI=$( echo $fakeNIFTI | sed -e "s|.nii.gz|.${Extension}|" );
			${CARET7DIR}/wb_command -cifti-convert -from-nifti $fakeNIFTI $CIFTItemplate $CIFTI -reset-timepoints 1 1
			rm $fakeNIFTI 
		done
	fi		
done
done



