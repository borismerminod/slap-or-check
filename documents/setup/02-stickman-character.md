# Le personnage stickman — figure et animations

> **Étape 2 des 3C** · branche `SlapOrCheck-3C` · décidé le 2026-10-22, implémenté.

## Contexte

Deuxième brique des 3C, après la caméra. Question posée : faut-il modéliser le
personnage dans Blender ?

**Non.** Le stickman de la maquette est une hiérarchie de 13 cylindres et sphères, et
toutes ses animations sont des **rotations de pivots** — aucune déformation de maillage,
donc aucun squelette, aucun skinning, aucun import. Blender n'apporterait rien et
coûterait un pipeline d'import, des binaires dans le dépôt et un aller-retour export à
chaque ajustement de proportion.

Blender redeviendra pertinent le jour où on voudra un personnage déformable, des coudes
qui plient, du tissu ou des expressions faciales. Rien de tout cela n'est au game design.

## Décision : une seule scène pour tout le monde

`scenes/characters/Stickman.tscn` sert au joueur **et** aux personnages de la file,
comme la fonction `stick()` de la maquette. Le joueur n'est pas un cas particulier :
c'est le même corps, vu de dos.

La figure a ses pieds à l'origine et **regarde vers -Z**, la convention « avant » de
Godot. C'est l'inverse de la maquette (qui fait face à +Z et retourne le joueur de 180°) :
ici le joueur n'a aucune rotation, ce sont les arrivants qu'on retourne.

### Arborescence

```
Stickman (Node3D)              ← le code déplacera CE nœud le long du couloir
├── Body (Node3D)              ← les animations possèdent CE nœud
│   ├── Torso, Pelvis
│   ├── Head (Node3D)          → Skull, LeftEye, RightEye, HatAnchor
│   ├── ChestAnchor (Marker3D)
│   ├── LeftArmPivot  (-0.2, 1.5, 0)  → UpperArm, Hand, HandAnchor
│   ├── RightArmPivot (+0.2, 1.5, 0)  → UpperArm, Hand, HandAnchor
│   └── Hips (0, 0.9, 0)
│       ├── LeftLegPivot  (-0.1, 0, 0) → Leg, Foot
│       └── RightLegPivot (+0.1, 0, 0) → Leg, Foot
└── AnimationPlayer
```

**La séparation `Stickman` / `Body` est le point important.** Le code de gameplay déplace
la racine (position dans le couloir, trajectoire d'envol) ; les animations ne touchent
qu'à `Body` (inclinaison, rebond de marche, vacillement, culbute). Les deux ne se
marchent jamais dessus. Même principe que le `ShakeOffset` du rig de caméra.

Les `Marker3D` (`HatAnchor`, `ChestAnchor`, `HandAnchor`) sont les points d'accroche des
personnages spéciaux — casquette du Relou, cravate du Coriace, lunettes et téléphone de
l'Influenceur, fleur du Vrai Gentil. Ils ne portent rien pour l'instant : ils existent
pour que l'étape « briques » n'ait pas à rouvrir ce fichier.

### Proportions

Reprises telles quelles de `stick()`. Hauteur totale 2,10 m.

| Partie | Dimensions | Position |
|---|---|---|
| Torse | cylindre 0.66 × r0.075 | haut à y = 1.56 |
| Bassin / mains / pieds | sphères de rayon × 1.25 | aux extrémités des membres |
| Tête | sphère r0.25 | y = 1.85 |
| Bras | cylindre 0.62 × r0.055 | pivot à (±0.2, 1.5) |
| Jambes | cylindre 0.9 × r0.06 | pivot à (±0.1, 0.9) |

Pas de disque d'ombre truqué, contrairement à la maquette : les ombres portées réelles
sont activées sur la lumière du couloir depuis l'étape 1.

## Les six animations

| Clip | Durée | Boucle | Ce qu'elle fait |
|---|---|---|---|
| `idle` | 3.14 s | oui | Bras légèrement écartés, l'un oscille doucement |
| `walk` | 0.74 s | oui | Un cycle complet de `sin()` : jambes, bras opposés, rebond vertical |
| `slap` | 0.42 s | non | Bras droit armé en arrière, balayage, retour ; le buste pivote avec |
| `check` | 0.60 s | non | Main droite levée en avant, maintenue, redescendue |
| `knocked_away` | 1.40 s | non | Pose bras écartés + culbute du `Body` |
| `stagger` | 0.35 s | non | Vacillement amorti, échantillonné sur `sin(t·30)·0.12·(1−t/0.35)` |

Deux choix à connaître :

- **Il n'y a pas de clip « bousculade ».** Dans la maquette, c'est `walkAnim` joué à
  vitesse 13 au lieu de 8.5. Ici c'est `walk` avec un `speed_scale` plus élevé. Même
  chose pour la file qui avance au fond (vitesse 7) et pour la ruée finale (16) : un
  seul clip, plusieurs vitesses.
- **`knocked_away` n'anime que la pose et la culbute**, pas la trajectoire. La parabole
  (vitesse initiale, gravité) dépend de l'instant de la frappe : elle appartiendra au
  code qui déplace la racine, pas à un clip figé.

**Correction après premier test.** Les rotations en X des membres avaient été reprises
telles quelles de la maquette, dont la figure regarde vers **+Z**. La nôtre regarde vers
**-Z** : sur un pivot dont le membre pend vers le bas, une rotation X **positive** envoie
donc le membre vers l'avant ici, et vers l'arrière là-bas. La claque et le check
partaient dans le dos. Les X de `slap`, `check` et `knocked_away` sont inversés, ainsi
que le lacet du buste dans `slap` (l'épaule droite doit reculer à l'armement, pas
avancer).

`walk` n'était pas touché : son balancement est symétrique, inverser les signes ne fait
que décaler le cycle d'une demi-foulée. `idle` et `stagger` non plus, ils ne tournent
qu'autour de Z.

**Règle à retenir** : sur un membre qui pend, rotation X positive = vers l'avant, parce
que la figure regarde vers -Z.

Le `check` utilise le bras **droit** des deux personnages. Deux personnes face à face
qui lèvent chacune leur main droite, leurs mains se rencontrent : c'est le geste réel.

## Couleur des personnages

Tous les maillages du corps partagent **un seul** `stickman_body.tres`. C'est délibéré :
la couleur par personnage (« stickmen simples, couleurs variées » du game design) se fera
en dupliquant ce matériau au moment de l'apparition, dans le code du spawner. Tant que ce
code n'existe pas, les quatre stickmen du niveau sont identiques.

**Aucun GDScript à cette étape** : une figure et des clips d'animation n'en demandent
pas. L'API (`play_animation`, `set_body_color`) viendra avec le spawner, qui est le
premier à en avoir besoin.

## Fichiers

| Fichier | Rôle |
|---|---|
| `scenes/characters/Stickman.tscn` | la figure, ses 6 clips, son `AnimationPlayer` |
| `assets/materials/stickman_body.tres` | corps, couleur par défaut du joueur |
| `assets/materials/stickman_eye.tres` | yeux |
| `scenes/levels/Level.tscn` | les 4 blocs repères remplacés par des Stickman |
| `scenes/camera/ThirdPersonCameraRig.tscn` | transform réécrite (voir ci-dessous) |

`scenes/placeholders/PlaceholderFigure.tscn` n'est plus utilisé mais reste dans le dépôt :
il resservira à bloquer les prochains éléments (bulle, bonus café).

## Rangement de la caméra, et une correction

Le cadrage ajusté à la main dans `Level.tscn` avait été appliqué au **rig**, pas au
`Camera3D`. La transform a été recomposée : ancre revenue à (0.55, 0, 2.65) sans
rotation, rotation passée dans le `Camera3D`. Résultat à l'écran identique.

**Correction d'une erreur de l'étape 1.** Un `Transform3D` dans un fichier `.tscn` est
sérialisé **par lignes** : les arguments 0 à 2 sont `basis.rows[0]`, soit
`(x_axis.x, y_axis.x, z_axis.x)`. Ce n'est **pas** la convention du constructeur GDScript
`Transform3D(x_axis, y_axis, z_axis, origin)`, qui prend les axes. Les deux transforms
écrites à la main à l'étape 1 — la caméra et le `SunLight` — l'avaient été par axes,
donc transposées, donc tournées de la rotation **inverse**. Les deux sont corrigées.

Toute transform sans rotation (translation seule) était épargnée, la matrice identité
étant symétrique, ainsi que les demi-tours des arrivants.

À retenir pour la suite : **une rotation écrite à la main dans un `.tscn` se vérifie à
l'image**, pas au calcul.

### État actuel du cadrage

Caméra monde à **(1.465 ; 3.467 ; 7.565)**, orientée **vers le bas de 17,4°**.

| Élément | Profondeur | Hauteur à l'écran | Position horizontale (720×1280) |
|---|---|---|---|
| Tête du joueur | 5,17 m | 45,7 % | +0,30 |
| Tête de l'arrivant (z = 1.75) | 6,10 m | 38,6 % | +0,13 |
| Tête de la file (z = -12) | 18,78 m | 12,6 % | **+0,80** |

Deux points ouverts, mesurés et non résolus :

- **La file frôle le bord droit.** À +0,80 sur un axe qui va de -1 à +1, un personnage
  au fond du couloir est presque hors cadre, et une bulle au-dessus de sa tête serait
  rognée. L'écart vient du format : l'éditeur montre un viewport plus large que le jeu.
- **Le joueur et l'arrivant se chevauchent** : 0,20 d'écart entre leurs têtes, pour des
  figures qui occupent 46 % et 39 % de la hauteur. Reculer la distance d'arrêt n'y change
  presque rien (0,19 à z = 0.25, 0,30 à z = -1.25) : le levier est le décalage latéral
  de la caméra ou la position en x du joueur, pas la distance.

## Vérification

1. Ouvrir `Stickman.tscn`, sélectionner l'`AnimationPlayer`, jouer les six clips un par
   un. C'est là que se jugent les signes de rotation : si la claque part du mauvais côté
   ou si le check lève le bras vers l'arrière, c'est un signe à inverser dans la piste.
2. Ouvrir `Level.tscn` et regarder par la caméra : quatre stickmen, le joueur de dos au
   premier plan, trois arrivants qui lui font face.
3. Juger les proportions **en mouvement**, pas à l'arrêt : jouer `walk` en boucle et
   vérifier que l'amplitude des jambes (0.6 rad) ne fait pas patiner la figure.
4. La contre-plongée : un stickman à z = −12 est-il assez grand pour porter une bulle
   lisible ?
