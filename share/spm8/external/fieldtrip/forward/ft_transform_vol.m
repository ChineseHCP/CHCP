function [vol] = ft_transform_vol(transform, vol)

% FT_TRANSFORM_VOL applies a homogenous coordinate transformation to
% a structure with an EEG or MEG colume conduction model. The homogenous
% transformation matrix should be limited to a rigid-body translation
% plus rotation and a global rescaling.
%
% Use as
%   vol = ft_transform_vol(transform, vol)
%
% See also FT_READ_VOL, FT_PREPARE_VOL_SENS, FT_COMPUTE_LEADFIELD

% Copyright (C) 2008, Robert Oostenveld
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
% $Id: ft_transform_vol.m 7123 2012-12-06 21:21:38Z roboos $

vol = ft_transform_geometry(transform, vol);