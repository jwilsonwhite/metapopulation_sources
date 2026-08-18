function get_conn_mat(Species_Names,Species_params_file,Hab_Pkgs_file,Connmat_Dir,Ocean,Oceanyears)

% reads in and cleans up connectivity matrix from text files
% for 2D DPR model for Northern California

% save results in conn_mat_2D.mat
% major outputs:
%       conn_mat = connectivity matrix
%       I = indices of conn_mat with non-NaN values

% Updates July 2018 for Sophie Perron project:
% Now uses de_convert_drake_matrix.m to get connectivity at scale of
% connectivity nodes
% Note that in doing so, the lookup_table.ROMS_code becomes the de-facto
% lookup table.
% This will also create new habitat vector. This will have to be inserted
% into...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load in parameters and filenames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(Species_params_file); % load DPR_2D_params.mat
load(Hab_Pkgs_file); %
%eval(strcat('load Hab_and_Pkgs_',Datename,'.mat')) 

conn_struct = struct([]);

% Must loop over each species
for s = 1:length(Species_Names)
    sp = Species_Names{s};

    ss = Species.(sp);
    cs = struct([]);
    
    % Find correct  lookup table
    switch ss.hab_type
        case 'Hard_0-30'
            ht = 'Hard_0_30';
            habras = habras_Hard_0_30;
        case 'Hard_0-100'
            ht = 'Hard_0_100';
            habras = habras_Hard_0_100;
        case 'Soft_0-30'
            ht = 'Soft_0_30';
            habras = habras_Soft_0_30;
        case 'Soft_0-100'
            ht = 'Soft_0_100';
            habras = habras_Soft_0_100;
    end
    eval(strcat(['lookup_table = lookup_table_',ht,';']));
    
    % Make a vector of Habitat
    habvec = zeros(length(lookup_table.RowCode),1);
    for j = 1:length(habvec)
        habvec(j) = habras(lookup_table.RowCode(j),lookup_table.ColCode(j));
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get connectivity matrix and clean of NaN's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PLD = ss.PLD;
months = ss.SpawnSeason;

% kluge to deal with spawning that spans Dec-Jan
months = unique(months);


if PLD < 1 % if no larval dispersal (surfperch)
    
   conn_mat = diag(ones(1,length(lookup_table.ShortID)));

else % if PLD > 1

    switch Ocean
        case 'fixed' % fixed average connectivity matrix
        
       
        D_temp = generate_dispmat_drake(PLD,months,Connmat_Dir);
   
        [D,H,LUT_short] = de_convert_drake_matrix(D_temp,lookup_table,habvec);
    
        conn_mat = D;
        habvec = H;

        case 'montecarlo' % have multiple dispersal matrices & draw from them randomly
            % This option is not supported for NC model
            
            error('This option is not currently supported, need to update de_convert_drake_matrix.m to work with this option');
            
            yr = Oceanyears;
            D = zeros([n,n,length(yr)]);
            
            for yy = 1:length(yr)
                y = yr(yy);
                
                D_temp = generate_dispmat_drake(PLD,months,Connmat_Dir);
    
                D_temp = convert_drake_matrix(D_temp,Datename,lookup_table);
    
                D(:,:,yy) = D_temp';
            end % end for yr
            
            conn_mat = D;
            D = [];
            
    end % end switch over Ocean

end % end if PLD < 1


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% conn_mat has origins on columns & destinations on rows%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If not square, error
if numel( conn_mat(:,:,1) ) ~= size( conn_mat,1 )^2
  error( 'Connectivity Matrix not square' );
end

% Make sure sizes match
if size(conn_mat,1) ~= size(lookup_table.ShortID,1)
 %   keyboard
%  error( 'Connectivity matrix and lookup table dont match' );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only allow spawning & settlement at correct depths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Currently don't have depth data, so skip this

% Only allow spawning at depth = spawndepth
% Find bad rows
%OKrows = false(size(lookup_table.Depth));
%for sd = ss.SpawnDepth
%    OKrows = OKrows | lookup_table.Depth == sd;
%end

%conn_mat(:,OKrows == false) = 0; % no spawning at wrong depths

% Only allow settlement at depth = settledepth
% Find bad rows
%OKrows = false(size(lookup_table.Depth));
%for sd = ss.SettleDepth
%    OKrows = OKrows | lookup_table.Depth == sd;
%end

%conn_mat(OKrows == false,:) = 0; % no settling at wrong depths

%conn_mat = conn_mat/num_release; % normalize by number of released larvae

%conn_mat = conn_mat/max(sum(conn_mat)); % normalize so at least one column sums to one

% Find columns and rows with non-NaN data
I = isfinite(conn_mat(:,1,1)) & isfinite(conn_mat(1,:,1)');
J = lookup_table.ShortID(I); % Should be indices of raster files, FRAGILE

cs(1).conn_mat = conn_mat;
cs(1).lookup_table = LUT_short;
cs(1).I = I;
cs(1).J = J;
cs(1).habvec = habvec;
conn_struct(1).(sp) = cs;
end

save conn_mat_NC_2D.mat conn_struct
