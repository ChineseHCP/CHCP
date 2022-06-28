#!/bin/bash
set -e
set -u

export PATH=$PATH:/md_disk3/guoyuan/CHCP_structure_function/SC_script/panda-p-network-gpu-3.0.0/script;
source $FSLDIR/etc/fslconf/fsl.sh;

sub_list=/md_disk3/guoyuan/CHCP_structure_function/SC_script/file_list/sub_list_others/CHCP_new4.txt;

for data_num in `cat ${sub_list}`
do 
{ 
data_name_path=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion/data.nii.gz;  
if  [ -f "${data_name_path}" ]  ; then
{
RUN_DIR=/md_disk3/guoyuan/CHCP_structure_function/SC_script/panda-p-network-gpu-3.0.0;
NATIVE_SPACE_DIR=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion;
BASE_DIR=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/results;
mkdir -p ${BASE_DIR};
DWI_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion/data.nii.gz；
BVAL_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion/bvals;
BVEC_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion/bvecs;
NODIF_BRAIN_MASK_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/Diffusion/nodif_brain_mask.nii.gz;

T1_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/T1w_acpc_dc_restore_brain_1.50.nii.gz;

CUSTOMIZED_FILE=/md_disk3/guoyuan/CHCP_structure_function/SC/atlas/MNI/Schaefer2018_400Parcels_7Networks_order_FSLMNI152_2mm.nii.gz;
CUSTOMIZED_LABEL=/md_disk3/guoyuan/CHCP_structure_function/SC/atlas/MNI/Schaefer2018_400Parcels_7Networks_order.txt;
BEDPOSTX_DIR=${NATIVE_SPACE_DIR}.bedpostX;

# Network Node Definition
# Job_Name60: Copy T1
T1_DIR=${BASE_DIR}/T1
mkdir -p ${T1_DIR}

T1_BRAIN=${T1_FILE};                        # native space brain

DIFF_BRAIN=${NATIVE_SPACE_DIR}/nodif_brain.nii.gz;

if  [ ! -f "${T1_DIR}/diff_2T1.nii.gz" ]  ; then
flirt -in ${DIFF_BRAIN} -ref ${T1_BRAIN} -omat ${T1_DIR}/diff_2T1.mat \
    -cost corratio -dof 12 -o ${T1_DIR}/diff_2T1.nii.gz
fi

if  [ ! -f "${T1_DIR}/T1_2diff.mat" ]  ; then
convert_xfm -omat ${T1_DIR}/T1_2diff.mat -inverse ${T1_DIR}/diff_2T1.mat
fi 

if  [ ! -f "${T1_DIR}/T1_2diff.nii.gz" ]  ; then
applywarp -i ${T1_BRAIN} -r ${DIFF_BRAIN} -o ${T1_DIR}/T1_2diff.nii.gz \
    --premat=${T1_DIR}/T1_2diff.mat
fi


# Job_Name65: T1 to standard space
T1_TEMPLATE=MNI152_T1_2mm_brain;
if [ "${T1_TEMPLATE}" = 'MNI152_T1_2mm_brain' ]; then
    TEMPLATE_BRAIN=${RUN_DIR}/resource/Templates/MNI152_T1_2mm_brain.nii.gz;
else
    echo "The T1 template ${T1_TEMPLATE} is invalid."
    exit 1
fi

if  [ ! -f "${T1_DIR}/T1_2MNI.nii.gz" ]  ; then
fsl_reg ${T1_BRAIN} ${TEMPLATE_BRAIN} ${T1_DIR}/T1_2MNI     # insteaded by blow two lines
fi

#T1_2MNI=/md_disk3/guoyuan/HCP_structure_function/SC/DTI/100206/MNINonLinear/T1w_restore_brain.nii.gz;
#cp ${T1_2MNI} ${T1_DIR}/T1_2MNI.nii.gz;


# Job_Name66: invwarp
if  [ ! -f "${T1_DIR}/T1_2MNI_warp_inv.nii.gz" ]  ; then
invwarp -w ${T1_DIR}/T1_2MNI_warp.nii.gz -r ${T1_BRAIN} -o ${T1_DIR}/T1_2MNI_warp_inv
fi

# Probabilistic Network
# Job_Name44: ProbabilisticNetworkpre
NETWORK_DIR=${BASE_DIR}/Network/Probabilistic
mkdir -p ${NETWORK_DIR}

ATLAS_LIST=('Customized')
for atlas in ${ATLAS_LIST[@]}; do
{
    echo "Building matrix based on ${atlas}"
    if [ "$atlas" = 'Schaefer2018_400Parcels_7Networks' ]; then
        parcellation_file=${RUN_DIR}/resource/atlases/AAL/AAL_Contract_116_2MM.nii.gz
        parcellation_label=${RUN_DIR}/resource/atlases/AAL/AAL_LabelID_116.txt
    elif [ "$atlas" = 'HOA_110_2mm' ]; then
        parcellation_file=${RUN_DIR}/resource/atlases/HOA/HOA_Contract_110_2MM.nii.gz
        parcellation_label=${RUN_DIR}/resource/atlases/HOA/HOA_labelID_110.txt
    elif [ "$atlas" = 'Customized' ]; then
        parcellation_file=${CUSTOMIZED_FILE}
        parcellation_label=${CUSTOMIZED_LABEL}
    else
        echo "Invalid parcellation: ${atlas}"
        exit 1
    fi
    if [ ! -f "${parcellation_file}" ] || [ ! -f "${parcellation_label}" ]; then
        echo "Atlas is missing."
        exit 1
    fi

    # Job_Name67: Individual Parcellated
    echo "Generating parcellated brain in diffusion image space..."
    individual_parcellation_file=${NETWORK_DIR}/${atlas}.nii.gz
    parcellation_mask_file=${NETWORK_DIR}/mask_ribbon_${atlas}.nii.gz;
    ribbon_file_native=/md_disk3/guoyuan/CHCP_structure_function/SC/DTI/${data_num}/T1w/${data_num}/mri/r_1.50mm_ribbon.nii;

    rm -rf ${parcellation_mask_file}
    if [ ! -f "${parcellation_mask_file}" ] ; then
         echo "ribbon exist = ${ribbon_file_native}";
         echo "mask exist = ${parcellation_mask_file}";
         cp -rf ${ribbon_file_native} ${parcellation_mask_file};
    fi


    if  [ ! -f "${individual_parcellation_file}" ]  ; then
    applywarp -i ${parcellation_file} -o ${individual_parcellation_file} \
        -r ${DIFF_BRAIN} -w ${T1_DIR}/T1_2MNI_warp_inv \
        --postmat=${T1_DIR}/T1_2diff.mat --interp=nn
    fi


    # ${RUN_DIR}/script/register.py --atlas $atlas



    echo "Calculating the connectivity matrix..."
    ${RUN_DIR}/script/export_p_network_ygy_step1.py \
                 --parcellation_name ${atlas} \
                 --parcellation_file ${individual_parcellation_file} \
                 --parcellation_label_file ${parcellation_label} \
                 --network_dir ${NETWORK_DIR}/${atlas} \
                 --bedpostx_dir ${BEDPOSTX_DIR} \
                 --output ${NETWORK_DIR}/${atlas}_matrix_prob
}
done
}
else
    echo "Data number = ${data_num} not exist!";
fi
} 
done
