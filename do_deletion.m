function [Delete,All_patches_biomass] = do_deletion(Region, Species_Name, Delete)

switch Region
    case 'NCSR'
        Setup_params = 'NCSR/NC_2D_setup_params.mat';
        Res_Struct = 'NCSR/DPR_2D_spatial_vars.mat';
        Conn_Struct = 'NCSR/conn_mat_NC_2D.mat';
        Pat_Num = 19;
        
    case 'SCSR'
        Setup_params = 'SCSR/SC_2D_setup_params.mat';
        Res_Struct = 'SCSR/DPR_2D_spatial_vars.mat';
        Conn_Struct = 'SCSR/conn_mat_SC_2D.mat';
        Pat_Num = 135;
end

load(Setup_params);
load(Res_Struct); %res_struct_2D
load(Conn_Struct) %conn_struct

%SN = fieldnames(conn_struct); %species name
speciesname = Species_Name;

%not altering original conn_mat in order to get biomass over all patches
conmat_orig = conn_struct.(speciesname).conn_mat; %saves original, just in case

%puts the unchanged conn_mat into alt_conn_mat for reference purposes in
%do_fake_DPR_2D
conn_struct.(speciesname).alt_conn_mat = conn_struct.(speciesname).conn_mat; 
%keyboard
Res_vec = ones(Pat_Num,1);
res_struct_2D.(speciesname).pkg.deletion.resvec = Res_vec;

%keyboard
save(Res_Struct); %, res_struct_2D);
save(Conn_Struct); %, conn_struct);
%{
  save 'SCSR/DPR_2D_spatial_vars.mat' res_struct_2D;
  save 'SCSR/conn_mat_SC_2D.mat' conn_struct;
%}
        
Fake = do_fake_DPR_2D(Region,(speciesname));
%keyboard
All_patches_biomass = sum(Fake.(speciesname).pkg.deletion.slope1.biomass(:,3));

for j = 1:Pat_Num
    OK = false(Pat_Num,1);
    OK(j) = true;
        
    conmat_temp = conn_struct.(speciesname).conn_mat;
    conmat_temp(OK, OK) = 0;
    conn_struct.(speciesname).alt_conn_mat = conmat_temp;

    avg_metrics.deletion.res_vec = Res_vec;    
    
    %saving the Res_vec to res_struct_2D.(species)
    res_struct_2D.(speciesname).pkg.deletion.resvec = Res_vec;
        
    save(Res_Struct); %, res_struct_2D);
    save(Conn_Struct); %, conn_struct);
   
    Fake = do_fake_DPR_2D(speciesname);
    %keyboard
    Biomass = Fake.(speciesname).pkg.deletion.slope1.biomass(:,3);
    
    Delete(j) = 1 - (sum(Biomass) / All_patches_biomass );

    end %end loop over patches
    
%keyboard
end 