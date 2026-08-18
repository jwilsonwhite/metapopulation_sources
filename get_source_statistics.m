function get_source_statistics(Region,Option)

%Assigning values based on region
switch Region
    case 'NCSR'
        load('NCSR/DPR_2D_spatial_vars.mat'); %res_struct_2D
        load('NCSR/conn_mat_NC_2D.mat') %conn_struct
        avg_metrics = 'avg_metrics_NCSR.mat';
        Pat_Num = 19;
        MPA_num = 4;

    case 'SCSR'
        load('SCSR/DPR_2D_spatial_vars.mat'); %res_struct_2D
        load('SCSR/conn_mat_SC_2D.mat') %conn_struct
        avg_metrics = 'avg_metrics_SCSR.mat';
        Pat_Num = 135;
        MPA_num = 27;
end


SN = fieldnames(conn_struct); %species names
Snum = length(SN); % number of species

avg_metrics = struct;
%creating the array to store average data
%currently hard codes the size, should fix
avg_metrics.habitat.mean = zeros(Pat_Num,1+Snum); 
avg_metrics.self_retain.mean = zeros(Pat_Num,1+Snum);
avg_metrics.self_recruit.mean = zeros(Pat_Num,1+Snum);
avg_metrics.export.mean = zeros(Pat_Num,1+Snum);
%avg_metrics.lifetime_export.mean = zeros(Pat_Num,1+Snum);
avg_metrics.import.mean = zeros(Pat_Num,1+Snum);
avg_metrics.centrality.mean = zeros(Pat_Num,1+Snum);
avg_metrics.scaled_centrality.mean = zeros(Pat_Num,1+Snum);
avg_metrics.contribution.mean = zeros(Pat_Num,1+Snum);
avg_metrics.deletion.mean = zeros(Pat_Num,1+Snum);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Looping over each species, calculating metric data, 
%adding it to fields, and ranking it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for s = 1:length(SN)

speciesname = SN{s}; % extract the desired element of SN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% March 2026 – don't do this anymore, use the habitat instead
%switch Option
%    case 'Realized' % obtain the values of larval production for a 'realized' connectivity matrix
%[~,Biomass] = do_deletion(Region, speciesname, []);
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Hab-Habitat: proportion in cell, (0,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Hab_vec = (conn_struct.(speciesname).habvec).';

%Normalizing
Sum = sum(Hab_vec);
Hab_vec = Hab_vec / Sum;

conn_struct.(speciesname).raw_metrics.habitat = Hab_vec; %adding new field

[~,Index]=sort(Hab_vec,'descend'); %sort based on greatest value
Rank = 1:length(Index);
J = Rank;
J(Index) = Rank;


conn_struct.(speciesname).rankings.habitat = J;

 avg_metrics.habitat.mean(:,s) = J;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SR-Self Retention: Diagonal of the conn_mat, (0,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SR = []; 
SR = diag(conn_struct.(speciesname).conn_mat).';

%Multiplying by the habitat to account for habitat too
%But not doing it so that SR and habitat are different
%SR = SR.*Hab_vec; 
switch Option
    case 'Realized'
       % SR = SR.*Biomass;
       SR = SR.*Hab_vec;
end

%Normalizing
Sum = sum(SR);
SR = SR / Sum;

conn_struct.(speciesname).raw_metrics.self_retain = SR;

[~,Index]=sort(SR,'descend'); %sort based on greatest value
Rank = 1:length(Index);
K = Rank;
K(Index) = Rank;


conn_struct.(speciesname).rankings.self_retain = K;

%adding each patch ranking to the average matrix
avg_metrics.self_retain.mean(:,s) = K;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SRt-Self Recruitment: Proportional self-recruitment, (0,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SRt = []; 
SRt = diag(conn_struct.(speciesname).conn_mat).';
Denom = sum(conn_struct.(speciesname).conn_mat).';
SRt = SRt./Denom; % 

%Multiplying by the habitat to account for habitat too
%But not doing it so that SR and habitat are different
%SR = SR.*Hab_vec; 
switch Option
    case 'Realized'
       % SR = SR.*Biomass;
       SRt = SRt.*Hab_vec;
end

%Normalizing
Sum = sum(SRt);
SRt = SRt / Sum;

conn_struct.(speciesname).raw_metrics.self_recruit = SRt;

[~,Index]=sort(SRt,'descend'); %sort based on greatest value
Rank = 1:length(Index);
K2 = Rank;
K2(Index) = Rank;


conn_struct.(speciesname).rankings.self_recruit = K2;

%adding each patch ranking to the average matrix
avg_metrics.self_recruit.mean(:,s) = K2;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%centrality: left eigenvector, |(0,infinity)| (closer to 1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Option
    case 'Realized'
   % [V,D,W] = eig(conn_struct.(speciesname).conn_mat.*repmat(Biomass(:)',[length(Biomass),1]));
   [V,D,W] = eig(conn_struct.(speciesname).conn_mat.*repmat(Hab_vec(:)',[length(Hab_vec),1]));
    otherwise
[V,D,W] = eig(conn_struct.(speciesname).conn_mat);
end

diagonal = diag(D);
Dmax = max(diagonal);
Lmax = diagonal == Dmax;
L_eig = W(:,Lmax).';

%Normalizing
Sum = sum(L_eig);
L_eig = L_eig/ Sum;

conn_struct.(speciesname).raw_metrics.centrality = L_eig;

L = zeros(1, 135);
[~,Index]=sort(L_eig,'descend'); %sort based on greatest value
Rank = 1:length(Index);
L = Rank;
L(Index) = Rank;

conn_struct.(speciesname).rankings.centrality = L;

if strcmp(speciesname, 'BlackSurfperch')
    L = L.';
end

%adding each patch ranking to the average matrix
    avg_metrics.centrality.mean(:,s) = L;

%done with centrality

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%scaled centrality: left eigenvector * habitat, |(0,infinity)| (closer to 1)
% but multiplied by habitat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Multiplying by the habitat to account for habitat too
L_eig = L_eig.*Hab_vec;

%Normalizing
Sum = sum(L_eig);
L_eig = L_eig/ Sum;

conn_struct.(speciesname).raw_metrics.scaled_centrality = L_eig;

L2 = zeros(1, 135);
[~,Index]=sort(L_eig,'descend'); %sort based on greatest value
Rank = 1:length(Index);
L2 = Rank;
L2(Index) = Rank;

conn_struct.(speciesname).rankings.scaled_centrality = L2;

if strcmp(speciesname, 'BlackSurfperch')
    L2 = L2.';
end

%adding each patch ranking to the average matrix
    avg_metrics.scaled_centrality.mean(:,s) = L2;

%done with centrality

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%contribution: eigenvector product, |(0,infinity)| (closer to 1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

R_eig = V(:,Lmax).';

RL_eig = abs(L_eig).*abs(R_eig);

%Normalizing
Sum = sum(RL_eig);
RL_eig = RL_eig/ Sum;

conn_struct.(speciesname).raw_metrics.contribution = RL_eig;

L3 = zeros(1, 135);
[~,Index]=sort(L_eig,'descend'); %sort based on greatest value
Rank = 1:length(Index);
L3 = Rank;
L3(Index) = Rank;


conn_struct.(speciesname).rankings.contribution = L3;

if strcmp(speciesname, 'BlackSurfperch')
    L3 = L3.';
end

%adding each patch ranking to the average matrix
    avg_metrics.contribution.mean(:,s) = L3;

%done with contribution



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%import: row sums of conn_mat, (0,infinity) (closer to 1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%for j= 1:length(conn_struct.(speciesname).J)  %rows
%    row_sum = 0;
    
%    for i=1:length(conn_struct.(speciesname).J) %stops at each column
%        row_sum = row_sum + conn_struct.(speciesname).conn_mat(j,i);
%    end
    
%    Imprt(j) = row_sum;
%end

switch Option
    case 'Realized'
  %  Imprt = sum((conn_struct.(speciesname).conn_mat.*repmat(Biomass(:)',[length(Biomass),1]))');
    Imprt = sum((conn_struct.(speciesname).conn_mat.*repmat(Hab_vec(:)',[length(Hab_vec),1]))');
    otherwise
Imprt = sum(conn_struct.(speciesname).conn_mat');
end

%Multiplying by the habitat to account for habitat too
%Imprt = Imprt.*Hab_vec;

%Normalizing
Sum = sum(Imprt);
Imprt = Imprt / Sum;

conn_struct.(speciesname).raw_metrics.import = Imprt;

[~,Index]=sort(Imprt,'descend'); %sort based on greatest value
Rank = 1:length(Index);
M = Rank;
M(Index) = Rank;

conn_struct.(speciesname).rankings.import = M;

%adding each patch ranking to the average matrix
    avg_metrics.import.mean(:,s) = M;


%done with import
%keyboard 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%export: column sum of conn_mat, (0,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch Option
    case 'Realized'
    %Xprt = sum((conn_struct.(speciesname).conn_mat.*repmat(Biomass(:)',[length(Biomass),1])));
    Xprt = sum((conn_struct.(speciesname).conn_mat.*repmat(Hab_vec(:)',[length(Hab_vec),1])));
    otherwise
Xprt = sum(conn_struct.(speciesname).conn_mat);
end

%Multiplying by the habitat to account for habitat too
%keyboard
%Xprt = Xprt.*Hab_vec;


%Normalizing
Sum = sum(Xprt);

Xprt = Xprt / Sum;

conn_struct.(speciesname).raw_metrics.export = Xprt;

[~,Index]=sort(Xprt,'descend'); %sort based on greatest value
Rank = 1:length(Index);
N = Rank;
N(Index) = Rank;

conn_struct.(speciesname).rankings.export = N;

%adding each patch ranking to the average matrix
    avg_metrics.export.mean(:,s) = N;


%Done with export

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Deletion: 1 - ((avg biomass w/o patch j) / 
%(avg biomass of all patches))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Delete = [];

Delete = do_deletion(Region, speciesname, Delete);

%Multiplying by the habitat to account for habitat too
%Delete = Delete.*Hab_vec;
%keyboard
%Normalizing
Sum = sum(Delete);

Delete = Delete / Sum;

conn_struct.(speciesname).raw_metrics.deletion = Delete;

[~,Index]=sort(Delete,'descend'); %sort based on greatest value
Rank = 1:length(Index);
O = Rank;
O(Index) = Rank;


conn_struct.(speciesname).rankings.deletion = O;

%adding each patch ranking to the average matrix
    avg_metrics.deletion.mean(:,s) = O;


%end of deletion



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Rank matrix - one matrix with all the rankings as columns 
%columns are ordered as follows:
%1 - habitat
%2 - self retention
%3 – self recruitment
%4 - centrality
%5 - scaled centrality
%6 - contribuiton
%7 - import
%8 - export
%9 - deletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%conn_struct.(speciesname).rank_matrix 

conn_struct.(speciesname).rank_matrix = [J(:)'; K(:)'; K2(:)'; L(:)'; L2(:)'; L3(:)'; M(:)'; N(:)'; O(:)'].'; %metrics were rows, but transformed into columns

end %end loop over SN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Creating Res_vec's and adding it to the res_struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Res_vecs for the 5 metrics
Metric = fieldnames(avg_metrics); %gets metric names
for X = 1:length(Metric)
    %keyboard
    Metric_temp = Metric{X};
    % This vector is the average rank of each patch in the system
    avg_metrics.(Metric_temp).mean(:,end) = sum(avg_metrics.(Metric_temp).mean(:,1:end-1),2) / length(SN); %averages numbers
    
    %Getting patches of interest, sorting the numbers, ranking them, creating MPAs, and resvec
  %  switch Region
   %     case 'NCSR'
            % At one point we only considered locations in the study
            % region. Deprecated.
         %   No_buffers = avg_metrics.(Metric_temp).mean(4:16);
         %   [~,Rank]=sort(No_buffers);

    %        [~,Rank]=sort(avg_metrics.(Metric_temp).mean);
     %       MPAs = Rank(1:MPA_num);
            %MPAs = MPAs +3 ;
     %   case 'SCSR'
     %       [~,Rank]=sort(avg_metrics.(Metric_temp).mean);
      %      MPAs = Rank(1:MPA_num);
    %end
    
     % overall across multiple species
    [~,Rank]=sort(avg_metrics.(Metric_temp).mean(:,end),'ascend');
    MPAs = Rank(1:MPA_num);

    Res_vec = zeros(Pat_Num,1);
    Res_vec(MPAs)=1;
    avg_metrics.(Metric_temp).res_vec = Res_vec;    

    
    %saving the Res_vec to res_struct_2D.(species)
    SN = fieldnames(conn_struct); %species name
    for s = 1:length(SN)
        res_struct_2D.(SN{s}).pkg.(Metric_temp).resvec = Res_vec;

     % Also do the ranking on a species-specific basis
     Metric_sp_name = strcat(Metric_temp,SN{s});

    [~,Rank]=sort(avg_metrics.(Metric_temp).mean(:,s),'ascend');
     MPAs = Rank(1:MPA_num);
     Res_vec_sp = 0*Res_vec;
     Res_vec_sp(MPAs) = 1;

     res_struct_2D.(SN{s}).pkg.(Metric_sp_name).resvec = Res_vec_sp;

switch Metric_temp
    case 'import'
        switch SN{s}
            case 'BlackRockfish'
   % keyboard

    %%%% CHECK THE SORTING THIS SEEMS WRONG SOMEHOW
        end
end

    end
%keyboard
end

%Creating random MPAs and their resvec
Straight_vec = 1:Pat_Num;
Rand_num = 100;
for r = 1:Rand_num
Rand_names{r} = strcat('Rand',num2str(r));
end

for Y = 1:length(Rand_names) %end of all random variables
    MPAs = randsample(Straight_vec, MPA_num);
    Res_vec = zeros(Pat_Num,1);
    Res_vec(MPAs)=1;
    
    %saving the Res_vec to res_struct_2D.(species)
    SN = fieldnames(conn_struct); %species name
    for Q = 1:length(SN)
        res_struct_2D.(SN{Q}).pkg.(Rand_names{Y}).resvec = Res_vec;
    end
    
end

%how to save correctly?
switch Region
    case 'NCSR'
        save NCSR/avg_metrics_NCSR.mat avg_metrics;
        save NCSR/conn_mat_NC_2D.mat conn_struct;
        save NCSR/DPR_2D_spatial_vars.mat res_struct_2D;
        
    case 'SCSR'
        save SCSR/avg_metrics_SCSR.mat avg_metrics;
        save SCSR/conn_mat_SC_2D.mat conn_struct;
        save SCSR/DPR_2D_spatial_vars.mat res_struct_2D;
end
        

end 
