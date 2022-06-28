clc, clear, close all;
% load subject matrix
data_path='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/Dice_surface_area_regress';

dice=importdata([data_path '/Dice_Variation_regress_surface_area.xlsx']);
area=importdata([data_path '/Surface_area_Variation_regress_surface_area.xlsx']);
dice_hcp=dice.data(:,1);
dice_chcp=dice.data(:,2);
area_hcp=area.data(:,1);
area_chcp=area.data(:,2);
regressor_HCP=dice.data(:,3);
regressor_CHCP=dice.data(:,4);

% Dice regress surface area
[B,dev,stats]=glmfit(regressor_HCP,dice_hcp);
con=B(1);
dice_hcp_regressed=stats.resid+con;
    
[B,dev,stats]=glmfit(regressor_CHCP,dice_chcp);
con=B(1);
dice_chcp_regressed=stats.resid+con;

% Area regress surface area
[B,dev,stats]=glmfit(regressor_HCP,area_hcp);
con=B(1);
area_hcp_regressed=stats.resid+con;
    
[B,dev,stats]=glmfit(regressor_CHCP,area_chcp);
con=B(1);
area_chcp_regressed=stats.resid+con;
