clc;clear;
ROI_LABEL = 1:2:209; ROI = 'Cortex'; LorR = 'L'; lr = 'l'; % based on BNA label table
% ROI_LABEL = 2:2:210; ROI = 'Cortex'; LorR = 'R'; lr = 'r';
WD='/md_disk4/meizhen/CHCP/hcp_indipar/add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
dti = '/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/';
SUB = textread(SUB_LIST,'%s');

% confidence_value_thr = 1.15;
threshold = 10;
pm_threshold = 40;
perc_voxel_thr = 0.01;
NewVoxSize = [5,5,5];

for isub=1:length(SUB)
display(strcat(num2str(isub),PWD,SUB{isub},'_',ROI,'_',LorR,'_start!new7!'));
%% indipar mask in individual b0 space as initial seeds
BNA_nii = load_untouch_nii(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/wBN_Atlas_246_1.5mm.nii'));
BNA_img = double(BNA_nii.img);
BNA_img(BNA_img>210) = 0;
indipar_mask = load_untouch_nii(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/indipar_mask_1.5mm_',lr,'.nii'));
indipar_mask_img = double(indipar_mask.img);
BNA_indipar_img = BNA_img.*indipar_mask_img; % to calc initial ref con
% BNA_nii.img = BNA_indipar_img;
% save_untouch_nii(BNA_nii,strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/indipar_wBNA_1.5mm.nii'));
clear BNA_nii BNA_img indipar_mask;
%% ROI_calc_coord
% [nxr,nyr,nzr] = size(BNA_img);
% fid_r = fopen(strcat(WD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord.txt'),'w');
% for zr = 1:nzr
%     [xr, yr] = find(ismember(BNA_img(:,:,zr),ROI_LABEL));
%     for j = 1:numel(xr)
%         fprintf(fid_r,'%d %d %d\r\n',xr(j)-1,yr(j)-1,zr-1);
%     end
% end
% clear xr yr zr j nzr nxr nyr fid_r;

%% fiber_tracking
% % qsub -cwd -l vf=200G ROI_probtrackx.sh

%% calc_connectivity_matrix
imgfolder = strcat(PWD,SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_probtrackx');
outfolder = strcat(PWD,SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_matrix/');
if ~exist(outfolder,'dir'); mkdir(outfolder); end
f_Create_Connectivity_Matrix(imgfolder,outfolder,threshold,NewVoxSize);
delete(gcp('nocreate'))

%% record initial label from BNA
load(strcat(outfolder,'connection_matrix'));
load(strcat(outfolder,'xyz'));
[n_roi_voxel, n_brain_voxel] = size(con_matrix);
n_roi_label = length(ROI_LABEL);
% input initial label
label = zeros(length(xyz),1);
for i = 1:length(xyz)
    label(i,1) = BNA_indipar_img(xyz(i,1)+1,xyz(i,2)+1,xyz(i,3)+1); % xyz + 1 = actual xyz
end
output_label = strcat(outfolder,'label_iter_0.mat'); % initial label
save(output_label,'label','-v7.3'); n_iteration = 0;
f_map_label_iter_in_b0_space(PWD,outfolder,SUB{isub},n_iteration,label,xyz);
clear output_label i;

%% record pm_indipar from BNA_PM
f_Create_PM_in_b0_space(dti,PWD,outfolder,SUB{isub},ROI_LABEL);
pm_indipar = zeros(length(xyz),length(ROI_LABEL));
for ilabel = 1:length(ROI_LABEL)
    pm = load_untouch_nii(strcat(outfolder,'pm/wr',num2str(ROI_LABEL(ilabel),'%03d'),'.nii'));
    pm_img = double(pm.img);
    pm_indipar_img = pm_img.*indipar_mask_img;
    for i = 1:length(xyz)
        pm_indipar(i,ilabel) = pm_indipar_img(xyz(i,1)+1,xyz(i,2)+1,xyz(i,3)+1); % xyz + 1 = actual xyz
    end
end
pm_indipar(pm_indipar<pm_threshold) = 0;
clear i ilabel pm pm_img pm_indipar_img;

%% calc_roi_ref_con_matrix (initial ref connection)
label_xyz_index = cell(n_roi_label,1);
roi_ref_con_matrix = zeros(n_roi_label,n_brain_voxel);
for ilabel = 1:n_roi_label
    a(:) = find(pm_indipar(:,ilabel)>=pm_threshold);
    label_xyz_index{ilabel} = a; % xyz index of each ROI label
    clear a;
end
clear ilabel;
for ilabel = 1:n_roi_label
    a = sum(con_matrix(label_xyz_index{ilabel},:).*pm_indipar(label_xyz_index{ilabel},ilabel));
    b = a./sum(pm_indipar(label_xyz_index{ilabel},ilabel));
    roi_ref_con_matrix(ilabel,:) = b(:); % initial ref connection
end
roi_ref_con_matrix(isnan(roi_ref_con_matrix)) = 0;
clear a b ilabel label_xyz_index;
output_label = strcat(outfolder,'roi_ref_con_matrix_iter_0.mat');
save(output_label,'roi_ref_con_matrix','-v7.3');

n_iteration = 0;
perc_voxel = 1;
% confidence_value = zeros(n_roi_voxel,1);

%% iteration body
while (perc_voxel>perc_voxel_thr)
    n_iteration = n_iteration+1;
    corr_matrix = zeros(n_roi_voxel,n_roi_label);
    parfor i = 1:n_roi_voxel
        for j = 1:n_roi_label
            a = corrcoef(con_matrix(i,:),roi_ref_con_matrix(j,:)); % method 1
            corr_matrix(i,j) = a(1,2);
        end
    end
    corr_matrix(isnan(corr_matrix)) = 0;
    clear i j a;
    
    %% reassign voxel to max corr roi
    corr_max_value = zeros(n_roi_voxel,1);
    corr_max_label = zeros(n_roi_voxel,1);
    sii=zeros(n_roi_voxel,1);
    parfor i = 1:n_roi_voxel
        [sv, si] = max(corr_matrix(i,:));
        corr_max_value(i,1) = sv;  % sv=corrcoef(max--min)
        corr_max_label(i,1) = ROI_LABEL(si);  % si=label index, NEED translate to ROI_LABEL
        sii(i) = si;
    end
    label0 = label; % label0 = before iter, label1 = after iter
    label(:) = corr_max_label(:,1);
    clear si sii sv i corr_matrix corr_max_label;
    
    %% calc roi_core_con_matrix, roi_mean_con_matrix, roi_ref_con_matrix(NEW)
    % calc roi_mean_con_matrix
    label_xyz_index = cell(n_roi_label,1);
    for i = 1:n_roi_label
        a(:) = find(label(:) == ROI_LABEL(i));
        label_xyz_index{i} = a; % xyz index of each ROI label
        clear a i;
    end
    roi_mean_con_matrix = zeros(n_roi_label,n_brain_voxel);
    for i = 1:n_roi_label
        a = sum(con_matrix(label_xyz_index{i},:));
        b = a./length(label_xyz_index{i});
        roi_mean_con_matrix(i,:) = b(:);
    end
    clear a b i label_xyz_index;
    roi_mean_con_matrix(isnan(roi_mean_con_matrix)) = 0;
    output_label = strcat(outfolder,'roi_mean_con_matrix_iter_',num2str(n_iteration),'.mat');
    save(output_label,'roi_mean_con_matrix','-v7.3');
    
    % calc roi_ref_con_matrix (NEW)
    roi_ref_con_matrix = 0.9*roi_ref_con_matrix+0.1*roi_mean_con_matrix;
    roi_ref_con_matrix(isnan(roi_ref_con_matrix)) = 0;
    
    % calc the percentage of voxels whose label changed
    b = ((label-label0)~=0);
    n_voxel_change_label = sum(b(:));
    perc_voxel = n_voxel_change_label./n_roi_voxel;
    perc_voxel_change_label(n_iteration) = perc_voxel;
    clear b;
    f_map_label_iter_in_b0_space(PWD,outfolder,SUB{isub},n_iteration,label,xyz);
    display(strcat(num2str(isub),PWD,SUB{isub},'_',ROI,'_',LorR,'_',num2str(n_iteration),'th iteration finished!'));
    display(strcat(num2str((perc_voxel*100)),'% voxels changed label.'));
end

%% after iteration
max_corr_value = corr_max_value;
output_max_corr_value = strcat(outfolder,'max_corr_value.mat');
save(output_max_corr_value,'max_corr_value','-v7.3');

output_n_roi_voxel = strcat(outfolder,'n_roi_voxel.mat');
save(output_n_roi_voxel,'n_roi_voxel');

output_perc_voxel_change_label = strcat(outfolder,'perc_voxel_change_label.mat');
save(output_perc_voxel_change_label,'perc_voxel_change_label');

output_roi_mean_connection = strcat(outfolder,'roi_mean_con_matrix.mat');
save(output_roi_mean_connection,'roi_mean_con_matrix','-v7.3');

clear output_xyz output_max_corr_value output_n_roi_voxel...
    output_perc_voxel_change_label output_roi_mean_connection;

filename = strcat(outfolder,'label.nii');
nii = load_untouch_nii(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/indipar_mask_1.5mm_',lr,'.nii'));
image_f = nii.img;
image_f(:,:,:)=0;
for i = 1:length(xyz)
    image_f(xyz(i,1)+1,xyz(i,2)+1,xyz(i,3)+1)=label(i);
end
nii.img = image_f;
save_untouch_nii(nii,filename);
clear i image_f;
end

