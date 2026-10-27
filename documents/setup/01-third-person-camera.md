# Mise en place de la caméra 3C — vue troisième personne fixe

> **Étape 1 des 3C** · branche `SlapOrCheck-3C` · plan validé le 2026-10-22, implémenté.

## Contexte

Le projet Godot est vide (seul `project.godot` existe) et on attaque les 3C en
commençant par la **caméra**. Objectif : une scène jouable vide, cadrée exactement comme
la maquette Three.js, pour pouvoir juger le cadrage avant d'écrire la moindre ligne de
gameplay.

Contraintes données : caméra **fixe**, placée **derrière le personnage**, pas de
personnage réel, pas d'interface, uniquement des blocs simples servant de repères de
projection.

La maquette (`documents/claque-ou-check-local.html`) fournit toutes les valeurs de
cadrage. **Three.js et Godot partagent la même convention d'axes** (Y haut, Z vers le
spectateur, repère direct) : les coordonnées se transposent telles quelles, seules les
rotations sont à recalculer.

**Aucun script GDScript à cette étape.** Une caméra fixe et un décor statique n'ont
besoin d'aucun code : tout reste réglable à la souris dans l'inspecteur, ce qui est
précisément ce qu'on veut pour itérer sur le cadrage. Le premier script arrivera avec le
personnage et les contrôles.

## Arborescence créée

Conventions : `PascalCase` pour les scènes, `snake_case` pour les ressources, noms de
nœuds en anglais (cf. `.claude/CLAUDE.md`).

```
slap-or-check/
  assets/materials/*.tres               # StandardMaterial3D partagés, un par surface
  assets/environments/open_space.tres   # Environment : ciel, ambiance, brouillard
  scenes/environment/OfficeBay.tscn     # un poste de travail (bureau + écran + cloison)
  scenes/environment/OfficePlant.tscn   # un pot + feuillage
  scenes/environment/OpenSpaceCorridor.tscn
  scenes/camera/ThirdPersonCameraRig.tscn
  scenes/placeholders/PlaceholderFigure.tscn
  scenes/levels/Level.tscn              # scène principale, assemble le tout
```

## 1. `ThirdPersonCameraRig.tscn` — le cœur de la demande

Le rig est **ancré à l'emplacement du personnage**, et la caméra porte un décalage
**local**. L'offset se lit donc directement comme « derrière et au-dessus du
personnage », au lieu d'être une position absolue opaque.

```
ThirdPersonCameraRig (Node3D)   # ancre : posée aux pieds du personnage
└── ShakeOffset (Node3D)        # identité pour l'instant ; réservé au screenshake
    └── Camera3D
```

| Propriété | Valeur | Origine |
|---|---|---|
| `Camera3D.position` (locale) | `(0.8, 2.55, 3.05)` | maquette : monde `(1.35, 2.55, 5.7)` − ancre `(0.55, 0, 2.65)` |
| `Camera3D.rotation_degrees` | `(-7.6, 7.9, 0)` | recalculé depuis `lookAt(0, 1.25, -4)` |
| `Camera3D.fov` | `48` | identique (Godot `keep_aspect = KEEP_HEIGHT`, comme Three.js) |
| `Camera3D.near` / `far` | `0.1` / `80` | maquette |

Le `ShakeOffset` intermédiaire existe pour que la secousse de la claque s'applique plus
tard sans toucher ni à l'ancre ni au cadrage : c'est la seule anticipation de ce plan,
elle coûte un nœud vide.

## 2. `OpenSpaceCorridor.tscn` — le décor

Contient aussi l'éclairage et le `WorldEnvironment` : changer de décor (open space →
salon de l'emploi → visio, prévus au game design) doit changer l'ambiance d'un bloc.

```
OpenSpaceCorridor (Node3D)
├── WorldEnvironment        → assets/environments/open_space.tres
├── SunLight (DirectionalLight3D)
├── Ground      PlaneMesh 10 × 60      à (0, 0, -20)
├── Lane        PlaneMesh 1.6 × 60     à (0.1, 0.005, -20)
├── LaneDashes (Node3D)     19 × PlaneMesh 0.08 × 1.0, x = 0.1, y = 0.01,
│                           z de 4 à -39.2 par pas de -2.4
├── BackWall    BoxMesh 14 × 8 × 0.2   à (0, 4, -34)
├── OfficeBays (Node3D)     18 instances d'OfficeBay
└── Plants (Node3D)         5 instances d'OfficePlant, x = -1.6,
                            z = -1.2, -10.2, -19.2, -28.2, -37.2
```

Le mur du fond est un `BoxMesh` et non un `PlaneMesh` : un plan vertical en Godot est
simple face, et une erreur d'orientation se traduit par un mur invisible.

**`OfficeBay.tscn`** (origine locale au sol, au centre du bureau) :

| Nœud | Mesh | Position locale |
|---|---|---|
| `Desk` | BoxMesh 1.6 × 0.75 × 0.9 | `(0, 0.375, 0)` |
| `Monitor` | BoxMesh 0.7 × 0.45 × 0.06 | `(0, 1.0, -0.2)` |
| `Partition` | BoxMesh 1.7 × 1.3 × 0.08 | `(0, 0.65, -0.6)` |

Instanciées sur 9 rangées, `z = 0, -4.5, -9 … -36` : côté gauche `x = -2.9`, côté droit
`x = 3.1` **décalé de -2 en z** (le décalage de la maquette, qui casse la symétrie et
donne de la profondeur).

**`OfficePlant.tscn`** : `Planter` CylinderMesh (haut 0.22, bas 0.18, hauteur 0.45,
10 segments) à `(0, 0.225, 0)` ; `Foliage` SphereMesh rayon 0.42 à `(0, 0.8, 0)`.

**`open_space.tres`** (Environment) : fond couleur `#DCE3EE` ; brouillard de profondeur
activé, `fog_depth_begin = 12`, `fog_depth_end = 30`, couleur `#DCE3EE` — c'est lui qui
fait disparaître le fond du couloir comme sur l'image. Lumière ambiante par couleur,
énergie ≈ 0.85, en remplacement de la `HemisphereLight` de la maquette (à juger à l'œil).

**`SunLight`** : `rotation_degrees = (-50, 26.5, 0)`, énergie `0.55`, ombres activées —
recalculé depuis la lumière directionnelle placée en `(3, 8, 6)` de la maquette.

## 3. Matériaux

Un `StandardMaterial3D` par surface dans `assets/materials/`, partagé par instanciation —
changer la couleur du sol se fait en un endroit. Valeurs reprises de la maquette :

| Fichier | Couleur | Usage |
|---|---|---|
| `ground.tres` | `#C9D1DC` | sol |
| `lane.tres` | `#B7C1CF` | couloir central |
| `lane_dash.tres` | `#E8ECF2` | pointillés |
| `desk.tres` | `#E3E7EE` | bureaux |
| `monitor.tres` | `#2F3B63` | écrans |
| `partition.tres` | `#AFC0D6` | cloisons |
| `planter.tres` | `#C27A4E` | pots |
| `foliage.tres` | `#5E9E6E` | feuillage |
| `back_wall.tres` | `#CDD5E1` | mur du fond |
| `placeholder.tres` | `#1B1E26` | blocs repères |

## 4. Blocs repères

Un seul `PlaceholderFigure.tscn` (BoxMesh 0.4 × 1.8 × 0.3, centré à `y = 0.9` pour poser
la base au sol), instancié sous un nœud `Placeholders` qu'on supprimera d'un clic :

| Instance | Position | Ce qu'elle matérialise |
|---|---|---|
| `PlayerPlaceholder` | `(0.55, 0, 2.65)` | le joueur — valide le cadrage par-dessus l'épaule |
| `IncomingCharacter` | `(0.11, 0, 1.75)` | la distance de réponse, où le personnage arrive |
| `QueuedCharacter1` | `(0.11, 0, -12)` | l'apparition au fond de la file |
| `QueuedCharacter2` | `(0.11, 0, -13.7)` | l'espacement de la file (1.7) |

Le bloc joueur est légèrement plus large (0.45 × 1.8 × 0.3) pour se distinguer au premier
plan.

## 5. `Level.tscn` et réglages projet

```
Level (Node3D)
├── OpenSpaceCorridor (instance)
├── ThirdPersonCameraRig (instance)   à (0.55, 0, 2.65)
└── Placeholders (Node3D)             les 4 blocs ci-dessus
```

Ajouts à `project.godot` :

```ini
[application]
run/main_scene="res://scenes/levels/Level.tscn"

[display]
window/size/viewport_width=720
window/size/viewport_height=1280
window/handheld/orientation="portrait"
```

`stretch/mode="canvas_items"` et `aspect="expand"` sont déjà en place et conviennent. Le
renderer reste **Forward Plus** : le passage en Mobile pourra se faire plus tard, il
n'influence pas le cadrage.

## Vérification

Rien n'est lancé de mon côté. À faire dans l'éditeur :

1. Ouvrir le projet, puis **F5** : la fenêtre doit s'ouvrir en portrait et montrer le
   couloir cadré comme l'image — bloc joueur en bas à gauche, couloir fuyant vers le
   fond, bureaux de part et d'autre, fond noyé dans le brouillard.
2. Ouvrir `Level.tscn` et cliquer sur le `Camera3D` → **Aperçu** dans la vue 3D, pour
   comparer au cadrage de la maquette.
3. Points à juger, qui conditionnent la suite : le bloc en `z = -12` est-il assez gros
   pour qu'une bulle au-dessus de lui soit lisible ? La hauteur de caméra (2.55) montre-
   t-elle assez de couloir ? Le bloc joueur mange-t-il trop d'écran ?
4. Tout se règle en déplaçant le `Camera3D` dans l'inspecteur : les valeurs ci-dessus
   sont le point de départ de la maquette, pas une cible.

## Hors périmètre, à signaler

L'exécutable de 146 Mo à la racine n'est toujours pas ignoré par git. Il est encore en
`untracked` : un `git add -A` sur cette branche le ferait entrer dans l'historique.
