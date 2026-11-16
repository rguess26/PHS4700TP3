function [q1,ev] = mouvement_billes(q0,t0,dt)

    R=0.031; g=9.8; mu_c=0.3; mu_r=0.03;
    tol=1e-12;
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
        direction=u0/norm(u0);
        t_transition=2*norm(u0)/(7*mu_c*g);
        h=min(dt,t_transition);
        derivee=@(q,t) g_function(q,t,'glissement',direction);
        q1=Runge_Kutta(q1,t0,h,derivee);
        ecoule=h;
        if dt<t_transition
            ev.regime_final='glissement';
            ev.u_final=vitesse_contact(q1,R);
            return;
        end
        ev.tr=t_transition;
        q1(7:8)=[-q1(2);q1(1)]/R;
    else
        q1(7:8)=[-q1(2);q1(1)]/R;
    end

    vitesse=norm(q1(1:2));
    if vitesse<=tol
        q1(1:2)=0;q1(7:8)=0;
        ev.t_arret=ecoule;ev.regime_final='immobile';
        ev.u_final=zeros(3,1);
        return;
    end

    restant=max(0,dt-ecoule);
    t_stop=vitesse/(mu_r*g);
    h=min(restant,t_stop);
    direction=[q1(1:2)/vitesse;0];
    derivee=@(q,t) g_function(q,t,'roulement',direction);
    if h>0
        q1=Runge_Kutta(q1,t0+ecoule,h,derivee);
    end
    q1(7:8)=[-q1(2);q1(1)]/R;
    if restant>=t_stop
        q1(1:2)=0;q1(7:8)=0;
        ev.t_arret=ecoule+t_stop;ev.regime_final='immobile';
    else
        ev.regime_final='roulement';
    end
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
