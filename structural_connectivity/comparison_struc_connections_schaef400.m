% Comparison between CHCP and HCP in structural connections
% in modules level.
clc;
clear;

HCP_list='/md_disk3/guoyuan/HCP_structure_fucntion/SC_script/exist_file/exist_txt/HCP.txt';
CHCP_list='/md_disk3/guoyuan/CHCP_structure_function/SC_script/file_list/CHCP_diffusion_bedpostx.txt';

HCP_num=textread(HCP_list,'%s');
CHCP_num=textread(CHCP_list,'%s');

HCP_num_exist=[];
for i=1:length(HCP_num)
    HCP_sub=char(HCP_num(i));
    SC_csv=['/md_disk3/guoyuan/HCP_structure_fucntion/SC/DTI/',HCP_sub,'/results/Network/Probabilistic/Customized_matrix_prob_thr75.mat'];
    if exist(SC_csv,'file')
        HCP_num_exist(end+1)=str2num(cell2mat(HCP_num(i)));
    end
end
HCP_total=length(HCP_num_exist);
HCP_matrix_all=zeros(400,400,HCP_total);
for i=1:length(HCP_num_exist)
    HCP_sub=num2str(HCP_num_exist(i));
    SC_csv=['/md_disk3/guoyuan/HCP_structure_fucntion/SC/DTI/',HCP_sub,'/results/Network/Probabilistic/Customized_matrix_prob_thr75.mat'];
    SC_ind=load(SC_csv);
    HCP_matrix_all(:,:,i)=SC_ind.SC_mat_thr;
end
HCP_mean=mean(HCP_matrix_all,3);

CHCP_num_exist=[];
for i=1:length(CHCP_num)
    CHCP_sub=char(CHCP_num(i));
    SC_csv=['/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/',CHCP_sub,'/results/Network/Probabilistic/Customized_matrix_prob_thr75.mat'];
    if exist(SC_csv,'file')
        CHCP_num_exist(end+1)=str2num(cell2mat(CHCP_num(i)));
    end
end
CHCP_total=length(CHCP_num_exist);
CHCP_matrix_all=zeros(400,400,CHCP_total);
for i=1:length(CHCP_num_exist)
    CHCP_sub=num2str(CHCP_num_exist(i),'%03d');
    SC_csv=['/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/',CHCP_sub,'/results/Network/Probabilistic/Customized_matrix_prob_thr75.mat'];
    SC_ind=load(SC_csv);
    CHCP_matrix_all(:,:,i)=SC_ind.SC_mat_thr;
end
CHCP_mean=mean(CHCP_matrix_all,3);

    
p=0.10;
% HCP
[x,y,z]=size(HCP_matrix_all);
HCP_matrix_threshold=zeros(x,y,z);
for i=1:z
    sub_i=HCP_matrix_all(:,:,i);
    sub_i(1:x+1:end)=0;
    if isequal(sub_i,sub_i.')
        sub_i=triu(sub_i);
        ud=2;
    else
        ud=1;
    end
    ind=find(sub_i);
    E=sortrows([ind sub_i(ind)],-2);
    en=round((x^2-x)*p/ud);
    sub_i(E(en+1:end,1))=0; 
    if ud==2
        sub_i=sub_i+sub_i.';
    end
    HCP_matrix_threshold(:,:,i)=sub_i;
end
clear x y z i ud sub_i ind en E;
% CHCP
[x,y,z]=size(CHCP_matrix_all);
CHCP_matrix_threshold=zeros(x,y,z);
for i=1:z
    sub_i=CHCP_matrix_all(:,:,i);
    sub_i(1:x+1:end)=0;
    if isequal(sub_i,sub_i.')
        sub_i=triu(sub_i);
        ud=2;
    else
        ud=1;
    end
    ind=find(sub_i);
    E=sortrows([ind sub_i(ind)],-2);
    en=round((x^2-x)*p/ud);
    sub_i(E(en+1:end,1))=0; 
    if ud==2
        sub_i=sub_i+sub_i.';
    end
    CHCP_matrix_threshold(:,:,i)=sub_i;
end



% Calculate the ttest p-values
p_values=zeros(400,400);
for i=1:400
    for j=1:400
        [~,p_values(i,j),~]=ttest2(HCP_matrix_threshold(i,j,:),CHCP_matrix_threshold(i,j,:));
    end
end

p_values=triu(p_values);
ind=find(p_values);
p_values_series=p_values(ind);
[~,~,p_values_adj]=fdr(p_values_series);
p_values_adj_matrix=zeros(400,400);
p_values_adj_matrix(ind)=p_values_adj;
p_values_adj_matrix=p_values_adj_matrix.';

CHCP_matrix_mean=mean(CHCP_matrix_all,3);
HCP_matrix_mean=mean(HCP_matrix_all,3);
HCP_CHCP=HCP_matrix_mean-CHCP_matrix_mean;

figure_all=cat(3,p_values_adj_matrix,CHCP_matrix_mean,HCP_matrix_mean,HCP_CHCP);

    fig=imagesc(p_values_adj_matrix, [-0.8,0.8]);

