function [coll,tr,t,xb,yb,xr,yr,xj,yj] = Devoir3(xyb,xyr,xyj,Vb0)
% DEVOIR3 Interface imposee par le TP3. Integration : Rayane.
% Reprend l'etat de Guillaume : q = [v(3); r(3); omega(3)].
% La physique du mouvement et des bandes reste dans les modules de l'equipe.
    [coll,tr,t,positions] = simuler_tp3(xyb,xyr,xyj,Vb0);
    xb = positions(1,:); yb = positions(2,:);
    xr = positions(3,:); yr = positions(4,:);
    xj = positions(5,:); yj = positions(6,:);
end
