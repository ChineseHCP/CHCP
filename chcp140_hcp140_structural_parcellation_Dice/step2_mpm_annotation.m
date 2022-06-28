clear all; clc;

pardir = '/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/chcp140_hcp140_pdice/';

% % rh
[v, l, ct] = read_annotation(['/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/label/rh.BN_Atlas.annot']); % l is important
t = 0;
bnamask = zeros(163842,1);
for i = 2:2:210
    for j = 1:163842
        if l(j)==ct.table(i+1,5)
            bnamask(j) = 1;
            t = t+1;
        end
    end
end
bnamask0 = zeros(163842,1);
for i = 1
    for j = 1:163842
        if l(j)==ct.table(i,5)
            bnamask0(j) = 1;
        end
    end
end

chcpmpm = MRIread(strcat(pardir,'chcp_mpm_N140_fsaverage_164k_rh.nii.gz'));
chcp = chcpmpm.vol;
newchcp = chcp.*bnamask';
chcpmpm.vol = newchcp;
MRIwrite(chcpmpm,strcat(pardir,'chcp_mpm_N140_fsaverage_164k_rh.nii.gz'));

hcpmpm = MRIread(strcat(pardir,'hcp_mpm_N140_fsaverage_164k_rh.nii.gz'));
hcp = hcpmpm.vol;
newhcp = hcp.*bnamask';
hcpmpm.vol = newhcp;
MRIwrite(hcpmpm,strcat(pardir,'hcp_mpm_N140_fsaverage_164k_rh.nii.gz'));

% annotation file
chcpl = l;
hcpl = l;
chcpl(:) = 0;
hcpl(:) = 0;
for i = 1:210
    for j = 1:163842
        if newchcp(j)==i
            chcpl(j) = ct.table(i+1,5);
        end
        if newhcp(j)==i
            hcpl(j) = ct.table(i+1,5);
        end
    end
end
for j = 1:163842
    if bnamask0(j)==1
        chcpl(j) = ct.table(1,5);
        hcpl(j) = ct.table(1,5);
    end
end

filename = strcat(pardir,'chcp_mpm_N140_fsaverage_164k_rh.annot');
write_annotation(filename,v,chcpl,ct);
filename = strcat(pardir,'hcp_mpm_N140_fsaverage_164k_rh.annot');
write_annotation(filename,v,hcpl,ct);

% % lh
[v, l, ct] = read_annotation(['/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/label/lh.BN_Atlas.annot']); % l is important
t = 0;
bnamask = zeros(163842,1);
for i = 1:2:209
    for j = 1:163842
        if l(j)==ct.table(i+1,5)
            bnamask(j) = 1;
            t = t+1;
        end
    end
end
bnamask0 = zeros(163842,1);
for i = 1
    for j = 1:163842
        if l(j)==ct.table(i,5)
            bnamask0(j) = 1;
        end
    end
end

chcpmpm = MRIread(strcat(pardir,'chcp_mpm_N140_fsaverage_164k_lh.nii.gz'));
chcp = chcpmpm.vol;
newchcp = chcp.*bnamask';
chcpmpm.vol = newchcp;
MRIwrite(chcpmpm,strcat(pardir,'chcp_mpm_N140_fsaverage_164k_lh.nii.gz'));

hcpmpm = MRIread(strcat(pardir,'hcp_mpm_N140_fsaverage_164k_lh.nii.gz'));
hcp = hcpmpm.vol;
newhcp = hcp.*bnamask';
hcpmpm.vol = newhcp;
MRIwrite(hcpmpm,strcat(pardir,'hcp_mpm_N140_fsaverage_164k_lh.nii.gz'));

% annotation file
chcpl = l;
hcpl = l;
chcpl(:) = 0;
hcpl(:) = 0;
for i = 1:210
    for j = 1:163842
        if newchcp(j)==i
            chcpl(j) = ct.table(i+1,5);
        end
        if newhcp(j)==i
            hcpl(j) = ct.table(i+1,5);
        end
    end
end
for j = 1:163842
    if bnamask0(j)==1
        chcpl(j) = ct.table(1,5);
        hcpl(j) = ct.table(1,5);
    end
end
filename = strcat(pardir,'chcp_mpm_N140_fsaverage_164k_lh.annot');
write_annotation(filename,v,chcpl,ct);
filename = strcat(pardir,'hcp_mpm_N140_fsaverage_164k_lh.annot');
write_annotation(filename,v,hcpl,ct);

% .annot file can be visualized by tksurfer
