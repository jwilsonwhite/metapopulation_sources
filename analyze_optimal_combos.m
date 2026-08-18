function analyze_optimal_combos(Region,Option,Option2,F)


% input F gives the level of fishing to use in displaying results
% 1 = 'scorched earth', 2 = 'sustainable'

% Option is the type of connectivity matrix used (Equal, Actual, Realized)

% Option 2 is whether species were run on separately optimized reserve
% networks ('Together','Indiv')

%load('source_setup.mat')
%load(DPR_setup_opt_file)
%load(optimal_results_savename)
%load('avg_metrics_NCSR.mat')

savename = strcat('DPR2D_',Region,'_',Option,'_opt_23Mar2026_all.mat');

load(savename,'DPR_2D_struct');


Species_Names = fieldnames(DPR_2D_struct);
switch Region
    case 'SCSR' % exclude black surfperch from analysis
        Species_Names = Species_Names(~strcmp(Species_Names,'BlackSurfperch'));
end

Pkg_Names = fieldnames(DPR_2D_struct.(Species_Names{1}).pkg);


Mean_biomass = nan(length(Species_Names),length(Pkg_Names)-8); % (have to subtract 8 bc have two versions of each one
Persist = Mean_biomass;
%Mean_yield = Mean_biomass;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Creating data for Biomass and Yield
%vs the metrics against the random 
%plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over Sp
for s = 1:length(Species_Names)

Pkg_Names = fieldnames(DPR_2D_struct.(Species_Names{s}).pkg);

% Select the correct packages, given Option 2
IsSp = false(length(Pkg_Names),1);
IsRnd = IsSp;
for p = 1:length(Pkg_Names)
    IsSp(p) = any(strfind(Pkg_Names{p},Species_Names{s})); % find the packages that have the species name in it
    IsRnd(p) = any(strfind(Pkg_Names{p},'Rand')); % find the random ones
end

switch Option2
    case 'Together'
Pkg_Names = Pkg_Names(~IsSp | IsRnd);
    case 'Indiv'
Pkg_Names = Pkg_Names(IsSp | IsRnd);
end

    for p = 1:length(Pkg_Names)
        
        stmp = DPR_2D_struct.(Species_Names{s}).pkg.(Pkg_Names{p}).slope1;
        
        % this assumes FLEPs = [0 0.4 1];
        % Option to only tally biomass in reserves?
        ResOnly = false;
        if ResOnly
            Res = stmp.reserves;
        else
            Res = stmp.reserves*0 + 1;
        end
        Res = logical(Res);
        % Need to make sure this is region 1 only (NCSR only)
        Mean_biomass(s,p,1) = sum(stmp.biomass(Res,1))./sum(stmp.biomass(Res,3));
        Mean_biomass(s,p,2)= sum(stmp.biomass(Res,2))./sum(stmp.biomass(Res,3));
        
        Mean_yield(s,p,1) = sum(stmp.yield(:,1));
        Mean_yield(s,p,2)= sum(stmp.yield(:,2));
        
        Size(s,p) = sum(stmp.reserves); % total reserve area
        
    end
end

%Mean_biomass = Mean_biomass./repmat(Size,[1, 1, 2]);
OKpkg = [1:6,8:9]; % don't use 'scaled centrality'; it's redundant
Rndpkg = 10:length(Pkg_Names); % the random ones

MB = Mean_biomass(:,OKpkg,:); %see how many packages we are looking at
RB = Mean_biomass(:,Rndpkg,:); % random simulation %first or third is the higher fishing rate (FLEP)

MY = Mean_yield(:,OKpkg,:);
RY = Mean_yield(:,Rndpkg,:); % random simulation

% scale by random reserve simulations 
for f = 1:2
MB(:,:,f) = MB(:,:,f)./repmat(mean(RB(:,:,f),2),[1,size(MB,2)]);
MY(:,:,f) = MY(:,:,f)./repmat(mean(RY(:,:,f),2),[1,size(MY,2)]);
end

for f = 1:2
RB(:,:,f) = RB(:,:,f)./repmat(mean(RB(:,:,f),2),[1,size(RB,2)]);
RY(:,:,f) = RY(:,:,f)./repmat(mean(RY(:,:,f),2),[1,size(RY,2)]);
end
%Labels = {'Deletion','Centrality','Centrality2','Loo','Export','Import','Self P','Self R','Biomass','Area'};
%Labels = {'Habitat', 'Self R', 'Centrality','Sc Centrality','Contrib' 'Import', 'Export','Deletion','Random'};
Labels = {'Habitat', 'Self R','Self Rct','Export','Import','Centrality','Contrib', 'Deletion','Random'};


Order = 1:(length(Labels)-1);%

switch Region
    case 'NCSR'

%Wthey are the colors for the different specie
Col = [0.0 0.0 0.0;... % black rockfish
       0.2 0.2 0.9;... % cabezon
       0.5 0.5 0.5;... % brown rockfish
       0.8 0.2 0.2];   % red abalone

    case 'SCSR'
%[0.1 0.1 0.9;... % black surfperch
Col = [0.0 0.0 0.0;... % opaleye
       0.2 0.2 0.9;... % kelpbass
       0.5 0.5 0.5;... % kelp rockfish
       0.8 0.2 0.2];... % sheephead
      % 0.9 0.1 0.1;... % red sea urchin
      % 0.5 0.5 0.5];   % halibut
       
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1: scatterplot
%%%%%%%%%%%%%%%%%%%%%%%%%%
DoPlot1 = true;


if DoPlot1 == false
figure(1)
clf
set(gcf,'units','cent','position',[10,5,9,11])

subplot(2,1,1)
hold on

for s = 1:length(Species_Names)

% Calculate quantiles of random ones
Qs = quantile(RB(s,:,F),[0.1,0.9]);

% Values that are better than the upper quantile:
MBtmp = MB(s,:,F);
MBbest = MBtmp >= Qs(2);


 %   plot both fishing rates with offset
 if any(~MBbest)
    ph(1) = plot(Order(~MBbest),MBtmp(~MBbest),'ko');
    set(ph(1),'markeredgecolor',Col(s,:),'markerfacecolor','none')
 end

 if any(MBbest)
    ph(1) = plot(Order(MBbest),MBtmp(MBbest),'ko');
    set(ph(1),'markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:))
 end
  %  ph(2) = plot(Order+0.1,MB(s,:,2),'kd');
  %  set(ph(2),'markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:))
%keyboard

Xrnd = size(RB,2);


  %  ph(3) = plot(repmat(Order(end)+1,[10,1])+(rand(10,1)-0.5)*0.3,RB(s,:,1),'k^');
    ph(3) = plot(repmat(Order(end)+1,[Xrnd,1])+(s*0.3)-0.6+(rand(Xrnd,1)-0.5)*0.3,RB(s,:,F),'kd');
    set(ph(3),'markeredgecolor',Col(s,:),'markerfacecolor','none')


%plot(Order(end)+1+(s*0.3)-0.6,Qs(1),'kd','markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:));
%plot(Order(end)+1+(s*0.3)-0.6,Qs(2),'kd','markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:));


  %  plot(repmat(6,[size(RB,2),1]),RB(s,:),'ko')
end
plot([0 length(Order)+1],[1 1],'k--')%dashed line at 1 on the y-axis
xlim([0.5 length(Order)+1.9])
set(gca,'xtick',1:(length(Order)),'xticklabel',Labels(Order),'fontsize',8) %gives names to x-axis steps
ylabel(gca,'Mean Biomass','fontsize',14)
%legend(p(1),Species_Names)

subplot(2,1,2)
hold on

for s = 1:length(Species_Names)
    ph(1) = plot(Order-0.1,MY(s,:,F),'ko');
    set(ph(1),'markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:))
 %   ph(2) = plot(Order+0.1,MY(s,:,2),'kd');
  %  set(ph(2),'markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:))

  %ph(3) = plot(repmat(Order(end)+1,[10,1])+(rand-0.5)*0.3,RY(s,:,1),'k^');
  ph(3) = plot(repmat(Order(end)+1,[Xrnd,1])+(s*0.3)-0.6,RY(s,:,F),'kd');
        set(ph(3),'markeredgecolor',Col(s,:),'markerfacecolor','none')

        % also plot quantiles
Qs = quantile(RY(s,:,F),[0.1,0.9]);
plot(Order(end)+1+(s*0.3)-0.6,Qs(1),'kd','markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:));
plot(Order(end)+1+(s*0.3)-0.6,Qs(2),'kd','markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:));

end
plot([0 length(Order)+1],[1 1],'k--') %dashed line at 1 on the y-axis
xlim([0.5 length(Order)+1.9])
set(gca,'xtick',1:length(Order),'xticklabel',Labels(Order),'fontsize',8)
ylabel(gca,'Mean Yield','fontsize',14)
%legend(Species_Names)
switch Region
    case 'NCSR'
        if F == 1
        ylim([0.7, 1.2]);
        else
        ylim([0.9, 1.1]);
        end
    case 'SCSR'
       if F == 1 
       ylim([0.6 1.3])
       else
        ylim([0.9 1.05])
       end
end

if ResOnly
    fname = strcat('Figures/',Region,'_results_ResOnly_',Option,'_',Option2,'_FLEP',num2str(F-1),'.eps');
else
fname = strcat('Figures/',Region,'_results_',Option,'_',Option2,'_FLEP',num2str(F-1),'.eps');
end
print(fname,'-depsc2')

else
    T=1;
end % End doPlot1

%keyboard

%%%%%%%%%%%
% Plot packages
switch Option2
    case 'Together' 
        S_loop = 1;
    case 'Indiv'
        S_loop = length(Species_Names);
end


for s = 1:S_loop
figure(2)
clf
set(gcf,'units','cent','position',[10,6,9,5])
hold on



switch Option2 % get the appropriate list of packages, depending on the option
    case 'Together'
        Pkg_Names_short = Pkg_Names(OKpkg);
    case 'Indiv'
        switch Region
            case 'NCSR'
               % Sp_tmp = 'Cabezon';
               Sp_tmp = Species_Names{s};
            case 'SCSR'
               % Sp_tmp = 'KelpBass';
               Sp_tmp = Species_Names{s};
        end % end Region switch
    Pkg_Names_tmp = fieldnames(DPR_2D_struct.(Sp_tmp).pkg);
    IsSp = false(length(Pkg_Names_tmp),1);
    for p = 1:length(Pkg_Names_tmp)
    IsSp(p) = any(strfind(Pkg_Names_tmp{p},Sp_tmp));
    end

    Pkg_Names_short = Pkg_Names_tmp(IsSp);
    Pkg_Names_short = Pkg_Names_short(OKpkg);
end % end Option2 switch


for p = 1:8
%keyboard

switch Option2
    case 'Together'
    Ptmp = DPR_2D_struct.(Species_Names{1}).pkg.(Pkg_Names_short{p}).slope1;
    case 'Indiv'
    Ptmp = DPR_2D_struct.(Sp_tmp).pkg.(Pkg_Names_short{p}).slope1;
end


    X = 1:length(Ptmp.reserves);
    OKr = Ptmp.reserves == 1; % the reserves

    Res = zeros(1,length(X));
Bump = 9:-1:1;
plot(X(OKr),Res(OKr)+Bump(p),'ro','markerfacecolor',[0.8, 0.1, 0.1])
plot(X(~OKr),Res(~OKr)+Bump(p),'bo')

end % end loop over P

switch Region
    case 'SCSR'
Ticks = [63,97];
Lims = [1,135];
    case 'NCSR'
        Ticks = [5,11,16];
    Lims = [1,20];
end

set(gca,'Ytick',1:9,'Xtick',Ticks,'Xgrid','on')
set(gca,'Yticklabel',fliplr(Labels),'tickdir','out','ticklength',[0.02 0.02])
set(gca,'xlim',Lims)

switch Option2
    case 'Together'
        fname = strcat('Figures/',Region,'_reserve_map_',Option,'_',Option2,'_FLEP',num2str(F-1),'.eps');
    case 'Indiv'
        fname = strcat('Figures/',Region,'_',Sp_tmp,'_reserve_map_',Option,'_',Option2,'_FLEP',num2str(F-1),'.eps');
end
print(fname,'-depsc2')
end % end S_loop

%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot biomass by package
figure(3)
clf
set(gcf,'units','cent','position',[10,7,9,7])
clf
hold on

for p = 1:8
    Pkg_Names_short{p}
switch Option2
    case 'Together'
    Ptmp = DPR_2D_struct.(Species_Names{1}).pkg.(Pkg_Names_short{p}).slope1;
    case 'Indiv'
    Ptmp = DPR_2D_struct.(Sp_tmp).pkg.(Pkg_Names_short{p}).slope1;
end % end Option2 switch


    X = 1:length(Ptmp.reserves);
    OKr(:,p) = Ptmp.reserves(:) == 1; % the reserves

    switch Option2 % average across species or single species
        case 'Together'
    for s = 1:4
            Ptmp2 = DPR_2D_struct.(Species_Names{s}).pkg.(Pkg_Names{p}).slope1;
            Btmp = Ptmp2.biomass(:,1);
         %   Btmp = Btmp/max(Btmp);
            B2(s,:,p) = Btmp(:);
 
    end % end loop over species

    Bmean(:,p) = mean(B2(:,:,p),1);
        case 'Indiv'
            Bmean(:,p) = Ptmp.biomass(:,1);
         %   Bmean = Btmp/max(Btmp);
    end % end Option2 switch

end % end loop over P

Bmean = Bmean./(max(Bmean(:)));% scale relative to absolute highest value in any plan


for p = 1:8

   
    Bmean2 = Bmean(:,p)';
    OKr2 = OKr(:,p)';

Res = zeros(1,length(X));
Bump = 9:-1:1;
plot(X,Bmean2+Bump(p),'k-')
plot(X(OKr2),Bmean2(OKr2)+Bump(p),'ro','markerfacecolor',[0.8, 0.1, 0.1])
plot(X(~OKr2),Bmean2(~OKr2)+Bump(p),'bo','markerfacecolor','none')
set(gca,'Ygrid','on','Ytick',1:9)
set(gca,'Yticklabel',fliplr(Labels))

end % end loop over P

switch Region
    case 'SCSR'
Ticks = [63,97];
Lims = [1,135];
    case 'NCSR'
        Ticks = [5,11,16];
    Lims = [1,20];
end

set(gca,'Ytick',1:9,'Xtick',Ticks,'Xgrid','on')
set(gca,'Yticklabel',fliplr(Labels),'tickdir','out','ticklength',[0.02 0.02])
set(gca,'xlim',Lims)

fname = strcat('Figures/',Region,'_spatial_biomass_',Option,'_',Option2,'_FLEP',num2str(F-1),'.eps');
print(fname,'-depsc2')

%%% Save this figure
%end % end switch over Option2


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Creating data for Biomass vs Yield
%
%Trying to average across species by
%putting all the species data into one
%struct but seems incredibly complicated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
SN = fieldnames(DPR_2D_struct); %get species name out of file produced by do_DPR_2D
avg_over_species = struct;
Metrics = fieldnames(DPR_2D_struct.(SN{1}).pkg);
Info = fieldnames(DPR_2D_struct.(SN{1}).pkg.(Metrics{1})) ;
for P = 1:length(SN)
    for Q = 1:length(Metrics) 
        for R = 1:length(Info)
         avg_over_species.Metrics{Q}.Info{R} = avg_over_species.Metrics{Q}.Info{R} + DPR_2D_struct.(SN{P}).pkg.(Metrics{Q}).(Info{R});
        end
    end
end
%}
%{
plot(MY(s,:),MB(s,:),'ko')
for s = 1:length(Species_Names)
 %   keyboard
    ph = plot(MY(s,:),MB(s,:),'ko');
    set(ph,'markeredgecolor',Col(s,:),'markerfacecolor',Col(s,:))
end
plot([0 length(Order)+1],[1 1],'k--')%dashed line at 1 on the y-axis
xlim([0.5 5.5])
set(gca,'xtick',1:length(Order),'xticklabel',Labels(Order),'fontsize',8) %gives names to x-axis steps
ylabel(gca,'Mean Biomass','fontsize',14)
legend(Species_Names);
%}
%keyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Older barchart figure code:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DoPlotOld = false;

if DoPlotOld == true
YL = [0.8 1.4;...
      0.12 0.18;...
      0.3 0.7;...
      0.6 1.0;...
      0.2 0.5;...
      0.8 1.6];

figure(2);
clf;

for s = 1:length(Species_Names)
    subplot(5,1,s)
    hold on
    
    MBt = MB(s,Order);
    
    for i = Order
        bh(i) = bar(i,MBt(i));
    end
    
    [~,Col_order] = sort(MBt,'descend');
    %if s == 5
      %  keyboard
   % end
    
    for j = 1:length(bh)-1
       % keyboard
        set(bh(Col_order(j)),'facecolor',Col(j,:));
    end
    
    set(gca,'xtick',1:length(Labels),'tickdir','out','ticklength',[0.015 0.015])
    set(gca,'ylim',YL(s,:))
    if s == 4
        set(gca,'xticklabel',Labels(Order));
    else
        set(gca,'xticklabel',[])
    end
       % T=4;
end
end