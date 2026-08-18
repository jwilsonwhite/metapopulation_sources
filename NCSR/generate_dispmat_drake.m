function D = generate_dispmat_drake(PLD,months,Connmat_Dir)

% generate useable dispersal matrix from Patrick Drake's data

% months as numerics (scalar or vector)
% PLD as numeric (scalar or vector)

Dir = Connmat_Dir;

n = 81; % should be a constant number of sites 

Monthnames = {'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'};

D = zeros(n);

    
    if PLD > 135 % BlackRockfish
        
        PLD_name = '120d_180d';
        
    elseif PLD < 135 && PLD > 60 % RedSeaUrchin, Cabezon, DungenessCrab
        
        PLD_name = '90d_120d';
        
    elseif PLD < 60 && PLD > 10 % BrownRockfish
        
        PLD_name = '30d_60d';
        
    elseif PLD < 10 % Abalone 
        
        PLD_name = '4d_7d';
        
    end
        
        
for m = months
        
monthname = Monthnames{m};

% Drake created matrices using 2 different settlement criteria: 10 km from
% shore, and the 250m isobath.  These are essentially equivalent except at
% Farallon Is., so use them interchangeably here.  Use 250 m preferentially
filename1 = strcat([Dir,'/settlement_combined_2000_2006_',monthname,'_',monthname,'_1.0deg_250m_',PLD_name,'.mat']);
filename2 = strcat([Dir,'/settlement_combined_2000_2006_',monthname,'_',monthname,'_1.0deg_10km_',PLD_name,'.mat']);    

if exist(filename1,'file')
    eval(strcat(['load ',filename1]))
elseif exist(filename2,'file')
    eval(strcat(['load ',filename2]))
else
   % keyboard
end

D_temp = FLTCW.conmat1;

D = D + D_temp; % add in each new matrix

end % end for months

D = D./(length(months)); % rescale to obtain probabilities averaged across months & all PLDs

%keyboard


