# Victoire, défaite et redémarrage

> **Étape 6** · branche `SlapOrChack-GameLoop` · décidé le 2026-10-27, implémenté.

## Contexte

L'étape 05 a donné la jauge de Moral, mais la partie **ne se termine jamais**.

- À zéro, le niveau se figeait sur un « Moral à zéro » définitif, sans suite.
- La victoire n'existait pas du tout : le drapeau `restarts_when_empty` de
  `LevelDirector` reconstruisait la file à l'infini. C'était un bouche-trou posé à l'étape 04
  en attendant précisément cette étape.

Il faut donc trois choses : un arbitre qui décide « victoire ou défaite », un affichage en
deux lignes, et un minuteur qui relance la partie.

Le terrain est prêt : `LevelDirector` émet déjà la fin de file et possède `stop()`,
`MoralController` émet déjà `depleted`.

## Ce qui est demandé

| Cas | Condition | Gros titre | Deuxième ligne |
|---|---|---|---|
| **Victoire** | toute la file traitée avec du Moral restant | « Gagné !!! » | aucune |
| **Défaite** | Moral à zéro | « Essayer encore !!! » | « Moral à zéro » |

Dans les deux cas, un minuteur de **3 secondes** puis redémarrage de la partie.

La victoire **attend que le dernier personnage ait quitté le cadre**, comme le
`finishWhenClear` de la maquette, plutôt que de tomber par-dessus quelqu'un encore en l'air.

## Un affichage séparé du bandeau de réponse

L'écran de fin ne va **pas** dans `FeedbackBanner`. Celui-ci écrit des messages transitoires
sur une réponse et les retire au bout de 1,2 s ; l'écran de fin reste jusqu'au redémarrage.
Deux durées de vie, donc deux responsabilités.

`LevelOutcomeBanner` reprend donc le « Moral à zéro », et `FeedbackBanner.show_defeat()`
disparaît. C'est aussi l'endroit où viendront se greffer les étoiles, les statistiques et le
rappel des erreurs.

## Un seul arbitre

`LevelEndController` est le seul endroit qui sait que le niveau est terminé. Son travail
s'énonce sans « et » : **terminer le niveau** — arrêter ce qui tourne, dire comment ça s'est
fini, relancer plus tard.

```
LevelDirector.queue_cleared ──→ LevelEndController.report_victory()
MoralController.depleted ─────→ LevelEndController.report_defeat()
                                      ↓
                              LevelEndController
                                ├→ level_director.stop()      (injecté par @export)
                                ├→ moral_controller.stop()    (injecté par @export)
                                ├→ level_ended(outcome)  → LevelOutcomeBanner.show_outcome()
                                └→ restart_timer (3 s)   → reload_current_scene()
```

Deux connexions de l'étape 05 **disparaissent** : `depleted → LevelDirector.stop` et
`depleted → FeedbackBanner.show_defeat`. L'arbitre les reprend, pour que la défaite et la
victoire suivent exactement le même chemin.

Un drapeau `_is_ended` garde contre une double fin : le Moral peut s'épuiser sur la frame
même où la file se vide, et le premier arrivé gagne.

## Le défaut corrigé au passage

**`MoralController` ne s'arrête aujourd'hui que sur `depleted`.** Sur une victoire il
continuerait de drainer : 3 secondes de bandeau, soit 2,4 points qui descendent sous un
« Gagné !!! », et dans un cas limite la barre atteindrait zéro pendant l'écran de victoire.

Il gagne donc un `stop()` public, appelé par l'arbitre dans les deux cas. `_on_depleted()`
l'appelle aussi, au lieu de faire son `set_process(false)` lui-même.

## Fichiers

### Créés

| Fichier | Rôle |
|---|---|
| `scripts/core/LevelOutcome.gd` | enum `{ VICTORY, DEFEAT }`, comme `AnswerGesture` et `PhraseKind` |
| `scripts/gameplay/LevelEndController.gd` | l'arbitre : arrête, annonce, relance |
| `scripts/ui/LevelOutcomeBanner.gd` | les deux lignes et leur contenu |
| `scenes/ui/LevelOutcomeBanner.tscn` | le titre et la ligne de détail, centrés |

### Modifiés

| Fichier | Changement |
|---|---|
| `scripts/gameplay/LevelDirector.gd` | `restarts_when_empty` **retiré** ; `queue_emptied` renommé `queue_cleared` et émis une fois le couloir vide |
| `scripts/gameplay/MoralController.gd` | `stop()` public, appelé aussi par `_on_depleted()` |
| `scripts/ui/FeedbackBanner.gd` | `show_defeat()` et `DEFEAT_MESSAGE` **retirés** |
| `scenes/levels/Level.tscn` | `LevelEndController` + son `Timer`, `LevelOutcomeBanner`, connexions refaites |

## Le renommage de `queue_emptied`

Le signal ne veut plus dire la même chose : il part quand le **couloir est vide**, pas quand
la liste d'attente s'est vidée. `queue_cleared` dit ça, et garder l'ancien nom mentirait sur
le moment où il part.

Mécanique, dans `LevelDirector` :

- `_on_queue_cleared()` lève `_is_waiting_for_the_last_exit` s'il reste des sorties en cours,
  et émet tout de suite sinon.
- `_advance_exits()` vérifie après chaque nettoyage si le drapeau est levé et la liste vide,
  et émet alors, une seule fois.

Les sorties continuent d'avancer même quand le niveau est arrêté — c'est le cas depuis
l'étape 05 — donc le dernier personnage finit sa trajectoire pendant que le bandeau apparaît.

## Valeurs chiffrées

| Valeur | Choix | Où |
|---|---|---|
| Délai avant redémarrage | **3,0 s** | `LevelEndController.restart_delay_seconds` (`@export`) |
| Titre, taille de police | 52 | `LevelOutcomeBanner.tscn` |
| Deuxième ligne, taille | 24 | idem |
| Couleur de victoire | vert du check `#117A64` | constante du script |
| Couleur de défaite | rouge de la claque `#D9411F` | idem |
| Contour blanc du titre | 10 px, 86 % d'opacité | `LevelOutcomeBanner.tscn` |
| Contour de la deuxième ligne | 6 px | idem |

« Essayer encore !!! » fait 18 caractères : à 52 px ce sont ≈ 470 px sur un viewport de 720,
donc ça tient sans retour à la ligne. **À vérifier à l'image** — c'est le genre de calcul qui
se démentit.

## Détails qui comptent

**La couleur passe par un override de thème, pas par `modulate`.** Les deux lignes portent un
contour blanc, pour rester lisibles par-dessus le couloir quel qu'en soit le fond. Or
`modulate` multiplie *toutes* les couleurs du label, contour compris : il aurait teinté le
contour en vert ou en rouge et annulé exactement ce qui rend le texte lisible. D'où
`add_theme_color_override(&"font_color", ...)`, qui ne touche que les glyphes. Écart avec le
plan, qui ne parlait pas de contour.

**« Reste 0 » s'affiche sur le dernier personnage.** `_close_queue()` annonce le compte
avant tout le reste, sinon le HUD resterait bloqué sur « Reste 1 » pendant tout l'écran de
victoire. Une ligne qui n'était pas au plan.

**`_restart_queue()` est devenu `_build_queue()`.** Il n'est plus appelé qu'une fois, à
l'ouverture du niveau : « restart » décrivait la boucle infinie qui vient de disparaître.

**Le rechargement remet tout à neuf.** `get_tree().reload_current_scene()` rebâtit la scène
depuis le `.tscn` : Moral à 70, nouvelle file tirée au hasard, nouvelles couleurs, nouvelles
phrases. Rien à réinitialiser à la main, et aucun état résiduel possible. Godot opère
l'échange en fin de frame, donc l'appel depuis un `timeout` est sûr.

**Le minuteur est un nœud enfant injecté par `@export`**, donc son `node_paths` doit être
déclaré dans l'en-tête du nœud dans `Level.tscn`. Piège consigné depuis l'étape 03.
`restart_timer.start(restart_delay_seconds)` passe la durée à l'appel, pour que le `@export`
reste la seule source et que le `wait_time` du `.tscn` ne puisse pas le contredire.

**`LevelOutcomeBanner` est en `mouse_filter = ignore`**, comme tout le HUD : il couvre le
centre de l'écran, là où commencent les swipes.

**Le bandeau de réponse peut se superposer** une seconde à l'écran de fin : la dernière
réponse affiche son message pendant 1,2 s alors que le titre apparaît. Les deux sont à des
hauteurs différentes — titre au centre, message à +170 — donc à regarder, pas à corriger
d'avance.

## Vérification dans l'éditeur

Le moteur n'est pas lancé de mon côté.

1. **Gagner.** Traiter les 10 personnages sans tomber à zéro. Le « Gagné !!! » doit
   apparaître **une fois le dernier personnage sorti du cadre**, pas pendant son envol, et
   sans deuxième ligne.
2. **La barre ne doit plus bouger** pendant l'écran de victoire. C'est le défaut corrigé
   ci-dessus : si elle descend encore, `MoralController.stop()` n'est pas appelé.
3. **Perdre.** Laisser passer quatre personnes : « Essayer encore !!! » en gros, « Moral à
   zéro » en dessous.
4. **Le redémarrage** tombe 3 s après l'affichage, dans les deux cas. Moral revenu à 70,
   « Reste 10 », nouvelles phrases, nouvelles couleurs.
5. **Rien ne répond plus** entre la fin et le redémarrage : ni bouton, ni flèche, ni swipe.
6. **Le texte n'est ni rogné ni replié**, en particulier « Essayer encore !!! ».
7. **Enchaîner trois parties** sans quitter : pas de fuite de nœuds au moniteur de débogage,
   et le compteur « Reste N » repart bien de 10.

Points à juger :

- **3 s, est-ce le bon délai ?** C'est un `@export` sur `LevelEndController`.
- **Le titre au centre tombe sur la tête du joueur**, qui occupe 46 % de la hauteur. Faut-il
  le remonter vers le tiers supérieur ?
- **Gagner est-il atteignable ?** Avec les valeurs actuelles, trois erreurs sur dix font
  perdre. Si la victoire ne tombe jamais, c'est l'équilibrage qu'il faut bouger, dans
  `data/balance/default_moral_balance.tres`.

## Hors périmètre

Étoiles (3 à partir de 60 de Moral, 2 à partir de 30), statistiques de fin, rappel des
dernières erreurs avec la réponse attendue, pub récompensée « +50 de Moral », carte « Règle
du jour » à l'ouverture, et choix du niveau suivant. `LevelOutcomeBanner` est l'endroit où
tout cela viendra se greffer.

Le cadrage de la caméra retouché à la main (rig à `x = 1.09` avec un lacet de −1,2°) n'est
toujours pas recomposé selon la convention de la doc 02. Et l'exécutable du moteur (146 Mo)
est toujours `untracked` à la racine, hors de portée du `.gitignore` qui se trouve à
l'intérieur de `slap-or-check/`.
