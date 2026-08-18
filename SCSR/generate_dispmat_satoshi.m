function D = generate_dispmat_satoshi(year,months,PLD,behav)

% generate useable dispersal matrix from satoshi's data

% year as a numeric
% months as numerics (scalar or vector)
% PLD as numeric (scalar or vector)

% behav must be 'pass' (passive particle) or 'surf' (maintains 5m depth)

mat_dir = num2str(year); % directory for results

n = 135; % should be a constant number of sites for all Satoshi results

area = pi*5^2; % area of a Satoshi grid cell

D = zeros(n);

for m = months
    
    for p = 1:length(PLD)
        pp = PLD(p);
        

    if m >= 10
    monthname = num2str(m);
    else
        monthname = strcat(['0',num2str(m)]); % must have a leading zero
    end 
    
    
eval(strcat(['load Satoshi_matrix/',behav,'/',mat_dir,'/connect_',monthname,'.mat'])) %read in the proper file, should contain structure 'connect'

pp;
mat_dir;
monthname;
size(connect.Matrix);

%keyboard

D_temp = connect.Matrix(:,:,pp)*area; % multiply by area to get probabilities

D = D + D_temp; % add in each new matrix

    end % end for PLD
    
end % end for months


D = D./(length(months)*length(PLD)); % rescale to obtain probabilities averaged across months & all PLDs




