function [va2, vb2, wa2, wb2, info] = collision_billes(ra, rb, va, vb, wa, wb)
% Methode des conditions initiales
% a = bille 1, b = bille 2. Tous les vecteurs sont des colonnes 3x1.
% info.j = impulsion normale, info.Jt = impulsion tangentielle, info.glisse = true si le contact glisse (frottement cinetique).

m = 0.210;  R = 0.031;  I = 2/5*m*R^2;
mu_s = 0.15;  mu_c = 0.10;  eps_b = 0.9;

% Normale entrante a la bille a (de b vers a)
n = ra - rb;  n(3) = 0;  n = n / norm(n);
rap = -R*n;  rbp = R*n;

% Vitesses des points de contact et vitesse relative avant le choc
vap = va + cross(wa, rap);
vbp = vb + cross(wb, rbp);
vr  = vap - vbp;

c = cross(vr, n);
if norm(c) > 1e-12 % pour éviter div par 0
    u = c / norm(c);
    t = cross(n, u);
else
    t = zeros(3,1);
end

vrn = dot(n, vr);                   
vrt = dot(t, vr);

%Pas de choc
if vrn >= 0
    va2 = va; vb2 = vb; wa2 = wa; wb2 = wb;
    info = struct('j',0,'Jt',0,'glisse',false);
    return
end

% Impulsion normale
meq = m/2;
j = -meq*(1 + eps_b)*vrn;

% Impulsion tangentielle
G_ap = dot(t, (cross(cross(rap, t) / I, rap) ));
G_bp = dot(t, (cross(cross(rbp, t) / I, rbp) ));

alpha = 1 / ( 2/m + G_ap + G_bp );

if mu_s * (1 + eps_b) * abs(vrn) < abs(dot(t, vr))

    Jt = alpha * mu_c * (1 + eps_b) * vrn;   glisse = true;
else
    Jt = -alpha * abs(dot(t, vr));   glisse = false;
end

J = j*n + Jt*t;
J(3) = 0;
va2 = va + J/m;
vb2 = vb - J/m;
wa2 = wa + cross(rap,  J)/I;
wb2 = wb + cross(rbp, -J)/I;
info = struct('j',j,'Jt',Jt,'glisse',glisse);
end
