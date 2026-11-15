# Interfaces a convenir avec l equipe

Cette contribution ne fournit ni le modele du mouvement ni les lois de rebond
sur les bandes. Elle assemble les modules ci-dessous. Ces signatures sont une
**proposition d'interface**, pas une affirmation sur les codes que les autres
membres ont deja ecrits. Si leurs signatures different, adapter leurs appels
dans simuler_tp3.m ou ecrire un petit adaptateur avec eux.

## Etat commun

Chaque bille est decrite par une colonne q de 9 nombres :

`q = [vx; vy; vz; x; y; z; wx; wy; wz]`.

Les unites sont les unites SI ; vz=0 et z=0.031 m. Dans Q, les colonnes
correspondent a la blanche, la rouge et la jaune. Ce format reprend celui de
Guillaume. La fonction publique accepte Vb0 sur deux composantes.

## Mouvement entre les collisions

```matlab
function [q1,ev] = mouvement_billes(q0,t0,dt)
```

- Le module avance **une** bille de dt secondes, sans traiter les collisions.
- Il gere les forces, les rotations, les regimes glissement/roulement et l'arret.
- Il retourne un q1 colonne 9x1 fini, a l'instant t0+dt.
- `ev.tr` est un vecteur de **delais relatifs a t0**, entre 0 et dt, pour les
  transitions glissement -> roulement survenues pendant cette avancee ; sinon [].
- `ev.t_arret` est le delai relatif d'arret si la bille s'immobilise pendant le
  pas, sinon Inf. Une bille deja immobile retourne 0 et garde son etat.
- Si elle s'arrete avant la fin du pas, elle reste immobile jusqu'a t0+dt.
- Un appel de prediction ne doit pas modifier un etat global ou persistant.
  Le moteur peut rappeler le module depuis le meme q0 pour localiser un contact.
- Le module doit accepter dt=0, les billes immobiles et les pas raccourcis.

Le moteur ne conserve que les transitions de la blanche dans la sortie tr.
Il raccourcit l'avancee des trois billes a l'instant d'arret de la blanche.

## Collision entre billes

```matlab
function [va2,vb2,wa2,wb2,info] = collision_billes(ra,rb,va,vb,wa,wb)
```

Cette interface est deja celle de Mael. Tous les vecteurs sont des colonnes 3x1.
Le moteur appelle la fonction au contact avec rapprochement. `info.j` doit etre
l'impulsion normale positive du choc. Le fichier de Mael n'est pas remplace par
ce ZIP ; conserver celui du depot.

`info.glisse` eventuel concerne le contact **entre billes** et ne remplace pas
les transitions sur le tapis.

## Collision avec une bande

```matlab
function [v2,w2,info] = collision_bande(r,v,w,n)
```

Les vecteurs sont des colonnes 3x1. n est la normale horizontale unitaire qui
pointe **vers l'interieur de la table**. r est la position du centre au contact.
La fonction retourne les vitesses apres le choc ; info peut etre une structure
vide. La physique avec restitution, frottement statique/cinetique et rotation
appartient au module du responsable des bandes.

Les normales gauche, droite, bas, haut sont respectivement +x, -x, +y, -y.

## Validation commune necessaire

Le moteur localise les contacts avant d'appeler les modules et ne traite pas
les collisions en ajoutant une force de choc a RK4. La methode des conditions
initiales est appliquee par les modules de collision.

La localisation numerique des evenements et les tests avec des doublures ne
prouvent pas la precision physique de 1 mm. Il reste a comparer les quatre tirs
avec les vrais modules en reduisant le pas maximal, puis a controler les chocs,
les transitions, les contacts rasants et les contacts multiples.
