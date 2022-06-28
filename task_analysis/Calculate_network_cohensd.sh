#!/bin/bash 


population=HCP;
NumContrasts=6;
Networks_cohensd=/md_disk3/HCP_group_activation/Cohens_d/Network_cohensd;
mkdir -p ${Networks_cohensd};

for task in EMOTION GAMBLING LANGUAGE RELATIONAL SOCIAL ; do
#for task in MOTOR ; do
	for hemi in L R ; do
		txt_file=${Networks_cohensd}/${population}_${task}_cohensd_${hemi}h.txt;
		surface_in=/md_disk3/HCP_CHCP_atlas_comparison/Yeo7_atlas/template/Conte69.${hemi}.midthickness.32k_fs_LR.surf.gii;
		for ((network=1;network<=7;network++)) ; do
			copeCounter=1
			while [ "$copeCounter" -le "${NumContrasts}" ] ; do
				Network_mask=/md_disk3/HCP_CHCP_atlas_comparison/Yeo7_atlas/surface_area/${population}_surface_roi/${population}.${hemi}.network_${network}.func.gii;
				cope_file=/md_disk3/HCP_group_activation/Cohens_d/${task}/GrayordinatesStats/HCP_CHCP_cope${copeCounter}_cohens_d_abs_${hemi}.func.gii;
				cope_network_output=${Networks_cohensd}/network_cohensd_metric/${task};
				mkdir -p ${cope_network_output};
				wb_command -metric-math 'x*y' ${cope_network_output}/HCP_CHCP_cope${copeCounter}_network${network}.func.gii -var x ${Network_mask} -var y ${cope_file};
				cope_network_in=${cope_network_output}/HCP_CHCP_cope${copeCounter}_network${network}.func.gii;
				surface_area=`wb_command -metric-weighted-stats ${cope_network_in} -mean -area-surface ${surface_in} -roi ${Network_mask}`; 
                       		echo -n "${surface_area}	" >> ${txt_file};
				copeCounter=$(($copeCounter+1))
			done	
		echo >> ${txt_file}
		done
	done
done



