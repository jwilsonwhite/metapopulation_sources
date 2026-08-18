function F_spatial = dynamic_fleet(F_spatial_init,N,Habvec,Depvec,Res,nu,Dist,mu)

% Do dynamic fishing fleet model for SC


N = N.*(1-Res).*(Depvec>0); % can only see non-reserve biomass in correct depth

% how is F losing value over time? %%%%%%%%%%%%%%

F_total = sum(sum(F_spatial_init));

if nansum(nansum(N.^(1/nu))) ~= 0 % if there is any N

F_spatial = F_total .* ( N.^(1/nu)./nansum(nansum(N.^(1/nu))) ) .* (Depvec > 0); % .* ( 1./Dist.^(1/mu) ./ sum(1./Dist.^(1/mu)) );

else

    F_spatial = F_spatial_init;
    % (otherwise, just do nothing)
    
end

%keyboard