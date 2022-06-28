#!/bin/bash 

chcp_path="/md_disk3/HCP_group_activation/test_retest_reliability/result/smooth/CHCP/Cope_map";
CIFTItemplate="/md_disk3/CHCP_preproc/3001/MNINonLinear/Results/rfMRI_Emotion_AP/rfMRI_Emotion_AP_hp200_s2_level1.feat/GrayordinatesStats/cope1.dtseries.nii";
Extension="dtseries.nii";
for task in Motor Nback Emotion Gambling Language Relation Social
do
	for fakeNIFTI in ${chcp_path}/${task}/*.nii.gz; do
		CIFTI=$( echo $fakeNIFTI | sed -e "s|.nii.gz|.${Extension}|" );
		wb_command -cifti-convert -from-nifti $fakeNIFTI $CIFTItemplate $CIFTI -reset-timepoints 1 1
		#rm $fakeNIFTI 
	done
done
