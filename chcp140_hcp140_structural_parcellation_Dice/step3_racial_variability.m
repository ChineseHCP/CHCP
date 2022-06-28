% % b = glmfit([intra],inter,'normal','link','identity')
% % regression code
%
% b = glmfit([intra],inter)
% c = sum(intra)*b(2)/210
% corrected_inter = inter-b(2)*intra+c;

clear all; clc;

pardir = '/md_disk4/meizhen/CHCP/hcp_indipar/samplesize/github/chcp140_hcp140_pdice/';
load(strcat(pardir,'pdice_lh.mat'));
load(strcat(pardir,'pdice_rh.mat'));

pdice = zeros(210,1);
for i = 1:105
    pdice(i*2-1) = pdice_lh(i);
    pdice(i*2) = pdice_rh(i);
end

% % 1. racial variability = invert pdice
normalized_pdice = pdice./max(pdice);
va = 1-normalized_pdice+0.001; % variability
va = va./max(va); % normalization of variability [0,1]

% % 2. corrected racial variability = regression size from pdice and then inverted
size_hcp = zeros(210,1);
size_chcp = zeros(210,1);
for i = 1:105
    size_chcp(i*2-1) = sum(lh_chcp_pm(i,:));
    size_hcp(i*2-1) = sum(lh_hcp_pm(i,:));
    size_chcp(i*2) = sum(rh_chcp_pm(i,:));
    size_hcp(i*2) = sum(rh_hcp_pm(i,:));
end
save(strcat(pardir,'size.mat'),'size_hcp','size_chcp');

size = (size_chcp+size_hcp)./2;
b = glmfit([size],pdice);% regression size from pdice
c = sum(size)*b(2)/210;
normalized_pdice = pdice-b(2)*size+c;
normalized_pdice = normalized_pdice./max(normalized_pdice);
cva = 1-normalized_pdice; % invert
cva = cva./max(cva); % normalization to [0,1]
save(strcat(pardir,'corrected_pdice_and_invert.mat'),'corrected_pdice','cva','va');

