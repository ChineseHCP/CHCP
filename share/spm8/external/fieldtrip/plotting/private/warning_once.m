function [ws warned] = warning_once(varargin)
%
% Use as one of the following
%   warning_once(string)
%   warning_once(string, timeout)
%   warning_once(id, string)
%   warning_once(id, string, timeout)
% where timeout should be inf if you don't want to see the warning ever
% again. The default timeout value is 60 seconds.
%
% It can be used instead of the MATLAB built-in function WARNING, thus as
%   s = warning_once(...)
% or as
%   warning_once(s)
% where s is a structure with fields 'identifier' and 'state', storing the
% state information. In other words, warning_once accepts as an input the
% same structure it returns as an output. This returns or restores the
% states of warnings to their previous values.
%
% It can also be used as
%    [s w] = warning_once(...)
% where w is a boolean that indicates whether a warning as been thrown or not.
%
% Please note that you can NOT use it like this
%   warning_once('the value is %d', 10)
% instead you should do
%   warning_once(sprintf('the value is %d', 10))

% Copyright (C) 2012, Robert Oostenveld
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
% $Id: warning_once.m 7123 2012-12-06 21:21:38Z roboos $

persistent stopwatch previous

if nargin < 1
  error('You need to specify at least a warning message');
end

warned = false;
if isstruct(varargin{1})
  warning(varargin{1});
  return;
end

% put the arguments we will pass to warning() in this cell array
warningArgs = {};

if nargin==3
  % calling syntax (id, msg, timeout)
  
  warningArgs = varargin(1:2);
  timeout = varargin{3};
  fname = [warningArgs{1} '_' warningArgs{2}];
  
elseif nargin==2 && isnumeric(varargin{2})
  % calling syntax (msg, timeout)
  
  warningArgs = varargin(1);
  timeout = varargin{2};
  fname = warningArgs{1};
  
elseif nargin==2 && ~isnumeric(varargin{2})
  % calling syntax (id, msg)
  
  warningArgs = varargin(1:2);
  timeout = 60;
  fname = [warningArgs{1} '_' warningArgs{2}];
  
elseif nargin==1
  % calling syntax (msg)
  
  warningArgs = varargin(1);
  timeout = 60; % default timeout in seconds
  fname = [warningArgs{1}];
  
end

if isempty(timeout)
  error('Timeout ill-specified');
end

if isempty(stopwatch)
  stopwatch = tic;
end
if isempty(previous)
  previous = struct;
end

now = toc(stopwatch); % measure time since first function call
fname = decomma(fixname(fname)); % make a nice string that is allowed as structure fieldname

if length(fname) > 63 % MATLAB max name
  fname = fname(1:63);
end

if ~isfield(previous, fname) || ...
    (isfield(previous, fname) && now>previous.(fname).timeout)
  
  % warning never given before or timed out
  ws = warning(warningArgs{:});
  previous.(fname).timeout = now+timeout;
  previous.(fname).ws = ws;
  warned = true;

else
  
  % the warning has been issued before, but has not timed out yet
  ws = previous.(fname).ws;
  
end

end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function name = decomma(name)
name(name==',')=[];
end % function
