function Species = find_FLEP_threshold_2D(Species_Names,Species)

% This code computes the correction factor needed to ensure that a species
% collapses when FLEP = 0.35 in the no-reserve case (i.e. the adjustment to
% the CRT needed b/c of long-distance dispersal on a finite coastline with
% non-continuous habitat)

% This version: finds critical value of slope in one step using eigenvalue of connectivity matrix
% Follows logic used in White (2010) Fisheries Research

%inputs: D = vector of dispersal distances
%        HR = vector of homeranges
%        spp = species type: 1 = crab, 2 = abalone, 3 = urchin
%        h = cooling rate (larger values cool faster)

%output: slope = slope of hockey-stick stock-rect curve


% make sure all of the habitat stuff is done
load NC_2D_setup_params.mat  
load conn_mat_NC_2D
load DPR_2D_spatial_vars.mat


% Must loop over each species
for s = 1:length(Species_Names)
    sp = Species_Names{s};
    
    habvec = res_struct_2D.(sp).Habvec;
    habvec =  habvec./max(habvec);
    habvec = double(habvec > 0);  % habvec needs to be just 0s and 1s for this step
    
    % Also loop over possible slopes
    
   for sl = 1:length(Species.(sp).nominal_thresh)
    
FLEP_crit = Species.(sp).nominal_thresh(sl); % this will usually be 0.35
I = conn_struct.(sp).I; 
%J = conn_struct.(sp).J; 

if size(conn_struct.(sp).conn_mat,3) > 1 % if there is more than one connectivity matrix (montecarlo ocean option)
    conn_mat = mean(conn_struct.(sp).conn_mat(I,I,:),3); % take mean across all years
else
    conn_mat = conn_struct.(sp).conn_mat(I,I); % only real values of conn_mat
end


    % Assemble connectivity matrix from egg production & dispersal matrix
    % (assume LEP = 1 if hab = 1)
    
    C = conn_mat.*repmat(habvec(:)',[length(habvec),1]);

    
    % Find max eigenvalue
    E = max(eig(C));
    
    %Slope is 1/threshold * 1/E
    T = 1/FLEP_crit*1/E; %
    
    Species.(sp).slope(sl) = T;
   end % end loop over slopes
end % end loop over species

save NC_2D_setup_params.mat 
save conn_mat_NC_2D conn_struct;
save DPR_2D_spatial_vars.mat res_struct_2D;      
            
    