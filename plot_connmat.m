function plot_connmat(Metric,Option,Option2)

% Make graphics of the connectivity matrices in the south and north study
% regions, including option to plot selected MPA options

c_names = {'NCSR/conn_mat_NC_2D.mat','SCSR/conn_mat_SC_2D.mat'};

figure(1) % for connectivity
clf
set(gcf,'units','centimeters',"Position",[10,10,21,25])

figure(2) % for habitat
clf
set(gcf,'units','centimeters',"Position",[10,20,21,4.5])

Splots = reshape(1:8,[2,4])';

for r = 1:2

    load(c_names{r},'conn_struct');

% Species names
Sp = fieldnames(conn_struct);
if r == 2
    Sp = Sp(2:end); % don't use Black Surfperch
end

for s = 1:length(Sp)

C = conn_struct.(Sp{s}).conn_mat;

Hab = conn_struct.(Sp{s}).habvec;

C2 = C;
C2(:,end+1) = NaN;
C2(end+1,:) = NaN;


    C2(C2<1e-4)=1e-4;


figure(1)
subplot(5,2,Splots(s,r))
hold on

pcolor((C2)); shading flat
axis square
cb=colorbar;
%cb.Limits = [1e-4,0.25];

set(gca,'xcolor','k','ycolor','k','tickdir','out','ticklength',[0.015 0.015])

if r == 1
    % 59 = Pt. St. George
    % 54 = Cape Mendocino
    % 48 = Pt Arena
    Ticks = [5,11,16];
    Lims = [1,20];
else
    Ticks = [63,97];
    Lims = [1,135];
end % end if r

set(gca,'xtick',Ticks,'ytick',Ticks,'xgrid','on','YGrid','on')
set(gca,'xlim',Lims,'ylim',Lims)

for i = 1:length(Ticks)
    plot(Lims,[Ticks(i),Ticks(i)],'w--')
    plot([Ticks(i),Ticks(i)],Lims,'w--')
end


% Highlight selected sites, if desired
if exist('Metric','var')
    if r == 1
        fname = strcat('DPR2D_NCSR_',Option,'_opt_24Jan2025_all.mat');

        load(fname,'DPR_2D_struct');
        MS = 10;
    else
        fname = strcat('DPR2D_SCSR_',Option,'_opt_24Jan2025_all.mat');

        load(fname,'DPR_2D_struct');
        MS = 6;
    end
Species_Names = fieldnames(DPR_2D_struct);
Pkg_Names = fieldnames(DPR_2D_struct.(Sp{1}).pkg);


switch Option2 % separate Together vs Indiv
    case 'Together'
Pkg = DPR_2D_struct.(Sp{s}).pkg.(Metric).slope1.reserves; % indices of the reserves
Res = find(Pkg);
    case 'Indiv'
MetricTmp = strcat(Metric,Sp{s});
Pkg = DPR_2D_struct.(Sp{s}).pkg.(MetricTmp).slope1.reserves; % indices of the reserves
Res = find(Pkg);
end

Res

for i = 1:length(Res)
 %   plot(Lims,[Res(i),Res(i)],'r--','LineWidth',2)
  %  plot([Res(i),Res(i)],Lims,'r--')

plot(Res(i)+0.5,Res(i)+0.5,'rs','MarkerSize',MS,'LineWidth',1)

end


% Now plot habvec
figure(2)
subplot(1,2,r)
hold on

plot(Hab,'k-')
set(gca,'xtick',Ticks,'xgrid','on')
%set(gca,'xlim',Lims)

ymax = get(gca,'ylim');

for i = 1:length(Res)
 %   plot(Lims,[Res(i),Res(i)],'r--','LineWidth',2)
  %  plot([Res(i),Res(i)],Lims,'r--')

%plot([Res(i)-0.5,Res(i)-0.5],[0,ymax(2)],'r-','LineWidth',1)
%plot([Res(i)+0.5,Res(i)+0.5],[0,ymax(2)],'r-','LineWidth',1)

patch([Res(i)-0.5,Res(i)-0.5,Res(i)+0.5,Res(i)+0.5,],...
       [0 ymax(2) ymax(2) 0],'r','facealpha',0.1,'edgecolor','k')

end






end % end loop over metric


end % end loop over species

end % end loop over regions


print -depsc2 -vector Figures/Fig2_connmats.esp