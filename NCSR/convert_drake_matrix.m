function D_out = de-convert_drake_matrix(D_in,lookup_table)

% converts 81x81 dispersal matrix created by Patrick Drake
% into a matrix useable with 1km-resolution habitat matrix

% This version_

%eval(strcat('load Hab_and_Pkgs_',Datename,'.mat')) 

newD = zeros(length(lookup_table.ShortID));
Destmat = newD;
ROMS_origin = zeros(length(lookup_table.ShortID),1);

for i = 1:length(lookup_table.ShortID) % loop over every cell of suitable habitat for this species
    %r = lookup_table.RowCode(i);
    %c = lookup_table.ColCode(i);
    ROMS_origin(i) = lookup_table.ROMScode(i); % ID of corresponding ROMS cell
    %Destvec(i) = ROMS_origin(i); % keeping track of how many 1km cells are assigned to each ROMS cell
    
    for j = 1:length(lookup_table.ShortID) % now loop over all possible destinations
        %rr = lookup_table.RowCode(j);
        %cc = lookup_table.ColCode(j);
        
        ROMS_dest = lookup_table.ROMScode(j); % ID of corresponding ROMS cell
        
        newD(j,i) = D_in(ROMS_dest,ROMS_origin(i)); % destination on rows, origin on columns
        
        Destmat(j,i) = ROMS_dest; % keep track of how many 1km cells have the same destination ROMS cell
        
    end % end loop over possible destinations
    
 
end % end loop over origins
    
%standardize by number of destinations
%unique_dest = unique(Destmat);
%newD_temp = newD;

%for i = 1:length(lookup_table.ShortID)
    
%    unique_dest = unique(Destmat(:,i));
    
%    for j = 1:length(unique_dest)
%        
%        t = sum(Destmat(:,i) == unique_dest(j));
        
%        newD(Destmat(:,i) == unique_dest(j),i) = newD(Destmat(:,i) == unique_dest(j),i)./t;
%    end
    
%end

unique_dest = unique(Destmat);

for i = 1:length(unique_dest)
    
    t = sum(sum(Destmat(:,1) == unique_dest(i)));
    
    newD(Destmat == unique_dest(i)) = newD(Destmat == unique_dest(i))./t;
    
end
%keyboard

D_out = newD;

