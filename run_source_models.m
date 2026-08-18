function run_source_models(Region,Option,Option2)

% This code runs the source-sink models for source definitions paper
% Operates on both SCSR & NCSR results

% Region is NCSR or SCSR (North coast/South coast)
% Option is:
% 'Equal' equal habitat everywhere
% 'Actual' realistic habitat
% 'Realized' realistic habitat, but source metrics calculated using
% realized connectivity instead of raw connectivity.

% Option2 is:
% 'Together' results will be plotted for MPAs designed the same for all
% species
% 'Indiv' results will be plotted for MPAs designed separately for each
% species

% Generate results for each species individually and for combined reserve
% networks

if ~exist('Region','var')
Region = 'SCSR';
end


% Name some files & associate metadata
switch Region
    case 'NCSR'
     % Input metadata:
     Species_Names = {'BlackRockfish','Cabezon','BrownRockfish','RedAbalone'};
     Species_params_file = 'NCSR/NC_2D_setup_params.mat';
     XPR_file = 'NCSR/XPR_NC.mat';
     Hab_Pkgs_file = 'NCSR/Hab_and_Pkgs_Dec14.mat';
     Datename = 'Dec14';
     connmat_dir = 'Drake_connmat_Apr2010';
    
        
   % Possibly deprecated now, cleaning up:
   connmat_file = 'conn_mat_NC_2D.mat';
   connmat_file2 = 'NCSR/conn_mat_NC_2D.mat';
   DPR_file = 'NCSR/DPR_2D_redist_Round1.mat';
   DPR_setup_file = 'NCSR/DPR_2D_spatial_vars.mat';
   
   Del_postproc = 'NCSR/Del_postproc_results_Round1.mat';
   res_file = 'NCSR/res_ID_str_Round1.mat';

    DPR_setup_opt_file = 'NCSR/NC_2D_setup_params.mat';%DPR_2D_opt_setup_NCSR.mat';
    DPR_spatial_setup_opt_file = 'NCSR/DPR_2D_spatial_vars_opt_NCSR.mat';
    
    case 'SCSR'
        %Input metadata:
        Species_Names = {'BlackSurfperch','Opaleye','KelpBass','KelpRockfish','Sheephead'};
        Species_params_file = 'SCSR/SC_2D_setup_params.mat';
        XPR_file = 'SCSR/XPR_SC.mat';
        Hab_Pkgs_file = 'SCSR/Hab_and_Pkgs_May2013.mat';
        Datename = 'May2013';
        connmat_dir = 'null';
        
    
   connmat_file = 'conn_mat_SC_2D.mat';
   connmat_file2 = 'SCSR/conn_mat_SC_2D.mat';
   DPR_file = 'SCSR/DPR_2D_Round1_redist.mat';
   DPR_setup_file = 'SCSR/DPR_2D_spatial_vars.mat'; %'SCSR/DPR_2D_spatial_vars_Round1.mat';
   Hab_Pkgs_file = 'SCSR/Hab_and_Pkgs_May2013.mat';

   %Species_params_file = 'SCSR/SC_species_struct.mat';
   % optimal_results_savename = 'DPR2D_SCSR_opt_15June2016_all.mat';
    DPR_setup_opt_file = 'SCSR/SC_2D_setup_params.mat'; %DPR_2D_opt_setup_SCSR.mat'
    DPR_spatial_setup_opt_file = 'DPR_2D_spatial_vars_opt_SCSR.mat';
    
end

    % Output_metadata:
    stats_savename = strcat('rect_stats_str_',Region,'_',Option,'.mat');
    source_savename = strcat('source_metrics_str_',Region,'_',Option,'.mat');
    optimal_codes_savename = strcat('optimal_codes_',Region,'_',Option,'.mat');
    optimal_results_savename = strcat('DPR2D_',Region,'_',Option,'_opt_23Mar2026_all.mat');

% Options for model runs:
FLEP = [0, 0.4];
Rounds=1;
fleet_model = 'dynamic';
rect_type = 'Bev-Holt';
Ocean = 'fixed';
save('source_setup.mat','Region','connmat_file','connmat_file2','Hab_Pkgs_file','Species_Names','Species_params_file','FLEP','Rounds', ...
    'DPR_file','XPR_file','DPR_setup_file','DPR_setup_opt_file','DPR_spatial_setup_opt_file','stats_savename','source_savename','optimal_codes_savename',...
        'optimal_results_savename','Ocean','fleet_model','rect_type')

% Setup the connectivity & habitat spatial data:
% Need to switch over region, step into NCSR or SCSR directory & run the
% appropriate file
cd(Region) % change to directory for the study region to obtain region-specific data
get_conn_mat(Species_Names,Species_params_file,Hab_Pkgs_file,connmat_dir,'fixed')
load(Species_params_file,'Species')
%keyboard
get_spatial_vars_2D(Datename,Species_Names,Species,connmat_file);
find_FLEP_threshold_2D(Species_Names,Species);
get_XPR_vs_F(Species_Names,Species);

cd .. %  step back out to main directory

% Now you can do this:
%load DPR_2D_spatial_vars.mat res_struct_2D
%load conn_mat_NC_2D.mat conn_struct
% All of the necessary spatial variables are in those two structures

doRuns = false;
if doRuns
get_source_statistics(Region,Option);

%get_optimal_packages % do the ranking
%run_optimal_combos_setup % generate all of the necessary setup parameters
do_DPR_2D(Option);
end



%practice_graphs(Region)

analyze_optimal_combos(Region,Option,Option2,1)

