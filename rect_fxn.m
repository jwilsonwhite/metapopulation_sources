function R = rect_fxn(L,rect_type,Rmax,slope)

% implements several different recruitment functions
%load NCC_species_parameters.mat

switch rect_type
    
    case 'hockey'
        
        R = slope.*L;
        R = min(Rmax,R);
        
        
    case {'Bev-Holt','bev-holt'} 
        
        R = slope.*L./(1+slope.*L./Rmax);
        
    otherwise
        
end

R(isnan(R)) = 0; % sometimes NaNs pop up because of divide-by-zero.  Constrain to zero.