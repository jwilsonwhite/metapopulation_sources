function XPR = get_XPR_vs_F(Species_Names,Species)

% given range of F values, this calculates distribution of LEP, YPR, BPR 

%load DPR_2D_params.mat
%load FLEP_thresh_2D.mat Species % note that this file contains the version of 'Species' with the slope param


Fdist = 0:0.01:50;


for sp = Species_Names % for each species
    sp = sp{:};

        % Retrieve parameters for this species
        
        pre_l_a = Species(1).(sp).pre_l_a;
        size_a = Species(1).(sp).size_a;
        matage = Species(1).(sp).matage;
        rec = Species(1).(sp).rec;
        tc = Species(1).(sp).tc;
        egg_a = Species(1).(sp).egg_a;
        LEP_virgin = Species(1).(sp).LEP_virgin;
        mature = Species(1).(sp).mature;
        len_a = Species(1).(sp).len_a;

        switch sp
            case 'Abalone'
                % for abalone, there is a different natural mortality rate
                % for indivs that enter the fishery. So pre-recruitment
                % mortality is already summarized in pre_l_a, and now the
                % (smaller) mortality rate for fishery recruits can be used
                % as M
                % Note that this assumes that tc = 13
                M = Species(1).Abalone.M_ab(2);
            otherwise % all other species
                M = Species(1).(sp).M;
        end
        

        for f = 1:length(Fdist) % for each value of F
            
            F = Fdist(f);
            
            %M and F for recruits
            %need tc(r)+1 above since MATLAB indexes from 1 but age indexes
            %from zero
            rec_l_a=pre_l_a(tc).*exp((-(M+F)).*(matage-tc+1)).*rec; 
           
            rec_l_a(isnan(rec_l_a)) = 0; % this fixes weird errors caused by unusual mortality rates
            

            %add recruits and pre recruits together    
            fished_l_a=pre_l_a + rec_l_a;  
    
            %get LEP for fished population
            switch sp
                case 'DungenessCrab'
                    LEP_fishing = 1;
                otherwise
            LEP_fished= sum(fished_l_a .* egg_a .* mature);
            end

            %get fractional LEP (FLEP) by dividing LEP_fished by LEP_virgin
            FLEP(f) = LEP_fished / LEP_virgin;
            
            %calculate the number caught from each age
            dead_l_a = fished_l_a(tc+1:end-1) - fished_l_a(tc+2:end); 
            dead_l_a = [repmat(0,[1,tc+1]), dead_l_a];
            
            caught_l_a = dead_l_a.*(F/(M + F)); % the proportion that are caught
            
            
            caught_l_a(isnan(caught_l_a)) = 0; % this fixes weird errors caused by unusual mortality rates
            
            
            YPR(f) = caught_l_a(:)'*size_a(:); % number caught in each size class * biomass
            
            %calculate biomass-per-recruit
            BPR(f) = fished_l_a(:)'*size_a(:); %proportion in each size class * biomass
            
            
        end % end for Fdist
        
        
        XPR(1).(sp).Fishing = Fdist;
        XPR(1).(sp).FLEP = FLEP;
        XPR(1).(sp).BPR = BPR;
        XPR(1).(sp).YPR = YPR;
        
end % end for sp

save XPR_NC.mat XPR
        