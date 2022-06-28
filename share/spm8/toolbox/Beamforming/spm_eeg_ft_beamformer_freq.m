function spm_eeg_ft_beamformer_freq(S)
% Compute power images using DICS beamformer
% FORMAT spm_eeg_ft_beamformer_freq(S)
%
% S            - struct (optional)
% (optional) fields of S:
% S.D          - meeg object or filename
%                coregistration must has been performed beforehand
%__________________________________________________________________________
% Copyright (C) 2009 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_eeg_ft_beamformer_freq.m 5136 2012-12-20 12:58:36Z vladimir $

[Finter,Fgraph] = spm('FnUIsetup','Fieldtrip beamformer for power', 0);
%%

%% ============ Load SPM EEG file and verify consistency
if nargin == 0
    S = [];
end

try
    D = S.D;
catch
    D = spm_select(1, 'mat', 'Select EEG mat file');
    S.D = D;
end

if ischar(D)
    try
        D = spm_eeg_load(D);
    catch
        error(sprintf('Trouble reading file %s', D));
    end
end

[ok, D] = check(D, 'sensfid');

if ~ok
    if check(D, 'basic')
        errordlg(['The requested file is not ready for source reconstruction.'...
            'Use prep to specify sensors and fiducials.']);
    else
        errordlg('The meeg file is corrupt or incomplete');
    end
    return
end

modality = spm_eeg_modality_ui(D, 1, 1);
channel = D.chanlabels(strmatch(modality, D.chantype))';

if ~isfield(S, 'refchan') 
    if spm_input('What to beam?','+1', 'power|coherence', [0, 1]);    
        [selection, ok]= listdlg('ListString', D.chanlabels, 'SelectionMode', 'single' ,'Name', 'Select reference' , 'ListSize', [400 300]);
        if ~ok
            return;
        end
        refchan = D.chanlabels(selection);
        S.refchan = refchan;
    else
        S.refchan = [];
    end
end

refchan = S.refchan;

%% ============ Find or prepare head model

if ~isfield(D, 'val')
    D.val = 1;
end

if ~isfield(D, 'inv') || ~iscell(D.inv) ||...
        ~(isfield(D.inv{D.val}, 'forward') && isfield(D.inv{D.val}, 'datareg')) ||...
        ~isa(D.inv{D.val}.mesh.tess_ctx, 'char') % detects old version of the struct
    D = spm_eeg_inv_mesh_ui(D, D.val);
    D = spm_eeg_inv_datareg_ui(D, D.val);
    D = spm_eeg_inv_forward_ui(D, D.val);
end

for m = 1:numel(D.inv{D.val}.forward)
    if strncmp(modality, D.inv{D.val}.forward(m).modality, 3)
        vol  = D.inv{D.val}.forward(m).vol;
        if isa(vol, 'char')
            vol = ft_read_vol(vol);
        end
        datareg  = D.inv{D.val}.datareg(m);
    end
end

if isequal(modality, 'EEG')
    sens = datareg.sensors;
else
    % This is to make it possible to use the same 'inv' in multiple files
    sens = D.sensors('MEG');
end

M1 = datareg.toMNI;
[U, L, V] = svd(M1(1:3, 1:3));
M1(1:3,1:3) =U*V';

vol = ft_transform_vol(M1, vol);
sens = ft_transform_sens(M1, sens);


%% ============ Select the data and convert to Fieldtrip struct

clb = D.condlist;

if ~isfield(S, 'conditions')
    if numel(clb) > 1
        [selection, ok]= listdlg('ListString', clb, 'SelectionMode', 'multiple' ,'Name', 'Select conditions' , 'ListSize', [400 300]);
        if ~ok
            return;
        end
    else
        selection = 1;
    end
else
    selection = find(ismember(clb, S.conditions));
end
%%
ind = [];
condvec = [];
for i = 1:length(selection)
    ind = [ind D.pickconditions(clb(selection(i)))];
    condvec = [condvec selection(i)*ones(size(D.pickconditions(clb(selection(i)))))];
end
%%
if isempty(ind)
    warning('No valid trials found');
    return;
end
%%
data = D.fttimelock;
data.trial = data.trial(ind, :, :);
%%
if ~isfield(S, 'freqrange')
    if ~(isfield(S, 'centerfreq') && isfield(S, 'tapsmofrq'))
        S.freqrange = spm_input('Frequency range (Hz):', '+1', 'r', '', 2);
        S.centerfreq = mean(S.freqrange);
        S.tapsmofrq  = 0.5*diff(S.freqrange);
    end
else
    S.centerfreq = mean(S.freqrange);
    S.tapsmofrq  = 0.5*diff(S.freqrange);
end


%%
if ~isfield(S, 'timewindows')
    for i = 1:spm_input('Number of time windows:', '+1', 'r', '1', 1)
        S.timewindows{i} = spm_input('Time ([start end] in sec):', '+1', 'r', '', 2);
    end
end
cfg = [];
cfg.channel = [channel; refchan];
for i = 1:numel(S.timewindows)
    cfg.latency = S.timewindows{i};
    timelock{i} = ft_selectdata(cfg, data);
end

%%
if numel(timelock) == 1
    S.contrast = 1;
elseif ~isfield(S, 'contrast')
    if numel(timelock) == 2
        def = '1 -1';
    else
        def = '';
    end
    
    S.contrast = spm_input('Contrast vector:', '+1', 'r', def, i);
end
%%
if ~isfield(S, 'lambda')
    S.lambda = [num2str(spm_input('Regularization (%):', '+1', 'r', '0')) '%'];
end

if ~isfield(S, 'gridres')
    S.gridres = spm_input('Grid resolution (mm)', '+1', 'r', '10');
end

if ~any(ismember({'bycondition', 'preview', 'singleimage'}, fieldnames(S)))
   switch spm_input('Output format','+1', 'm', 'single image|image per condition|image per trial|preview', ...
        char('singleimage', 'bycondition', 'trials', 'preview'))
       case 'singleimage'
           S.singleimage = 1;
           S.preview = 0;
           S.bycondition = 0;
       case 'bycondition'
           S.singleimage = 1;
           S.preview = 0;
           S.bycondition = 1;
       case 'trials'
           S.singleimage = 0;
           S.preview = 0;
           S.bycondition = 0;           
       case 'preview'
           S.singleimage = 0;
           S.preview = 1;
           S.bycondition = 0;                      
   end
end
    
if ~isfield(S, 'normalize')
  S.normalize = spm_input('Global normalization?','+1','yes|no',[1 0], 1);
end

if ~isfield(S, 'mniout')
  S.mniout = spm_input('Output space?','+1','MNI-aligned|MNI template',[0 1], 0);
end

%%
cfg = [];
cfg.method    = 'mtmfft';

if ~license('checkout','signal_toolbox') || isdeployed;
    cfg.taper = 'sine';
end

cfg.output    = 'powandcsd';
cfg.tapsmofrq = S.tapsmofrq;
cfg.foilim    = [S.centerfreq S.centerfreq];
cfg.keeptrials = 'yes';

for i = 1:numel(timelock)
    freq{i} = ft_freqanalysis(cfg, timelock{i});
end

if isfield(S, 'usewholetrial') && S.usewholetrial
    cfg.channel = channel;
    cfg.channelcmb = ft_channelcombination({'all', 'all'}, channel);
    if ~isempty(refchan)
        cfg.channelcmb =  [cfg.channelcmb; ft_channelcombination({'all', refchan}, [channel; {refchan}])];
    end
    filtfreq = ft_freqanalysis(cfg, data);
end
%%
freqall = freq{1};
timevec = ones(1, size(freq{1}.powspctrm, 1));
trialvec = ind;
if length(freq) > 1
    for i = 2:length(freq)
        freqall.powspctrm = cat(1,  freqall.powspctrm, freq{i}.powspctrm);
        freqall.crsspctrm = cat(1,  freqall.crsspctrm, freq{i}.crsspctrm);
        freqall.cumsumcnt = cat(1,  freqall.cumsumcnt, freq{i}.cumsumcnt);
        freqall.cumtapcnt = cat(1,  freqall.cumtapcnt, freq{i}.cumtapcnt);
        timevec = [timevec i*ones(1, size(freq{i}.powspctrm, 1))];
        condvec = [condvec(:)' condvec(:)'];
        trialvec = [trialvec ind];
    end
end
%%
cfg                       = [];

if strcmp('EEG', modality)
    cfg.elec = sens;
else
    cfg.grad = sens;
    cfg.dics.reducerank            = 2;
end

cfg.channel = D.chanlabels(D.meegchannels(modality));
cfg.vol                   = vol;

mnigrid.xgrid = -90:S.gridres:90;
mnigrid.ygrid = -120:S.gridres:100;
mnigrid.zgrid = -50:S.gridres:110;

mnigrid.dim   = [length(mnigrid.xgrid) length(mnigrid.ygrid) length(mnigrid.zgrid)];
[X, Y, Z]  = ndgrid(mnigrid.xgrid, mnigrid.ygrid, mnigrid.zgrid);
mnigrid.pos   = [X(:) Y(:) Z(:)];

cfg.grid.dim = mnigrid.dim;
cfg.grid.pos = spm_eeg_inv_transform_points(M1*datareg.fromMNI, mnigrid.pos);
cfg.inwardshift = -10;
cfg.sourceunits = 'mm';

grid            = ft_prepare_leadfield(cfg);


cfg = [];

if strcmp('EEG', modality)
    cfg.elec = D.inv{D.val}.datareg.sensors;
else
    cfg.grad = D.sensors('MEG');
    cfg.dics.reducerank = 2;
end

cfg.channel = D.chanlabels(D.meegchannels(modality));

if ~isempty(refchan)
    cfg.refchan = refchan;
end

cfg.dics.keepfilter   = 'yes';
cfg.frequency    = S.centerfreq;
cfg.method       = 'dics';

if isfield(S, 'fixedori') && S.fixedori
    cfg.dics.fixedori = 'yes';
end

cfg.dics.realfilter = 'yes';

cfg.dics.powmethod  = 'trace';

cfg.dics.projectnoise = 'no';
cfg.grid         = grid;
cfg.vol          = vol;
cfg.dics.lambda       = S.lambda;
cfg.dics.keepcsd = 'yes';

if isfield(S, 'usewholetrial') && S.usewholetrial
    filtsource   = ft_sourceanalysis(cfg, filtfreq);
else
    filtsource   = ft_sourceanalysis(cfg, freqall);
end

if isfield(S, 'geteta') && S.geteta
    if isfield(S, 'mniout') && S.mniout
        filtsource.pos = mnigrid.pos;
        filtsource.dim = mnigrid.dim;
    end
    save(fullfile(D.path, 'ori.mat'), 'filtsource');
end
%
cfg.dics.keepfilter   = 'no';
cfg.grid.filter  = filtsource.avg.filter; % use the filter computed in the previous step

sMRI = fullfile(spm('dir'), 'canonical', 'single_subj_T1.nii');

if (isfield(S, 'preview') && S.preview) || ~isempty(refchan) ||...
        (isfield(S, 'singleimage') && S.singleimage)
    if S.bycondition       
        cl = unique(condvec);        
        ni = length(cl);        
    else
        ni = 1;
    end
    
    for c = 1:ni
        source = {};
        
        for t = 1:length(unique(timevec))
            cfreq = freqall;
            
            if S.bycondition    
                cind = find(timevec == t & condvec == cl(c));
            else
                cind = find(timevec == t);
            end
            
            cfreq.powspctrm = cfreq.powspctrm(cind, :);
            cfreq.crsspctrm = cfreq.crsspctrm(cind, :);
            cfreq.cumsumcnt = cfreq.cumsumcnt(cind);
            cfreq.cumtapcnt = cfreq.cumtapcnt(cind);
            source{t}   = ft_sourceanalysis(cfg, cfreq);
        end
        
        %
        pow = [];
        for i = 1:numel(source)
            if isempty(refchan)
                pow = [pow source{i}.avg.pow(:)];
            else
                pow = [pow source{i}.avg.coh(:)];
            end
        end
        
        
        if isfield(S, 'normalize') && S.normalize
            pow = pow./mean(pow(~isnan(pow)));
        end
        
        csource = source{1};
        csource.pow = (pow*S.contrast(:));
        
        if isfield(S, 'mniout') && S.mniout
            csource.pos = mnigrid.pos;
            csource.dim = mnigrid.dim;
        end
        
        
        cfg1 = [];
        cfg1.sourceunits   = 'mm';
        cfg1.parameter = 'pow';
        cfg1.downsample = 1;
        sourceint = ft_sourceinterpolate(cfg1, csource, ft_read_mri(sMRI, 'format', 'nifti_spm'));
        %%
        
        if (isfield(S, 'preview') && S.preview)
            cfg1 = [];
            cfg1.funparameter = 'pow';
            cfg1.funcolorlim = 0.1*[-1 1]*max(abs(csource.pow));
            if ~(S.bycondition && numel(cind)>1)
                cfg1.interactive = 'yes';
            end
            figure
            ft_sourceplot(cfg1,sourceint);
        end
        
        if ~isempty(refchan) || (isfield(S, 'singleimage') && S.singleimage)
            res = mkdir(D.path, 'images');
            outvol = spm_vol(sMRI);
            outvol.dt(1) = spm_type('float32');
            
            outvol.fname= fullfile(D.path, 'images', ['img_' spm_str_manip(D.fname, 'r')]);
            
            if S.bycondition
                outvol.fname= [outvol.fname '_' clb{cl(c)}];
            end
            
            if ~isempty(refchan)
                outvol.fname= [outvol.fname '_coh.nii'];
            else
                outvol.fname= [outvol.fname '.nii'];
            end
            
            outvol = spm_create_vol(outvol);
            spm_write_vol(outvol, sourceint.pow);
        end
    end
else
    cfg.rawtrial     = 'yes';
    
    source   = ft_sourceanalysis(cfg, freqall);
    
    if isfield(S, 'mniout') && S.mniout
        source.pos = mnigrid.pos;
        source.dim = mnigrid.dim;
    end
    
    clear('data', 'csource', 'filtsource', 'timelock', 'freq', 'grid', 'freqall');
    
    cfg = [];
    cfg.sourceunits   = 'mm';
    cfg.parameter = 'pow';
    cfg.downsample = 1;
    %
    res = mkdir(D.path, 'images');
    
    outvol = spm_vol(sMRI);
    %
    outvol.dt(1) = spm_type('float32');
    
    trialind = unique(trialvec);
    
    pow = nan(size(source.pos, 1), length(S.contrast));
    
    for i = 1:length(trialind)
        ind = find(trialvec == trialind(i));
        
        cond = unique(condvec(ind));
        
        for j = 1:length(ind)
            pow(:, j) = source.trial(ind(j)).pow(:);
        end
        
        if isfield(S, 'normalize') && S.normalize
            pow = pow./mean(pow(~isnan(pow)));
        end
        
        source.pow = (pow*S.contrast(:));
        
        sourceint = ft_sourceinterpolate(cfg, source, ft_read_mri(sMRI, 'format', 'nifti_spm'));
        
        outvol.fname= fullfile(D.path, 'images', ['img_' spm_str_manip(D.fname, 'r') '_' clb{cond} '_trial_' num2str(trialind(i)) '.nii']);
        outvol = spm_create_vol(outvol);
        spm_write_vol(outvol, sourceint.pow);
    end
    %%
end

