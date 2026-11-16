function [va2, wa2, info] = collision_mur(ra, va, wa)
    % Methode des conditions initiales
    % info.j = impulsion normale, info.Jt = impulsion tangentielle, info.glisse = true si le contact glisse (frottement cinetique).
    
    m = 0.210;  R = 0.031;  I = 2/5*m*R^2;
    mu_s = 0.4;  mu_c = 0.3;  eps_m = 0.8;
    
    gauche = ra; gauche(1) = gauche(1) - R;
    droite = ra; droite(1) = droite(1) + R;
    haut = ra; haut(2) = haut(2) + R;
    bas = ra; bas(2) = bas(2) - R;
    
    rb = zeros(3,1);
    if gauche(1) <= 0
        rb = gauche;
    elseif droite(1) >= 2.8
        rb = droite;
    elseif haut(2) >= 1.53
        rb = haut;
    elseif bas(2) <= 0
        rb = bas;
    else
        va2 = va; wa2 = wa;
        info = struct('j',0,'Jt',0,'glisse',false);
        return
    end

    % Normale
    n = ra - rb;  n(3) = 0;  n = n / norm(n);
    rap = -R*n;
    
    % Vitesses des points de contact et vitesse relative avant le choc
    vap = va + cross(wa, rap);
    vbp = zeros(3,1);
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
        va2 = va; wa2 = wa;
        info = struct('j',0,'Jt',0,'glisse',false);
        return
    end
    
    % Impulsion normale
    j = -m*(1 + eps_m)*vrn;
    
    % Impulsion tangentielle
    G_ap = dot(t, (cross(cross(rap, t), rap)/I ));

    alpha = 1 / ( 1/m + G_ap );

    if mu_s * (1 + eps_m) * abs(vrn) < abs(dot(t, vr))

        Jt = alpha * mu_c * (1 + eps_m) * vrn;   glisse = true;
    else
        Jt = -alpha * abs(dot(t, vr));   glisse = false;
    end
    
    J = j*n + Jt*t;
    
    va2 = va + J/m; va2(3) = 0;
    wa2 = wa + cross(rap,  J)/I;
    info = struct('j',j,'Jt',Jt,'glisse',glisse);
end