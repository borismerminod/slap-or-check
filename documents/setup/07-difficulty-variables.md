# Les variables de difficulté et les constantes du jeu

> **Étape 7** · branche `SlapOrChack-GameLoop` · décidé le 2026-10-31, implémenté.

## Contexte

Le jeu comptait **51 constantes et 47 exports**, répartis à vue : certains nombres en `const`
privée, d'autres en `@export` sur un nœud, d'autres dans un `.tres`. Le classement n'avait
jamais été énoncé — il avait été deviné fichier par fichier.

C'était le dernier moment où c'était gratuit. Les briques apportent chacune trois à six
réglages de plus ; sans règle écrite, ils se seraient posés là où c'était pratique.

**La livraison de cette étape est donc d'abord ce document.** Le code qui suit n'est que ce que
le classement imposait de corriger.

## Trois fonctionnalités abandonnées

Décidé en cours d'étape, et c'est ce qui l'a le plus simplifiée :

| Abandonné | Conséquence |
|---|---|
| **La carte « Règle du jour »** | le joueur découvre la règle en jouant |
| **Le mode inversé** (niveau bonus) | la règle ne varie plus jamais |
| **La bulle brouillée** | jugée trop punitive |

Donc `DailyRule` a disparu. Et comme la correspondance « bateau → claque, vraie info → check »
n'a plus aucune raison de varier, **elle est remontée du niveau 3 au niveau 1** du classement :
d'une ressource réglable, elle est redevenue une constante du jeu.

`documents/claque-ou-check.md` a été mis à jour : section « Règle du jour » retirée (les
sections suivantes renumérotées), les deux modificateurs abandonnés sortis du tableau 6.2, et
le niveau bonus sorti du tableau de progression.

## L'anomalie révélée par l'inventaire

Le drain est global (0,8/s) mais les récompenses sont par personnage (+5) :

| Niveau | Durée | Drain | Gain au sans-faute | Net |
|---|---|---|---|---|
| 1 (10 pers., 4,2 s) | ≈ 45 s | −36 | +66 | **+30** |
| 11 (20 pers., 2,4 s) | ≈ 55 s | −44 | +132 | **+88** |

Plus un niveau monte dans le tableau de progression, **plus sa jauge est généreuse**.

**Décision : on assume.** La difficulté reste le temps de lecture ; la jauge n'est qu'une
condition d'échec, et le filet plus large compense qu'on se trompe davantage quand on a moins
de temps. Aucun code — mais c'est désormais un choix, plus un accident.

---

# Le classement

## Niveau 1 — Constantes du jeu

**Identiques à tous les niveaux, à tous les décors, pour toujours.** La claque doit se sentir
exactement pareil au niveau 1 et au niveau 20 : c'est la signature du jeu, et un niveau qui la
changerait tricherait.

### En dur dans la classe qui s'en sert, jamais exposé

| Où | Quoi |
|---|---|
| `AnswerRule` | **bateau → claque, vraie info → check** |
| `Encounter` | dash 0,14 s · impact de la claque 0,25 s · check 0 / 0,45 s · vitesses de clip 1,0 et 1,88 |
| `CharacterExit` | les 13 valeurs d'envol, de départ content et de bousculade |
| `MoralGauge` | `MAX_VALUE = 100` — l'échelle de tous les chiffres du jeu |
| `Stickman` | les six noms de clips |
| `QueueBuilder` | pas de teinte 137° · saturation 0,62 · valeur 0,725 · `CLICHE_PROBABILITY` 0,5 · une phrase culte par file de 10+, jamais avant le rang 3 |
| `FeedbackBanner`, `LevelOutcomeBanner`, `MoralHud` | les libellés et les deux couleurs du jeu |

### Exposés pour qu'on puisse les régler en jouant, mais jamais par niveau

| Où | Quoi | Pourquoi pas par niveau |
|---|---|---|
| `LevelDirector.delay_between_characters` | 0,35 s | un seul levier de temps par niveau, sinon deux nombres à bouger ensemble |
| `LevelEndController.restart_delay_seconds` | 3,0 s | confort de relance, pas de défi |
| `AnswerSwipeArea.trigger_ratio` / `full_glow_ratio` | 0,13 / 0,20 | un niveau qui durcirait le swipe serait injuste |
| `CharacterSpawner.character_scene` | la scène du stickman | identité |

> **Règle** : promouvoir une de ces valeurs en champ de `LevelConfig` est une régression, pas
> une fonctionnalité.

## Niveau 2 — Géométrie du décor

**Par décor, pas par niveau.** Le game design prévoit trois décors (open space, salon de
l'emploi, visio). Un décor est une scène, avec ses propres nombres.

| Où | Quoi |
|---|---|
| `CharacterSpawner` | `spawn_z = -12` · `answer_z = 1.75` · `lane_x = 0.11` |
| `Level.tscn` | la transform du rig de caméra, le couloir lui-même |

Ils restent des `@export` sur des nœuds **de la scène de niveau**, où ils étaient déjà. Ils ne
doivent pas descendre dans `LevelConfig` : un `LevelConfig` décrit un **défi**, une scène
décrit un **décor**.

**Conséquence qui justifie le choix de l'allure en durée** : allonger le couloir d'un décor
change la vitesse de marche mais **pas le temps de lecture**. Le défi reste comparable d'un
décor à l'autre, ce qui est exactement la propriété qu'on veut.

## Niveau 3 — Équilibrage global

**Une seule source pour tout le jeu.** Régler le jeu = éditer un de ces fichiers. Jamais un
niveau, jamais un script.

| Ressource | Contenu | Fichiers |
|---|---|---|
| `MoralBalance` | départ 70 · drain 0,8 · +5 · −22 · −14 · série 5 / +8 · seuil bas 30 | 1 partagé |
| `WalkPace` | un libellé et une durée, par palier | 3 : lente 4,2 · moyenne 3,4 · rapide 2,4 |
| `PhrasePool` | les trois listes de phrases | 1 partagé, un par décor plus tard |

**Les valeurs de comportement d'une brique appartiennent ici, pas au niveau.** Le Relou se
comporte pareil partout ; seule sa *présence* et son *nombre* varient. Le game design le dit :
« une brique est introduite seule sur un niveau, puis combinée aux autres » — c'est le contexte
qui change, pas la brique. Donc une `Resource` partagée par brique, qui portera :

| Brique | Ses valeurs (relevées dans la maquette) |
|---|---|
| Le Relou | rang de réinsertion 2 |
| Le Coriace | 2 encaissements · taille ×1,18 · marche ×1,3 · retour ×0,55 · +2 de Moral |
| L'Influenceur | 2 abonnés ajoutés |
| Le Vrai Gentil | +20 de Moral · marche ×1,35 |
| Bonus café | ralentissement ×0,55 · 5 s · réapparition 10–16 s · visible 3 s |

Deux d'entre elles **multiplient la durée de marche** : la brique lira le `WalkPace` du niveau
et appliquera son facteur. C'est pour ça que l'allure doit rester un nombre lisible, et pas
seulement un palier nommé.

## Niveau 4 — Difficulté du niveau

**Exactement les trois leviers du game design**, et rien d'autre.

| Champ de `LevelConfig` | Valeurs du tableau de progression |
|---|---|
| `character_count` | 10 · 14 · 16 · 20 |
| `walk_pace` → `WalkPace` | lente · moyenne · moyenne · rapide |
| `bricks` *(à venir)* | quelles briques, et combien de chacune |

Plus les désignations : `display_name`, `phrase_pool`, `moral_balance`.

**Ce qui n'est pas un levier de difficulté, et pourquoi** : le drain (décision ci-dessus), le
délai entre personnages (niveau 1), et la proportion bateau / vraie info — un tirage biaisé
deviendrait devinable, ce qui ruine le fait de *lire*, donc elle reste à 50 / 50 et est
devenue une constante nommée.

---

# Ce que le classement a imposé de corriger

## 1. La règle est devenue une constante

`resources/DailyRule.gd` et `data/rules/standard_rule.tres` supprimés. À leur place,
`scripts/core/AnswerRule.gd` : une table constante, même forme que le `REACTION_BY_GESTURE` de
`PlayerAnswerController`.

`Encounter` n'a pas été touché : il recevait déjà le geste attendu comme **valeur**, justement
pour ne pas connaître la règle. C'est ce découplage, écrit à l'étape 04, qui a rendu la
suppression indolore — seul `LevelDirector` a changé, sur une ligne.

## 2. L'allure est devenue une ressource partagée

`LevelConfig.walk_duration_seconds` était un nombre libre par niveau : onze niveaux, onze
nombres qui dérivent. Remplacé par `walk_pace: WalkPace`, un palier désigné.

Retoucher « rapide » corrige d'un coup tous les niveaux concernés, et les trois paliers restent
cohérents entre eux. Le `display_name` sert à l'écran de choix de niveau prévu au game design
(« 20 personnes · marche rapide ») et à la lisibilité de l'inspecteur.

**Perte assumée** : la maquette utilisait 3,0 pour le niveau 8, étiqueté « moyenne ». Avec
trois paliers il passera à 3,4. Si cette granularité manque, un quatrième palier est un fichier.

## 3. Le seuil de 30 est remonté dans l'équilibrage

`MoralHud.low_moral_threshold = 30` était un nombre d'**équilibrage** posé dans la couche
présentation. Et c'était un doublon qui s'ignorait : le game design donne « 2 étoiles à partir
de 30 », donc le seuil d'alerte et le barème des étoiles sont le même nombre — ils auraient
dérivé dès que les étoiles existeraient.

Il est remonté dans `MoralBalance`. Mais le HUD ne reçoit pas la ressource pour autant, ce qui
aurait rebranché l'équilibrage une troisième fois — exactement le défaut corrigé à l'étape 05.
C'est `MoralController`, qui détient déjà la balance et la valeur, qui tranche :

- `signal low_moral_changed(is_low: bool)`, émis **au franchissement** seulement ;
- `MoralHud` a perdu son seuil et son état interne, et gagné `show_low_moral(is_low)` qui ne
  fait qu'échanger le style de remplissage.

Le HUD ne détient plus aucune règle du jeu : on lui dit d'alerter, il alerte.

## 4. Le tirage à pile ou face a reçu un nom

`randf() < 0.5` dans `QueueBuilder._draw_brief()` était le seul vrai nombre magique restant
dans un corps de fonction, et le `.claude/CLAUDE.md` les interdit. Devenu
`CLICHE_PROBABILITY`, avec la raison de le laisser à la moitié en commentaire.

Les autres nombres nus relevés à l'inventaire — `minf(1.0, …)`, `progress >= 1.0`, la formule
d'interpolation d'`Encounter` — sont des bornes de progression normalisée, idiomatiques, et
restent.

---

## Fichiers

### Créés

| Fichier | Rôle |
|---|---|
| `scripts/core/AnswerRule.gd` | la règle du jeu, désormais constante |
| `resources/WalkPace.gd` | un palier d'allure : son libellé et sa durée |
| `data/paces/slow_pace.tres` · `medium_pace.tres` · `fast_pace.tres` | lente 4,2 · moyenne 3,4 · rapide 2,4 |

### Supprimés

| Fichier | Pourquoi |
|---|---|
| `resources/DailyRule.gd` | la règle ne varie plus |
| `data/rules/standard_rule.tres` | son unique instance, et son énoncé n'avait plus de carte à remplir |

### Modifiés

| Fichier | Changement |
|---|---|
| `resources/LevelConfig.gd` | `walk_duration_seconds` → `walk_pace` ; `daily_rule` retiré |
| `data/levels/level_01.tres` | désigne `slow_pace.tres`, perd sa règle |
| `scripts/gameplay/LevelDirector.gd` | lit `AnswerRule` et `config.walk_pace.duration_seconds` |
| `resources/MoralBalance.gd` | gagne `low_moral_threshold` |
| `scripts/gameplay/MoralController.gd` | `low_moral_changed(is_low)`, émis au franchissement |
| `scripts/ui/MoralHud.gd` | perd le seuil et son état, gagne `show_low_moral(is_low)` |
| `scenes/ui/MoralHud.tscn` | la propriété de seuil retirée du nœud |
| `scripts/core/QueueBuilder.gd` | `CLICHE_PROBABILITY` nommée |
| `scenes/levels/Level.tscn` | une connexion de plus : `low_moral_changed` → `show_low_moral` |
| `documents/claque-ou-check.md` | les trois fonctionnalités abandonnées retirées, sections renumérotées |
| `documents/setup/05-moral-gauge.md` | note le départ du seuil vers l'équilibrage |

`level_01.tres` reste le seul niveau : les autres lignes du tableau de progression arriveront
avec leurs briques, chacune au moment où elle a un sens.

## Point ouvert, signalé et non traité

**Les textes affichés au joueur sont dans le code.** « Claque méritée », « Gagné !!! »,
« Reste », « Essayer encore !!! » sont des `const` de leurs classes. Or le `.claude/CLAUDE.md`
énonce que ce qui est affiché au joueur « vit dans des fichiers de données, pas dans le code ».

La règle visait les phrases des recruteurs, qui sont bien dans un `.tres`. Pour les libellés
d'interface, les sortir aujourd'hui coûterait une ressource de plus sans rien apporter. Le jour
où la localisation arrive, le chemin idiomatique est `tr()` et un CSV de traduction, pas une
ressource maison — donc autant attendre ce moment et tout sortir d'un coup, plutôt que de
construire un intermédiaire à jeter.

Et dans `documents/claque-ou-check.md`, la brique prévue **« Double règle »** reposait sur
l'existence d'une règle variable. Elle est laissée dans le document, marquée d'un avertissement
plutôt que supprimée : c'est une décision de design, pas de code.

## Vérification dans l'éditeur

Le moteur n'est pas lancé de mon côté. Le classement se vérifie à la lecture ; les quatre
corrections se testent.

1. **F5**, et rien ne doit avoir changé à l'œil : marche à 4,2 s, barre à 70, alerte rouge sous
   30. C'est le but — ce sont des déplacements, pas des réglages.
2. **Claquer une phrase bateau, checker une vraie info** : toujours les bonnes réponses. C'est
   le seul test de la suppression de `DailyRule`.
3. **Ouvrir `level_01.tres`** : plus de champ de règle, et le champ d'allure montre une
   ressource. Un clic dessus ouvre `slow_pace.tres` avec « lente » et 4,2.
4. **Désigner `medium_pace.tres` dans `level_01.tres`** : les personnages marchent plus vite
   sans qu'aucun script ne bouge.
5. **Mettre `low_moral_threshold` à 60 dans l'équilibrage** : la barre rougit beaucoup plus
   tôt. C'est ce qui prouve que le seuil est lu depuis la ressource et non resté dans le HUD.
6. **Passer sous le seuil puis remonter au-dessus** : la barre rougit, puis reverdit. Une seule
   fois dans chaque sens.
7. **Jouer deux files complètes** : la proportion de phrases bateau reste autour de la moitié.

## Hors périmètre

Les briques elles-mêmes et leurs ressources, les autres niveaux du tableau de progression, les
étoiles et leur barème.

Le cadrage de la caméra retouché à la main (rig à `x = 1.09`, lacet de −1,2°) n'est toujours pas
recomposé selon la convention de la doc 02. L'exécutable du moteur (146 Mo) est toujours
`untracked` à la racine, hors de portée du `.gitignore` interne à `slap-or-check/`.
