#! /bin/bash
# generate probabilistic tractography for each voxel in ROI
# submit job:
# qsub -cwd -l vf=200G ROI_probtrackx.sh
# 2.5G resource for each sub

% Parallel computing mode with 30+ threads

SUB_LIST=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt;
WD=/md_disk4/meizhen/CHCP/hcp_indipar/add5/;
ROI=Cortex;
LorR=R;
DATA_DIR=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5; #directory of DTI file
BED=/md_disk6/guoyuan/HCP_preproc; #directory of bedpostx file
destdir=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/9_ROI_probtrackx/temp_sublist_hcp_add5_5_server10_${LorR}.txt;

cat ${SUB_LIST}|while read line
do
{
echo ${line};

for sub in ${line}
do
{
COORD_LIST=${WD}/${sub}/${sub}_${ROI}_${LorR}_coord/${sub}_${ROI}_${LorR}_coord_list.txt;
for coord in $(cat ${COORD_LIST})
do
{
output_dir=${WD}/${sub}/${sub}_${ROI}_${LorR}_probtrackx;
# 3_ROI_probtrackx, Number of samples, default 5000
N_SAMPLES=5000
# 3_ROI_probtrackx, distance correction, yes--(--pd), no--( )space
DIS_COR=--pd
# 3_ROI_probtrackx, the length of each step, default 0.5 mm
LEN_STEP=0.5
# 3_ROI_probtrackx, maximum number of steps, default 2000
N_STEPS=2000
# 3_ROI_probtrackx, curvature threshold (cosine of degree), default 0.2
CUR_THRES=0.2
# single voxel probtrackx
#echo ${WD}/${sub}/${sub}_${ROI}_${LorR}_coord/${coord};
${FSLDIR}/bin/probtrackx2 --simple --seedref=${WD}/100206/b0_brain -o ${sub}_${ROI}_${LorR} -x ${WD}/${sub}/${sub}_${ROI}_${LorR}_coord/${coord} -l ${DIS_COR} -c ${CUR_THRES} -S ${N_STEPS} --steplength=${LEN_STEP} -P ${N_SAMPLES} --forcedir --opd -s ${BED}/${sub}/T1w/Diffusion.bedpostX/merged -m ${BED}/${sub}/T1w/Diffusion.bedpostX/nodif_brain_mask --dir=$output_dir;
}&
done
wait
echo "${sub}" > "${destdir}"
}
done
}
done

#$ -V
#$ -cwd
#$ -j y
#$ -S /bin/bash

