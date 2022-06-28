clc, clear, close all;
% load subject matrix
data_path_regress='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/Dice_coeff';
data_path_dice='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/a_bash/paralle';
data_path='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/DIce_surface_area_permuted/Dice/original_dice';

dice7L=importdata([data_path '/HCP_CHCP_dice_7network_new_L.txt']);
dice7R=importdata([data_path '/HCP_CHCP_dice_7network_new_R.txt']);

regressor_area_7_L=fullfile(data_path_regress,'HCP_CHCP_area_7networkL.txt');
regressor_area_7_R=fullfile(data_path_regress,'HCP_CHCP_area_7networkR.txt');

regressor7L=importdata(regressor_area_7_L);
regressor7R=importdata(regressor_area_7_R);
dice7L=1-dice7L;
dice7R=1-dice7R;
[inter_num,net_num]=size(dice7L);
dice7_L_regressed_chcp=zeros(inter_num,net_num);
dice7_R_regressed_chcp=zeros(inter_num,net_num);
for i=1:inter_num
    dice7L_i=dice7L(i,:);
    [B,dev,stats]=glmfit(regressor7L,dice7L_i);
    con=B(1);
    dice7L_regressed_i=stats.resid+con;
    dice7_L_regressed_chcp(i,:)=dice7L_regressed_i;
    
    dice7R_i=dice7R(i,:);
    [B,dev,stats]=glmfit(regressor7R,dice7R_i);
    con=B(1);
    dice7R_regressed_i=stats.resid+con;
    dice7_R_regressed_chcp(i,:)=dice7R_regressed_i;
end
dice7_L_regressed_chcp=dice7_L_regressed_chcp';
dice7_R_regressed_chcp=dice7_R_regressed_chcp';