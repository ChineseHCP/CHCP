clc;
clear;
data_path='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/Task_distribution_FDR';
p_values=importdata([data_path '/P_values.xlsx']);
p_values_corrected=zeros(7,7);
for i=1:7
    task_i=p_values.data(:,i);
    [~,~,padj]=fdr(task_i);
    p_values_corrected(1:7,i)=padj;
end

volume_data=MRIread([data_path '/mask.nii.gz']);
voxel_sum=sum(sum(sum(volume_data.vol)));


