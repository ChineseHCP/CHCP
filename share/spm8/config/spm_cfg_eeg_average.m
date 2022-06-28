function S = spm_cfg_eeg_average
% configuration file for M/EEG epoching
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Stefan Kiebel
% $Id: spm_cfg_eeg_average.m 3881 2010-05-07 21:02:57Z vladimir $

rev = '$Rev: 3881 $';
D = cfg_files;
D.tag = 'D';
D.name = 'File Name';
D.filter = 'mat';
D.num = [1 1];
D.help = {'Select the M/EEG mat file.'};

standard = cfg_const;
standard.tag = 'standard';
standard.name = 'Standard';
standard.val  = {false};

ks = cfg_entry;
ks.tag = 'ks';
ks.name = 'Offset of the weighting function';
ks.strtype = 'r';
ks.val = {3};
ks.num = [1 1];
ks.help = {'Parameter determining the how far the values should be from the median, '...
    'to be considered outliers (the larger, the farther).'};

bycondition = cfg_menu;
bycondition.tag = 'bycondition';
bycondition.name = 'Compute weights by condition';
bycondition.help = {'Compute weights for each condition separately or for all conditions together.'};
bycondition.labels = {'Yes', 'No'};
bycondition.values = {true, false};
bycondition.val = {true};

savew = cfg_menu;
savew.tag = 'savew';
savew.name = 'Save weights';
savew.help = {'Save weights in a separate dataset for quality control.'};
savew.labels = {'Yes', 'No'};
savew.values = {true, false};
savew.val = {true};

robust = cfg_branch;
robust.tag = 'robust';
robust.name = 'Robust';
robust.val = {ks, bycondition, savew};

userobust = cfg_choice;
userobust.tag = 'userobust';
userobust.name = 'Averaging type';
userobust.help = {'choose between using standard and robust averaging'};
userobust.values = {standard, robust};
userobust.val = {standard};

plv = cfg_menu;
plv.tag = 'plv';
plv.name = 'Compute phase-locking value';
plv.help = {'Compute phase-locking value rather than average the phase',...
    'This option is only relevant for TF-phase datasets'};
plv.labels = {'Yes', 'No'};
plv.values = {true, false};
plv.val = {false};

S = cfg_exbranch;
S.tag = 'average';
S.name = 'M/EEG Averaging';
S.val = {D, userobust, plv};
S.help = {'Average epoched EEG/MEG data.'};
S.prog = @eeg_average;
S.vout = @vout_eeg_average;
S.modality = {'EEG'};

function out = eeg_average(job)
% construct the S struct
S.D = job.D{1};
if isfield(job.userobust, 'robust')
    S.robust = job.userobust.robust;
else
    S.robust = false;
end
S.review = false;

S.circularise = job.plv;

out.D = spm_eeg_average(S);
out.Dfname = {fullfile(out.D.path, out.D.fname)};

function dep = vout_eeg_average(job)
% Output is always in field "D", no matter how job is structured
dep = cfg_dep;
dep.sname = 'Average Data';
% reference field "D" from output
dep.src_output = substruct('.','D');
% this can be entered into any evaluated input
dep.tgt_spec   = cfg_findspec({{'strtype','e'}});

dep(2) = cfg_dep;
dep(2).sname = 'Averaged Datafile';
% reference field "Dfname" from output
dep(2).src_output = substruct('.','Dfname');
% this can be entered into any file selector
dep(2).tgt_spec   = cfg_findspec({{'filter','mat'}});


