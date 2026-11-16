function TesterTir1()
    ici=fileparts(mfilename('fullpath'));addpath(ici);
    xyb=[.5;.3];xyr=[1.5;1.1];xyj=[1.45;1.31];Vb0=[3.4;1.5];
    [coll,tr,t,xb,yb,xr,yr,xj,yj]=Devoir3(xyb,xyr,xyj,Vb0);
    dossier=fullfile(ici,'resultats_tir1');
    if ~exist(dossier,'dir'),mkdir(dossier);end
    save(fullfile(dossier,'tir1.mat'),'coll','tr','t','xb','yb','xr','yr','xj','yj');
    fid=fopen(fullfile(dossier,'tir1_resultats.txt'),'w');
    fprintf(fid,'Tir 1 - simulation complete avec les modules de l''equipe\n');
    fprintf(fid,'Nombre de billes distinctes touchees : %d\n',coll);
    fprintf(fid,'Instant d''arret de la simulation : %.10f s\n',t(end));
    fprintf(fid,'Transitions de la blanche (s) :');fprintf(fid,' %.10f',tr);fprintf(fid,'\n');
    fprintf(fid,'Blanche finale (m) : %.10f %.10f\n',xb(end),yb(end));
    fprintf(fid,'Rouge finale (m) : %.10f %.10f\n',xr(end),yr(end));
    fprintf(fid,'Jaune finale (m) : %.10f %.10f\n',xj(end),yj(end));
    fprintf(fid,'\nLe graphique doit etre accompagne d''une interpretation dans le rapport.\n');
    fclose(fid);
    f=figure('color','w');hold on;
    plot([0 2.8 2.8 0 0],[0 0 1.53 1.53 0],'k-','HandleVisibility','off');
    a=plot(xb,yb,'k-','LineWidth',1.5);
    b=plot(xr,yr,'r--','LineWidth',1.5);
    c=plot(xj,yj,':','Color',[.65 .45 0],'LineWidth',1.8);
    axis equal;xlim([-.05 2.85]);ylim([-.05 1.58]);grid on;
    xlabel('x (m)');ylabel('y (m)');
    legend([a b c],{'Blanche','Rouge','Jaune'},'Location','northoutside','Orientation','horizontal');
    print(f,fullfile(dossier,'tir1_trajectoires.png'),'-dpng','-r200');
    fprintf('Tir 1 : coll=%d, arret a %.8f s. Fichiers dans %s\n',coll,t(end),dossier);
end
