function mailto(address, subject, varargin)

% MAILTO sends an email to specified email address. Uses a system command. 
% 
%   use as:
%     mailto(address, subject, message_body, attachment)
%
% Attachment is optional.  When you use your login name (for instance ingnie)
% as address an email is sent to your @fcdonders.ru.nl email address.
%
% See also system

% Copyright (C) 2006, Ingrid Nieuwenhuis
%
% $Id: mailto.m 7123 2012-12-06 21:21:38Z roboos $

ft_defaults

message_body = varargin{1};

% create a temporary file
temp_file = tempname;
fh = fopen(temp_file, 'w');

% write contents of message_body to the file
fprintf(fh, '%s', message_body);

% close the file
fclose(fh);

% construct the shell commando for sending the email with or without
% attachment
if length(varargin) == 1
  commando = ['cat ', temp_file, ' | mutt -s "', subject, '" ', address];
elseif length(varargin) == 2
  attachment = varargin{2};
  commando = ['cat ', temp_file, ' | mutt -s "', subject, '" ', '-a ', attachment, ' ', address];
else
  error('to many input arguments')
end

% do it!
system(commando);

% clean up the mess
delete(temp_file)
