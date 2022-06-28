clc;
clear;
sub_list='/md_disk5/guoyuan/ReHo_fALFF/ReHo_surf/sublist/CHCP_all_run_140.txt';
chcp_data_path_L='/md_disk5/guoyuan/ReHo_fALFF/ReHo_surf/gii_test/CHCP/Results/FunSurfLH';
chcp_data_path_R='/md_disk5/guoyuan/ReHo_fALFF/ReHo_surf/gii_test/CHCP/Results/FunSurfRH';

sublist=importdata(sub_list);
data_L=zeros(32492,1);
data_R=zeros(32492,1);
data_L=single(data_L);
data_R=single(data_R);
for i=1:length(sublist)
    sub_i=num2str(sublist(i));
    falff_L_i=fullfile(chcp_data_path_L,['fALFF_FunSurfW/fALFF_sub',sub_i,'.func.gii']);
    falff_R_i=fullfile(chcp_data_path_R,['fALFF_FunSurfW/fALFF_sub',sub_i,'.func.gii']);
    [falff_L_i_data,voxel_L_i,filelist_L_i,falff_L_i_header]=y_ReadAll(falff_L_i);
    [falff_R_i_data,voxel_R_i,filelist_R_i,falff_R_i_header]=y_ReadAll(falff_R_i);
    data_L=data_L+falff_L_i_data;
    data_R=data_R+falff_R_i_data;
end
sub_nums=length(sublist);
mean_falff_L=data_L/sub_nums;
mean_falff_R=data_R/sub_nums;

out_L='/md_disk5/guoyuan/ReHo_fALFF/ReHo_surf/gii_test/CHCP/Results/mean/falff_chcp_mean.L.func.gii';
out_R='/md_disk5/guoyuan/ReHo_fALFF/ReHo_surf/gii_test/CHCP/Results/mean/falff_chcp_mean.R.func.gii';  
y_Write(mean_falff_L,falff_L_i_header,out_L);
y_Write(mean_falff_R,falff_R_i_header,out_R);
