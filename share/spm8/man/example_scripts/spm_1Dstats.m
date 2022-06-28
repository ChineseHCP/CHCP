% example script for converting 1D signals into nifti files which can then be used to
% run stats in SPM in the normal way
%__________________________________________________________________________
% Copyright (C) 2012 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak 
% $Id: spm_1Dstats.m 4727 2012-05-01 10:18:17Z vladimir $

for i = 1:20
    
    fname = ['test' num2str(i) '.nii'];
    
    data = randn(50, 1); % this is your data 
    time = linspace(-200, 300, 50); % this is the corresponding time axis (in ms)
    
    N     = nifti;
    dat   = file_array(fname, [length(data), 1], 'FLOAT64-LE');
    N.dat = dat;
    N.mat = [...
        diff(time(1:2))   0               0        time(1);...
        0                 1               0        0;...
        0                 0               1        0;...
        0                 0               0        1];
    N.mat(1,4) = N.mat(1,4) - N.mat(1,1);
    N.mat_intent = 'Aligned';
    create(N);
    
    N.dat(:, :) = data;
end
%%