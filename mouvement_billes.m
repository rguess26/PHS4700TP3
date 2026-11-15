function [q1,ev] = mouvement_billes(q0,t0,dt)
% MOUVEMENT_BILLES Mouvement libre d'une bille du TP3 entre deux collisions.
% Partie 1 : glissement, roulement et transition. Aucun choc n'est traite ici.
%
% [q1,ev] = mouvement_billes(q0,t0,dt)
% q0 et q1 : colonnes [vx;vy;vz;x;y;z;wx;wy;wz], unites SI.
% ev.tr : delais relatifs a t0 des transitions glissement -> roulement.
% ev.t_arret : delai relatif d'immobilisation dans le pas, sinon Inf.
% Une bille deja immobile retourne ev.t_arret=0.
% Les appels sont independants : aucun etat global ni persistant.
%
% Sources : enonce TP3 ; chapitre 4, diapositives 70, 72 et 74-80.
% Force de roulement equivalente F_r=-mu_r*m*g*v/|v|, comme diapositive 72.
% En roulement, omega_xy est imposee par la contrainte sans glissement.
% Les solutions sont analytiques par regime ; le pas peut contenir une
% transition et un arret sans depassement ni inversion numerique de vitesse.

    m=0.210; R=0.031; g=9.8; mu_c=0.3; mu_r=0.03;
    I=(2/5)*m*R^2; tol=1e-12;
    if ~isnumeric(q0)||~isreal(q0)||~isequal(size(q0),[9 1])||any(~isfinite(q0))
        error('TP3:MouvementEtat','q0 doit etre un vecteur colonne 9x1 reel et fini.');
    end
    if ~isnumeric(t0)||~isreal(t0)||~isscalar(t0)||~isfinite(t0)|| ...
       ~isnumeric(dt)||~isreal(dt)||~isscalar(dt)||~isfinite(dt)||dt<0
        error('TP3:MouvementTemps','t0 doit etre fini et dt doit etre fini et positif ou nul.');
    end
    if abs(q0(3))>1e-9 || abs(q0(6)-R)>1e-9
        error('TP3:MouvementPlan','Le modele impose vz=0 et z=0.031 m.');
    end
    q1=double(q0); q1(3)=0; q1(6)=R;
    u0=vitesse_contact(q1,R);
    initial=regime(q1,u0,tol);
    ev=struct('tr',[],'t_arret',Inf,'regime_initial',initial, ...
        'regime_final',initial,'u_initial',u0,'u_final',u0);
    if strcmp(initial,'immobile')
        q1(1:2)=0;q1(7:8)=0;ev.t_arret=0;ev.u_final=zeros(3,1);
        return;
    end
    if dt==0, return; end

    ecoule=0;
    if norm(u0)>tol
        % F_c s'oppose au glissement du point de contact, pas toujours a v_C.
        direction=u0/norm(u0);
        F=-mu_c*m*g*direction;
        a=F/m;
        alpha=cross([0;0;-R],F)/I;
        % du/dt=-(7/2)*mu_c*g*u/|u| : la direction de u reste constante.
        t_transition=2*norm(u0)/(7*mu_c*g);
        h=min(dt,t_transition);
        q1(4:6)=q1(4:6)+q1(1:3)*h+0.5*a*h^2;
        q1(1:3)=q1(1:3)+a*h;
        q1(7:9)=q1(7:9)+alpha*h;
        ecoule=h;
        if dt<t_transition
            ev.regime_final='glissement';
            ev.u_final=vitesse_contact(q1,R);
            return;
        end
        ev.tr=t_transition;
        % Supprimer uniquement le residu d'arrondi a la transition exacte.
        q1(7:8)=[-q1(2);q1(1)]/R;
    else
        % Etat deja en roulement : aucune nouvelle transition n'est declaree.
        q1(7:8)=[-q1(2);q1(1)]/R;
    end

    vitesse=norm(q1(1:2));
    if vitesse<=tol
        q1(1:2)=0;q1(7:8)=0;
        ev.t_arret=ecoule;ev.regime_final='immobile';
        ev.u_final=zeros(3,1);
        return;
    end

    % Roulement sans glissement : la force equivalente impose dv/dt.
    % La contrainte v=-omega x (0,0,-R) fixe simultanement omega_xy.
    restant=max(0,dt-ecoule);
    t_stop=vitesse/(mu_r*g);
    h=min(restant,t_stop);
    direction=q1(1:2)/vitesse;
    q1(4:5)=q1(4:5)+direction*(vitesse*h-0.5*mu_r*g*h^2);
    q1(1:2)=direction*max(0,vitesse-mu_r*g*h);
    q1(7:8)=[-q1(2);q1(1)]/R;
    if restant>=t_stop
        q1(1:2)=0;q1(7:8)=0;
        ev.t_arret=ecoule+t_stop;ev.regime_final='immobile';
    else
        ev.regime_final='roulement';
    end
    % Le modele de contact ponctuel du TP ne produit pas de couple sur z.
    % La composante wz est donc conservee entre les chocs.
    ev.u_final=vitesse_contact(q1,R);
end

function u=vitesse_contact(q,R)
    u=q(1:3)+cross(q(7:9),[0;0;-R]);
    u(3)=0;
end

function nom=regime(q,u,tol)
    if norm(u)>tol
        nom='glissement';
    elseif norm(q(1:2))>tol
        nom='roulement';
    else
        nom='immobile';
    end
end
