# Les contrôles — deux boutons de réponse

> **Étape 3 des 3C** · branche `SlapOrCheck-3C` · décidé le 2026-10-22, implémenté.

## Contexte

Troisième brique des 3C. Demande : deux boutons comme dans la maquette, « Claque » à
gauche et « Check » à droite ; appuyer sur l'un déclenche l'animation correspondante sur
le personnage joueur.

C'est le **premier GDScript du projet**. Les étapes 1 et 2 n'en avaient pas besoin : une
caméra fixe et des clips d'animation se règlent dans l'éditeur. Ici il faut relier une
intention du joueur à une réaction visible, donc du code.

## Les quatre couches

Un bouton qui joue une animation tient en dix lignes, mais c'est l'endroit où se décide
la forme du reste du jeu. Le chemin suivi est volontairement découpé :

```
AnswerButtons (présentation)        « le joueur a demandé une claque »
        ↓ signal answer_submitted
PlayerAnswerController (orchestration)   choisit le clip correspondant
        ↓ appel
Stickman (présentation)             joue le clip, revient à idle
```

Ce qu'aucune de ces classes ne fait :

- `AnswerButtons` **ne touche à aucun personnage**. Il annonce une intention et s'arrête
  là. Il ignore jusqu'à l'existence de la 3D.
- `Stickman` **ne sait pas d'où vient l'ordre**. Il expose ses clips par leur nom ;
  personne n'atteint son `AnimationPlayer` de l'extérieur.
- `PlayerAnswerController` **ne juge pas la réponse**. Savoir si la claque était méritée
  relève de la règle du jour, qui se branchera sur le même signal sans toucher à ces
  trois classes.

`AnswerGesture.Kind` (SLAP / CHECK) est le vocabulaire commun. Il vit dans son propre
fichier pour que la couche entrée et la couche gameplay le partagent sans dépendre l'une
de l'autre : si l'enum vivait dans `AnswerButtons`, tout le gameplay dépendrait de l'UI.

## Fichiers

| Fichier | Rôle |
|---|---|
| `scripts/core/AnswerGesture.gd` | l'enum des deux réponses possibles |
| `scripts/characters/Stickman.gd` | l'API d'animation de la figure |
| `scripts/ui/AnswerButtons.gd` | les deux boutons, émet `answer_submitted` |
| `scripts/gameplay/PlayerAnswerController.gd` | relie le signal au clip du joueur |
| `scenes/ui/AnswerButtons.tscn` | la barre de boutons, couleurs de la maquette |
| `scenes/characters/Stickman.tscn` | script attaché à la racine |
| `scenes/levels/Level.tscn` | `CanvasLayer` + boutons + contrôleur |
| `project.godot` | actions `answer_slap` et `answer_check` |

Noms de fichiers de scripts en `PascalCase`, selon la convention du projet
(`.claude/CLAUDE.md`, section 4). C'est un écart assumé au guide de style de Godot, qui
recommande `snake_case` pour les fichiers : la cohérence avec les noms de scènes a été
jugée plus utile. À basculer si vous préférez la convention Godot.

## Détails qui comptent

**Une réaction ne peut pas en interrompre une autre.** `play_reaction()` refuse pendant
qu'un clip est en cours : deux appuis rapides ne coupent pas une claque en plein geste.
`play_loop()`, lui, passe outre — marcher doit toujours pouvoir annuler une pose.

**Le retour à `idle` est automatique**, via `animation_finished`. Les clips en boucle
n'émettent jamais ce signal, donc seules les réactions passent par là.

**Les flèches du clavier** sont branchées sur les mêmes actions que les boutons.
Ajout non demandé, mais la maquette affiche « flèche gauche » et « flèche droite » sous
ses boutons : reproduire les libellés sans brancher les touches aurait été un mensonge.
Deux entrées dans `project.godot`, aucun code en plus — le même `_submit_answer()` sert
les deux. À retirer si vous n'en voulez pas.

**Correction après premier lancement.** Les trois scènes qui portent une référence de
nœud exportée ont dû déclarer `node_paths=PackedStringArray(...)` dans l'en-tête du
nœud : sans cette déclaration Godot ne convertit pas le `NodePath` en nœud, et la
propriété reste nulle jusqu'au `_ready()` qui s'en sert. Piège consigné dans
`.claude/CLAUDE.md`.

**Pas de swipe pour l'instant.** Le geste au doigt de la maquette viendra se brancher sur
`_submit_answer()` sans rien changer d'autre : c'est la raison d'être de cette méthode.

## Vérification

1. **F5**. Les deux boutons apparaissent en bas, rouge à gauche, vert à droite.
2. Cliquer « Claque » : le joueur arme le bras et balaye, puis revient à l'arrêt.
   Cliquer « Check » : il lève la main, la tient, la redescend.
3. Les flèches gauche et droite font la même chose.
4. Marteler un bouton pendant une animation : rien ne doit se déclencher avant la fin.
5. Les trois autres stickmen ne bougent pas — ils n'ont pas de contrôleur, c'est normal.

Point à juger : **le joueur est vu de dos et occupe 46 % de la hauteur**. La claque
part-elle du bon côté sous cet angle, ou faut-il inverser le signe de rotation du bras
dans le clip ?
