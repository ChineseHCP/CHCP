function [stats,mnipositions]=spm_eeg_ft_beamformer_lcmv_fusepca_cva(S)
% Compute power-based beamformer image
% FORMAT [stats,mnipositions]=spm_eeg_ft_beamformer_lcmv(S)
%
% returns a stats structure containing univariate t test on power (based
% purely on sign in first column of design matrix S.design.X)
% and a list of the image files produced
%__________________________________________________________________________
% Copyright (C) 2009 Wellcome Trust Centre for Neuroimaging

% Gareth Barnes, fusion and normalisation based on Mark Woolrich's
% ols_beamformer
% $Id: spm_eeg_ft_beamformer_lcmv_fusepca_cva.m 5136 2012-12-20 12:58:36Z vladimir $

[Finter,Fgraph] = spm('FnUIsetup','univariate LCMV beamformer for power', 0);
%%

%% ============ Load SPM EEG file and verify consistency
if nargin == 0
    S = [];
end


if ~isfield(S,'gridpos'),
    S.gridpos=[];
end;

if ~isfield(S,'maskgrid'),
    %%
    S.maskgrid=[];
end;


if ~isfield(S,'design'),
    error('Design matrix required');
end; % if

if ~isfield(S,'return_weights')
    ctf_weights=[];
    S.return_weights=0;
end

if ~isfield(S,'Niter')
    S.Niter=[];
end; % if

if isempty(S.Niter),
    S.Niter=1;
end; % if

if ~isfield(S,'weightttest'),
    S.weightttest=[];
end;

if ~isfield(S,'testbands'),
    S.testbands=[];
end;

if ~isfield(S,'gridpos'),
    if ~isfield(S,'gridstep');
        S.gridstep = spm_input('Grid step (mm):', '+1', 'r', '5');
    end;
end; % if

if ~isfield(S,'reducerank'),
    disp('reduce rank for MEG to tangential plane by default');
    
    S.reducerank=1;
end; %

if ~isfield(S,'detrend'),
    S.detrend=[];
end;

if isempty(S.detrend),
    disp('detrending data by default');
    S.detrend=1;
end; %

if ~isfield(S,'hanning'),
    S.hanning=[];
end;

if isempty(S.hanning),
    disp('windowing data by default');
    S.hanning=1;
end; %

if ~isfield(S,'logflag'),
    S.logflag=[];
end; % if

if isempty(S.logflag),
    S.logflag=0;
end; % if
%
if ~isfield(S,'CorrectPvals'),
    S.CorrectPvals=0;
end;

if ~isfield(S,'regpc'),
    S.regpc=[];
end; % if

if isempty(S.regpc),
    S.regpc=0;
end; % if


try
    D = S.D;
catch
    D = spm_select(1, 'mat', 'Select MEEG mat file');
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


modalities=S.modalities;


if ~isfield(D,'inv')
    errordlg('Need to set up a forward model before you start');
end;

if isfield(S, 'refchan') && ~isempty(S.refchan)
    refchan = S.refchan;
else
    refchan = [];
end

%% ============ Find or prepare head model

if ~isfield(D, 'val')
    D.val = 1;
end

if ~isfield(S,'filenamestr'),
    S.filenamestr=[];
end;%



def_colormap=colormap;
jetmap=colormap('jet');
colormap(def_colormap);

covest='concat_trials';  % HL Mod 4.1
if isfield(S,'covest')
    covest=S.covest;
end

covfun = @cov_standard; % AB Mod
if isfield(S,'covfun') && isa(S.covfun,'function_handle')
    covfun = S.covfun;
    
end %





Xdesign  =S.design.X;
c=S.design.contrast; %% c is contrast eg [ 0 1 -1] compare columns 2,3 of X




try S.design.X(:,1)-S.design.Xtrials-S.design.Xstartlatencies;
catch
    error('Design windows missepcified');
end;



outfilenames='';


freqrange=[];
if ~isfield(S, 'freq_range')
    error('need to supply frequency bands')
end


if isempty(S.testbands),
    S.testbands=S.freq_range; %% bands to do the test on
end; % if


Nbands=numel(S.freq_range);

if Nbands>1,
    error('only working for a single freq band at the moment');
end;


%% READ IN JUST THE DATA WE need
%% ASSUME THAT INPUT IS AS FOLLOWS
%% a list of trial types and latency ranges for 2 conditions/periods (active and
%% rest for now)
%% each condition has an associated time window which must of equal sizes
%% SO will have
%% a list of trial indices and latencies, a list of trial types of the same
%% length

try
    data = D.ftraw; %% convert to field trip format- direct memory map
catch
    disp('failed to read data directly.. going slowly');
    data = D.ftraw(0); %% convert to field trip format - file pointers
end;

%% setup channel_labels, which will be a list of the relevant
% channels/sensors, for use later in the Fieldtrip leadfield calculations
%%%%%%%%%%%%%%%

channel_labels=[];
chans=setdiff(D.meegchannels,D.badchannels); %LH
sta=1;

for ff=1:length(modalities),
    chan_ind_interleaved{ff}=[];
end;





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
        % interleaved, e.g. 3:3:306 MEG if MEG and MEGPLANAR, and 1:105 if just
        % MEG
        chan_ind_interleaved{ff}=[chan_ind_interleaved{ff} sta]; %
        sta=sta+1;
        channel_labels = [channel_labels D.chanlabels(chans(ch))]; % this is
    end;
end;





%% now read in the first trial of data just to get sizes of variables right
cfg=[];
cfg.keeptrials='no';
cfg.trials=1;


Ntrials=size(S.design.X,1);
cfg.latency=[S.design.Xstartlatencies(1) S.design.Xstartlatencies(1)+S.design.Xwindowduration];

subdata=ft_timelockanalysis(cfg,data);
Nsamples=length(subdata.time);
Nchans=length(channel_labels);


X0  = Xdesign - Xdesign*c'*pinv(c');  %% make sure X0 is orthogonal to X
Xdesign   = full(Xdesign*c');
X0  = spm_svd(X0); %% X0 is null space i.e. everything that is happening in other columns of X
dfe=Ntrials-rank(Xdesign);  % df test


if S.hanning,
    fftwindow=hamming(Nsamples);
else
    disp('not windowing');
    fftwindow=ones(Nsamples,1);
end;

allfftwindow=repmat(fftwindow,1,Nchans);
NumUniquePts = ceil((Nsamples+1)/2); %% data is real so fft is symmetric

if NumUniquePts<=2,
    error('Need to have more than 2 samples of data');
end;
fftnewdata=zeros(Ntrials,NumUniquePts,Nchans);
allepochdata=zeros(Ntrials,Nchans,Nsamples); %% for loading in data quickly

fHz = (0:NumUniquePts-1)*D.fsample/Nsamples;


if ~isfield(S,'Nfeatures'),
    Nfeatures=floor(Ntrials/3);
else
    Nfeatures=S.Nfeatures;
end;


%% now read in all trialtype and hold them as windowed fourier transforms
%%%%%%%%%%%%%%%
%% now read in all trials
[uniquewindows]=unique(S.design.Xstartlatencies);
Nwindows=length(uniquewindows);

for i=1:Nwindows,     %% puts trials into epoch data according to order of design.X structures
    winstart=uniquewindows(i); %% window start
    cfg=[];
    cfg.keeptrials='yes';
    % even though channel labels is (e.g.) 1-204 MEGPLANAR, 205-306 MEG,
    % allepochdata (and leadfields will be interleaved (e.g. MEG is
    % 3:3:306)
    cfg.channel=channel_labels;
    cfg.feedback='off';
    useind=find(winstart==S.design.Xstartlatencies); %% indices into design.X structures
    cfg.trials=S.design.Xtrials(useind); %% trials starting at these times
    cfg.latency=[winstart winstart+S.design.Xwindowduration];
    warning off;
    subdata=ft_timelockanalysis(cfg,data); % subset of original data
    warning on;
    allepochdata(useind,:,:)=squeeze(subdata.trial); %% get an epoch of data with channels in columns
end; % for i

%%%%%%%%%%%%%%
%% Now convert data into Fourier domain and bandpass and window and detrend (as specified)

allepochdata_old=allepochdata;

times=subdata.time;

for i=1:Ntrials, %% read in all individual trial types
    
    epochdata=permute(allepochdata(i,:,:),[2 3 1])';
    if S.detrend==1
        dtepochdata=detrend(epochdata); %% detrend epoch data, this includes removind dc level. NB. This will have an effect on specific evoked response components !
    else
        dtepochdata=epochdata; %% no dc removal, no detrend : this will have effect on accuracy of fourier estimate at non dc bins
    end; % detrend
    
    %figure;plot(dtepochdata);
    
    allepochdata(i,:,:)=dtepochdata';
    
    %dtepochdata=dtepochdata*allepochdata_prew; %% get an epoch of data with channels in columns
    
    wdtepochfft=dtepochdata.*allfftwindow; %% windowed
    
    
    epochfft=fft(wdtepochfft);
    
    fftnewdata(i,:,:)=epochfft(1:NumUniquePts,:); % .*filtervect';
end;

% if(~S.output_epochdata)
clear allepochdata; %% no longer needed
clear allepochdata_old;
% end;


if size(fftnewdata,3)~=Nchans,
    size(fftnewdata)
    error('Data dimension mismatch');
end;

%%%%%%%%%%%%%%%
%% Now setup leadfields using Fieldtrip call

% can deal with EEG only, or any combo of MEG only
if strcmp('EEG', modalities{1})
    chantype='EEG';
else
    chantype='MEG';
end;

for m = 1:numel(D.inv{D.val}.forward)
    if strncmp(chantype, D.inv{D.val}.forward(m).modality, 3)
        vol  = D.inv{D.val}.forward(m).vol;
        if isa(vol, 'char')
            vol = fileio_read_vol(vol);
        end
        datareg  = D.inv{D.val}.datareg(m);
    end
end

for m = 1:numel(D.inv{D.val}.forward)
    if strncmp(chantype, D.inv{D.val}.forward(m).modality, 3)
        mm=m;
    end;
end;

cfg                       = [];

if strcmp('EEG', D.inv{D.val}.forward(mm).modality)
    cfg.grad = D.inv{D.val}.datareg(mm).sensors; % in MRI space
else,
    cfg.grad = D.inv{D.val}.datareg(mm).sensors;  % in MEG space
end

disp('This should be in the direction (-1 1):');
cfg.grad.tra(1,1:2)

cfg.reducerank=3;
if(S.reducerank),
    if strcmp('EEG', D.inv{D.val}.forward(mm).modality)
        cfg.reducerank=3;
    else
        cfg.reducerank=2;
        disp('Reducing possible source orientations to a tangential plane for MEG');
    end
    
end;




cfg.channel = channel_labels;
cfg.vol                   = vol;



if  isempty(S.gridpos),
    cfg.grid.resolution            = S.gridstep;
else
    disp('USING pre-specified gridpoints');
    cfg.grid.pos=S.gridpos; %% predefined grid
    cfg.grid.inside=[1:size(S.gridpos,1)]; %% assume all in head
    cfg.grid.outside=[];
end;


cfg.feedback='off';
cfg.inwardshift           = 0; % mm
cfg.sourceunits = 'mm';

if ~isfield(S,'grid'),
    disp('preparing leadfield');
    grid                      = ft_prepare_leadfield(cfg);
    D.inv{1}.datareg(1).sensors.tra(1,1:2)
    
    % this bit is needed to correct for error in the fieldtrip code in
    % SPM8
    correct_grads=1;
    if(correct_grads)
        disp('correcting grad scaling');
        correct_factor=1/0.017; % gradiometer coils are 17mm apart
        
        imod=strmatch('MEGPLANAR',modalities);
        chan_ind_interleaved{imod}
        for i1=1:length(grid.inside),
            %  figure;
            %  plot(grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{2},:)); hold on;
            grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{imod},:)=grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{imod},:).*correct_factor;
            %  plot(grid.leadfield{grid.inside(i1)}(chan_ind_interleaved{2},:),':');
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




%% Now have all lead fields and all data
%% Now do actual beamforming
%% decide on the covariance matrix we need
%% construct covariance matrix within frequency range of interest

disp('now running over a SINGLE freq band and constructing t stat images');
fband=1; %% was originally a for loop

freqrange=S.freq_range{fband};
freq_ind=intersect(find(fHz>=freqrange(1)),find(fHz<freqrange(2)));
if length(freq_ind)<=1,
    disp(sprintf('Cannot use band %3.2f-%3.2f',freqrange(1),freqrange(2)));
    error('Need more than one frequency bin in the covariance band');
end
freqrangetest=S.testbands{fband};
Ntestbands=length(freqrangetest)/2;
if floor(Ntestbands)~=Ntestbands,
    error('Need pairs of values in testband');
end;
freq_indtest=[];
freq_teststr='';
for k=1:Ntestbands
    newtestind=intersect(find(fHz>=freqrangetest(k*2-1)),find(fHz<freqrangetest(k*2)));
    freq_indtest=[freq_indtest newtestind];
    freq_teststr=sprintf('%s %3.2f-%3.2fHz,',freq_teststr,fHz(min(newtestind)),fHz(max(newtestind)));
end; % for k
if length(setdiff(freq_indtest,freq_ind))>0,
    error('Bands in test band are not within covariance band')
end;
covtrial=zeros(Nchans,Nchans);
old=0;
%old=1; %% GRB MOD

used_maxfilter_multiplier=1;
if(~old), %% rescale different modalities to approx equivalent magnitures and rescale lead fields accordingly
    offtnewdata=fftnewdata;
    for ff=1:length(modalities),
        dat=reshape(permute(fftnewdata(:,freq_ind,chan_ind_interleaved{ff}),[1 2 3]),[size(fftnewdata,1)*length(freq_ind) size(fftnewdata(:,:,chan_ind_interleaved{ff}),3)]);
        
        pca_dim=size(dat,2);
        
        if(S.used_maxfilter>0)
            pca_dim=min(pca_dim,S.used_maxfilter);
        end;
        
        [allsvd,Apca]=pca(dat,pca_dim);
        
        normalisation{ff}=sqrt(allsvd(end));
        disp(['Modality ' modalities{ff} ' has data normalisation ' num2str(normalisation{ff})]);
        
        td=fftnewdata(:,:,chan_ind_interleaved{ff});
        fftnewdata(:,:,chan_ind_interleaved{ff})=td/normalisation{ff};
    end;
    
    for i=1:length(maskedgrid_inside_ind),
        lf=cell2mat(grid.leadfield(grid.inside(maskedgrid_inside_ind(i))));
        lfn=lf;
        for ff=1:length(modalities),
            
            lfn(chan_ind_interleaved{ff},:)=lf(chan_ind_interleaved{ff},:)./normalisation{ff}; %% GRB MOD
        end;
        grid.leadfield{grid.inside(maskedgrid_inside_ind(i))}=lfn;
    end;
    
    used_maxfilter_multiplier=1;
end;

% D.inv{D.val}.leadfield=grid;
%D.inv{D.val}.leadfield.label= ['sens_' chantype '_fm_'  D.inv{D.val}.date(1,:) '_' D.inv{D.val}.date(2,:)]; %HL Mod to save leadfields for reuse to speed up beamformer.
%D.save;


if(S.regpc<0)  % HL Mod 4.2
    fftnewdata_expanded=zeros(Ntrials,2*length(freq_ind),Nchans);
    ffttrial = permute(fftnewdata(:,freq_ind,:),[2 3 1]);
    
    for i=1:Ntrials
        ffttrial_i = [imag(ffttrial(:,:,i))' real(ffttrial(:,:,i))']';
        if strcmp(covest,'average_trials')
            fftnewdata_expanded(i,:,:)=demean(ffttrial_i,1);
        else
            fftnewdata_expanded(i,:,:)=ffttrial_i;
        end
    end
end


% Get data corresponding to frequency band and concatenate if necessary
if strcmp(covest,'concat_trials')
    ffttrial = reshape(fftnewdata(:,freq_ind,:),[],size(fftnewdata,3));
elseif strcmp(covest,'average_trials')
    ffttrial = permute(fftnewdata(:,freq_ind,:),[2 3 1]);
end

% Compute covariance matrix over trials (1 trial now exists if concatentated)
covtrial=zeros(Nchans,Nchans);
for i = 1:size(ffttrial,3) % This indexes over trials
    ffttrial_i = ffttrial(:,:,i);
    covtrial = covtrial + feval(covfun,ffttrial_i,D,freq_ind,Nsamples);
end
covtrial=covtrial/size(ffttrial,3);
figure;imagesc(real(covtrial));colorbar;



    function cov_out = cov_standard(covdata,~,~,~)
        % Default covariance matrix calc - AB Mod
        covdata = [imag(covdata)' real(covdata)']';
        cov_out = cov(covdata);
    end


allsvd = svd(covtrial);
cumpower=cumsum(allsvd)./sum(allsvd);
nmodes95=min(find(cumpower>0.95));

pcadim=size(covtrial,1);
if S.used_maxfilter>0;
    pcadim=S.used_maxfilter*used_maxfilter_multiplier;
end;

if isfield(S,'regpc2') && S.regpc2>0
    allsvd2=allsvd(1:pcadim);
    tmp=allsvd2/sum(allsvd2)*100;
    tmp2=find(tmp>S.regpc2);
    pcadim=tmp2(end);
    disp(['Using top ' num2str(pcadim) ' PCs']);
    old=0;
end;




%     for i=1:Ntrials, %% read in all individual trial types
%         ffttrial=squeeze(fftnewdata(i,freq_ind,:)); % .*Allfiltervect;
%         covtrial=covtrial+real(cov(ffttrial));
%     end; % for i
%     covtrial=covtrial/Ntrials;
%     allsvd = svd(covtrial);
%     cumpower=cumsum(allsvd)./sum(allsvd);
%     nmodes99=min(find(cumpower>0.99));

disp(sprintf('95 percent of the power in this data is in the first %d principal components of the cov matrix',nmodes95));
disp(sprintf('largest/smallest eigenvalue=%3.2f',allsvd(1)/allsvd(end)));
disp(sprintf('\nFrequency resolution %3.2fHz',mean(diff(fHz))));
noise = allsvd(end); %% use smallest eigenvalue
noise_id=eye(size(covtrial)).*noise;
redNfeatures=[Nfeatures*2 Nfeatures]; %% NB major change

if redNfeatures(2)>length(freq_indtest),
    disp(sprintf('reducing number of  power features to match bandwidth (from %d to %d) !!',redNfeatures(2),length(freq_indtest)));
    redNfeatures(2)=length(freq_indtest);
end;
if redNfeatures(1)>length(freq_indtest)*2,    % more features in evoked case
    disp(sprintf('reducing number of evoked features to match bandwidth (from %d to %d) !!',redNfeatures(1),2*length(freq_indtest)));
    redNfeatures(1)=length(freq_indtest)*2;
end;


disp(['Nfeatures:',num2str(redNfeatures)]);

%%%%%%%%%%%%%%%
%% regularise data covariance estimate by a specified amount
lambda=0;

%lambda = S.regpc/100 * min(allsvd(1:pcadim)); % regularise by min eigenvalue;
%% GRB MOD
lambda = (S.regpc/100) * sum(allsvd)/size(covtrial,1); %% scale lambda relative mean eigenvalue


disp(sprintf('regularisation relative to mean (Not min as in OLS) eigenvalue=%3.2f percent',S.regpc));
covtrial2=covtrial+eye(size(covtrial,1))*lambda;

if(S.regpc>0),
    covtrial=covtrial2;
    old=0;
end;

%%%%%%%%%%%%%%%
%% override classical data covariance estimate with a Bayesian PCA estimate

need_invC=1;

if(S.regpc==-1)
    
    covtrial_classical=covtrial;
    
    dat=squeeze(fftnewdata_expanded);
    
    %dat=squeeze(fftnewdata(:,freq_ind,:));
    
    if(Ntrials>1)
        dat=reshape(dat,size(dat,1)*size(dat,2),size(dat,3));
    end;
    
    dims2use=min(size(dat,1),round(3*size(dat,2)/4));
    
    if(S.used_maxfilter>0)
        dims2use=min(dims2use,length(modalities)*S.used_maxfilter);
    end;
    
    %[m_w, alpha, covtrial, taus, tau, m_x, Sigma_w, Sigma_x, Q, N, DD,alphamin,alphamax]=bayes_pca(demean(dat,1)',dims2use,40,Ntrials);
    
    [m_w, alpha, covtrial, cinv, taus, tau, m_x, Sigma_w, Sigma_x, Q, N, Dd,alphamin,alphamax]=bayes_pca_ss(demean(dat,1)',dims2use,40,Ntrials);
    need_invC=0;
    
    maxw = min(find(alpha>((alpha(1)*alphamax)^(1/2))))-1;
    
    if(isempty(maxw))
        maxw=1;
    end;
    
    if(maxw<1)
        maxw=1;
    end;
    
    beamformer_results.alpha=alpha;
    beamformer_results.tau=tau;
    beamformer_results.taus=taus;
    
    maxw
end;

%ocinv=cinv;
%%%%%%%%%%%%%%%
%% compute inverse of data cov matrix
if(S.regpc~=-1),
    %     if(need_invC) %% redundant as not used if S.regpc==-1;
    %         if(S.used_maxfilter>0),
    %
    %             [cinv, tol, rnk] = mwpinv(covtrial,min(S.used_maxfilter*used_maxfilter_multiplier,maxw),0); %% get inverse doing pinv with max rank of rank
    %
    %
    %             maxw = rnk;
    %
    %         else,
    %
    %             [cinv, tol, rnk] = mwpinv(covtrial,maxw,0); %% get inverse doing pinv with max rank of rank
    %
    %             maxw = rnk;
    %
    %         end;
    %     end;
    % else
    if(S.used_maxfilter>0),
        
        if(old)
            [cinv, tol, rnk] = mwpinv_old(covtrial,pcadim,0); %% get inverse doing pinv with max rank of rank
        else
            [cinv, tol, rnk] = mwpinv(covtrial,pcadim,0); %% get inverse doing pinv with max rank of rank
        end;
        
        maxw = rnk;
        
    else,
        
        cinv=mwpinv(covtrial,pcadim,0);
        
        maxw = size(covtrial,1);
        
    end;
    
end;

disp(['rank=' num2str(maxw)]);



CVA_maxstat=zeros(length(grid.inside),2,S.Niter);
roymax=zeros(size(CVA_maxstat));

tstat=zeros(length(grid.inside),2,S.Niter);
maxcva=zeros(2,S.Niter);
power_trial=zeros(Ntrials,length(freq_indtest));
evoked_trial=zeros(Ntrials,length(freq_indtest));


TrueIter=1; %% no permutation for this iteration
for j=1:S.Niter, %% set up permutations in advance- so perms across grid points are identical
    randind(j,:)=randperm(Ntrials);
    if j==TrueIter,
        randind(j,:)=1:Ntrials; % don't permute first run
    end;
end;


for i=1:length(maskedgrid_inside_ind), %% 81
    lf=cell2mat(grid.leadfield(grid.inside(maskedgrid_inside_ind(i))));
    
    %% get optimal orientation- direct copy from Robert's beamformer_lcmv.m
    projpower_vect=pinv(lf'*cinv*lf);
    [u, s, v] = svd(real(projpower_vect));
    eta = u(:,1);
    lf  = lf * eta; %% now have got the lead field at this voxel, compute some contrast
    weights=lf'*cinv/(lf'*cinv*lf); %% CORRECT WEIGHTS CALC
    
    
    stats(fband).ctf_weights(maskedgrid_inside_ind(i),:)=weights;
    alllf(maskedgrid_inside_ind(i),:)=lf;
    
    %%%%%%%%%%%%%%CVA PASTE
    for j=1:Ntrials, %% this non-linear step (power estimation) has to be done at each location
        fdata=squeeze(fftnewdata(j,freq_indtest,:));
        if length(freq_indtest)==1,
            fdata=fdata';
        end; % if length
        fdatatrial=fdata*weights';
        evoked_trial(j,:)=fdatatrial;
        if S.logflag,
            power_trial(j,:)=log(fdatatrial.*conj(fdatatrial));
        else
            power_trial(j,:)=fdatatrial.*conj(fdatatrial); %%
        end; % i
        
    end; % for j
    
    
    
    for power_flag=0:1,
        if power_flag,
            Yfull=power_trial;
        else
            Yfull=[real(evoked_trial), imag(evoked_trial)]; %% split into sin and cos parts
        end; % if power_fla
        Y     = Yfull - X0*(X0'*Yfull); %% eg remove DC level or drift terms from all of Y
        %[u s v] = spm_svd(Y,-1,-1); % ,1/4);              %% get largest variance in Y   -1s make sure nothing is removed
        
        %% reduce dimensions to Nfeatures
        [u,s,v]=svd(Y'*Y); %% reduce dimensions of useful signal
        
        U=u(:,1:redNfeatures(power_flag+1));
        Y   = Y*U;
        
        
        
        %% Now permute the rows of X if necessary
        for iter=1:S.Niter,
            
            X=Xdesign(randind(iter,:),:); %% randind(1,:)=1, i.e. unpermuted
            
            
            
            
            
            %-Canonical Variates Analysis
            %   ==========================================================================
            % remove null space of contrast
            %--------------------------------------------------------------------------
            Y     = Y - X0*(X0'*Y); %% eg remove DC level or drift terms from all of Y
            X     = X - X0*(X0'*X);
            P     = pinv(X);
            
            
            
            [n,b] = size(X);
            [n,m] = size(Y); %% n is number of epochs, m is number of features
            b     = rank(X);
            h     = min(b,m); %% either number of features or rank of X
            f     = n - b - size(X0,2); %% number of epochs- rank(X) - number of confounds
            
            
            
            % generalised eigensolution for treatment and residual sum of squares
            %--------------------------------------------------------------------------
            T     = X*(P*Y); %% predticon of Y based on X (P*Y is the coefficient)
            
            SST   = T'*T;
            SSR   = Y - T; %% residuals in Y (unexplained by X)
            SSR   = SSR'*SSR;
            lastwarn('')
            [v,d] = eig(SSR\SST); %% explained/unexplained variance
            
            [lastmsg, LASTID] = lastwarn;
            if ~isempty(lastmsg),
                disp('rank problem, zeroing eigenvals');
                d=zeros(size(d));
            end;
            
            [q,r] = sort(-real(diag(d)));
            r     = r(1:h);
            d     = real(d(r,r));
            v     = real(v(:,r));
            V     = U*v;                          % canonical vectors  (data)
            v     = Y*v;                          % canonical variates (data)
            W     = P*v;                          % canonical vectors  (design)
            w     = X*W;                          % canonical variates (design)
            C     = c*W;                          % canonical contrast (design)
            
            
            
            
            % inference on dimensionality - p(i) test of D >= i; Wilk's Lambda := p(1)
            %--------------------------------------------------------------------------
            roymax(maskedgrid_inside_ind(i),power_flag+1,iter)=d(1,1); %% maximum root is the first one
            Roy2F=(f+m-max(b,m))/max(b,m); %% conversion from Roy's max root to F
            
            
            cval  = log(diag(d) + 1);
            chi=[];df=[];p=[];p05thresh=[];
            for i1 = 1:h
                chi(i1) = (f - (m - b + 1)/2)*sum(cval(i1:h));
                df(i1)  = (m - i1 + 1)*(b - i1 + 1); % m is the number of features, b is the rank of the design matrix
                p(i1)   = 1 - spm_Xcdf(chi(i1),df(i1));
                p05thresh(i1) = spm_invXcdf(1-0.05,df(i1));
            end
            
            
            CVA_maxstat(maskedgrid_inside_ind(i),power_flag+1,iter)=chi(1); %% get wilk's lambda stat
            CVA_otherdim(maskedgrid_inside_ind(i),power_flag+1,iter,1:h-1)=chi(2:h); %% tests on other dimensions
            
            if CVA_maxstat(maskedgrid_inside_ind(i),power_flag+1,iter)>maxcva(power_flag+1,iter),
                stats(fband).bestchi(power_flag+1,1:h,iter)=chi;
                
                if power_flag,
                    stats(fband).bestVpw(1:h,iter,:)=V';
                    stats(fband).bestvpw(1:h,iter,:)=v';
                    stats(fband).bestUpw=U;
                    stats(fband).maxw_pw=w;
                    stats(fband).maxW_pw=W;
                    
                else
                    stats(fband).bestVev(1:h,iter,:)=complex(V(1:size(evoked_trial,2),:),V(size(evoked_trial,2)+1:end,:))';
                    stats(fband).bestvev(1:h,iter,:)=v';
                    stats(fband).bestUev=U;
                    stats(fband).maxw_ev=w;
                    stats(fband).maxW_ev=W;
                    
                end;
                
                
                stats(fband).pval(power_flag+1,1:h,iter)=p;
                stats(fband).df(power_flag+1,1:h,iter)=df;
                stats(fband).p05alyt(power_flag+1,1:h)=p05thresh;
                stats(fband).maxind(power_flag+1,iter)=maskedgrid_inside_ind(i);
                stats(fband).freqHz=fHz(freq_indtest);
                stats(fband).freq_indtest=freq_indtest;
                stats(fband).freq_ind=freq_ind;
                maxcva(power_flag+1,iter)=CVA_maxstat(maskedgrid_inside_ind(i),power_flag+1,iter);
            end; % if CVA_Stat
            if (iter==TrueIter) && (length(V)>1),
                if power_flag,
                    stats(fband).allVpw(1:h,i,:)=V';
                else
                    stats(fband).allVev(1:h,i,:)=complex(V(1:size(evoked_trial,2),:),V(size(evoked_trial,2)+1:end,:))';
                end;
            end;% if iter
            
        end; % for Niter
        
        
        
    end; % for power_flag
    
    if i/100==floor(i/100)
        disp(sprintf('done CVA stats for %3.2f percent of freq band %d of %d, log=%d',100*i/length(maskedgrid_inside_ind),fband,Nbands,S.logflag));
    end; % if
    
    
    %%%%%%%%%%%%%%%%%%END PASTE
    
    
    
end; % for grid points

%%PASTE

%% GET NUMBER OF UNIQUE EXTREMA- ONLY WORKS FOR SPECIFIC GRAD TYPES (mag or axial)
alpha=0.05; %% for display only
%[alyt_thresh_Chi,Nu_extrema,overlap_ind,overlap_pos]=correction_for_ROI(roi_str,talpositions,alllf,alpha,redNfeatures(1)*b)

[maxvals,maxind]=max(alllf');
[minvals,minind]=max(-alllf');


lead_extrema=[maxind' minind'];
lead_extrema=sort(lead_extrema')'; %% doesn't matter if extrema are reversed
u_extrema=unique(lead_extrema,'rows');
Nu_extrema=size(u_extrema,1)

stats(fband).maskedgrid_inside_ind=maskedgrid_inside_ind;
stats(fband).CVAmax=CVA_maxstat;
stats(fband).CVAotherdim=CVA_otherdim;
stats(fband).roymax=roymax;
stats(fband).Roy2F=Roy2F;
%stats(fband).allw=allw;
stats(fband).tstat=tstat.^2;
stats(fband).fHz=fHz;
stats(fband).dfmisc=[b h m];
dispthresh_mv=max(stats(fband).CVAmax)/2; % default display thresholds
max_mv=max(stats(fband).CVAmax); % default display thresholds

if S.Niter>1,
    %% get corrected p values for CVA
    allglobalmax=squeeze(max(stats(fband).CVAmax(:,:,1:end)));
    [sortglobalmax,sortglobalmaxind]=sort(allglobalmax','descend');
    allglobalmax_roy=squeeze(max(stats(fband).roymax(:,:,1:end)));
    [sortglobalmax_roy,sortglobalmaxind_roy]=sort(allglobalmax_roy','descend');
    
    for k=1:2,
        stats(fband).corrpmax_cva(k)=find(sortglobalmaxind(:,k)==TrueIter)/length(sortglobalmaxind);
        stats(fband).corrpmax_roy(k)=find(sortglobalmaxind_roy(:,k)==TrueIter)/length(sortglobalmaxind_roy);
    end;
    stats(fband).thresh05globalmax_cva=sortglobalmax(round(length(sortglobalmaxind)*5/100),:);
    stats(fband).thresh05globalmax_roy=sortglobalmax_roy(round(length(sortglobalmaxind)*5/100),:);
    dispthresh_mv=stats(fband).thresh05globalmax_cva; % display only significant effects
end; % if



%

csource=grid; %% only plot and write out unpermuted iteration
gridpositions=csource.pos(csource.inside,:);
csource.pow_maxchi(csource.inside) = CVA_maxstat(:,2,TrueIter);  %power
log_pvals_corr_pow=log(1-spm_Xcdf(CVA_maxstat(:,2,TrueIter),redNfeatures(2)*b));
if S.CorrectPvals,
    log_pvals_corr_pow=log_pvals_corr_pow+log(Nu_extrema); %% multiply by number of comparisons
    log_pvals_corr_pow(find(log_pvals_corr_pow>0))=0;
end; % if

csource.logp_power(csource.inside) = -log_pvals_corr_pow; %% write negative log so that largest image values have high significance
%spm_Xcdf(1-alpha/(stats(fband).Nu_extrema),redNfeatures(1)*b)
csource.evoked_maxchi(csource.inside) = CVA_maxstat(:,1,TrueIter); % evoked
log_pvals_corr_evoked=log(1-spm_Xcdf(CVA_maxstat(:,1,TrueIter),redNfeatures(1)*b));
if S.CorrectPvals,
    log_pvals_corr_evoked=log_pvals_corr_evoked+log(Nu_extrema); %% multiply by number of comparisons
    log_pvals_corr_evoked(find(log_pvals_corr_evoked>0))=0;
end; % if

csource.logp_evoked(csource.inside) = -log_pvals_corr_evoked;


csource.pow_maxchi(csource.outside)=0;
csource.evoked_maxchi(csource.outside)=0;
csource.logp_evoked(csource.outside)=0;
csource.logp_power(csource.outside)=0;

csource.pos = spm_eeg_inv_transform_points(datareg.toMNI, csource.pos);


sMRI = fullfile(spm('dir'), 'canonical', 'single_subj_T1.nii');
mnipositions = spm_eeg_inv_transform_points(datareg.toMNI, grid.pos(grid.inside,:)); %% MADE DATAREG STAND ALONE

if isempty(S.gridpos), %% only write images if they use whole volume
    
    
    cfg1 = [];
    cfg1.sourceunits   = 'mm';
    cfg1.parameter = 'pow_maxchi';
    cfg1.downsample = 1;
    sourceint_pow_maxchi = ft_sourceinterpolate(cfg1, csource, ft_read_mri(sMRI, 'format', 'nifti_spm'));
    
    cfg1 = [];
    cfg1.sourceunits   = 'mm';
    cfg1.parameter = 'evoked_maxchi';
    cfg1.downsample = 1;
    sourceint_evoked_maxchi = ft_sourceinterpolate(cfg1, csource, ft_read_mri(sMRI, 'format', 'nifti_spm'));
    
    
    cfg1 = [];
    cfg1.sourceunits   = 'mm';
    cfg1.parameter = 'logp_power';
    cfg1.downsample = 1;
    sourceint_logp_pow = ft_sourceinterpolate(cfg1, csource, ft_read_mri(sMRI, 'format', 'nifti_spm'));
    
    cfg1 = [];
    cfg1.sourceunits   = 'mm';
    cfg1.parameter = 'logp_evoked';
    cfg1.downsample = 1;
    sourceint_logp_evoked = ft_sourceinterpolate(cfg1, csource, ft_read_mri(sMRI, 'format', 'nifti_spm'));
    
    
    
    stats(fband).Nu_extrema=Nu_extrema;
    
    stats(fband).alyt_thresh_Chi_05(1)=spm_invXcdf(1-alpha/(stats(fband).Nu_extrema),redNfeatures(1)*b); %% estimate of volumetric threshold for evoked
    stats(fband).alyt_thresh_Chi_05(2)=spm_invXcdf(1-alpha/(stats(fband).Nu_extrema),redNfeatures(2)*b); %% estimate of volumetric thres for induced
    
    
    
    
    
    %% else %% write out the data sets
    disp('writing images');
    
    cfg = [];
    cfg.sourceunits   = 'mm';
    cfg.parameter = 'pow';
    cfg.downsample = 1;
    dirname='cvaBf_images';
    if S.logflag,
        dirname=[dirname '_log'];
    end;
    
    res = mkdir(D.path, dirname);
    outvol = spm_vol(sMRI);
    outvol.dt(1) = spm_type('float32');
    featurestr=[S.filenamestr 'Nf' num2str(redNfeatures(2))] ;
    
    outvol.fname= fullfile(D.path, dirname, ['chi_pw_'  spm_str_manip(D.fname, 'r') '_' num2str(freqrange(fband,1)) '-' num2str(freqrange(fband,2)) 'Hz' featurestr '.nii']);
    stats(fband).outfile_chi_pw=outvol.fname;
    outvol = spm_create_vol(outvol);
    spm_write_vol(outvol, sourceint_pow_maxchi.pow_maxchi);
    cmap=colormap;
    jetmap=colormap('jet');
    if (isfield(S, 'preview') && S.preview)
        spm_check_registration(sMRI)
        prop=0.4;
        colourmap=jetmap;
        spm_orthviews('Addtruecolourimage',1,outvol.fname,colourmap,prop,max_mv(2),dispthresh_mv(2));
        disp(sprintf('Chi pw image. Est thresh for p<0.05 (corr) is %3.2f. Press any key to continue..',stats(fband).alyt_thresh_Chi_05(2)));
        pause;
    end; % if preview
    colormap(cmap);
    featurestr=[S.filenamestr 'Nf' num2str(redNfeatures(1))] ;
    outvol.fname= fullfile(D.path, dirname, ['chi_ev_' spm_str_manip(D.fname, 'r') '_' num2str(freqrange(fband,1)) '-' num2str(freqrange(fband,2)) 'Hz' featurestr '.nii']);
    stats(fband).outfile_chi_ev=outvol.fname;
    outvol = spm_create_vol(outvol);
    spm_write_vol(outvol, sourceint_evoked_maxchi.evoked_maxchi);
    
    if (isfield(S, 'preview') && S.preview)
        spm_check_registration(sMRI)
        prop=0.4;
        colourmap=jetmap;
        spm_orthviews('Addtruecolourimage',1,outvol.fname,colourmap,prop,max_mv(1),dispthresh_mv(1));
        disp(sprintf('Chi ev image. Est thresh for p<0.05 (corr) is %3.2f. Press any key to continue..',stats(fband).alyt_thresh_Chi_05(1)));
        pause;
    end; % if preview
    
    outvals=CVA_maxstat(:,1,TrueIter);
    %  prefix='testrun';
    %[outvol]=write_trial_image(0,0,talpositions,datareg,sMRI,D,dirname,csource,outvals,prefix,freqrange(fband,:))
    colormap(cmap);
    
    featurestr=[S.filenamestr 'Nf' num2str(redNfeatures(2))] ;
    outvol.fname= fullfile(D.path, dirname, ['logp_pow_' spm_str_manip(D.fname, 'r') '_' num2str(freqrange(fband,1)) '-' num2str(freqrange(fband,2)) 'Hz' featurestr S.filenamestr '.nii']);
    stats(fband).outfile_logp_pow=outvol.fname;
    outvol = spm_create_vol(outvol);
    spm_write_vol(outvol, sourceint_logp_pow.logp_power);
    featurestr=[S.filenamestr 'Nf' num2str(redNfeatures(1))] ;
    outvol.fname= fullfile(D.path, dirname, ['logp_evoked_' spm_str_manip(D.fname, 'r') '_' num2str(freqrange(fband,1)) '-' num2str(freqrange(fband,2)) 'Hz' featurestr S.filenamestr '.nii']);
    stats(fband).outfile_logp_evoked=outvol.fname;
    outvol = spm_create_vol(outvol);
    spm_write_vol(outvol, sourceint_logp_evoked.logp_evoked);
    
    % %% now write all trials of data out
    
    
    
end; % if ~S.gridpos




end % function




%% END PASTE


