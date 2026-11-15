function [coll,tr,t,positions,journal] = simuler_tp3(xyb,xyr,xyj,Vb0,options)
% SIMULER_TP3 Assemblage des modules du TP3, sans leurs lois physiques.
% Usage public : Devoir3. Usage diagnostic : cinquieme sortie journal.
% options sert aux essais d'integration et au choix du pas, pas a RouleDevoir3.
% Contrats des modules : voir CONTRATS_MODULES.md.

    if nargin < 5, options = struct(); end
    R = 0.031; L = 2.80; H = 1.53;
    xy = [vecteur2(xyb,'xyb'), vecteur2(xyr,'xyr'), vecteur2(xyj,'xyj')];
    vb = vecteur2(Vb0,'Vb0');
    if any(xy(1,:) < R) || any(xy(1,:) > L-R) || ...
       any(xy(2,:) < R) || any(xy(2,:) > H-R)
        error('TP3:PositionInitiale','Un centre de bille est hors de la table utile.');
    end
    paires = [1 2;1 3;2 3];
    for k=1:3
        if norm(xy(:,paires(k,1))-xy(:,paires(k,2))) < 2*R-1e-10
            error('TP3:ChevauchementInitial','Deux billes se chevauchent au depart.');
        end
    end

    cfg = configuration(options);
    Q = zeros(9,3);
    Q(4:5,:) = xy; Q(6,:) = R;
    Q(1:2,1) = vb; % Vb0 a bien deux composantes, vz = 0.
    maintenant = 0; touchees = [false false]; tr = [];
    capacite = 8192; nombre = 1;
    temps = zeros(1,capacite); trajectoire = zeros(6,capacite);
    trajectoire(:,1) = reshape(Q(4:5,:),6,1);
    journal = struct('temps',{},'type',{},'billes',{});
    iterations = 0;

    while ~immobile(Q(:,1),cfg.v_tol)
        iterations = iterations+1;
        if iterations > cfg.max_iterations
            error('TP3:Convergence', ...
                'Trop d''iterations : verifier les modules. Aucun resultat partiel n''est valide.');
        end

        % Resoudre les contacts presents avant toute nouvelle avancee.
        [Q,touchees,evenements] = traiter_contacts(Q,touchees,cfg,R,L,H);
        if ~isempty(evenements)
            for k=1:numel(evenements)
                evenements(k).temps = maintenant;
            end
            journal = [journal evenements]; %#ok<AGROW>
            trajectoire(:,nombre) = reshape(Q(4:5,:),6,1);
        end
        if immobile(Q(:,1),cfg.v_tol), break; end

        vitesse = max(sqrt(sum(Q(1:2,:).^2,1)));
        h = min(cfg.dt_max, R/(4*max(vitesse,cfg.v_tol)));
        [Qessai,evb] = avancer(Q,maintenant,h,cfg,R);

        % Le module du mouvement signale l'arret interieur au pas.
        if isfinite(evb.t_arret) && evb.t_arret < h
            if evb.t_arret <= cfg.t_tol && ~immobile(Qessai(:,1),cfg.v_tol)
                error('TP3:ContratMouvement','t_arret est nul mais la blanche bouge encore.');
            end
            h = max(evb.t_arret,cfg.t_tol);
            [Qessai,evb] = avancer(Q,maintenant,h,cfg,R);
        end

        % Localiser le premier contact avant de valider l'avancee.
        hcontact = premier_contact(Q,Qessai,maintenant,h,cfg,R,L,H);
        if isfinite(hcontact) && hcontact < h
            h = hcontact;
            [Qessai,evb] = avancer(Q,maintenant,h,cfg,R);
        end
        if h <= 0 || maintenant+h == maintenant
            error('TP3:AvanceeNulle','La localisation des evenements ne progresse plus.');
        end

        nouvelles = maintenant+evb.tr(:).';
        for k=1:numel(nouvelles)
            if isempty(tr) || nouvelles(k)-tr(end) > cfg.t_tol
                tr(end+1) = nouvelles(k); %#ok<AGROW>
                journal(end+1) = struct('temps',nouvelles(k), ...
                    'type','transition','billes',1); %#ok<AGROW>
            end
        end
        maintenant = maintenant+h; Q = Qessai;
        nombre = nombre+1;
        if nombre > capacite
            capacite = 2*capacite;
            temps(1,capacite) = 0; trajectoire(6,capacite) = 0;
        end
        temps(nombre) = maintenant;
        trajectoire(:,nombre) = reshape(Q(4:5,:),6,1);
    end

    coll = sum(touchees);
    temps = temps(1:nombre); trajectoire = trajectoire(:,1:nombre);
    [t,positions] = echantillonner(temps,trajectoire);
    journal(end+1) = struct('temps',maintenant,'type','arret_blanche','billes',1);
end

function v = vecteur2(v,nom)
    if ~isnumeric(v) || ~isreal(v) || numel(v)~=2 || any(~isfinite(v(:)))
        error('TP3:Entree','%s doit contenir deux nombres reels finis.',nom);
    end
    v = double(v(:));
end

function cfg = configuration(o)
    if ~isstruct(o), error('TP3:Options','Les options doivent former une structure.'); end
    cfg = struct('dt_max',1e-3,'t_tol',1e-9,'contact_tol',1e-8, ...
        'v_tol',1e-8,'max_iterations',2000000);
    noms = fieldnames(cfg);
    for k=1:numel(noms)
        if isfield(o,noms{k}), cfg.(noms{k})=o.(noms{k}); end
        x=cfg.(noms{k});
        if ~isnumeric(x)||~isscalar(x)||~isfinite(x)||x<=0
            error('TP3:Options','Option invalide : %s.',noms{k});
        end
    end
    requis={'mouvement_billes','collision_billes','collision_bande'};
    absents={};
    for k=1:numel(requis)
        nom=requis{k};
        if isfield(o,nom) && isa(o.(nom),'function_handle')
            cfg.(nom)=o.(nom);
        elseif exist(nom,'file')==2
            cfg.(nom)=str2func(nom);
        else
            absents{end+1}=nom; %#ok<AGROW>
        end
    end
    if ~isempty(absents)
        error('TP3:ModulesManquants', ...
            'Modules manquants : %s. Voir CONTRATS_MODULES.md. Aucun modele fictif n''est utilise.', ...
            strjoin(absents,', '));
    end
end

function oui = immobile(q,tol)
    % Une vitesse du centre nulle instantanement ne suffit pas si la bille
    % tourne encore autour d'un axe horizontal et peut repartir en glissant.
    oui = norm(q(1:2))<=tol && 0.031*norm(q(7:8))<=tol;
end

function [Q1,evb] = avancer(Q,t0,h,cfg,R)
    Q1=zeros(9,3); evb=struct('tr',[],'t_arret',Inf);
    for b=1:3
        [q,ev]=cfg.mouvement_billes(Q(:,b),t0,h);
        q=etat(q);
        if abs(q(3))>1e-9 || abs(q(6)-R)>1e-9
            error('TP3:PlanTable','Le module mouvement doit conserver vz=0 et z=R.');
        end
        if ~isstruct(ev)||~isfield(ev,'tr')||~isfield(ev,'t_arret')
            error('TP3:ContratMouvement','Le module mouvement doit retourner ev.tr et ev.t_arret.');
        end
        z=ev.tr;
        if ~isnumeric(z)||~isreal(z)||any(~isfinite(z(:)))|| ...
           any(z(:)<-cfg.t_tol)||any(z(:)>h+cfg.t_tol)|| ...
           ~isnumeric(ev.t_arret)||~isreal(ev.t_arret)||~isscalar(ev.t_arret)|| ...
           isnan(ev.t_arret)||ev.t_arret<0|| ...
           (isfinite(ev.t_arret)&&ev.t_arret>h+cfg.t_tol)
            error('TP3:ContratMouvement','Evenements du mouvement hors du pas demande.');
        end
        Q1(:,b)=q;
        if b==1
            evb=ev; evb.tr=sort(unique(max(0,min(h,z(:).'))));
            if ~immobile(Q(:,1),cfg.v_tol) && immobile(q,cfg.v_tol) && ~isfinite(ev.t_arret)
                error('TP3:ContratMouvement', ...
                    'La blanche s''arrete dans le pas : le module doit fournir ev.t_arret.');
            end
        end
    end
end

function q=etat(q)
    if ~isnumeric(q)||~isreal(q)||~isequal(size(q),[9 1])||any(~isfinite(q))
        error('TP3:Etat','Un module a produit un etat invalide ; vecteur 9x1 fini attendu.');
    end
end

function tau=premier_contact(Q,Q1,t0,h,cfg,R,L,H)
    tau=Inf;
    % Douze distances centre-bande ; les centres restent a au moins R.
    G0=distances_bandes(Q,R,L,H); G1=distances_bandes(Q1,R,L,H);
    for b=1:3
        for cote=1:4
            if G1(cote,b)<0 && G0(cote,b)>=-cfg.contact_tol
                f=@(s) ecart_bande(Q,t0,s,cfg,R,L,H,b,cote);
                candidate=racine(f,0,h,cfg.t_tol);
                tau=min(tau,candidate);
            end
        end
    end
    paires=[1 2;1 3;2 3];
    for k=1:3
        a=paires(k,1); b=paires(k,2);
        r0=Q(4:5,a)-Q(4:5,b); r1=Q1(4:5,a)-Q1(4:5,b);
        g0=norm(r0)-2*R; g1=norm(r1)-2*R;
        % Un contact initial separant est deja traite et doit pouvoir quitter
        % le contact. Un rapprochement ulterieur sera traite au pas suivant.
        if g0<=cfg.contact_tol && dot(r0,Q(1:2,a)-Q(1:2,b))>=0
            if g1>=-cfg.contact_tol, continue; end
        end
        f=@(s) ecart_billes(Q,t0,s,cfg,R,a,b);
        borne=h;
        if g1>0
            dr=r1-r0;
            if dot(dr,dr)==0, continue; end
            fraction=max(0,min(1,-dot(r0,dr)/dot(dr,dr)));
            % Test du segment balaye, avec une marge pour la courbure du pas.
            if norm(r0+fraction*dr)>2*R+1e-4, continue; end
            [borne,gmin]=fminbnd(f,0,h,optimset('TolX',cfg.t_tol));
            if gmin>0, continue; end
        end
        if g0>=-cfg.contact_tol && borne>cfg.t_tol
            candidate=racine(f,0,borne,cfg.t_tol);
            if candidate>0, tau=min(tau,candidate); end
        end
    end
end

function g=ecart_bande(Q,t0,h,cfg,R,L,H,b,cote)
    [A,~]=avancer(Q,t0,h,cfg,R);
    D=distances_bandes(A,R,L,H);g=D(cote,b);
end

function g=ecart_billes(Q,t0,h,cfg,R,a,b)
    [A,~]=avancer(Q,t0,h,cfg,R);
    g=norm(A(4:5,a)-A(4:5,b))-2*R;
end

function x=racine(f,a,b,tol)
    % Renvoie le cote contact du premier zero encadre.
    for k=1:64
        if b-a<=tol, break; end
        c=(a+b)/2;
        if f(c)<=0, b=c; else, a=c; end
    end
    x=b;
end

function D=distances_bandes(Q,R,L,H)
    D=[Q(4,:)-R; L-R-Q(4,:); Q(5,:)-R; H-R-Q(5,:)];
end

function [Q,touchees,journal]=traiter_contacts(Q,touchees,cfg,R,L,H)
    journal=struct('temps',{},'type',{},'billes',{});
    paires=[1 2;1 3;2 3]; normales=[1 -1 0 0;0 0 1 -1;0 0 0 0];
    % Plusieurs contacts a un meme instant (ex. coin) sont retraites jusqu'a
    % separation. Les vrais chocs multiples restent a valider par l'equipe.
    for passage=1:16
        changement=false;
        for k=1:3
            a=paires(k,1); b=paires(k,2);
            delta=Q(4:5,a)-Q(4:5,b); d=norm(delta);
            if d==0, error('TP3:CentresConfondus','Centres de billes confondus.'); end
            n=[delta/d;0];
            if d<=2*R+cfg.contact_tol && dot(Q(1:3,a)-Q(1:3,b),n)<-cfg.v_tol
                [va,vb,wa,wb,info]=cfg.collision_billes( ...
                    Q(4:6,a),Q(4:6,b),Q(1:3,a),Q(1:3,b),Q(7:9,a),Q(7:9,b));
                Q(1:3,a)=vecteur3(va); Q(1:3,b)=vecteur3(vb);
                Q(7:9,a)=vecteur3(wa); Q(7:9,b)=vecteur3(wb);
                if ~isstruct(info)||~isfield(info,'j')||~isscalar(info.j)|| ...
                   ~isfinite(info.j)||info.j<=0
                    error('TP3:ContratCollision','Une collision approchante doit produire info.j > 0.');
                end
                correction=max(0,2*R-d)/2;
                Q(4:5,a)=Q(4:5,a)+correction*n(1:2);
                Q(4:5,b)=Q(4:5,b)-correction*n(1:2);
                if a==1, touchees(b-1)=true; end
                journal(end+1)=struct('temps',0,'type','bille_bille','billes',[a b]); %#ok<AGROW>
                changement=true;
            end
        end
        D=distances_bandes(Q,R,L,H);
        for b=1:3
            for cote=1:4
                n=normales(:,cote);
                if D(cote,b)<=cfg.contact_tol && dot(Q(1:3,b),n)<-cfg.v_tol
                    [v,w,~]=cfg.collision_bande(Q(4:6,b),Q(1:3,b),Q(7:9,b),n);
                    Q(1:3,b)=vecteur3(v); Q(7:9,b)=vecteur3(w);
                    switch cote
                        case 1, Q(4,b)=R;
                        case 2, Q(4,b)=L-R;
                        case 3, Q(5,b)=R;
                        case 4, Q(5,b)=H-R;
                    end
                    journal(end+1)=struct('temps',0,'type','bille_bande','billes',[b cote]); %#ok<AGROW>
                    changement=true;
                end
            end
        end
        if ~changement, return; end
    end
    error('TP3:ContactMultiple','Contacts persistants : verifier les reponses aux collisions.');
end

function v=vecteur3(v)
    if ~isnumeric(v)||~isreal(v)||~isequal(size(v),[3 1])||any(~isfinite(v))
        error('TP3:ContratCollision','Vecteur colonne 3x1 fini attendu apres collision.');
    end
end

function [t,P]=echantillonner(T,A)
    n=numel(T);
    if n==1
        t=zeros(1,100); P=repmat(A(:,1),1,100);
    elseif n<100
        t=linspace(T(1),T(end),100);
        P=interp1(T.',A.',t.','linear').';
    else
        indices=unique(round(linspace(1,n,min(n,1000))));
        t=T(indices); P=A(:,indices);
    end
end
