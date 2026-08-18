function do_DPR_2D(Option)

% run DPR calculation for 2D model for North Coast

% Update 25 Jan 2013 to run with MARXAN project by J. Schroeger
% Update 21 Apr 2013 to run source metrics project

% Updated 4 March 2010 to fix an erroneous homerange calculation within the
% fleet model.  Likely explains why spatial fishing effort results for large homerange
% fish always looked funny.

% Updated Jan 2025 to include the input argument 'Option' which allows
% switching how to treat the habitat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load in all of the parameters and such
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('source_setup.mat')
load(Species_params_file)
load(XPR_file)
load(connmat_file2)
load(DPR_setup_file)
%load(DPR_setup_opt_file)
%keyboard
savename = optimal_results_savename;


FLEP = [0 0.4 1]; % have to add the unfished scenario
%keyboard
switch Ocean
    case 'montecarlo' % if eventually use Monte Carlo ocean, this will become relevant
        yr = 10;
    case 'fixed'
        yr = 0;
end

DPR_2D_struct = struct([]);

for s = 1:length(Species_Names) % loop across species names
    SN = Species_Names{s};

    Package_Names = fieldnames(res_struct_2D.(Species_Names{s}).pkg); % read out of DPR_setup_opt_file

    %keyboard
    rst = struct;%([]);
    
    HR_matrix = res_struct_2D.(SN).HR_matrix;
    
    conn_mat = conn_struct.(SN).conn_mat; %CONN MAT
    I = conn_struct.(SN).I;
    J = conn_struct.(SN).J;
    lookup_table = conn_struct.(SN).lookup_table;
    
    habras = res_struct_2D.(SN).Habras;
    habvec = res_struct_2D.(SN).Habvec(:); %HAB VEC

    switch Option
        case 'Equal'
            habvec = habvec*0 + 1; % all equal everywhere
    end
    
    % Habvec must be in km^2
    
    switch s
        case 'RedSeaUrchin'
        depvec = res_struct_2D.(SN).Depvec(:); 
        % RSU: depth: 1 if < 30, 0 otherwise
        % other species: same as habvec     
        otherwise
        depvec = habvec;    
    end
   
    % get distance vector & Row-Col codes
   % Habcodes = lookup_table.GridCode;
    %Dist = Dist_master(Habcodes);
    I = conn_struct.(SN).I;
   % rows = lookup_table.RowCode(I);
    %cols = lookup_table.ColCode(I);
    %Rows2 = rows/max(rows);
    %Cols2 = cols/max(cols);
    
    Package_Names = Package_Names';
for p = 1:length(Package_Names) % loop across MPA packages 
        P = Package_Names{p};

        rstp = struct([]);
        
        Resvec = res_struct_2D.(SN).pkg.(P).resvec(:);
        
        %Existing = res_struct_2D.(s).pkg.P0.Resvec; % need this for dynamic fleet

%FIX SLODE AND NOMINAL THRESH
for sl = 1:1%length(Species.(s).slope) % loop over different slopes for the species
    sl = sl;
    
    rstp(1).slope = .25; %Species.(s).slope(sl);
    rstp(1).nominal_slope = 1/Species.(SN).nominal_thresh(sl); %ends up being 4
    
    qrstp = struct([]);
    
   
    
for f = 1:length(FLEP) % loop across FLEPs
    f=f;
    
    qrstp(1).FLEP(f) = FLEP(f);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initial assumption of constant fishing rate
    
    if FLEP(f) < 1
        % find total fishing effort, then distribute among available habitat
    
    % Add a kluge to constrain urchin fishing to shallow water
        switch s
            case 'RedSeaUrchin'
                
                F_total = sum((habvec>0).*(depvec>0).*Species.(SN).fishing(f));
                Area_total = sum((habvec>0).*(depvec>0).*(1-Resvec));
                F_spatial = (depvec>0).*(habvec>0).*(1-Resvec).*F_total./Area_total;
        
                
            case 'DungenessCrab' % only have 1 fishing level
                
                F_total = sum((habvec>0).*(depvec>0).*Species.(SN).fishing(1));
                Area_total = sum((habvec>0).*(depvec>0).*(1-Resvec));
                F_spatial = (depvec>0).*(habvec>0).*(1-Resvec).*F_total./Area_total;
                
            otherwise
                F_total = sum((habvec>0).*Species.(SN).fishing(f));
                %keyboard
                Area_total = sum((habvec>0).*(1-Resvec));
                F_spatial = (habvec>0).*(1-Resvec).*F_total./Area_total;
        end
             
    
    else
        F_spatial = (habvec>0)*0;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    % FIXED FLEET
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch fleet_model
        
        case 'fixed'
    
    % find total fishing pressure for each location
    F_summarized = HR_matrix*F_spatial(:);
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Switch Ocean conditions, Fixed Fleet model
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
     switch Ocean
         
         % Fixed Ocean, fixed fleet
            case 'fixed'
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Create FLEP, BPR, YPR
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Fdist = XPR.(s).Fishing;
        FLEPdist = XPR.(s).FLEP;
        BPRdist = XPR.(s).BPR;
        YPRdist = XPR.(s).YPR;
        
        FLEP_vec = interp1(Fdist,FLEPdist,F_summarized,'spline').*(habvec>0);
        BPR_vec = interp1(Fdist,BPRdist,F_summarized,'spline').*(habvec>0);
        YPR_vec = interp1(Fdist,YPRdist,F_summarized,'spline').*(habvec>0);

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % Run DPR
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
        [eggs,settlers,recruits,selfers] = calculate_dpr( Species.(SN).slope(sl), habvec, FLEP_vec(I), conn_mat(I,I),100, rect_type );
        
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          % Get output vars: settlement, biomass
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            
            qrstp(1).habvec = habvec;
            qrstp(1).sstvec = sstvec;
            qrstp(1).eggs(:,f,:) = eggs(:,end-yr:end);
            qrstp(1).setts(:,f,:) = settlers(:,end-yr:end);
            qrstp(1).rects(:,f,:) = recruits(:,end-yr:end);
            qrstp(1).selfers(:,f,:) = selfers(:,end-yr:end);
            qrstp(1).biomass(:,f,:) = recruits(:,end-yr:end).*repmat(BPR_vec(:),[1,yr+1]);
            qrstp(1).yield(:,f,:) = recruits(:,end-yr:end).*repmat(YPR_vec(:),[1,yr+1]);
            qrstp(1).fishing(:,f,:) = repmat(F_summarized(:),[1,yr+1]);
            qrstp(1).FLEP_vec(:,f) = FLEP_vec;
            qrstp(1).BPR_vec(:,f) = BPR_vec;
            qrstp(1).YPR_vec(:,f) = YPR_vec;
            qrstp(1).reserves = Resvec(:);
        
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
        % Fixed Fleet, Monte Carlo Ocean conditions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            case 'montecarlo'
              
            % get initial age & yield distribution    
            maxage = Species.(s).maxage;
            nbins = 20; %% ** NEED TO FIX THIS so it automatically calculates the number of size classes **

            % rescale slope to work in units of actual settlers, not FLEP
            slope_2 = Species.(s).slope(sl)/Species.(s).LEP_virgin;
            
            N_init = repmat(1,[length(habvec),maxage+1]);
            Y_init = repmat(0,[length(habvec),nbins]); 
            N_init(:,1) = double(habvec);
            noF_spatial = F_summarized.*0;
            [N_init, R S SR Y_init, B, bins] = popmodel(N_init,Y_init,conn_mat(I,I,:),noF_spatial,habvec(:),Species.(s),slope_2,100);
            N_init = N_init(:,:,end);
            Y_init = Y_init(:,:,end);    
         
            % now run the actual model
            % Even for fixed effort, with a dynamic ocean need to run full popmodel with age structure
                [N R S SR Y B bins] = popmodel(N_init, Y_init, conn_mat(I,I,:), F_summarized, habvec(:), Species.(s),slope_2,100);  
                % N is n x age x time
                % R, S, SR are n x time
                % Y, B are n x sizeclass x time
                   
             settlers = S;
             recruits = R;
             selfers = SR;
             biomass = squeeze(sum(B,2));
             yield = squeeze(sum(Y,2));
                                      
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Get output vars: settlement, biomass
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            
            qrstp(1).habvec = habvec;
            qrstp(1).eggs(:,f,:) = NaN;
            qrstp(1).setts(:,f,:) = settlers(:,end-yr:end);
            qrstp(1).rects(:,f,:) = recruits(:,end-yr:end);
            qrstp(1).selfers(:,f,:) = selfers(:,end-yr:end);
            qrstp(1).biomass(:,f,:) = biomass(:,end-yr:end);
            qrstp(1).yield(:,f,:) = yield(:,end-yr:end);
            qrstp(1).fishing(:,f,:) = repmat(F_summarized(:),[1,yr+1]);
            qrstp(1).FLEP_vec(:,f) = NaN;
            qrstp(1).BPR_vec(:,f) = NaN;
            qrstp(1).YPR_vec(:,f) = NaN;
            qrstp(1).reserves = Resvec(:);
            
        end % end switch Ocean

        case {'dynamic','dynamic2'}
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DYNAMIC FLEET MODEL
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create FLEP, BPR, YPR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Fdist = XPR.(SN).Fishing;
            FLEPdist = XPR.(SN).FLEP;
            BPRdist = XPR.(SN).BPR;
            YPRdist = XPR.(SN).YPR;
            
            % number of years to run
            n = 50;
            
            % find total fishing pressure for each location
            F_vec = HR_matrix*F_spatial(:);
            
            % information parameters (could put these in params file)
            nu = 1; % fishers information on fish abundance
            mu = 0.1; % fishers weight on travel costs
            
            % get initial age & yield distribution    
            maxage = Species.(SN).maxage;
            nbins = maxage+1; %% ** May want to fix this to calculate biomass in different size bins than age **
            
            % rescale slope to work in units of actual settlers, not FLEP
            slope_2 = Species.(SN).slope(sl)/Species.(SN).LEP_virgin;
            
            N_init = repmat(1,[length(habvec),maxage+1]);
            Y_init = repmat(0,[length(habvec),nbins]); 
            N_init(:,1) = double(habvec);
            noF_spatial = F_vec(:,1).*0;
        %    keyboard
Species.(SN).Species_Name = SN;            
            [N_init, R_init S_init SR_init Y_init, B_init] = popmodel(N_init,Y_init,conn_mat(I,I,:),noF_spatial,habvec(:),Species.(SN),slope_2,100,rect_type);
            N_init = N_init(:,:,end);
            B_init = B_init(:,:,end);
            Y_init = Y_init(:,:,end);    
           
            
             %pre-allocate
             FLEP_vec = repmat(0,[length(habvec),n]); 
             settlers = FLEP_vec;
             recruits = FLEP_vec;
             selfers = FLEP_vec;
             eggs = FLEP_vec;
             
             biomass = squeeze(sum(B_init,2));
             yield = squeeze(sum(Y_init,2));
            
            % Run pop model
            for i = 2:n
            i = i;
            
            %keyboard
            
            % single iteration of pop model
            [N R S SR Y B E] = popmodel(N_init, Y_init, conn_mat(I,I,:), F_vec(:,i-1), habvec(:), Species.(SN),slope_2,2,rect_type);  
                % N is n x age x time
                % R, S are n x time
                % Y, B are n x sizeclass x time
            
                settlers(:,i) = S(:,end);
                recruits(:,i) = R(:,end);
                selfers(:,i) = SR(:,end);
                eggs(:,i) = E(:,end);
                biomass(:,i) = sum(B(:,:,end),2);
                yield(:,i) = sum(Y(:,:,end),2);
                N_init = N(:,:,end);
                Y_init = Y(:,:,end);
            
            % Adjust fleet to biomass
            
            % Need to redistribute biomass according to homerange use?
            
            % blank this out to make dynamic fleet model run with constant effort
            switch fleet_model
                case 'dynamic'
                F_spatial = dynamic_fleet(F_vec(:,i-1),(HR_matrix')*biomass(:,i),habvec>0,depvec>0,Resvec,nu);
                case 'dynamic2'
                    
                    % RSU gets slightly different fleet parameters
                    switch s
                        case 'RedSeaUrchin'
                            fp = fleet_params;
                        otherwise
                            fp = fleet_params;
                            fp(4:8) = 0;
                    end
                    
                    
                F_spatial = dynamic_fleet_v2(F_vec(:,i-1),(HR_matrix')*biomass(:,i),habvec>0,depvec>0,Resvec,nu,Dist,Rows2,Cols2,fp);  
            end
            
            F_vec(:,i) = HR_matrix*F_spatial(:);
            
            FLEP_vec(:,i) = interp1(Fdist,FLEPdist,F_vec(:,i),'spline').*(habvec>0);
            
            
            % potential break
            if sum(recruits(:,i-1) == recruits(:,i)) == length(habvec)
                
                ii = i
                
                settlers(:,i:n) = repmat(settlers(:,i),[1,n-i+1]);
                recruits(:,i:n) = repmat(recruits(:,i),[1,n-i+1]);
                selfers(:,i:n) = repmat(selfers(:,i),[1,n-i+1]);
                eggs(:,i:n) = repmat(eggs(:,i),[1,n-i+1]);
                biomass(:,i:n) = repmat(biomass(:,i),[1,n-i+1]);
                yield(:,i:n) = repmat(yield(:,i),[1,n-i+1]);
                F_vec(:,i:n) = repmat(F_vec(:,i),[1,n-i+1]);
                FLEP_vec(:,i:n) = repmat(FLEP_vec(:,i),[1,n-i+1]);
                
                break
                
            end % end potential break if loop
                
            end % end i loop for fleet-pop model
    
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Get output vars: settlement, biomass
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
            qrstp(1).habvec = habvec;
            qrstp(1).eggs(:,f,:) = eggs(:,end-yr:end);
            qrstp(1).setts(:,f,:) = settlers(:,end-yr:end);
            qrstp(1).rects(:,f,:) = recruits(:,end-yr:end);
            qrstp(1).selfers(:,f,:) = selfers(:,end-yr:end);
            qrstp(1).biomass(:,f,:) = biomass(:,end-yr:end);
            qrstp(1).yield(:,f,:) = yield(:,end-yr:end);
            qrstp(1).fishing(:,f,:) = F_vec(:,end-yr:end);
            qrstp(1).FLEP_vec(:,f,:) = FLEP_vec(:,end-yr:end);
            qrstp(1).BPR_vec(:,f,:) = NaN;
            qrstp(1).YPR_vec(:,f,:) = NaN;
            qrstp(1).reserves = Resvec(:);
            
            
    end % end switch fleet model
    
    clear recruits settlers selfers biomass yield F_vec FLEP_vec
                                      
end % end loop over FLEPs

eval(strcat(['rstp.slope',num2str(sl),' = qrstp;']))

clear yield_vec bio_vec_distributed spatial_rect_vec spatial_fishing_vec spatial_FLEP_vec spatial_setts_vec spatial_selfers_vec
clear yield_mat biomass_mat rect_mat setts_mat selfers_mat fishing_mat flep_mat Hab_mask2 Hab_mask


end % end loop over slopes

rst.(P) = rstp;
%keyboard
clear Res rstp

end % end loop over packages
%keyboard

DPR_2D_struct(1).(SN).pkg = rst;

clear habras habvec HR_matrix  rst

end % end loop over species
                                      
save(savename,'DPR_2D_struct','-v7.3');% save DPR_2D_struct
clear all