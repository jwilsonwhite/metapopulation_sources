function [D_out,Hab_out,lookup_table_short] = de_convert_satoshi_matrix(D_in,lookup_table,Hab_in)

% Forked from de_convert_satoshi_matrix

% Inputs:
% D_in = raw connectivity matrix
% lookup_table = structure containing mappings from ROMS cells to
% high-resolution habitat grid
% Hab_in = habitat vector for this species

% Outputs:
% D_out = same as D_in
% lookup_table_short  = structure corresponding to lookup_table but at
% spatial resolution of D_in
% Hab_out = habitat vector at resolution of D_out

%eval(strcat('load Hab_and_Pkgs_',Datename,'.mat')) 

%newD = zeros(length(lookup_table.ShortID));

%Destmat = newD;
%ROMS_origin = zeros(length(lookup_table.ShortID),1);
ras = load('rasallocate/rasallocate2.txt'); % map of assignments for each habitat raster to each Satoshi cell


%ROMS_indices = unique(lookup_table.ROMScode); % the list of ROMS cell codes
ROMS_indices = unique(ras); % the list of ROMS cell codes


newD = zeros(length(ROMS_indices));

Hab_out = zeros(length(ROMS_indices),1); % new habitat vector

lut_ROMScode = Hab_out;
lut_Habind = cell(length(Hab_out),1);

for i = 1:length(ROMS_indices)
    
    ROMS2Hab = ras == ROMS_indices(i); % the cells that fall within this ROMS cell
    
    [r,c] = find(ROMS2Hab);
    Hab_tmp = nan(size(Hab_in));
    for rr = 1:length(r)
       Hab_ok = r(rr) == lookup_table.RowCode &  c(rr) == lookup_table.ColCode; % find matching cells in lookup table
       if any(Hab_ok)
           try
       Hab_tmp(rr) = Hab_in(Hab_ok);
           catch
               keyboard
           end
       end
    end
    
    Hab_out(i) = nansum(Hab_tmp);
  %  Hab_out(i) = nanmean(Hab_in(ROMS2Hab)); % the new aggregated habitat is just the mean of all the cells
    
    lut_ROMScode(i) = ROMS_indices(i);
    lut_Habind{i} = ROMS2Hab;
    
    for j = 1:length(ROMS_indices)
        
        newD(i,j) = D_in(ROMS_indices(i),ROMS_indices(j));
        
    end % end loop over ROMS indices
    
end % end loop over ROMS indices

lookup_table_short(1).ROMScode = lut_ROMScode;
lookup_table_short(1).Habindices = lut_Habind;

D_out = newD;

