function [N R L SR Y B E] = popmodel(N_init,Y_init, dm,F_spatial,Hab,Species,slope,t_init,rect_type)
%keyboard
%rect_type = 'hockey';

if exist('t_init')
    T_Final = t_init;
else
    T_Final = 100;
end

%if ~exist('Rmax')
%   Rmax = repmat(1,size(F_spatial));
%end

% make rect proportional to habitat
Rmax = Hab;

maxage = Species.maxage;
mature = Species.mature;
rec = Species.rec;
M = Species.M;
egg_a = Species.egg_a;
Species_Name = Species.Species_Name;

% assemble transition matrix for each location
n = size(dm,1);
matage = 0:maxage;
Fvec = rec;

% vector of natural mortality + fishing mortality for each age class in each location
Mvec = ones(n,length(matage)).*M + repmat(Fvec,[n,1]).*repmat(F_spatial(:),[1,length(matage)]);
Mvec = exp(-Mvec);

% reshape into 1 x maxage+1 x n array, in preparation for making into array of transition matrices
Mvec = reshape(Mvec',[1,maxage+1,n]);
% repeat for maxage+1 rows.  Now have maxage+1 x maxage+1 x n array
Mmat = repmat(Mvec,[maxage+1,1,1]);

% Fmat will convert each matrix in Mmat into a transition matrix by zeroing out the appropriate entries
Fmat = diag(ones(size(matage)));
Fmat = [Fmat(end,:); Fmat(1:end-1,:)];
Fmat(1,end) = 0;
% now expand Fmat into a maxage+1 x maxage+1 x n array
Fmat = repmat(Fmat,[1,1,n]);

% Tmat is a maxage+1:maxage+1:n array with transition matrix for each location
Tmat = Fmat.*Mmat; 

% assemble matrix showing how many fish are caught
Cvec = repmat(Fvec,[n,1]).*repmat(M + F_spatial(:),[1,length(matage)]);
Cvec = 1 - exp(-Cvec);
Cvec = Cvec.*repmat(F_spatial(:)./(M + F_spatial(:)),[1,length(matage)]);
Cvec = reshape(Cvec',[1, maxage+1,n]);
Cmat = repmat(Cvec,[maxage+1,1,1]);

CFmat = diag(ones(size(matage)));
CFmat = [CFmat(end,:); CFmat(1:end-1,:)];
CFmat(end,end) = CFmat(1,end);
CFmat(1,end) = 0;
CFmat = repmat(CFmat,[1,1,n]);

CFmat = Cmat.*CFmat;


% iterate the model
N = repmat(0,[n,maxage+1,T_Final]);
YN = N;


N(:,:,1) = N_init;

E = repmat(0,[n,T_Final]);
L = E;
R = E;
SR = E;

if size(dm,3) > 1
    dm_temp = mean(dm,3);
else
    dm_temp = dm;
end

switch Species_Name
    case 'DungenessCrab' % for crabs, always have max reproduction
        E(:,1) = Rmax.*Species.LEP_virgin;
    otherwise
E(:,1) = sum(N(:,:,1).*repmat(egg_a.*mature,[n,1]),2); % eggs
end
L(:,1) = dm_temp*E(:,1); % larvae
R(:,1) = rect_fxn(L(:,1),rect_type,Rmax,slope); % recruits
R(:,1) = R(:,1).*(Hab>0);

% self-recruitment
SR(:,1) = ( (dm_temp.*eye(length(dm_temp)))*E(:,1) ).*(Hab>0);

%keyboard

for t = 2:T_Final
    
    
    if size(dm,3) > 1 % if it's a multiple-years run
        yr = size(dm,3);
        index = round(rand*(yr-1) + 1);
        dm_temp = dm(:,:,index);
        %dm_temp = nanmean(dm,3);
    else
        dm_temp = dm;
    end
    
    
    % reproduce
    switch Species_Name
    case 'DungenessCrab' % for crabs, always have max reproduction
        E(:,t) = Rmax.*Species.LEP_virgin;
        otherwise
        E(:,t) = sum(N(:,:,t-1).*repmat(egg_a.*mature,[n,1]),2); % eggs
    end
    L(:,t) = dm_temp*E(:,t);
    
    % recruitment
    R(:,t) = rect_fxn(L(:,t),rect_type,Rmax,slope);
    
    % no recruitment in non-habitat (should be redundant)
    R(:,t) = R(:,t).*(Hab>0);
    
    % self-recruitment
    SR(:,t) = ( (dm_temp.*eye(length(dm_temp)))*E(:,t) ).*(Hab>0);
    
    % adult dynamics
    for nn = 1:n
    N(nn,:,t) = (Tmat(:,:,nn)*N(nn,:,t-1)')';
    end
    N(:,1,t) = R(:,t-1);
    
    % fishery yield in # of fish
    for nn = 1:n
    YN(nn,:,t) = (CFmat(:,:,nn)*N(nn,:,t-1)')';
    end
    
    
end % end for T_Final


% convert numbers to biomass

B = N.*repmat(Species.size_a,[n,1,T_Final]);
Y = YN.*repmat(Species.size_a,[n,1,T_Final]);


%[B Y bins] = convert_sizedist(N,YN,Species);

%B = B.*repmat(Species.a2.*bins.^Species.b2,[size(B,1),1,size(B,3)]);
%Y = Y.*repmat(Species.a2.*bins.^Species.b2,[size(Y,1),1,size(Y,3)]);

%size(Y)
%size(Y_init)

Y(:,:,1) = Y_init;

 %keyboard
    
    