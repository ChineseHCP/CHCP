%calculate the test-retest reliability.
clc;
clear;
HCP_list='/md_disk3/guoyuan/HCP_group_activation/test_retest_reliability/a_bash/HCP.txt';
CHCP_list='/md_disk3/guoyuan/HCP_group_activation/test_retest_reliability/a_bash/CHCP.txt';

HCP_path='/md_disk3/guoyuan/HCP_group_activation/test_retest_reliability/smooth/HCP';
CHCP_path='/md_disk3/guoyuan/HCP_group_activation/test_retest_reliability/smooth/CHCP';

HCP_num=textread(HCP_list,'%s');
CHCP_num=textread(CHCP_list,'%s');

data_matrix=[];
phase_encode={'AP','PA'};
task_name={'Emotion','Gambling','Language','Relation','Social','Nback'};
cope_num=12;                 % Change the cope number for each task.

for task=1:length(task_name)
        for j=1:length(phase_encode)
            for cope=1:cope_num
                i_corr=0;
                for i=1:length(CHCP_num)
                    sub_i_phase_j_cope_task=fullfile(CHCP_path,['rfMRI_',cell2mat(task_name(task)),'_',cell2mat(phase_encode(j))],'GrayordinatesStats',cell2mat(CHCP_num(i)),['cope',num2str(cope),'.nii.gz']);
                    if exist(sub_i_phase_j_cope_task,'file')  
                        sub_struc=MRIread(sub_i_phase_j_cope_task);
                        sub_matrix=sub_struc.vol;
                        [x,y]=size(sub_matrix);
                        z=x*y;
                        sub_matrix1=reshape(sub_matrix,1,z);
                        for k=1:z
                        data_matrix(i-i_corr,j,k,cope,task)=sub_matrix1(k);
                        end
                    else
                        i_corr=i_corr+1;
                    end
                end
            end
        end
end

for task=1:length(task_name)
    for cope=1:cope_num  
        ICC_map=[];
        for k=1:z
            vertex_retest=data_matrix(:,:,k,cope,task);
            %vertex_retest=data_matrix(:,:,k);
            [ICC_vertex,ICC_sigma]=ICC(1,'single',vertex_retest);
            ICC_map(k)=ICC_vertex;
        end
        ICC_map1=reshape(ICC_map,x,y);
        sub_struc.vol=ICC_map1;
        ICC_filepath=fullfile('/md_disk3/HCP_group_activation/test_retest_reliability/result/smooth/CHCP/Cope_map',cell2mat(task_name(task)));
        if ~exist(ICC_filepath,'dir')
            mkdir(ICC_filepath);
        end
        ICC_filename=fullfile(ICC_filepath,['ICC_cope',num2str(cope),'.nii.gz']);
        MRIwrite(sub_struc,ICC_filename);
    end
end

        
              
