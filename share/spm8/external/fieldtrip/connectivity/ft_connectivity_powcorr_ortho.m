function [c] = ft_connectivity_amplcorr_ortho(mom, varargin)

% FIXME build in proper documentation

% Copyright (C) 2012 Jan-Mathijs Schoffelen
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
% $Id: ft_connectivity_powcorr_ortho.m 7123 2012-12-06 21:21:38Z roboos $

refindx = ft_getopt(varargin, 'refindx', 'all');
tapvec  = ft_getopt(varargin, 'tapvec',  ones(1,size(mom,2)));

if strcmp(refindx, 'all')
  refindx = 1:size(mom,1);
end

cmomnorm = conj(mom./abs(mom)); % only need to do conj() once

n        = size(mom,1);
ntap     = tapvec(1);
if ~all(tapvec==ntap)
  error('unequal number of tapers per observation is not yet supported');
end
if ntap>1
  error('more than one taper per observation is not yet supported');
end
tra  = zeros(size(mom,2), numel(tapvec));
for k = 1:numel(tapvec)
  tra((k-1)*ntap+(1:ntap), k) = 1./ntap;
end
powmom = (abs(mom).^2)*tra; % need only once
powmom = standardise(log10(powmom), 2);

c = zeros(n, numel(refindx)*2);
N = ones(n,1);
warning off;
for k = 1:numel(refindx)      
  indx     = refindx(k)
  ref      = mom(indx,:);
  crefnorm = conj(ref./abs(ref));

  % FIXME the following is probably not correct for ntap>1
  pow2 = (abs(imag(ref(N,:).*cmomnorm)).^2)*tra;
  pow2 = standardise(log10(pow2), 2);
  c1   = mean(powmom.*pow2, 2);
  pow1 = (abs(imag(mom.*crefnorm(N,:))).^2)*tra;
  pow2 = repmat((abs(ref).^2)*tra, [n 1]);
  pow1 = standardise(log10(pow1), 2);
  pow2 = standardise(log10(pow2), 2);
  c2   = mean(pow1.*pow2, 2);

  c(:,k) = c1;
  c(:,k+numel(refindx)) = c2;
end

