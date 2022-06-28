function Y = spm_eeg_img2timecourse(xyz)
% Extract time course from scalp x time image
% FORMAT Y = spm_eeg_img2timecourse(xyz)
%
% Input:
%   xyz - N x 2 matrix of coordinates in mm
%__________________________________________________________________________
% Copyright (C) 2012 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_eeg_img2timecourse.m 4850 2012-08-18 16:14:33Z vladimir $

fname = spm_select(1, 'image', 'Select image');
vol = nifti(fname);
%%
if nargin == 0
 xyz = spm_input('Enter scalp coordinates (N x 2)', '+1', 'r', '', [Inf, 2]);
end

if size(xyz, 2) == 2
    xyz(end, end+1) = 0;
end

xyz = inv(vol.mat)*[xyz';ones(1,size(xyz, 1))];

ij = round(xyz(1:2, :))';

Y = zeros(size(ij, 1), size(vol.dat, 3));
for i = 1:size(ij, 1)
    Y(i, :) = squeeze(vol.dat(ij(1), ij(2), :));
end
