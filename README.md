# PHS4700 — Devoir 3 : billard français

Remise : 16 novembre.

## Rapport partagé

Lien du Word : À AJOUTER

## Répartition

- Membre 1 : mouvement, frottement, glissement/roulement,
  transitions et analyse du tir 1.
- Membre 2 : collisions entre billes et analyse du tir 2.
- Membre 3 : collisions avec les bandes et analyse du tir 3.
- Membre 4 : fonction principale, intégration, sorties,
  conditions d’arrêt et analyse du tir 4.

Chacun rédige sa section et vérifie son module.
Les vérifications finales se font ensemble.

## Interface imposée

[coll,tr,t,xb,yb,xr,yr,xj,yj] = Devoir3(xyb,xyr,xyj,Vb0)

## Organisation du code

- Devoir3.m : fonction principale.
- mouvement_billes.m : mouvement entre les collisions.
- collision_billes.m : collisions entre deux billes.
- collision_bande.m : collisions avec une bande.

Avant de développer les modules, convenir ensemble du format
des données et de leurs entrées/sorties.

## Conventions

- Unités SI : mètres, secondes, kilogrammes, radians.
- Ordre des billes dans les données communes : blanche, rouge, jaune.
- Compatibilité MATLAB et GNU Octave.
- RouleDevoir3.m est le pilote fourni par le professeur.

## Échéancier visé

- 13 novembre : modules vérifiés séparément.
- 14 novembre : intégration et simulations complètes.
- 15 novembre : rapport et validation finale.