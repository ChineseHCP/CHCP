function [output] = volumethreshold(input, thresh, str)

% VOLUMETHRESHOLD is a helper function for segmentations. It applies a
% relative threshold and subsequently looks for the largest connected part,
% thereby removing small blobs such as vitamine E capsules.
%
% See also VOLUMEFILLHOLES, VOLUMESMOOTH

% check for any version of SPM
if ~ft_hastoolbox('spm')
  % add SPM8 to the path
  ft_hastoolbox('spm8', 1);
end

% mask by taking the negative of the segmentation, thus ensuring
% that no holes are within the compartment and do a two-pass
% approach to eliminate potential vitamin E capsules etc.

if ~islogical(input)
  fprintf('thresholding %s at a relative threshold of %0.3f\n', str, thresh);
  output   = double(input>(thresh*max(input(:))));
else
  % there is no reason to apply a threshold, but spm_bwlabel still needs a double input
  output = double(input);
end

[tmp, N] = spm_bwlabel(output, 6);
for k = 1:N
  n(k,1) = sum(tmp(:)==k);
end
output   = double(tmp~=find(n==max(n))); clear tmp;
[tmp, N] = spm_bwlabel(output, 6);
for k = 1:N
  m(k,1) = sum(tmp(:)==k);
end
% select the tissue that has the most voxels belonging to it
output = (tmp~=find(m==max(m)));