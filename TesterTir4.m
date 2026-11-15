function TesterTir4()
% TESTERTIR4 Production des resultats du tir attribue a Rayane.
% Necessite les vrais modules de l'equipe. Ne modifie pas RouleDevoir3.m.
    ici=fileparts(mfilename('fullpath')); addpath(ici);
    xyb=[.2;.2]; xyr=[1.5;1.1]; xyj=[1.45;1.31]; Vb0=[4;2.9];
    [coll,tr,t,P,journal]=simuler_tp3(xyb,xyr,xyj,Vb0);
    xb=P(1,:);yb=P(2,:);xr=P(3,:);yr=P(4,:);xj=P(5,:);yj=P(6,:);
    dossier=fullfile(ici,'resultats_rayane');
    if ~exist(dossier,'dir'),mkdir(dossier);end
    save(fullfile(dossier,'tir4.mat'),'coll','tr','t','xb','yb','xr','yr', ...
         'xj','yj','journal','xyb','xyr','xyj','Vb0');
    fid=fopen(fullfile(dossier,'tir4_resultats.txt'),'w');
    if fid<0,error('TP3:Export','Impossible de creer le fichier de resultats.');end
    protection=onCleanup(@() fclose(fid));
    fprintf(fid,'Tir 4 - resultats calcules avec les modules presents sur le chemin Octave\n');
    fprintf(fid,'Blanche initiale (m) : %.8f %.8f\n',xyb);
    fprintf(fid,'Vitesse initiale (m/s) : %.8f %.8f\n',Vb0);
    fprintf(fid,'Billes distinctes touchees : %d\n',coll);
    fprintf(fid,'Temps d''arret (s) : %.10f\n',t(end));
    fprintf(fid,'Nombre de points : %d\n',numel(t));
    fprintf(fid,'Blanche finale (m) : %.10f %.10f\n',xb(end),yb(end));
    fprintf(fid,'Rouge finale (m) : %.10f %.10f\n',xr(end),yr(end));
    fprintf(fid,'Jaune finale (m) : %.10f %.10f\n',xj(end),yj(end));
    fprintf(fid,'Transitions de la blanche (s) :');fprintf(fid,' %.10f',tr);fprintf(fid,'\n\n');
    fprintf(fid,'Journal des evenements (billes 1=blanche, 2=rouge, 3=jaune)\n');
    for k=1:numel(journal)
        fprintf(fid,'%.10f  %s  ',journal(k).temps,journal(k).type);
        fprintf(fid,'%d ',journal(k).billes);fprintf(fid,'\n');
    end
    fprintf(fid,'\nParagraphe de resultats a verifier et a integrer au rapport\n');
    fprintf(fid,['Pour le quatrieme tir, la bille blanche part de (0,2 ; 0,2) m avec une vitesse ' ...
        'initiale de (4,0 ; 2,9) m/s. La simulation se termine a %.6f s, lorsque la blanche ' ...
        's''arrete. Elle a touche %d bille(s) distincte(s). '],t(end),coll);
    if coll==2
        fprintf(fid,'La blanche ayant touche la rouge et la jaune, le joueur marque un point.\n');
    else
        fprintf(fid,'La blanche n''ayant pas touche les deux autres billes, le joueur ne marque pas de point.\n');
    end
    fprintf(fid,['La position finale de la blanche est (%.6f ; %.6f) m. ' ...
        'Les trajectoires des trois billes sont presentees a la figure correspondante. ' ...
        'Le journal permet de commenter l''ordre des collisions et les transitions.\n'],xb(end),yb(end));
    clear protection;
    f=figure('color','w');hold on;
    plot([0 2.8 2.8 0 0],[0 0 1.53 1.53 0],'k-','HandleVisibility','off');
    a=plot(xb,yb,'k-','LineWidth',1.5);
    b=plot(xr,yr,'r--','LineWidth',1.5);
    c=plot(xj,yj,'b:','LineWidth',1.8);
    plot(xyb(1),xyb(2),'ko','HandleVisibility','off');
    plot(xyr(1),xyr(2),'ro','HandleVisibility','off');
    plot(xyj(1),xyj(2),'bo','HandleVisibility','off');
    axis equal; xlim([-.05 2.85]);ylim([-.05 1.58]);grid on;
    xlabel('x (m)');ylabel('y (m)');
    legend([a b c],{'Blanche','Rouge','Jaune'},'Location','northoutside','Orientation','horizontal');
    print(f,fullfile(dossier,'tir4_trajectoires.png'),'-dpng','-r200');
    fprintf('Tir 4 termine : coll=%d, t=%.8f s. Resultats dans %s\n',coll,t(end),dossier);
end
