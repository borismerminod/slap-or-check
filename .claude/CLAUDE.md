# Slap or Check — Instructions de développement

## 1. Le projet

Jeu hypercasual mobile (portrait, une main) sur le thème de la recherche d'emploi.
Des personnages avancent vers le joueur avec une phrase dans une bulle ; le joueur
swipe à gauche pour **claquer** (phrase « bateau ») ou à droite pour **checker**
(vraie information).

| Référence | Fichier |
|---|---|
| Game design complet (règles, briques, équilibrage) | `documents/claque-ou-check.md` |
| Maquette jouable Three.js (comportements de référence) | `documents/claque-ou-check-local.html` |

La maquette est la **référence du ressenti** (distances, durées, animations, valeurs de
Moral), pas une référence d'architecture : son code est volontairement compact et ne
respecte pas les conventions ci-dessous.

**Moteur : Godot 4.7.2-stable, GDScript.** Le binaire du moteur est versé dans le
dépôt : `Godot_v4.7.2-stable_linux.x86_64`, à la racine.

Organisation du dépôt :

```
slap-or-check/                          # racine du dépôt git
  Godot_v4.7.2-stable_linux.x86_64      # exécutable du moteur
  CLAUDE.md                             # importe .claude/CLAUDE.md
  documents/                            # game design et maquette
  slap-or-check/                        # racine du projet Godot (project.godot)
```

**Ne pas lancer le moteur sans que l'utilisateur le demande**, ni pour ouvrir
l'éditeur, ni en `--headless`. C'est lui qui teste dans l'éditeur. Toute scène ou
ressource doit donc être écrite dans un format texte valide (`.tscn`, `.tres`) et rester
simple à relire à la main. À la fin d'un changement, dire ce qu'il faut vérifier.

### Écrire un `.tscn` à la main

Deux pièges déjà rencontrés, qui échouent silencieusement :

- **Un `Transform3D` est sérialisé par lignes**, pas par axes : les arguments 0 à 2 sont
  `basis.rows[0]`, soit `(x_axis.x, y_axis.x, z_axis.x)`. Ce n'est **pas** la convention
  du constructeur GDScript `Transform3D(x_axis, y_axis, z_axis, origin)`. Se tromper
  écrit la rotation **transposée**, donc inverse — et une translation seule n'en souffre
  pas, ce qui masque l'erreur. Toute rotation écrite à la main se vérifie **à l'image**.
- **Une référence de nœud exportée** (`@export var x: SomeNode`) n'est résolue que si
  l'en-tête du nœud la déclare :
  `[node name="A" type="B" node_paths=PackedStringArray("x")]`. Sans ça le `NodePath`
  n'est jamais converti, la propriété reste nulle, et l'erreur n'apparaît qu'à
  l'exécution dans le `_ready()` qui s'en sert.

Règle générale : après avoir écrit un `.tscn` à la main, faire vérifier le résultat dans
l'éditeur avant d'empiler l'étape suivante dessus.

## 2. Langue

- **Tout le code est en anglais** : noms de classes, de fonctions, de variables, de
  signaux, de fichiers, de nœuds, de dossiers, et contenu des commentaires.
- Les **phrases du jeu** affichées au joueur restent en français : c'est du contenu, il
  vit dans des fichiers de données, pas dans le code.
- Les échanges avec l'utilisateur et les documents de conception restent en français.

## 3. Principes SOLID

Ces principes ne sont pas négociables, y compris sur un petit fichier.

### Single responsibility
- Un script = une responsabilité, énonçable en une phrase sans « et ».
- Séparer systématiquement les quatre couches : **données** (`Resource`), **règles**
  (classes pures, sans nœud), **présentation** (scènes, animations, HUD),
  **orchestration** (un seul chef d'orchestre par niveau).
- Exemple : `MoralGauge` détient la valeur du Moral et ses bornes ; il n'affiche rien et
  ne connaît pas l'existence d'un `Label`. Le HUD écoute son signal.

### Open/closed
- Les « briques » de gameplay (Le Relou, Le Recruteur coriace, L'Influenceur, Le Vrai
  Gentil, Bulle brouillée, Bonus café, Mode inversé) s'ajoutent **sans modifier** le
  code existant : une nouvelle `Resource` de configuration et/ou une nouvelle
  implémentation d'interface, jamais un `match` de plus dans une fonction centrale.
- Pas de grand `match character_kind:` qui grossit à chaque brique. Le comportement est
  porté par l'objet lui-même.

### Liskov substitution
- Une sous-classe doit pouvoir remplacer sa classe de base sans surprise : pas de
  méthode surchargée qui refuse de faire son travail, pas de pré-condition ajoutée.

### Interface segregation
- Des interfaces courtes et ciblées. Un script qui n'a besoin que de lire le Moral ne
  reçoit pas l'objet capable de le modifier.

### Dependency inversion
- Les couches hautes dépendent d'abstractions, pas de nœuds concrets.
- **Interdit** : `get_parent()`, `get_node("../../Something")`, `$"/root/Main/..."` pour
  atteindre un collaborateur.
- **À la place** : injection par `@export` (assignée dans la scène), injection par une
  méthode `setup(...)` appelée par le parent, ou communication par **signal** vers le
  haut. Un enfant émet, il n'appelle pas son parent.

## 4. Lisibilité

Le lecteur cible est un humain qui reprend le projet sans contexte.

### Pas d'appels imbriqués
Chaque résultat intermédiaire reçoit une variable dont le nom explique ce qu'elle
contient. Une ligne ne fait qu'une chose.

```gdscript
# À éviter
label.text = str(clamp(round(gauge.get_value()), 0, MAX_MORAL))

# À faire
var current_moral: float = gauge.get_value()
var rounded_moral: int = int(round(current_moral))
var displayed_moral: int = clamp(rounded_moral, 0, MAX_MORAL)
label.text = str(displayed_moral)
```

La même règle vaut pour les conditions : une condition composée est extraite dans une
variable booléenne nommée, ou dans une petite fonction qui répond à une question.

```gdscript
var is_reachable: bool = distance_to_player <= SLAP_RANGE
var is_awaiting_answer: bool = current_phase == Phase.WALKING
if is_reachable and is_awaiting_answer:
    ...
```

### Nommage
- Les noms décrivent **l'intention**, jamais le type ni l'implémentation : `remaining_queue`,
  pas `arr2` ; `apply_correct_answer()`, pas `handle()`.
- Fonctions = verbe à l'infinitif : `spawn_next_character()`, `drain_moral_over_time()`.
- Fonctions qui renvoient un booléen = question : `is_slap_expected()`, `has_brick()`.
- Pas d'abréviation inventée : `duration`, pas `dur` ; `character`, pas `char`.
- Conventions GDScript : `PascalCase` pour les classes et les fichiers de scripts et de
  scènes, `snake_case` pour les fonctions et les variables, `UPPER_SNAKE_CASE` pour les
  constantes, préfixe `_` pour ce qui est privé au script.
- Les signaux se nomment par l'événement passé, au participe : `moral_depleted`,
  `character_reached_player`, `answer_submitted`.

### Écriture des fonctions
- **Typage statique partout** : paramètres, valeurs de retour, variables, `@export`.
- Une fonction tient à l'écran (≈ 25 lignes). Au-delà, elle fait plusieurs choses :
  extraire des fonctions au nom explicite.
- Sorties anticipées (`return` tôt) plutôt que des `if` imbriqués ; deux niveaux
  d'indentation dans le corps, au maximum.
- Pas de nombre magique dans le corps d'une fonction : une constante nommée, ou un champ
  `@export` de la ressource de configuration.

## 5. Commentaires

Règle stricte, à respecter dans chaque fichier.

- **Aucun commentaire dans le corps d'une fonction.** Si une ligne a besoin d'être
  expliquée, elle doit être réécrite : variable intermédiaire mieux nommée, ou extraction
  dans une fonction dont le nom dit l'intention.
- **Un commentaire en en-tête** de chaque classe, de chaque fonction et au-dessus de
  chaque attribut, qui dit en quelques points ce que la chose fait.
- Utiliser les commentaires de documentation `##` de Godot (visibles dans l'aide de
  l'éditeur).
- Un commentaire dit **ce que** la chose fait et **pourquoi**, pas comment : il ne
  paraphrase pas le code.
- Quand la fonction ou la classe est complexe, le commentaire devient une **liste à
  puces** : étapes, cas traités, effets de bord, ou conditions d'erreur. La lisibilité
  passe avant la concision.

```gdscript
## Moral gauge of the current level: the player's single resource.
##
## - Starts at a configured value and drains continuously while the level runs.
## - Rewards correct answers, punishes mistakes and ignored characters.
## - Emits [signal depleted] once, as soon as the value reaches zero.
class_name MoralGauge
extends RefCounted

## Emitted when the moral reaches zero, which ends the level as a defeat.
signal depleted

## Emitted on every change, so the HUD can refresh without polling.
signal value_changed(new_value: float)

## Highest reachable moral; also the width of a full gauge.
const MAX_VALUE: float = 100.0

## Current moral, always within [0, MAX_VALUE].
var _value: float = 0.0

## Guards against emitting [signal depleted] more than once per level.
var _is_depleted: bool = false

## Applies the continuous drain of time, then reports the new value.
##
## - [param delta_seconds] is the frame time already scaled by the coffee slowdown.
## - Does nothing once the gauge is depleted, so a defeat stays final.
func drain(delta_seconds: float, drain_per_second: float) -> void:
    if _is_depleted:
        return
    var drained_amount: float = drain_per_second * delta_seconds
    _set_value(_value - drained_amount)
```

## 6. Architecture visée

Le contenu est séparé du code : ajouter des phrases, un niveau ou une brique ne doit pas
demander de toucher à un script.

```
slap-or-check/      # racine du projet Godot, à côté de project.godot
  scenes/           # .tscn : Main, Level, Character, Player, HUD, panels
  scripts/
    core/           # règles pures, sans nœud ni dépendance à l'arbre de scène
    gameplay/       # orchestration du niveau, file d'attente, réactions
    characters/     # comportements de personnages (une brique = un fichier)
    ui/             # HUD, carte « Règle du jour », écran de fin
  resources/        # classes Resource : LevelConfig, PhrasePool, CharacterKind...
  data/             # .tres : phrases, niveaux, briques — données, pas de code
  assets/           # matériaux, polices, sons
```

Points d'attention repris de la maquette :
- Le temps de réaction est une **distance** : la vitesse de marche est la variable de
  difficulté, elle vient de la configuration du niveau.
- Les erreurs ont des **conséquences visibles dans la file**, pas seulement un chiffre
  qui baisse (le Relou revient, l'Influenceur ajoute deux abonnés).
- Les valeurs d'équilibrage (Moral de départ 70, drain 0,8/s, bonne réaction +5,
  erreur −22, laissé passer −14, série de 5 +8, Vrai Gentil +20) sont **exposées** dans
  la configuration : elles ne sont pas testées et vont bouger.

## 7. Plans d'implémentation

Tout plan d'implémentation est **écrit dans `documents/setup/`**, versionné avec le code.

- Un fichier par étape, préfixé d'un numéro d'ordre : `01-third-person-camera.md`,
  `02-...`. Le numéro dit dans quel ordre le jeu a été construit.
- Le fichier commence par un en-tête de statut : étape, branche, date, état
  (proposé / implémenté / abandonné).
- Il contient le **contexte** (pourquoi ce changement), l'approche retenue, les fichiers
  touchés, les valeurs chiffrées retenues et leur origine, et comment vérifier.
- Quand l'implémentation s'écarte du plan, c'est le plan qu'on corrige : il doit rester
  la description de ce qui existe, pas de ce qu'on avait imaginé.

C'est la mémoire du projet : quelqu'un qui reprend doit pouvoir lire `documents/setup/`
dans l'ordre et comprendre comment on en est arrivé là.

## 8. Méthode de travail

- Avancer par briques : une brique du game design à la fois, jouable, avant la suivante.
- Nouvelle fonctionnalité = d'abord se demander où elle va dans les quatre couches
  (données / règles / présentation / orchestration).
- Ne pas introduire de dépendance à un plugin ou à un asset externe sans le proposer
  d'abord.
- À la fin d'un changement, signaler à l'utilisateur ce qu'il doit vérifier dans
  l'éditeur, puisque le moteur n'est pas lancé ici.
