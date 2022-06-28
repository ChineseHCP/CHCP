#! /usr/bin/bash
path=`pwd`
SUBJECTS_DIR=$path
Subject="100307"

### mapping BN_atlas cortex to subjects
mris_ca_label -l $SUBJECTS_DIR/$Subject/label/lh.cortex.label $Subject lh $SUBJECTS_DIR/$Subject/surf/lh.sphere.reg $SUBJECTS_DIR/lh.BN_Atlas.gcs $SUBJECTS_DIR/$Subject/label/lh.BN_Atlas.annot
mris_ca_label -l $SUBJECTS_DIR/$Subject/label/rh.cortex.label $Subject rh $SUBJECTS_DIR/$Subject/surf/rh.sphere.reg $SUBJECTS_DIR/rh.BN_Atlas.gcs $SUBJECTS_DIR/$Subject/label/rh.BN_Atlas.annot

### check the result in Freeview
freeview -f $SUBJECTS_DIR/$Subject/surf/lh.pial:annot=$SUBJECTS_DIR/$Subject/label/lh.BN_Atlas.annot
freeview -f $SUBJECTS_DIR/$Subject/surf/rh.pial:annot=$SUBJECTS_DIR/$Subject/label/rh.BN_Atlas.annot

### Parcellation Stats
mris_anatomical_stats -mgz -cortex $SUBJECTS_DIR/$Subject/label/lh.cortex.label -f $SUBJECTS_DIR/$Subject/stats/lh.BN_Atla.stats -b -a $SUBJECTS_DIR/$Subject/label/lh.BN_Atlas.annot -c $SUBJECTS_DIR/BN_Atlas_210_LUT.txt $Subject lh white 
aparcstats2table -s $Subject --hemi lh --parc BN_Atlas --meas thickness --tablefile ./$Subject/lh.thickness.txt

mris_anatomical_stats -mgz -cortex $SUBJECTS_DIR/$Subject/label/rh.cortex.label -f $SUBJECTS_DIR/$Subject/stats/rh.BN_Atlas.stats -b -a $SUBJECTS_DIR/$Subject/label/rh.BN_Atlas.annot -c $SUBJECTS_DIR/BN_Atlas_210_LUT.txt $Subject rh white
aparcstats2table -s $Subject --hemi rh --parc BN_Atlas --meas thickness --tablefile ./$Subject/rh.thickness.txt

### convert to CIFTI files
mkdir -p $Subject/Native
mris_convert --annot ./$Subject/label/lh.BN_Atlas.annot ./$Subject/surf/lh.white ./$Subject/Native/$Subject.L.BN_Atlas.native.label.gii
wb_command -set-structure ./$Subject/Native/$Subject.L.BN_Atlas.native.label.gii CORTEX_LEFT
mris_convert --annot ./$Subject/label/rh.BN_Atlas.annot ./$Subject/surf/rh.white ./$Subject/Native/$Subject.R.BN_Atlas.native.label.gii
wb_command -set-structure ./$Subject/Native/$Subject.R.BN_Atlas.native.label.gii CORTEX_RIGHT

mris_convert ./$Subject/surf/lh.white ./$Subject/Native/$Subject.L.white.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.L.white.native.surf.gii CORTEX_LEFT -surface-type ANATOMICAL -surface-secondary-type GRAY_WHITE
mris_convert ./$Subject/surf/rh.white ./$Subject/Native/$Subject.R.white.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.R.white.native.surf.gii CORTEX_RIGHT -surface-type ANATOMICAL -surface-secondary-type GRAY_WHITE

mris_convert ./$Subject/surf/lh.pial ./$Subject/Native/$Subject.L.pial.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.L.pial.native.surf.gii CORTEX_LEFT -surface-type ANATOMICAL -surface-secondary-type PIAL
mris_convert ./$Subject/surf/rh.pial ./$Subject/Native/$Subject.R.pial.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.R.pial.native.surf.gii CORTEX_RIGHT -surface-type ANATOMICAL -surface-secondary-type PIAL

wb_command -surface-average ./$Subject/Native/$Subject.L.midthickness.native.surf.gii -surf $Subject/Native/$Subject.L.white.native.surf.gii -surf ./$Subject/Native/$Subject.L.pial.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.L.midthickness.native.surf.gii CORTEX_LEFT -surface-type ANATOMICAL -surface-secondary-type MIDTHICKNESS

wb_command -surface-average ./$Subject/Native/$Subject.R.midthickness.native.surf.gii -surf $Subject/Native/$Subject.R.white.native.surf.gii -surf ./$Subject/Native/$Subject.R.pial.native.surf.gii
wb_command -set-structure ./$Subject/Native/$Subject.L.midthickness.native.surf.gii CORTEX_RIGHT -surface-type ANATOMICAL -surface-secondary-type MIDTHICKNESS

### generate Workbench spec file
cd $Subject/Native
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_LEFT ./$Subject.L.white.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_LEFT ./$Subject.L.pial.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_LEFT ./$Subject.L.midthickness.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_LEFT ./$Subject.L.BN_Atlas.native.label.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_RIGHT ./$Subject.R.white.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_RIGHT ./$Subject.R.pial.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_RIGHT ./$Subject.R.midthickness.native.surf.gii
wb_command -add-to-spec-file ./$Subject.native.wb.spec CORTEX_RIGHT ./$Subject.R.BN_Atlas.native.label.gii

### mapping BN_atlas subcortex to subjects 
mri_ca_label $SUBJECTS_DIR/$Subject/mri/brain.mgz $SUBJECTS_DIR/$Subject/mri/transforms/talairach.m3z $SUBJECTS_DIR/BN_Atlas_subcortex.gca $SUBJECTS_DIR/$Subject/mri/BN_Atlas_subcotex.mgz

### Segmentation stats
mri_segstats --seg $SUBJECTS_DIR/$Subject/mri/BN_Atlas_subcotex.mgz --ctab $SUBJECTS_DIR/BN_Atlas_246_LUT.txt --excludeid 0 --sum $SUBJECTS_DIR/$Subject/stats/BN_Atlas_subcotex.stats
