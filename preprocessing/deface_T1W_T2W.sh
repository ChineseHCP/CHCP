#!/bin/bash

input_path=/md_disk3/guoyuan/CHCP;
sub_list=/md_disk3/guoyuan/a_bash/sub_list/sublist.txt

for data_num in `cat ${sub_list}`
do
{
input_t1=${input_path}/CHCP${data_num}/nii/stru/T1w_MPR-1/T1w*.nii.gz;
input_t2=${input_path}/CHCP${data_num}/nii/stru/T2w_SPC-1/T2w*.nii.gz;
input_t1_path=${input_path}/CHCP${data_num}/nii/stru/T1w_MPR-1;
input_t2_path=${input_path}/CHCP${data_num}/nii/stru/T2w_SPC-1;
reorient_t1=${input_path}/CHCP${data_num}/nii/stru/T1w_MPR-1/T1w_reorient.nii.gz;
mask_t1=T1_deface_mask;
mask_t1_name=${input_path}/CHCP${data_num}/nii/stru/T1w_MPR-1/T1_deface_mask.nii.gz;
output_t1=${input_path}/CHCP${data_num}/nii/stru/T1w_MPR-1/T1w_deface.nii.gz;
output_t2=${input_path}/CHCP${data_num}/nii/stru/T2w_SPC-1/T2w_deface.nii.gz;

cd $input_t1_path
fslreorient2std $input_t1 $reorient_t1
fsl_deface $reorient_t1 $output_t1 -d $mask_t1

cd $input_t2_path
antsRegistrationSyN.sh -d 3 -t 'a' -f $reorient_t1 -m $input_t2 -o affine_
antsApplyTransforms -d 3 -i $mask_t1_name -o mask_t2.nii.gz -r $input_t2 -t affine_0GenericAffine.mat
ImageMath 3 $output_t2 m mask_t2.nii.gz $input_t2

}
done


