# La jauge de Moral — pression, récompense et défaite

> **Étape 5** · branche `SlapOrChack-GameLoop` · décidé le 2026-10-27, implémenté.

## Contexte

L'étape 04 avait donné la boucle de personnage, mais **rien ne comptait** : une erreur
produisait un message qui s'effaçait en 1,2 s et le jeu continuait à l'identique. Ni
pression, ni enjeu, ni fin.

Cette étape ajoute la ressource unique du joueur. Le game design remplace les « 3 essais »
par une jauge de Moral de 0 à 100, cohérente avec le thème — la recherche d'emploi use : le
temps qui passe coûte, les bonnes réponses regonflent, les erreurs assomment.

`LevelDirector` émettait déjà `answer_judged(outcome)` avec le verdict `CORRECT / WRONG /
IGNORED`. C'était la raison d'être de ce signal, et **la boucle de personnage n'a pas eu à
être rouverte** : elle a seulement gagné deux choses qu'elle ne savait pas faire, un
compteur de file et un arrêt.

**Hors périmètre** : écran de fin, étoiles, rappel des erreurs, pub récompensée, victoire en
fin de file (étape 06) ; bonus café, Vrai Gentil et le reste des briques (étape 07+).

## Décisions

- **Les valeurs d'équilibrage vivent dans une ressource `MoralBalance` à part**, désignée par
  `LevelConfig`. Les onze niveaux partageront le même `.tres` : régler le drain se fait en un
  endroit, et un niveau ne diffère que par sa vitesse et la longueur de sa file.
- **À zéro, le niveau s'arrête** où il en est. Plus de spawn, la bulle disparaît, le bandeau
  annonce « Moral à zéro » et n'en bouge plus. Les personnages déjà en sortie finissent leur
  trajectoire. L'écran de fin de l'étape 06 se branchera sur le même signal.
- **Un nœud `MoralController` séparé.** `LevelDirector` ignore jusqu'à l'existence du Moral :
  les deux ne se connaissent que par des signaux reliés dans `Level.tscn`, dans les deux
  sens. On peut retirer le Moral, ou en changer les règles, sans toucher à la boucle.
- **Le HUD montre la barre, la valeur chiffrée et « Reste N personnes »**, sans compteur de
  série. Le bonus de série existe quand même et il est **annoncé par le bandeau** au moment
  où il tombe, comme le toast de la maquette : l'information arrive quand elle sert, sans
  élément permanent de plus.

## `MoralGauge`, ou l'exemple du CLAUDE.md pris au mot

Le `.claude/CLAUDE.md` donne cette classe comme **exemple de style**, en-tête et signature
comprises. Elle est écrite telle quelle, et deux de ses choix méritent d'être compris :

- **`drain(delta_seconds, drain_per_second)`** : le drain par seconde est un *paramètre*, pas
  un champ de la jauge. La raison est dans le commentaire d'origine — le `delta` arrivera
  déjà multiplié par le ralentissement du bonus café. `AnswerStreak.is_bonus_due(longueur)`
  suit la même forme, pour la même raison : le nombre est de l'équilibrage, pas une propriété
  d'un compteur.
- **`apply_change(amount)` prend un montant signé.** La jauge ne sait pas si c'est une
  récompense ou une punition : c'est l'appelant qui porte le signe. C'est ce qui empêche les
  règles du score d'entrer dans la jauge.

Et personne ne reçoit la jauge elle-même. `MoralController` relaie ses signaux ; le HUD n'a
que des nombres. C'est l'interface segregation du CLAUDE.md appliquée littéralement : un
script qui lit le Moral n'obtient pas l'objet capable de le modifier.

**`AnswerStreak` est un objet séparé** parce que `MoralGauge` ferait deux choses sinon. La
série casse sur une erreur **et** sur un laissé-passer : le bonus récompense l'attention
soutenue, pas la chance.

## Le flux de signaux

```
LevelDirector.answer_judged(outcome)
      ├────→ FeedbackBanner.show_outcome()        « Claque méritée »
      └────→ MoralController.apply_outcome()
                    ↓ MoralGauge / AnswerStreak
              MoralController
                    ├→ moral_changed(value)       → MoralHud.show_moral()
                    ├→ streak_bonus_earned(n)     → FeedbackBanner.show_streak_bonus()
                    └→ depleted                   → LevelDirector.stop()
                                                   → FeedbackBanner.show_defeat()

LevelDirector.characters_remaining_changed(n)     → MoralHud.show_remaining()
```

**Le piège évité, et il a été rencontré pour de vrai.** Deux signaux écrivent dans le même
bandeau pour une seule réponse : le verdict, puis le bonus de série qui doit l'écraser. Le
premier réflexe a été de compter sur l'ordre des connexions dans `Level.tscn`, puisque Godot
émet dans l'ordre de connexion. **Mauvaise idée** : à la première ouverture de la scène dans
l'éditeur, Godot a réenregistré le fichier et **réordonné les connexions**.

La solution tient en un mot-clé : `MoralController` annonce le bonus en différé
(`streak_bonus_earned.emit.call_deferred(...)`), donc à la fin de la frame, donc toujours
après le message que la réponse elle-même a écrit — quel que soit l'ordre des connexions.
Plus de dépendance invisible à un fichier que l'éditeur réécrit.

**À retenir pour la suite** : l'ordre des connexions dans un `.tscn` n'est pas un contrat.
Quand deux consommateurs d'un même signal doivent s'exécuter dans un ordre donné, c'est au
code de le dire, pas au fichier de scène.

## Fichiers

### Créés

| Fichier | Rôle |
|---|---|
| `scripts/core/MoralGauge.gd` | la valeur, ses bornes, ses deux signaux |
| `scripts/core/AnswerStreak.gd` | les bonnes réactions consécutives |
| `resources/MoralBalance.gd` | ce que chaque événement coûte ou rapporte |
| `scripts/gameplay/MoralController.gd` | tient le Moral à jour |
| `scripts/ui/MoralHud.gd` + `scenes/ui/MoralHud.tscn` | barre, valeur, « Reste N » |
| `data/balance/default_moral_balance.tres` | les sept valeurs du tableau 4 |

### Modifiés

| Fichier | Changement |
|---|---|
| `resources/LevelConfig.gd` | `@export var moral_balance: MoralBalance` |
| `data/levels/level_01.tres` | désigne le `.tres` d'équilibrage |
| `scripts/gameplay/LevelDirector.gd` | `characters_remaining_changed`, `stop()`, `_is_stopped` |
| `scripts/ui/FeedbackBanner.gd` | `show_streak_bonus()`, `show_defeat()`, et un `_write_message()` commun |
| `scenes/levels/Level.tscn` | `MoralController`, `MoralHud`, et six connexions de plus |

## Valeurs chiffrées et leur origine

Tableau 4 du game design, toutes dans `default_moral_balance.tres`.

| Champ | Valeur | Origine |
|---|---|---|
| `starting_value` | 70 | « Départ du niveau » |
| `drain_per_second` | 0,8 | « Temps qui passe −0,8/s » |
| `correct_answer_reward` | 5 | « Bonne réaction +5 » |
| `wrong_answer_penalty` | 22 | « Mauvaise réaction −22 » |
| `ignored_character_penalty` | 14 | « Personne laissée passer −14 » |
| `streak_length_for_bonus` | 5 | « Série de 5 bonnes réactions » |
| `streak_bonus` | 8 | « +8 bonus » |
| `low_moral_threshold` (HUD) | 30 | maquette, `classList.toggle("low", m < 30)` |

Les pénalités sont stockées **positives** et nommées `penalty` : remplir l'inspecteur ne
demande pas de se souvenir d'un signe, et `MoralBalance.change_for()` le pose.

**Ce que ces valeurs donnent, calculé et non testé** — c'est tout l'objet de l'étape :

- Un niveau de 10 personnes dure ≈ 45 s (4,2 s de marche + 0,35 s de battement), soit
  **−36 de drain**. Sans faute : +50 de bonnes réactions et +16 de deux bonus de série, donc
  la jauge sature à 100.
- Une erreur creuse un écart de 27 points (−22 au lieu de +5). **Trois erreurs sur dix**
  font perdre un niveau parti de 70.
- Ne rien faire du tout coûte ≈ 3,8 points par seconde, donc **mort en 18 s**, au quatrième
  personnage. Pratique pour tester la défaite vite.
- Le drain pèse donc **plus que sept bonnes réponses** sur un niveau. C'est peut-être lui le
  vrai adversaire, et pas les erreurs. À juger.

## Détails qui comptent

**Une seule source pour l'équilibrage.** Le plan prévoyait un `@export var balance` sur
`MoralController` *et* un `moral_balance` sur `LevelConfig` — soit la même référence branchée
à deux endroits. Corrigé en écrivant : le contrôleur prend le `LevelConfig` entier et lit
`config.moral_balance`. Les prix suivent le niveau, et il n'y a rien à rebrancher.

**Le personnage figé est remis à l'arrêt.** `stop()` appelle `_freeze_current_character()`,
qui repasse la figure en `idle`. Sans ça elle continue de **marcher sur place** : arrêter le
niveau n'arrête que le code qui la fait avancer, pas l'`AnimationPlayer`, qui tourne sur sa
propre horloge. Écart avec la maquette, dont la pose se gèle d'elle-même puisque son
animation est recalculée à chaque frame.

**La barre suit la valeur exacte, le nombre est arrondi.** Le drain se lit comme un
glissement continu, pendant qu'un chiffre qui vacillerait entre 69 et 70 serait illisible. Le
calcul de l'affichage suit mot pour mot l'exemple de lisibilité du CLAUDE.md
(`rounded_moral` → `displayed_moral`), qui est précisément ce cas.

**L'échange de style de la barre ne se fait qu'au franchissement du seuil**, pas à chaque
frame : `value_changed` part soixante fois par seconde à cause du drain, et
`add_theme_stylebox_override` à ce rythme serait du gâchis pur. Un booléen `_is_showing_warning`
garde l'état.

**Le HUD est en `mouse_filter = ignore` de bout en bout.** Il couvre le haut de l'écran, là
où commencent beaucoup de swipes : sans ça il mangerait le geste.

**`MoralHud` prend l'étendue de la barre dans `MoralGauge.MAX_VALUE`**, une constante lue — et
non la jauge reçue. Les deux ne peuvent pas se désaccorder, et le HUD n'obtient toujours rien
qu'il puisse modifier.

**L'ordre des `_ready` est sans conséquence.** `MoralController._ready()` annonce la valeur
d'ouverture avant que `MoralHud._ready()` n'ait tourné, mais les références exportées sont
résolues au chargement de la scène, bien avant tout `_ready` : écrire dans un label marche.
C'est pour cette raison que `MoralHud._ready()` ne réinitialise rien.

## Vérification dans l'éditeur

Rien n'est lancé de mon côté.

1. **F5.** La barre apparaît en haut, verte, aux deux tiers, avec « 70 » à droite et
   « Reste 10 » en dessous.
2. **Regarder sans rien faire 10 s** : la barre descend de 8 points. C'est le seul test du
   drain.
3. **Une bonne réponse** +5, **une erreur** −22, **un laissé-passer** −14. L'erreur doit se
   voir comme une chute franche.
4. **Cinq bonnes réponses d'affilée** : le bandeau doit afficher « Série de 5 : bonus de
   Moral » *à la place* de « Claque méritée », et la jauge sauter de 13 et non de 5.
5. **Se tromper au quatrième d'une série** : le compte repart de zéro, donc pas de bonus au
   cinquième.
6. **Passer sous 30** : la barre passe au rouge, et revient au vert si le Moral remonte.
7. **Laisser passer quatre personnes de suite** : la jauge atteint 0 en ≈ 18 s. Le bandeau
   annonce « Moral à zéro » et **ne disparaît pas**. Plus aucun personnage n'apparaît, la
   bulle est partie, celui qui marchait **s'arrête net sans piétiner**, et celui qui était en
   l'air finit sa trajectoire avant de disparaître.
8. **« Reste N »** décompte de 10 à 1, puis repart à 10 quand la file se reconstruit.
9. **Swiper depuis le haut de l'écran**, sur la barre : le geste doit passer.

Points à juger, qui conditionnent l'étape 06 :

- **Les valeurs sont-elles jouables ?** Trois erreurs sur dix qui font perdre : trop sévère,
  ou pas assez ? Tout est dans `default_moral_balance.tres`, aucun code à toucher.
- **Le drain se sent-il trop ?** 36 points sur un niveau, c'est beaucoup. Le baisser à 0,5
  changerait complètement le ton du jeu.
- La barre en haut gêne-t-elle la lecture de la bulle, qui monte haut quand un personnage est
  au fond du couloir ?

## Hors périmètre, à signaler

**Le cadrage de la caméra a été retouché à la main** dans `Level.tscn` entre les deux étapes :
le rig est passé de `(0.55, 0, 2.65)` à `(1.09, 0, 2.65)` avec un lacet de −1,2°. C'est
légitime — c'était le levier identifié par la doc 02 pour séparer le joueur de l'arrivant —
mais le rig n'est plus « posé aux pieds du personnage » comme cette doc l'énonce, donc le
décalage local de la `Camera3D` ne se lit plus comme « derrière et au-dessus ». À recomposer
une fois le cadrage figé, comme ça avait été fait à l'étape 2.

L'exécutable du moteur (146 Mo) est toujours `untracked` à la racine, et le `.gitignore`
ajouté est à l'intérieur de `slap-or-check/`, donc il ne le couvre pas. Signalé depuis
l'étape 01.
