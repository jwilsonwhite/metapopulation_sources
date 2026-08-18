function get_spatial_vars_2D(Datename,Species_Names,Species, connmat_file)
%NORTHERN COAST

% Creates structure variable holding vectors of habitat & reserve data for
% each species & package
% Also creates matrices for homerange operations

% This has been altered from original version to operate at scale of ROMS
% cells for Perron REU project. As a result, habitat vector for each
% species was already created in get_connmat.m

%load DPR_2D_params.mat

load(connmat_file)

eval(strcat('load Hab_and_Pkgs_',Datename,'.mat'))  
% holds files with rasters of where habitat &
% GIS-coded MPAs are
% created by make_rasters.m

clear Hab_lookup Habitat Reserve Reserve_area habras
%clear some unnecessary things

%eval(strcat('load NC_reserve_protection_levels',Datename,'.mat')) % this contains the level of protection for each MPA (in struct Package_Descrips)

load conn_mat_NC_2D.mat % connectivity matrices

res_struct_2D = struct([]);

for s = 1:length(Species_Names) % loop across species names
    
 %   lookup_table = conn_struct.(s).lookup_table;
    %keyboard
    rs = Species.(Species_Names{s});
    
    % Find correct habitat raster
    switch rs.hab_type
        case 'Hard_0-30'
            habras = habras_Hard_0_30;
        case 'Hard_30-100'
            habras = habras_Hard_30_100;
        case 'Hard_0-100'
            habras = habras_Hard_0_100;
        case 'Soft_0-30'
            habras = habras_Soft_0_30;
        case 'Soft_30-100'
            habras = habras_Soft_30_100;
        case 'Soft_0-100'
            habras = habras_Soft_0_100;
    end
    
  
%res_struct_2D(1).(s).pkg.(p).Res = Res;
%res_struct_2D(1).(s).pkg.(p).Resvec = resvec;
res_struct_2D(1).(Species_Names{s}).Habras = habras;
res_struct_2D(1).(Species_Names{s}).Habvec = conn_struct.(Species_Names{s}).habvec;
%res_struct_2D(1).(s).Depvec = depvec;


% Now calculate distribution of homerange use
% this is now obsolete because we are using bigger cells and ignoring
% movement
%HR_temp = calculate_2D_homerange(habras,s,Species); 

% Add in a diagonal matrix here to indicate no movement
res_struct_2D(1).(Species_Names{s}).HR_matrix = diag(ones(length(conn_struct.(Species_Names{s}).habvec),1));


end % end loop across spp

save DPR_2D_spatial_vars.mat res_struct_2D








