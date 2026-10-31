# Les deux premières briques — Le Relou et Le Coriace

> **Étape 8** · branche `SlapOrChack-GameLoop` · décidé le 2026-10-31, implémenté.

## Contexte

C'est la première extension par brique, donc le moment où l'architecture est mise à
l'épreuve. Le `.claude/CLAUDE.md` est catégorique : une brique s'ajoute « **sans modifier** le
code existant : une nouvelle `Resource` de configuration et/ou une nouvelle implémentation
d'interface, **jamais un `match` de plus** dans une fonction centrale ».

Deux choses posées plus tôt ont payé exactement comme prévu :

- `CharacterQueue.insert_at()`, écrite à l'étape 04 et inutilisée depuis, **pour le Relou** ;
- `HatAnchor` et `ChestAnchor` sur le Stickman, posés à l'étape 02 « pour que l'étape briques
  n'ait pas à rouvrir ce fichier » — et elle ne l'a pas rouvert pour les placer.

## Les deux briques ne demandent pas le même genre d'extension

C'est le point central, et il n'était pas évident avant de les regarder de près.

### Le Coriace est une **donnée**

« Il encaisse : il faut 2 bonnes réactions » se généralise en un nombre : *combien de bonnes
réponses ce personnage absorbe avant de tomber*. Ce nombre couvre aussi le boss « Le Gourou »
du game design (« chaque bonne réponse lui retire un point de vie »), qui est le même mécanisme
en plus grand.

Donc **zéro branche, zéro sous-classe** : un `.tres` de `CharacterKind` avec
`resilience = 1`, `walk_duration_factor = 1.3`, `figure_scale = 1.18` et une cravate.
`Encounter` lit un entier porté par le personnage et ne sait pas qu'un « Coriace » existe.

### Le Relou est un **comportement**

« Il se remet dans la file » ne se généralise pas en donnée, parce que l'Influenceur fera une
mutation différente de la même file (ajouter deux abonnés). Un drapeau par brique
s'accumulerait jusqu'à redevenir le `match` interdit.

Donc **une méthode virtuelle** :

```gdscript
## Lets this kind change what is still to come, as a consequence of an answer.
func react_in_queue(_outcome: AnswerOutcome, _queue: CharacterQueue) -> void:
	pass
```

`ReluctantCharacterKind` la surcharge, `LevelDirector` l'appelle **sans condition** pour tout
le monde. L'Influenceur sera un troisième fichier et pas une ligne de plus ailleurs.

## Le personnage ordinaire est un objet, pas un `null`

`data/characters/base_character.tres` est une instance de `CharacterKind` qui ne fait rien :
pas d'accessoire, échelle 1, résilience 0, et un `react_in_queue` vide.

C'est délibéré. Avec un `null`, chaque point d'extension aurait demandé un
`if kind != null` — quatre tests répartis dans le spawner, le directeur, la bulle et
l'encounter. Avec un objet neutre, il n'en reste **aucun**. C'est le seul endroit où le patron
« objet nul » valait la peine, et il la valait quatre fois.

Conséquence : `LevelConfig` désigne son `base_character_kind`, comme il désigne déjà son pool
de phrases et son équilibrage.

## Un quatrième verdict

Encaisser un coup n'est ni une bonne réponse ni une erreur : le geste était juste, mais la
rencontre n'est pas finie. D'où `AnswerOutcome.Verdict.ABSORBED`, à côté de CORRECT, WRONG et
IGNORED.

| Ce qu'il fait | Ce qu'il ne fait pas |
|---|---|
| rapporte `absorbed_answer_reward` (+2) | ne rapporte pas les +5 d'une bonne réponse |
| laisse la série **intacte** | ne l'allonge pas, ne la casse pas |
| fait reculer puis revenir le personnage | ne le fait pas sortir du couloir |
| affiche un message neutre | n'affiche ni vert ni rouge |

Les quatre `match` qui gagnent un cas (`MoralBalance.change_for`, `AnswerStreak.record`,
`FeedbackBanner`, `Encounter`) portent tous sur un ensemble **fermé de verdicts**, pas sur les
personnages. C'est la distinction que l'étape 07 avait établie : les verdicts ne grossissent
pas brique par brique, les personnages si.

## La phase STAGGERING

`Encounter` gagne une quatrième phase. Après un coup encaissé, le personnage recule de 2,4 m
en 0,35 s, puis **repart** sur une marche à 0,55 × la première.

Deux détails qui comptent :

- **Chaque retour est mesuré depuis la *première* marche**, pas depuis la précédente. Sans ça,
  deux coups encaissés composeraient 0,55 × 0,55 = 0,30, soit 1,3 s pour lire — illisible. La
  phase `WALK` était déjà réentrante depuis l'étape 04, écrite pour ce cas précis ; il a
  seulement fallu séparer `start_walk()` (public, premier départ) de `_walk_from()` (privé,
  réutilisable).
- **`_has_reacted` est remis à zéro** à chaque départ, sinon la réaction du deuxième coup ne
  serait jamais jouée.

Et la claque encaissée joue `stagger`, pas `knocked_away` : le clip du vacillement amorti, pas
celui de la culbute, puisqu'il va revenir. Les six clips de l'étape 02 suffisent, aucun à
ajouter.

## La bulle annonce la brique

Le game design l'exige : « chaque personnage spécial est reconnaissable visuellement **et
annoncé dans sa bulle** ». Sans ça, la première rencontre avec une casquette rouge impose une
règle que le joueur ne peut pas deviner.

`SpeechBubble` gagne une ligne au-dessus de la phrase, masquée quand le nom est vide — donc
invisible pour les personnages ordinaires, sans laisser de trou.

## Les accessoires

Deux scènes posées sur les ancres existantes, instanciées par `Stickman.attach_accessory()`.

| Accessoire | Ancre | Géométrie (de la maquette) |
|---|---|---|
| `RedCap.tscn` | `Body/Head/HatAnchor` | demi-sphère r 0,26 + visière 0,3 × 0,03 × 0,22 |
| `Tie.tscn` | `Body/ChestAnchor` | boîte 0,09 × 0,38 × 0,03 |

**La visière pointe vers −Z**, pas +Z comme dans la maquette : notre figure regarde vers −Z
(règle de l'étape 02). C'est le genre de signe qui ne se vérifie qu'à l'image.

Les ancres sont **sous `Body`**, contrairement à l'ancre de bulle : un accessoire fait partie
de la figure et doit suivre son animation, alors que la bulle ne doit pas vibrer.

`AccessorySlot` est un enum à part — même patron qu'`AnswerGesture` et `PhraseKind` — pour
qu'une brique nomme un endroit du corps sans dépendre de la figure.

## La friction refermée au passage

`level_01.tres` était désigné **deux fois** dans `Level.tscn`, par `LevelDirector` et par
`MoralController`. Avec un deuxième fichier de niveau, oublier l'un des deux aurait fait jouer
une file avec l'équilibrage d'un autre niveau. `MoralController` prend désormais le directeur
et y lit le niveau : **une seule désignation dans la scène**.

Signalé à l'étape 07 comme « à traiter avant le deuxième fichier de niveau » — c'est fait.

## Fichiers

### Créés

| Fichier | Rôle |
|---|---|
| `scripts/core/AccessorySlot.gd` | enum des trois endroits du corps |
| `resources/CharacterKind.gd` | le personnage ordinaire, et la base des briques |
| `resources/ReluctantCharacterKind.gd` | Le Relou : surcharge `react_in_queue` |
| `data/characters/base_character.tres` | l'objet neutre |
| `data/characters/reluctant_character.tres` | Le Relou, rang de retour 2 |
| `data/characters/tough_recruiter.tres` | Le Coriace : résilience 1, marche ×1,3, taille ×1,18 |
| `scenes/characters/accessories/RedCap.tscn` · `Tie.tscn` | les deux accessoires |
| `assets/materials/red_cap.tres` · `tie.tres` | leurs matériaux |
| `data/levels/level_lab.tres` | 12 personnes, allure moyenne, 2 Relous + 2 Coriaces |

### Modifiés

| Fichier | Changement |
|---|---|
| `scripts/core/CharacterBrief.gd` | porte son `character_kind` et sa `remaining_resilience` ; gagne `copy()` |
| `scripts/core/AnswerOutcome.gd` | verdict `ABSORBED` et sa fabrique |
| `scripts/core/AnswerStreak.gd` | un coup encaissé ne touche pas la série |
| `scripts/core/QueueBuilder.gd` | place les briques sur des rangs tirés au hasard, jamais les premiers |
| `scripts/gameplay/Encounter.gd` | phase `STAGGERING`, jugement de l'encaissement, retour |
| `scripts/gameplay/CharacterSpawner.gd` | habille la figure selon son type |
| `scripts/gameplay/LevelDirector.gd` | laisse le type réagir sur la file ; applique son facteur de marche |
| `scripts/gameplay/MoralController.gd` | lit le niveau chez le directeur |
| `scripts/characters/Stickman.gd` | `set_figure_scale()`, `attach_accessory()`, trois ancres exportées |
| `scripts/ui/SpeechBubble.gd` + `.tscn` | la ligne qui nomme la brique |
| `scripts/ui/FeedbackBanner.gd` | les deux messages d'encaissement, couleur neutre |
| `resources/MoralBalance.gd` | `absorbed_answer_reward` |
| `resources/LevelConfig.gd` | `bricks` et `base_character_kind` |
| `scenes/characters/Stickman.tscn` | les trois ancres déclarées en `node_paths` |
| `data/levels/level_01.tres` | désigne le type ordinaire, sans brique |
| `scenes/levels/Level.tscn` | joue `level_lab.tres`, désigné **une seule fois** |

## Deux risques à vérifier en premier

Je ne lance pas le moteur, et ces deux-là échouent silencieusement.

### 1. Le tableau de briques dans le `.tres`

`level_lab.tres` porte :

```
bricks = Array[CharacterKind]([ExtResource("6_reluctant"), …])
```

C'est la forme attendue pour un `Array` typé d'une classe de script, mais je ne peux pas la
confirmer sans l'éditeur. **Si elle ne passe pas, la liste chargera vide et aucune brique
n'apparaîtra** — sans message d'erreur. À vérifier dans l'inspecteur : le champ `Bricks` doit
montrer 4 entrées. Sinon, les ajouter à la main (deux fois Le Relou, deux fois Le Coriace)
suffit, et vaut confirmation que le chemin inspecteur fonctionne.

### 2. Les trois `.tres` de type de personnage, au premier import

Exactement le piège rencontré avec `default_phrase_pool.tres` : un `.tres` écrit **avant** que
Godot ait enregistré sa classe de script peut charger sans ses propriétés, et se faire
réenregistrer vide.

À ouvrir une fois dans l'inspecteur après le premier import :

| Fichier | Valeurs attendues |
|---|---|
| `reluctant_character.tres` | « Le Relou », casquette, rang de retour 2 |
| `tough_recruiter.tres` | « Recruteur coriace », résilience 1, marche 1,3, taille 1,18, cravate |
| `base_character.tres` | tout à sa valeur par défaut (c'est normal qu'il paraisse vide) |

### 3. Et une référence croisée

`CharacterBrief` connaît `CharacterKind`, qui connaît `AnswerOutcome`, qui connaît
`CharacterBrief`. Godot 4 résout ce genre de cycle quand il ne porte que sur des annotations de
type, ce qui est le cas ici — aucune constante, aucune héritance croisée. Mais si la sortie se
plaint de « Cyclic reference », le correctif est d'une ligne : annoter
`CharacterBrief.character_kind` en `Resource`.

## Vérification dans l'éditeur

1. **F5.** Douze personnages, allure moyenne. Sur douze, quatre doivent être spéciaux :
   deux casquettes rouges et deux grands à cravate. Jamais sur les deux premiers.
2. **Le Coriace** doit être visiblement **plus grand** (×1,18) et marcher **plus lentement**
   (×1,3), avec « Recruteur coriace » au-dessus de sa phrase.
3. **Lui donner la bonne réponse** : il vacille, recule de 2,4 m, et **revient** — plus vite
   qu'à l'aller. Le bandeau dit « Il encaisse. Encore une ! », en gris et non en vert. La jauge
   monte de 2 seulement.
4. **La série ne doit pas bouger** sur ce coup-là : enchaîner quatre bonnes réponses dont un
   encaissement ne doit pas déclencher le bonus de cinq.
5. **Lui redonner la bonne réponse** : il s'envole normalement, +5, et la série avance.
6. **Se tromper sur un Coriace** : −22 et il part, sans deuxième chance. Encaisser ne protège
   que les bonnes réponses.
7. **Laisser passer un Relou** : −14, il bouscule, **et « Reste N » augmente de 1**. Il doit
   réapparaître deux personnages plus tard, avec la même phrase.
8. **Le claquer ou le checker** : il part comme tout le monde, sans revenir.
9. **La visière de la casquette** doit pointer vers le joueur, pas vers l'arrière du couloir.
10. **Laisser tourner une partie entière** : pas de fuite de nœuds, et la victoire tombe bien
    quand la file — Relous revenus compris — est vide.

## Hors périmètre

L'Influenceur, Le Vrai Gentil et le Bonus café. Le premier surchargera `react_in_queue` comme
le Relou ; le deuxième est une donnée de plus comme le Coriace ; le troisième n'est pas un
personnage et demandera son propre point d'extension.

Les quatre niveaux du tableau de progression : seul `level_lab.tres` porte des briques, et
`level_01.tres` reste sans. Les étoiles et leur barème.

Le cadrage de la caméra retouché à la main n'est toujours pas recomposé selon la convention de
la doc 02. L'exécutable du moteur (146 Mo) est toujours `untracked` à la racine.
