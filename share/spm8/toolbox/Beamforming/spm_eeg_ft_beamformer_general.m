function [opstats,mripositions,ctfpositions,grid]=spm_eeg_ft_beamformer_general(S)
%%function [opstats,talpositions,gridpositions,grid,alllf,allepochdata]=spm_eeg_ft_beamformer_general(S)
% A general scalar LCMV beamformer function using Sekihara;s orientation
% estimate
% S.D spm filename
% DESIGN MATRX:
% S.design.X : N*d design matrix
% S.design.contrast: contrast matrix
% S.design.Xtrials : Nx1 trial numbers of the N trials
% S.design.Xstartlatencies : Nx1 event latencies within each of the N trials
%
% REGULARISATION
% S.regpc >0 the percentage of the mean eigevalue with which to smooth the
% channel covariance matrix prior to inversion
% S.regpc -1: Mark Woolrich's ARD based Bayesian PCA
% S.regpc -2: Will Penny's model order selection Bayesian PCA (i.e.
% truncation)
% S.regpc -3: As above but using Bayes PCA to get conventional
% regularisation parameter. Returned as S.eff_reg
%
% DATATYPE,
% S.datatype  a list of datatypes to be used
% 'meanHenv' : mean hilber envelope per trial
%  'meanHreal' : mean real hilbert coefficient
%  'meanHimag' : mean imaginary hilbert coefficient
%
% STATISTIC
% S.stattype
% 'Tstat' :  A (univariate) t-statistic image
% 'Beta' : A univariate Beta value per voxel
%  'CVA' : A classical chi approximation to the CVA multivariate test
% 'probCVA':  BIC model evidence difference between using 0 and 1 latent
% variable (based on Will Penny's code)
%
% Modality
% S.modalities for example= {'MEGGRAD','MEGMAG'}
% This code corrects for scaling error in neuromag planar grad lead fields
% also adjusts magnitudes of leadfields and data to make covariance matrix
% uniform
% _______________________________________________________________________
% Copyright (C) 2012 Institute of Neurology, UCL

% Gareth Barnes
% $Id: spm_eeg_ft_beamformer_general.m 5214 2013-01-29 10:47:14Z gareth $

[Finter,Fgraph] = spm('FnUIsetup','Multivariate LCMV beamformer for power', 0);

%%%%%%%%%%%%% SET OPTIONAL FLAGS AND CHECK THE INPUT%%%%%%%%%%%%%%%%%%


if ~isfield(S,'filenamestr'),
    S.filenamestr=[];
end;%

% Return beamformer weights
if ~isfield(S,'return_weights')
    ctf_weights=[];
    S.return_weights=0;
    alllf=[];
end
 if ~isfield(S,'MRIname'),
     S.MRIname=[];
 end;

if ~isfield(S,'volcorrect'),
    S.volcorrect=[];
end;
if ~isfield(S,'design'),
    error('Design matrix required');
end; % if

if ~isfield(S,'regressout'),
    S.regressout=[];
end;


if size(S.design.X(:,1),1)~=size(S.design.Xtrials,1)
    error('Design windows missepcified');
end;
if size(S.design.X(:,1),1)~=size(S.design.Xstartlatencies,1)
    error('Design windows missepcified');
    
end;


if ~isfield(S,'gridpos'),
    S.gridpos=[];
    if ~isfield(S,'gridstep');
        S.gridstep = spm_input('Grid step (mm):', '+1', 'r', '5');
    end;
end; % if

if ~isfield(S,'maskgrid'),
    S.maskgrid=[];
end;

if ~isfield(S,'maskfile'),
    S.maskfile=[];
end;

if ~isfield(S,'regpc'),
    S.regpc=[];
end; % if
if isempty(S.regpc),
    S.regpc=0;
end; % if

if ~isfield(S,'modalities'),
    S.modalities=[];
end;

if ~isfield(S,'templatemri'),
    S.templatemri='';
end;

if isempty(S.modalities),
    disp('setting modality to MEGGRAD by default');
    S.modalities={'MEGGRAD'};
end;
modalities=S.modalities;
%% ============ Load SPM EEG file and verify consistency
if nargin == 0
    S = [];
end

try
    D = S.D;
catch
    D = spm_select(1, '\.mat$', 'Select EEG mat file');
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

if ~isfield(D, 'val')
    D.val = 1;
end





%% ============ Find or prepare head model


try
    vol = D.inv{D.val}.forward.vol;
    datareg = D.inv{D.val}.datareg;
catch
    D = spm_eeg_inv_mesh_ui(D, D.val, [], 1);
    D = spm_eeg_inv_datareg_ui(D, D.val);
    datareg = D.inv{D.val}.datareg;
end


%% Identify good channels and keep a record of which modality they belong to (MEGGRAD/MAG etc)

channel_labels=[];
chans=setdiff(D.meegchannels,D.badchannels); %LH
for ff=1:length(modalities),
    chan_ind_interleaved{ff}=[];
end;

sta=1;
keyboard
for ch=1:length(chans),
    % find modality index
    for ff=1:length(modalities),
        if(strcmp(D.chantype(chans(ch)),modalities{ff}))
            break;
        elseif(ff==length(modalities))
            ff=0;
        end;
    end;
    if(ff>0) % channel  needed
        % interleaved, e.g.for neuromag 3:3:306 MEG if MEG and MEGPLANAR, and 1:105 if just MEG
        chan_ind_interleaved{ff}=[chan_ind_interleaved{ff} sta]; %
        sta=sta+1;
        channel_labels = [channel_labels D.chanlabels(chans(ch))]; % this is

    end;
end;



%%%%%%%%%%%%%%%% NOW READ IN THE DATA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% now read in the first trial of data just to get sizes of variables right
Ntrials=size(S.design.X,1);
Isamples = D.indsample([S.design.Xstartlatencies(1) S.design.Xstartlatencies(1)+S.design.Xwindowduration]);
Nsamples= diff(Isamples)+1;
Nchans=length(channel_labels);
allepochdata=zeros(Ntrials,Nchans,Nsamples); %% for loading in data quickly


[uniquewindows]=unique(S.design.Xstartlatencies);
Nwindows=length(uniquewindows);

%% GET DATA- put each trial in allepochdata in same order as design matrix (i.e. remove dependence on Xtrials and Xstartlatencies)

if length(unique(S.design.Xtrials))==1, %% for single trial data
    disp('loading single trial data');
    allIsamples=[];
    Itrials=S.design.Xtrials(1);
    for i=1:Nwindows,     %% puts trials into epoch data according to order of design.X structures
        Isamples = D.indsample([uniquewindows(i) uniquewindows(i)+S.design.Xwindowduration]);
        alluseind(i)=find(uniquewindows(i)==S.design.Xstartlatencies);
        allIsamples=[allIsamples Isamples(1):Isamples(2)];
    end; % for i
    testdata=squeeze(D(D.indchannel(channel_labels), allIsamples, Itrials)); %% get an epoch of data with channels in columns
    flatpepdata=testdata';
    testdata=reshape(testdata,Nchans,Nsamples,Ntrials);
    testdata=permute(testdata,[3 1 2]);
    
    allepochdata=testdata(alluseind,:,:); %% put into order of design matrix
    clear testdata;
else %% multiple trial data
    disp('reading multiple trial data');
    for i=1:Nwindows,     %% puts trials into epoch data according to order of design.X structures
        Isamples = D.indsample([uniquewindows(i) uniquewindows(i)+S.design.Xwindowduration]);
        useind=find(uniquewindows(i)==S.design.Xstartlatencies);
        Itrials =S.design.Xtrials(useind); %% indices into design.X structures
        allepochdata(useind,:,:)=permute(squeeze(D(D.indchannel(channel_labels), Isamples(1):Isamples(2), Itrials)), [3 1 2]); %% get an epoch of data with channels in columns
    end; % for i
    
end;

%%%%% prepare  data : in Ntrials rows %%%%%%%%%%%%%%%%%%%%%%%%
disp('flattening data');
testdata=permute(allepochdata,[2,3,1]);
flatpepdata=reshape(testdata,Nchans,Ntrials*Nsamples,1)';
clear testdata;


%%%%%%%%%%%%%%%%% NOW SET UP FORWARD MODE %%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg                       = [];
if ~isempty(strfind(cell2mat(modalities),'EEG'))
    cfg.elec = D.inv{D.val}.datareg.sensors;
    cfg.reducerank=3;
else
    cfg.grad = D.sensors('MEG');
    
    cfg.reducerank=2;
    disp('Reducing possible source orientations to a tangential plane for MEG');
end



cfg.channel = channel_labels;
cfg.vol                   = vol;




if  isempty(S.gridpos),
    %cfg.resolution            = S.gridstep;
    if ~isempty(S.templatemri),
        V1=spm_vol(S.templatemri);
        [Y1,XYZ1]=spm_read_vols(V1);
        tempind=find(Y1);
        mnigrid.xgrid=min(XYZ1(1,tempind)):S.gridstep:max(XYZ1(1,tempind));
        mnigrid.ygrid=min(XYZ1(2,tempind)):S.gridstep:max(XYZ1(2,tempind));
        mnigrid.zgrid=min(XYZ1(3,tempind)):S.gridstep:max(XYZ1(3,tempind));
        
    else
        mnigrid.xgrid = -100:S.gridstep:100;
        mnigrid.ygrid = -120:S.gridstep:100;
        mnigrid.zgrid = -50:S.gridstep:120;
    end;
    
    mnigrid.dim   = [length(mnigrid.xgrid) length(mnigrid.ygrid) length(mnigrid.zgrid)];
    [X, Y, Z]  = ndgrid(mnigrid.xgrid, mnigrid.ygrid, mnigrid.zgrid);
    mnigrid.pos   = [X(:) Y(:) Z(:)];
    
    cfg.grid.dim = mnigrid.dim;
    cfg.grid.pos = spm_eeg_inv_transform_points(datareg.fromMNI, mnigrid.pos);
    
    
else
    disp('USING pre-specified gridpoints');
    cfg.grid.pos=S.gridpos; %% predefined grid
    cfg.grid.inside=[1:size(S.gridpos,1)]; %% assume all in head
    cfg.grid.outside=[];
end;

% figure;
% %plot3(cfg.grid.pos(:,1),cfg.grid.pos(:,2),cfg.grid.pos(:,3),'.');
% hold on;
% plot3(cfg.grad.pnt(:,1),cfg.grad.pnt(:,2),cfg.grad.pnt(:,3),'or');
% hold on
% plot3(cfg.vol.o(:,1),cfg.vol.o(:,2),cfg.vol.o(:,3),'m*');

cfg.feedback='off';
cfg.inwardshift           = -S.gridstep; % mm
cfg.sourceunits = 'mm';

if ~isfield(S,'grid'),
    disp('preparing leadfield');
    grid                      = ft_prepare_leadfield(cfg);
    % this is needed to correct for error in the fieldtrip code in
    % SPM8
    correct_grads=1;
    if (correct_grads)
        disp('correcting grad scaling by 1/0.017');
        correct_factor=1/0.017; % gradiometer coils are 17mm apart
        imod=strmatch('MEGPLANAR',modalities);
        %chan_ind_interleaved{imod}
        for i1=1:length(grid.inside),
            grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{imod},:)=grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{imod},:).*correct_factor;
        end;
    end;
    
else
    disp('Using precomputed leadfield');
    grid=S.grid;
end; % if


maskedgrid_inside_ind=[1:length(grid.inside)];

if ~isempty(S.maskgrid),
    if length(S.maskgrid)~=length(grid.inside),
        error('mask and grid points must be of same size');
    end;
    maskedgrid_inside_ind=find(S.maskgrid==1); %% indices into grid.inside
end;

if ~isempty(S.maskfile),
    if ~isempty(S.maskgrid),
        error('cannot have two masks defined');
    end;
    alltalpositions = spm_eeg_inv_transform_points(datareg.toMNI, grid.pos(grid.inside,:));
    V_aal = spm_vol(S.maskfile);
    [Y_aal,XYZ]=spm_read_vols(V_aal);
    mask_coords=XYZ(:,find(Y_aal>0));
    
    
    %% now express mni grid and mesh grid at same coarse scale to get
    %% intersection
    coarse_mm=10;
    mask_coarse=unique(round(mask_coords'/coarse_mm)*coarse_mm,'rows');
    grid_coarse= round(alltalpositions/coarse_mm)*coarse_mm;
    [overlap_pos,maskedgrid_inside_ind]=intersect(grid_coarse,mask_coarse,'rows'); %% mesh_vert_ind are mesh points in this mask
    maskedgrid_inside_ind=sort(maskedgrid_inside_ind);
end; % if

if cfg.reducerank, %% follow up rank reduction and remove redundant dimension from lead fields
    for i=1:length(maskedgrid_inside_ind), %% 81
        lf1=cell2mat(grid.leadfield(grid.inside(maskedgrid_inside_ind(i))));
        [u1,s1,v1]=svd(lf1'*lf1);
        grid.leadfield(grid.inside(maskedgrid_inside_ind(i)))={lf1*u1(:,1:cfg.reducerank)};
        %normlf(i)=std(dot(lfnew',lfnew'));
    end;
end; % if reduce rank



%% prepare to write images
if isempty(S.MRIname),
    sMRI = fullfile(spm('dir'), 'canonical', 'single_subj_T1.nii');
    mripositions = spm_eeg_inv_transform_points(datareg.toMNI, grid.pos); %% MADE DATAREG STAND ALONE
    %spm_eeg_inv_transform_points(datareg.toMNI, csource.pos);
else
    sMRI=S.MRIname;
    
    mripositions=[grid.pos ones(size(grid.pos,1),1)]*pinv(S.MRI2CTFMEG);
end;

% if S.ctfseedpos,
%     d1=grid.pos-repmat(S.ctfseedpos,size(grid.pos,1),1);
%     d1=dot(d1',d1');
%     [dum,ctfseedind]=min(d1);
%     disp('Using seed at ctf position:');
%     grid.pos(ctfseedind,:)
%     disp('Mri position:');
%     mripositions(ctfseedind,:)
%
% end;

%%%%% GET FREQUENCY BANDS OF INTEREST- THESE SEPARATE BANDS WILL DEFINE THE
%%%%% COVARIANCE MATRIX (TOGETHER) AND INDIVIDUALLY FORM DIFFERENT
%%%%% POTENTIAL FEATURES
freqbands=[];
if ~isfield(S, 'freqbands')
    for i = 1:spm_input('Number of frequency bands:', '+1', 'r', '1', 1)
        outstr=sprintf('Band %d [st end] in Hz ',i);
        S.freqbands{i} = spm_input(outstr, '+1', 'r', '', 2);
        freqbands =[freqbands;S.freqbands{i}'];
    end
else
    freqbands=cell2mat(S.freqbands');
end

Nbands=numel(S.freqbands);

%dctfreq = (1:Nsamples)/2/S.design.Xwindowduration;           % DCT frequencies (Hz)
dctfreq = (0:Nsamples-1)/2/S.design.Xwindowduration;           % DCT frequencies (Hz)
dctT      = spm_dctmtx(Nsamples,Nsamples);


freqstr=[];
allfreqind=[];
for fband=1:Nbands, %% allows one to break up spectrum and ignore some frequencies
    freqrange=freqbands(fband,:);
    j      = find( (dctfreq >= freqrange(1)) & (dctfreq<=freqrange(2)) );
    featureind{fband}=j;
    allfreqind=sort(unique([allfreqind j]));
    freqstr=[freqstr sprintf('%3.1f-%3.1f,',dctfreq(min(j)),dctfreq(max(j)))];
end; % for fband=1:Nbands

Tfull      = dctT(:,allfreqind); %% A filter for all bands


%%%%%%%%%%%%%%%% READ IN AND FILTER DATA %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

YY=zeros(Nsamples,Nsamples);

HW  = sparse(1:Nsamples,1:Nsamples,spm_hanning(Nsamples));
%YY=zeros(Nchans,Nchans);
%covtrial=YY;
%allY=zeros(Nchans,Ntrials*Nsamples);
allY=[];
for i=1:Ntrials, %% read in all individual trial types
    Y     = squeeze(allepochdata(i,:,:));
    Y=Y-repmat(mean(Y,2),1,size(Y,2)); %% take off dc per channel per trial
    Y=Y*HW; % window
    Y=Y*Tfull;   % filter
    allY=[allY Y];
    %    YY=YY+Y*Y'; % augment covariance
    
end; % for i

%%% NOW WANT TO SCALE UP CHANNELS/ SCALE DOWN LEAD FIELDS ACCORDING TO
%%% THEIR NOISE LEVEL -ONLY HAS AN EFFECT IN  MIXED MODALITY DATASETS

for ff=1:length(modalities),
    [M_opt,log_ev,lambda1] = spm_pca_order (allY(chan_ind_interleaved{ff},:));
    noisevar=mean(lambda1(M_opt+1:max(find(lambda1>0)))); %% some eigenvals can come out negative
    
    normalisation{ff}=sqrt(noisevar);
    disp(['Modality ' modalities{ff} ' has data normalisation ' num2str(normalisation{ff})]);
    allY(chan_ind_interleaved{ff},:)=allY(chan_ind_interleaved{ff},:)./normalisation{ff};
end;


for i=1:length(maskedgrid_inside_ind),
    lf=cell2mat(grid.leadfield(grid.inside(maskedgrid_inside_ind(i))));
    lfn=lf;
    for ff=1:length(modalities),
        lfn(chan_ind_interleaved{ff},:)=lf(chan_ind_interleaved{ff},:)./normalisation{ff}; %% GRB MOD
    end;
    grid.leadfield{grid.inside(maskedgrid_inside_ind(i))}=lfn;
end;

%% END OF RESCALING




YY=(allY*allY')./Ntrials;
imagesc(YY);
allsvd = svd(YY);
cumpower=cumsum(allsvd)./sum(allsvd);
nmodes99=min(find(cumpower>0.99));
disp(sprintf('99 percent of the power in this data is in the first %d principal components of the cov matrix',nmodes99));
disp(sprintf('largest/smallest eigenvalue=%3.2f',allsvd(1)/allsvd(end)));
disp(sprintf('\nFrequency resolution %3.2fHz',dctfreq(allfreqind(2))-dctfreq(allfreqind(1))));
noise = allsvd(end); %% use smallest eigenvalue
disp(sprintf('covariance band from %3.2f to %3.2fHz (%d bins)',dctfreq(allfreqind(1)),dctfreq(allfreqind(end)),length(allfreqind)))





%%%%%%%%%%%%%%%% SET REGULARISATION
%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch S.regpc,
    case -1, %% run Mark's bayesian pca to regularise
        
        dims2use=min(size(allY,1),round(3*size(allY,2)/4));
        [m_w, alpha, covtrial, cinv, taus, tau, m_x, Sigma_w, Sigma_x, Q, N, Dd,alphamin,alphamax]=bayes_pca_ss(allY,dims2use,40,Ntrials);
        need_invC=0;
        
        maxw = min(find(alpha>((alpha(1)*alphamax)^(1/2))))-1;
        
        if(isempty(maxw))
            maxw=1;
        end;
        
        if(maxw<1)
            maxw=1;
        end;
        
        opstats.alpha=alpha;
        opstats.tau=tau;
        opstats.taus=taus;
        opstats.m_w=m_w;
        noisevar=mean(allsvd(m_w+1:end));
        noise_id=eye(size(YY,1))*noisevar; %% noise power
    case -2,,
        %keyboard;
        %%% WIll's code- based on MInka- based on trunctation to optimum model order
        disp('Will Penny Bayes PCA to get model order');
        [u,s]=svd(allY*allY');
        [M_opt,log_ev,lambda1] = spm_pca_order (allY);
        noisevar=mean(lambda1(M_opt+1:max(find(lambda1>0)))); %% some eigenvals can come out negative
        redYY=u(:,1:M_opt)*s(1:M_opt,1:M_opt)*u(:,1:M_opt)';
        cinv=pinv(redYY);
        op_stats.truncorder=M_opt;
        noise_id=eye(size(YY,1))*noisevar; %% noise power
    case -3, %% use Will's bayes pca to get noise level then use this to augment diagonal
        
        disp('Will Penny Bayes PCA to get noise and augment diagonal');
        [M_opt,log_ev,lambda1] = spm_pca_order (allY);
        noisevar=mean(lambda1(M_opt+1:max(find(lambda1>0)))); %% some eigenvals can come out negative
        
        opstats.eff_reg=100*noisevar./mean(allsvd);
        disp(sprintf('effective regularisation =%3.2f percent',opstats.eff_reg));
        cinv=pinv(YY+eye(size(YY,1))*noisevar); %%
        noise_id=eye(size(YY,1))*noisevar;
    case -4, %% MATT REG
        disp('DOING REG Of 4* SMALLest eiGEN VALUE FOR TESTING');
        lambda = 4*min(allsvd)/size(YY,1); %% scale lambda relative min eigenvalue
        %disp(sprintf('regularisation =%3.2f percent',S.regpc));
        cinv=pinv(YY+eye(size(YY,1))*lambda); %% get inverse - if N features has been reduced should maybe think of sorting this out too.
        noise_id=eye(size(YY,1))*lambda; %% noise power
    otherwise,
        lambda = (S.regpc/100) * sum(allsvd)/size(YY,1); %% scale lambda relative mean eigenvalue
        disp(sprintf('regularisation =%3.2f percent',S.regpc));
        cinv=pinv(YY+eye(size(YY,1))*lambda); %% get inverse - if N features has been reduced should maybe think of sorting this out too.
        noise_id=eye(size(YY,1))*lambda; %% noise power
end;






%% remove data we no longer need
clear allepochdata allY;

%%% initialise variables
gen_maxstat=zeros(length(maskedgrid_inside_ind),1);
regressout=S.regressout;
Yfull=bf_get_epoch_data(flatpepdata,Nsamples,Ntrials,-1,Tfull,S.datatype,featureind,regressout); %% set up data structures
opstats=[];
if S.return_weights,
    opstats.ctf_weights=zeros(length(maskedgrid_inside_ind),Nchans);
end;
alllf=zeros(length(maskedgrid_inside_ind),Nchans);
cva=[];
%if S.return_canV,
    ;
    

for i=1:length(maskedgrid_inside_ind), %% 81
    
    lf=cell2mat(grid.leadfield(grid.inside(maskedgrid_inside_ind(i)))); %%
    %     if grid.inside(maskedgrid_inside_ind(i))==8495,
    %         keyboard;
    %     end;
    %
    %% get optimal orientation- direct copy from Robert's beamformer_lcmv.m
    projpower_vect=pinv(lf'*cinv*lf);
    
    [u, s, v] = svd(real(projpower_vect)); %% MAY NOT BE POWER WE NEED TO OPTIMISE
    eta = u(:,1);
    lf  = lf * eta; %% now have got the lead field at this voxel, compute some contrast
    weights=(lf'*cinv*lf)\lf'*cinv; %% no regularisation for now
    
    [Yfull,vedata]=bf_get_epoch_data(flatpepdata,Nsamples,Ntrials,weights,dctT,S.datatype,featureind,regressout);
    Yfull=Yfull-repmat(mean(Yfull),size(Yfull,1),1); %% remove dc level from each column/feature
    Yfull=Yfull./repmat(std(Yfull),size(Yfull,1),1); %% normalize features to have unit variance by default
    
    switch S.stattype,
        case 'CVAbic',
            [chi,BIC,cva]=gen_bf_cva(S.design.X,Yfull,S.design.contrast); %%  design matrix, datafeatures, contrast c
            gen_maxstat(maskedgrid_inside_ind(i))=-BIC(1); %% get bic (of dominant mode)
            opstats.cva=cva;
        case 'CVAccorr',
            [chi,BIC,cva]=gen_bf_cva(S.design.X,Yfull,S.design.contrast); %%  design matrix, datafeatures, contrast c
            gen_maxstat(maskedgrid_inside_ind(i))=cva.ccorr(1); %% get canonical correlation (of dominant mode)
            opstats.cva=cva;
            
        case 'CVAchi',
            [chi,BIC,cva]=gen_bf_cva(S.design.X,Yfull,S.design.contrast); %%  design matrix, datafeatures, contrast c
            gen_maxstat(maskedgrid_inside_ind(i))=chi(1); %% get wilk's lambda stat
            opstats.cva=cva;
            
            if i==1,
                opstats.allW=zeros(length(maskedgrid_inside_ind),size(cva.W,1));
                opstats.allV=zeros(length(maskedgrid_inside_ind),size(cva.V,1));
            end;

            opstats.allW(maskedgrid_inside_ind(i),:)=cva.W(:,1);
            opstats.allV(maskedgrid_inside_ind(i),:)=cva.V(:,1);
        case 'probCVAbic'
            prCVA=spm_cva_compare(Yfull,S.design.X,S.design.contrast);
            gen_maxstat(maskedgrid_inside_ind(i))=prCVA.bic(2)-prCVA.bic(1); %% get Bayesian info criteria, JUST USING 1st CAN VECTOR FOR NOW
            %gen_maxstat(maskedgrid_inside_ind(i))=prCVA.L(2)-prCVA.L(1); %% get Bayesian info criteria, JUST USING 1st CAN VECTOR FOR NOW
        case 'probCVAccorr'
            prCVA=spm_cva_compare(Yfull,S.design.X,S.design.contrast);
            gen_maxstat(maskedgrid_inside_ind(i))=prCVA.ccorr;
        case 'probCVAbic2'
            prCVA=spm_cva_compare(Yfull,S.design.X,S.design.contrast);
            gen_maxstat(maskedgrid_inside_ind(i))=prCVA.bic2(2);
            
        case 'Ttest'
            [t_stat,Beta,SE,F_stat] = gen_bf_ttest(S.design.X,Yfull,S.design.contrast);
            gen_maxstat(maskedgrid_inside_ind(i))=t_stat;
        case 'Beta'
            [t_stat,Beta,SE,F_stat] = gen_bf_ttest(S.design.X,Yfull,S.design.contrast);
            gen_maxstat(maskedgrid_inside_ind(i))=Beta; %% this works  because Y has unit variance (See above) throughout the brain
        otherwise
            error('undefined stattype');
    end;
    
    
    if i/100==floor(i/100)
        disp(sprintf('done %s stats for %3.2f percent ',S.stattype,100*i/length(maskedgrid_inside_ind)));
    end; % if
   
    opstats.Yfull=Yfull; %% sometimes will be evaluating at a single (seed) voxel
    
    if S.return_weights,
    opstats.ctf_weights(i,:)=weights;
   
    
    end;
    opstats.vedata=vedata;
    alllf(i,:)=lf;
    
    
end; % for grid points


%% GET NUMBER OF UNIQUE EXTREMA- ONLY WORKS FOR SPECIFIC GRAD TYPES (mag or axial)

[maxvals,maxind]=max(alllf');
[minvals,minind]=max(-alllf');


lead_extrema=[maxind' minind'];
lead_extrema=sort(lead_extrema')'; %% doesn't matter if extrema are reversed
u_extrema=unique(lead_extrema,'rows');
Nu_extrema=size(u_extrema,1)

dispthresh_mv=max(gen_maxstat)/2; % default display thresholds
testalpha=0.05;

if isfield(cva,'df'),
    opstats.alyt_thresh_Chi_05=spm_invXcdf(1-testalpha/Nu_extrema,cva.df(1));
    if S.volcorrect
        dispthresh_mv=opstats.alyt_thresh_Chi_05;
    end;
end;
opstats.maskedgrid_inside_ind=maskedgrid_inside_ind;
opstats. gen_maxstat=gen_maxstat;

%opstats(fband).CVAotherdim=CVA_otherdim;
opstats.fHz=dctfreq;
%opstats.cva=cva;
opstats.alllf=alllf;



csource=grid; %% only plot and write out unpermuted iteration
ctfpositions=csource.pos;

csource.genstat(csource.inside) = gen_maxstat;


csource.genstat(csource.outside)=0;

csource.pos = mripositions;

if isempty(S.gridpos), %% only write images if they use whole volume
    
    
    cfg1 = [];
    cfg1.sourceunits   = 'mm';
    cfg1.parameter = 'genstat';
    cfg1.downsample = 1;
    sourceint_genstat = ft_sourceinterpolate(cfg1, csource, sMRI);
    
    
    
    opstats.Nu_extrema=Nu_extrema;
    
    
    
    
    %% else %% write out the data sets
    disp('writing images');
    
    cfg = [];
    cfg.sourceunits   = 'mm';
    cfg.parameter = 'pow';
    cfg.downsample = 1;
    dirname=['Bf_' S.stattype S.datatype];
    
    res = mkdir(D.path, dirname);
        
    outvol = spm_vol(sMRI);
    outvol.dt(1) = spm_type('float32');
    featurestr=[S.filenamestr freqstr] ;
    outvol.fname= fullfile(D.path, dirname, [S.stattype  spm_str_manip(D.fname, 'r') '_' featurestr '.nii']);
    opstats.outfile_chi_pw=outvol.fname;
    outvol = spm_create_vol(outvol);
    spm_write_vol(outvol, sourceint_genstat.genstat);
    cmap=colormap;
    jetmap=colormap('jet');
    if (isfield(S, 'preview') && S.preview)
        spm_check_registration(sMRI);
        prop=0.4;
        colourmap=jetmap;
        spm_orthviews('Addtruecolourimage',1,outvol.fname,colourmap,prop,dispthresh_mv+1,dispthresh_mv);
        %disp(sprintf('Chi pw image. Est thresh for p<0.05 (corr) is %3.2f. Press any key to continue..',opstats(fband).alyt_thresh_Chi_05(2)));
        %pause;
    end; % if preview
    
    
    
    
    
end; % if ~S.gridpos



end % main function

function [t_stat,B,SE,F_stat] = gen_bf_ttest(X,Y,c,U)
% Run a t-test

if nargin<4,
    U=[];
end;
if isempty(U),
    U=eye(size(Y,2));
end;

X0  = X - X*c*pinv(c);  %% make sure X0 is orthogonal to X
Xred   = full(X*c); %% reduced design matrix
X0  = spm_svd(X0); %% X0 is null space i.e. everything that is happening in other columns of X

%   ==========================================================================
% remove null space of contrast
%--------------------------------------------------------------------------
Y     = Y - X0*(X0'*Y); %% eg remove DC level or drift terms from all of Y
Xred     = Xred - X0*(X0'*Xred);

P     = pinv(Xred);


[n,b] = size(Xred);
[n,m] = size(Y); %% n is number of epochs, m is number of features
b     = rank(Xred);
h     = min(b,m); %% either number of features or rank of X

Ym=mean(Y,2);
B  = pinv(Xred)*Ym;
RSS   = sum((Ym - Xred*B).^2);
MRSS  = RSS / (n-b);
SE    = sqrt(MRSS*(pinv(Xred'*Xred)));
t_stat=B./SE;
F_stat=(B./SE).^2;

end




function [chi,BIC,cva] = gen_bf_cva(X,Y,c,U)
%function [chi,cva,t_stat] = gen_bf_cva(X,Y,c,U)
% CVA. See Chatfield and Collins

if nargin<4,
    U=[];
end;
if isempty(U),
    U=eye(size(Y,2));
end;

X0  = X - X*c*pinv(c);  %% make sure X0 is orthogonal to X
Xred   = full(X*c); %% reduced design matrix
X0  = spm_svd(X0); %% X0 is null space i.e. everything that is happening in other columns of X

%-Canonical Variates Analysis
%   ==========================================================================
% remove null space of contrast
%--------------------------------------------------------------------------
Y     = Y - X0*(X0'*Y); %% eg remove DC level or drift terms from all of Y
Xred     = Xred - X0*(X0'*Xred);

P     = pinv(Xred);


[n,b] = size(Xred);
[n,m] = size(Y); %% n is number of epochs, m is number of features
b     = rank(Xred);
h     = min(b,m); %% either number of features or rank of X
f     = n - b - size(X0,2); %% number of epochs- rank(X) - number of confounds


% generalised eigensolution for treatment and residual sum of squares
%--------------------------------------------------------------------------
T     = Xred*(P*Y); %% predticon of Y based on X (P*Y is the coefficient)

SST   = T'*T;
SSR   = Y - T; %% residuals in Y (unexplained by X)
SSR   = SSR'*SSR;

[v,d] = eig(SSR\SST); %% explained/unexplained variance

[q,r] = sort(-real(diag(d)));
r     = r(1:h);
d     = real(d(r,r));
v     = real(v(:,r));
V     = U*v;                          % canonical vectors  (data)
v     = Y*v;                          % canonical variates (data)
W     = P*v;                          % canonical vectors  (design)
w     = Xred*W;                          % canonical variates (design)
%   C     = c*W;                          % canonical contrast (design)




% inference on dimensionality - p(i) test of D >= i; Wilk's Lambda := p(1)
%--------------------------------------------------------------------------

cval  = log(diag(d) + 1);
chi=[];df=[];p=[];p05thresh=[];
for i1 = 1:h
    chi(i1) = (f - (m - b + 1)/2)*sum(cval(i1:h));
    df(i1)  = (m - i1 + 1)*(b - i1 + 1); % m is the number of features, b is the rank of the design matrix
    p(i1)   = 1 - spm_Xcdf(chi(i1),df(i1));
    p05thresh(i1) = spm_invXcdf(1-0.05,df(i1));
end


ccorr=(W'*Xred'*Y*V)/sqrt((W'*Xred'*Xred*W)*(V'*Y'*Y*V));%% canonical correlation
ccorr=real(diag(ccorr));
BIC=n*log(1-ccorr.^2)+(b+m)*log(n); %http://www.sciencedirect.com/science/article/pii/S0167947311002660
% Comparison of penalty functions for sparse canonical correlation
% analysis,  Chalise , Brooke ,  Fridley: Computational Statistics and Data
% Analysis 2012, pp245-254
%% d=p+q, where x=N*p, Y=N*q

%BIC=-n*log(1-ccorr.^2);
cva.ccorr=ccorr;
cva.r=r;
cva.d=d;
cva.df=df;

cva.V=V;
cva.v=v;
cva.W=W;
cva.w=w;
%    cva.C=C;
cva.p05thresh=p05thresh;


end

