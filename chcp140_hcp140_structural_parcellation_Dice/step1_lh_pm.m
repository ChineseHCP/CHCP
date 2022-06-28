clear all; clc;
% WD2 = '/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/';
% WD2 = '/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/';
ROI_LABEL_left = 1:2:209; % based on BNA label table
ROI_LABEL_right = 2:2:210;
hemi=cell(2,1); hemi{1}='lh'; hemi{2}='rh';
label=cell(2,1); label{1}=ROI_LABEL_left; label{2}=ROI_LABEL_right;

WD='/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/';
pardir = '/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/chcp140_hcp140_pdice/';
%%
h=1;
seed = label{h};
SUB_LIST='/md_disk4/meizhen/chapter4/sub_hcp_140.txt';
SUB = textread(SUB_LIST,'%s');
WD2 = '/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/';
session1 = MRIread(strcat(WD2,SUB{1},'/',SUB{1},'_0.8mm_label_fsaverage_164k_',hemi{h},'.nii.gz'));
fs = session1.vol;
fs_size = length(fs);
pdice_lh= zeros(105,1);

% chcp
lh_pm_chcp = zeros(105,fs_size);
SUB_LIST='/md_disk4/meizhen/chapter4/sub_chcp_140.txt';
SUB = textread(SUB_LIST,'%s');
WD2 = '/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/';

for isub = 1:numel(SUB)
    session1 = MRIread(strcat(WD2,SUB{isub},'/',SUB{isub},'_0.8mm_label_fsaverage_164k_',hemi{h},'.nii.gz'));
    fs = session1.vol;
    for s = 1:105
        tmp_ind = (fs==seed(s));
        lh_pm_chcp(s,:) = lh_pm_chcp(s,:)+tmp_ind;
    end
end
lh_pm_chcp = lh_pm_chcp./numel(SUB)*100;

% hcp
lh_pm_hcp = zeros(105,fs_size);
SUB_LIST='/md_disk4/meizhen/chapter4/sub_hcp_140.txt';
SUB = textread(SUB_LIST,'%s');
WD2 = '/md_disk4/meizhen/CHCP/hcp_indipar/Parcel_Dice/';

for isub = 1:numel(SUB)
    session1 = MRIread(strcat(WD2,SUB{isub},'/',SUB{isub},'_0.8mm_label_fsaverage_164k_',hemi{h},'.nii.gz'));
    fs = session1.vol;
    for s = 1:105
        tmp_ind = (fs==seed(s));
        lh_pm_hcp(s,:) = lh_pm_hcp(s,:)+tmp_ind;
    end
end
lh_pm_hcp = lh_pm_hcp./numel(SUB)*100;

%% mask pm with bna annot file
[v, l, ct] = read_annotation(['/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/label/lh.BN_Atlas.annot']); % l is important

lh_chcp_pm = lh_pm_chcp;
lh_chcp_pm(:,:,:) = 0;
lh_hcp_pm = lh_pm_hcp;
lh_hcp_pm(:,:,:) = 0;

for i = 1:2:209
    for j = 1:163842
        if l(j)==ct.table(i+1,5)
            lh_chcp_pm(:,j) = lh_pm_chcp(:,j);
            lh_hcp_pm(:,j) = lh_pm_hcp(:,j);
        end
    end
end

% pdice
pdice_lh = zeros(105,1);
for s = 1:105
    suma = sum(sum(sum(lh_chcp_pm(s,:))));
    sumb = sum(sum(sum(lh_hcp_pm(s,:))));
    minab = min(lh_chcp_pm(s,:),lh_hcp_pm(s,:));
    summinab = sum(sum(sum(minab)));
    pdice_lh(s) = 2.*summinab./(suma+sumb);
end

save(strcat(pardir,'pdice_lh.mat'),'pdice_lh','lh_chcp_pm','lh_hcp_pm','-v7.3');

%% calc mpm
% hcp
outfilename='hcp_mpm_N140';
h=1;
seed = label{h};
session1 = MRIread(strcat(WD,'/100408/100408_0.8mm_label_fsaverage_164k_',hemi{h},'.nii.gz'));
fs = session1.vol;
fs_size = length(fs);
mpm = zeros(1,fs_size);
for i=1:fs_size
    [sv,si] = max(lh_hcp_pm(:,i,1));
    if sv>0; mpm(i) = seed(si); end
end
session1.vol = mpm;
filename = strcat(pardir,outfilename,'_fsaverage_164k_',hemi{h},'.nii.gz');
MRIwrite(session1,filename);

% chcp
outfilename='chcp_mpm_N140';
h=1;
seed = label{h};
session1 = MRIread(strcat(WD,'/100408/100408_0.8mm_label_fsaverage_164k_',hemi{h},'.nii.gz'));
fs = session1.vol;
fs_size = length(fs);
mpm = zeros(1,fs_size);
for i=1:fs_size
    [sv,si] = max(lh_chcp_pm(:,i,1));
    if sv>0; mpm(i) = seed(si); end
end
session1.vol = mpm;
filename = strcat(pardir,outfilename,'_fsaverage_164k_',hemi{h},'.nii.gz');
MRIwrite(session1,filename);
