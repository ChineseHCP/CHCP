function [y] = spm_gen_erp(P,M,U)
% Generates a prediction of trial-specific source activity
% FORMAT [y] = spm_gen_erp(P,M,U)
%
% P - parameters
% M - neural-mass model structure
% U - trial-effects
%   U.X  - between-trial effects (encodes the number of trials)
%   U.dt - time bins for within-trial effects
%
% y - {[ns,nx];...} - predictions for nx states {trials}
%                   - for ns samples
%
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_gen_erp.m 4611 2012-01-03 14:05:18Z vladimir $

% within-trial inputs
%==========================================================================

% check input u = f(t,P,M)
%--------------------------------------------------------------------------
try, fu  = M.fu; catch,  fu  = 'spm_erp_u'; end
try, ns  = M.ns; catch,  ns  = 128;         end
try, dt  = U.dt; catch,  dt  = 0.004;       end

% peri-stimulus time inputs
%--------------------------------------------------------------------------
U.u = feval(fu,[1:ns]*U.dt,P,M);

% between-trial inputs
%==========================================================================
try
    X = U.X;
    if all(~size(X))
        X = sparse(1,0);
    end
catch
    X = sparse(1,0);
end

% solve for fixed point (i.e., 64 ms burn in)
%--------------------------------------------------------------------------
S     = M;
S.g   = {};
V.u   = sparse(8,S.m);
V.dt  = 8/1000;
x     = spm_int_L(P,S,V);
x     = spm_unvec(x(end,:),S.x);
M.x   = x;

% cycle over trials
%--------------------------------------------------------------------------
y      = cell(size(X,1),1);
for  c = 1:size(X,1)

    % baseline parameters
    %----------------------------------------------------------------------
    Q  = P;

    % trial-specific effects
    %----------------------------------------------------------------------
    for i = 1:size(X,2)

      Q.A{1} = Q.A{1} + X(c,i)*P.B{i};          % Forward  connections 
      Q.A{2} = Q.A{2} + X(c,i)*P.B{i};          % Backward connections
      Q.A{3} = Q.A{3} + X(c,i)*P.B{i};          % Lateral connections 
      
      % for cmc
      try 
          Q.A{4} = Q.A{4} + X(c,i)*P.B{i};         % Backward connections 
      end
      
        % intrinsic connections
        %----------------------------------------------------------------------
        try
            Q.H(:,1) = Q.H(:,1) + X(c,i)*diag(P.B{i});
        catch
            Q.G(:,1) = Q.G(:,1) + X(c,i)*diag(P.B{i});
        end
        
    end

    % integrate DCM for this trial
    %----------------------------------------------------------------------
    y{c}      = spm_int_L(Q,M,U);

end

