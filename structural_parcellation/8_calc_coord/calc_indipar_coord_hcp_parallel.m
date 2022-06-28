clc;clear;
% ROI_LABEL = 1:2:209; ROI = 'Cortex'; LorR = 'L'; lr = 'l'; % based on BNA label table
ROI_LABEL = 2:2:210; ROI = 'Cortex'; LorR = 'R'; lr = 'r';
PWD='/md_disk4/meizhen/CHCP/hcp_indipar/add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');

for isub=1:numel(SUB)
    display(strcat(PWD,SUB{isub},'_',ROI,'_',LorR,'_coord_start!new7!'));
    % %% indipar mask in individual b0 space as initial seeds
    % BNA_nii = load_untouch_nii(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/wBN_Atlas_246_1.5mm.nii'));
    % BNA_img = double(BNA_nii.img);
    % BNA_img(BNA_img>210) = 0;
    % indipar_mask = load_untouch_nii(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/indipar_mask_1.5mm_',lr,'.nii'));
    % indipar_mask_img = double(indipar_mask.img);
    % BNA_indipar_img = BNA_img.*indipar_mask_img; % to calc initial ref con
    % % BNA_nii.img = BNA_indipar_img;
    % % save_untouch_nii(BNA_nii,strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_indipar_mask/indipar_wBNA_1.5mm.nii'));
    % clear BNA_nii BNA_img indipar_mask;
    % %% ROI_calc_coord
    % [nxr,nyr,nzr] = size(indipar_mask_img);
    % fid_r = fopen(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord.txt'),'w');
    % for zr = 1:nzr
    %     [xr, yr] = find(indipar_mask_img(:,:,zr)==1);
    %     for j = 1:numel(xr)
    %         fprintf(fid_r,'%d %d %d\r\n',xr(j)-1,yr(j)-1,zr-1);
    %     end
    % end
    % clear xr yr zr j nzr nxr nyr fid_r;
    
    data = load(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord.txt'));
    [a,b] = size(data);
    n = ceil(a/30);
    
    filename = strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord');
    mkdir(filename);
    for m = 1:29
        fid_r = fopen(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord/',SUB{isub},'_',ROI,'_',LorR,'_coord_',num2str(m),'.txt'),'w');
        for i = (1+n*(m-1)):(n*m)
            fprintf(fid_r,'%d %d %d\r\n',data(i,1),data(i,2),data(i,3));
        end
        fclose(fid_r);
        clear fid_r;
    end
    
    fid_r = fopen(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord/',SUB{isub},'_',ROI,'_',LorR,'_coord_30.txt'),'w');
    for i = (1+n*29):a
        fprintf(fid_r,'%d %d %d\r\n',data(i,1),data(i,2),data(i,3));
    end
    fclose(fid_r);
    clear fid_r;
    
    fid_r = fopen(strcat(PWD,'/',SUB{isub},'/',SUB{isub},'_',ROI,'_',LorR,'_coord/',SUB{isub},'_',ROI,'_',LorR,'_coord_list.txt'),'w');
    for i = 1:30
        fprintf(fid_r,strcat(SUB{isub},'_',ROI,'_',LorR,'_coord_',num2str(i),'.txt'));
        fprintf(fid_r,'\n');
    end
    fclose(fid_r);
    clear fid_r;
end





