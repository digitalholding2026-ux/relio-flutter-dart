# Specification de marque — source

Ce dossier contient les fichiers de marque **livres et valides**. Ce ne sont pas
des livrables : ce sont les **entrees** du generateur.

| Fichier | Role |
|---|---|
| `relio_app_icon.svg` | icone applicative — **fait master** du mark |
| `relio_logo_principal.svg` | logo principal : lockup mark + mot + signature |

## Pourquoi un seul mark

Les deux fichiers ne dessinent pas exactement le meme « R » : dans l'icone il
mesure 233 x 307 unites, dans le logo 203 x 242. Ce ne sont pas deux mises a
l'echelle du meme dessin, ce sont deux dessins.

Une marque ne peut pas avoir deux « R ». La regle 9 impose une geometrie
unique, et c'est donc **`relio_app_icon.svg` qui fait master** : elle est en
512 px, elle porte les quatre elements du mark (le « R », le zigzag d'accent,
le second zigzag, le point), et elle se decline sans reecriture.

`relio_logo_principal.svg` sert alors de reference pour ce qui n'est pas le
mark : le rapport entre le mark et le mot, la taille de la signature, son
ecartement. Ces valeurs sont reprises dans `RelioBrand`.

**Si le « R » du logo est en realite le dessin voulu**, il faut le signaler :
la geometrie est a reconstruire sur cette base, et les valeurs de l'icone a
recalculer.

## Ce que ces fichiers NE sont pas

Ils ne sont pas la source de verite du code. La source de verite est
`lib/presentation/branding/relio_mark_geometry.dart` :

- les traces y sont normalisees dans la grille de reference 100 x 100 ;
- le SVG, le PNG et le rendu a l'ecran sont generes a partir de ce fichier ;
- le mot et la signature ne sont PAS dans ces SVG de mark : ils sont poses par
  l'application en Inter SemiBold 600, la police etant deja embarquee.

## Ce qui garantit la coherence

`test/branding/brand_spec_test.dart` relit `relio_app_icon.svg`, reapplique
exactement la normalisation de l'import, et compare le resultat aux constantes
de la geometrie.

Concretement : **ajuster une coordonnee a la main dans
`relio_mark_geometry.dart` fait echouer la suite.** La regle 9 devient
opposable au lieu d'etre une declaration.

Pour modifier la marque, dans l'ordre :

1. editer le SVG de specification ici ;
2. reconstruire les constantes de `relio_mark_geometry.dart` ;
3. `dart run tool/gen_branding.dart` ;
4. `flutter test tool/render_branding_test.dart` ;
5. `flutter analyze && flutter test`.