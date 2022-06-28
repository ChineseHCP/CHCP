#!/bin/bash

population=HCP;
label_out_parcel_path=/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/surface_area/${population}_surface_roi;
mkdir -p $label_out_parcel_path


        for hemi in L R ; do
		txt_file=/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/surface_area/${population}_surface_area_sess2_new_${hemi}h.txt;
		label_in=/md_disk4/guoyuan/Indvidual_atlas/HCP/post_preproc_smooth4_362/generate_profiles_and_ini_params/group/group_362_1_session1_${hemi}H_clusters7.label.gii;
		surface_in=/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/template/Conte69.${hemi}.midthickness.32k_fs_LR.surf.gii;
		for ((network=1;network<=7;network++)) ; do
			label_out_parcel=${label_out_parcel_path}/${population}.${hemi}.network_${network}.func.gii;	
			wb_command -gifti-label-to-roi ${label_in} ${label_out_parcel} -key ${network}
			surface_area=`wb_command -metric-weighted-stats ${label_out_parcel} -sum -area-surface ${surface_in}`;  # >> ${txt_file};
                        echo -n "${surface_area}	" >> ${txt_file};
		done
	echo >> ${txt_file}
	done


