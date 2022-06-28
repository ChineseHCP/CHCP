sublist=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt;
hemi=rh;  # lh and rh
for sub in `cat ${sublist}`
do 
{

#project volume(nii.gz) to surface(nii.gz)#
SUBJECTS_DIR=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/${sub}/T1w/${sub}/T1w
#cp -r /md_disk2/meizhen/CHCP/Data/3000/T1w/fsaverage /md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/${sub}/T1w/${sub}/T1w;
subject=$sub
regfile=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/${sub}/T1w/${sub}/T1w/${subject}/mri/transforms/hires21mm.dat;
volume=/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/${subject}/${subject}_0.8mm_label_r;  # lr
output=/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/${subject}/${subject}_0.8mm_label_fsaverage_164k_${hemi}.nii.gz;
proj_mesh=fsaverage;
gzip ${volume}.nii;
mri_vol2surf --srcsubject ${sub} --mov ${volume}.nii.gz --reg $regfile --hemi $hemi --projfrac 0.5 --trgsubject $proj_mesh --o $output --noreshape --interp nearest;

}
done

