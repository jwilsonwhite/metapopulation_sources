function get_conn_mat(Species_Names,Species_params_file,Hab_Pkgs_file,Connmat_Dir,Ocean,Oceanyears)

% reads in and cleans up connectivity matrix from text files
% for 2D DPR model for SoCal

% save results in conn_mat_2D.mat
% major outputs:
%       conn_mat = connectivity matrix
%       I = indices of conn_mat with non-NaN values
%       inres_I = logical of reserves/not reserve

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load in parameters and filenames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(Species_params_file); % load DPR_2D_params.mat
load(Hab_Pkgs_file); %

conn_struct = struct([]);

% Must loop over each species
for s = 1:length(Species_Names)
    sp = Species_Names{s};

    ss = Species.(sp);
    cs = struct([]);
    
    % Find correct habitat raster to use to create lookup table
    switch ss.hab_type
        case 'Hard_0-30'
            habras = habras_Hard_0_30';
        case 'Hard_30-100'
            habras = habras_Hard_30_100';
        case 'Hard_0-100'
            habras = habras_Hard_0_30'+habras_Hard_30_100';
        case 'Soft_0-30'
            habras = habras_Soft_0_30';
        case 'Soft_30-100'
            habras = habras_Soft_30_100';
        case 'Soft_0-100'
            habras = habras_Soft_0_30'+habras_Soft_30_100';
    end
    
    % the transpose in this assignment is needed.  The rasters from Doug read cell numbers
    % L-R in columns, then top-down in rows.  But the Matlab 'find' operator always reads
    % down columns first, then across in rows.  The transpose forces find to read the same
    % way Doug does
    
    % update (2018): Not sure about that transpose - seems to screw up the
    % way the lookup table works.
    habras = habras';
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create lookup table 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lookup_table(1).GridCode = find(habras')';
%[Rows,Cols] = find(habras);
lookup_table(1).RowCode = Hab_lookup(find(habras'),2); % lookup table of just desired habitat
lookup_table(1).ColCode = Hab_lookup(find(habras'),3);

n = length(lookup_table.GridCode);

lookup_table(1).ShortID = (1:n)';

%lookup_table = csvread_lookup_file( ss.lookup_file, ss.lookup_numeric_columns );
  
    % Make a vector of Habitat
    habvec = zeros(length(lookup_table.RowCode),1);
    for j = 1:length(habvec)
        habvec(j) = habras(lookup_table.RowCode(j),lookup_table.ColCode(j));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get connectivity matrix and clean of NaN's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


PLD = ss.PLD;
behav= 'pass';
months = ss.SpawnSeason;

% temporary bodge to deal with spawning that spans Dec-Jan
months = unique(months);

if PLD < 1 % if no larval dispersal %this is where its at right now
    
    D_temp = diag(ones(1,n));
   [conn_mat,H,LUT_short] = de_convert_satoshi_matrix(D_temp,lookup_table,habvec);

    habvec= H;
    
else % if PLD > 1

    switch Ocean
        case 'fixed' % fixed average connectivity matrix
        
    yr = Oceanyears;
    D = zeros(135);
    for y = yr
        D_temp = generate_dispmat_satoshi(y,months,PLD,behav);
   
       [D_temp,H,LUT_short] = de_convert_satoshi_matrix(D_temp,lookup_table,habvec);
       
       %keyboard

        %D2 = D_temp;
        
       % D_temp = convert_satoshi_matrix(D_temp,Datename,lookup_table);
    
      %  size(D)
      %  size(D_temp);
    
        D = D + D_temp;
    end % end loop over years

    %keyboard
    D = D./length(yr);
    D = D';
    
    % 

    
    conn_mat = D;
    D = [];
    
    habvec= H;
    
    

        case 'montecarlo' % have multiple dispersal matrices & draw from them randomly
            
                        error('This option is not currently supported, need to update de_convert_satoshi_matrix.m to work with this option');

            yr = Oceanyears;
            D = zeros([n,n,length(yr)]);
            
            for yy = 1:length(yr)
                y = yr(yy);
                
                D_temp = generate_dispmat_satoshi(y,months,PLD,behav);
    
                D_temp = convert_satoshi_matrix(D_temp,Datename,lookup_table);
    
                size(D)
                size(D_temp)
                
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
 % error( 'Connectivity matrix and lookup table dont match' );
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

save conn_mat_SC_2D.mat conn_struct
