function f_map_label_iter_in_b0_space(WD,outfolder,sub_num,iter_num,label,xyz)
%-------------------------------------------------------------------------%
% visualise the iteration results(label_iter_n.nii) in brain volume space
%-------------------------------------------------------------------------%
% WD = '/meizhen/DTI/Data/Indipar/';
filename = strcat(outfolder,'label_iter_',num2str(iter_num),'.nii');
nii = load_untouch_nii(strcat(WD,sub_num,'/',sub_num,'_indipar_mask/indipar_mask_1.5mm.nii'));
image_f = nii.img;
image_f(:,:,:)=0;
for i = 1:length(xyz)
    image_f(xyz(i,1)+1,xyz(i,2)+1,xyz(i,3)+1)=label(i);
end
clear i xyz;
nii.img = image_f;
save_untouch_nii(nii,filename);
    

