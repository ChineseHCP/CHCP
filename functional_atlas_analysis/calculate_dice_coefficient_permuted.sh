#!/bin/bash

python_path=/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/a_bash;
hemi=R;
txt_name=/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/a_bash/permuted/permuted_dice_${hemi}.txt;
for i in {1..1000} ; do
	j=$(($i+1000));
	sub_i=`printf "%04d\n" ${i}`;
	sub_j=`printf "%04d\n" ${j}`;
	echo "sub_i is ${sub_i}, sub_j is ${sub_j}";
	sub_i_label=/md_disk4/guoyuan/Indvidual_atlas/Group_atlas_permutation/generate_profiles_and_ini_params/group/a_label/Permuted_${sub_i}_${hemi}H_clusters7.label.gii;
	sub_j_label=/md_disk4/guoyuan/Indvidual_atlas/Group_atlas_permutation/generate_profiles_and_ini_params/group/a_label/Permuted_${sub_j}_${hemi}H_clusters7.label.gii;
	python ${python_path}/calculate_dice_yeo7_permuted.py ${hemi} ${sub_i_label} ${sub_j_label} ${txt_name};
done

