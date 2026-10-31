# La boucle de personnage — file, marche, jugement, réaction, sortie

> **Étape 4** · branche `SlapOrChack-GameLoop` · décidé le 2026-10-27, implémenté.

## Contexte

Les trois étapes des 3C donnaient une caméra cadrée, un stickman animé et deux boutons qui
jouaient une claque. Rien ne tournait : `Level.tscn` portait trois arrivants posés à la
main, et `PlayerAnswerController` jouait la réaction du joueur **sans savoir** s'il y avait
quelqu'un en face ni si la réponse était la bonne.

Cette étape construit la plus petite des trois boucles imbriquées du jeu — celle qui dure 2
à 4 secondes et qu'on répète une centaine de fois par partie.

```
spawn → walk ──(réponse)──→ dash → réaction ──→ envol / départ
          └──(arrivé, rien)→ laissé passer ───→ bousculade
```

**Hors périmètre, volontairement** : jauge de Moral, HUD, carte « Règle du jour », écran de
fin, étoiles, briques (Relou, Coriace, Influenceur, Vrai Gentil, Bulle brouillée, Café,
Mode inversé), onomatopées flottantes, secousse d'écran, et la file visible au fond du
couloir. Le but ici est de **juger le ressenti de l'enchaînement** avant d'empiler de la
mécanique dessus. Quand la file se vide, elle se reconstruit : on peut jouer aussi longtemps
qu'il faut pour trancher sur les distances et les durées.

## Les trois instants

C'est le point le plus important du fichier, et la seule chose qu'on peut rater sans que ça
se voie dans le code. Relire la maquette ligne par ligne a montré qu'un coup joué ne se
résume pas à un moment mais à trois, et la maquette les sépare :

| Quand | Ce qui part | Pourquoi |
|---|---|---|
| **à l'appui** | le verdict et le message | la maquette appelle `toast()` dans `act()`, avant le dash. C'est ce qui rend le jeu nerveux |
| **fin du dash (0,14 s)** | l'animation du joueur | la maquette ne pose `P.type = c.gesture` que dans la branche `dash`. Déclencher le geste à l'appui ferait frapper dans le vide |
| **à l'impact (0,25 s)** | l'envol du personnage | la rencontre est finie, la figure part en sortie |

Ces trois instants sont trois signaux de `Encounter` : `answer_judged`,
`player_reaction_requested`, `resolved`.

## Deux objets, pas un

`Encounter` tient les phases d'**un** personnage. `CharacterExit` tient un personnage **qui
s'en va**. Les deux sont séparés parce que dans la maquette, le suivant apparaît *pendant*
que le précédent est encore en l'air : `S.exiting` est une liste tenue en parallèle, et le
spawn est relancé 380 ms après la frappe, pas après l'atterrissage. C'est ce chevauchement
qui donne le rythme ; sans lui le couloir se vide entre deux personnages.

Les deux sont des `RefCounted` avancés par `advance(delta)` depuis le `_process` du
directeur. Aucun des deux n'existe dans l'arbre de scène : un seul nœud a un `_process`,
c'est le chef d'orchestre.

## Le flux de signaux

```
AnswerSwipeArea ─┐  answer_submitted(gesture)
AnswerButtons  ──┴────────→ LevelDirector.submit_answer()   ← filtre
                                   ↓ Encounter.submit_answer()
                            Encounter
                              ├→ answer_judged       → LevelDirector.answer_judged  → FeedbackBanner
                              ├→ player_reaction_…   → LevelDirector.answer_accepted → PlayerAnswerController
                              └→ resolved            → CharacterExit + spawn suivant
```

`AnswerButtons` et `Stickman` n'ont pas été touchés par ce câblage : c'est ce que la doc 03
annonçait. `PlayerAnswerController` écoute maintenant le directeur au lieu des boutons, et
gagne un second cas — le vacillement quand on se fait bousculer.

**Deux styles de branchement, et c'est voulu.** `FeedbackBanner` est relié par une
`[connection]` dans `Level.tscn` : il ne veut rien du directeur qu'un événement, donc il n'a
aucune référence vers lui, et le directeur n'en a aucune vers lui. Les contrôles sont reliés
de la même façon, ce qui a permis de **supprimer** l'export `answer_sources` du directeur :
ajouter une troisième façon de répondre est désormais une connexion dans la scène, et aucune
ligne de code. `PlayerAnswerController`, lui, garde l'injection par `@export`, parce qu'il a
de toute façon besoin d'une référence vers le joueur et qu'il écoute deux signaux.

## Fichiers

### Créés

| Fichier | Rôle |
|---|---|
| `scripts/core/PhraseKind.gd` | enum `{ CLICHE, REAL_INFORMATION }`, symétrique d'`AnswerGesture` |
| `scripts/core/CharacterBrief.gd` | un personnage à venir : phrase, nature, couleur |
| `scripts/core/AnswerOutcome.gd` | verdict d'une rencontre : `{ CORRECT, WRONG, IGNORED }` |
| `scripts/core/CharacterQueue.gd` | la file restante : `pop_next`, `insert_at` |
| `scripts/core/QueueBuilder.gd` | construit la file depuis `LevelConfig` + `PhrasePool` |
| `resources/PhrasePool.gd` | les trois listes de phrases |
| `resources/DailyRule.gd` | l'énoncé et le geste attendu, inversable |
| `resources/LevelConfig.gd` | nom, nombre de personnes, durée de marche, pool, règle |
| `scripts/gameplay/Encounter.gd` | les phases d'un personnage |
| `scripts/gameplay/CharacterExit.gd` | un personnage qui s'en va |
| `scripts/gameplay/CharacterSpawner.gd` | brief → figure dans le couloir |
| `scripts/gameplay/LevelDirector.gd` | le chef d'orchestre |
| `scripts/ui/SpeechBubble.gd` + `scenes/ui/SpeechBubble.tscn` | la bulle projetée |
| `scripts/ui/AnswerSwipeArea.gd` + `scenes/ui/AnswerSwipeArea.tscn` | le swipe et la lueur de bord |
| `scripts/ui/FeedbackBanner.gd` + `scenes/ui/FeedbackBanner.tscn` | le message de verdict |
| `data/phrases/default_phrase_pool.tres` | 14 phrases bateau, 12 vraies infos, 3 cultes |
| `data/rules/standard_rule.tres` | « Claque les phrases bateau. Check les vraies infos. » |
| `data/levels/level_01.tres` | Premier jour : 10 personnes, marche lente (4,2 s) |

`resources/` est un nouveau dossier à la racine du projet Godot, à côté de `scripts/`,
comme prévu par l'arborescence du `.claude/CLAUDE.md`.

### Modifiés

| Fichier | Changement |
|---|---|
| `scenes/characters/Stickman.tscn` | un `BubbleAnchor` (Marker3D) à `(0, 2.4, 0)` sur la **racine** |
| `scripts/characters/Stickman.gd` | `set_body_color()`, et les exports `body`, `body_material`, `bubble_anchor` |
| `scripts/gameplay/PlayerAnswerController.gd` | écoute le directeur ; gère aussi la bousculade |
| `scenes/levels/Level.tscn` | les 3 arrivants figés retirés ; spawner, directeur, bulle, swipe, bandeau, et 3 connexions |

## Valeurs chiffrées et leur origine

Toutes viennent de la maquette. La difficulté est dans `LevelConfig`, la géométrie du
couloir dans les `@export` du spawner, le timing des animations dans les constantes de
`Encounter` et `CharacterExit`.

| Valeur | Maquette | Où elle vit |
|---|---|---|
| Apparition au fond | `Z0 = -12` | `CharacterSpawner.spawn_z` |
| Distance de réponse | `ZS = 1.75` | `CharacterSpawner.answer_z` |
| Axe du couloir | `LANE_X = 0.11` | `CharacterSpawner.lane_x` |
| Durée de marche, niveau 1 | `dur = 4.2` | `LevelConfig.walk_duration_seconds` |
| Dash | 0,14 s | `Encounter.DASH_DURATION` |
| Impact de la claque | 0,25 s | `Encounter.SLAP_IMPACT_DELAY` |
| Départ après un check | 0,45 s | `Encounter.CHECK_RESOLVE_DELAY` |
| Envol | `v = (-5.5, 4.2, -2.5)`, g = 16 | `CharacterExit.FLY_*` |
| Départ content | −1,9 en x, −1,2 en z, demi-tour de 2,3 rad, bonds de 0,22 | `CharacterExit.LEAVE_*` |
| Bousculade | x → −1,1 et z → 8 en 1,1 s | `CharacterExit.SHOVE_*` |
| Durée de vie d'une sortie | 1,4 s | `CharacterExit.LIFETIME` |
| Délai avant le suivant | 380 / 300 / 350 ms | **un seul** `delay_between_characters = 0.35` |

**La conversion des vitesses de marche.** La maquette avance un compteur de phase à
`dt × speed` et lit un `sin()` dessus : sa vitesse 8,5 fait donc un cycle complet en
`2π / 8,5 ≈ 0,74 s`, qui est exactement la longueur du clip `walk` écrit à l'étape 2. La
correspondance est donc directe :

| Situation | Maquette | `speed_scale` |
|---|---|---|
| marche normale | 8,5 | **1,0** |
| dash | 16 | 1,88 |
| départ content | 10 | 1,18 |
| bousculade | 13 | 1,53 |

**Le seuil de swipe.** La maquette déclenche à 50 px et sature sa lueur à 80 px sur un écran
d'environ 390 px. Les deux sont devenus des fractions de la largeur de l'écran — 0,13 et
0,20 — soit ≈ 94 px et 144 px dans le viewport 720 × 1280, et le même geste à la main sur
n'importe quelle taille d'écran.

**Les couleurs des personnages.** La maquette tire `setHSL(hue, 0.45, 0.5)` avec un pas de
hue de 137°. Godot prend du HSV, pas du HSL : `HSL(0.45, 0.5)` vaut `HSV(0.62, 0.725)`,
d'où les deux constantes de `QueueBuilder`. Le pas de 137° reste, il est proche de l'angle
d'or et garantit que deux personnages de suite ne se ressemblent pas.

## Détails qui comptent

**La bulle est en 2D, projetée.** `SpeechBubble` reçoit la `Camera3D` et appelle
`unproject_position()` chaque frame. Le texte reste net à toute distance et le brouillard de
profondeur du couloir ne le mange pas. Son ancre est sur la **racine** du Stickman et non
sous `Body` : le rebond vertical du cycle de marche aurait fait vibrer la bulle. Et comme la
caméra est prise par référence et vit sous `ShakeOffset`, la bulle suivra la secousse le jour
où il y en aura une, sans une ligne de plus.

**L'ordre dans le `CanvasLayer`** est significatif : `AnswerSwipeArea` d'abord, pour que les
boutons restent au-dessus et prennent les clics en premier. La racine d'`AnswerButtons` est
en `mouse_filter = ignore` depuis l'étape 3, donc le reste de l'écran laisse passer le geste.

**Un seul chemin pour le doigt et la souris.** `AnswerSwipeArea` ne lit que des
`InputEventMouse*` : Godot émule la souris depuis le tactile par défaut, donc le même code
sert le doigt sur téléphone et la souris dans l'éditeur. Godot route aussi les mouvements et
le relâchement vers le `Control` qui a reçu l'appui, donc un geste qui finit sur un bouton
reste un geste.

**Le `match _phase` est permis**, contrairement au `match character_kind` que le
`.claude/CLAUDE.md` interdit : les phases d'une rencontre sont un ensemble **fermé**, alors
que les personnages sont ce qui grossit brique par brique. Même raisonnement pour le `match`
sur la nature d'une phrase dans `PhrasePool`.

**`WALK` est réentrant.** `Encounter.start_walk(from_z, duration)` est écrit pour pouvoir
être rappelé, parce que le Recruteur coriace fait reculer un personnage et le renvoie sur une
marche plus courte. C'est la seule anticipation du fichier, et elle coûte un paramètre.

**La trajectoire n'est pas dans le clip.** `knocked_away` ne porte que la pose et la culbute
du `Body`, comme annoncé à l'étape 2. La parabole est dans `CharacterExit`, qui ne touche
qu'à la racine — ce qui évite au passage une double rotation.

**`set_body_color()` reconnaît les maillages du corps par leur matériau**, pas par leur nom
ni par une liste codée en dur. Le matériau partagé est dupliqué, jamais écrit : la couleur
d'un personnage ne peut pas fuir sur les autres. Les yeux portent un autre matériau, ils sont
donc épargnés tout seuls, et une casquette ajoutée plus tard le sera aussi — ou pas, selon le
matériau qu'on lui donne.

## Écarts assumés par rapport à la maquette

- **Un seul délai entre deux personnages** (0,35 s) au lieu de trois (380 / 300 / 350 ms).
  L'écart est sous le seuil perceptible et la valeur est exposée.
- **La main du personnage checké ne reste pas levée** pendant qu'il s'éloigne. La maquette
  force `armP.rotation.x` dans sa phase `leave` ; ici le clip `check` est interrompu par le
  cycle de marche au bout de 0,45 s. À reprendre dans la passe de « jus », avec les
  onomatopées et la secousse.
- **Pas de file visible au fond du couloir.** La maquette montre trois personnages qui
  attendent et avancent d'un cran. C'est de la lisibilité, pas de la boucle : à ajouter dans
  sa propre classe, sans toucher à celles-ci.

## Vérification dans l'éditeur

Rien n'est lancé de mon côté.

1. **F5.** Un personnage apparaît au fond du couloir, marche vers le joueur, une bulle au
   dessus de sa tête. Elle doit rester accrochée **sans vibrer** pendant la marche : c'est ce
   que teste l'ancre posée sur la racine et pas sous `Body`.
2. **Claquer** (bouton, flèche gauche, ou swipe vers la gauche) : le personnage accélère
   brièvement, le joueur arme et balaye, le personnage s'envole vers la gauche. Le message
   « Claque méritée » doit partir **dès l'appui**, pas à l'impact.
3. **Checker** : les deux lèvent la main droite, puis le personnage se retourne et s'éloigne
   en sautillant.
4. **Ne rien faire** : le personnage arrive, le joueur vacille, le personnage part sur le
   côté et passe derrière la caméra. Message « Il t'a bousculé et il est passé ».
5. **Se tromper** : le message dit ce qu'il fallait faire.
6. **Marteler les contrôles** pendant un envol : rien ne doit se déclencher.
7. **Le chevauchement** : le suivant doit apparaître au fond *pendant* que le précédent est
   encore en l'air. Si l'écran se vide entre deux personnages, `delay_between_characters` est
   trop grand.
8. **Laisser tourner deux files** (20 personnages) : la file se reconstruit, et le compteur
   d'objets du moniteur de débogage ne doit pas monter — les figures sorties sont libérées au
   bout de 1,4 s.
9. **Swiper puis revenir** sans lâcher : la lueur de bord doit s'allumer puis s'éteindre, et
   aucune réponse ne doit partir.

Points à juger, qui conditionnent l'étape 05 :

- **A-t-on le temps de lire ?** 4,2 s sur 13,75 m. C'est la question ouverte n° 1 du game
  design et le levier est `walk_duration_seconds` dans `level_01.tres`.
- La bulle au fond du couloir est-elle **rognée à droite** ? La doc 02 avait mesuré la tête
  de file à +0,80 sur un axe qui va de −1 à +1 : c'est maintenant que ça se voit.
- Le seuil de swipe à 13 % de la largeur : trop sensible, ou trop exigeant ?
- Le délai de 0,35 s entre deux personnages : assez de répit, ou trop de temps mort ?

## Hors périmètre, à signaler

L'exécutable du moteur (146 Mo) est toujours `untracked` à la racine du dépôt, et le
`.gitignore` ajouté est **à l'intérieur** de `slap-or-check/`, donc il ne le couvre pas. Un
`git add -A` sur cette branche le ferait entrer dans l'historique. Signalé depuis l'étape 01.
