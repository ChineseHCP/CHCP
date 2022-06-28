function varargout = spm_list(varargin)
% Display an analysis of SPM{.}
% FORMAT TabDat = spm_list('List',xSPM,hReg,[Num,Dis,Str])
% Summary list of local maxima for entire volume of interest
% FORMAT TabDat = spm_list('ListCluster',xSPM,hReg,[Num,Dis,Str])
% List of local maxima for a single suprathreshold cluster
%
% xSPM    - structure containing SPM, distribution & filtering details
%        - required fields are:
% .Z     - minimum of n Statistics {filtered on u and k}
% .n     - number of conjoint tests
% .STAT  - distribution {Z, T, X or F}
% .df    - degrees of freedom [df{interest}, df{residual}]
% .u     - height threshold
% .k     - extent threshold {voxels}
% .XYZ   - location of voxels {voxel coords}
% .S     - search Volume {voxels}
% .R     - search Volume {resels}
% .FWHM  - smoothness {voxels}
% .M     - voxels - > mm matrix
% .VOX   - voxel dimensions {mm}
% .DIM   - image dimensions {voxels}
% .units - space units
% .VRpv  - filehandle - Resels per voxel
% .Ps    - uncorrected P values in searched volume (for voxel FDR)
% .Pp    - uncorrected P values of peaks (for peak FDR)
% .Pc    - uncorrected P values of cluster extents (for cluster FDR)
% .uc    - 0.05 critical thresholds for FWEp, FDRp, FWEc, FDRc
% .thresDesc - description of height threshold (string)
%
% (see spm_getSPM.m for further details of xSPM structures)
%
% hReg   - Handle of results section XYZ registry (see spm_results_ui.m)
%
% Num    - number of maxima per cluster [3]
% Dis    - distance among clusters {mm} [8]
% Str    - header string
%
% TabDat - Structure containing table data
%        - fields are
% .tit   - table title (string)
% .hdr   - table header (2x12 cell array)
% .fmt   - fprintf format strings for table data (1x12 cell array)
% .str   - table filtering note (string)
% .ftr   - table footnote information (5x2 cell array)
% .dat   - table data (Nx12 cell array)
%
%                           ----------------
%
% FORMAT spm_list('TxtList',TabDat,c)
% Prints a tab-delimited text version of the table
% TabDat - Structure containing table data (format as above)
% c      - Column of table data to start text table at
%          (E.g. c=3 doesn't print set-level results contained in columns 1 & 2)
%                           ----------------
%
% FORMAT spm_list('SetCoords',xyz,hAx,hReg)
% Highlighting of table co-ordinates (used by results section registry)
% xyz    - 3-vector of new co-ordinate
% hAx    - table axis (the registry object for tables)
% hReg   - Handle of caller (not used)
%__________________________________________________________________________
%
% spm_list characterizes SPMs (thresholded at u and k) in terms of
% excursion sets (a collection of face, edge and vertex connected subsets
% or clusters).  The corrected significance of the results are based on
% set, cluster and voxel-level inferences using distributional
% approximations from the Theory of Gaussian Fields.  These distributions
% assume that the SPM is a reasonable lattice approximation of a
% continuous random field with known component field smoothness.
%
% The p values are based on the probability of obtaining c, or more,
% clusters of k, or more, resels above u, in the volume S analysed =
% P(u,k,c).  For specified thresholds u, k, the set-level inference is
% based on the observed number of clusters C, = P(u,k,C).  For each
% cluster of size K the cluster-level inference is based on P(u,K,1)
% and for each voxel (or selected maxima) of height U, in that cluster,
% the voxel-level inference is based on P(U,0,1).  All three levels of
% inference are supported with a tabular presentation of the p values
% and the underlying statistic:
%
% Set-level     - c    = number of suprathreshold clusters
%               - P    = prob(c or more clusters in the search volume)
%
% Cluster-level - k    = number of voxels in this cluster
%               - Pc   = prob(k or more voxels in the search volume)
%               - Pu   = prob(k or more voxels in a cluster)
%               - Qc   = lowest FDR bound for which this cluster would be
%                        declared positive
%
% Peak-level    - T/F  = Statistic upon which the SPM is based
%               - Ze   = The equivalent Z score - prob(Z > Ze) = prob(t > T)
%               - Pc   = prob(Ze or higher in the search volume)
%               - Qp   = lowest FDR bound for which this peak would be
%                        declared positive
%               - Pu   = prob(Ze or higher at that voxel)
%
% Voxel-level   - Qu   = Expd(Prop of false positives among voxels >= Ze)
%
% x,y,z (mm)    - Coordinates of the voxel
%
% The table is grouped by regions and sorted on the Ze-variate of the
% primary maxima.  Ze-variates (based on the uncorrected p value) are the
% Z score equivalent of the statistic. Volumes are expressed in voxels.
%
% Clicking on values in the table returns the value to the MATLAB
% workspace. In addition, clicking on the co-ordinates jumps the
% results section cursor to that location. The table has a context menu
% (obtained by right-clicking in the background of the table),
% providing options to print the current table as a text table, or to
% extract the table data to the MATLAB workspace.
%
%__________________________________________________________________________
% Copyright (C) 1999-2011 Wellcome Trust Centre for Neuroimaging

% Karl Friston, Andrew Holmes, Guillaume Flandin
% $Id: spm_list.m 6071 2014-06-27 12:52:33Z guillaume $


%==========================================================================
switch lower(varargin{1}), case 'list'                               %-List
%==========================================================================
% FORMAT TabDat = spm_list('List',xSPM,hReg,[Num,Dis,Str])

    %-Parse arguments
    %----------------------------------------------------------------------
    if nargin < 2, error('Not enough input arguments.'); end
    if nargin < 3, hReg = []; else  hReg = varargin{3};  end
    xSPM = varargin{2};
    
    %-Extract results table and display it
    %----------------------------------------------------------------------
    spm('Pointer','Watch')
    
    TabDat = spm_list('Table',xSPM,varargin{4:end});
    
    spm_list('Display',TabDat,hReg);
    
    spm('Pointer','Arrow')
    
    %-Return TabDat structure
    %----------------------------------------------------------------------
    varargout = { TabDat };
    
    
%==========================================================================
case 'table'                                                        %-Table
%==========================================================================
    % FORMAT TabDat = spm_list('table',xSPM,[Num,Dis,Str])
    
    %-Parse arguments
    %----------------------------------------------------------------------
    if nargin < 2, error('Not enough input arguments.'); end
    xSPM = varargin{2};
    
    %-Get number of maxima per cluster to be reported
    %----------------------------------------------------------------------
    if length(varargin) > 2, Num = varargin{3}; else Num = spm_get_defaults('stats.results.volume.nbmax'); end
    
    %-Get minimum distance among clusters (mm) to be reported
    %----------------------------------------------------------------------
    if length(varargin) > 3, Dis = varargin{4}; else Dis = spm_get_defaults('stats.results.volume.distmin'); end
    
    %-Get header string
    %----------------------------------------------------------------------
    if length(varargin) > 4 && ~isempty(varargin{5})
        Title = varargin{5};
    else
        if xSPM.STAT ~= 'P'
            Title = 'p-values adjusted for search volume';
        else
            Title = 'Posterior Probabilities';
        end
    end
    
    %-Extract data from xSPM
    %----------------------------------------------------------------------
    S         = xSPM.S;
    VOX       = xSPM.VOX;
    DIM       = xSPM.DIM;
    M         = xSPM.M;
    XYZ       = xSPM.XYZ;
    Z         = xSPM.Z;
    VRpv      = xSPM.VRpv;
    n         = xSPM.n;
    STAT      = xSPM.STAT;
    df        = xSPM.df;
    u         = xSPM.u;
    k         = xSPM.k;
    try, uc   = xSPM.uc; end
    try, QPs  = xSPM.Ps; end
    try, QPp  = xSPM.Pp; end
    try, QPc  = xSPM.Pc; end
        
    if STAT~='P'
        R     = full(xSPM.R);
        FWHM  = full(xSPM.FWHM);
    end
    try
        units = xSPM.units;
    catch
        units = {'mm' 'mm' 'mm'};
    end
    units{1}  = [units{1} ' '];
    units{2}  = [units{2} ' '];
    
    DIM       = DIM > 1;              % non-empty dimensions
    D         = sum(DIM);             % highest dimension
    VOX       = VOX(DIM);             % scaling
    
    if STAT ~= 'P'
        FWHM  = FWHM(DIM);            % Full width at half max
        FWmm  = FWHM.*VOX;            % FWHM {units}
        V2R   = 1/prod(FWHM);         % voxels to resels
        k     = k*V2R;                % extent threshold in resels
        R     = R(1:(D + 1));         % eliminate null resel counts
        try, QPs = sort(QPs(:)); end  % Needed for voxel   FDR
        try, QPp = sort(QPp(:)); end  % Needed for peak    FDR
        try, QPc = sort(QPc(:)); end  % Needed for cluster FDR
    end

    % Choose between voxel-wise and topological FDR
    %----------------------------------------------------------------------
    topoFDR = spm_get_defaults('stats.topoFDR');
    
    %-Tolerance for p-value underflow, when computing equivalent Z's
    %----------------------------------------------------------------------
    tol = eps*10;
    
    %-Table Headers
    %----------------------------------------------------------------------
    TabDat.tit = Title;
    
    TabDat.hdr = {...
        'set',      'p',            '\itp';...
        'set',      'c',            '\itc';...
        'cluster',  'p(FWE-corr)',  '\itp\rm_{FWE-corr}';...
        'cluster',  'p(FDR-corr)',  '\itq\rm_{FDR-corr}';...
        'cluster',  'equivk',       '\itk\rm_E';...
        'cluster',  'p(unc)',       '\itp\rm_{uncorr}';...
        'peak',     'p(FWE-corr)',  '\itp\rm_{FWE-corr}';...
        'peak',     'p(FDR-corr)',  '\itq\rm_{FDR-corr}';...
        'peak',      STAT,          sprintf('\\it%c',STAT);...
        'peak',     'equivZ',       '(\itZ\rm_\equiv)';...
        'peak',     'p(unc)',       '\itp\rm_{uncorr}';...
        '',         'x,y,z {mm}',   [units{:}]}';...
        
    %-Coordinate Precisions
    %----------------------------------------------------------------------
    if isempty(xSPM.XYZmm) % empty results
        xyzfmt = '%3.0f %3.0f %3.0f';
        voxfmt = repmat('%0.1f ',1,numel(FWmm));
    elseif ~any(strcmp(units{3},{'mm',''})) % 2D data
        xyzfmt = '%3.0f %3.0f %3.0f';
        voxfmt = repmat('%0.1f ',1,numel(FWmm));
    else % 3D data, work out best precision based on voxel sizes and FOV
        xyzsgn = min(xSPM.XYZmm(DIM,:),[],2) < 0;
        xyzexp = max(floor(log10(max(abs(xSPM.XYZmm(DIM,:)),[],2)))+(max(abs(xSPM.XYZmm(DIM,:)),[],2) >= 1),0);
        voxexp = floor(log10(abs(VOX')))+(abs(VOX') >= 1);
        xyzdec = max(-voxexp,0);
        voxdec = max(-voxexp,1);
        xyzwdt = xyzsgn+xyzexp+(xyzdec>0)+xyzdec;
        voxwdt = max(voxexp,0)+(voxdec>0)+voxdec;
        tmpfmt = cell(size(xyzwdt));
        for i = 1:numel(xyzwdt)
            tmpfmt{i} = sprintf('%%%d.%df ', xyzwdt(i), xyzdec(i));
        end
        xyzfmt = [tmpfmt{:}];
        tmpfmt = cell(size(voxwdt));
        for i = 1:numel(voxwdt)
            tmpfmt{i} = sprintf('%%%d.%df ', voxwdt(i), voxdec(i));
        end
        voxfmt = [tmpfmt{:}];
    end
    TabDat.fmt = {  '%-0.3f','%g',...                          %-Set
        '%0.3f', '%0.3f','%0.0f', '%0.3f',...                  %-Cluster
        '%0.3f', '%0.3f', '%6.2f', '%5.2f', '%0.3f',...        %-Peak
        xyzfmt};                                               %-XYZ
    
    %-Table filtering note
    %----------------------------------------------------------------------
    if isinf(Num)
        TabDat.str = sprintf('table shows all local maxima > %.1fmm apart',Dis);
    else
        TabDat.str = sprintf(['table shows %d local maxima ',...
            'more than %.1fmm apart'],Num,Dis);
    end 
    
    %-Footnote with SPM parameters
    %----------------------------------------------------------------------
    if STAT ~= 'P'
        Pz              = spm_P(1,0,u,df,STAT,1,n,S);
        Pu              = spm_P(1,0,u,df,STAT,R,n,S);
        [P Pn Ec Ek]    = spm_P(1,k,u,df,STAT,R,n,S);
        
        TabDat.ftr      = cell(9,2);
        TabDat.ftr{1,1} = ...
            ['Height threshold: ' STAT ' = %0.2f, p = %0.3f (%0.3f)'];
        TabDat.ftr{1,2} = [u,Pz,Pu];
        TabDat.ftr{2,1} = ...
            'Extent threshold: k = %0.0f voxels, p = %0.3f (%0.3f)';
        TabDat.ftr{2,2} = [k/V2R,Pn,P];
        TabDat.ftr{3,1} = ...
            'Expected voxels per cluster, <k> = %0.3f';
        TabDat.ftr{3,2} = Ek/V2R;
        TabDat.ftr{4,1} = ...
            'Expected number of clusters, <c> = %0.2f';
        TabDat.ftr{4,2} = Ec*Pn;
        if any(isnan(uc))
            TabDat.ftr{5,1} = 'FWEp: %0.3f, FDRp: %0.3f';
            TabDat.ftr{5,2} = uc(1:2);
        else
            TabDat.ftr{5,1} = ...
                'FWEp: %0.3f, FDRp: %0.3f, FWEc: %0.0f, FDRc: %0.0f';
            TabDat.ftr{5,2} = uc;
        end
        TabDat.ftr{6,1} = 'Degrees of freedom = [%0.1f, %0.1f]';
        TabDat.ftr{6,2} = df;
        TabDat.ftr{7,1} = ...
            ['FWHM = ' voxfmt units{:} '; ' voxfmt '{voxels}'];
        TabDat.ftr{7,2} = [FWmm FWHM];
        TabDat.ftr{8,1} = ...
            'Volume: %0.0f = %0.0f voxels = %0.1f resels';
        TabDat.ftr{8,2} = [S*prod(VOX),S,R(end)];
        TabDat.ftr{9,1} = ...
            ['Voxel size: ' voxfmt units{:} '; (resel = %0.2f voxels)'];
        TabDat.ftr{9,2} = [VOX,prod(FWHM)];
     else
        TabDat.ftr = {};
    end 

    %-Characterize excursion set in terms of maxima
    % (sorted on Z values and grouped by regions)
    %----------------------------------------------------------------------
    if isempty(Z)
        TabDat.dat = cell(0,12);
        varargout  = {TabDat};
        return
    end

    %-Workaround in spm_max for conjunctions with negative thresholds
    %----------------------------------------------------------------------
    minz           = abs(min(min(Z)));
    Z              = 1 + minz + Z;
    [N Z XYZ A L]  = spm_max(Z,XYZ);
    Z              = Z - minz - 1;
    
    %-Convert cluster sizes from voxels (N) to resels (K)
    %----------------------------------------------------------------------
    c              = max(A);                           %-Number of clusters
    NONSTAT        = spm_get_defaults('stats.rft.nonstat');
    
    if STAT ~= 'P'
        if NONSTAT
            K      = zeros(c,1);
            for i  = 1:c
                
                %-Get LKC for voxels in i-th region
                %----------------------------------------------------------
                LKC = spm_get_data(VRpv,L{i});
                
                %-Compute average of valid LKC measures for i-th region
                %----------------------------------------------------------
                valid = ~isnan(LKC);
                if any(valid)
                    LKC = sum(LKC(valid)) / sum(valid);
                else
                    LKC = V2R; % fall back to whole-brain resel density
                end
                
                %-Intrinsic volume (with surface correction)
                %----------------------------------------------------------
                IV   = spm_resels([1 1 1],L{i},'V');
                IV   = IV*[1/2 2/3 2/3 1]';
                K(i) = IV*LKC;
                
            end
            K = K(A);
        else
            K = N*V2R;
        end
    end
    
    %-Convert maxima locations from voxels to mm
    %----------------------------------------------------------------------
    XYZmm = M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];
    
    %-Set-level p values {c} - do not display if reporting a single cluster
    %----------------------------------------------------------------------
    if STAT ~= 'P'
        Pc     = spm_P(c,k,u,df,STAT,R,n,S);            %-Set-level p-value
    else
        Pc     = [];
    end

    TabDat.dat = {Pc,c};
    TabLin     = 1;
    
    %-Cluster and local maxima p-values & statistics
    %----------------------------------------------------------------------
    while numel(find(isfinite(Z)))
    
        %-Find largest remaining local maximum
        %------------------------------------------------------------------
        [U,i]  = max(Z);            %-largest maxima
        j      = find(A == A(i));   %-maxima in cluster


        %-Compute cluster {k} and peak-level {u} p values for this cluster
        %------------------------------------------------------------------
        if STAT ~= 'P'
            
            % p-values (FWE)
            %--------------------------------------------------------------
            Pz      = spm_P(1,0,   U,df,STAT,1,n,S);  % uncorrected p value
            Pu      = spm_P(1,0,   U,df,STAT,R,n,S);  % FWE-corrected {based on Z}
            [Pk Pn] = spm_P(1,K(i),u,df,STAT,R,n,S);  % [un]corrected {based on K}
            
            % q-values (FDR)
            %--------------------------------------------------------------
            if topoFDR
                Qc  = spm_P_clusterFDR(K(i),df,STAT,R,n,u,QPc); % based on K
                Qp  = spm_P_peakFDR(U,df,STAT,R,n,u,QPp);       % based on Z
                Qu  = [];
            else
                Qu  = spm_P_FDR(U,df,STAT,n,QPs);     % voxel FDR-corrected
                Qc  = [];
                Qp  = [];
            end

            % Equivalent Z-variate
            %--------------------------------------------------------------
            if Pz < tol
                Ze  = Inf;
            else
                Ze  = spm_invNcdf(1 - Pz);
            end
        else
            Pz      = [];
            Pu      = [];
            Qu      = [];
            Pk      = [];
            Pn      = [];
            Qc      = [];
            Qp      = [];
            ws      = warning('off','SPM:outOfRangeNormal');
            Ze      = spm_invNcdf(U);
            warning(ws);
        end
        
        if topoFDR
        [TabDat.dat{TabLin,3:12}] = deal(Pk,Qc,N(i),Pn,Pu,Qp,U,Ze,Pz,XYZmm(:,i));
        else
        [TabDat.dat{TabLin,3:12}] = deal(Pk,Qc,N(i),Pn,Pu,Qu,U,Ze,Pz,XYZmm(:,i));
        end
        TabLin = TabLin + 1;
        
        %-Print Num secondary maxima (> Dis mm apart)
        %------------------------------------------------------------------
        [l,q] = sort(-Z(j));                              % sort on Z value
        D     = i;
        for i = 1:length(q)
            d = j(q(i));
            if min(sqrt(sum((XYZmm(:,D)-repmat(XYZmm(:,d),1,size(D,2))).^2)))>Dis
                if length(D) < Num
                    % voxel-level p values {Z}
                    %------------------------------------------------------
                    if STAT ~= 'P'
                        Pz     = spm_P(1,0,Z(d),df,STAT,1,n,S);
                        Pu     = spm_P(1,0,Z(d),df,STAT,R,n,S);
                        if topoFDR
                            Qp = spm_P_peakFDR(Z(d),df,STAT,R,n,u,QPp);
                            Qu = [];
                        else
                            Qu = spm_P_FDR(Z(d),df,STAT,n,QPs);
                            Qp = [];
                        end
                        if Pz < tol
                            Ze = Inf;
                        else
                            Ze = spm_invNcdf(1 - Pz); 
                        end
                    else
                        Pz     = [];
                        Pu     = [];
                        Qu     = [];
                        Qp     = [];
                        ws     = warning('off','SPM:outOfRangeNormal');
                        Ze     = spm_invNcdf(Z(d));
                        warning(ws);
                    end
                    D     = [D d];
                    if topoFDR
                    [TabDat.dat{TabLin,7:12}] = ...
                        deal(Pu,Qp,Z(d),Ze,Pz,XYZmm(:,d));
                    else
                    [TabDat.dat{TabLin,7:12}] = ...
                        deal(Pu,Qu,Z(d),Ze,Pz,XYZmm(:,d));
                    end
                    TabLin = TabLin+1;
                end
            end
        end
        Z(j) = NaN;     % Set local maxima to NaN
    end
    
    varargout = {TabDat};
    
    %======================================================================
    case 'display'                       %-Display table in Graphics window
    %======================================================================
    % FORMAT spm_list('display',TabDat,hReg)
    
    %-Parse arguments
    %----------------------------------------------------------------------
    if nargin < 2, error('Not enough input arguments.'); 
    else           TabDat = varargin{2}; end
    if nargin < 3, hReg = []; else hReg = varargin{3}; end
    
    %-Get current location (to highlight selected voxel in table)
    %----------------------------------------------------------------------
    xyzmm = spm_results_ui('GetCoords');
    
    %-Setup Graphics panel
    %----------------------------------------------------------------------
    Fgraph = spm_figure('FindWin','Satellite');
    if ~isempty(Fgraph)
        figure(Fgraph);
        ht = 0.85; bot = 0.14;
    else
        Fgraph = spm_figure('GetWin','Graphics');
        ht = 0.4; bot = 0.1;
    end
    spm_results_ui('Clear',Fgraph)
    FS     = spm('FontSizes');           %-Scaled font sizes
    PF     = spm_platform('fonts');      %-Font names (for this platform)
    
    %-Table axes & Title
    %----------------------------------------------------------------------
    hAx   = axes('Position',[0.025 bot 0.9 ht],...
                 'DefaultTextFontSize',FS(8),...
                 'DefaultTextInterpreter','Tex',...
                 'DefaultTextVerticalAlignment','Baseline',...
                 'Tag','SPMList',...
                 'Units','points',...
                 'Visible','off');

    AxPos = get(hAx,'Position'); set(hAx,'YLim',[0,AxPos(4)])
    dy    = FS(9);
    y     = floor(AxPos(4)) - dy;

    text(0,y,['Statistics:  \it\fontsize{',num2str(FS(9)),'}',TabDat.tit],...
              'FontSize',FS(11),'FontWeight','Bold');   y = y - dy/2;
    line([0 1],[y y],'LineWidth',3,'Color','r'),        y = y - 9*dy/8;

    %-Display table header
    %----------------------------------------------------------------------
    set(gca,'DefaultTextFontName',PF.helvetica,'DefaultTextFontSize',FS(8))

    Hs = []; Hc = []; Hp = [];
    h  = text(0.01,y, [TabDat.hdr{1,1} '-level'],'FontSize',FS(9));
    h  = line([0,0.11],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r');
    h  = text(0.02,y-9*dy/8,    TabDat.hdr{3,1});              Hs = [Hs,h];
    h  = text(0.08,y-9*dy/8,    TabDat.hdr{3,2});              Hs = [Hs,h];
    
    text(0.22,y, [TabDat.hdr{1,3} '-level'],'FontSize',FS(9));
    line([0.14,0.44],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r');
    h  = text(0.15,y-9*dy/8,    TabDat.hdr{3,3});              Hc = [Hc,h];
    h  = text(0.24,y-9*dy/8,    TabDat.hdr{3,4});              Hc = [Hc,h];
    h  = text(0.34,y-9*dy/8,    TabDat.hdr{3,5});              Hc = [Hc,h];
    h  = text(0.39,y-9*dy/8,    TabDat.hdr{3,6});              Hc = [Hc,h];
    
    text(0.64,y, [TabDat.hdr{1,7} '-level'],'FontSize',FS(9));
    line([0.48,0.88],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r');
    h  = text(0.49,y-9*dy/8,    TabDat.hdr{3,7});              Hp = [Hp,h];
    h  = text(0.58,y-9*dy/8,    TabDat.hdr{3,8});              Hp = [Hp,h];
    h  = text(0.67,y-9*dy/8,    TabDat.hdr{3,9});              Hp = [Hp,h];
    h  = text(0.75,y-9*dy/8,    TabDat.hdr{3,10});             Hp = [Hp,h];
    h  = text(0.82,y-9*dy/8,    TabDat.hdr{3,11});             Hp = [Hp,h];
    
    text(0.92,y - dy/2,TabDat.hdr{3,12},'Fontsize',FS(8));

    %-Move to next vertical position marker
    %----------------------------------------------------------------------
    y     = y - 7*dy/4;
    line([0 1],[y y],'LineWidth',1,'Color','r')
    y     = y - 5*dy/4;
    y0    = y;

    %-Table filtering note
    %----------------------------------------------------------------------
    text(0.5,4,TabDat.str,'HorizontalAlignment','Center',...
        'FontName',PF.helvetica,'FontSize',FS(8),'FontAngle','Italic')

    %-Footnote with SPM parameters (if classical inference)
    %----------------------------------------------------------------------
    line([0 1],[0 0],'LineWidth',1,'Color','r')
    if ~isempty(TabDat.ftr)
        set(gca,'DefaultTextFontName',PF.helvetica,...
            'DefaultTextInterpreter','None','DefaultTextFontSize',FS(8))
        
        fx = repmat([0 0.5],ceil(size(TabDat.ftr,1)/2),1);
        fy = repmat((1:ceil(size(TabDat.ftr,1)/2))',1,2);
        for i=1:size(TabDat.ftr,1)
            text(fx(i),-fy(i)*dy,sprintf(TabDat.ftr{i,1},TabDat.ftr{i,2}),...
                'UserData',TabDat.ftr{i,2},...
                'ButtonDownFcn','get(gcbo,''UserData'')');
        end
    end
    
    %-Characterize excursion set in terms of maxima
    % (sorted on Z values and grouped by regions)
    %======================================================================
    if isempty(TabDat.dat)
        text(0.5,y-6*dy,'no suprathreshold clusters',...
            'HorizontalAlignment','Center',...
            'FontAngle','Italic','FontWeight','Bold',...
            'FontSize',FS(16),'Color',[1,1,1]*.5);
        return
    end
    
    %-Table proper
    %======================================================================

    %-Column Locations
    %----------------------------------------------------------------------
    tCol = [ 0.01      0.08 ...                                %-Set
             0.15      0.24      0.33      0.39 ...            %-Cluster
             0.49      0.58      0.65      0.74      0.83 ...  %-Peak
             0.92];                                            %-XYZ
    
    %-Pagination variables
    %----------------------------------------------------------------------
    hPage = [];
    set(gca,'DefaultTextFontName',PF.courier,'DefaultTextFontSize',FS(7));

    %-Set-level p values {c} - do not display if reporting a single cluster
    %----------------------------------------------------------------------
    if isempty(TabDat.dat{1,1}) % Pc
        set(Hs,'Visible','off');
    end
    
    if TabDat.dat{1,2} > 1 % c
        h     = text(tCol(1),y,sprintf(TabDat.fmt{1},TabDat.dat{1,1}),...
                    'FontWeight','Bold', 'UserData',TabDat.dat{1,1},...
                    'ButtonDownFcn','get(gcbo,''UserData'')');
        hPage = [hPage, h];
        h     = text(tCol(2),y,sprintf(TabDat.fmt{2},TabDat.dat{1,2}),...
                    'FontWeight','Bold', 'UserData',TabDat.dat{1,2},...
                    'ButtonDownFcn','get(gcbo,''UserData'')');
        hPage = [hPage, h];
    else
        set(Hc,'Visible','off');
    end
    
    %-Cluster and local maxima p-values & statistics
    %----------------------------------------------------------------------
    HlistXYZ = [];
    for i=1:size(TabDat.dat,1)
        
        %-Paginate if necessary
        %------------------------------------------------------------------
        if y < dy
            h = text(0.5,-5*dy,...
                sprintf('Page %d',spm_figure('#page',Fgraph)),...
                        'FontName',PF.helvetica,'FontAngle','Italic',...
                        'FontSize',FS(8));
            spm_figure('NewPage',[hPage,h])
            hPage = [];
            y     = y0;
        end
        
        %-Print cluster and maximum peak-level p values
        %------------------------------------------------------------------
        if  ~isempty(TabDat.dat{i,5}), fw = 'Bold'; else fw = 'Normal'; end
        
        for k=3:11
            h     = text(tCol(k),y,sprintf(TabDat.fmt{k},TabDat.dat{i,k}),...
                        'FontWeight',fw,...
                        'UserData',TabDat.dat{i,k},...
                        'ButtonDownFcn','get(gcbo,''UserData'')');
            hPage = [hPage, h];
        end
        
        % Specifically changed so it properly finds hMIPax
        %------------------------------------------------------------------
        tXYZmm = TabDat.dat{i,12};
        h      = text(tCol(12),y,sprintf(TabDat.fmt{12},tXYZmm),...
            'FontWeight',fw,...
            'Tag','ListXYZ',...
            'ButtonDownFcn',[...
            'hMIPax = findobj(''tag'',''hMIPax'');',...
            'spm_mip_ui(''SetCoords'',get(gcbo,''UserData''),hMIPax);'],...
            'Interruptible','off','BusyAction','Cancel',...
            'UserData',tXYZmm);

        HlistXYZ = [HlistXYZ, h];
        if spm_XYZreg('Edist',xyzmm,tXYZmm)<eps && ~isempty(hReg)
            set(h,'Color','r')
        end
        hPage  = [hPage, h];

        y      = y - dy;
    end
    
    %-Number and register last page (if paginated)
    %----------------------------------------------------------------------
    if spm_figure('#page',Fgraph)>1
        h = text(0.5,-5*dy,sprintf('Page %d/%d',spm_figure('#page',Fgraph)*[1,1]),...
            'FontName',PF.helvetica,'FontSize',FS(8),'FontAngle','Italic');
        spm_figure('NewPage',[hPage,h])
    end
    
    %-End: Store TabDat in UserData of context menu
    %======================================================================
    h = uicontextmenu('Tag','TabDat','UserData',TabDat);
    set(gca,'UIContextMenu',h,...
        'Visible','on',...
        'XColor','w','YColor','w')
    uimenu(h,'Label','Print text table',...
        'CallBack',...
        'spm_list(''txtlist'',get(get(gcbo,''Parent''),''UserData''),3)',...
        'Interruptible','off','BusyAction','Cancel');
    uimenu(h,'Label','Extract table data structure',...
        'CallBack','TabDat=get(get(gcbo,''Parent''),''UserData'')',...
        'Interruptible','off','BusyAction','Cancel');
    if ispc
        uimenu(h,'Label','Export to Excel',...
        'CallBack',...
        'spm_list(''xlslist'',get(get(gcbo,''Parent''),''UserData''))',...
        'Interruptible','off','BusyAction','Cancel');
    end
    uimenu(h,'Label','Export to CSV file',...
        'CallBack',...
        'spm_list(''csvlist'',get(get(gcbo,''Parent''),''UserData''))',...
        'Interruptible','off','BusyAction','Cancel');

    %-Setup registry
    %----------------------------------------------------------------------
    set(hAx,'UserData',struct('hReg',hReg,'HlistXYZ',HlistXYZ))
    spm_XYZreg('Add2Reg',hReg,hAx,'spm_list');

    varargout = {};
    
    %======================================================================
    case 'listcluster'                      %-List for current cluster only
    %======================================================================
    % FORMAT TabDat = spm_list('ListCluster',xSPM,hReg,[Num,Dis,Str])

        %-Parse arguments
        %------------------------------------------------------------------
        if nargin < 2, error('Not enough input arguments.'); end
        if nargin < 3, hReg = []; else hReg = varargin{3};   end
        xSPM = varargin{2};

        %-Get number of maxima per cluster to be reported
        %------------------------------------------------------------------
        if nargin < 4, Num = spm_get_defaults('stats.results.svc.nbmax'); else Num = varargin{4}; end
        
        %-Get minimum distance among clusters (mm) to be reported
        %------------------------------------------------------------------
        if nargin < 5, Dis = spm_get_defaults('stats.results.svc.distmin'); else Dis = varargin{5}; end

        %-Get header string
        %------------------------------------------------------------------
        if nargin < 6, Str = ''; else Str = varargin{6}; end
        
        %-If there are suprathreshold voxels, filter out all but current cluster
        %------------------------------------------------------------------
        if ~isempty(xSPM.Z)

            %-Jump to voxel nearest current location
            %--------------------------------------------------------------
            [xyzmm,i] = spm_XYZreg('NearestXYZ',...
                spm_results_ui('GetCoords'),xSPM.XYZmm);
            spm_results_ui('SetCoords',xSPM.XYZmm(:,i));

            %-Find selected cluster
            %--------------------------------------------------------------
            A          = spm_clusters(xSPM.XYZ);
            j          = find(A == A(i));
            xSPM.Z     = xSPM.Z(j);
            xSPM.XYZ   = xSPM.XYZ(:,j);
            xSPM.XYZmm = xSPM.XYZmm(:,j);
        end

        %-Call 'list' functionality to produce table
        %------------------------------------------------------------------
        varargout = { spm_list('list',xSPM,hReg,Num,Dis,Str) };


    %======================================================================
    case 'txtlist'                                 %-Print ASCII text table
    %======================================================================
    % FORMAT spm_list('TxtList',TabDat,c)

        if nargin<2, error('Not enough input arguments.'); end
        if nargin<3, c = 1; else c = varargin{3}; end
        TabDat = varargin{2};

        %-Table Title
        %------------------------------------------------------------------
        fprintf('\n\nStatistics: %s\n',TabDat.tit)
        fprintf('%c',repmat('=',1,80)), fprintf('\n')

        %-Table header
        %------------------------------------------------------------------
        fprintf('%s\t',TabDat.hdr{1,c:end-1}), fprintf('%s\n',TabDat.hdr{1,end})
        fprintf('%s\t',TabDat.hdr{2,c:end-1}), fprintf('%s\n',TabDat.hdr{2,end})
        fprintf('%c',repmat('-',1,80)), fprintf('\n')

        %-Table data
        %------------------------------------------------------------------
        for i = 1:size(TabDat.dat,1)
            for j=c:size(TabDat.dat,2)
                fprintf(TabDat.fmt{j},TabDat.dat{i,j});
                fprintf('\t')
            end
            fprintf('\n')
        end
        for i=1:max(1,12-size(TabDat.dat,1)), fprintf('\n'), end
        fprintf('%s\n',TabDat.str)
        fprintf('%c',repmat('-',1,80)), fprintf('\n')

        %-Table footer
        %------------------------------------------------------------------
        for i=1:size(TabDat.ftr,1)
            fprintf([TabDat.ftr{i,1} '\n'],TabDat.ftr{i,2});
        end
        fprintf('%c',repmat('=',1,80)), fprintf('\n\n')

        
    %======================================================================
    case 'xlslist'                                  %-Export table to Excel
    %======================================================================
    % FORMAT spm_list('XLSList',TabDat)

        if nargin<2, error('Not enough input arguments.'); end
        TabDat = varargin{2};
        
        d          = [TabDat.hdr(1:2,:);TabDat.dat];
        xyz        = d(3:end,end);
        xyz        = num2cell([xyz{:}]');
        d(:,end+1) = d(:,end);
        d(:,end+1) = d(:,end);
        d(3:end,end-2:end) = xyz;
        tmpfile    = [tempname '.xls'];
        xlswrite(tmpfile, d);
        winopen(tmpfile);
    
    %======================================================================
    case 'csvlist'            %-Export table to comma-separated values file
    %======================================================================
    % FORMAT spm_list('CSVList',TabDat)

        if nargin<2, error('Not enough input arguments.'); end
        TabDat = varargin{2};
        
        tmpfile = [tempname '.csv'];
        fid = fopen(tmpfile,'wt');
        fprintf(fid,[repmat('%s,',1,11) '%d,,\n'],TabDat.hdr{1,:});
        fprintf(fid,[repmat('%s,',1,12) '\n'],TabDat.hdr{2,:});
        fmt = TabDat.fmt;
        [fmt{2,:}] = deal(','); fmt = [fmt{:}];
        fmt(end:end+1) = '\n'; fmt = strrep(fmt,' ',',');
        for i=1:size(TabDat.dat,1)
            fprintf(fid,fmt,TabDat.dat{i,:});
        end
        fclose(fid);
        open(tmpfile);
    
    %======================================================================
    case 'setcoords'                                    %-Coordinate change
    %======================================================================
    % FORMAT spm_list('SetCoords',xyz,hAx,hReg)
        if nargin<3, error('Not enough input arguments.'); end
        hAx      = varargin{3};
        xyz      = varargin{2};
        UD       = get(hAx,'UserData');
        HlistXYZ = UD.HlistXYZ(ishandle(UD.HlistXYZ));

        %-Set all co-ord strings to black
        %------------------------------------------------------------------
        set(HlistXYZ,'Color','k');

        %-If co-ord matches a string, highlight it in red
        %------------------------------------------------------------------
        XYZ      = get(HlistXYZ,'UserData');
        if iscell(XYZ), XYZ = cat(2,XYZ{:}); end
        [tmp,i,d] = spm_XYZreg('NearestXYZ',xyz,XYZ);
        if d<eps
            set(HlistXYZ(i),'Color','r');
        end

    %======================================================================
    otherwise                                       %-Unknown action string
    %======================================================================
        error('Unknown action string')
end
