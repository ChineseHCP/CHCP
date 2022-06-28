#!/usr/bin/env python

"""
Created on Tue March 23 12:30:54 2019

@author: Guoyuan Yang
"""

# script for calculating average of gifti sulcal depth maps

import numpy as np
import sys
from sys import argv
# sys.path.append('/disk2/guoyuan/software/conde/install_path/anaconda2/lib/python2.7/site-packages/nibabel'
import nibabel as nib
import nibabel.gifti as nibgif
import os
import copy
import csv
hemi = "R"
temp_name_chcp="/md_disk4/guoyuan/Indvidual_atlas/CHCP/post_preproc_smooth4_140/generate_profiles_and_ini_params/group/group_140_session2_" + str(hemi) + "H_clusters7.label.gii"
temp_name_hcp="/md_disk4/guoyuan/Indvidual_atlas/HCP/post_preproc_smooth4_140/generate_profiles_and_ini_params/group/group_140_session1_" + str(hemi) + "H_clusters7.label.gii"

temp_file_chcp=nibgif.giftiio.read(temp_name_chcp)
temp_data_chcp=temp_file_chcp.darrays[0].data
temp_file_hcp=nibgif.giftiio.read(temp_name_hcp)
temp_data_hcp=temp_file_hcp.darrays[0].data

txt_path="/md_disk3/guoyuan/HCP_CHCP_atlas_comparison/Yeo7_atlas/Dice_coeff/"
#os.mkdir(txt_path)
txt_name=str(txt_path)  + "HCP_CHCP_dice_7network_new_" + str(hemi) + ".txt"
f_open = open(txt_name,'a+')
for i in range(1,7+1):
        temp_data1=copy.deepcopy(temp_data_chcp)
        sub_data1=copy.deepcopy(temp_data_hcp)
        temp_data1[temp_data1!=i]=0
        temp_data1[temp_data1==i]=1
        sub_data1[sub_data1!=i]=0
        sub_data1[sub_data1==i]=1
        sub_data1=np.float32(sub_data1)
        temp_data1=np.float32(temp_data1)
        sum_data=sub_data1+temp_data1
        sum_data[sum_data!=2]=0
        dice=np.sum(sum_data)/(np.sum(temp_data1)+np.sum(sub_data1)+1)
        f_open.write(str(dice)+"\t")
        print(dice)
f_open.write("\n")
        
    
    
        



