function l = length(tree,r)
% XMLTREE/LENGTH Length Method
% FORMAT l = length(tree,r)
% 
% tree - XMLTree object
% r    - 'real' if present, returns the real number of nodes in the
%         tree (deleted nodes aren't populated)
% l    - length of the XML tree (number of nodes)
%_______________________________________________________________________
%
% Return the number of nodes of an XMLTree object.
%_______________________________________________________________________
% Copyright (C) 2002-2008  http://www.artefact.tk/

% Guillaume Flandin <guillaume@artefact.tk>
% $Id: length.m 1460 2008-04-21 17:43:18Z guillaume $

error(nargchk(1,2,nargin));

% Return the full number of nodes once allocated
l = length(tree.tree);

% Substract the number of deleted nodes to the previous length
if nargin == 2
    if strcmp(r,'real')
        ll = 0;
        for i=1:l
            if ~strcmp(tree.tree{i}.type,'deleted')
                ll = ll + 1;
            end
        end
        l = ll;
    else
        error('[XMLTree] Bad input argument.');
    end
end
