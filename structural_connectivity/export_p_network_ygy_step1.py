#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Mon May 14 23:55:56 2020

"""

import os
import subprocess
import argparse
import shutil
import pandas as pd
import numpy as np
import nibabel as nib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def prepare_rois(parcellation_file, label_number, network_dir):
    parcellation_mask_file = os.path.join(os.path.dirname(parcellation_file),
                                          'mask_roi_multi_ribbon_' + os.path.basename(parcellation_file))
    parcellation_mask_file_ribbon = os.path.join(os.path.dirname(parcellation_file),
                                          'mask_ribbon_' + os.path.basename(parcellation_file))
    parcellation_file1 = os.path.join(os.path.dirname(parcellation_file),
                                          'roi_multi_ribbon_' + os.path.basename(parcellation_file))
    print(parcellation_mask_file_ribbon)
    subprocess.call(['fslmaths', parcellation_file,
                     '-mul', parcellation_mask_file_ribbon, parcellation_file1])
    subprocess.call(['fslmaths', parcellation_file1,
                     '-bin', parcellation_mask_file])
    if not os.path.exists(network_dir):
        os.makedirs(network_dir)
    with open(os.path.join(network_dir, 'Seed2Target.txt'), 'w') as f:
        for i in range(1, label_number+1):
            label_output_dir = os.path.join(
                network_dir, 'Label{:03.0f}_OPDtrackNET'.format(i))
            if not os.path.exists(label_output_dir):
                os.makedirs(label_output_dir)
            label_seed_file = os.path.join(
                label_output_dir, 'Label{:03.0f}_SeedMask.nii.gz'.format(i))
            label_term_file = os.path.join(
                label_output_dir, 'Label{:03.0f}_TermMask.nii.gz'.format(i))
            subprocess.call(['fslmaths', parcellation_file1,
                             '-thr', str(i), '-uthr', str(i), '-div', str(i),
                             label_seed_file])
            subprocess.call(['fslmaths', parcellation_mask_file,
                             '-sub', label_seed_file,
                             label_term_file])
            f.write(label_seed_file)
            f.write('\n')


def track_from_rois(label_number, network_dir, bedpostx_dir):
    for i in range(1, label_number + 1):
        label_output_dir = os.path.join(network_dir,
                                        'Label{:03.0f}_OPDtrackNET'.format(i))
        label_seed_file = os.path.join(label_output_dir,
                                       'Label{:03.0f}_SeedMask.nii.gz'.format(i))
        label_term_file = os.path.join(label_output_dir,
                                       'Label{:03.0f}_TermMask.nii.gz'.format(i))
        subprocess.call(['probtrackx2_gpu',
                         '-l',
                         '-c', '0.2',
                         '-S', '1000',
                         '--steplength=0.5',
                         '-P', '5000',
                         '--stop={}'.format(label_term_file),
                         '-x', label_seed_file,
                         '--forcedir',
                         '--opd',
                         '--s2tastext',
                         '--targetmasks={}'.format(os.path.join(network_dir,
                                                                'Seed2Target.txt')),
                         '-s', os.path.join(bedpostx_dir, 'merged'),
                         '-m', os.path.join(bedpostx_dir, 'nodif_brain_mask'),
                         '--dir={}'.format(label_output_dir),
                         '-o', 'fdt_paths'])      


def build_matrix(labelFile, networkPath, outputFile):
    label = []
    label_name = []
    with open(labelFile, 'rU') as f:
        for line in f:
            line = line.strip('\n').split(None, 1)
            line1=line[1]
            line1 = line1.strip('\n').split(None, 1)
            if line:
                label.append(line[1])
                label_name.append(line1[0])
    labelNumber = len(label)
    labelSeedFiles = [os.path.join(networkPath,
                                   "Label{:03.0f}_OPDtrackNET".format(l),
                                   "Label{:03.0f}_SeedMask.nii.gz".format(l))
                      for l in range(1, labelNumber+1)]
    labelFDTFiles = [os.path.join(networkPath,
                                  "Label{:03.0f}_OPDtrackNET".format(l),
                                  "fdt_paths.nii.gz")
                     for l in range(1, labelNumber+1)]
    matrixSeedVoxel = np.zeros([labelNumber, labelNumber])
    matrixTargetVoxel = np.zeros([labelNumber, labelNumber])
    matrixTargetMeanFDT = np.zeros([labelNumber, labelNumber])
    for i in range(labelNumber):
        seedFile = labelSeedFiles[i]
        fdtFile = labelFDTFiles[i]
        seed_voxel_number = int(subprocess.check_output(' '.join([
            'fslstats', seedFile, '-V']), shell=True).split()[0])
        matrixSeedVoxel[i, :] = seed_voxel_number
        if seed_voxel_number > 0:
            for j in range(labelNumber):
                if i != j:
                    targetFile = labelSeedFiles[j]
                    r = subprocess.check_output(['fslstats', 
                                                fdtFile, 
                                                '-k', targetFile, 
                                                '-M', '-V'],
                                                stderr=open(os.devnull, 'w'))
                    matrixTargetMeanFDT[i, j] = float(r.split()[0])
                    matrixTargetVoxel[i, j] = float(r.split()[1])

    matrixFDT = matrixTargetVoxel * matrixTargetMeanFDT
    matrixProb = np.divide(matrixFDT, matrixSeedVoxel,
                           out=np.zeros_like(matrixFDT), where=matrixSeedVoxel != 0)
    matrixProb = matrixProb / 10000
    # matrixProb = matrixFDT / matrixSeedVoxel / 10000
    matrixProb = pd.DataFrame(matrixProb, index=label_name, columns=label_name)
    basename, prefix = os.path.split(outputFile)
    matrixProb.to_csv(os.path.join(basename, prefix + '.csv'))
    plot_matrix(matrixProb, 'Probability',
                os.path.join(basename, prefix + '.png'))


def plot_matrix(df, title, filename):
    fig = plt.figure()
    ax = fig.add_subplot(111)
    im = ax.imshow(df.values, cmap='plasma')
    plt.title(title)
    plt.xlabel('ROI Number')
    plt.ylabel('ROI Number')
    ax.figure.colorbar(im, ax=ax)
    plt.savefig(filename)


def generate_results(parcellation_file, parcellation_label_file, network_dir, bedpostx_dir, output_file):
    label_number = 0
    with open(parcellation_label_file, 'rU') as f:
        for l in f:
            if l.strip():
                label_number += 1

    prepare_rois(parcellation_file, label_number, network_dir)
    #track_from_rois(label_number, network_dir, bedpostx_dir)
    #build_matrix(parcellation_label_file, network_dir, output_file)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--parcellation_name', type=str, required=True)
    ap.add_argument('--parcellation_file', type=str, required=True)
    ap.add_argument('--parcellation_label_file', type=str, required=True)
    ap.add_argument('--network_dir', type=str, required=True)
    ap.add_argument('--bedpostx_dir', type=str, required=True)
    ap.add_argument('--output', type=str, required=True)

    args = ap.parse_args()
    generate_results(args.parcellation_file,
                     args.parcellation_label_file,
                     args.network_dir,
                     args.bedpostx_dir,
                     args.output)
