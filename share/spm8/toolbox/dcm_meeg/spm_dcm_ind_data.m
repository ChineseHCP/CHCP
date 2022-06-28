function DCM = spm_dcm_ind_data(DCM)
% gets time-frequency amplitude at specified sources for DCM
% FORMAT DCM = spm_dcm_ind_data(DCM)
% DCM    -  DCM structure
% requires
%
%    DCM.xY.Dfile
%    DCM.Lpos
%    DCM.options.Nmodes
%    DCM.options.trials
%    DCM.options.Tdcm
%    DCM.options.Fdcm
%    DCM.options.D
%    DCM.options.Rft
%    DCM.options.h
%
% sets
%
%    DCM.xY.pst     - Peristimulus Time [ms] of time-frequency data
%    DCM.xY.dt      - sampling in seconds [s]
%    DCM.xY.y       - concatenated induced response over sources
%    DCM.xY.xf      - induced response over sources
%    DCM.xY.It      - Indices of time bins
%    DCM.xY.Ic      - Indices of good channels
%    DCM.xY.Hz      - Frequency bins (for Wavelet transform)
%    DCM.xY.Mz      - Mean frequency response over trial and sources
%    DCM.xY.Rft     - wavelet coefficient
%    DCM.xY.Nm      - number of frequency modes
%    DCM.xY.U       - Frequency modes
%    DCM.xY.S       - and their singular values
%
%    DCM.xY.y{i}(k,l)    = l-th region X frequency mode (fast over regions)
%                          k-th time-bin
%                          i-th trial
%
%    DCM.xY.xf{i,j}(k,l) = l-th frequency mode
%                          k-th time-bin
%                          j-th region
%                          i-th trial
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_dcm_ind_data.m 4567 2011-11-23 12:13:01Z spm $
 
% Set defaults and Get D filename
%-------------------------------------------------------------------------
try
    Dfile = DCM.xY.Dfile;
catch
    errordlg('Please specify data and trials');
    error('')
end
 
if strcmp(Dfile, 'custom')
    return;
end
 
% load D
%--------------------------------------------------------------------------
D = spm_eeg_load(Dfile);
 
% indices of EEG channel (excluding bad channels)
%--------------------------------------------------------------------------
if ~isfield(DCM.xY, 'modality')
    [mod, list] = modality(D, 0, 1);
    
    if isequal(mod, 'Multimodal')
        qstr = 'Only one modality can be modelled at a time. Please select.';
        if numel(list) < 4
            options             = [];
            options.Default     = list{1};
            options.Interpreter = 'none';
            DCM.xY.modality     = questdlg(qstr, 'Select modality', list{:}, options);
        else
            % to accommodate more buttons
            %--------------------------------------------------------------
            ind = menu(qstr, list);
            DCM.xY.modality = list{ind};
        end
    else
        DCM.xY.modality = mod;
    end
end
 
TFinput = isequal(D.transformtype, 'TF');
 
if  ~isfield(DCM.xY,'Ic')
    Ic        = setdiff(D.meegchannels(DCM.xY.modality), D.badchannels);
    DCM.xY.Ic = Ic;
end
Ic   = DCM.xY.Ic;
Nc   = length(DCM.xY.Ic);
 
% options
%--------------------------------------------------------------------------
try, Nm  = DCM.options.Nmodes; catch, Nm  = 4; DCM.options.Nmodes = Nm; end
try, h   = DCM.options.h;      catch, h   = 1; DCM.options.h      = h;  end
try, DT  = DCM.options.D;      catch, DT  = 2; DCM.options.D      = DT; end
try, DT  = DCM.options.D;      catch, DT  = 2; DCM.options.D      = DT; end
try, Rft = DCM.options.Rft;    catch, Rft = 6; DCM.options.Rft    = Rft;end

try
    trial = DCM.options.trials;
catch
    errordlg('please specify trials');
    error('')
end

% check data are not oversampled (< 4ms)
%--------------------------------------------------------------------------
if DT/D.fsample < 0.004
    DT            = ceil(0.004*D.fsample);
    DCM.options.D = DT;
end
 


% get peristimulus times
%--------------------------------------------------------------------------
try
    DCM.options.Tdcm(1) = max(DCM.options.Tdcm(1),1000*D.time(1));
    DCM.options.Tdcm(2) = min(DCM.options.Tdcm(2),1000*D.time(end));
catch
    DCM.options.Tdcm(1) = 1000*D.time(1)   + 512;
    DCM.options.Tdcm(2) = 1000*D.time(end) - 512;
end

% time window and bins for modelling (with 512 ms extra)
%--------------------------------------------------------------------------
DCM.xY.Time = 1000*D.time;

ms          = DCM.options.Tdcm(1) - DCM.xY.Time(1);
ms          = max(min(ms,512),64);
T1          = DCM.options.Tdcm(1) - ms;
T2          = DCM.options.Tdcm(2) + ms;
[i, T1]     = min(abs(DCM.xY.Time - T1));
[i, T2]     = min(abs(DCM.xY.Time - T2));
B1          = T1 + fix(ms*D.fsample/1000);
B2          = T2 - fix(ms*D.fsample/1000);


% check data are not oversampled (< 4ms)
%--------------------------------------------------------------------------
if (T2 - T1)/DT > 256
    DT            = fix((T2 - T1)/128);
end
DCM.options.D = DT;

% Time [ms] of down-sampled data
%--------------------------------------------------------------------------
It          = [T1:DT:T2]';               % indices - bins (full)
Ib          = [B1:DT:B2]';               % indices - bins (pst)
Is          = [T1:T2]';                  % indices - samples
Ns          = length(Is);                % number of samples
Nt          = length(It);                % number of bins (full)
Nb          = length(Ib);                % number of bins (pst)
DCM.xY.pst  = DCM.xY.Time(Ib);           % PST
DCM.xY.It   = Ib;                        % indices of time bins
DCM.xY.dt   = DT/D.fsample;              % sampling in seconds
Id          = (1:Nb) + fix((Ib(1) - It(1) + 1)/DT);


 
% get frequency range
%--------------------------------------------------------------------------
try
    Hz1     = DCM.options.Fdcm(1);          % lower frequency
    Hz2     = DCM.options.Fdcm(2);          % upper frequency
catch
    pst     = DCM.xY.pst(end) - DCM.xY.pst(1);
    Hz1     = max(ceil(2*1000/pst),4);
    if Hz1 < 8;
        Hz2 = 48;
    else
        Hz2 = 128;
    end
end
 
if TFinput
    DCM.xY.Hz = D.frequencies;
    DCM.xY.Hz = DCM.xY.Hz(DCM.xY.Hz>=Hz1 & DCM.xY.Hz<=Hz2);
else
    if (Hz2 - Hz1) > 64, HzD = 2; else, HzD = 1; end
    DCM.xY.Hz  = Hz1:HzD:Hz2;          % Frequencies
end
 
DCM.xY.Nm  = Nm;                       % number of frequency modes
dt         = 1000/D.fsample;           % sampling interval (ms)
Nf         = length(DCM.xY.Hz);        % number of frequencies
if isequal(DCM.xY.modality, 'LFP')
    Nr = Nc;
else
    Nr = size(DCM.C,1);                % number of sources
end
Ne     = length(trial);                % number of ERPs
Nm     = DCM.xY.Nm;                    % number of frequency modes
 
if ~TFinput
 
% get Morelet wavelets
%--------------------------------------------------------------------------
    
    % get induced responses (use previous time-frequency results if possible)
    %==========================================================================
    try
        if size(DCM.xY.xf,1) == Ne
            if size(DCM.xY.xf,2) == Nr
                if size(DCM.xY.xf{1},1) == Nb
                    if size(DCM.xY.xf{1},2) == Nm
                        if size(DCM.xY.U,1) == length(DCM.xY.Hz)
                            if DCM.xY.Rft == Rft
                                DCM.xY.y = spm_cond_units(spm_cat(spm_cell_swap(DCM.xY.xf),2));
                                return
                            end
                        end
                    end
                end
            end
        end
    end
    
    % high-pass filter (detrend)
    %----------------------------------------------------------------------
    if Ns < 512
        T = spm_orthpoly(Ns,h);
        T = speye(Ns,Ns) - T*T';
    else
        T = 1;
    end
    
    % precision of Transform coefficients (assuming an AR process over time)
    %----------------------------------------------------------------------
    P     = spm_Q(1/2,Nt);
     
    % create convolution matrices
    %----------------------------------------------------------------------
    W     = spm_eeg_morlet(Rft,dt,DCM.xY.Hz);
    for i = 1:length(W)
        
        fprintf('\nCreating wavelet projector (%i Hz),',DCM.xY.Hz(i))
        
        C      = spm_convmtx(W{i}',Ns,'square');
        C      = C(:,It + 1 - T1);
        C      = P*C'*T;
        M{i}   = C(Id,:);
    end
end
 
% get MAP projector matrix for source components
%==========================================================================
 
% parameterised lead field ECD given positions (or LFP data)
%--------------------------------------------------------------------------
clear spm_erp_L
if strcmp(DCM.options.spatial, 'ECD')
    if ismember(DCM.xY.modality, {'EEG', 'MEG', 'MEGPLANAR'})        
        try
            pos = DCM.Lpos;
        catch
            pos = DCM.M.dipfit.Lpos;
        end
        
        % number of moments per source
        %------------------------------------------------------------------
        Ng     = 3;
        G.L    = kron(ones(1,Nr),speye(Ng,Ng));
        G.Lpos = kron(pos,ones(1,Ng));
        L      = spm_erp_L(G,DCM.M);
        MAP    = pinv(L);
        
        
        % add (spatial filtering) re-referencing to MAP projector
        %--------------------------------------------------------------------------
        R     = speye(Nc,Nc) - ones(Nc,1)*pinv(ones(Nc,1));
        MAP   = MAP*R;
    else
        warndlg('ECD option can only be used with EEG/MEG/MEGPLANAR channels');
        return;
    end
elseif strcmp(DCM.options.spatial, 'LFP')
    if strcmp(DCM.xY.modality, 'LFP')
        Ng        = 1;
        MAP       = speye(Nr,Nr);
        DCM.Sname = D.chanlabels(Ic);
    else
        warndlg('LFP option can only be used with datasets of LFP modality');
        return;
    end
else
    warndlg('Invalid spatial model specification.')
    return;
end
 
 
% Wavelet amplitudes for each (projected) source
%==========================================================================
condlabels = D.condlist;
for i = 1:Ne;
    
    % trial indices
    %----------------------------------------------------------------------
    c = D.pickconditions(condlabels{trial(i)});
    
    % use only the first 512 trials
    %----------------------------------------------------------------------
    try c = c(1:512); end
    Nt    = length(c);
            
    Ny    = Nb*Ng*Nr;
    Y     = zeros(Ny*Nf,Nt);
    
    % Get data: spectral magnitude
    %----------------------------------------------------------------------
    for j = 1:Nf
        f     = [1:Ny] + (j - 1)*Ny;
        for k = 1:Nt
            if TFinput
                y      = squeeze(D(Ic, D.indfrequency(DCM.xY.Hz(j)), It, c(k)))';
                Y(f,k) = y(:);
            else
                y      = D(Ic,Is,c(k));
                y      = abs(M{j}*y'*MAP');
                Y(f,k) = log(y(:));
            end
        end
        fprintf('\nevaluating %.1f Hz, condition %i (%i trials)',DCM.xY.Hz(j),i,Nt)
    end        
    
    % weight with principal eigenvariate over trials (c.f., averaging)
    %----------------------------------------------------------------------
    u     = spm_svd(Y'*Y);
    u     = full(u(:,1)*sign(max(u(:,1))));
    Y     = reshape(Y*u,Nb,Ng,Nr,Nf);
    
    % sum response over dipole moments and remove baseline (first few bins)
    %----------------------------------------------------------------------
    n     = fix(Nb/8);
    for j = 1:Nr
        Yk      = squeeze(sum(Y(:,:,j,:),2))/Nt;
        Yz{i,j} = Yk - ones(Nb,n)*Yk(1:n,:)/n;
    end
end


% reduce to frequency modes
%==========================================================================
 
% find frequency modes (over time and sources)
%--------------------------------------------------------------------------
Y          = spm_cat(Yz(:));
[U S]      = spm_svd(Y'*Y,0);
U          = U(:,1:Nm);
 
% project time-frequency data onto modes
%--------------------------------------------------------------------------
DCM.xY.xf = cell(Ne,Nr);
for i = 1:Ne
    for j = 1:Nr
        DCM.xY.xf{i,j} = Yz{i,j}*U;
    end
end
DCM.xY.y    = spm_cond_units(spm_cat(spm_cell_swap(DCM.xY.xf),2));
DCM.xY.U    = U;
DCM.xY.S    = S;
DCM.xY.Rft  = Rft;
DCM.xY.code = condlabels(trial);
