%% gm + wmsurf -> indipar_mask
%% mask
clear all; clc;
WD='/md_disk4/meizhen/CHCP/hcp_indipar/add5/';
SUB_LIST='/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt';
SUB = textread(SUB_LIST,'%s');

%%
parfor i = 1:numel(SUB)
outfolder = strcat(WD,SUB{i},'/',SUB{i},'_indipar_mask');
filename = strcat(outfolder,'/indipar_mask_1.5mm.nii');
filename_l = strcat(outfolder,'/indipar_mask_1.5mm_l.nii');
filename_r = strcat(outfolder,'/indipar_mask_1.5mm_r.nii');
gm_nii = load_untouch_nii(strcat(outfolder,'/raparc+aseg.nii'));
image_f = gm_nii.img;
image_f(:,:,:)=0;
image_f = image_f+gm_nii.img;
image_f(image_f<1000) = 0;
image_f(image_f>=1000) =1;
% dilate gm.img as mask to remove wm voxels located in subcortex
B = zeros(3,3,3);
B(:,:,1) = [0 1 0; 1 1 1; 0 1 0];
B(:,:,2) = [1 1 1; 1 1 1; 1 1 1]; 
B(:,:,3) = [0 1 0; 1 1 1; 0 1 0];
image_ff = imdilate(image_f,B); % gm mask
% dilate bna as mask to remove subcortex voxels in gm mask
bna_nii = load_untouch_nii(strcat(outfolder,'/wBN_Atlas_246_1.5mm.nii'));
image_bna = bna_nii.img;
image_bna(:,:,:) = 0;
image_bna(find(bna_nii.img<=210&bna_nii.img>0)) = 1;
image_bna = imdilate(image_bna,B);
image_bna = imdilate(image_bna,B); % bna mask
image_ff = image_ff.*image_bna; % final mask
%% lrh_white.nii
wm_rh = gm_nii.img;
wm_rh(:,:,:) = 0;
wm_rh(gm_nii.img==41) = 1;
wm_lh = gm_nii.img;
wm_lh(:,:,:) = 0;
wm_lh(gm_nii.img==2) = 1;
gm_nii.img = wm_rh;
save_untouch_nii(gm_nii,strcat(outfolder,'/rh_white.nii'));

gm_nii.img = wm_lh;
save_untouch_nii(gm_nii,strcat(outfolder,'/lh_white.nii'));

%% indipar mask
gm_nii = load_untouch_nii(strcat(outfolder,'/raparc+aseg.nii'));
wm_lh_nii = load_untouch_nii(strcat(outfolder,'/lh_white.nii'));
wm_rh_nii = load_untouch_nii(strcat(outfolder,'/rh_white.nii'));
image_f = gm_nii.img;
image_f(:,:,:)=0;
image_f = image_f+wm_lh_nii.img;
image_f = image_f+wm_rh_nii.img;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
image_w = image_f.*image_ff;

gm_nii = load_untouch_nii(strcat(outfolder,'/raparc+aseg.nii'));
image_g = gm_nii.img;
image_g(image_g<1000) = 0;
image_g(image_g>=1000) =1;
image_g = image_g.*image_ff;

image_f = image_g+image_w;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
gm_nii.img = image_f;
save_untouch_nii(gm_nii,filename); 
%% indipar mask left hemisphere
wm_lh_nii = load_untouch_nii(strcat(outfolder,'/lh_white.nii'));
image_f = gm_nii.img;
image_f(:,:,:)=0;
image_f = image_f+wm_lh_nii.img;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
image_w = image_f.*image_ff;
gm_nii = load_untouch_nii(strcat(outfolder,'/raparc+aseg.nii'));
image_g = gm_nii.img;
image_g(image_g<1000) = 0;
image_g(image_g>=2000) = 0;
image_g(image_g>=1000) =1;
image_g = image_g.*image_ff;
image_f = image_g+image_w;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
gm_nii.img = image_f;
save_untouch_nii(gm_nii,filename_l); 
%% indipar mask right hemisphere
wm_rh_nii = load_untouch_nii(strcat(outfolder,'/rh_white.nii'));
image_f = gm_nii.img;
image_f(:,:,:)=0;
image_f = image_f+wm_rh_nii.img;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
image_w = image_f.*image_ff;
gm_nii = load_untouch_nii(strcat(outfolder,'/raparc+aseg.nii'));
image_g = gm_nii.img;
image_g(image_g<2000) = 0;
image_g(image_g>=2000) = 1;
image_g = image_g.*image_ff;
image_f = image_g+image_w;
image_f(image_f<1) = 0;
image_f(image_f>=1) =1;
gm_nii.img = image_f;
save_untouch_nii(gm_nii,filename_r); 
end
