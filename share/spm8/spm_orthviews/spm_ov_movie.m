function ret = spm_ov_movie(varargin)
% Movie tool - plugin for spm_orthviews
%
% This plugin allows an automatic "fly-through" through all displayed
% volumes. Apart from pre-defined trajectories along the x-, y- and z-axis,
% resp., it is possible to define custom start and end points (in mm) for
% oblique trajectories.
%
% Displayed movies can be captured and saved using MATLABs getframe and
% movie2avi commands. One movie per image and axis (i.e. slice display)
% will be created. Movie resolution is given by the displayed image size,
% frame rate is MATLAB standard.
%
% This routine is a plugin to spm_orthviews for SPM8. For general help about
% spm_orthviews and plugins type
%             help spm_orthviews
% at the matlab prompt.
%_______________________________________________________________________
%
% @(#) $Id: spm_ov_movie.m 2536 2008-12-08 14:14:20Z volkmar $

global st;
if isempty(st)
    error('movie: This routine can only be called as a plugin for spm_orthviews!');
end;

if nargin < 2
    error('movie: Wrong number of arguments. Usage: spm_orthviews(''movie'', cmd, volhandle, varargin)');
end;

cmd = lower(varargin{1});
volhandle = varargin{2};

switch cmd
    
    %-------------------------------------------------------------------------
    % Context menu and callbacks
    case 'context_menu'
        item0 = uimenu(varargin{3}, 'Label', 'Movie tool');
        item1 = uimenu(item0, 'Label', 'Run', 'Callback', ...
            sprintf('%s(''context_init'', %d);', mfilename, volhandle), ...
            'Tag', ['MOVIE_0_', num2str(volhandle)]);
        item1 = uimenu(item0, 'Label', 'Help', 'Callback', ...
            sprintf('spm_help(''%s'');', mfilename));
        
    case 'context_init'
        Finter = spm_figure('FindWin', 'Interactive');
        opos=spm_orthviews('pos');
        spm_input('!DeleteInputObj',Finter);
        dir=logical(cell2mat(spm_input('Select movie direction', '!+1', 'b', 'x|y|z|custom', ...
            {[1 0 0], [0 1 0], [0 0 1], 0}, 1)));
        if all(dir==0)
            mstart=spm_input('First point (mm)', '!+1', 'e', num2str(opos'), [3 1]);
            mend  =spm_input('Final point (mm)', '!+1', 'e', num2str(opos'), [3 1]);
        else
            mstart=opos;
            mend=opos;
            bb = st.Space*[st.bb'; 1 1];
            dirs='XYZ';
            tmp=spm_input([dirs(dir) ' intervall (mm)'], '!+1', 'e', ...
                num2str(bb(dir,:), '%.1f %.1f'), 2);
            mstart(dir)=tmp(1);
            mend(dir)=tmp(2);
        end;
        ds=spm_input('Step size (mm)', '!+1', 'e', '1', 1);
        d=mend-mstart;
        l=sqrt(d'*d);
        d=d./l;
        steps = 0:ds:l;
        domovie = cell2mat(spm_input('Save movie(s)?','!+1', 'm', ...
            {'Don''t save', 'Save as image series', ...
            'Save as movie'}, {0,1,2},0));
        if domovie > 0
            vh = spm_input('Select image(s)', '!+1', 'e', ...
                num2str(spm_orthviews('valid_handles')));
            prefix = spm_input('Filename prefix','!+1', 's', ...
                'movie');
            if domovie == 2
                if ispc
                    comp = spm_input('Compression', '!+1', 'm', ...
                        {'None','Indeo3', 'Indeo5', 'Cinepak', 'MSVC'}, ...
                        {'None','Indeo3', 'Indeo5', 'Cinepak', 'MSVC'});
                else
                    comp = 'None';
                end
            end
        else
            vh = [];
        end;
        for k=1:numel(steps)
            spm_orthviews('reposition', mstart+steps(k)*d);
            for ci = 1:numel(vh)
                for ca = 1:3
                    M{ci,ca}(k) = getframe(st.vols{vh(ci)}.ax{ca}.ax);
                end;
            end;
        end;
        spm('pointer', 'watch');
        for ci = 1:numel(vh)
            for ca = 1:3
                if domovie == 1
                    for cf = 1:numel(M{ci,ca})
                        fname = sprintf('%s-%02d-%1d-%03d.png',prefix,vh(ci),ca, ...
                            cf);
                        imwrite(frame2im(M{ci,ca}(cf)), fname, 'png');
                    end;
                elseif domovie == 2
                    fname = sprintf('%s-%02d-%1d.avi',prefix,vh(ci),ca);
                    movie2avi(M{ci,ca},fname, 'compression',comp);
                end;
            end;
        end;
        spm('pointer', 'arrow');
        spm_orthviews('reposition', opos);
        spm_input('!DeleteInputObj',Finter);
    otherwise
        fprintf('spm_orthviews(''movie'', ...): Unknown action %s', cmd);
end;


spm('pointer','arrow');
