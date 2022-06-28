function [dipout] = residualvariance(dip, grad, vol, dat, varargin);

% RESIDUALVARIANCE scan with a single dipole and computes the RV
% at each grid location.
% 
% Use as 
%   [dipout] = residualvariance(dip, grad, vol, dat, ...)

% Copyright (C) 2004-2006, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: residualvariance.m 7123 2012-12-06 21:21:38Z roboos $

% get the optional settings, or use default value
feedback      = keyval('feedback',      varargin); if isempty(feedback),      feedback = 'text';            end

% ensure that these are row-vectors
dip.inside = dip.inside(:)';
dip.outside = dip.outside(:)';

Nchan = length(grad.label);
Ndip  = length(dip.inside);

if isfield(dip, 'subspace')
  % remember the original data prior to the voxel dependant subspace projection
  dat_pre_subspace = dat;
  fprintf('using subspace projection\n');
end

ft_progress('init', feedback, 'computing inverse');
for i=1:length(dip.inside)

  ft_progress(i/length(dip.inside), 'computing inverse %d/%d\n', i, length(dip.inside));
  i = dip.inside(i);
  
  if isfield(dip, 'leadfield')
    % reuse the leadfield that was previously computed
    lf = dip.leadfield{i};
  else
    % compute the leadfield
    lf = ft_compute_leadfield(dip.pos(i,:), grad, vol);
  end

  if isfield(dip, 'subspace')
    % do subspace projection of the forward model
    lf = dip.subspace{i} * lf;
    % the data and the covariance become voxel dependent due to the projection
    dat = dip.subspace{i} * dat_pre_subspace;
  end
  
  % compute spatiotemporal inverse using regional source
  lfi    = pinv(lf);
  mom{i} = lfi * dat;
  rv(i)  = sum(sum((dat - lf*mom{i}).^2, 1), 2)./sum(sum(dat.^2, 1), 2);

  % for plotting convenience also compute power at each location
  % FIXME is this normalization correct?
  pow(i) = mean(sum(mom{i}(:).^2, 1));
end
ft_progress('close');

% locations outside the head get assigned an 
for i=dip.outside
  mom{i} = [];
  rv(i)  = nan;
  pow(i) = nan;
end

% assign the output data
dipout.mom = mom(:);  % ensure that it is a column vector
dipout.rv  = rv(:);   % ensure that it is a column vector
dipout.pow = pow(:);  % ensure that it is a column vector

% add other descriptive information to the output source model
dipout.pos     = dip.pos;
dipout.inside  = dip.inside;
dipout.outside = dip.outside;
