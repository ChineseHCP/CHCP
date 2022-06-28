% Comparison between CHCP and HCP in resting state functional connections
% in modules level.
clc;

clear;

HCP_connectivity='/md_disk3/guoyuan/HCP_structure_fucntion/FC/Results/FC_metric/REST1/Pearson_r_noMSM_REST1_all2all.mat';
CHCP_connectivity='/md_disk3/guoyuan/CHCP_structure_function/FC/Results/FC_metric/REST1/Pearson_r_without_msm_all2all.mat';

HCP_matrix=load(HCP_connectivity);
CHCP_matrix=load(CHCP_connectivity);
p=0.10;
% HCP
[x,y,z]=size(HCP_matrix.corr_mat);
HCP_matrix_threshold=zeros(x,y,z);
for i=1:z
    sub_i=HCP_matrix.corr_mat(:,:,i);
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
[x,y,z]=size(CHCP_matrix.corr_mat);
CHCP_matrix_threshold=zeros(x,y,z);
for i=1:z
    sub_i=CHCP_matrix.corr_mat(:,:,i);
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

HCP_matrix_threshold(HCP_matrix_threshold>0)=1;
CHCP_matrix_threshold(CHCP_matrix_threshold>0)=1;
HCP_matrix_mean=mean(HCP_matrix_threshold,3);
CHCP_matrix_mean=mean(CHCP_matrix_threshold,3);

CHCP_community_file='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/CHCP/convert_bash/atlas/atlas400/CHCP_7networks_modules.mat';
CHCP_community=load(CHCP_community_file);
CHCP_community_vector=CHCP_community.label_networks;
HCP_community_file='/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/HCP/convert_bash/atlas/atlas400/HCP_7networks_modules.mat';
HCP_community=load(HCP_community_file);
HCP_community_vector=HCP_community.label_networks;

% Group results.
% CHCP
networks={'Vis','Soma','dANT','vATN','Lim','FPN','DMN'};
CHCP_network_connections=zeros(7,7);
for j=1:length(networks)
        CHCP_community_j=CHCP_community_vector;
        CHCP_community_j(CHCP_community_vector~=j)=0;
        CHCP_community_j(CHCP_community_vector==j)=1;
        for i=1:length(networks)
            CHCP_community_i=CHCP_community_vector;
            CHCP_community_i(CHCP_community_vector~=i)=0;
            CHCP_community_i(CHCP_community_vector==i)=1;
            CHCP_community_ij=CHCP_community_j.*CHCP_community_i.';
            chcp_matrix_network_ij=sum(CHCP_matrix_mean.*CHCP_community_ij)/2;
            CHCP_network_connections(j,i)=chcp_matrix_network_ij;
        end
end

% HCP
HCP_network_connections=zeros(7,7);
for j=1:length(networks)
        HCP_community_j=HCP_community_vector;
        HCP_community_j(HCP_community_vector~=j)=0;
        HCP_community_j(HCP_community_vector==j)=1;
        for i=1:length(networks)
            HCP_community_i=HCP_community_vector;
            HCP_community_i(HCP_community_vector~=i)=0;
            HCP_community_i(HCP_community_vector==i)=1;
            HCP_community_ij=HCP_community_j.*HCP_community_i.';
            hcp_matrix_network_ij=sum(HCP_matrix_mean.*HCP_community_ij)/2;
            HCP_network_connections(j,i)=hcp_matrix_network_ij;
        end
end


% For individual t-map
[x,y,z]=size(CHCP_matrix_threshold);
networks={'Vis','Soma','dANT','vATN','Lim','FPN','DMN'};
CHCP_network_connections_ind=zeros(7,7,z);
for sub=1:z
    for j=1:length(networks)
        CHCP_community_j=CHCP_community_vector;
        CHCP_community_j(CHCP_community_vector~=j)=0;
        CHCP_community_j(CHCP_community_vector==j)=1;
        for i=1:length(networks)
            CHCP_community_i=CHCP_community_vector;
            CHCP_community_i(CHCP_community_vector~=i)=0;
            CHCP_community_i(CHCP_community_vector==i)=1;
            CHCP_community_ij=CHCP_community_j.*CHCP_community_i.';
            chcp_matrix_network_ij=sum(sum(CHCP_matrix_threshold(:,:,sub).*CHCP_community_ij))/2;
            CHCP_network_connections_ind(j,i,sub)=chcp_matrix_network_ij;
        end
    end
end

[x,y,z]=size(HCP_matrix_threshold);
networks={'Vis','Soma','dANT','vATN','Lim','FPN','DMN'};
HCP_network_connections_ind=zeros(7,7,z);
for sub=1:z
    for j=1:length(networks)
        HCP_community_j=HCP_community_vector;
        HCP_community_j(HCP_community_vector~=j)=0;
        HCP_community_j(HCP_community_vector==j)=1;
        for i=1:length(networks)
            HCP_community_i=HCP_community_vector;
            HCP_community_i(HCP_community_vector~=i)=0;
            HCP_community_i(HCP_community_vector==i)=1;
            HCP_community_ij=HCP_community_j.*HCP_community_i.';
            hcp_matrix_network_ij=sum(sum(HCP_matrix_threshold(:,:,sub).*HCP_community_ij))/2;
            HCP_network_connections_ind(j,i,sub)=hcp_matrix_network_ij;
        end
    end
end

% Calculate the ttest p-values
p_values=zeros(7,7);
for i=1:7
    for j=1:7
        [~,p_values(i,j),~]=ttest2(HCP_network_connections_ind(i,j,:),CHCP_network_connections_ind(i,j,:));
    end
end

HCP_networks_connections=mean(HCP_network_connections_ind,3);
HCP_networks_connections=triu(HCP_networks_connections);
HCP_networks_connections=HCP_networks_connections.';
CHCP_networks_connections=mean(CHCP_network_connections_ind,3);
CHCP_networks_connections=triu(CHCP_networks_connections);
CHCP_networks_connections=CHCP_networks_connections.';
p_values=triu(p_values);
ind=find(p_values);
p_values_series=p_values(ind);
[~,~,p_values_adj]=fdr(p_values_series);
p_values_adj_matrix=zeros(7,7);
p_values_adj_matrix(ind)=p_values_adj;
p_values_adj_matrix=p_values_adj_matrix.';


CHCP_networks_connections=log10(CHCP_networks_connections);
HCP_networks_connections=log10(HCP_networks_connections);
CHCP_networks_connections(CHCP_networks_connections<0)=0;
HCP_networks_connections(HCP_networks_connections<0)=0;
HCP_path='/md_disk3/guoyuan/a_bash/comparison_CHCP_HCP_atlas/connections_file/HCP_connections.xlsx';
CHCP_path='/md_disk3/guoyuan/a_bash/comparison_CHCP_HCP_atlas/connections_file/CHCP_connections.xlsx';
p_values_path='/md_disk3/guoyuan/a_bash/comparison_CHCP_HCP_atlas/connections_file/p_values.xlsx';
p_values_path1='/md_disk3/guoyuan/a_bash/comparison_CHCP_HCP_atlas/connections_file/p_values_pos_neg.xlsx';
HCP_CHCP=HCP_networks_connections-CHCP_networks_connections;
HCP_CHCP(HCP_CHCP>0)=1;
HCP_CHCP(HCP_CHCP<0)=-1;
p_values_adj_matrix_pos_neg=p_values_adj_matrix.*HCP_CHCP;

xlswrite(HCP_path,HCP_networks_connections);
xlswrite(CHCP_path,CHCP_networks_connections);
xlswrite(p_values_path,p_values_adj_matrix);
xlswrite(p_values_path1,p_values_adj_matrix_pos_neg);


