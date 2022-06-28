#! /bin/bash
# generate probabilistic tractography for each voxel in ROI
# submit job:

# qsub -cwd -l vf=200G ROI_probtrackx.sh

# 2.5G resource for each sub

SUB_LIST=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5.txt;
WD=/md_disk4/meizhen/CHCP/hcp_indipar/add5/;
ROI=Cortex;
LorR=L;
DATA_DIR=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5/;
 for sub in $(cat ${SUB_LIST})
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
${FSLDIR}/bin/probtrackx2 --simple --seedref=${WD}/100206/b0_brain -o ${sub}_${ROI}_${LorR} -x ${WD}/${sub}/${sub}_${ROI}_${LorR}_coord.txt -l ${DIS_COR} -c ${CUR_THRES} -S ${N_STEPS} --steplength=${LEN_STEP} -P ${N_SAMPLES} --forcedir --opd -s ${DATA_DIR}/${sub}/Diffusion.bedpostX/merged -m ${DATA_DIR}/${sub}/Diffusion.bedpostX/nodif_brain_mask --dir=$output_dir;
}
done

#$ -V
#$ -cwd
#$ -j y
#$ -S /bin/bash

