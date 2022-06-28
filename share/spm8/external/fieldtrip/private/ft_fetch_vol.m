function [vol] = ft_fetch_vol(cfg, data)

% FT_FETCH_VOL mimics the behaviour of FT_READ_VOL, but for a FieldTrip
% data structure or a FieldTrip configuration instead of a file on disk.
%
% Use as
%   [vol] = ft_fetch_vol(cfg, data)
% where either of the two input arguments may be empty.
%
% The volume conductor definitions are specified in the configuration or
% data. The sensor configuration can be passed into this function in three ways:
%  (1) in a file whose name is passed in a configuration field.
%  (2) in a configuration field,
%  (3) in a data field.
% 
% % You should specify the volume conductor model with
%   cfg.hdmfile       = string, file containing the volume conduction model
% or alternatively
%   cfg.vol           = structure with volume conduction model
%   data.vol          = structure with volume conduction model
%
% See also FT_READ_VOL, FT_FETCH_DATA

% Copyright (C) 2011, J�rn M. Horschig
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
% $Id: ft_fetch_vol.m 7123 2012-12-06 21:21:38Z roboos $

% check input arguments
if nargin > 1 && ~isempty(data)
  data = ft_checkdata(data);
else
  data = struct; % initialize as empty struct
end

cfg = ft_checkconfig(cfg);

% meg booleans
hashdmfile = isfield(cfg, 'hdmfile');
hascfgvol  = isfield(cfg, 'vol');
hasdatavol = isfield(data, 'vol');

if (hashdmfile + hascfgvol + hasdatavol) > 1
  display = @warning;
  fprintf('Your data and configuration allow for multiple headmodel definitions.\n');
else
  display = @fprintf;
end

% get the headmodel definition/volume conduction model
if isfield(cfg, 'hdmfile')
  display('reading headmodel from file ''%s''\n', cfg.hdmfile);
  vol = ft_read_vol(cfg.hdmfile);
elseif isfield(cfg, 'vol')
  display('using headmodel specified in the configuration\n');
  vol = cfg.vol;
elseif isfield(data, 'vol')
  display('using headmodel specified in the data\n');
  vol = data.vol;
else
  error('no headmodel specified');
end

% ensure that the headmodel description is up-to-date
vol = ft_datatype_headmodel(vol);
