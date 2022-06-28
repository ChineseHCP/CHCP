function f_Create_Connectivity_Matrix(imgfolder,outfolder,threshold,NewVoxSize)
%-------------------------------------------------------------------------%
% imgfolder * - prename_x_y_z.imgtype
% outfolder   - output directory
% threshold   - threshold probtrackx result
% down_size   - voxel size of resampled images
%-------------------------------------------------------------------------%
imgtype = 'nii.gz';
filedir = dir(strcat(imgfolder,'/*_*_*.',imgtype));
nimg = length(filedir);

xyz = zeros(nimg,3);
x = zeros(nimg,1);
y = zeros(nimg,1);
z = zeros(nimg,1);

tnii = f_load_nii_no_xform(strcat(imgfolder,'/',filedir(1).name));
old_M = tnii.hdr.hist.old_affine;
[timg] = affine(tnii.img,old_M,NewVoxSize,0,0,1); % method = 1
con_matrix = sparse(nimg,size(timg,1)*size(timg,2)*size(timg,3)); 
% con_matrix size = ROI voxel num * down sampled whole brain voxel num

parfor iimg = 1:nimg
    tname = regexp(filedir(iimg).name,'\d+(?#)','match');
    x(iimg)=str2double(tname{end-2});
    y(iimg)=str2double(tname{end-1});
    z(iimg)=str2double(tname{end});
    
    imgname = strcat(imgfolder,'/',filedir(iimg).name);
    nii = load_untouch_nii(imgname);
    [reimg] = affine(nii.img,old_M,NewVoxSize,0,0,1); % method = 1
    con_matrix(iimg,:) = reshape(reimg,1,[]);
end
xyz = [x,y,z];
% remove 0 or NaN columns
con_matrix(isnan(con_matrix) | isinf(con_matrix)) = 0;
d = ~(max(con_matrix) == 0 & min(con_matrix) == 0);
con_matrix = con_matrix(:,d>0);
% full matrix
con_matrix = full(con_matrix);
% threshold
con_matrix(con_matrix < threshold )=0; 

if ~exist(outfolder,'dir') mkdir(outfolder); end;
% create connection_matrix.mat
output = strcat(outfolder,'connection_matrix.mat');
save(output,'con_matrix','xyz','-v7.3');
output_xyz = strcat(outfolder,'xyz.mat');
save(output_xyz,'xyz','-v7.3');
clear con_matrix xyz;

