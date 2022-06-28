SUB_LIST=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5_5.txt;
guoyuan=/md_disk6/guoyuan/HCP_preproc;
data=/md_disk1/hcp;
DTI=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5;

for sub in `cat ${SUB_LIST}`
do
{
mkdir $DTI/$sub;

zip=$data/$sub/preproc/${sub}_3T_Diffusion_preproc.zip;
file=$sub/T1w/Diffusion/nodif_brain_mask.nii.gz;
dest=$DTI;
unzip -o $zip $file -d $dest

zip=$data/$sub/preproc/${sub}_3T_Diffusion_preproc.zip;
file=$sub/T1w/Diffusion/data.nii.gz;
dest=$DTI;
unzip -o $zip $file -d $dest

zip=$data/$sub/preproc/${sub}_3T_Structural_preproc.zip;
file=$sub/T1w/aparc+aseg.nii.gz;
dest=$DTI;
unzip -o $zip $file -d $dest

zip=$data/$sub/preproc/${sub}_3T_Structural_preproc_extended.zip;
dest=$DTI/$sub/T1w;
unzip $zip -d $dest

cp -r $guoyuan/$sub/T1w/T1w_acpc_dc_restore_brain.nii.gz $DTI/$sub/T1_brain.nii.gz;
#cp -r $data/$sub/T1w/Diffusion.bedpostX $DTI/$sub;

echo $sub;
}
done


DATA=/md_disk4/meizhen/CHCP/hcp_indipar/add5;
DTI=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5;
SUB_LIST=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist/sublist_hcp_add5_5.txt;

for sub_num in `cat ${SUB_LIST}`
do
{
sub_path=$DTI/$sub_num/T1w/Diffusion;
cd $sub_path;
fslroi data.nii.gz nodif1 0 1 
fslroi data.nii.gz nodif2 16 1
fslroi data.nii.gz nodif3 32 1 
fslroi data.nii.gz nodif4 48 1
fslroi data.nii.gz nodif5 64 1 
fslroi data.nii.gz nodif6 80 1
fslmerge -t nodif nodif1.nii.gz nodif2.nii.gz nodif3.nii.gz nodif4.nii.gz nodif5.nii.gz nodif6.nii.gz
fslmaths nodif -Tmean nodif_mean
fslmaths nodif_mean -mul nodif_brain_mask.nii.gz nodif_brain
echo $sub_num;
}
done

DATA=/md_disk4/meizhen/CHCP/hcp_indipar/add5;
DTI=/md_disk4/meizhen/CHCP/hcp_dti/hcp_add5;
SUB_LIST=/md_disk4/meizhen/CHCP/hcp_indipar/add5/a_code/sublist_hcp_add5.txt;

for sub in `cat ${SUB_LIST}`
do
{
mkdir $DATA/$sub;
mkdir $DATA/$sub/${sub}_indipar_mask;
gunzip $DTI/$sub/T1w/Diffusion/nodif_brain.nii.gz;
gunzip $DTI/$sub/T1_brain.nii.gz;
cp $DTI/$sub/T1w/Diffusion/nodif_brain.nii $DATA/$sub/b0_brain.nii;
cp $DTI/$sub/T1w/aparc+aseg.nii.gz $DATA/$sub/${sub}_indipar_mask;
gunzip $DATA/$sub/${sub}_indipar_mask/aparc+aseg.nii.gz;
echo $sub;
}
done

