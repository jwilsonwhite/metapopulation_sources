function D_out = convert_satoshi_matrix(D_in,Datename,lookup_table)

% converts 135x135 dispersal matrix created by Satoshi
% into a matrix useable with 1km-resolution habitat matrix

ras = load('rasallocate/rasallocate2.txt'); % map of assignments for each habitat raster to each Satoshi cell

eval(strcat('load Hab_and_Pkgs_',Datename,'.mat')) 

%load conn_mat_SC_2D.mat  conn_struct

%cs = conn_struct.(Speciesname);

newD = zeros(length(lookup_table.ShortID));
Destmat = newD;

for i = 1:length(lookup_table.ShortID) % loop over every cell of suitable habitat for this species
    r = lookup_table.RowCode(i);
    c = lookup_table.ColCode(i);
    
    Satoshi_origin = ras(r,c); % ID of corresponding Satoshi cell
    Destvec(i) = Satoshi_origin; % keeping track of how many 1km cells are assigned to each Satoshi cell
    
    %total_cells = 0; % keep track of how many 1km cells are destinations for this origin
    
    for j = 1:length(lookup_table.ShortID) % now loop over all possible destinations
        rr = lookup_table.RowCode(j);
        cc = lookup_table.ColCode(j);
        
        Satoshi_dest = ras(rr,cc); % ID of corresponding Satoshi cell
        
        newD(i,j) = D_in(Satoshi_origin,Satoshi_dest);
        
        Destmat(i,j) = Satoshi_dest; % keep track of how many 1km cells have the same destination Satoshi cell
        
        %total_cells = total_cells + 1; 
        
    end % end loop over possible destinations
    
    %newD(Satoshi_origin,:) = newD(Satoshi_origin,:)./total_cells; % rescale by total number of destinations involved
    
end % end loop over origins
    
unique_dest = unique(Destmat);

for i = 1:length(unique_dest)
    
    t = sum(sum(Destvec == unique_dest(i)));
    
    newD(Destmat == unique_dest(i)) = newD(Destmat == unique_dest(i))./t;
    
end

D_out = newD;

%keyboard